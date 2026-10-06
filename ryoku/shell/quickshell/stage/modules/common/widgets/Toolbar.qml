import QtQuick
import QtQuick.Layouts
import stage.modules.common
import stage.modules.common.widgets

// The Stage toolbar is the same compact masthead slab as Ryogami's FilterBar:
// paper, one hairline, a six-pixel corner and restrained spacing.
Item {
    id: root

    property bool enableShadow: true
    property real padding: Appearance.sizes.space2
    property alias colBackground: background.color
    property alias spacing: toolbarLayout.spacing
    default property alias toolbarData: toolbarLayout.data
    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight
    width: implicitWidth
    height: implicitHeight
    property alias radius: background.radius

    Loader {
        active: root.enableShadow
        anchors.fill: background
        sourceComponent: StyledRectangularShadow {
            target: background
            anchors.fill: undefined
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: Appearance.withAlpha(Appearance.m3colors.m3surface, 0.94)
        implicitHeight: Appearance.sizes.toolbarHeight
        implicitWidth: toolbarLayout.implicitWidth + root.padding * 2
        radius: Appearance.rounding.small
        border.width: 1
        border.color: Appearance.withAlpha(Appearance.m3colors.m3outline, 0.5)

        RowLayout {
            id: toolbarLayout
            spacing: Appearance.sizes.space2
            anchors {
                fill: parent
                margins: root.padding
            }
        }
    }
}
