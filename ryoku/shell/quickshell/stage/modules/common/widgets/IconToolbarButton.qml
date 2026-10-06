import QtQuick
import QtQuick.Layouts
import stage.modules.common

ToolbarButton {
    id: iconBtn
    Layout.fillHeight: false
    implicitWidth: Appearance.sizes.controlHeight
    implicitHeight: Appearance.sizes.controlHeight
    buttonRadius: Appearance.rounding.small

    colBackground: "transparent"
    colBackgroundHover: Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.09)
    colBackgroundActive: Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.16)
    colBackgroundToggled: Appearance.m3colors.m3onSurface
    colBackgroundToggledHover: Appearance.m3colors.m3onSurface
    colBackgroundToggledActive: Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.9)
    colRipple: Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.16)
    colRippleToggled: Appearance.withAlpha(Appearance.m3colors.m3surface, 0.16)
    borderWidth: activeFocus ? 2 : 1
    borderColor: toggled ? Appearance.m3colors.m3onSurface
        : activeFocus ? Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.7)
        : hovered ? Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.24)
        : Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.18)

    property color colText: toggled
        ? Appearance.m3colors.m3surface
        : Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.82)
    property bool iconFill: toggled
    property real iconSize: 18

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        iconSize: iconBtn.iconSize
        text: iconBtn.text
        fill: iconBtn.iconFill ? 1 : 0
        color: iconBtn.colText
        animateChange: true
    }
}
