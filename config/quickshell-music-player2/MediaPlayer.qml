import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root
    
    // Theme properties
    property color backgroundColor: "#1e1e2e"
    property color foregroundColor: "#cdd6f4"
    property color mutedColor: "#585b70"
    property color secondaryColor: "#a6adc8"
    property color accentColor: "#89b4fa"
    property color surfaceColor: "#313244"
    property color hoverColor: "#45475a"
    property color badgeColor: "#1e1e2e"
    property color badgeBorder: "#585b70"
    property color volumeColor: "#89b4fa"
    
    property int cornerRadius: 8
    property int albumArtSize: 64
    property bool showCycleArrows: true
    property bool showProgressBar: true
    property bool showPlayerDots: true
    
    property int playerIndex: 0
    property MprisPlayer player: Mpris.players.values.length > 0 ? Mpris.players.values[playerIndex % Mpris.players.values.length] : null
    
    implicitWidth: 320
    implicitHeight: slideContainer.height + bottomSection.height + 24
    
    function cyclePlayer(direction) {
        const count = Mpris.players.values.length
        if (count === 0) return
        playerIndex = (playerIndex + direction + count) % count
        slideAnim.stop()
        playerContent.x = direction * (slideContainer.width + 12)
        slideAnim.to = 0
        slideAnim.start()
    }
    
    Timer { running: root.player?.playbackState === MprisPlaybackState.Playing; interval: 1000; repeat: true; onTriggered: root.player?.positionChanged() }
    
    Connections { target: Mpris.players; function onValuesChanged() { root.playerIndex = Mpris.players.values.length === 0 ? 0 : root.playerIndex % Mpris.players.values.length } }
    
    Item {
        id: slideContainer
        clip: true
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: playerContent.implicitHeight
        
        SpringAnimation { id: slideAnim; target: playerContent; property: "x"; spring: 4.5; damping: 0.35; mass: 1.0 }
        
        PlayerContent {
            id: playerContent
            x: 0
            width: slideContainer.width
            player: root.player
        }
    }
    
    CycleArrow {
        id: leftArrow
        anchors { left: parent.left; verticalCenter: slideContainer.verticalCenter; leftMargin: -12 }
        text: "‹"
        visible: Mpris.players.values.length > 1
        onClicked: root.cyclePlayer(-1)
    }

    CycleArrow {
        id: rightArrow
        anchors { right: parent.right; verticalCenter: slideContainer.verticalCenter; rightMargin: -12 }
        text: "›"
        visible: Mpris.players.values.length > 1
        onClicked: root.cyclePlayer(1)
    }
    
    Column {
        id: bottomSection
        spacing: 6

        anchors { top: slideContainer.bottom; left: parent.left; right: parent.right; topMargin: 6 }
        
        ProgressBar { width: parent.width; visible: showProgressBar && root.player !== null }
        PlayerDots { width: parent.width; visible: showPlayerDots && Mpris.players.values.length > 1 }
    }
    
    function formatTime(seconds) {
        const s = Math.floor(seconds)
        const m = Math.floor(s / 60)
        const h = Math.floor(m / 60)
        if (h > 0) return h + ":" + String(m % 60).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0")
        return m + ":" + String(s % 60).padStart(2, "0")
    }
    
    component CycleArrow: Rectangle {
        property string text
        signal clicked()

        width: 20
        height: slideContainer.height
        color: "transparent"

        Text {
            anchors { centerIn: parent }
            text: parent.text
            color: arrowArea.containsMouse ? "#cdd6f4" : "#45475a"
            font.pixelSize: 16

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea { id: arrowArea; anchors { fill: parent } hoverEnabled: true; onClicked: parent.clicked() }
    }
    
    component ProgressBar: RowLayout {
        spacing: 6
        
        Text {
            text: formatTime(root.player?.position ?? 0)
            color: root.mutedColor
            font.pixelSize: 10
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: root.surfaceColor
            
            Rectangle {
                width: root.player?.length > 0 ? parent.width * (Math.min(root.player.position, root.player.length) / root.player.length) : 0
                height: parent.height
                radius: parent.radius
                color: root.accentColor
                Behavior on width { SpringAnimation { spring: 4.5; damping: 0.35; mass: 1.0 } }
            }
            MouseArea { anchors { fill: parent } onClicked: (mouse) => { if (root.player?.canSeek) root.player.position = root.player.length * (mouse.x / width) } }
        }
        
        Text {
            text: formatTime(root.player?.length ?? 0)
            color: root.mutedColor
            font.pixelSize: 10
        }
    }
    
    component PlayerDots: Item {
        height: 6
        Row {
            anchors { centerIn: parent }
            spacing: 6
            Repeater {
                model: Mpris.players.values.length
                delegate: Rectangle {
                    width: index === root.playerIndex ? 16 : 6
                    height: 6
                    radius: 3
                    color: index === root.playerIndex ? root.accentColor : root.hoverColor
                    Behavior on width { SpringAnimation { spring: 4.5; damping: 0.35; mass: 1.0 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    MouseArea { anchors { fill: parent } onClicked: { if (index !== root.playerIndex) root.cyclePlayer(index > root.playerIndex ? 1 : -1) } }
                }
            }
        }
    }
    
    component PlayerContent: Item {
        property MprisPlayer player
        implicitHeight: contentCol.implicitHeight
        
        property var entry: null
        property string iconSource: ""
        
        onPlayerChanged: updateEntry()
        Component.onCompleted: updateEntry()
        
        Connections { target: player; function onDesktopEntryChanged() { updateEntry() } }
        
        function updateEntry() {
            if (!player?.desktopEntry) {
                entry = null
                iconSource = ""
                return
            }
            entry = DesktopEntries.heuristicLookup(player.desktopEntry)
            iconSource = entry?.icon ? Quickshell.iconPath(entry.icon, true) : ""
        }
        
        Timer { interval: 200; repeat: true;running: iconSource === "" && player?.desktopEntry !== undefined; onTriggered: { updateEntry(); running = false } }
        
        ColumnLayout {
            id: contentCol
            anchors { left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8 }
            spacing: 4
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                AlbumArt { Layout.alignment: Qt.AlignVCenter; player: contentCol.parent.player; iconSource: contentCol.parent.iconSource }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Text {
                        Layout.fillWidth: true
                        text: player?.trackTitle ?? "Nothing playing"
                        color: root.foregroundColor
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: player?.trackArtist ?? ""
                        color: root.secondaryColor
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                    
                    RowLayout {
                        spacing: 8
                        
                        MediaButton { text: "󰼨"; enabled: player?.canGoPrevious ?? false; onClicked: player?.previous() }
                        MediaButton { text: player?.isPlaying ? "󰏤" : "󰼛"; enabled: player?.canTogglePlaying ?? false; onClicked: player.isPlaying = !player.isPlaying }
                        MediaButton { text: "󰼧"; enabled: player?.canGoNext ?? false; onClicked: player?.next() }
                        VolumeControl { player: contentCol.parent.player }
                    }
                }
            }
        }
    }
    
    component AlbumArt: Item {
        property MprisPlayer player
        property string iconSource
        
        width: 68
        height: 68
        
        Item {
            id: artItem
            width: root.albumArtSize
            height: root.albumArtSize
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#aa000000"
                shadowBlur: 0.8
                shadowVerticalOffset: 3
                shadowHorizontalOffset: 2
                autoPaddingEnabled: true
            }
            
            Rectangle {
                anchors { fill: parent }
                radius: root.cornerRadius
                color: root.surfaceColor
                
                Image {
                    id: artImage
                    anchors { fill: parent }
                    source: player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }
                
                Rectangle {
                    id: artMask
                    anchors { fill: parent }
                    radius: root.cornerRadius
                    visible: false
                }
                
                OpacityMask {
                    anchors { fill: parent }
                    source: artImage
                    maskSource: artMask
                    visible: artImage.source !== ""
                }
                
                Text {
                    anchors { centerIn: parent }
                    text: "♪"
                    font.pixelSize: 24
                    color: root.foregroundColor
                    visible: !artImage.source
                }
            }
        }
        
        Rectangle {
            visible: iconSource !== ""
            anchors { right: artItem.right; bottom: artItem.bottom; rightMargin: -4; bottomMargin: -4 }
            width: 22
            height: 22
            radius: 7
            color: ma.containsMouse && player?.canRaise ? root.surfaceColor : root.badgeColor
            border.color: root.badgeBorder
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }
            
            Image {
                anchors { fill: parent; margins: 3 }
                source: iconSource
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: ma.containsMouse && player?.canRaise ? 1.0 : 0.7
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
            
            MouseArea {
                id: ma
                anchors { fill: parent }
                hoverEnabled: true
                enabled: player?.canRaise ?? false
                cursorShape: player?.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: player?.raise()
            }
        }
    }
    
    component VolumeControl: Item {
        property MprisPlayer player
        
        width: 28
        height: 28
        visible: player?.volumeSupported ?? false
        
        Item {
            anchors { left: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 4 }
            width: hoverArea.containsMouse || sliderArea.containsMouse ? 70 : 0
            height: 28
            clip: true
            Behavior on width { SpringAnimation { spring: 4.5; damping: 0.5; mass: 1.0 } }
            
            Rectangle {
                id: track
                width: 60
                height: 4
                radius: 2
                color: root.surfaceColor
                anchors { verticalCenter: parent.verticalCenter }
                
                Rectangle {
                    width: parent.width * (player?.volume ?? 1)
                    height: parent.height
                    radius: parent.radius
                    color: root.volumeColor
                    Behavior on width { SpringAnimation { spring: 4.5; damping: 0.35; mass: 1.0 } }
                }
                
                MouseArea {
                    id: sliderArea
                    anchors { fill: track; margins: -10 }
                    hoverEnabled: true
                    onClicked: (mouse) => { if (player?.volumeSupported) player.volume = Math.max(0, Math.min(1, (mouse.x - 10) / track.width)) }
                    onPositionChanged: (mouse) => { if (pressed && player?.volumeSupported) player.volume = Math.max(0, Math.min(1, (mouse.x - 10) / track.width)) }
                    onWheel: (wheel) => { if (player?.volumeSupported) player.volume = Math.max(0, Math.min(1, player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))) }
                }
            }
        }
        
        Rectangle {
            anchors { fill: parent }
            radius: 6
            color: hoverArea.containsMouse ? root.hoverColor : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
            
            Text {
                anchors { centerIn: parent }
                text: (player?.volume ?? 0) === 0 ? "󰓄" : "󰓃"
                font.pixelSize: 14
                color: root.foregroundColor
            }
            
            MouseArea { id: hoverArea; anchors { fill: parent } hoverEnabled: true; acceptedButtons: Qt.NoButton }
        }
    }
    
    component MediaButton: Rectangle {
        property string text
        property bool enabled: true
        signal clicked()
        
        width: 28
        height: 28
        radius: 6
        color: ma.containsMouse ? root.hoverColor : "transparent"
        
        Text {
            anchors { centerIn: parent }
            text: parent.text
            color: parent.enabled ? root.foregroundColor : root.mutedColor
            font.pixelSize: 18
        }
        
        MouseArea { id: ma; anchors { fill: parent } hoverEnabled: true; enabled: parent.enabled; onClicked: parent.clicked() }
    }
}