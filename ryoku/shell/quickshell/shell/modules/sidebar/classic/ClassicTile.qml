pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import Ryoku.Ui.Singletons
import "../../../components"

Item {
    id: root

    required property real s
    property string icon: "circle"
    property string label: ""
    property string sub: ""
    property bool on: false
    property bool available: true
    property bool hasPage: false
    property string pageTip: ""
    readonly property bool motionAllowed: !Motion.reduce && !Tokens.reduceMotion
    readonly property color effectiveBackground: Theme.blend(
        root.on ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.20)
                : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.06),
        Theme.effectiveSurface)

    signal toggled()
    signal pageRequested()

    implicitHeight: 64 * root.s

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusWidget * root.s
        color: root.on
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, face.containsMouse ? 0.26 : 0.20)
            : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, face.containsMouse ? 0.10 : 0.06)
        border.width: Theme.borderWidth
        border.color: root.on
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.55)
            : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.30)
        Behavior on color {
            enabled: root.motionAllowed
            ColorAnimation { duration: Motion.crossfade; easing.type: Motion.crossfadeCurve }
        }
        SumiEdge {}
    }

    MouseArea {
        id: face
        anchors.fill: parent
        anchors.rightMargin: root.hasPage ? 34 * root.s : 0
        hoverEnabled: true
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.available) root.toggled()
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12 * root.s
        anchors.rightMargin: (root.hasPage ? 34 : 12) * root.s
        spacing: 10 * root.s
        opacity: root.available ? 1 : 0.45
        Behavior on opacity {
            enabled: root.motionAllowed
            NumberAnimation { duration: Motion.crossfade; easing.type: Motion.crossfadeCurve }
        }

        Rectangle {
            id: iconDisc
            anchors.verticalCenter: parent.verticalCenter
            width: 34 * root.s
            height: width
            radius: width / 2
            scale: face.pressed ? 0.86 : 1
            color: root.on ? Theme.primary
                : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.10)
            Behavior on scale {
                enabled: root.motionAllowed
                NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
            }
            Behavior on color {
                enabled: root.motionAllowed
                ColorAnimation { duration: Motion.crossfade; easing.type: Motion.crossfadeCurve }
            }
            MaterialIcon {
                anchors.centerIn: parent
                text: root.icon
                fill: root.on ? 1 : 0
                color: root.on ? Theme.inkOn(Theme.primary, Theme.onPrimary, 3.0)
                    : Theme.inkOn(root.effectiveBackground, Theme.onSurface, 3.0)
                font.pixelSize: 18 * root.s
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - iconDisc.width - parent.spacing
            spacing: root.s
            Text {
                width: parent.width
                text: I18n.tr(root.label)
                color: Theme.inkOn(root.effectiveBackground, Theme.onSurface)
                font.family: Theme.fontPrimary
                font.pixelSize: Theme.fontSm * root.s
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                visible: text.length > 0
                text: root.sub
                color: Theme.inkOn(root.effectiveBackground, Theme.onSurfaceVariant, 3.0)
                font.family: Theme.fontPrimary
                font.pixelSize: (Theme.fontSm - 2) * root.s
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        visible: root.hasPage
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 6 * root.s
        width: 26 * root.s
        radius: Math.max(2, (Theme.radiusWidget - 4) * root.s)
        color: pageTap.containsMouse
            ? Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.12)
            : "transparent"
        scale: pageTap.pressed ? 0.9 : 1
        Behavior on scale {
            enabled: root.motionAllowed
            NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
        }
        MaterialIcon {
            anchors.centerIn: parent
            text: "chevron_right"
            color: Theme.inkOn(root.effectiveBackground, Theme.onSurfaceVariant, 3.0)
            font.pixelSize: 16 * root.s
        }
        MouseArea {
            id: pageTap
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pageRequested()
        }
    }
}
