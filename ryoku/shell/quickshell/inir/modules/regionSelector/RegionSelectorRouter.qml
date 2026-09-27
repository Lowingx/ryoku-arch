pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import inir
import inir.modules.common

Scope {
    id: root

    function open(action, mode): void {
        GlobalStates.regionSelectorAction = action
        GlobalStates.regionSelectorMode = mode
        GlobalStates.regionSelectorOpen = true
    }
    // Dedicated screenshot calls are always a rectangular capture. The unified
    // menu is the only entry point allowed to restore a previous toolbar choice.
    function screenshot(): void { GlobalStates.openRegionScreenshot() }
    function search(): void {
        open(RegionSelection.SnipAction.Search,
            (Config.options?.search?.imageSearch?.useCircleSelection ?? false)
                ? RegionSelection.SelectionMode.Circle : RegionSelection.SelectionMode.RectCorners)
    }
    function ocr(): void { open(RegionSelection.SnipAction.CharRecognition, RegionSelection.SelectionMode.RectCorners) }
    function record(): void { open(RegionSelection.SnipAction.Record, RegionSelection.SelectionMode.RectCorners) }
    function recordWithSound(): void { open(RegionSelection.SnipAction.RecordWithSound, RegionSelection.SelectionMode.RectCorners) }
    function menu(): void { GlobalStates.openRememberedRegionTool() }

    IpcHandler {
        target: "region"
        function screenshot(): void { root.screenshot() }
        function search(): void { root.search() }
        function googleLens(): void { root.search() }
        function ocr(): void { root.ocr() }
        function record(): void { root.record() }
        function recordWithSound(): void { root.recordWithSound() }
        function menu(): void { root.menu() }
        function dismiss(): void { GlobalStates.regionSelectorOpen = false }
        function current(): string {
            return JSON.stringify({
                open: GlobalStates.regionSelectorOpen,
                action: GlobalStates.regionSelectorAction,
                mode: GlobalStates.regionSelectorMode
            })
        }
    }
}
