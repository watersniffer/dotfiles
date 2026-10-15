//@ pragma UseQApplication
//
// Media player widget for the waybar mpris module.
//
// Replaces the old eww music widget, using https://github.com/GTGalaxi/qsMediaPlayer
// (a single self-contained MediaPlayer.qml) embedded in a wrapper that adds the
// three things the raw component does not do:
//
//  1. A WINDOW. MediaPlayer.qml is a bare Item, so it needs a PanelWindow to live
//     on screen.
//
//  2. CENTRING. Anchored to the top and given margins.left, because anchoring
//     left+right as well makes a PanelWindow stretch between the margins and
//     ignore the content's width. 473 = (1366 - 420) / 2, which is also where
//     the old eww widget sat, so it lines up under the mpris module.
//
//  3. OPEN/CLOSE ANIMATION. A PanelWindow is a Window, not an Item, so it has no
//     opacity/x/y to animate - the animation lives on `slideHost`, an inner Item.
//     opacity (fade), scale (OutBack pop) and y (slides down from the bar) all
//     animate together.
//
// TOGGLE
// ------
// ~/.local/bin/music-widget-toggle flips a one-byte state file, read here by a
// long-running `tail -f` Process. This replaced two earlier approaches that both
// failed on this Quickshell build (0.3.2 from Arch):
//
//   * FileView + watchChanges - verified broken: loaded=true and text() returned
//     the right value, but writing to the file externally never triggered a
//     re-read. It only tracks its own writes.
//   * start/stop the process - worked, but Quickshell needs ~15s to bring this up,
//     so the widget appeared slowly and with no animation at all, because a brand
//     new window just pops into existence.
//
// A persistent process makes the toggle instant and lets the animation run.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "MediaPlayer.qml"

ShellRoot {
    id: root

    // XDG_RUNTIME_DIR, not UID: UID is a shell *variable*, not an environment
    // variable, so Quickshell.env("UID") returns "" and the read silently
    // fails. XDG_RUNTIME_DIR is exported and is always correct.
    readonly property string statePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000")
                                         + "/music-widget-open"
    readonly property bool open: state === "1"

    property string state: "0"

    // Follow the toggle file.
    //
    // A one-shot `cat` on a timer, NOT `tail -f`. StdioCollector signals
    // onStreamFinished when the stream ENDS, so a long-running tail never fires
    // it - that is why a tail-based watcher loaded fine but never updated the
    // state. Restarting a short-lived Process each tick does fire it.
    //
    // 250ms interval is ~4 tiny spawns per second and only while a player is
    // running, which is far cheaper than the 15s restart this replaced.
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

    PanelWindow {
        id: win

        visible: root.open

        anchors.top: true
        anchors.left: true
        // Centre on the 1366px panel.
        //
        // Calibrated against `hyprctl layers`, not arithmetic. Two wrinkles:
        //   * margins.left is NOT the surface x - Hyprland reports x = margin - 57.
        //   * the committed surface is 340 wide, not the 378 requested below.
        //     Neither implicitWidth nor width reaches the committed size on this
        //     build; the window auto-sizes to the card's content (320 implicit
        //     plus the 12px cycle-arrow overhang on each side).
        // 570 is therefore what puts the 340px card at x=513: centre 683.
        margins.left: 570
        margins.top: 28

        // This widget floats OVER the desktop. Without this, Hyprland gives the
        // surface an exclusive zone and reserves that space, which shoves every
        // tiled window down/out of the way - the "it pushes the windows away"
        // report. -1 means reserve nothing.
        exclusiveZone: -1

        // These are advisory; see the note above about the committed size.
        implicitWidth: 378
        width: 378
        implicitHeight: card.implicitHeight
        color: "transparent"

        Item {
            id: slideHost
            anchors.fill: parent
            opacity: root.open ? 1 : 0
            y: root.open ? 0 : -18

            transform: Scale {
                origin.x: slideHost.width / 2
                origin.y: 0
                xScale: root.open ? 1 : 0.94
                yScale: root.open ? 1 : 0.94

                Behavior on xScale {
                    NumberAnimation {
                        duration: root.open ? 300 : 150
                        easing.type: Easing.OutBack
                    }
                }
                Behavior on yScale {
                    NumberAnimation {
                        duration: root.open ? 300 : 150
                        easing.type: Easing.OutBack
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: root.open ? 200 : 130
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: root.open ? 240 : 130
                    easing.type: Easing.OutCubic
                }
            }

            // Opaque AMOLED background.
            //
            // MediaPlayer.qml declares a `backgroundColor` property and then
            // never uses it - upstream draws no background rectangle anywhere,
            // because it is designed as a transparent floating widget. So the
            // theme colours we pass in below only affect text/icons/buttons and
            // the widget renders see-through.
            //
            // The fix lives here rather than in the vendored file so
            // MediaPlayer.qml stays a byte-for-byte copy of upstream and can be
            // re-fetched with a plain curl.
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "#0b0b11"          // @base
                border.width: 1
                border.color: "#1c1c24"    // hairline, keeps the edge visible on a dark wallpaper
            }

            // AMOLED palette, matching ~/.config/waybar/colors.css:
            //   @base #0b0b11   @text #bfbcc7   @subtext #85838b
            MediaPlayer {
                id: card

                // The component's children anchor to `parent.left`/`parent.right`,
                // but it never sets its own width, so as a plain Item it would
                // lay out at 0 and render nothing.
                width: 378

                backgroundColor: "#0b0b11"
                foregroundColor: "#bfbcc7"
                mutedColor:      "#85838b"
                secondaryColor:  "#9c9aa6"
                accentColor:     "#bfbcc7"
                surfaceColor:    "#121219"
                hoverColor:      "#1e1e26"
                badgeColor:      "#0b0b11"
                badgeBorder:      "#2a2a34"
                volumeColor:     "#bfbcc7"
                cornerRadius: 12
            }
        }
    }
}
