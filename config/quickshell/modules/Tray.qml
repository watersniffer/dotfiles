import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../lib"
import "."

// System tray - port of the waybar tray module, using Quickshell's native
// SystemTray service (StatusNotifierItem host) rather than GTK's.
//
// This was the piece with no Qt equivalent in Arch, but Quickshell ships it, so
// nothing had to be hand-rolled.

Item {
    id: root

    implicitHeight: Theme.barHeight - Theme.barMargin * 2
    implicitWidth: row.implicitWidth + 12

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items.values || []

            delegate: Item {
                required property var modelData

                width: 16
                height: 16

                Image {
                    anchors.fill: parent
                    source: modelData.icon || ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    smooth: true
                    // Waybar used icon-size 13; 16 with PreserveAspectFit keeps
                    // the visual weight similar inside a 24px bar.
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (!modelData) return;
                        if (mouse.button === Qt.RightButton) {
                            if (modelData.menu) modelData.menu.popup();
                        } else {
                            modelData.activate(0, 0); // 0 = X11 activation, ignored on Wayland
                        }
                    }
                }
            }
        }
    }
}
