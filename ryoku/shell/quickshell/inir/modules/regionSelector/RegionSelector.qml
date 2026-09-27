pragma ComponentBehavior: Bound
import inir
import inir.modules.common
import inir.modules.common.functions
import inir.modules.common.widgets
import inir.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    function dismiss() {
        GlobalStates.regionSelectorOpen = false
    }

    readonly property var action: GlobalStates.regionSelectorAction
    readonly property var selectionMode: GlobalStates.regionSelectorMode
    
    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: regionSelectorLoader
            required property var modelData
            active: GlobalStates.regionSelectorOpen

            sourceComponent: RegionSelection {
                screen: regionSelectorLoader.modelData
                onDismiss: root.dismiss()
                action: root.action
                selectionMode: root.selectionMode
            }
        }
    }

    // Native annotation editor (Edit action). Lives in this Scope so it survives
    // the selection overlay dismissing.
    Loader {
        active: GlobalStates.annotationEditorOpen
        sourceComponent: AnnotationEditor {}
    }

}
