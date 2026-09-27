pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import inir
import inir.services
import inir.modules.common
import inir.modules.iris.components

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panel
        required property var modelData

        readonly property bool desktopMenuOpen: desktopMenu.active

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        // Sits above ryogami's wallpaper surface but paints nothing itself, so
        // the wallpaper shows through. The desktop-widget canvas (Background.qml)
        // replaces this once widgets are enabled.
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:iris-background"
        // Bare-desktop actions are shell actions, not widget actions, so keep the
        // surface pointer-capable and only request keyboard focus while its menu
        // is actually open.
        WlrLayershell.keyboardFocus: panel.desktopMenuOpen
            ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            z: 20
            acceptedButtons: Qt.RightButton | Qt.LeftButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    if (desktopMenu.active) desktopMenu.close()
                    return
                }
                desktopMenuAnchor.x = mouse.x
                desktopMenuAnchor.y = mouse.y
                desktopMenu.requestOpen()
            }
        }

        Item {
            id: desktopMenuAnchor
            z: 21
            width: 1
            height: 1
        }

        // The iRiS desktop menu stays available even when the heavy widget canvas
        // is unloaded. The Widgets tile enables that module before entering edit
        // mode instead of opening an editor with no canvas behind it.
        IrisDesktopMenu {
            id: desktopMenu
            z: 22
            anchorItem: desktopMenuAnchor
            model: [
                { type: "quick", items: [
                    { text: Translation.tr("Wallpaper"), iconName: "wallpaper",
                        image: Wallpapers.effectiveWallpaperPath ?? "",
                        action: () => { GlobalStates.wallpaperSelectorOpen = true } },
                    { text: Translation.tr("Widgets"), iconName: "widgets",
                        action: () => {
                            Config.setNestedValue("iris.modules.desktopWidgets", true)
                            GlobalStates.setWidgetEditMode(true)
                        } },
                    { text: Translation.tr("Studio"), iconName: "palette",
                        action: () => { GlobalStates.irisStudioOpen = true } },
                    { text: Translation.tr("Search"), iconName: "search",
                        action: () => { GlobalStates.searchOpen = true } }
                ] },
                { type: "separator" },
                { text: Translation.tr("Edit iRiS"), iconName: "edit",
                    action: () => { GlobalStates.irisEdit = true } },
                { text: Translation.tr("Quick controls"), iconName: "tune",
                    action: () => { GlobalStates.controlPanelOpen = true } },
                { text: Translation.tr("Settings"), iconName: "settings",
                    action: () => { GlobalStates.openSettings() } },
                { type: "separator" },
                { text: Translation.tr("Reload shell"), iconName: "refresh",
                    action: () => { Quickshell.execDetached(["ryoku-shell", "reload"]) } }
            ]
        }
    }
}
