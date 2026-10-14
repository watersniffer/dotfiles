//@ pragma UseQApplication
//
// Media player widget for the waybar mpris module.
//
// Built on https://github.com/GTGalaxi/qsMediaPlayer (a single self-contained
// MediaPlayer.qml) and wrapped in two layer-shell windows:
//
//  * TRIGGER - always visible, fully transparent, sitting over the bar in the
//    column above the card. This is what makes hover work at all: the card's own
//    window is destroyed when hidden, so it cannot be the thing that re-opens it.
//
//  * CARD - the visible widget. Appears on hover, disappears when hover is gone
//    from BOTH the trigger and the card.
//
// WHY HOVER EVENTS AND NOT A POLL
// -------------------------------
// The obvious approach is to poll the cursor and test it against two rectangles.
// That costs ~8.7ms per `hyprctl cursorpos` call on this machine (measured over
// 50 calls), so even 10Hz would burn ~9% of a core - unacceptable on the i5.
// A long-lived polling loop does not help, because the cost is hyprctl's own
// runtime, not the fork.
//
// Quickshell's Hyprland module exposes no cursor position either (its qmltypes is
// an empty stub), so there is nothing native to read. Qt's HoverHandler is
// event-driven and costs nothing, so that is what this uses.
//
// The trigger strip does cover waybar's mpris module, which means clicks there
// land on us rather than waybar. That is fine - hover replaced the need to click
// to open, and the module's only click action was our own toggle anyway.
//
// A NOTE ON THE NUMBERS IN HERE
// -----------------------------
// Every size and offset below is divided by 0.9 on purpose. Quickshell requests
// a surface size/position and Hyprland commits exactly 0.9x that, for both
// position and extent - verified across four independent requests (420->378,
// 378->340, 380->342, 30->27, all 0.9000) and on margins (570->513, 568->511,
// 549->494, all 0.9000). So the literal-looking 422 and 548 below are really
// "380 and 493", which is what centres the card on the 1366px panel.
//
// Separately, the bar reserves the top 26px (`hyprctl monitors` shows
// `reserved: 0 26 0 0`), which pushes any top-anchored layer surface down to
// y=26. That is why the trigger needs a negative top margin to sit over the bar
// rather than under it.
//
// To move or resize the card, change the LOGICAL number you want and divide by
// 0.9, then confirm with `hyprctl layers | grep quickshell`.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "MediaPlayer.qml"

ShellRoot {
    id: root

    readonly property string statePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000")
                                         + "/music-widget-open"

    // Hover state of the two zones.
    property bool hoverTrigger: false
    property bool hoverCard: false

    // Click pin. The state file is still watched so the waybar mpris click (which
    // runs ~/.local/bin/music-widget-toggle) keeps working as a "pin it open"
    // control. Hover alone would be enough, but the pin is a useful fallback if
    // the trigger strip ever ends up misaligned with the module.
    property string state: "0"
    readonly property bool pinned: state === "1"

    property bool hovering: hoverTrigger || hoverCard
    readonly property bool open: pinned || hovering

    // Follow the pin file.
    //
    // A one-shot `cat` on a timer, NOT `tail -f`. StdioCollector signals
    // onStreamFinished when the stream ENDS, so a long-running tail never fires
    // it. Restarting a short-lived Process each tick does fire it.
    Process {
        id: poll
        running: true
        command: ["cat", root.statePath]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = String(text).trim();
                if (t !== "") root.state = t;
            }
        }
    }

    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            poll.running = false;
            poll.running = true;
        }
    }

    // A short grace period so travelling from the bar down onto the card - or
    // between the two - does not flash the widget closed mid-movement.
    Timer {
        id: hideGrace
        interval: 220
        onTriggered: root.hoverTrigger = false
    }

    Connections {
        target: root
        function onHoveringChanged() {
            if (root.hovering)
                hideGrace.stop();
            else
                hideGrace.restart();
        }
    }

    // ---------------------------------------------------------------- trigger
    // Invisible, always-on trigger strip over the bar, in the column the card
    // hangs below. 380 wide covers the mpris module and the card beneath it.
    PanelWindow {
        id: trigger

        visible: true

        anchors.top: true
        anchors.left: true
        margins.left: 548
        // Negative: the bar reserves the top 26px, which pushes a top-anchored
        // layer surface below it. Without this the trigger would sit under the
        // bar instead of over it, and hovering the module would never hit it.
        margins.top: -29

        // Floating overlay: reserve no space, or Hyprland would shove every
        // tiled window out of the way.
        exclusiveZone: -1

        implicitWidth: 422
        implicitHeight: 33

        color: "transparent"

        // A Rectangle, not a bare Item: only visual items report implicitWidth/
        // implicitHeight, and PanelWindow commits to the content's implicit size.
        // A plain Item here collapses the trigger to a few stray pixels.
        Rectangle {
            width: 422
            height: 33
            color: "transparent"

            HoverHandler {
                id: triggerHover
                onHoveredChanged: {
                    root.hoverTrigger = hovered;
                    if (hovered) hideGrace.stop();
                }
            }
        }
    }

    // ------------------------------------------------------------------- card
    PanelWindow {
        id: win

        visible: root.open

        anchors.top: true
        anchors.left: true
        margins.left: 548
        margins.top: 4

        exclusiveZone: -1

        implicitWidth: 422
        implicitHeight: 138
        color: "transparent"

        Item {
            id: slideHost
            // Explicit, not anchors.fill: PanelWindow commits to its content's
            // size, and a content Item that only anchors.fill collapses.
            width: 422
            height: 138

            opacity: root.open ? 1 : 0
            y: root.open ? 0 : -14

            // Spring physics rather than fixed-duration easing. Quickshell's
            // SpringAnimation carries velocity across interruptions, so a
            // reversal mid-flight continues smoothly instead of restarting, and
            // it is frame-rate independent rather than tied to a duration.
            property real pop: root.open ? 1 : 0.92

            transform: Scale {
                origin.x: slideHost.width / 2
                origin.y: slideHost.height / 2
                xScale: slideHost.pop
                yScale: slideHost.pop
            }

            SpringAnimation {
                target: slideHost
                property: "pop"
                spring: 3.4
                damping: 0.58
                mass: 0.7
            }

            SpringAnimation {
                target: slideHost
                property: "opacity"
                spring: 4.2
                damping: 0.85
                mass: 0.7
            }

            SpringAnimation {
                target: slideHost
                property: "y"
                spring: 3.2
                damping: 0.62
                mass: 0.7
            }

            Rectangle {
                width: 380
                height: 124
                color: "transparent"
                HoverHandler {
                    id: cardHover
                    onHoveredChanged: {
                        root.hoverCard = hovered;
                        if (hovered) hideGrace.stop();
                    }
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
                width: 380
                height: 124
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
}