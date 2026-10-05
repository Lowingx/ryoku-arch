import QtQuick
import RashinApp

// The app's one navigation: a glyph rail that grows labels when open. The
// active row carries a sliding bone marker; the seal stays vermillion, the
// one fixed colour. Collapse state is a UI preference, remembered.
Rectangle {
    id: rail

    required property var pages
    required property string page
    signal navigated(string id)

    width: collapsed ? 60 : 180
    color: Theme.surfaceLow
    readonly property bool collapsed: Preferences.sidebarCollapsed
    Behavior on width {
        enabled: !Theme.reduceMotion
        NumberAnimation { duration: Theme.move; easing.type: Easing.OutQuint }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Theme.s4
        spacing: 0

        // The seal: 羅, the dashboard's mark, on vermillion.
        Rectangle {
            id: seal
            anchors.horizontalCenter: parent.horizontalCenter
            width: 34
            height: width
            radius: 10
            color: Theme.primary
            Text {
                anchors.centerIn: parent
                text: "羅"
                color: "white"
                font.pixelSize: 19
                font.family: "Noto Sans CJK JP, Sans Serif"
            }
            scale: sealHover.hovered ? 1.06 : 1
            Behavior on scale {
                enabled: !Theme.reduceMotion
                NumberAnimation { duration: Theme.swap; easing.type: Easing.OutBack }
            }
            HoverHandler { id: sealHover }
            TapHandler { onTapped: Preferences.sidebarCollapsed = !Preferences.sidebarCollapsed }
        }

        Item { width: 1; height: Theme.s5 }

        Repeater {
            model: rail.pages
            delegate: Item {
                id: nav
                required property var modelData
                width: rail.width
                height: 46
                readonly property bool current: rail.page === modelData.id
                property bool hovered: hh.hovered

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.s2
                    anchors.rightMargin: Theme.s2
                    radius: Theme.radiusSm
                    color: nav.current ? Theme.tint16 : nav.hovered ? Theme.tint5 : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.snap } }
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: nav.current ? 20 : 0
                    radius: 2
                    color: Theme.bone
                    Behavior on height {
                        enabled: !Theme.reduceMotion
                        NumberAnimation { duration: Theme.move; easing.type: Easing.OutQuint }
                    }
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.s2 + 12
                    spacing: Theme.s3
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: nav.modelData.glyph
                        color: nav.current ? Theme.ink : Theme.inkMuted
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 21
                        Behavior on color { ColorAnimation { duration: Theme.swap } }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !rail.collapsed
                        opacity: rail.collapsed ? 0 : 1
                        text: nav.modelData.label
                        color: nav.current ? Theme.ink : Theme.inkDim
                        font.family: Theme.ui
                        font.pixelSize: Theme.fSmallPx
                        font.weight: nav.current ? Font.DemiBold : Font.Normal
                        Behavior on opacity { NumberAnimation { duration: Theme.swap } }
                    }
                }
                HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: rail.navigated(nav.modelData.id) }
            }
        }

        Item { width: 1; height: Theme.s4 }

        IconBtn {
            anchors.horizontalCenter: parent.horizontalCenter
            glyph: rail.collapsed ? "chevron_right" : "chevron_left"
            onAct: Preferences.sidebarCollapsed = !rail.collapsed
        }
    }
}
