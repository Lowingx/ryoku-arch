pragma Singleton
pragma ComponentBehavior: Bound

import inir.modules.common
import inir.services
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    // Shell entry animation gate — starts false, set true after delay so panels slide in
    property bool shellEntryReady: false
    // Deferred panel loading gate — non-critical panels wait for this before activating
    property bool deferredPanelsReady: false
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property string sidebarLeftTargetOutput: ""
    property bool sidebarLeftExpanded: false
    // A left-sidebar feature requests the panel stay open through implicit closes
    // (backdrop click / focus loss) and yield keyboard focus — e.g. the InnerTune
    // device-flow login, where the user must type a code into an external browser.
    property bool sidebarLeftHoldOpen: false
    property bool aiChatDetached: false
    property bool sidebarRightOpen: false
    property string sidebarRightTargetOutput: ""
    property bool mediaControlsOpen: false
    property bool equalizerOpen: false
    property string equalizerTargetOutput: ""
    readonly property bool equalizerEnabled: (Config.options?.enabledPanels ?? []).includes("iiEqualizer")

    function openEqualizer(outputName: string): void {
        if (!root.equalizerEnabled)
            return
        const requested = String(outputName ?? "")
        equalizerTargetOutput = requested.length > 0
            ? requested
            : String(root.focusedScreen?.name ?? root.primaryScreen?.name ?? "")
        equalizerOpen = true
    }

    function closeEqualizer(): void {
        equalizerOpen = false
    }

    function toggleEqualizer(outputName: string): void {
        if (!root.equalizerEnabled) {
            closeEqualizer()
            return
        }
        if (equalizerOpen) {
            closeEqualizer()
            return
        }
        openEqualizer(outputName)
    }
    property real irisLevelQuietUntil: 0
    function quietIrisLevels(): void { root.irisLevelQuietUntil = Date.now() + 700 }
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool osdMicOpen: false
    property bool osdMediaOpen: false
    property string osdMediaAction: "play" // "play", "pause", "next", "previous"
    signal osdMediaActionTriggered(string action)

    function showMediaAction(action: string): void {
        const normalized = String(action ?? "")
        if (!["play", "pause", "next", "previous"].includes(normalized))
            return
        root.osdMediaAction = normalized
        root.osdMediaOpen = true
        root.osdMediaActionTriggered(normalized)
    }

    property bool osdKeyboardLayoutOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property string overviewMode: "default"
    property string overviewTargetOutput: ""
    property string overviewSearchPrefix: ""
    signal pillSurfaceCommand(string command, string surface)
    property bool altSwitcherOpen: false
    signal altSwitcherCommand(string command)
    property int activeContextMenuCount: 0
    property var activeContextMenu: null
    property bool clipboardOpen: false
    property bool settingsOverlayOpen: false
    property int settingsOverlayRequestedPage: -1 // Set before opening to navigate to a specific page
    property string settingsOverlayRequestedSection: ""
    property int settingsOverlayCurrentPage: -1 // Published by whichever overlay chrome is loaded
    property var _settingsNativeDialogs: ({})
    readonly property bool settingsNativeDialogOpen:
        Object.keys(root._settingsNativeDialogs).length > 0

    // The frame's own settings overlay. Ryoku Hub owns every non-frame
    // setting page, so the family chrome opens locally and deep-links the
    // requested section; the legacy page index is ignored.
    function openSettingsPage(index: int, section): void {
        root.settingsOverlayRequestedPage = -1
        root.settingsOverlayRequestedSection = String(section ?? "")
        root.settingsOverlayOpen = true
    }

    function openSettings(): void {
        root.settingsOverlayRequestedPage = -1
        root.settingsOverlayRequestedSection = ""
        root.settingsOverlayOpen = true
    }

    function toggleSettings(): void {
        if (root.settingsOverlayOpen) {
            root.settingsOverlayOpen = false
            return
        }
        root.openSettings()
    }

    function setSettingsNativeDialogVisible(dialogKey: string, visible: bool): void {
        const key = String(dialogKey ?? "").trim()
        if (!key) return
        const next = Object.assign({}, root._settingsNativeDialogs)
        if (visible)
            next[key] = true
        else
            delete next[key]
        root._settingsNativeDialogs = next
    }

    property bool regionSelectorOpen: false
    property bool japaneseLookupOpen: false
    property bool japaneseLookupExpanded: false
    property var japaneseLookupResult: ({})
    property string japaneseLookupScreen: ""
    property real japaneseLookupX: 0
    property real japaneseLookupY: 0
    property real japaneseLookupWidth: 0
    property real japaneseLookupHeight: 0
    property var regionSelectorAction: 0
    property var regionSelectorMode: 0
    // Explicit screenshot callers must remain deterministic. The dedicated
    // Niri binds for screenshot, OCR and visual search are separate contracts;
    // opening one must never inherit state left by another tool.
    function openRegionScreenshot(): void {
        regionSelectorAction = 0
        regionSelectorMode = 0
        regionSelectorOpen = true
    }

    // The unified snip menu may restore the last toolbar choice. Raw ordinals
    // mirror RegionSelection's enums: action 0 Shot, 1 Edit, 2 Search, 3 OCR
    // (record is never restored); mode 0 rectangle, 1 circle.
    function openRememberedRegionTool(): void {
        let action = 0
        let mode = 0
        if (Config.options?.regionSelector?.rememberSnipChoice ?? true) {
            const savedAction = Config.options?.regionSelector?.lastAction ?? 0
            const savedMode = Config.options?.regionSelector?.lastMode ?? 0
            if (savedAction >= 0 && savedAction <= 3) action = savedAction
            if (savedMode === 1) mode = savedMode
        }
        regionSelectorAction = action
        regionSelectorMode = mode
        regionSelectorOpen = true
    }
    property bool tilingOverlayPickerOpen: false
    property bool tilingOverlayOsdOpen: false
    // Native screenshot annotation editor (Edit action)
    property bool annotationEditorOpen: false
    property string annotationEditorPath: ""
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool wallpaperSelectorOpen: false
    property string wallpaperSelectorSource: ""
    property string wallpaperSelectorQuery: ""
    property bool wallpaperLauncherOpen: false
    property string wallpaperLauncherMode: "static"
    property bool widgetEditMode: false
    property string selectedDesktopWidget: ""
    property string selectedDesktopItem: ""
    property string desktopWidgetQuickControls: ""
    property bool shellLayoutEditMode: false

    function setWidgetEditMode(enabled: bool): void {
        if (enabled)
            shellLayoutEditMode = false
        else {
            selectedDesktopWidget = ""
            selectedDesktopItem = ""
            desktopWidgetQuickControls = ""
        }
        widgetEditMode = enabled
    }

    function selectDesktopWidget(instanceKey: string): void {
        if (!widgetEditMode)
            return
        selectedDesktopWidget = String(instanceKey ?? "")
        selectedDesktopItem = ""
    }

    function clearDesktopWidgetSelection(): void {
        selectedDesktopWidget = ""
        selectedDesktopItem = ""
        desktopWidgetQuickControls = ""
    }

    function selectDesktopItem(instanceKey: string): void {
        selectedDesktopItem = String(instanceKey ?? "")
        selectedDesktopWidget = ""
    }

    function clearDesktopItemSelection(): void {
        selectedDesktopItem = ""
    }

    function requestDesktopWidgetQuickControls(instanceKey: string): void {
        if (!widgetEditMode)
            return
        const key = String(instanceKey ?? "")
        selectedDesktopWidget = key
        desktopWidgetQuickControls = key
    }

    function setShellLayoutEditMode(enabled: bool): void {
        if (enabled) {
            widgetEditMode = false
            selectedDesktopWidget = ""
            selectedDesktopItem = ""
            desktopWidgetQuickControls = ""
        }
        shellLayoutEditMode = enabled
    }
    // Navigate sidebar right to a specific widget by type (e.g. "notepad", "calendar")
    property string sidebarRightRequestedWidget: ""
    // Dialog requests from other panels (e.g. left sidebar → right sidebar)
    property bool requestWifiDialog: false
    property bool requestBluetoothDialog: false
    // Selection targets: "main", "backdrop", "waffle", "waffle-backdrop"
    property string wallpaperSelectionTarget: "main"
    // Target monitor for wallpaper selector (set before opening, avoids config timing issues)
    property string wallpaperSelectorTargetMonitor: ""
    onWallpaperSelectorOpenChanged: {
        // Reset selection target when selector closes without selection
        if (!wallpaperSelectorOpen) {
            wallpaperSelectionTarget = "main";
            wallpaperSelectorTargetMonitor = "";
            // Also reset Config targets if they were set
            if (Config.options?.wallpaperSelector?.selectionTarget &&
                Config.options.wallpaperSelector.selectionTarget !== "main") {
                Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
            }
            if (Config.options?.wallpaperSelector?.targetMonitor) {
                Config.setNestedValue("wallpaperSelector.targetMonitor", "")
            }
        }
    }
    onWallpaperLauncherOpenChanged: {
        if (!wallpaperLauncherOpen) {
            wallpaperSelectionTarget = "main"
            wallpaperSelectorTargetMonitor = ""
            if (Config.options?.wallpaperSelector?.selectionTarget
                    && Config.options.wallpaperSelector.selectionTarget !== "main")
                Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
            if (Config.options?.wallpaperSelector?.targetMonitor)
                Config.setNestedValue("wallpaperSelector.targetMonitor", "")
        }
    }
    property bool cheatsheetOpen: false
    property bool coverflowSelectorOpen: false
    onCoverflowSelectorOpenChanged: {
        if (!coverflowSelectorOpen) {
            wallpaperSelectionTarget = "main";
            wallpaperSelectorTargetMonitor = "";
            if (Config.options?.wallpaperSelector?.selectionTarget &&
                Config.options.wallpaperSelector.selectionTarget !== "main") {
                Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
            }
            if (Config.options?.wallpaperSelector?.targetMonitor) {
                Config.setNestedValue("wallpaperSelector.targetMonitor", "")
            }
        }
    }
    property bool controlPanelOpen: false
    // iRiS: screen-local geometry ({x, y, width, height, radius, screen}) of the
    // Island part that last opened a surface, so it can morph out of and back
    // into that exact shape. Transient coordination only; null means "no origin".
    property var irisMorphOrigin: null
    // Who published that origin when it is not the Island (e.g. "left" for a
    // side panel's button). The Island leaves a foreign origin alone on open and
    // close; the morph surface clears it once it has fully collapsed.
    property string irisMorphOwner: ""
    // True while a surface is mid-morph out of or back into that origin; the
    // Island hides the published part so only one shape is ever on screen.
    // iRiS intent preloading: the pointer resting on the Island (controls) or an
    // expanded Island (settings) instantiates those surfaces hidden, so the
    // morph starts on the click frame instead of after an async load.
    property bool irisControlsWarm: false
    // Asks the focused Island to open a page ("media", "desktop", "activity",
    // "tray", "tools") from a surface that is not the Island (card, floating bubble).
    property string irisIslandPageRequest: ""
    // A bubble's own card: { kind, x, y, width, height, radius, screen, source }
    // with the screen-local rect of the bubble it grows out of; `source` names
    // that bubble ("island-<slot>" or "float-<slot>") so it can hide meanwhile.
    property var irisBubbleCard: null
    // The Island's desktop page is being arranged in place (iRiS Studio).
    property bool irisArrange: false
    // The Dock's body per output, so the chassis field draws it in the same pass
    // as the frame and the Island instead of the Dock carrying a second surface.
    property var irisDockBody: ({})
    // iRiS is being edited in place: every piece is grabbable, the edit bar
    // holds the pieces, the look and the sizes, and Done ends it.
    property bool irisEdit: false
    // What the edit bar is inspecting: a piece slot ("extra:vitals", "left",
    // "app:kitty"), a surface ("island", "dock", "cards"…) or "" for the family.
    property string irisEditSelection: ""
    // A Studio target the edit bar should inspect ("" = keep what it shows).
    property string irisEditTarget: ""
    property string irisEditTab: "pieces"
    property int irisChassisEpoch: 0
    onIrisEditChanged: if (!irisEdit) { irisEditSelection = ""; irisEditTarget = "" }
    // iRiS Studio, the live appearance editor, is open.
    property bool irisStudioOpen: false
    // Where Studio is on screen while it is presented ({ screen, x, y, width,
    // height }), so surfaces it edits can leave its area out of their input.
    property var irisStudioRect: null
    // A target Studio should show when it opens or is already open ("" = keep).
    property string irisStudioTarget: ""
    // The `source` of the card on screen (kept while it collapses), "" when none.
    // Asks whichever bubble shows this kind (floating first, then the Island)
    // to open its card; IPC and keyboard paths use it.
    property string irisBubbleCardRequest: ""
    // A floating piece asked to open its own menu, by kind (IPC).
    property string irisBubbleMenuRequest: ""
    // A bubble being carried: { slot, kind, screen, x, y (screen-local centre),
    // size, released }. The bubble layer draws it and resolves the drop.
    property var irisBubbleDrag: null
    // Per output name: what each bubble slot shows ({ left, right, utility }) and
    // the resting Island's screen-local geometry, published by each Island.
    property var irisBubbleKinds: ({})
    property var irisIslandGeometry: ({})
    // Per output: pieces an edge owner carries instead of floating over it ({ island: [...], dock: [...] }).
    property var irisAbsorbed: ({})
    property bool irisSettingsWarm: false
    // iRiS side panel ("left"/"right") that was revealed by resting at its screen
    // edge: it closes when the pointer leaves until a press inside commits it.
    property string irisSidebarPeek: ""
    // iRiS Dock held on screen by IPC (`inir iris dock show`) until hidden again
    // or an app is chosen from it.
    property bool irisDockShown: false
    // Opens an app's windows or menu on the focused Dock: { appId, mode: "windows" | "menu" }.
    property var irisDockMenuRequest: null
    // A query for Spotlight to type as it opens (IPC); taken and cleared by the palette.
    property string irisSpotlightQuery: ""
    // Desktop widget manager toggle routed to the output that should show it.
    signal desktopWidgetManagerToggleRequested(string outputName)
    // Whether any output's Island is expanded, published for `inir iris status`.
    property bool irisIslandExpanded: false
    property string irisIslandPage: ""
    property bool dashboardOpen: false
    property bool workspaceShowNumbers: false
    property var activeBooruImageMenu: null  // Track which BooruImage has its menu open
    property var activeTaskViewMenu: null  // Track which WindowThumbnail has its menu open
    // Waffle-specific states
    property bool searchOpen: false
    property bool waffleActionCenterOpen: false
    property bool waffleNotificationCenterOpen: false
    property bool waffleWidgetsOpen: false
    property bool waffleAltSwitcherOpen: false
    property bool waffleClipboardOpen: false
    property bool waffleTaskViewOpen: false
    // Panel family transition animation state
    property bool familyTransitionActive: false
    property string familyTransitionDirection: "left" // "left" = current exits left, new enters from right
    property string familyTransitionTarget: ""

    signal requestRipple(real x, real y, string screenName)

    // User-configured fallback for singular panels such as wallpaper pickers.
    // Empty string uses the first available Quickshell screen.
    readonly property var primaryScreen: {
        const name = Config.options?.display?.primaryMonitor ?? ""
        if (name.length > 0) {
            const s = Quickshell.screens.find(scr => scr.name === name)
            if (s) return s
        }
        return Quickshell.screens[0]
    }

    // Focus-following screen for singular interactive surfaces. Keep this
    // separate from primaryScreen: the latter is a user fallback, while this
    // follows the compositor and only falls back when focus cannot be resolved.
    readonly property var focusedScreen: {
        const name = String(CompositorService.currentOutput ?? "")
        return Quickshell.screens.find(screen => (screen?.name ?? "") === name)
            ?? root.primaryScreen
            ?? Quickshell.screens[0]
            ?? null
    }

    function connectedOutputNames(allowedOutputs): var {
        const connected = Quickshell.screens
            .map(screen => String(screen?.name ?? ""))
            .filter(name => name.length > 0)
        if (!Array.isArray(allowedOutputs) || allowedOutputs.length === 0)
            return connected
        const enabled = connected.filter(name => allowedOutputs.includes(name))
        return enabled.length > 0 ? enabled : connected
    }

    function resolveOutputName(requestedOutput, allowedOutputs): string {
        const names = root.connectedOutputNames(allowedOutputs)
        if (names.length === 0)
            return ""
        const requested = String(requestedOutput ?? "")
        if (requested.length > 0 && names.includes(requested))
            return requested
        const focused = String(root.focusedScreen?.name ?? "")
        if (focused.length > 0 && names.includes(focused))
            return focused
        const primary = String(root.primaryScreen?.name ?? "")
        if (primary.length > 0 && names.includes(primary))
            return primary
        return names[0]
    }

    readonly property string overviewPresentationOutput:
        root.resolveOutputName(root.overviewTargetOutput, [])
    readonly property var sidebarScreenList: (Config.options?.panelFamily ?? "ii") === "iris"
        ? [] : (Config.options?.sidebar?.screenList ?? [])
    readonly property string sidebarLeftPresentationOutput:
        root.resolveOutputName(root.sidebarLeftTargetOutput,
            root.sidebarScreenList)
    readonly property string sidebarRightPresentationOutput:
        root.resolveOutputName(root.sidebarRightTargetOutput,
            root.sidebarScreenList)

    function openOverview(outputName): void {
        overviewMode = "default"
        overviewTargetOutput = root.resolveOutputName(outputName, [])
        overviewOpen = true
    }

    function closeOverview(): void {
        overviewOpen = false
    }

    function toggleOverview(outputName): void {
        const resolved = root.resolveOutputName(outputName, [])
        if (overviewOpen && overviewMode === "default" && overviewPresentationOutput === resolved)
            root.closeOverview()
        else
            root.openOverview(resolved)
    }

    function openSidebarLeft(outputName): void {
        if (Config.options?.panelFamily === "iris" && !(Config.options?.iris?.sidebars?.left?.enable ?? true)) return
        sidebarLeftTargetOutput = root.resolveOutputName(outputName,
            root.sidebarScreenList)
        sidebarLeftOpen = true
    }

    function closeSidebarLeft(): void {
        sidebarLeftOpen = false
    }

    function toggleSidebarLeft(outputName): void {
        const resolved = root.resolveOutputName(outputName,
            root.sidebarScreenList)
        if (sidebarLeftOpen && sidebarLeftPresentationOutput === resolved)
            root.closeSidebarLeft()
        else
            root.openSidebarLeft(resolved)
    }

    function openSidebarRight(outputName): void {
        if (Config.options?.panelFamily === "iris" && !(Config.options?.iris?.sidebars?.right?.enable ?? true)) return
        sidebarRightTargetOutput = root.resolveOutputName(outputName,
            root.sidebarScreenList)
        sidebarRightOpen = true
    }

    function closeSidebarRight(): void {
        sidebarRightOpen = false
    }

    function toggleSidebarRight(outputName): void {
        const resolved = root.resolveOutputName(outputName,
            root.sidebarScreenList)
        if (sidebarRightOpen && sidebarRightPresentationOutput === resolved)
            root.closeSidebarRight()
        else
            root.openSidebarRight(resolved)
    }

    onOverviewOpenChanged: {
        if (overviewOpen && overviewTargetOutput.length === 0)
            overviewTargetOutput = root.resolveOutputName("", [])
    }

    onSidebarLeftOpenChanged: {
        if (sidebarLeftOpen && sidebarLeftTargetOutput.length === 0)
            sidebarLeftTargetOutput = root.resolveOutputName("",
                root.sidebarScreenList)
    }

    // Close other waffle popups when one opens (unless allowMultiplePanels is enabled)
    property bool _allowMultiple: Config.options?.waffles?.behavior?.allowMultiplePanels ?? false
    onSearchOpenChanged: {
        if (searchOpen && !_allowMultiple) {
            waffleActionCenterOpen = false
            waffleNotificationCenterOpen = false
            waffleWidgetsOpen = false
            waffleClipboardOpen = false
        }
    }
    onWaffleActionCenterOpenChanged: {
        if (waffleActionCenterOpen && !_allowMultiple) {
            searchOpen = false
            waffleNotificationCenterOpen = false
            waffleWidgetsOpen = false
            waffleClipboardOpen = false
        }
    }
    onWaffleNotificationCenterOpenChanged: {
        if (waffleNotificationCenterOpen) {
            if (!_allowMultiple) {
                searchOpen = false
                waffleActionCenterOpen = false
                waffleWidgetsOpen = false
                waffleClipboardOpen = false
            }
            // Mark notifications as read when opening notification center
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }
    onWaffleWidgetsOpenChanged: {
        if (waffleWidgetsOpen && !_allowMultiple) {
            searchOpen = false
            waffleActionCenterOpen = false
            waffleNotificationCenterOpen = false
            waffleClipboardOpen = false
        }
    }
    onWaffleClipboardOpenChanged: {
        if (waffleClipboardOpen && !_allowMultiple) {
            searchOpen = false
            waffleActionCenterOpen = false
            waffleNotificationCenterOpen = false
            waffleWidgetsOpen = false
            waffleTaskViewOpen = false
        }
    }
    onWaffleTaskViewOpenChanged: {
        if (waffleTaskViewOpen && !_allowMultiple) {
            searchOpen = false
            waffleActionCenterOpen = false
            waffleNotificationCenterOpen = false
            waffleWidgetsOpen = false
            waffleClipboardOpen = false
        }
    }

    onSidebarRightOpenChanged: {
        if (sidebarRightOpen && sidebarRightTargetOutput.length === 0)
            sidebarRightTargetOutput = root.resolveOutputName("",
                root.sidebarScreenList)
        if (sidebarRightOpen) {
            Notifications.timeoutAll()
            Notifications.markAllRead()
        }
    }

    property real screenZoom: 1
    // Screen magnification is applied by the window-manager seam's zoom
    // action; the frame only owns the level and its easing.
    Behavior on screenZoom {
        animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
    }

    IpcHandler {
		target: "zoom"

		function zoomIn(): void {
            screenZoom = Math.min(screenZoom + 0.4, 3.0)
        }

        function zoomOut(): void {
            screenZoom = Math.max(screenZoom - 0.4, 1)
        }
	}
}
