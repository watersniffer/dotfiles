import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../lib"
import "."

// MPRIS module for the bar - port of the waybar mpris module, and the click
// target that opens the animated MediaDropdown.
//
// Shows "{artist} {title}" like the waybar format, with a play/pause status
// glyph. Left click toggles the dropdown, matching the old eww behaviour.

Rectangle {
    id: root

    property alias dropdown: dd

    implicitHeight: Theme.barHeight - Theme.barMargin * 2
    implicitWidth: row.implicitWidth + 16
    radius: Theme.pillRadius
    color: Theme.base

    readonly property var player: dd.player
    readonly property bool playing: player ? player.playbackState === 1 : false

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.playing ? "" : ""
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.player
                  ? ((root.player.trackArtist ? root.player.trackArtist + " " : "")
                     + (root.player.trackTitle ? root.player.trackTitle : ""))
                  : "nothing"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 240)
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: dd.open = !dd.open
    }

    // The dropdown lives here so both share the same resolved player.
    MediaDropdown {
        id: dd
        visible: shown
    }

    // Middle click toggles playback without opening the dropdown.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: {
            if (root.player) root.player.togglePlaying();
            dd.open = false;
        }
    }
}
