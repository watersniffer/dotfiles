import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../lib"

// The animated media dropdown.
//
// This is the reason for moving to Quickshell: real QML animations, which
// GTK3/eww cannot do. Three properties animate together on open -
//
//   opacity   0    -> 1     (fade)
//   scale     0.94 -> 1     (a genuine pop, OutBack overshoot)
//   y         -14  -> 0     (slides down out of under the bar)
//
// and reverse faster on close so it feels responsive rather than sluggish.
//
// CPU notes: nothing polls. Track data arrives as MPRIS change signals, and the
// single 1s timer only re-renders the elapsed clock between position updates.

// ------------------------------------------------------------------- window

PanelWindow {
    id: root

// Quickshell 0.3.2's Mpris service exposes ONLY a `players` model - there is no
// activePlayer property, and it does not prefer the playing player. With spotify
// and a browser both registered it will settle on a paused one, which is the bug
// the eww widget had. So: prefer a player whose playbackState is Playing
// (Stopped=0, Playing=1, Paused=2), else the first registered.
//
// Mpris.players is a Quickshell UntypedObjectModel - the array is `.values`
// (verified by probing the live object; it has no get()/count).
    function pickPlayer() {
    var list = [];
    try {
        var v = Mpris.players.values;
        if (v) list = v;
    } catch (e) {
        return null;
    }
    if (list.length === 0) return null;
    for (var i = 0; i < list.length; ++i) {
        if (list[i].playbackState === 1) return list[i];
    }
    return list[0];
}
    function fmt(ms) {
    if (!ms || ms <= 0) return "0:00";
    var t = Math.floor(ms / 1000);
    var m = Math.floor(t / 60);
    var s = t % 60;
    return m + ":" + (s < 10 ? "0" : "") + s;
}


    // Anchor ONLY the top edge.
    //
    // Two mistakes fixed here, both found by inspecting `hyprctl layers`:
    //  * anchoring left+right as well makes the window stretch between the
    //    margins, ignoring implicitWidth - that produced a 959px card.
    //  * anchoring the BOTTOM put the card at the bottom of the screen instead
    //    of just under the bar. It belongs under the bar, so top it is, with a
    //    top margin equal to bar height + bar margin + a small gap.
    //
    // margins.left 453 matches the waybar media module, which is also where the
    // old eww widget sat.
    anchors {
        top: true
    }

    margins.left: 453
    margins.top: Theme.barHeight + Theme.barMargin + 4
    implicitWidth: 460
    implicitHeight: 244
    color: "transparent"

    property bool open: false

    // `shown` is the animated truth; `open` is the request. Separating them lets
    // the close animation finish before the surface is really hidden.
    property bool shown: false
    property var player: picked
    property var picked: null
    property real elapsedMs: 0

    readonly property bool playing: player ? player.playbackState === 1 : false
    readonly property real progress: {
        if (!player || player.length <= 0) return 0;
        return Math.max(0, Math.min(1, player.position / player.length));
    }

    // PanelWindow is a Window: it exposes neither opacity nor x/y, so both the
    // fade and the slide are applied to slideHost below instead.
    visible: shown

   onOpenChanged: {
        if (open) {
            root.picked = pickPlayer();
            shown = true;
        } else {
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 150
        onTriggered: root.shown = false
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.picked = pickPlayer();
        }
    }

    Timer {
        interval: 1000
        running: root.shown
        repeat: true
        onTriggered: root.elapsedMs = root.player ? root.player.position : 0
    }

    // Click anywhere not on the card to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    // ------------------------------------------------------------------ card

    // PanelWindow is a Window, so it has no y to animate. The slide therefore
    // lives on this inner host, which slides the card down out from under the bar.
    Item {
        id: slideHost
        anchors.fill: parent
        y: root.shown ? 0 : -14
        opacity: root.shown ? 1 : 0

        // The pop: a Scale transform with an OutBack overshoot. A Behavior cannot
        // target a grouped `transform`, so xScale/yScale animate individually.
        transform: Scale {
            origin.x: width / 2
            origin.y: 0
            xScale: root.shown ? 1 : 0.94
            yScale: root.shown ? 1 : 0.94

            Behavior on xScale {
                NumberAnimation {
                    duration: root.open ? 280 : 140
                    easing.type: Easing.OutBack
                }
            }
            Behavior on yScale {
                NumberAnimation {
                    duration: root.open ? 280 : 140
                    easing.type: Easing.OutBack
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.open ? 220 : 140
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: root.open ? 240 : 140
                easing.type: Easing.OutCubic
            }
        }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 6
        radius: 12
        color: Theme.base
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        MouseArea {
            anchors.fill: parent
            onClicked: mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                spacing: 14

                // Cover art
                Rectangle {
                    Layout.preferredWidth: 78
                    Layout.preferredHeight: 78
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.05)
                    clip: true

                    Image {
                        id: art
                        anchors.fill: parent
                        anchors.margins: 2
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        smooth: true
                        source: root.player && root.player.trackArtUrl
                                ? root.player.trackArtUrl : ""
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !art.visible
                        text: "♪"
                        color: Theme.subtext
                        font.pixelSize: 26
                        font.family: Theme.fontFamily
                    }
                }

                ColumnLayout {
                    spacing: 3
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: root.player && root.player.trackTitle
                              ? root.player.trackTitle : "Nothing playing"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.player && root.player.trackArtist
                              ? root.player.trackArtist : "—"
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        text: fmt(root.elapsedMs) + " / " + fmt(root.player ? root.player.length : 0)
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }
            }

            // Progress bar, draggable
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: Theme.bg3

                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: 2
                    color: Theme.text
                }

                MouseArea {
                    id: seek
                    anchors.fill: parent
                    anchors.margins: -7
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.player ? root.player.canSeek : false
                    onPressed: mouse => seekTo(mouse.x / width)
                    onPositionChanged: mouse => { if (pressed) seekTo(mouse.x / width); }
                }
            }

            // Transport
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Tbtn {
                    icon: ""
                    tip: "Previous"
                    on: root.player ? root.player.canGoPrevious : false
                    onFire: if (root.player) root.player.previous()
                }
                Tbtn {
                    icon: root.playing ? "" : ""
                    tip: root.playing ? "Pause" : "Play"
                    on: root.player ? root.player.canControl : false
                    onFire: if (root.player) root.player.togglePlaying()
                }
                Tbtn {
                    icon: ""
                    tip: "Next"
                    on: root.player ? root.player.canGoNext : false
                    onFire: if (root.player) root.player.next()
                }
            }
        }
    }
    }

    function seekTo(f) {
        if (!root.player || !root.player.canSeek) return;
        root.player.seek(Math.max(0, Math.min(1, f)) * root.player.length);
    }

component Tbtn: Rectangle {
    id: btn

    property string icon: ""
    property string tip: ""
    property bool on: true
    signal fire()

    width: 38
    height: 38
    radius: 19
    color: hov.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    opacity: on ? 1 : 0.35

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: btn.icon
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 19
    }

    HoverHandler { id: hov }
    TapHandler {
        enabled: btn.on
        onTapped: btn.fire()
    }

    ToolTip.visible: hov.hovered && btn.on
    ToolTip.text: btn.tip
    ToolTip.delay: 500
}

}

// ------------------------------------------------------- transport button
//
// Declared as a separate component rather than a Repeater over an array of
// objects: QML's parser rejects `function` values inside an object literal used
// as a Repeater model ("Expected token `,'").
