import QtQuick
import QtQuick.Layouts
import stage.modules.common

ToolbarButton {
    id: iconBtn
    required property string iconText
    property bool compact: false
    property real maximumLabelWidth: 140
    property color colText: toggled
        ? Appearance.m3colors.m3surface
        : Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.82)

    Layout.fillHeight: false
    implicitHeight: Appearance.sizes.controlHeight
    implicitWidth: Math.max(implicitHeight,
        contentRow.implicitWidth + horizontalPadding * 2)
    horizontalPadding: Appearance.sizes.space3
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

    contentItem: Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: label.visible && icon.visible ? Appearance.sizes.space1 : 0

        MaterialSymbol {
            id: icon
            visible: iconBtn.iconText.length > 0
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            iconSize: 18
            text: iconBtn.iconText
            color: iconBtn.colText
        }
        StyledText {
            id: label
            visible: !iconBtn.compact && iconBtn.text.length > 0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, iconBtn.maximumLabelWidth)
            color: iconBtn.colText
            text: iconBtn.text
            elide: Text.ElideRight
            font.family: Appearance.font.family.main
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Bold
        }
    }
}
