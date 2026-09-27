pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Ryoku.Ui.Singletons

// Compositor seam for the vendored frame. The reference spoke one
// compositor's private protocol; this keeps that public surface (window and
// workspace lists in the frame's shape, focus/close/switch actions, the
// overview flag) and sources every fact from Ryoku's window-manager seam, so
// the frame runs unchanged on any compositor the desktop supports. Consumers
// branch on capabilities through the surface, never on the compositor.
Singleton {
    id: root

    // The reference branched on which compositor it drove. The seam answers in
    // one shape on every compositor, so the niri-shaped path is always the
    // live one and the compositor-specific branches fold to it.
    readonly property bool nativeOverview: true
    readonly property bool compositorBlur: false
    readonly property bool windowWorkspaceMap: false
    readonly property bool overviewOpen: Wm.overviewOpen
    // True when a native overview covers fullscreen windows (the compositor
    // raises the overview above them); the frame hides its bar while a
    // fullscreen window owns the screen otherwise.
    readonly property bool overviewOverFullscreen: Wm.caps.nativeOverview === true
        && Wm.overviewOpen
    readonly property bool focusHistory: Wm.caps.focusHistory === true
    readonly property bool hasTilingLayout: Wm.caps.tiledLayout === true

    // ---- outputs ----
    readonly property var outputs: {
        const map = {};
        const outs = Wm.outputs;
        for (let i = 0; i < outs.length; i++) {
            const o = outs[i];
            map[o.name] = {
                name: o.name,
                logical: {
                    x: o.x || 0,
                    y: o.y || 0,
                    width: o.width || 0,
                    height: o.height || 0,
                    scale: o.scale || 1
                }
            };
        }
        return map;
    }
    readonly property var displayScales: {
        const s = {};
        for (const k of Object.keys(root.outputs))
            s[k] = root.outputs[k].logical.scale;
        return s;
    }
    readonly property string currentOutput: Wm.focusedOutput

    // ---- workspaces ----
    // The frame's workspace shape: stable id, output, activity, occupancy.
    readonly property var allWorkspaces: {
        const list = Wm.workspaces;
        const out = [];
        for (let i = 0; i < list.length; i++) {
            const w = list[i];
            if (w.special)
                continue;
            out.push({
                id: w.name,
                name: w.name,
                idx: Number(w.name) || 0,
                output: w.output || "",
                is_active: w.active === true,
                is_urgent: w.urgent === true,
                is_occupied: w.occupied === true,
                has_fullscreen: w.fullscreen === true,
                layout: w.layout || "",
                canActivate: w.canActivate !== false
            });
        }
        return out;
    }
    readonly property var workspaces: {
        const map = {};
        for (const w of root.allWorkspaces)
            map[w.id] = w;
        return map;
    }
    readonly property int focusedWorkspaceIndex: {
        const fw = Wm.focusedWorkspace;
        if (!fw)
            return 0;
        return Number(fw.name) || 0;
    }
    readonly property string focusedWorkspaceId: Wm.focusedWorkspace ? Wm.focusedWorkspace.name : ""
    readonly property var currentOutputWorkspaces: root.allWorkspaces.filter(w => w.output === Wm.focusedOutput)

    function switchToWorkspaceById(id) {
        Wm.focusWorkspace(String(id));
    }

    function workspaceById(id) {
        for (const w of root.allWorkspaces)
            if (w.id === id)
                return w;
        return null;
    }

    function hasWindowsOnActiveWorkspace(outputName: string): bool {
        const active = root.allWorkspaces.filter(w => w.is_active
            && (String(outputName ?? "").length === 0 || w.output === outputName));
        if (active.length === 0)
            return false;
        return root.windows.some(w => !w.is_minimized
            && active.some(ws => ws.id === w.workspace_id));
    }

    function activeWorkspaceCovers(outputName) {
        for (const w of root.allWorkspaces)
            if (w.output === outputName && w.is_active)
                return w;
        return null;
    }

    function tilingWindowCount(id) {
        return root.windows.filter(w => w.workspace_id === id).length;
    }

    // ---- windows ----
    readonly property var windows: {
        const list = Wm.windows;
        const out = [];
        const focusedId = Wm.focusedWindow ? Wm.focusedWindow.id : "";
        for (let i = 0; i < list.length; i++) {
            const w = list[i];
            if (!w.toplevel)
                continue;
            const ws = Wm.workspaceByName(w.workspace);
            // The seam's window key doubles as the frame's niri-shaped ids.
            w.toplevel.nativeWindowId = w.id;
            w.toplevel.nativeWorkspaceId = w.workspace || "";
            out.push({
                id: w.id,
                app_id: w.appId || "",
                title: w.title || "",
                workspace_id: w.workspace || "",
                output: w.output || "",
                is_active: w.id === focusedId,
                is_activated: w.toplevel.activated === true,
                is_urgent: w.toplevel.urgent === true,
                is_floating: w.floating === true,
                is_fullscreen: ws ? ws.fullscreen === true : false,
                is_minimized: w.toplevel.minimized === true,
                is_visible: w.toplevel.activated === true
                    || !(Wm.caps.focusHistory === true),
                focusOrder: w.focusOrder,
                x: w.x || 0,
                y: w.y || 0,
                width: w.width || 0,
                height: w.height || 0,
                toplevel: w.toplevel
            });
        }
        return out;
    }
    readonly property var liveWindows: root.windows.filter(w => !w.is_minimized)
    readonly property var activeWindow: {
        const fw = Wm.focusedWindow;
        if (!fw)
            return null;
        for (const w of root.windows)
            if (w.id === fw.id)
                return w;
        return { id: fw.id, app_id: fw.appId || "", title: fw.title || "", workspace_id: fw.workspace || "" };
    }

    function windowsFor(workspaceId) {
        return root.windows.filter(w => w.workspace_id === workspaceId);
    }

    function filterCurrentWorkspace(toplevels, screen) {
        const name = screen ? screen.name : "";
        const ws = root.activeWorkspaceCovers(name);
        if (!ws)
            return toplevels;
        return root.windows.filter(w => w.workspace_id === ws.id && !w.is_minimized);
    }

    function focusWindow(id) {
        Wm.focusWindow(String(id));
    }

    function closeAllWindows() {
        for (const w of root.windows)
            root.closeWindow(w.id);
    }

    function closeWindow(id) {
        Wm.closeWindow(String(id));
    }

    function moveWindowToWorkspaceById(id, workspaceId) {
        Wm.moveWindowToWorkspace(String(id), String(workspaceId));
    }

    function isWindowFullscreen(win) {
        return !!win && win.is_fullscreen === true;
    }

    function hasFullscreenOnOutput(outputName) {
        return Wm.outputHasFullscreen(outputName);
    }

    function hasVisibleFullscreenWindow() {
        const outs = Wm.outputs;
        for (let i = 0; i < outs.length; i++)
            if (Wm.outputHasFullscreen(outs[i].name))
                return true;
        return false;
    }

    function hasAnyFullscreenWindow() {
        for (const w of root.windows)
            if (w.is_fullscreen)
                return true;
        return false;
    }

    function toggleOverview() {
        Wm.toggleOverview();
    }

    function switchToWorkspaceIndex(index) {
        const list = root.currentOutputWorkspaces;
        if (index >= 0 && index < list.length)
            root.switchToWorkspaceById(list[index].id);
    }

    // ---- layouts ----
    readonly property string currentLayout: {
        const ws = workspaceById(root.focusedWorkspaceId);
        return ws && ws.layout ? ws.layout : "";
    }
    readonly property var layoutNames: ["split", "vsplit", "fullscreen", "columns", "stacks"]

    function switchLayout(name) {
        Wm.setWorkspaceLayout(root.focusedWorkspaceId, String(name));
    }

    function switchLayoutPrevious() {
        Wm.cycleWorkspace(-1);
    }

    function applyLayout(workspaceId, name) {
        Wm.setWorkspaceLayout(String(workspaceId), String(name));
    }

    // ---- keyboard ----
    readonly property var keyboardLayoutNames: Wm.keyboardLayouts
    readonly property int currentKeyboardLayoutIndex: {
        const cur = Wm.keyboardLayout;
        const list = Wm.keyboardLayouts;
        for (let i = 0; i < list.length; i++)
            if (list[i] === cur)
                return i;
        return 0;
    }
    readonly property bool hasMultipleKeyboardLayouts: Wm.keyboardLayouts.length > 1

    function getCurrentKeyboardLayoutName() {
        return Wm.keyboardLayout;
    }

    // ---- power / lifecycle ----
    function powerOffMonitors() {
        const outs = Wm.outputs;
        for (let i = 0; i < outs.length; i++)
            Wm.setOutputPower(outs[i].name, false);
    }

    function powerOnMonitors() {
        const outs = Wm.outputs;
        for (let i = 0; i < outs.length; i++)
            Wm.setOutputPower(outs[i].name, true);
    }

    function quit() {
        Wm._act("session.exit", "sessionExit", []);
    }

    // ---- ordering consumers (no-op: the seam already orders by focus) ----
    property var sortedToplevels: root.windows
    property var _sortingConsumers: ({})

    function setSortingConsumer(name, active) {
        const next = Object.assign({}, root._sortingConsumers);
        if (active)
            next[name] = true;
        else
            delete next[name];
        root._sortingConsumers = next;
        root.sortedToplevels = root.windows;
    }

    function acquireSortingConsumer() {
    }

    function releaseSortingConsumer() {
    }

    // The frame's config health probe: the daemon's doctor owns compositor
    // config truth, so the seam reports ready.
    property bool configLoaded: true
    property bool configLoadFailed: false
    property string configError: ""
    property bool actionReady: Wm.ready
    signal configLoadFinished(bool ok, string error)

    function refreshOverviewHotCorners() {
    }

    function overviewHotCornersForOutput(outputName) {
        return [];
    }

    function isOverviewHotCornerActive(outputName, cornerName) {
        return false;
    }

    function sortToplevels() {
        root.sortedToplevels = root.windows;
    }

    function maximizeColumn() {
    }

    signal windowOrderChanged
    signal windowUrgentChanged

    // Re-emit seam churn as the frame's own signals so consumers repaint.
    Connections {
        target: Wm
        function onWindowsChanged() {
            root.sortedToplevels = root.windows;
            root.windowOrderChanged();
        }
        function onWorkspacesChanged() {
        }
    }
}
