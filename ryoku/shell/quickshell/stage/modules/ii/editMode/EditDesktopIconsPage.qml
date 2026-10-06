import QtQuick
import QtQuick.Layouts
import stage.modules.common
import stage.modules.common.widgets
import stage.modules.ii.background.shortcuts

/**
 * Edit Mode's "Desktop icons" page: management, arrangement and appearance
 * for the shortcut layer on the monitor being edited.
 */
StyledFlickable {
    id: root
    required property string screenName

    readonly property var options: Config.options.background.desktopIcons
    readonly property var sources: DesktopShortcuts.otherScreens(root.screenName)
    readonly property var sorts: [
        { "key": "name", "symbol": "sort_by_alpha", "title": Translation.tr("Name") },
        { "key": "type", "symbol": "category", "title": Translation.tr("Type") },
        { "key": "added", "symbol": "schedule", "title": Translation.tr("Date added") },
        { "key": "used", "symbol": "trending_up", "title": Translation.tr("Most used") }
    ]

    contentHeight: column.implicitHeight
    clip: true

    ColumnLayout {
        id: column
        width: root.width
        spacing: 6

        EditPanelSectionLabel {
            Layout.topMargin: 0
            text: Translation.tr("Desktop")
        }
        EditPanelRow {
            Layout.fillWidth: true
            first: true
            last: false
            symbol: DesktopShortcuts.hidden ? "visibility_off" : "visibility"
            title: Translation.tr("Show icons")
            trailingKind: "switch"
            switchChecked: !DesktopShortcuts.hidden
            onActivated: DesktopShortcuts.setHidden(!DesktopShortcuts.hidden)
        }
        EditPanelRow {
            Layout.fillWidth: true
            readonly property bool locked: Config.options.background.desktopIconsLocked ?? false
            first: false
            last: false
            symbol: locked ? "lock" : "lock_open"
            title: Translation.tr("Lock icons")
            trailingKind: "switch"
            switchChecked: locked
            onActivated: Config.options.background.desktopIconsLocked = !locked
        }
        EditPanelRow {
            Layout.fillWidth: true
            first: false
            last: false
            symbol: "grid_on"
            title: Translation.tr("Align to grid")
            onActivated: DesktopShortcuts.alignToGrid(root.screenName)
        }
        EditPanelRow {
            Layout.fillWidth: true
            first: false
            last: false
            symbol: "auto_awesome_mosaic"
            title: Translation.tr("Auto-arrange")
            subtitle: Translation.tr("Drops snap to the nearest free cell")
            trailingKind: "switch"
            switchChecked: root.options.autoArrange
            onActivated: DesktopShortcuts.setAutoArrange(!root.options.autoArrange)
        }
        EditPanelRow {
            Layout.fillWidth: true
            first: false
            last: false
            symbol: "stacks"
            title: Translation.tr("Stacks")
            subtitle: Translation.tr("Group apps, folders and files by kind")
            trailingKind: "switch"
            switchChecked: root.options.stacks
            onActivated: DesktopShortcuts.setStacks(!root.options.stacks)
        }
        EditPanelRow {
            Layout.fillWidth: true
            first: false
            last: true
            symbol: "undo"
            title: Translation.tr("Undo icon change")
            enabled: DesktopShortcuts.canUndo
            onActivated: DesktopShortcuts.undo()
        }

        EditPanelSectionLabel {
            text: Translation.tr("Sort by")
        }
        Repeater {
            model: root.sorts
            delegate: EditPanelRow {
                required property var modelData
                required property int index
                readonly property bool current: root.options.sortBy === modelData.key
                Layout.fillWidth: true
                first: index === 0
                last: index === root.sorts.length - 1
                symbol: modelData.symbol
                title: modelData.title
                selected: current && root.options.keepSorted
                trailingKind: current ? "value" : "none"
                valueText: current ? (root.options.sortDescending ? "↓" : "↑") : ""
                onActivated: DesktopShortcuts.sortBy(root.screenName, modelData.key)
            }
        }
        EditPanelRow {
            Layout.fillWidth: true
            first: true
            last: true
            symbol: "autorenew"
            title: Translation.tr("Keep sorted")
            subtitle: Translation.tr("Re-sort when icons come and go")
            trailingKind: "switch"
            switchChecked: root.options.keepSorted
            onActivated: DesktopShortcuts.setKeepSorted(!root.options.keepSorted)
        }

        EditPanelSectionLabel {
            visible: root.sources.length > 0
            text: Translation.tr("Other screens")
        }
        Repeater {
            model: root.sources
            delegate: EditPanelRow {
                required property string modelData
                required property int index
                readonly property int iconCount: DesktopShortcuts.itemsFor(modelData).length
                Layout.fillWidth: true
                first: index === 0
                last: index === root.sources.length - 1
                symbol: DesktopShortcuts.isConnected(modelData) ? "monitor" : "desktop_access_disabled"
                title: Translation.tr("Bring icons from %1").arg(modelData)
                subtitle: DesktopShortcuts.isConnected(modelData)
                    ? Translation.tr("%1 icons").arg(String(iconCount))
                    : Translation.tr("%1 icons · disconnected").arg(String(iconCount))
                trailingKind: "add"
                onActivated: DesktopShortcuts.moveToScreen(modelData, root.screenName, null)
            }
        }

        EditPanelSectionLabel {
            text: Translation.tr("Appearance")
        }
        EditOptionChips {
            Layout.fillWidth: true
            label: Translation.tr("Icon size")
            currentValue: Config.options.background.desktopIconScale ?? 1
            options: [
                { "displayName": "0.75×", "value": 0.75 },
                { "displayName": "1×", "value": 1 },
                { "displayName": "1.25×", "value": 1.25 },
                { "displayName": "1.5×", "value": 1.5 },
                { "displayName": "1.75×", "value": 1.75 },
                { "displayName": "2×", "value": 2 },
            ]
            onSelected: value => Config.options.background.desktopIconScale = value
        }
        EditOptionChips {
            Layout.fillWidth: true
            label: Translation.tr("Spacing")
            currentValue: root.options.spacing
            options: [
                { "displayName": Translation.tr("Compact"), "value": "compact" },
                { "displayName": Translation.tr("Normal"), "value": "normal" },
                { "displayName": Translation.tr("Wide"), "value": "wide" },
            ]
            onSelected: value => Config.options.background.desktopIcons.spacing = value
        }
        EditOptionChips {
            Layout.fillWidth: true
            label: Translation.tr("Start from")
            currentValue: root.options.origin
            options: [
                { "displayName": Translation.tr("Top left"), "value": "topLeft", "icon": "north_west" },
                { "displayName": Translation.tr("Top right"), "value": "topRight", "icon": "north_east" },
                { "displayName": Translation.tr("Bottom left"), "value": "bottomLeft", "icon": "south_west" },
                { "displayName": Translation.tr("Bottom right"), "value": "bottomRight", "icon": "south_east" },
            ]
            onSelected: value => Config.options.background.desktopIcons.origin = value
        }
        EditOptionChips {
            Layout.fillWidth: true
            label: Translation.tr("Fill")
            currentValue: root.options.flow
            options: [
                { "displayName": Translation.tr("Columns"), "value": "columns", "icon": "view_column" },
                { "displayName": Translation.tr("Rows"), "value": "rows", "icon": "table_rows" },
            ]
            onSelected: value => Config.options.background.desktopIcons.flow = value
        }

        EditPanelRow {
            Layout.fillWidth: true
            Layout.topMargin: 4
            first: true
            last: false
            symbol: "fit_screen"
            title: Translation.tr("Keep clear of bar and dock")
            trailingKind: "switch"
            switchChecked: root.options.avoidPanels
            onActivated: Config.options.background.desktopIcons.avoidPanels = !root.options.avoidPanels
        }
        EditPanelRow {
            Layout.fillWidth: true
            first: false
            last: true
            symbol: "padding"
            title: Translation.tr("Edge margin")
            trailingKind: "stepper"
            valueText: `${root.options.margin} px`
            stepDownEnabled: root.options.margin > 0
            stepUpEnabled: root.options.margin < 120
            onStepUp: Config.options.background.desktopIcons.margin = Math.min(120, root.options.margin + 8)
            onStepDown: Config.options.background.desktopIcons.margin = Math.max(0, root.options.margin - 8)
        }

        EditOptionChips {
            Layout.fillWidth: true
            Layout.topMargin: 4
            label: Translation.tr("Labels")
            currentValue: root.options.labels
            options: [
                { "displayName": Translation.tr("Always"), "value": "always" },
                { "displayName": Translation.tr("On hover"), "value": "hover" },
                { "displayName": Translation.tr("Never"), "value": "never" },
            ]
            onSelected: value => Config.options.background.desktopIcons.labels = value
        }
        EditOptionChips {
            Layout.fillWidth: true
            visible: root.options.labels !== "never"
            label: Translation.tr("Label lines")
            currentValue: root.options.labelLines
            options: [
                { "displayName": Translation.tr("One"), "value": 1 },
                { "displayName": Translation.tr("Two"), "value": 2 },
            ]
            onSelected: value => Config.options.background.desktopIcons.labelLines = value
        }
        EditOptionChips {
            Layout.fillWidth: true
            visible: root.options.labels !== "never"
            label: Translation.tr("Label style")
            currentValue: root.options.labelStyle
            options: [
                { "displayName": Translation.tr("Auto"), "value": "auto" },
                { "displayName": Translation.tr("Shadow"), "value": "shadow" },
                { "displayName": Translation.tr("Pill"), "value": "pill" },
            ]
            onSelected: value => Config.options.background.desktopIcons.labelStyle = value
        }
        EditOptionChips {
            Layout.fillWidth: true
            label: Translation.tr("Icon background")
            currentValue: root.options.iconBackground
            options: [
                { "displayName": Translation.tr("None"), "value": "none" },
                { "displayName": Translation.tr("Translucent"), "value": "translucent" },
                { "displayName": Translation.tr("Circle"), "value": "circle", "icon": "circle" },
                { "displayName": Translation.tr("Squircle"), "value": "squircle", "icon": "square" },
            ]
            onSelected: value => Config.options.background.desktopIcons.iconBackground = value
        }

        EditPanelRow {
            Layout.fillWidth: true
            Layout.topMargin: 4
            first: true
            last: false
            symbol: "fiber_manual_record"
            title: Translation.tr("Running indicator")
            trailingKind: "switch"
            switchChecked: root.options.runningBadges
            onActivated: Config.options.background.desktopIcons.runningBadges = !root.options.runningBadges
        }
        EditPanelRow {
            Layout.fillWidth: true
            first: false
            last: true
            symbol: "notifications"
            title: Translation.tr("Notification count")
            trailingKind: "switch"
            switchChecked: root.options.notificationBadges
            onActivated: Config.options.background.desktopIcons.notificationBadges = !root.options.notificationBadges
        }
    }
}
