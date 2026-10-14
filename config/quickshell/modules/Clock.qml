import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../lib"
import "."

// Clock - port of the waybar clock module: 12-hour by default, and on middle
// click a second line with the full date.
//
// One 1s timer, which is the minimum a clock can run at.

Item {
    id: root

    implicitHeight: Theme.barHeight - Theme.barMargin * 2
    implicitWidth: txt.implicitWidth + 14

    readonly property bool alt: altState
    property bool altState: false

    property var now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Text {
        id: txt
        anchors.centerIn: parent
        text: root.alt
              ? Qt.formatDate(root.now, "dddd  |  HH:mm  |  d MMMM")
              : Qt.formatTime(root.now, "hh:mm AP")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: root.altState = !root.altState
    }
}
