pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import Ryoku.Ui.Singletons
import "../../../components"

Item {
    id: root

    required property real s
    property alias icon: fader.icon
    property alias value: fader.value
    property alias valueLabel: fader.valueLabel
    property alias muted: fader.muted
    property alias peakNode: fader.peakNode
    property alias peakEnabled: fader.peakEnabled
    property bool lit: false
    property bool hasPage: false
    readonly property bool motionAllowed: !Motion.reduce && !Tokens.reduceMotion

    signal moved(real value)
    signal committed(real value)
    signal iconTapped()
    signal pageRequested()

    implicitHeight: 40 * root.s

    HFader {
        id: fader
        s: root.s
        anchors.left: parent.left
        anchors.right: pageButton.visible ? pageButton.left : parent.right
        anchors.rightMargin: pageButton.visible ? 6 * root.s : 0
        anchors.verticalCenter: parent.verticalCenter
        lit: root.lit
        onMoved: value => root.moved(value)
        onCommitted: value => root.committed(value)
        onIconTapped: root.iconTapped()
    }

    Rectangle {
        id: pageButton
        visible: root.hasPage
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 26 * root.s
        height: 30 * root.s
        radius: Math.max(2, (Theme.radiusWidget - 4) * root.s)
        color: pageTap.containsMouse
            ? Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.12)
            : "transparent"
        scale: pageTap.pressed ? 0.9 : 1
        Behavior on color {
            enabled: root.motionAllowed
            ColorAnimation { duration: Motion.crossfade; easing.type: Motion.crossfadeCurve }
        }
        Behavior on scale {
            enabled: root.motionAllowed
            NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
        }
        MaterialIcon {
            anchors.centerIn: parent
            text: "chevron_right"
            color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
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
