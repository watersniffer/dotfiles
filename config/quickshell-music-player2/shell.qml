//@ pragma UseQApplication
//
// Media player: a bar module that expands into the player on hover.
//
// Built on https://github.com/GTGalaxi/qsMediaPlayer (a single self-contained
// MediaPlayer.qml).
//
// ONE SURFACE, NOT TWO
// --------------------
// Earlier versions used two windows - a transparent trigger strip over the bar
// and the card below - and hover was unreliable. The cause was structural, not
// a tuning problem: the card was stacked ABOVE the trigger and covered the same
// column, so past the boundary the card surface was what sat under the pointer
// and the trigger's surface received nothing. Every arrangement of "hover the
// bar to open, hover the card to keep open" across two surfaces had to survive
// that handover, and it never did.
//
// So there is now only one window, and it replaces waybar's mpris module
// outright. The collapsed pill IS the widget: you hover the thing itself, there
// is no proxy, no seam and no handover to lose. Hovering reveals the player
// underneath; the pill stays put, like any other bar module.
//
// WHY HOVER EVENTS AND NOT A POLL
// -------------------------------
// Polling the cursor costs ~8.7ms per `hyprctl cursorpos` call on this machine
// (measured over 50 calls), so even 10Hz would burn ~9% of a core. A long-lived
// polling loop does not help, because the cost is hyprctl's runtime, not the
// fork. Quickshell's Hyprland module exposes no cursor position either (its
// qmltypes is an empty stub). Qt hover events are event-driven and free.
//
// A NOTE ON THE NUMBERS IN HERE
// -----------------------------
// Every size and offset below is divided by 0.9 on purpose. Quickshell requests
// a surface size/position and Hyprland commits exactly 0.9x that, for both
// position and extent - verified across four independent requests (420->378,
// 378->340, 380->342, 30->27, all 0.9000) and on margins (570->513, 568->511,
// 549->494, all 0.9000). So the literal-looking 422 and 548 below are really
// "380 and 493", which is what centres this on the 1366px panel.
//
// The bar also reserves the top 26px (`hyprctl monitors` shows
// `reserved: 0 26 0 0`), which floors any top-anchored layer surface at y=26.
// The negative top margin is what lifts the window above that floor so the pill
// can sit on the bar at y=1.
//
// To move or resize things, change the LOGICAL number you want and divide by
// 0.9, then confirm with `hyprctl layers | grep quickshell`.

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "MediaPlayer.qml"

