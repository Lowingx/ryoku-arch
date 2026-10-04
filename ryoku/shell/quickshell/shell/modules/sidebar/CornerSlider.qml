pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root
    required property string label
    required property string glyph
    property real s: 1
    property real value: 0
    property real from: 0
    property bool muted: false
    property bool muteEnabled: false
    readonly property bool motionAllowed: !Tokens.reduceMotion && !Motion.reduce
    signal adjusted(real value)
    signal muteRequested()
    implicitHeight: 60 * s

    CornerButton {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: slider.verticalCenter
        s: root.s
        glyph: root.glyph
        subtle: true
        enabled: root.enabled && root.muteEnabled
        Accessible.name: root.muted ? I18n.tr("Unmute %1").arg(root.label) : I18n.tr("Mute %1").arg(root.label)
        checked: root.muted
        onClicked: root.muteRequested()
    }
    Text {
        anchors.left: slider.left
        anchors.top: parent.top
        text: root.label
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: Tokens.fMicro * root.s
    }
    Text {
        anchors.right: slider.right
        anchors.top: parent.top
        text: !root.enabled ? I18n.tr("Unavailable") : root.muted ? I18n.tr("Muted") : Math.round(root.value * 100) + "%"
        color: root.muted || !root.enabled ? Tokens.inkFaint : Tokens.ink
        font.family: Tokens.mono
        font.pixelSize: Tokens.fMicro * root.s
    }
    QQC.Slider {
        id: slider
        anchors.left: icon.right
        anchors.leftMargin: 4 * root.s
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 36 * root.s
        from: root.from
        to: 1
        stepSize: 0.01
        value: root.value
        Accessible.name: root.label
        onMoved: root.adjusted(value)
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 5 * root.s
            radius: height / 2
            color: Tokens.tint10
            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: parent.radius
                color: root.muted || !root.enabled ? Tokens.inkFaint : Tokens.sun
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 13 * root.s
            height: width
            radius: width / 2
            color: root.enabled ? Tokens.sun : Tokens.inkFaint
            border.width: 2 * root.s
            border.color: Tokens.paper
            scale: slider.pressed ? 1.25 : slider.hovered || slider.visualFocus ? 1.12 : 1
            Behavior on scale { enabled: root.motionAllowed; NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
}
