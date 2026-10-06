pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import stage
import stage.modules.common as StageIsland
import "Singletons" as StageCfg
import "../desktop/Singletons" as WidgetStore
import "../visualizer/Singletons" as VizCfg
import Ryoku.Ui.Singletons

// The Stage Editor's store bridge: Ryoku's real desktop widgets, seen through
// the ported chrome's own widget API. The chrome (stage.modules.common.Config)
// reads its catalogue, counts and placements through this object instead of
// its island store, so the toolbar edits the desktop the user actually has:
// widgets.json for the built-ins and hosted faces, plugins.json (through the
// place tool) for plugin tiles, and the visualizer's own config for the bar.
//
// One per editing screen, owned by that screen's Desktop; the chrome installs
// it while the mode frames that monitor and drops it on the way out.
Scope {
    id: root

    // The output whose widget fork this provider reads and writes.
    property string monitor: ""
    // The roster rows, in the chrome's row shape: {id, label, icon, enabled,
    // group}. Fed from Desktop.addItems, so the catalogue is exactly what the
    // desktop can place, and stays reactive with it.
    property var rows: []
    // The plugin place tool (dev checkout or installed path).
    property string placeTool: "ryoku-plugins-place"
    // Ryoku's live wallpaper, mirrored into the chrome's read path so the
    // folder browser and the colour previews start from what the desktop
    // actually shows (the picks themselves flow back through the shim).
    property string wallpaperPath: ""

    // ── The chrome's view ────────────────────────────────────────────────────

    // The catalogue, in the drawer's row shape.
    readonly property var catalogue: {
        const out = [];
        for (const r of root.rows)
            out.push({ widgetId: r.id, name: r.label, icon: r.icon,
                category: r.group === "" ? "Ryoku" : r.group, description: "" });
        return out;
    }

    // The placed widgets, in the island's entry shape (Ryoku widgets are
    // singletons: one entry, id == widgetId).
    readonly property var activeWidgets: {
        const out = [];
        for (const r of root.rows)
            if (r.enabled)
                out.push({ id: r.id, widgetId: r.id });
        return out;
    }

    // The drop grid, from Ryoku's own stage settings.
    readonly property bool snapEnabled: StageCfg.Config.editGridSnap
    readonly property real gridSize: StageCfg.Config.editGridSize
    function toggleSnap() {
        StageCfg.Config.toggleEditGridSnap();
    }

    function count(widgetId) {
        for (const r of root.rows)
            if (r.id === widgetId)
                return r.enabled ? 1 : 0;
        return 0;
    }

    // The editors Ryoku folds into the mode beside Widgets, Wallpaper and
    // Style: the visualiser's and the depth stage's, each a toolbar chip and a
    // drawer catalogue (stage Config.extraSections).
    readonly property var extraSections: [
        {
            "section": "visualizer",
            "label": I18n.tr("Visualizer"),
            "icon": "graphic_eq",
            "tooltip": I18n.tr("The audio visualizer: look, place, colour and motion"),
            "intro": I18n.tr("Drag the look on the desktop to move it, its corner to size it and the dot to turn it, or set it by number below."),
            "page": visualizerPage
        },
        {
            "section": "depth",
            "label": I18n.tr("Depth"),
            "icon": "layers",
            "tooltip": I18n.tr("Cut the wallpaper into layers and lift widgets between them"),
            "intro": I18n.tr("Cut the wallpaper's subject out so widgets can sit behind it, and choose how the layers look and move."),
            "page": depthPage
        }
    ]
    Component {
        id: visualizerPage
        StageVisualizerPage {}
    }
    Component {
        id: depthPage
        StageDepthPage {}
    }

    // ── Writers ──────────────────────────────────────────────────────────────

    // Enable a widget, optionally at a drop point, and record the walk-back:
    // the undo of an add is the state before it (a disable, or the old
    // placement a re-add moved), the redo is the same write again. Ryoku's
    // built-ins and hosted faces place through widgets.json (anchor "free" +
    // x/y); plugin tiles through the place tool; the visualizer owns its own
    // placement and is only switched on here.
    function addWidget(widgetId, x, y, monitorName) {
        const before = root.snapshot(widgetId);
        root._applyAdd(widgetId, x, y);
        GlobalStates.editHistoryPush({
            "undo": () => root.restore(widgetId, before),
            "redo": () => root._applyAdd(widgetId, x, y)
        });
        return widgetId;
    }

    function _applyAdd(widgetId, x, y) {
        const store = WidgetStore.Config;
        if (widgetId.indexOf("plugin:") === 0) {
            const pid = widgetId.slice(7);
            root.enqueue([root.placeTool, pid, "enabled", "true"]);
            if (x !== undefined && y !== undefined)
                root.enqueue([root.placeTool, pid, "desktopWidget", "" + Math.round(x), "" + Math.round(y)]);
            return;
        }
        if (widgetId === "visualizer") {
            VizCfg.Config.setEnabled(true);
            // A drop places the look's centre where the pointer let go, the same
            // way a built-in lands under the cursor: the visualiser box is
            // fractions of the monitor, so the chrome's pixel point converts here.
            if (x !== undefined && y !== undefined)
                root.placeVisualizerAt(x, y);
            return;
        }
        if (x === undefined || y === undefined) {
            store.setFor(root.monitor, widgetId + "Enabled", true);
            return;
        }
        const patch = {};
        patch[widgetId + "Enabled"] = true;
        patch[widgetId + "Anchor"] = "free";
        patch[widgetId + "X"] = Math.round(x);
        patch[widgetId + "Y"] = Math.round(y);
        store.setManyFor(root.monitor, patch);
    }

    // The drop point is the widget's top-left in screen px; the visualiser has
    // no top-left to keep (it is a centred box), so the box centre lands there
    // and the store's own clamp keeps it on screen.
    function placeVisualizerAt(px, py) {
        const scr = root._screen();
        if (!scr)
            return;
        const v = VizCfg.Config;
        const nx = px / scr.width - v.w / 2;
        const ny = py / scr.height - v.h / 2;
        v.setBox(nx, ny, v.w, v.h, scr.width / Math.max(1, scr.height));
    }

    // The screen this provider frames, falling back to the first one.
    function _screen() {
        return Quickshell.screens.find(s => s.name === root.monitor)
            || Quickshell.screens[0] || null;
    }

    function removeWidget(instanceId) {
        root.restore(instanceId, null);
    }

    // The state a restore needs, or null when the widget is not on the
    // desktop (the undo of an add is then a plain disable). For a
    // built-in/face: its placement keys; for a plugin: its whole plugins.json
    // entry (through Registry's merged placement); for the visualizer, its box,
    // so a walk-back lands the look where it was and not where it drifted.
    function snapshot(instanceId) {
        const store = WidgetStore.Config;
        if (instanceId.indexOf("plugin:") === 0) {
            const pid = instanceId.slice(7);
            const e = (WidgetStore.Registry.allPlugins || []).find(p => p.id === pid) || null;
            if (!e || !(e.placement && e.placement.enabled === true))
                return null;
            return { plugin: pid, entry: JSON.parse(JSON.stringify(e.placement)) };
        }
        if (instanceId === "visualizer")
            return VizCfg.Config.enabled
                ? { viz: true, x: VizCfg.Config.x, y: VizCfg.Config.y,
                    w: VizCfg.Config.w, h: VizCfg.Config.h, angle: VizCfg.Config.angle,
                    tiltX: VizCfg.Config.tiltX, tiltY: VizCfg.Config.tiltY }
                : null;
        if (store.get(instanceId + "Enabled", root.monitor) !== true)
            return null;
        return { key: instanceId,
            anchor: store.get(instanceId + "Anchor", root.monitor),
            x: store.get(instanceId + "X", root.monitor),
            y: store.get(instanceId + "Y", root.monitor) };
    }

    // Put a widget back the way a snapshot found it; `null` means it was not
    // on the desktop, so this is the disable path.
    function restore(instanceId, snap) {
        const store = WidgetStore.Config;
        if (instanceId.indexOf("plugin:") === 0) {
            const pid = instanceId.slice(7);
            if (snap === null || snap === undefined) {
                root.enqueue([root.placeTool, pid, "enabled", "false"]);
                return;
            }
            if (snap.entry && Object.keys(snap.entry).length > 0)
                root.enqueue([root.placeTool, pid, "restore", JSON.stringify(snap.entry), "true"]);
            else
                root.enqueue([root.placeTool, pid, "enabled", "true"]);
            return;
        }
        if (instanceId === "visualizer") {
            const v = VizCfg.Config;
            // A re-add restores the box the walk-back found, not wherever the
            // last session left it; a plain disable leaves the placement alone.
            // The turn lands first: the box is clamped against its own angle.
            // The flag goes last, so its immediate write already carries the box.
            if (snap && snap.x !== undefined) {
                if (snap.angle !== undefined)
                    v.rotate(snap.angle);
                v.setBox(snap.x, snap.y, snap.w, snap.h, root.aspect());
                if (snap.tiltX !== undefined)
                    v.setTiltX(snap.tiltX);
                if (snap.tiltY !== undefined)
                    v.setTiltY(snap.tiltY);
            }
            v.setEnabled(snap !== null && snap !== undefined);
            return;
        }
        if (snap === null || snap === undefined) {
            store.setFor(root.monitor, instanceId + "Enabled", false);
            return;
        }
        const patch = {};
        patch[instanceId + "Enabled"] = true;
        patch[instanceId + "Anchor"] = snap.anchor;
        patch[instanceId + "X"] = snap.x;
        patch[instanceId + "Y"] = snap.y;
        store.setManyFor(root.monitor, patch);
    }

    // The visualiser's walk-back, for every way its box changes (the grip's
    // gestures, the placement knobs): `before` is the snapshot taken when the
    // change began, and one undo entry lands if the box actually moved.
    function recordVisualizer(before) {
        if (!before)
            return;
        const after = root.snapshot("visualizer");
        if (!after || JSON.stringify(before) === JSON.stringify(after))
            return;
        GlobalStates.editHistoryPush({
            "undo": () => root.restore("visualizer", before),
            "redo": () => root.restore("visualizer", after)
        });
    }

    // The framed screen's width over its height: the visualiser box is
    // fractions of the monitor, and its clamp needs the real proportions.
    function aspect() {
        const scr = root._screen();
        return scr ? scr.width / Math.max(1, scr.height) : 1;
    }

    // ── The place tool, one command at a time ────────────────────────────────

    // The chrome's store seam is one global; a monitor switch mounts the next
    // screen's provider before this one dies, so only clear the slot when it
    // still holds this provider.
    Component.onCompleted: {
        StageIsland.Config.widgetProvider = root;
        WidgetStore.Config.selectMonitor(root.monitor, true);
    }
    Component.onDestruction: {
        if (StageIsland.Config.widgetProvider === root) {
            StageIsland.Config.widgetProvider = null;
            if (WidgetStore.Config.writeMonitor === root.monitor)
                WidgetStore.Config.selectMonitor("");
        }
    }

    property var _queue: []
    Process {
        id: placeProc
        onExited: (code, status) => root._runNext()
    }
    // The queue seam: the desktop records a plugin gesture's redo as the same
    // place-tool command, run back through here so it can't trample an
    // in-flight undo.
    function enqueue(cmd) {
        root._queue = root._queue.concat([cmd]);
        if (!placeProc.running)
            root._runNext();
    }
    function _runNext() {
        if (root._queue.length === 0)
            return;
        const cmd = root._queue[0];
        root._queue = root._queue.slice(1);
        placeProc.command = cmd;
        placeProc.running = true;
    }
}
