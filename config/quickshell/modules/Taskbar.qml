import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../lib"
import "."

// Taskbar - port of the waybar wlr/taskbar module: shows open windows grouped by
// appname, click to focus, middle click to close.
//
// Backed by Hyprland.toplevels, which is event-driven, so there is no polling.

Item {
    id: root

    implicitHeight: Theme.barHeight - Theme.barMargin * 2
    implicitWidth: row.implicitWidth + 10

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            // Bound directly to `.values` (a Quickshell UntypedObjectModel), NOT
            // through a helper function - a function call is not a tracked
            // dependency, so the Repeater would never update. `values` emits
            // valuesChanged, which QML tracks automatically.
            model: Hyprland.toplevels.values || []

            delegate: Rectangle {
                required property var modelData

                // Verified against the live object: a Hyprland toplevel exposes
                // address, title, activated, workspace, monitor - there is NO
                // `appname` property (an earlier version read it and got
                // undefined, so the bar rendered no window indicators).
                readonly property int wsId: modelData.workspace ? modelData.workspace.id : -1
                readonly property bool focused: modelData.activated === true
                readonly property bool onCurrentWs: wsId === (Hyprland.focusedWorkspace
                                                            ? Hyprland.focusedWorkspace.id : -1);

                width: 4
                height: focused ? 14 : 11
                radius: 2
                color: !onCurrentWs ? Qt.rgba(1, 1, 1, 0.18)
                     : focused     ? Theme.text
                                   : Theme.subtext

                Behavior on height {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 160 }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        var t = modelData;
                        if (!t) return;
                        if (mouse.button === Qt.MiddleButton) {
                            Hyprland.dispatch({ function () { return "closewindow address:" + t.address; } });
                        } else {
                            Hyprland.dispatch({ function () { return "focuswindow address:" + t.address; } });
                        }
                    }
                }

            }
        }
    }
}
