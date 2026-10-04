pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

Scope {
    id: root

    required property bool active
    required property var screen
    property string windowTitle: ""
    property string heading: ""
    property string subtitle: ""
    readonly property real s: Tokens.uiScaleFor(root.screen && root.screen.name ? root.screen.name : "")
    property alias body: contentHost.data
    signal requestClose()

    FloatingWindow {
        id: window

        screen: root.screen
        visible: root.active
        title: root.windowTitle
        color: Tokens.paper

        readonly property int screenWidth: window.screen && window.screen.width > 0 ? window.screen.width : 900
        readonly property int screenHeight: window.screen && window.screen.height > 0 ? window.screen.height : 760
        readonly property int fitWidth: Math.max(1, Math.min(Math.round(860 * root.s), window.screenWidth - Math.round(48 * root.s)))
        readonly property int fitHeight: Math.max(1, Math.min(Math.round(760 * root.s), window.screenHeight - Math.round(72 * root.s)))

        width: fitWidth
        height: fitHeight
        minimumSize: Qt.size(Math.min(Math.round(640 * root.s), fitWidth), Math.min(Math.round(520 * root.s), fitHeight))
        maximumSize: Qt.size(Math.max(1, window.screenWidth - Math.round(24 * root.s)), Math.max(1, window.screenHeight - Math.round(48 * root.s)))

        onClosed: if (root.active) root.requestClose()

        Rectangle {
            anchors.fill: parent
            color: Tokens.role("surface", Tokens.paper)

            Rectangle {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.round(76 * root.s)
                color: Tokens.role("surfaceContainerLow", Tokens.paperLift)

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Tokens.border
                    color: Tokens.line
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: closeButton.left
                    anchors.leftMargin: Tokens.s5 * root.s
                    anchors.rightMargin: Tokens.s4 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.s1 * root.s

                    Text {
                        width: parent.width
                        text: root.heading
                        color: Tokens.ink
                        font.family: Tokens.display
                        font.pixelSize: Tokens.fValue * root.s
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        visible: root.subtitle.length > 0
                        text: root.subtitle
                        color: Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                        elide: Text.ElideRight
                    }
                }

                CornerButton {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.s4 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    glyph: "close"
                    subtle: true
                    Accessible.name: I18n.tr("Close")
                    onClicked: root.requestClose()
                }
            }

            Item {
                id: contentHost
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.s5 * root.s
                clip: true
            }
        }

        Shortcut {
            enabled: root.active
            sequence: "Escape"
            context: Qt.WindowShortcut
            onActivated: root.requestClose()
        }
    }
}
