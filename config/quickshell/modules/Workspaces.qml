import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../lib"
import "."

// Workspace switcher - port of the waybar hyprland/workspaces module.
//
// Persistent workspaces 1-5, scroll to move, active one inverted (light pill on
// black text), matching the waybar CSS exactly.
//
// Entirely event-driven: Hyprland pushes workspace/focus changes, so there is no
// polling.

Rectangle {
    id: root

    implicitHeight: Theme.barHeight - Theme.barMargin * 2
    implicitWidth: row.implicitWidth + 16
    radius: Theme.pillRadius
    color: Theme.base

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: 5

            delegate: Rectangle {
                required property int index

                readonly property int wsId: index + 1
                readonly property bool active: Hyprland.focusedWorkspace
                                              ? Hyprland.focusedWorkspace.id === wsId
                                              : false

                width: 22
                height: 18
                radius: Theme.pillRadius
                color: active ? Theme.text : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 150; easing.type: Easing.InOutQuad }
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.wsId
                    color: parent.active ? Theme.base : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch({
                        function () { return "workspace " + wsId; }
                    })
                }
            }
        }
    }

    // Scroll anywhere on the pill to move workspaces, like the waybar module.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            var d = wheel.angleDelta.y;
            if (d === 0) return;
            Hyprland.dispatch({
                function () { return d > 0 ? "workspace e+1" : "workspace e-1"; }
            });
        }
    }
}
