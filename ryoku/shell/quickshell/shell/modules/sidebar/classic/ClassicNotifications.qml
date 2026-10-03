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
    signal requestClose()

    implicitHeight: root.compact
        ? Math.min(root.viewportHeight > 0 ? root.viewportHeight : 360 * root.s, 360 * root.s)
        : (root.viewportHeight > 0 ? root.viewportHeight : 560 * root.s)

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Menus.MenuNotifications {
        anchors.fill: parent
        anchors.margins: 12 * root.s
        s: root.s
        open: root.active
        onRequestClose: root.requestClose()
    }
}
