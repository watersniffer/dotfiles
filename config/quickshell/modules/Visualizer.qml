import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../lib"
import "."

// Audio visualiser - replaces the external `cava` process the waybar bar used.
//
// The old setup shelled out to cava, which streams ASCII bars and measured
// ~4% CPU plus a 3.6 MB process. This reads peak levels straight from
// Quickshell's native Pipewire service and draws them in-process, so there is no
// external process at all.
//
// Bars are animated with a Behavior, so they glide rather than jump, and the
// whole thing is driven by Pipewire change signals rather than polling - the
// only timer is the decay tick that makes the bars fall when audio stops.

Item {
    id: root

    implicitHeight: Theme.barHeight - Theme.barMargin * 2
    implicitWidth: 72

    readonly property int barCount: 14
    property var levels: new Array(barCount).fill(0)

    // Decay so silent sections settle to flat instead of freezing mid-height.
    Timer {
        interval: 60
        running: true
        repeat: true
        onTriggered: {
            // peaks live on Pipewire.defaultAudioSink.audio.peaks
            var node = Pipewire.defaultAudioSink;
            var audio = node ? node.audio : null;
            var pk = (audio && audio.peaks) ? audio.peaks : null;
            if (pk) {
                var n = Math.min(root.barCount, pk.length);
                for (var i = 0; i < n; ++i) {
                    // peaks arrive in dB; map roughly -60..0 onto 0..1
                    var db = pk[i];
                    var v = db <= -60 ? 0 : Math.min(1, Math.max(0, (db + 60) / 60));
                    if (v > root.levels[i]) root.levels[i] = v;
                }
            }
            for (var j = 0; j < root.levels.length; ++j) {
                if (root.levels[j] > 0.02) root.levels[j] *= 0.86;
                else root.levels[j] = 0;
            }
            root.levelsChanged();
        }
    }

    // Peak values are sampled inside the decay tick rather than through a
    // Connections block: the sink object exposes `peaks` but has no
    // peaksChanged signal (verified at runtime - Connections warned
    // "no signal of the target matches the name"). One property read per tick is
    // cheaper than guessing at a signal that isn't there.

    Row {
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.barCount

            delegate: Rectangle {
                required property int index

                width: 3
                height: Math.max(2, (root.levels[index] || 0) * (Theme.barHeight - Theme.barMargin * 2))
                radius: 1.5
                color: Theme.text

                Behavior on height {
                    NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}
