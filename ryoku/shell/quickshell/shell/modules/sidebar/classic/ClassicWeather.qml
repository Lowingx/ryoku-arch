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
        ? Math.min(root.viewportHeight > 0 ? root.viewportHeight : 320 * root.s, 320 * root.s)
        : (root.viewportHeight > 0 ? root.viewportHeight : Math.min(720 * root.s, Math.max(280 * root.s, weather.implicitHeight + 24 * root.s)))

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: weather.implicitHeight + 24 * root.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Menus.MenuWeather {
            id: weather
            x: 12 * root.s
            y: 12 * root.s
            width: Math.max(0, parent.width - 24 * root.s)
            s: root.s
            open: root.active
        }
    }
}
