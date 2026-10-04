pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons
import shell.services

Rectangle {
    id: root

    required property real s
    required property bool active
    signal openActivity()

    readonly property var topApp: root.active && ScreenTime.topApps.length > 0 ? ScreenTime.topApps[0] : null

    implicitHeight: Math.round(46 * root.s)
    radius: Tokens.radius * root.s
    color: Tokens.role("surfaceContainerLow", Tokens.tint5)
    border.width: Tokens.border
    border.color: Tokens.lineSoft

    Row {
        anchors.left: parent.left
        anchors.right: action.left
        anchors.leftMargin: Tokens.s3 * root.s
        anchors.rightMargin: Tokens.s3 * root.s
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.s4 * root.s

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text {
                text: I18n.tr("Active today")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fTiny * root.s
            }
            Text {
                text: ScreenTime.fmtDuration(root.active ? ScreenTime.activeToday : 0)
                color: Tokens.ink
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * root.s
                font.weight: Font.DemiBold
                font.features: ({ "tnum": 1 })
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.border
            height: Math.round(24 * root.s)
            color: Tokens.lineSoft
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - x)
            spacing: 0
            Text {
                width: parent.width
                text: root.topApp ? I18n.tr("Most used") : I18n.tr("Screen time")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fTiny * root.s
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.topApp ? root.topApp.name + " · " + ScreenTime.fmtDuration(root.topApp.seconds)
                    : I18n.tr("Usage builds as you work")
                color: Tokens.ink
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * root.s
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }

    CornerButton {
        id: action
        anchors.right: parent.right
        anchors.rightMargin: Tokens.s2 * root.s
        anchors.verticalCenter: parent.verticalCenter
        s: root.s
        text: I18n.tr("View activity")
        glyph: "arrow_forward"
        subtle: true
        onClicked: root.openActivity()
    }
}
