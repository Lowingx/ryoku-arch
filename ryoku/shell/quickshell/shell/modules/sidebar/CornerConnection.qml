pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui.Singletons
import shell.services

Rectangle {
    id: root
    required property string label
    required property string detail
    required property string glyph
    property real s: 1
    property bool connected: false
    property bool radioOn: false
    property bool available: true
    signal selected()
    signal toggleRequested()
    implicitHeight: 62 * s
    radius: Tokens.radius * s * 1.8
    color: connected ? Tokens.role("primaryContainer", Tokens.tint10) : Tokens.paperLift
    border.width: Tokens.border
    border.color: connected ? Qt.alpha(Tokens.sun, 0.16) : Tokens.lineSoft

    QQC.AbstractButton {
        id: main
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: radio.left
        hoverEnabled: true
        Accessible.name: root.label
        Accessible.description: root.detail
        onClicked: root.selected()
        background: Rectangle {
            radius: root.radius
            color: main.down ? Tokens.tint10 : main.hovered ? Tokens.tint5 : "transparent"
            border.width: Tokens.border
            border.color: main.visualFocus ? Tokens.sun : "transparent"
        }
        contentItem: Item {
            Text {
                id: icon
                x: 14 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph
                color: root.connected ? Tokens.role("onPrimaryContainer", Tokens.ink) : Tokens.inkDim
                font.family: "Material Symbols Rounded"
                font.pixelSize: 24 * root.s
                Accessible.ignored: true
            }
            Column {
                anchors.left: icon.right
                anchors.leftMargin: 10 * root.s
                anchors.right: parent.right
                anchors.rightMargin: 6 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * root.s
                Text {
                    width: parent.width
                    text: root.label
                    color: root.connected ? Tokens.role("onPrimaryContainer", Tokens.ink) : Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fBody * root.s
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: root.detail
                    color: root.connected ? Qt.alpha(Tokens.role("onPrimaryContainer", Tokens.ink), 0.78) : Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fMicro * root.s
                    elide: Text.ElideRight
                }
            }
        }
        QQC.ToolTip.visible: hovered
        QQC.ToolTip.text: root.detail
        QQC.ToolTip.delay: 700
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
    CornerButton {
        id: radio
        anchors.right: parent.right
        anchors.rightMargin: 8 * root.s
        anchors.verticalCenter: parent.verticalCenter
        s: root.s
        glyph: root.radioOn ? "toggle_on" : "toggle_off"
        subtle: true
        enabled: root.available
        Accessible.name: root.radioOn ? I18n.tr("Turn off %1").arg(root.label) : I18n.tr("Turn on %1").arg(root.label)
        onClicked: root.toggleRequested()
    }
}
