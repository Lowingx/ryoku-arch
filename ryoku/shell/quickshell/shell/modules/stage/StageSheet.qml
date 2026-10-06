pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC
import "../desktop"
import "../desktop/Singletons"
import Ryoku.Ui.Singletons

// A Stage Editor catalogue page built from a sectioned options column: the
// column's MenuSection headers become the page's tabs, and the page shows one
// section's band at a time, scrolled on its own. The same slicing the widget
// inspector does for a widget's Customize sheet, sized to the drawer, so one
// options file serves both and a catalogue never grows a second copy of it.
Item {
    id: sheet

    // The options column; its MenuSection children (ryoSection) name the tabs.
    property Component content: null
    // Rows above the tabs that every tab shares (an on/off switch, a status).
    default property alias header: headerHost.data

    property int tab: 0
    readonly property Item body: loader.item

    property var sections: []
    function rescan() {
        const arr = [];
        const col = loader.item;
        if (col && col.children) {
            for (let i = 0; i < col.children.length; i++) {
                const c = col.children[i];
                if (c && c.ryoSection === true && String(c.label || "").length > 0)
                    arr.push(c);
            }
        }
        sheet.sections = arr;
    }
    // A section whose header hides (a look family without it) drops its tab.
    readonly property var shown: sheet.sections.filter(s => s.visible)
    readonly property Item current: sheet.shown.length > 0
        ? sheet.shown[Math.max(0, Math.min(sheet.tab, sheet.shown.length - 1))] : null
    readonly property real bandTop: sheet.current ? sheet.current.y + sheet.current.height : 0
    readonly property real bandBottom: {
        if (!sheet.current || !loader.item)
            return 0;
        const i = sheet.sections.indexOf(sheet.current);
        for (let j = i + 1; j < sheet.sections.length; j++)
            if (sheet.sections[j].visible)
                return sheet.sections[j].y;
        return loader.item.implicitHeight;
    }
    onCurrentChanged: flick.contentY = 0

    Column {
        id: top
        width: parent.width
        spacing: 7

        Column {
            id: headerHost
            width: parent.width
            spacing: 4
        }

        Flow {
            id: tabs
            width: parent.width
            spacing: 4
            visible: sheet.shown.length > 1
            Repeater {
                model: sheet.shown
                delegate: MenuChip {
                    required property var modelData
                    required property int index
                    minWidth: Math.min(64, tabs.width)
                    width: Math.min(implicitWidth, tabs.width)
                    label: modelData.label
                    selected: sheet.current === modelData
                    onClicked: sheet.tab = index
                }
            }
        }
    }

    Flickable {
        id: flick
        anchors.top: top.bottom
        anchors.topMargin: 9
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        contentWidth: Math.max(0, width - 13)
        contentHeight: Math.max(0, sheet.bandBottom - sheet.bandTop)
        boundsBehavior: Flickable.StopAtBounds

        QQC.ScrollBar.vertical: QQC.ScrollBar {
            id: bandBar
            width: 7
            policy: QQC.ScrollBar.AsNeeded

            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: bandBar.pressed ? Theme.ink
                    : Qt.rgba(Theme.ink.r, Theme.ink.g, Theme.ink.b, 0.58)
                opacity: bandBar.active ? 1 : 0.72
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on color { ColorAnimation { duration: 180 } }
            }

            background: Item {
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: parent.height
                    color: Qt.rgba(Theme.ink.r, Theme.ink.g, Theme.ink.b, 0.18)
                }
            }
        }

        Item {
            width: flick.contentWidth
            height: flick.contentHeight
            clip: true

            Loader {
                id: loader
                width: parent.width
                y: -sheet.bandTop
                sourceComponent: sheet.content
                onLoaded: sheet.rescan()
            }
        }
    }
}
