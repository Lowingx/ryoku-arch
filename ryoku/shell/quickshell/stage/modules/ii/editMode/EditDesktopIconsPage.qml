import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons
import stage.modules.common
import stage.modules.common.widgets
import stage.modules.ii.background.shortcuts

StyledFlickable {
    id: root
    required property string screenName

    readonly property var options: Config.options.background.desktopIcons
    readonly property var sources: DesktopShortcuts.otherScreens(root.screenName)

    contentWidth: width
    contentHeight: content.implicitHeight + Tokens.s4
    clip: true

    Column {
        id: content
        x: Tokens.s1
        width: Math.max(0, root.width - Tokens.s2)
        spacing: Tokens.s4

        Section {
            width: parent.width
            title: I18n.tr("DESKTOP")

            SettingCard {
                width: parent.width
                title: I18n.tr("PRESENCE")
                kana: "卓上"
                collapsible: false

                SettingRow {
                    width: parent.width
                    label: "Show icons"
                    desc: "Keep shortcuts visible on this display"
                    controlWidth: showIcons.implicitWidth
                    Sw {
                        id: showIcons
                        anchors.centerIn: parent
                        on: !DesktopShortcuts.hidden
                        onToggled: DesktopShortcuts.setHidden(v)
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Lock positions"
                    desc: "Clicks still work; dragging stays put"
                    controlWidth: lockIcons.implicitWidth
                    Sw {
                        id: lockIcons
                        anchors.centerIn: parent
                        on: Config.options.background.desktopIconsLocked ?? false
                        onToggled: Config.options.background.desktopIconsLocked = v
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Align to grid"
                    desc: "Set every icon on the nearest clear cell"
                    controlWidth: alignButton.implicitWidth
                    Btn {
                        id: alignButton
                        anchors.centerIn: parent
                        compact: true
                        text: I18n.tr("ALIGN")
                        onAct: DesktopShortcuts.alignToGrid(root.screenName)
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Auto-arrange"
                    desc: "Drops snap to the nearest free cell"
                    controlWidth: autoArrange.implicitWidth
                    Sw {
                        id: autoArrange
                        anchors.centerIn: parent
                        on: root.options.autoArrange
                        onToggled: DesktopShortcuts.setAutoArrange(v)
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Stacks"
                    desc: "Collect apps, folders and files by kind"
                    controlWidth: stacks.implicitWidth
                    Sw {
                        id: stacks
                        anchors.centerIn: parent
                        on: root.options.stacks
                        onToggled: DesktopShortcuts.setStacks(v)
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Undo icon change"
                    desc: DesktopShortcuts.canUndo ? "Restore the previous arrangement" : "No changes to undo"
                    controlWidth: undoButton.implicitWidth
                    Btn {
                        id: undoButton
                        anchors.centerIn: parent
                        compact: true
                        armed: DesktopShortcuts.canUndo
                        text: I18n.tr("UNDO")
                        onAct: DesktopShortcuts.undo()
                    }
                }
            }
        }

        Section {
            width: parent.width
            title: I18n.tr("ORDER")

            SettingCard {
                width: parent.width
                title: I18n.tr("ARRANGEMENT")
                collapsible: false

                SettingRow {
                    width: parent.width
                    label: "Sort by"
                    desc: root.options.sortDescending ? "Descending order" : "Ascending order"
                    block: true
                    Seg {
                        width: parent.width
                        options: ["name", "type", "added", "used"]
                        labels: ({
                            "name": I18n.tr("Name"),
                            "type": I18n.tr("Type"),
                            "added": I18n.tr("Added"),
                            "used": I18n.tr("Used")
                        })
                        current: root.options.sortBy
                        onChose: key => DesktopShortcuts.sortBy(root.screenName, key)
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Keep sorted"
                    desc: "Re-sort when icons come and go"
                    controlWidth: keepSorted.implicitWidth
                    Sw {
                        id: keepSorted
                        anchors.centerIn: parent
                        on: root.options.keepSorted
                        onToggled: DesktopShortcuts.setKeepSorted(v)
                    }
                }
            }
        }

        Section {
            width: parent.width
            title: I18n.tr("APPEARANCE")

            SettingCard {
                width: parent.width
                title: I18n.tr("GRID")
                collapsible: false

                SettingRow {
                    width: parent.width
                    label: "Icon size"
                    desc: "Scales icons and their grid cells together"
                    value: `${DesktopShortcuts.iconScale}×`
                    block: true
                    Chips {
                        width: parent.width
                        options: ["0.75", "1", "1.25", "1.5", "1.75", "2"]
                        labels: ({
                            "0.75": "0.75×", "1": "1×", "1.25": "1.25×",
                            "1.5": "1.5×", "1.75": "1.75×", "2": "2×"
                        })
                        current: String(DesktopShortcuts.iconScale)
                        onChose: key => Config.options.background.desktopIconScale = Number(key)
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Spacing"
                    block: true
                    Seg {
                        width: parent.width
                        options: ["compact", "normal", "wide"]
                        labels: ({
                            "compact": I18n.tr("Compact"),
                            "normal": I18n.tr("Normal"),
                            "wide": I18n.tr("Wide")
                        })
                        current: root.options.spacing
                        onChose: key => root.options.spacing = key
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Start from"
                    block: true
                    Seg {
                        width: parent.width
                        options: ["topLeft", "topRight", "bottomLeft", "bottomRight"]
                        labels: ({
                            "topLeft": I18n.tr("Top left"),
                            "topRight": I18n.tr("Top right"),
                            "bottomLeft": I18n.tr("Bottom left"),
                            "bottomRight": I18n.tr("Bottom right")
                        })
                        current: root.options.origin
                        onChose: key => root.options.origin = key
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Fill direction"
                    block: true
                    Seg {
                        width: parent.width
                        options: ["columns", "rows"]
                        labels: ({ "columns": I18n.tr("Columns"), "rows": I18n.tr("Rows") })
                        current: root.options.flow
                        onChose: key => root.options.flow = key
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Keep clear of panels"
                    desc: "Leave room for the bar and dock"
                    controlWidth: avoidPanels.implicitWidth
                    Sw {
                        id: avoidPanels
                        anchors.centerIn: parent
                        on: root.options.avoidPanels
                        onToggled: root.options.avoidPanels = v
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Edge margin"
                    value: String(root.options.margin)
                    unit: "px"
                    controlWidth: marginStep.implicitWidth
                    Step {
                        id: marginStep
                        anchors.centerIn: parent
                        value: root.options.margin
                        from: 0
                        to: 120
                        stepBy: 8
                        onModified: v => root.options.margin = v
                    }
                }
            }

            SettingCard {
                width: parent.width
                title: I18n.tr("LABELS & MARKS")
                collapsible: false

                SettingRow {
                    width: parent.width
                    label: "Labels"
                    block: true
                    Seg {
                        width: parent.width
                        options: ["always", "hover", "never"]
                        labels: ({
                            "always": I18n.tr("Always"),
                            "hover": I18n.tr("On hover"),
                            "never": I18n.tr("Never")
                        })
                        current: root.options.labels
                        onChose: key => root.options.labels = key
                    }
                }
                SettingRow {
                    width: parent.width
                    visible: root.options.labels !== "never"
                    divider: true
                    label: "Label lines"
                    block: true
                    Seg {
                        width: parent.width
                        options: ["1", "2"]
                        labels: ({ "1": I18n.tr("One"), "2": I18n.tr("Two") })
                        current: String(root.options.labelLines)
                        onChose: key => root.options.labelLines = Number(key)
                    }
                }
                SettingRow {
                    width: parent.width
                    visible: root.options.labels !== "never"
                    divider: true
                    label: "Label style"
                    block: true
                    Seg {
                        width: parent.width
                        options: ["auto", "shadow", "pill"]
                        labels: ({
                            "auto": I18n.tr("Auto"),
                            "shadow": I18n.tr("Shadow"),
                            "pill": I18n.tr("Pill")
                        })
                        current: root.options.labelStyle
                        onChose: key => root.options.labelStyle = key
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Icon background"
                    block: true
                    Seg {
                        width: parent.width
                        options: ["none", "translucent", "circle", "squircle"]
                        labels: ({
                            "none": I18n.tr("None"),
                            "translucent": I18n.tr("Soft"),
                            "circle": I18n.tr("Circle"),
                            "squircle": I18n.tr("Square")
                        })
                        current: root.options.iconBackground
                        onChose: key => root.options.iconBackground = key
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Running indicator"
                    controlWidth: runningBadge.implicitWidth
                    Sw {
                        id: runningBadge
                        anchors.centerIn: parent
                        on: root.options.runningBadges
                        onToggled: root.options.runningBadges = v
                    }
                }
                SettingRow {
                    width: parent.width
                    divider: true
                    label: "Notification count"
                    controlWidth: notificationBadge.implicitWidth
                    Sw {
                        id: notificationBadge
                        anchors.centerIn: parent
                        on: root.options.notificationBadges
                        onToggled: root.options.notificationBadges = v
                    }
                }
            }
        }

        Section {
            width: parent.width
            visible: root.sources.length > 0
            title: I18n.tr("OTHER DISPLAYS")

            SettingCard {
                width: parent.width
                title: I18n.tr("BRING ICONS HERE")
                collapsible: false

                Repeater {
                    model: root.sources
                    delegate: SettingRow {
                        required property string modelData
                        required property int index
                        readonly property int iconCount: DesktopShortcuts.itemsFor(modelData).length
                        width: parent.width
                        divider: index > 0
                        label: modelData
                        desc: DesktopShortcuts.isConnected(modelData)
                            ? I18n.tr("%1 icons").arg(String(iconCount))
                            : I18n.tr("%1 icons, display disconnected").arg(String(iconCount))
                        controlWidth: bringButton.implicitWidth
                        Btn {
                            id: bringButton
                            anchors.centerIn: parent
                            compact: true
                            text: I18n.tr("BRING")
                            onAct: DesktopShortcuts.moveToScreen(modelData, root.screenName, null)
                        }
                    }
                }
            }
        }
    }
}
