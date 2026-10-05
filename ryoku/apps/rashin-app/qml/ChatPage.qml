import QtQuick
import QtQuick.Controls
import RashinApp

// The chat page: the shared agent session, live. The timeline is the
// daemon's transcript (the bridge replays it on join, so a conversation
// started in the Ask bar or a terminal is already on screen); the composer
// sends through the bridge; approvals surface inline on their tool row or as
// trailing cards. The session drawer on the left is the history: every ACP
// session the agent stored, and loading one replays it.
Item {
    id: page

    readonly property bool motionAllowed: !Theme.reduceMotion
    property bool sessionsOpen: false

    function focusComposer() {
        composer.focusField();
    }

    // Keep the newest line in view while the agent works, but never fight a
    // reader who scrolled up to re-read.
    function scrollEnd() {
        Qt.callLater(() => {
            if (list.count > 0)
                list.positionViewAtEnd();
        });
    }

    // "3m ago" from an RFC3339 stamp; unreadable stamps render as "".
    function relTime(stamp) {
        const raw = String(stamp || "");
        if (raw.length === 0)
            return "";
        const t = Date.parse(raw);
        if (Number.isNaN(t))
            return "";
        const mins = Math.max(0, Math.round((Date.now() - t) / 60000));
        if (mins < 1)
            return qsTr("just now");
        if (mins < 60)
            return qsTr("%1m ago").arg(mins);
        const hours = Math.round(mins / 60);
        if (hours < 24)
            return qsTr("%1h ago").arg(hours);
        return qsTr("%1d ago").arg(Math.round(hours / 24));
    }
    Connections {
        target: ChatBridge
        function onTouched() {
            if (ChatBridge.busy || list.atYEnd)
                page.scrollEnd();
        }
    }
    Component.onCompleted: {
        ChatBridge.loadSessions();
        page.scrollEnd();
    }

    Row {
        anchors.fill: parent
        spacing: 0

        // ---- the session drawer ------------------------------------------------
        Rectangle {
            id: drawer
            width: page.sessionsOpen ? 260 : 0
            height: parent.height
            visible: width > 0
            clip: true
            color: Theme.surfaceLow
            Behavior on width {
                enabled: !Theme.reduceMotion
                NumberAnimation { duration: Theme.move; easing.type: Easing.OutQuint }
            }
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.line }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: Theme.s3
                spacing: Theme.s2

                Row {
                    width: parent.width
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Chats")
                        color: Theme.inkMuted
                        font.family: Theme.mono
                        font.pixelSize: Theme.fMicroPx
                        font.letterSpacing: Theme.trackMark
                    }
                    Item { width: parent.width - implicitWidth - 70; height: 1 }
                    Pill {
                        compact: true
                        text: qsTr("New")
                        onAct: {
                            ChatBridge.newChat();
                            page.sessionsOpen = false;
                        }
                    }
                }

                ListView {
                    id: sessions
                    width: parent.width
                    height: parent.height - y - parent.spacing
                    clip: true
                    model: ChatBridge.sessions
                    spacing: Theme.s1
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    delegate: Rectangle {
                        required property var modelData
                        width: sessions.width
                        height: 52
                        radius: Theme.radiusSm
                        readonly property bool current: String(modelData.id || "") === ChatBridge.currentSession
                        color: current ? Theme.tint16 : rowHover.hovered ? Theme.tint5 : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.snap } }
                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.s3
                            anchors.rightMargin: Theme.s3
                            spacing: 2
                            Text {
                                width: parent.width
                                text: String(modelData.title || modelData.id || "")
                                color: current ? Theme.ink : Theme.inkDim
                                font.family: Theme.ui
                                font.pixelSize: Theme.fSmallPx
                                font.weight: current ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: page.relTime(modelData.updatedAt)
                                visible: text.length > 0
                                color: Theme.inkFaint
                                font.family: Theme.mono
                                font.pixelSize: Theme.fMicroPx
                            }
                        }
                        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                ChatBridge.switchSession(String(modelData.id || ""));
                                page.sessionsOpen = false;
                                page.scrollEnd();
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: sessions.count === 0
                        text: qsTr("No stored chats yet.")
                        color: Theme.inkFaint
                        font.family: Theme.ui
                        font.pixelSize: Theme.fSmallPx
                    }
                }
            }
        }

        // ---- the conversation ---------------------------------------------------
        Column {
            id: main
            width: parent.width - drawer.width
            height: parent.height
            spacing: 0

            // The strip: session tools live here (history toggle, agent,
            // approvals mode, new chat) in one calm row.
            Item {
                width: parent.width
                height: 48

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.s5
                    spacing: Theme.s2

                    IconBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "history"
                        active: page.sessionsOpen
                        onAct: {
                            page.sessionsOpen = !page.sessionsOpen;
                            if (page.sessionsOpen)
                                ChatBridge.loadSessions();
                        }
                    }
                    Pill {
                        anchors.verticalCenter: parent.verticalCenter
                        compact: true
                        text: qsTr("New chat")
                        onAct: {
                            ChatBridge.newChat();
                            page.scrollEnd();
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Theme.s4
                    spacing: Theme.s2

                    // Approvals: read-only auto-approves safe reads; ask
                    // governs every tool. The daemon owns the mode; this
                    // control only requests it.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: apprRow.implicitWidth + Theme.s4
                        height: Theme.ctlH - 8
                        radius: height / 2
                        color: apprHover.hovered ? Theme.tint10 : Theme.tint5
                        border.width: Theme.border
                        border.color: Theme.line
                        Behavior on color { ColorAnimation { duration: Theme.snap } }
                        Row {
                            id: apprRow
                            anchors.centerIn: parent
                            spacing: Theme.s1
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ChatBridge.approvalsMode === "ask" ? "lock" : "unlock"
                                color: Theme.inkDim
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: Theme.fSmallPx
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ChatBridge.approvalsMode === "ask" ? qsTr("Ask") : qsTr("Read-only")
                                color: Theme.inkDim
                                font.family: Theme.ui
                                font.pixelSize: Theme.fTinyPx
                            }
                        }
                        HoverHandler { id: apprHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: ChatBridge.setApprovals(
                                ChatBridge.approvalsMode === "ask" ? "read-only" : "ask")
                        }
                    }

                    // The agent answering, one click from another.
                    Rectangle {
                        id: agentChip
                        anchors.verticalCenter: parent.verticalCenter
                        width: agentRow.implicitWidth + Theme.s4
                        height: Theme.ctlH - 8
                        radius: height / 2
                        color: agentHover.hovered ? Theme.tint10 : Theme.tint5
                        border.width: Theme.border
                        border.color: Theme.line
                        Row {
                            id: agentRow
                            anchors.centerIn: parent
                            spacing: Theme.s1
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "smart_toy"
                                color: Theme.inkDim
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: Theme.fSmallPx
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ChatBridge.currentAgent.length > 0 ? ChatBridge.currentAgent : qsTr("agent")
                                color: Theme.ink
                                font.family: Theme.ui
                                font.pixelSize: Theme.fTinyPx
                            }
                        }
                        HoverHandler { id: agentHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: agentPop.open = !agentPop.open }
                        Popup {
                            id: agentPop
                            property bool open: false
                            parent: Overlay.overlay
                            visible: open
                            x: {
                                const at = agentChip.mapToGlobal(0, agentChip.height);
                                return Math.max(8, Math.min(at.x - 200, (parent ? parent.width : 1000) - width - 8));
                            }
                            y: agentChip.mapToGlobal(0, agentChip.height).y + 8
                            width: 220
                            padding: Theme.s2
                            closePolicy: Popup.CloseOnPressOutside
                            onAboutToHide: open = false
                            background: Rectangle {
                                radius: Theme.radius
                                color: Theme.paperLift
                                border.width: Theme.border
                                border.color: Theme.lineStrong
                            }
                            contentItem: ListView {
                                height: Math.min(contentHeight, 220)
                                clip: true
                                model: ChatBridge.backends
                                boundsBehavior: Flickable.StopAtBounds
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                                delegate: Rectangle {
                                    required property var modelData
                                    width: ListView.view.width
                                    height: 34
                                    radius: Theme.radiusSm
                                    color: bkHover.hovered ? Theme.tint10 : "transparent"
                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.s3
                                        spacing: Theme.s2
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.present ? "circle" : "remove"
                                            color: modelData.present ? Theme.ok : Theme.inkFaint
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: Theme.fTinyPx
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.name || modelData.id || ""
                                            color: Theme.ink
                                            font.family: Theme.ui
                                            font.pixelSize: Theme.fSmallPx
                                        }
                                    }
                                    HoverHandler { id: bkHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: {
                                            ChatBridge.setBackend(String(modelData.id || ""));
                                            agentPop.open = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // The first-run nudge: no agent configured yet. The daemon knows;
            // this only points at where to fix it.
            Rectangle {
                width: parent.width - Theme.s5 * 2
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !ChatBridge.ready
                height: visible ? hintCol.implicitHeight + Theme.s4 * 2 : 0
                radius: Theme.radius
                color: Theme.tint5
                border.width: Theme.border
                border.color: Theme.line
                Column {
                    id: hintCol
                    anchors.centerIn: parent
                    spacing: Theme.s2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("No agent is configured yet.")
                        color: Theme.ink
                        font.family: Theme.ui
                        font.pixelSize: Theme.fSmallPx
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.s2
                        Pill {
                            compact: true
                            primary: true
                            text: qsTr("Open setup")
                            onAct: Qt.openUrlExternally("http://127.0.0.1:" + DaemonClient.port)
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "ryoku-rashin setup"
                            color: Theme.inkMuted
                            font.family: Theme.mono
                            font.pixelSize: Theme.fTinyPx
                        }
                    }
                }
            }

            // The timeline.
            ListView {
                id: list
                width: parent.width
                height: parent.height - y - composerFrame.height - (workingStrip.visible ? workingStrip.height + 8 : 0)
                clip: true
                model: ChatBridge.model
                spacing: Theme.s4
                boundsBehavior: Flickable.StopAtBounds
                topMargin: Theme.s4
                bottomMargin: Theme.s4
                cacheBuffer: 3200
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: MessageRow {}

                // Standalone approvals: a permission that arrived before its
                // tool row, rendered as a trailing card so it is never lost.
                footer: Column {
                    width: list.width
                    spacing: Theme.s3
                    topPadding: list.count > 0 && ChatBridge.standalonePerms.length > 0 ? Theme.s3 : 0
                    Repeater {
                        model: ChatBridge.standalonePerms
                        delegate: Rectangle {
                            id: permCard
                            required property var modelData
                            width: parent.width
                            height: permCol2.implicitHeight + Theme.s4 * 2
                            radius: Theme.radius
                            color: Theme.tint10
                            border.width: Theme.border
                            border.color: Theme.lineStrong
                            Column {
                                id: permCol2
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Theme.s4
                                spacing: Theme.s2
                                Text {
                                    text: qsTr("RASHIN WANTS TO")
                                    color: Theme.inkMuted
                                    font.family: Theme.mono
                                    font.pixelSize: Theme.fMicroPx
                                    font.letterSpacing: Theme.trackLabel
                                }
                                Text {
                                    width: parent.width
                                    text: permCard.modelData.title || ""
                                    color: Theme.ink
                                    font.family: Theme.ui
                                    font.pixelSize: Theme.fSmallPx
                                    wrapMode: Text.Wrap
                                }
                                Flow {
                                    width: parent.width
                                    spacing: Theme.s2
                                    Repeater {
                                        model: permCard.modelData.options || []
                                        delegate: Pill {
                                            required property var modelData
                                            required property int index
                                            compact: true
                                            primary: index === 0
                                            text: modelData.name || modelData.id || ""
                                            onAct: ChatBridge.answerPermission(
                                                String(permCard.modelData.requestId || ""),
                                                String(modelData.id || ""))
                                        }
                                    }
                                    Pill {
                                        compact: true
                                        text: qsTr("Decline")
                                        onAct: ChatBridge.answerPermission(
                                            String(permCard.modelData.requestId || ""), "")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // The working strip: what the agent is doing right now.
            Rectangle {
                id: workingStrip
                anchors.horizontalCenter: parent.horizontalCenter
                visible: ChatBridge.busy && ChatBridge.activity.length > 0
                width: activityRow.implicitWidth + Theme.s4 * 2
                height: 30
                radius: height / 2
                color: Theme.tint5
                border.width: Theme.border
                border.color: Theme.line
                Behavior on visible {
                    enabled: !Theme.reduceMotion
                    NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: Theme.swap }
                }
                Row {
                    id: activityRow
                    anchors.centerIn: parent
                    spacing: Theme.s2
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ChatBridge.activity
                        color: Theme.inkDim
                        font.family: Theme.ui
                        font.pixelSize: Theme.fTinyPx
                    }
                }
            }

            // The composer frame.
            Item {
                id: composerFrame
                width: parent.width
                height: composer.height + Theme.s4 * 2

                Composer {
                    id: composer
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.s5
                    anchors.rightMargin: Theme.s5
                    onSend: (text, images) => {
                        ChatBridge.send(text, images);
                        page.scrollEnd();
                    }
                    onCancelRequested: ChatBridge.cancel()
                }
            }
        }
    }

    // The empty state rides over the timeline while there is nothing to show.
    Column {
        anchors.centerIn: parent
        visible: list.count === 0 && !ChatBridge.busy
        spacing: Theme.s2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "羅"
            color: Theme.lineStrong
            font.pixelSize: 44
            font.family: "Noto Sans CJK JP, Sans Serif"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Ask the Needle anything.")
            color: Theme.inkMuted
            font.family: Theme.ui
            font.pixelSize: Theme.fBodyPx
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("It knows this machine through the vault.")
            color: Theme.inkFaint
            font.family: Theme.ui
            font.pixelSize: Theme.fTinyPx
        }
    }
}
