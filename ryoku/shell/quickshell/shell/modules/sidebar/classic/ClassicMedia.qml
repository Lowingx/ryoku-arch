pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import "../../bar/framebars/menus" as Menus

Item {
    id: root

    required property real s
    required property bool open
    required property real reveal
    required property bool tabActive
    property int index: 0
    property bool compact: false
    property real viewportHeight: 0
    property string page: ""
    readonly property bool active: root.open && root.tabActive
    readonly property real pad: (root.compact ? 8 : 12) * root.s
    signal requestClose()

    implicitHeight: Math.max(64 * root.s, content.implicitHeight + root.pad * 2)

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.pad
        spacing: 12 * root.s

        Menus.QsSection {
            visible: !root.compact
            width: parent.width
            height: visible ? implicitHeight * root.s : 0
            label: I18n.tr("Media")
        }

        Menus.MenuMedia {
            id: media
            width: parent.width
            s: root.s
            open: root.active
        }

        Text {
            visible: !media.visible
            width: parent.width
            topPadding: 24 * root.s
            bottomPadding: 24 * root.s
            horizontalAlignment: Text.AlignHCenter
            text: I18n.tr("Nothing is playing")
            color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
            font.family: Theme.fontPrimary
            font.pixelSize: Theme.fontSm * root.s
        }
    }
}
