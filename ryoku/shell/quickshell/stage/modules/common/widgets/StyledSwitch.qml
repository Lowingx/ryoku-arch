import stage.modules.common
import QtQuick
import QtQuick.Controls

// The Stage control follows Ryogami's compact bone-and-ink switch rather than
// Qt's Material palette. The public colour properties stay available for the
// few callers that need to tune a disabled or destructive state.
Switch {
    id: root
    hoverEnabled: true

    property real sizeScale: 1
    implicitWidth: 44 * root.sizeScale
    implicitHeight: 24 * root.sizeScale

    property color activeColor: Appearance.m3colors.m3onSurface
    property color inactiveColor: Appearance.withAlpha(Appearance.m3colors.m3onSurface,
        root.hovered ? 0.12 : 0.05)
    property color activeThumbColor: Appearance.m3colors.m3surface
    property color inactiveThumbColor: Appearance.withAlpha(
        Appearance.m3colors.m3onSurface, 0.7)

    readonly property real inset: 3 * root.sizeScale
    readonly property real knobSize: root.height - root.inset * 2
    readonly property bool isPressed: root.pressed || root.down

    scale: root.isPressed && root.enabled ? 0.95 : 1
    Behavior on scale {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Easing.OutQuad
        }
    }

    PointingHandInteraction {}

    background: Rectangle {
        width: root.width
        height: root.height
        radius: height / 2
        color: root.checked ? root.activeColor : root.inactiveColor
        border.width: 1
        border.color: root.checked ? "transparent"
            : Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.3)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    indicator: Rectangle {
        width: root.knobSize
        height: root.knobSize
        radius: height / 2
        y: root.inset
        x: root.checked ? root.width - width - root.inset : root.inset
        color: root.checked ? root.activeThumbColor : root.inactiveThumbColor

        Behavior on x {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Easing.OutBack
                easing.overshoot: 2
            }
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}
