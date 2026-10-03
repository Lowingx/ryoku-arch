pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import "../../bar/popouts" as Popouts

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
    readonly property real contentHeight: captureLoader.item ? captureLoader.item.implicitHeight : 280 * root.s
    signal requestClose()

    implicitHeight: root.compact
        ? Math.min(root.viewportHeight > 0 ? root.viewportHeight : root.contentHeight, Math.max(260 * root.s, root.contentHeight))
        : (root.viewportHeight > 0 ? root.viewportHeight : Math.min(720 * root.s, Math.max(320 * root.s, root.contentHeight)))

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: root.contentHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Loader {
            id: captureLoader
            active: root.active
            width: parent.width
            sourceComponent: Component {
                Popouts.CapturePopout {
                    width: captureLoader.width
                    s: root.s * (root.compact ? 1 : 1.15)
                    open: root.active
                    skin: root.compact
                    onRequestClose: root.requestClose()
                }
            }
        }
    }
}
