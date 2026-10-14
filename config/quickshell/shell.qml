import QtQuick
import Quickshell
import Quickshell.Wayland
import "./lib"
import "./modules"

// The bar - a like-for-like replacement for the waybar config in
// ~/.config/waybar/{config-hypr.jsonc,Modules,ModulesCustom,style.css}.
//
// Layout matches the waybar one exactly:
//   left    : hyprland/workspaces        (own island)
//   centre  : wlr/taskbar, mpris, visualiser, all inside one pill
//   right   : ONE continuous pill - tray, volume, backlight, battery, clock
//
// Height 24, 1px margin, radius 6, AMOLED black with one light accent, all of
// which lives in lib/Theme.qml ported from waybar's colors.css.
//
// NOTE: the three regions are positioned with anchors on a plain Item rather than
// a Row. A Row forbids anchored children ("Cannot specify left, right,
// horizontalCenter... Row will not function"), so the earlier Row-based version
// silently laid out nothing.

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    margins.top: Theme.barMargin
    margins.left: Theme.barMargin
    margins.right: Theme.barMargin

    // The bar surface is transparent; only the pills carry colour.
    color: "transparent"

    readonly property int rowHeight: Theme.barHeight - Theme.barMargin * 2

    // ---------------------------------------------------------- left region
    Workspaces {
        id: ws
        anchors.left: parent.left
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter
    }

    // ------------------------------------------------------- centre region
    Item {
        id: centre

        // Centre group pill, centred on the monitor (the media module used to
        // sit at x=683, so the dropdown is still positioned under it).
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: centreRow.implicitWidth + 6
        height: root.rowHeight

        Rectangle {
            anchors.fill: parent
            radius: Theme.pillRadius
            color: Theme.base
        }

        Row {
            id: centreRow
            anchors.centerIn: parent
            spacing: 6

            Taskbar { }
            MprisBar { }
            Visualizer { }
        }
    }

    // ---------------------------------------------------------- right region
    Rectangle {
        id: rightPill

        anchors.right: parent.right
        anchors.rightMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        height: root.rowHeight
        width: rightRow.implicitWidth + 8
        radius: Theme.pillRadius
        color: Theme.base

        Row {
            id: rightRow
            anchors.centerIn: parent
            spacing: 8

            Tray { }
            Audio { }
            Power { }
            Clock { }
        }
    }
}
