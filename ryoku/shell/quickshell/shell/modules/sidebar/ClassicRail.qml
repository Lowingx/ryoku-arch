pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root
    required property string side
    required property real s
    property var tabs: []
    property string selectedTab: ""
    readonly property bool controls: side === "left"
    readonly property bool motionAllowed: !Motion.reduce && !Tokens.reduceMotion
    readonly property real minimumHeight: tabColumn.implicitHeight + utilityColumn.implicitHeight + 32 * s
    readonly property var utilities: controls ? [
        { glyph: "search", label: I18n.tr("Lens search"), command: "ryoku-cmd-google-lens" },
        { glyph: "document_scanner", label: I18n.tr("Copy text on screen"), command: "ryoku-cmd-ocr" },
        { glyph: "qr_code_scanner", label: I18n.tr("Scan a QR code"), command: "ryoku-cmd-qr-scan" },
        { glyph: "settings", label: I18n.tr("Customize sidebars in Ryoku Hub"), command: "settings" },
        { glyph: "colorize", label: I18n.tr("Pick a color"), command: "ryoku-cmd-color-picker" },
        { glyph: "close", label: I18n.tr("Close sidebar"), command: "close" }
    ] : [
        { glyph: "settings", label: I18n.tr("Customize sidebars in Ryoku Hub"), command: "settings" },
        { glyph: "close", label: I18n.tr("Close sidebar"), command: "close" }
    ]

    signal tabActivated(int index)
    signal settingsRequested()
    signal closeRequested()

    implicitWidth: (controls ? 44 : 50) * s
    width: implicitWidth

    Rectangle {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: root.controls ? 0 : 12 * root.s; bottomMargin: root.controls ? 0 : 12 * root.s }
        width: Tokens.border
        color: Qt.alpha(Theme.outline, root.controls ? 0.20 : 0.35)
    }

    QQC.ScrollView {
        id: tabScroll
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: (root.controls ? 10 : 14) * root.s }
        height: Math.max(0, utilityScroll.y - y - 10 * root.s)
        clip: true
        contentWidth: availableWidth
        QQC.ScrollBar.horizontal.policy: QQC.ScrollBar.AlwaysOff
        QQC.ScrollBar.vertical.policy: QQC.ScrollBar.AsNeeded

        Column {
            id: tabColumn
            width: tabScroll.availableWidth
            spacing: (root.controls ? 6 : 4) * root.s
            Repeater {
                model: root.tabs
                delegate: QQC.AbstractButton {
                    id: tab
                    required property var modelData
                    required property int index
                    readonly property bool selected: root.selectedTab === modelData.id
                    width: (root.controls ? 36 : 44) * root.s
                    height: (root.controls ? 36 : 48) * root.s
                    x: (tabColumn.width - width) / 2
                    text: I18n.tr(modelData.label)
                    hoverEnabled: true
                    Accessible.role: Accessible.PageTab
                    Accessible.name: text
                    Accessible.selected: selected
                    onClicked: root.tabActivated(index)
                    Keys.onUpPressed: root.tabActivated((index + root.tabs.length - 1) % root.tabs.length)
                    Keys.onDownPressed: root.tabActivated((index + 1) % root.tabs.length)
                    scale: root.motionAllowed && down ? 0.90 : 1
                    Behavior on scale { enabled: root.motionAllowed; NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
                    background: Item {
                        Rectangle {
                            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                            width: 36 * root.s; height: width; radius: width / 2
                            color: tab.selected ? Theme.primary : tab.hovered ? Qt.alpha(Theme.onSurface, 0.09) : "transparent"
                            border.width: tab.visualFocus ? Tokens.border : 0
                            border.color: Theme.primary
                            Behavior on color { enabled: root.motionAllowed; ColorAnimation { duration: Tokens.snap } }
                            Text {
                                anchors.centerIn: parent
                                text: tab.modelData.glyph
                                color: tab.selected ? Theme.inkOn(Theme.primary, Theme.onPrimary)
                                    : Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: (root.controls ? 20 : 15) * root.s
                                Accessible.ignored: true
                            }
                        }
                    }
                    contentItem: Text {
                        visible: !root.controls
                        text: tab.text
                        color: Theme.inkOn(Theme.effectiveSurface, tab.selected ? Theme.onSurface : Theme.onSurfaceVariant, 3.0)
                        font.family: Theme.fontPrimary
                        font.pixelSize: 7 * root.s
                        font.weight: tab.selected ? Font.DemiBold : Font.Normal
                        verticalAlignment: Text.AlignBottom
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    QQC.ToolTip.visible: hovered
                    QQC.ToolTip.text: text
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }

    QQC.ScrollView {
        id: utilityScroll
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 10 * root.s }
        height: Math.min(utilityColumn.implicitHeight, Math.max(0, root.height / 2 - 10 * root.s))
        contentWidth: availableWidth
        clip: true
        QQC.ScrollBar.horizontal.policy: QQC.ScrollBar.AlwaysOff
        QQC.ScrollBar.vertical.policy: QQC.ScrollBar.AsNeeded
        Column {
            id: utilityColumn
            width: utilityScroll.availableWidth
            spacing: 6 * root.s
            Repeater {
                model: root.utilities
                delegate: QQC.AbstractButton {
                    id: utility
                    required property var modelData
                    width: 34 * root.s; height: width
                    x: (utilityColumn.width - width) / 2
                    hoverEnabled: true
                    Accessible.name: modelData.label
                    onClicked: {
                        if (modelData.command === "settings") root.settingsRequested();
                        else if (modelData.command === "close") root.closeRequested();
                        else { root.closeRequested(); Spawn.run([modelData.command]); }
                    }
                    scale: root.motionAllowed && down ? 0.90 : 1
                    Behavior on scale { enabled: root.motionAllowed; NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
                    background: Rectangle {
                        radius: width / 2
                        color: utility.hovered ? Qt.alpha(Theme.onSurface, 0.09) : "transparent"
                        border.width: utility.visualFocus ? Tokens.border : 0
                        border.color: Theme.primary
                        Behavior on color { enabled: root.motionAllowed; ColorAnimation { duration: Tokens.snap } }
                    }
                    contentItem: Text {
                        text: utility.modelData.glyph
                        color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 17 * root.s
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    QQC.ToolTip.visible: hovered
                    QQC.ToolTip.text: modelData.label
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }
}
