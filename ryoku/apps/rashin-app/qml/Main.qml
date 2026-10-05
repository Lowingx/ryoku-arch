import QtQuick
import QtQuick.Controls
import RashinApp

// The Rashin window. A normal top-level (it opens like any app; the
// compositor floats and centres it), built like the Hub: a rail owns
// navigation, a loader swaps pages, and the header carries global state
// (connection, model, daemon actions). Pages receive props and emit signals;
// only this file and the pages touch the C++ bridges.
ApplicationWindow {
    id: win

    visible: true
    // Size and page start from the remembered state and persist on change;
    // binding them to Preferences would loop (the change writes the source).
    width: 1180
    height: 780
    minimumWidth: 880
    minimumHeight: 560
    color: Theme.surface
    title: "Rashin"
    Component.onCompleted: {
        if (Preferences.winWidth > 0)
            width = Preferences.winWidth;
        if (Preferences.winHeight > 0)
            height = Preferences.winHeight;
        if (Preferences.page.length > 0)
            page = Preferences.page;
        DaemonClient.get("/api/theme");
    }
    onWidthChanged: Preferences.winWidth = width
    onHeightChanged: Preferences.winHeight = height

    // ---- which page ----------------------------------------------------------
    readonly property var pages: [
        { id: "chat", glyph: "forum", label: qsTr("Chat") },
        { id: "ask", glyph: "bolt", label: qsTr("Ask") },
        { id: "vault", glyph: "auto_stories", label: qsTr("Vault") },
        { id: "agents", glyph: "smart_toy", label: qsTr("Agents") },
        { id: "models", glyph: "deployed_code", label: qsTr("Models") },
        { id: "system", glyph: "monitoring", label: qsTr("System") }
    ]
    property string page: "chat"
    onPageChanged: Preferences.page = page

    function navigate(id) {
        for (let i = 0; i < pages.length; i++)
            if (pages[i].id === id) {
                page = id;
                return;
            }
    }

    // ---- daemon theme --------------------------------------------------------
    // The app wears the desktop's live palette: /api/theme resolves the same
    // Material roles the dashboard paints with, re-read on focus and every
    // minute while the window is up.
    Connections {
        target: DaemonClient
        function onReply(path, ok, value) {
            if (path !== "/api/theme" || !ok)
                return;
            Theme.applyRoles(value["roles"]);
            Theme.reduceMotion = value["reduceMotion"] === true;
        }
    }
    Timer {
        interval: 60000
        running: win.visible
        repeat: true
        onTriggered: DaemonClient.get("/api/theme")
    }
    onActiveChanged: if (active) {
        DaemonClient.get("/api/theme");
        DaemonClient.probe();
    }

    // A turn that finishes while the window is unfocused earns a desktop
    // notification; an approval waiting on a person earns one immediately.
    property bool wasBusy: false
    property int lastPermCount: 0
    Connections {
        target: ChatBridge
        function onTouched() {
            if (ChatBridge.busy) {
                win.wasBusy = true;
                return;
            }
            if (win.wasBusy) {
                win.wasBusy = false;
                if (!win.active)
                    Notify.say("Rashin", qsTr("The answer is ready."));
            }
            const perms = ChatBridge.standalonePerms.length;
            if (perms > win.lastPermCount && !win.active)
                Notify.say("Rashin", qsTr("Rashin is waiting for your approval."));
            win.lastPermCount = perms;
        }
    }

    // ---- frame ----------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Row {
        anchors.fill: parent
        spacing: 0

        Rail {
            id: rail
            height: parent.height
            pages: win.pages
            page: win.page
            onNavigated: id => win.navigate(id)
        }

        // The body: a header strip over the page host.
        Column {
            width: parent.width - rail.width
            height: parent.height
            spacing: 0

            Header {
                id: header
                width: parent.width
                page: win.page
                pages: win.pages
            }

            Loader {
                id: host
                width: parent.width
                height: parent.height - header.height
                sourceComponent: componentFor(win.page)
            }
        }
    }

    function componentFor(id) {
        switch (id) {
        case "chat": return chatPage;
        case "ask": return askPage;
        case "vault": return vaultPage;
        case "agents": return agentsPage;
        case "models": return modelsPage;
        case "system": return systemPage;
        }
        return chatPage;
    }

    Component { id: chatPage; ChatPage {} }
    Component { id: askPage; AskPage {} }
    Component { id: vaultPage; VaultPage {} }
    Component { id: agentsPage; AgentsPage {} }
    Component { id: modelsPage; ModelsPage {} }
    Component { id: systemPage; SystemPage {} }

    // ---- keyboard --------------------------------------------------------------
    // Ctrl+1..6 jump pages, Ctrl+N starts a chat, Ctrl+K focuses the composer,
    // Ctrl+B toggles the rail.
    Shortcut { sequence: "Ctrl+Q"; onActivated: Qt.quit() }
    Shortcut { sequence: "Ctrl+N"; onActivated: { win.navigate("chat"); ChatBridge.newChat(); } }
    Shortcut {
        sequence: "Ctrl+K"
        onActivated: {
            win.navigate("chat");
            if (host.item)
                host.item.focusComposer();
        }
    }
    Shortcut { sequence: "Ctrl+B"; onActivated: Preferences.sidebarCollapsed = !Preferences.sidebarCollapsed }
    Shortcut { sequence: "Ctrl+1"; onActivated: win.navigate("chat") }
    Shortcut { sequence: "Ctrl+2"; onActivated: win.navigate("ask") }
    Shortcut { sequence: "Ctrl+3"; onActivated: win.navigate("vault") }
    Shortcut { sequence: "Ctrl+4"; onActivated: win.navigate("agents") }
    Shortcut { sequence: "Ctrl+5"; onActivated: win.navigate("models") }
    Shortcut { sequence: "Ctrl+6"; onActivated: win.navigate("system") }
}
