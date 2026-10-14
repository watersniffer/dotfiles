import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../lib"
import "."

// Volume control - port of the waybar pulseaudio module.
//
// Uses Quickshell's native Pipewire service instead of spawning pactl/wpctl, so
// there is no process per change. Volume comes from the sink object; setting it
// writes straight back to Pipewire.
//
// The sink volume is a cubic factor, matching PulseAudio semantics; the bar and
// the slider both work in the linear percentage a person actually expects.

Item {
    id: root

    // Verified against the live object: the Pipewire node exposes
    // id/name/description/nickname/isSink/isStream/type/properties/audio/ready -
    // volume, muted and peaks all live on the nested `audio` object, not the node.
    readonly property var node: Pipewire.defaultAudioSink
    readonly property var sink: node ? node.audio : null
    readonly property bool muted: (sink && sink.muted !== undefined) ? !!sink.muted : false

    // 0..1 linear
    readonly property real level: {
        if (!sink) return 0;
        var v = (sink.volume === undefined) ? 0 : sink.volume;
        if (v < 0) v = 0;
        return Math.pow(v, 1 / 3);
    }

    implicitHeight: Theme.barHeight - Theme.barMargin * 2
    implicitWidth: row.implicitWidth + 14

    function setLevel(n) {
        if (!sink) return;
        var clamped = Math.max(0, Math.min(1, n));
        sink.volume = Math.pow(clamped, 3);
    }

    function nudge(delta) {
        setLevel(level + delta);
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // Speaker glyph, click = mute toggle
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            horizontalAlignment: Text.AlignHCenter
            text: root.muted ? "" : ""
            color: root.muted ? Theme.subtext : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1

            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.sink) root.sink.muted = !root.sink.muted
            }
        }

        // Percentage, matching the waybar "{icon} {volume}%" format.
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.level * 100) + "%"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        // Volume bar
        Item {
            width: 46
            height: 18
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: trough
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.bg3

                Rectangle {
                    width: parent.width * root.level
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
                onPressed: (m) => root.setLevel(m.x / width)
                onPositionChanged: (m) => { if (pressed) root.setLevel(m.x / width); }
            }
        }
    }
}
