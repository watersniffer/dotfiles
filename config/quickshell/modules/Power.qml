import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../lib"
import "."

// Battery + backlight - port of the waybar battery and backlight/slider modules,
// kept in one component because they sit next to each other in the right pill.
//
// Both read sysfs directly with a tiny `cat`, which avoids a pactl/dbus round
// trip per update. Reads are event-ish (a 2s timer for backlight, 60s for the
// battery) and writes are one-shot processes.
//
// Clicking the battery runs the same night-light toggle the waybar module used.

Item {
    id: root

    implicitHeight: Theme.barHeight - Theme.barMargin * 2
    implicitWidth: row.implicitWidth + 14

    // --- backlight state ---------------------------------------------------
    property int brightness: 0
    property int maxBrightness: 0

    Process {
        id: blRead
        running: true
        command: ["sh", "-c",
                  "cat /sys/class/backlight/*/max_brightness /sys/class/backlight/*/brightness 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = (text || "").trim().split(/\s+/);
                if (p.length >= 2) {
                    var mx = parseInt(p[0]), cur = parseInt(p[1]);
                    if (!isNaN(mx) && mx > 0) root.maxBrightness = mx;
                    if (!isNaN(cur)) root.brightness = cur;
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: { blRead.running = false; blRead.running = true; }
    }

    readonly property real blFraction: maxBrightness > 0
        ? Math.max(0, Math.min(1, brightness / maxBrightness)) : 0

    function setBrightness(f) {
        if (maxBrightness <= 0) return;
        var v = Math.round(Math.max(0, Math.min(1, f)) * maxBrightness);
        blWrite.command = ["sh", "-c",
                           "echo " + v + " > /sys/class/backlight/*/brightness 2>/dev/null || true"];
        blWrite.running = true;
    }

    Process { id: blWrite; running: false }

    // --- battery state -----------------------------------------------------
    property int charge: 0
    property bool onAc: false

    Process {
        id: batRead
        running: true
        command: ["sh", "-c",
                  "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null; " +
                  "cat /sys/class/power_supply/AC*/online 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = (text || "").trim().split(/\n/);
                if (lines.length > 0) {
                    var c = parseInt(lines[0]);
                    if (!isNaN(c)) root.charge = c;
                }
                if (lines.length > 1) {
                    var a = parseInt(lines[1]);
                    root.onAc = !isNaN(a) && a === 1;
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: { batRead.running = false; batRead.running = true; }
    }

    function batteryGlyph() {
        if (onAc) return "";
        var idx = Math.max(0, Math.min(11, Math.floor(charge / 10)));
        return ["", "", "", "", "", "",
                "", "", "", "", "", ""][idx];
    }

    // --- layout ------------------------------------------------------------
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        // Backlight slider
        Item {
            width: 56
            height: 18
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.bg3

                Rectangle {
                    width: parent.width * root.blFraction
                    height: parent.height
                    radius: 2
                    color: Theme.text
                    Behavior on width {
                        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: (m) => root.setBrightness(m.x / width)
                onPositionChanged: (m) => { if (pressed) root.setBrightness(m.x / width); }
            }
        }

        // Battery. Wrapped in an Item because a MouseArea with anchors.fill
        // cannot live directly inside a Row (Row forbids anchored children).
        Item {
            implicitWidth: batRow.implicitWidth
            implicitHeight: batRow.implicitHeight

            Row {
                id: batRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: root.batteryGlyph()
                    color: root.charge <= 15 ? Theme.urgent : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                }

                Text {
                    text: root.charge + "%"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: nightToggle.running = true
            }
        }
    }

    Process {
        id: nightToggle
        running: false
        command: ["bash", "-lc", "$HOME/.config/waybar/scripts/toggle-hyprsunset"]
    }
}
