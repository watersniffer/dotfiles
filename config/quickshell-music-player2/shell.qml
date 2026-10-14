//@ pragma UseQApplication
//
// Media player widget for the waybar mpris module.
//
// Built on https://github.com/GTGalaxi/qsMediaPlayer (a single self-contained
// MediaPlayer.qml) plus two layer-shell windows.
//
// WHY TWO WINDOWS, AND WHY THE TRIGGER IS THE BIG ONE
// ---------------------------------------------------
// The card is its own window because it has to be clickable - the player cycle
// arrows and dots live on it.
//
// The hover handling is deliberately NOT shared with the card. An earlier
// version gave the card its own HoverHandler and relied on handing hover over
// when the cursor moved down off the bar. That handoff never completed: the
// cursor left the trigger, the card had not yet reported being hovered, so
// `hovering` went false and the widget closed - it was impossible to reach.
//
// So the trigger now spans the ENTIRE column, bar down past the bottom of the
// card, and owns all hover. One window means one continuous hover region and no
// handoff to lose. The card sits above it and only draws and takes clicks.
//
// While the card is closed the trigger is masked down to the bar strip, so the
// invisible part of the window does not swallow clicks meant for the desktop or
// for whatever window is underneath.
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
// "380 and 493", which is what centres the card on the 1366px panel.
//
// Separately, the bar reserves the top 26px (`hyprctl monitors` shows
// `reserved: 0 26 0 0`), which pushes any top-anchored layer surface down to
// y=26. That is why the trigger needs a negative top margin to start at y=0.
//
// To move or resize things, change the LOGICAL number you want and divide by
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

    // Hover state. Only the trigger sets this; the card never reports hover.
    property bool hoverTrigger: false

    // Click pin. The state file is still watched so the waybar mpris click (which
    // runs ~/.local/bin/music-widget-toggle) keeps working as a "pin it open"
    // control.
    property string state: "0"
    readonly property bool pinned: state === "1"

    readonly property bool open: pinned || hoverTrigger

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

    // ---------------------------------------------------------------- trigger
    // Declared FIRST so the card is stacked above it: the card takes clicks,
    // this takes hover.
    PanelWindow {
        id: trigger

        visible: true

        anchors.top: true
        anchors.left: true
        margins.left: 548

        // Negative: the bar reserves the top 26px, which pushes a top-anchored
        // layer surface down to y=26. Without this the trigger would start under
        // the bar instead of over it, and hovering the module would never hit it.
        margins.top: -29

        exclusiveZone: -1

        implicitWidth: 422
        implicitHeight: 198      // logical 178: bar strip down past the card

        color: "transparent"

        // Shrink to just the bar strip while the card is closed, so the invisible
        // remainder of this window does not eat clicks aimed at the desktop.
        mask: Region {
            regions: root.open
                ? [{ x: 0, y: 0, width: 422, height: 198 }]
                : [{ x: 0, y: 0, width: 422, height: 33 }]
        }

        Rectangle {
            width: 422
            height: 198
            color: "transparent"

            HoverHandler {
                id: triggerHover
                onHoveredChanged: root.hoverTrigger = hovered
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

        // 0, not a positive value: the bar's 26px reserved zone already places
        // the card at y=26, flush under the bar. An extra margin leaves a seam
        // the cursor crosses.
        margins.top: 0

        exclusiveZone: -1

        implicitWidth: 422
        implicitHeight: 169      // logical 152

        color: "transparent"

        Item {
            id: slideHost
            // Explicit, not anchors.fill: PanelWindow commits to its content's
            // size, and a content Item that only anchors.fill collapses.
            width: 422
            height: 169

            opacity: root.open ? 1 : 0
            y: root.open ? 0 : -34

            // The card emerges from the TOP CENTRE of its own box - directly
            // under the bar it belongs to - scaling up from there while dropping
            // in, with an OutBack overshoot for snap.
            //
            // This uses Behavior + NumberAnimation, NOT Quickshell's
            // SpringAnimation. A SpringAnimation on a property that also has a
            // binding takes ownership of the property and loses the binding it
            // needed as its target, so it never moves - verified by sampling
            // `pop` every frame: it sat at 0.550 for the whole open transition
            // while `open` was true. Behavior animates binding-driven changes
            // correctly. Easing.OutBack supplies the overshoot.
            property real pop: root.open ? 1 : 0.55

            transform: Scale {
                origin.x: slideHost.width / 2
                origin.y: 0
                xScale: slideHost.pop
                yScale: slideHost.pop
            }

            Behavior on pop {
                NumberAnimation {
                    duration: 340
                    easing.type: Easing.OutBack
                    easing.overshoot: 2.1
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 170
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 300
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
                // Must track slideHost's size, or the opaque fill stops
                // covering the window and the card shows a transparent rim.
                width: 422
                height: 169
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