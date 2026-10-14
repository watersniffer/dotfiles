//@ pragma UseQApplication
//
// Quickshell music player - replaces the old eww music widget.
//
// Upstream (github.com/zonicisalive/quickshell-music-player) ships a shell root
// whose window is `visible: true` from startup, and there is no IPC API in
// Quickshell 0.3.2 as shipped by Arch (no IpcHandler - checked
// /usr/lib/qt6/qml/Quickshell, which only has Quickshell.Io). So instead of
// trying to toggle visibility from outside, the player is STARTED when you want
// it and STOPPED when you don't, by ~/.local/bin/music-widget-toggle.
//
// The only thing that decides whether the window appears is the MUSIC_WIDGET_OPEN
// environment variable, which the toggle script sets when it launches us.
//
//   MUSIC_WIDGET_OPEN=1  -> window visible (the widget case)
//   (unset)              -> window hidden, process idles at ~0% with no surface

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import "components"
import "presets"
import "services"
import "common"

ShellRoot {
    id: root

    readonly property bool wantVisible: Quickshell.env("MUSIC_WIDGET_OPEN") === "1"

    PanelWindow {
        id: playerWindow

        visible: root.wantVisible

        anchors.top: true
        anchors.right: true

        // Just under the 24px bar rather than 40px down the screen, so it reads
        // as a dropdown from the media module.
        margins.top: 28
        margins.right: 40

        implicitWidth: playerWidget.width
        implicitHeight: playerWidget.height
        color: "transparent"

        readonly property MprisPlayer activePlayer: MprisController.activePlayer

        ExpandingLyricsPlayer {
            id: playerWidget
            player: playerWindow.activePlayer
            width: 420
            height: lyricsExpanded ? 380 : 144

            Behavior on height {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
