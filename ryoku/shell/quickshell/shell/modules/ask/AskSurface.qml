pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services
import "../../services" as Services

Rectangle {
    id: root

    required property real s
    required property var screen
    required property Services.AskSession session
    property bool active: false
    property string mode: "ask"
    property string tool: ""
    property string query: ""
    property real maximumHeight: 640 * s
    readonly property bool motionAllowed: !Tokens.reduceMotion && !Motion.reduce
    readonly property real screenHeight: screen && screen.height > 0 ? screen.height : 800
    readonly property real selectedBodyHeight: mode === "chat" ? chat.implicitHeight
        : mode === "tools" ? tools.implicitHeight
        : mode === "web" ? web.implicitHeight
        : answer.implicitHeight
    readonly property real bodyBudget: Math.max(90 * s,
        maximumHeight - 72 * s - 38 * s - Tokens.s7 * s)

    signal requestClose()
    signal modeRequested(string mode)

    implicitHeight: Math.min(maximumHeight, content.implicitHeight + Tokens.s4 * s * 2)
    radius: Tokens.radius * s
    color: Tokens.paper
    border.width: Tokens.border
    border.color: Tokens.lineStrong
    clip: true

    Behavior on implicitHeight {
        enabled: root.active && root.motionAllowed
        NumberAnimation { duration: Tokens.swap; easing.type: Tokens.ease }
    }

    function focusField() {
        field.focusField();
    }

    function requestMode(next) {
        if (["ask", "chat", "tools", "web"].indexOf(next) < 0 || next === mode)
            return;
        modeRequested(next);
        Qt.callLater(field.focusField);
    }

    function cycleMode() {
        const modes = ["ask", "chat", "tools", "web"];
        const index = Math.max(0, modes.indexOf(mode));
        requestMode(modes[(index + 1) % modes.length]);
    }

    function submit(value) {
        const text = String(value || "").trim();
        if (mode === "chat") {
            if (text.length > 0 && !Needle.busy) {
                Needle.send(text);
                query = "";
            }
        } else if (mode === "tools") {
            tools.activate(text);
        } else if (mode === "web") {
            web.activate();
        } else if (session.phase === "done" && text.length > 0) {
            answer.selectedChip = 0;
            session.ask(text);
        } else if (answer.chips.length > 0 && (session.busy || session.permPending)) {
            answer.activate();
        } else {
            answer.selectedChip = 0;
            session.ask(text);
        }
    }

    function newChat() {
        if (mode !== "chat")
            return;
        Needle.newChat();
        query = "";
        Qt.callLater(field.focusField);
    }

    function move(delta) {
        if (mode === "tools") tools.move(delta);
        else if (mode === "web") web.move(delta);
        else if (mode === "ask") {
            if (query.trim().length === 0 && delta < 0 && !session.recentOpen)
                session.requestRecent();
            else
                answer.move(delta);
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.s4 * root.s
        spacing: Tokens.s3 * root.s

        Text {
            text: I18n.tr("RASHIN // ASK")
            color: Tokens.inkMuted
            font.family: Tokens.mono
            font.pixelSize: Tokens.fMicro * root.s
            font.letterSpacing: Tokens.trackMark
        }

        AskField {
            id: field
            width: parent.width
            s: root.s
            active: root.active
            mode: root.mode
            phase: root.session.phase
            working: root.session.working
            chatBusy: Needle.busy
            chatActivity: Needle.activity
            horizontalNavigation: root.mode === "ask" && answer.chips.length > 0
            text: root.query
            onTextChanged: if (root.query !== text) root.query = text
            onSubmitted: value => root.submit(value)
            onPrefixRequested: (next, value) => {
                root.query = value;
                root.requestMode(next);
            }
            onTabRequested: root.cycleMode()
            onUpRequested: root.move(-1)
            onDownRequested: root.move(1)
            onLeftRequested: answer.move(-1)
            onRightRequested: answer.move(1)
            onNewChatRequested: root.newChat()
            onEscapeRequested: root.requestClose()
        }

        Flickable {
            id: modeViewport
            width: parent.width
            height: Math.min(root.selectedBodyHeight, root.bodyBudget)
            contentWidth: width
            contentHeight: root.selectedBodyHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded; visible: modeViewport.contentHeight > modeViewport.height + 1; motionEnabled: root.motionAllowed }

            AskAnswer {
                id: answer
                width: modeViewport.width
                s: root.s
                session: root.session
                active: root.active && root.mode === "ask"
                visible: root.mode === "ask"
                onSwitchToChat: root.requestMode("chat")
                onRecentLoaded: question => root.query = question
                onPinBubbleRequested: {
                    Config.patchAskBubble("screen", String(root.screen ? root.screen.name : ""));
                    Config.patchAskBubble("enabled", true);
                }
            }

            AskChat {
                id: chat
                width: modeViewport.width
                s: root.s
                showComposer: false
                active: root.active && root.mode === "chat"
                visible: root.mode === "chat"
                onInputFocusRequested: root.focusField()
                maximumHeight: root.screenHeight * 0.46
            }

            AskTools {
                id: tools
                width: modeViewport.width
                s: root.s
                active: root.active && root.mode === "tools"
                visible: root.mode === "tools"
                query: root.query
                tool: root.tool
                maximumHeight: root.bodyBudget
            }

            AskWeb {
                id: web
                width: modeViewport.width
                s: root.s
                active: root.active && root.mode === "web"
                visible: root.mode === "web"
                query: root.query
            }
        }

        AskModeStrip {
            width: parent.width
            s: root.s
            mode: root.mode
            onModeRequested: next => root.requestMode(next)
        }
    }
}