ShellRoot {
    id: root

    // Click pins the player open; hover is transient. Pinning lives in memory
    // only - the state file that used to back it is gone, because waybar's mpris
    // module (which was what invoked the toggle script) no longer exists.
    property bool hoverCard: false
    property bool pinned: false
    readonly property bool open: pinned || hoverCard

    readonly property var player: {
        var p = Mpris.players.values;
        return p.length > 0 ? p[0] : null;
    }

    PanelWindow {
        id: win

        visible: true

        anchors.top: true
        anchors.left: true

        // 493 logical: centres the 380-wide surface on the 1366px panel.
        margins.left: 548
        // Lifts the surface above the bar's 26px reserved zone so the pill can
        // sit at y=1, flush with waybar.
        margins.top: -29

        // Floating overlay: reserve no space, or Hyprland would shove every
        // tiled window out of the way.
        exclusiveZone: -1

        implicitWidth: 422      // logical 380
        implicitHeight: 198     // logical 178: 28 for the pill, 170 for the card

        color: "transparent"

        // While collapsed the input region is just the pill, so the invisible
        // card-shaped remainder does not swallow clicks meant for the desktop.
        //
        // This uses `item`, NOT `regions`: Region.regions is read-only
        // (isReadonly in the qmltypes, no setter), so binding to it is silently
        // ignored, which leaves the region EMPTY and makes the surface fully
        // click-through - hover dies and clicks fall through to whatever is
        // underneath. Only `item` is writable.
        mask: Region {
            item: root.open ? hitOpen : hitCollapsed
        }

        Rectangle {
            id: hitCollapsed
            x: 67
            y: 0
            width: 289
            height: 28
            color: "transparent"
        }

        Rectangle {
            id: hitOpen
            x: 0
            y: 0
            width: 422
            height: 198
            color: "transparent"
        }

        // ------------------------------------------------------------- pill
        // The bar module itself: matches waybar's pill styling from
        // ~/.config/waybar/style.css (@base background, radius 6, height 24).
        Rectangle {
            id: pill
            x: 67
            y: 1
            width: 289
            height: 27
            radius: 6
            color: "#0b0b11"           // @base, as waybar's pills
            border.width: 1
            border.color: "#1c1c24"

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Rectangle {
                    width: 16
                    height: 16
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#1c1c24"
                    border.width: 1
                    border.color: "#2a2a34"

                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        color: "#bfbcc7"   // @text
                        font.pixelSize: 11
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24 - 10 - 8
                    elide: Text.ElideRight
                    color: "#bfbcc7"       // @text
                    font.pixelSize: 12
                    text: {
                        if (!root.player || !root.player.metadata)
                            return "No media";
                        var a = root.player.metadata.artist || "";
                        var t = root.player.metadata.title || "";
                        if (a && t) return a + " - " + t;
                        return t || a || "No media";
                    }
                }
            }

            // Reproduces what waybar's mpris module used to do, so removing
            // that module did not quietly drop these bindings: left pins the
            // player open, middle toggles playback, right skips, wheel is volume.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: function (mouse) {
                    if (!root.player) return
                    if (mouse.button === Qt.MiddleButton)
                        root.player.togglePlaying();
                    else if (mouse.button === Qt.RightButton)
                        root.player.next();
                    else
                        root.pinned = !root.pinned;
                }

                onWheel: function (wheel) {
                    if (!root.player || !root.player.volumeSupported) return
                    var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    root.player.volume = Math.max(0, Math.min(1, root.player.volume + step));
                }
            }
        }

        // ------------------------------------------------------------- card
        // The player, revealed under the pill on hover.
        Item {
            id: cardSlot
            x: 0
            y: 28
            width: 422
            height: 170

          Item {
            id: cardHost
            width: 422
            height: 170

            opacity: root.open ? 1 : 0
            y: root.open ? 0 : -12

            property real pop: root.open ? 1 : 0.82

            transform: Scale {
                origin.x: cardHost.width / 2
                origin.y: 0
                xScale: cardHost.pop
                yScale: cardHost.pop
            }

            // Behavior + NumberAnimation, NOT Quickshell's SpringAnimation. A
            // SpringAnimation on a property that also has a binding takes
            // ownership of the property and loses the binding it needed as its
            // target, so it never moves - verified by sampling `pop` every
            // frame: it sat at 0.550 for the whole open transition while `open`
            // was true. Behavior animates binding-driven changes correctly.
            Behavior on pop {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.9
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutCubic
                }
            }

            // Opaque AMOLED background.
            //
            // MediaPlayer.qml declares a `backgroundColor` property and then
            // never uses it - upstream draws no background rectangle anywhere,
            // because it is designed as a transparent floating widget. So the
            // theme colours passed to the card only affect text/icons/buttons.
            //
            // The fix lives here rather than in the vendored file so
            // MediaPlayer.qml stays a byte-for-byte copy of upstream and can be
            // re-fetched with a plain curl.
            Rectangle {
                width: 422
                height: 170
                radius: 14
                color: "#0b0b11"           // @base
                border.width: 1
                border.color: "#1c1c24"
            }

            // AMOLED palette, matching ~/.config/waybar/colors.css:
            //   @base #0b0b11   @text #bfbcc7   @subtext #85838b
            MediaPlayer {
                id: card
                anchors.centerIn: parent
                width: 340

                backgroundColor: "#0b0b11"
                foregroundColor: "#bfbcc7"
                mutedColor:      "#85838b"
                secondaryColor:  "#9c9aa6"
                accentColor:     "#bfbcc7"
                surfaceColor:    "#121219"
                hoverColor:      "#1e1e26"
                badgeColor:      "#0b0b11"
                badgeBorder:    "#2a2a34"
                volumeColor:     "#bfbcc7"
                cornerRadius: 12
            }
          }
        }

        // One hover region for the whole surface - the pill and the card are the
        // same window, so there is nothing to hand over.
        Item {
            id: hoverZone
            x: 0
            y: 0
            width: 422
            height: 198

            HoverHandler {
                id: hover
                onHoveredChanged: root.hoverCard = hovered
            }
        }
    }
}