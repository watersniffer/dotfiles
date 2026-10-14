import QtQuick
import Quickshell

// The floating-island pill from the waybar bar: black rounded container, with
// hover feedback. Everything in the bar sits in one of these.
Rectangle {
    id: root

    property alias content: holder.data
    default property alias content: holder.data

    property bool interactive: true
    property int hPadding: 8
    property int vPadding: 2
    property int hMargin: 4

    implicitHeight: holder.implicitHeight + vPadding * 2
    implicitWidth: holder.implicitWidth + hPadding * 2

    color: Theme.base
    radius: Theme.pillRadius
    border.width: 0

    // Subtle lift on hover, same intent as the waybar #island_hover.
    opacity: 1.0
    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Item {
        id: holder
        anchors.fill: parent
        anchors.margins: root.vPadding
        anchors.leftMargin: parent.leftMargin + root.hPadding
        anchors.rightMargin: parent.rightMargin + root.hPadding
        implicitHeight: childrenRect.height
        implicitWidth: childrenRect.width
    }
}
