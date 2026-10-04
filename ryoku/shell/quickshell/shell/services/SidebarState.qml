pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "lib/screens.js" as Screens

Singleton {
    id: root

    readonly property int enterDuration: (Motion.reduce || Tokens.reduceMotion) ? 0 : Tokens.swap
    readonly property int exitDuration: (Motion.reduce || Tokens.reduceMotion) ? 0 : Tokens.move
    property string windowKind: ""
    property var windowScreen: null
    property string windowPage: ""
    readonly property var enterCurve: [0.16, 1, 0.3, 1, 1, 1]
    readonly property var exitCurve: [0, 0, 0.58, 1, 1, 1]

    function screenName(screen) {
        if (typeof screen === "string")
            return screen;
        return screen && screen.name ? screen.name : "";
    }

    function sliceFor(screen) {
        var name = root.screenName(screen);
        if (name !== "")
            return Screens.sliceForName(states.instances, name);
        var focused = Screens.sliceForName(states.instances, Wm.focusedOutput);
        if (focused)
            return focused;
        return states.instances.length > 0 ? states.instances[0] : null;
    }

    function validSide(side) {
        return side === "left" || side === "right";
    }


    function isOpen(screen, side) {
        var slice = root.sliceFor(screen);
        if (!slice || !root.validSide(side))
            return false;
        return side === "left" ? slice.leftOpen : slice.rightOpen;
    }

    function railClearances(screen) {
        var slice = root.sliceFor(screen);
        if (!slice)
            return { top: 0, left: 0, bottom: 0, right: 0 };
        return {
            top: slice.railTop,
            left: slice.railLeft,
            bottom: slice.railBottom,
            right: slice.railRight
        };
    }

    function setRailClearances(screen, clearances) {
        var slice = root.sliceFor(screen);
        if (!slice || !clearances)
            return;
        slice.railTop = Math.max(0, Number(clearances.top) || 0);
        slice.railLeft = Math.max(0, Number(clearances.left) || 0);
        slice.railBottom = Math.max(0, Number(clearances.bottom) || 0);
        slice.railRight = Math.max(0, Number(clearances.right) || 0);
    }

    function activeTab(screen, side) {
        var slice = root.sliceFor(screen);
        if (!slice || !root.validSide(side))
            return "";
        return side === "left" ? slice.leftTab : slice.rightTab;
    }

    function selectTab(side, screen, tab) {
        var slice = root.sliceFor(screen);
        if (!slice || !root.validSide(side) || !tab)
            return;
        if (side === "left")
            slice.leftTab = tab;
        else
            slice.rightTab = tab;
    }
    function closeSide(side, screen) {
        const slice = root.sliceFor(screen);
        if (!slice || !root.validSide(side)) return;
        if (side === "left") slice.leftOpen = false;
        else slice.rightOpen = false;
    }

    function sideForTab(side, tab) {
        return tab === "notices" || tab === "notifications" || tab === "weather"
            || tab === "media" || tab === "today" ? "right" : side;
    }

    function openWindow(kind, screen, page) {
        if (kind !== "tools" && kind !== "chat" && kind !== "activity")
            return;
        const name = root.screenName(screen) || Wm.focusedOutput;
        root.windowScreen = ShellState.screens.find(output => output.name === name)
            || ShellState.screens[0] || null;
        root.windowPage = page || "";
        root.closeAll(screen);
        root.windowKind = kind;
    }

    function closeWindow() {
        root.windowKind = "";
        root.windowPage = "";
    }

    function open(side, screen, tab) {
        if (tab === "tools" || tab === "compress" || tab === "install" || tab === "chat"
                || tab === "overview" || tab === "usage") {
            root.openWindow(tab === "chat" ? "chat" : tab === "overview" || tab === "usage" ? "activity" : "tools", screen, tab);
            return;
        }
        if (tab === "stage") {
            root.closeAll(screen);
            Spawn.run(["ryoku-shell", "hub", "open", "desktop-scene"]);
            return;
        }
        side = root.sideForTab(side, tab);
        const slice = root.sliceFor(screen);
        if (!slice || !root.validSide(side))
            return;
        slice.leftOpen = side === "left";
        slice.rightOpen = side === "right";
        if (side === "left")
            slice.leftTab = tab || "controls";
        else
            slice.rightTab = tab || "today";
    }

    function toggle(side, screen, tab) {
        side = root.sideForTab(side, tab);
        const slice = root.sliceFor(screen);
        if (!slice || !root.validSide(side))
            return;
        const isWindow = tab === "tools" || tab === "compress" || tab === "install"
            || tab === "chat" || tab === "overview" || tab === "usage" || tab === "stage";
        const opened = side === "left" ? slice.leftOpen : slice.rightOpen;
        const currentTab = side === "left" ? slice.leftTab : slice.rightTab;
        if (isWindow || (opened && tab && tab !== currentTab)) {
            root.open(side, screen, tab);
        } else if (opened) {
            root.closeSide(side, screen);
        } else {
            root.open(side, screen, tab);
        }
    }

    function closeAll(screen) {
        var slice = root.sliceFor(screen);
        if (!slice)
            return;
        if (!slice.leftOpen && !slice.rightOpen)
            return;
        slice.leftOpen = false;
        slice.rightOpen = false;
    }


    function consumeRequest(requestedId, monitor, context) {
        var value = requestedId || "";
        var split = value.indexOf("#");
        var id = split >= 0 ? value.substring(0, split) : value;
        var tab = split >= 0 ? value.substring(split + 1) : "";
        if (!tab && typeof context === "string")
            tab = context.charAt(0) === "#" ? context.substring(1) : context;
        else if (!tab && context && typeof context === "object")
            tab = context.tab || context.page || "";
        if (id !== "sidebar-left" && id !== "sidebar-right")
            return;
        root.toggle(id === "sidebar-left" ? "left" : "right", monitor, tab);
    }

    Connections {
        target: ShellState
        function onSurfaceRequested(id, mon, context) {
            root.consumeRequest(id, mon, context);
        }
        function onSurfaceClosed(id, mon) {
            var base = (id || "").split("#")[0];
            if (base === "sidebar-left" || base === "sidebar-right")
                root.closeSide(base === "sidebar-left" ? "left" : "right", mon);
        }
    }


    Variants {
        id: states
        model: ShellState.screens

        PersistentProperties {
            required property var modelData
            property bool leftOpen: false
            property bool rightOpen: false
            property string leftTab: "controls"
            property string rightTab: "today"
            property real railTop: 0
            property real railLeft: 0
            property real railBottom: 0
            property real railRight: 0
        }
    }
}
