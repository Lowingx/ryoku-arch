pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services
import ".."

Item {
    id: root

    required property real s
    required property bool open
    required property real reveal
    required property bool tabActive
    property int index: 0
    property bool compact: false
    property real viewportHeight: 0
    readonly property bool motionAllowed: !Tokens.reduceMotion && !Motion.reduce
    signal requestClose()

    property bool modelPickerOpen: false
    property bool historyOpen: false
    property bool needleMarkedOpen: false

    readonly property color ink: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface)
    readonly property color dim: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
    implicitHeight: root.viewportHeight > 0 ? Math.max(360 * root.s, root.viewportHeight) : 648 * root.s

    function scrollEnd() {
        if (transcript.stick)
            Qt.callLater(transcript.positionViewAtEnd);
    }

    function syncPresence() {
        const active = root.open && root.tabActive;
        if (active === root.needleMarkedOpen)
            return;
        root.needleMarkedOpen = active;
        if (active) {
            Needle.noteOpened();
            composer.forceFocus();
            root.scrollEnd();
        } else {
            Needle.noteClosed();
        }
    }

    Component.onCompleted: root.syncPresence()
    Component.onDestruction: if (root.needleMarkedOpen) Needle.noteClosed()
    onOpenChanged: root.syncPresence()
    onTabActiveChanged: root.syncPresence()

    Connections {
        target: Needle
        enabled: root.open && root.tabActive
        function onTouched() { root.scrollEnd(); }
    }

    Item {
        id: face
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 14 * root.s
        anchors.rightMargin: 14 * root.s
        anchors.topMargin: 14 * root.s
        height: root.implicitHeight - 28 * root.s

        DropArea {
            anchors.fill: parent
            onDropped: drop => {
                if (!drop.hasUrls)
                    return;
                for (var i = 0; i < drop.urls.length; i++)
                    composer.addDropUrl(drop.urls[i]);
                drop.accept();
            }
        }

        Item {
            id: chatHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 24 * root.s

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("RASHIN")
                color: root.dim
                font.family: Theme.mono
                font.pixelSize: 9 * root.s
                font.letterSpacing: 1.5
                font.weight: Font.DemiBold
            }

            Row {
                id: headerActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4 * root.s

                Rectangle {
                    id: modelChip
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18 * root.s
                    width: Math.min(152 * root.s, modelLabelText.implicitWidth + 24 * root.s)
                    radius: height / 2
                    color: modelHover.hovered || root.modelPickerOpen
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                        : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.06)
                    Behavior on color {
                        enabled: root.motionAllowed
                        ColorAnimation { duration: Motion.fast }
                    }
                    Text {
                        id: modelLabelText
                        anchors.left: parent.left
                        anchors.right: modelChevron.left
                        anchors.leftMargin: 7 * root.s
                        anchors.rightMargin: 3 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.modelLabel()
                        elide: Text.ElideMiddle
                        color: root.ink
                        font.family: Theme.mono
                        font.pixelSize: 8 * root.s
                    }
                    Text {
                        id: modelChevron
                        anchors.right: parent.right
                        anchors.rightMargin: 4 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⌄"
                        color: root.dim
                        font.family: Theme.mono
                        font.pixelSize: 9 * root.s
                    }
                    HoverHandler { id: modelHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.modelPickerOpen = true }
                }

                Rectangle {
                    id: approvalMode
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property bool autoRead: Needle.approvalsMode === "read-only"
                    width: approvalLabel.implicitWidth + 10 * root.s
                    height: 18 * root.s
                    radius: height / 2
                    color: approvalMode.autoRead
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                        : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.06)
                    Text {
                        id: approvalLabel
                        anchors.centerIn: parent
                        text: approvalMode.autoRead ? I18n.tr("READ") : I18n.tr("ASK")
                        color: approvalMode.autoRead ? Theme.primary : root.dim
                        font.family: Theme.mono
                        font.pixelSize: 6.5 * root.s
                        font.weight: Font.DemiBold
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Needle.setApprovals(approvalMode.autoRead ? "ask" : "read-only") }
                }

                Repeater {
                    model: [
                        { glyph: "history", action: "history" },
                        { glyph: "add_comment", action: "new" },
                        { glyph: "open_in_new", action: "setup" }
                    ]
                    delegate: Rectangle {
                        id: headerButton
                        required property var modelData
                        width: 24 * root.s
                        height: 24 * root.s
                        radius: width / 2
                        color: headerHover.hovered
                            ? Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.10)
                            : "transparent"
                        Behavior on color {
                            enabled: root.motionAllowed
                            ColorAnimation { duration: Motion.fast }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: headerButton.modelData.glyph
                            color: root.dim
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 13 * root.s
                        }
                        HoverHandler { id: headerHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (headerButton.modelData.action === "history") {
                                    root.historyOpen = true;
                                    Needle.loadSessions();
                                } else if (headerButton.modelData.action === "new") {
                                    Needle.newChat();
                                    composer.pendingImages = [];
                                    composer.forceFocus();
                                } else {
                                    Spawn.run(["ryoku-shell", "hub", "open", "rashin"]);
                                }
                            }
                        }
                    }
                }
            }
        }

        ListView {
            id: transcript
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: chatHeader.bottom
            anchors.bottom: workingStrip.top
            anchors.topMargin: 8 * root.s
            anchors.bottomMargin: 8 * root.s
            clip: true
            spacing: 12 * root.s
            model: Needle.convo
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 6000
            property bool stick: true
            onCountChanged: if (stick) Qt.callLater(positionViewAtEnd)
            onContentHeightChanged: if (stick) Qt.callLater(positionViewAtEnd)
            onMovementEnded: stick = atYEnd
            ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded; motionEnabled: root.motionAllowed }

            delegate: Item {
                id: transcriptRow
                required property int index
                required property string kind
                required property string role
                required property string body
                required property string thought
                required property bool open
                required property bool live
                required property bool cont
                required property bool failed
                required property string imagesJson
                required property string toolId
                required property string title
                required property string tkind
                required property string status
                required property string input
                required property string output
                required property string diffsJson
                required property bool auto
                required property string permJson
                width: ListView.view ? ListView.view.width : 0
                implicitHeight: rowLoader.implicitHeight

                Loader {
                    id: rowLoader
                    width: parent.width
                    sourceComponent: transcriptRow.kind === "tool" ? toolComponent : messageComponent
                }
                Component {
                    id: messageComponent
                    MessageView {
                        width: transcriptRow.width
                        s: root.s
                        compact: root.compact
                        role: transcriptRow.role
                        body: transcriptRow.body
                        thought: transcriptRow.thought
                        open: transcriptRow.open
                        live: transcriptRow.live
                        cont: transcriptRow.cont
                        failed: transcriptRow.failed
                        imagesJson: transcriptRow.imagesJson
                    }
                }
                Component {
                    id: toolComponent
                    ToolView {
                        width: transcriptRow.width
                        s: root.s
                        title: transcriptRow.title
                        tkind: transcriptRow.tkind
                        status: transcriptRow.status
                        input: transcriptRow.input
                        output: transcriptRow.output
                        diffsJson: transcriptRow.diffsJson
                        auto: transcriptRow.auto
                        permJson: transcriptRow.permJson
                    }
                }
            }

            footer: Column {
                width: transcript.width
                spacing: 5 * root.s
                bottomPadding: 5 * root.s
                Repeater {
                    model: Needle.standalonePerms
                    delegate: ApprovalView {
                        required property var modelData
                        width: transcript.width
                        s: root.s
                        perm: modelData
                    }
                }
            }
        }

        Column {
            anchors.centerIn: transcript
            width: Math.min(transcript.width - 24 * root.s, 300 * root.s)
            spacing: 7 * root.s
            visible: Needle.convo.count === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Needle.ready ? I18n.tr("Ask the needle") : I18n.tr("Connect an AI")
                color: root.ink
                font.family: Theme.mono
                font.pixelSize: 13 * root.s
                font.weight: Font.Medium
            }
            Text {
                width: parent.width
                visible: !root.compact
                horizontalAlignment: Text.AlignHCenter
                text: Needle.ready
                    ? I18n.tr("It knows this machine, your desktop, and the Ryoku source. Drop in an image to ask about it.")
                    : I18n.tr("Rashin needs an AI to answer. Set it up once and the needle is ready.")
                wrapMode: Text.WordWrap
                color: root.dim
                font.family: Theme.fontPrimary
                font.pixelSize: 8 * root.s
                lineHeight: 1.3
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !Needle.ready
                width: setupLabel.implicitWidth + 20 * root.s
                height: 24 * root.s
                radius: Theme.radiusWidget
                color: Theme.primary
                Text {
                    id: setupLabel
                    anchors.centerIn: parent
                    text: I18n.tr("Open setup")
                    color: Theme.inkOn(Theme.primary, Theme.onPrimary)
                    font.family: Theme.fontPrimary
                    font.pixelSize: 9 * root.s
                    font.weight: Font.DemiBold
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Spawn.run(["ryoku-shell", "hub", "open", "rashin"]) }
            }
        }

        Item {
            id: workingStrip
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: composer.top
            anchors.bottomMargin: visible ? 5 * root.s : 0
            visible: Needle.busy
            height: visible ? 20 * root.s : 0
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5 * root.s
                Rectangle {
                    width: 6 * root.s
                    height: width
                    radius: width / 2
                    color: Theme.primary
                    SequentialAnimation on opacity {
                        running: root.open && root.tabActive && workingStrip.visible && root.motionAllowed
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.3; to: 1; duration: 520 }
                        NumberAnimation { from: 1; to: 0.3; duration: 520 }
                    }
                }
                Text {
                    text: Needle.activity.length > 0 ? Needle.activity : I18n.tr("working")
                    color: root.dim
                    font.family: Theme.fontPrimary
                    font.pixelSize: 8 * root.s
                }
            }
        }

        ComposerView {
            id: composer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            s: root.s
        }
    }

    ModelPickerView {
        anchors.fill: parent
        s: root.s
        wide: !root.compact
        open: root.modelPickerOpen
        onClosed: root.modelPickerOpen = false
    }

    Rectangle {
        anchors.fill: parent
        visible: root.historyOpen
        color: Qt.rgba(0, 0, 0, 0.55)
        z: 60
        TapHandler { onTapped: root.historyOpen = false }
    }

    Rectangle {
        id: historyDrawer
        visible: root.historyOpen
        z: 61
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Tokens.s5 * root.s
        anchors.rightMargin: Tokens.s5 * root.s
        width: Math.min(parent.width - Tokens.s6 * root.s,
            (root.compact ? 310 : 430) * root.s)
        height: Math.min((Needle.sessions.length + 1) * 42 * root.s + Tokens.s4 * root.s, 420 * root.s)
        radius: Tokens.radius * root.s
        color: Tokens.paperLift
        border.width: Tokens.border
        border.color: Tokens.lineStrong
        clip: true
        TapHandler { }

        Column {
            anchors.fill: parent
            anchors.margins: Tokens.s2 * root.s
            spacing: Tokens.s1 * root.s

            Rectangle {
                width: parent.width
                height: 38 * root.s
                radius: Tokens.radius * root.s
                color: newChatHover.hovered ? Tokens.tint10 : "transparent"
                Text {
                    font.family: "Material Symbols Rounded"
                    id: newChatIcon
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.s3 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: "add_comment"
                    color: Tokens.sun
                    font.pixelSize: Tokens.fBody * root.s
                }
                Text {
                    anchors.left: newChatIcon.right
                    anchors.leftMargin: Tokens.s2 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("New chat")
                    color: Tokens.sun
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                    font.weight: Font.Medium
                }
                HoverHandler { id: newChatHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        Needle.newChat();
                        composer.pendingImages = [];
                        root.historyOpen = false;
                        composer.forceFocus();
                    }
                }
            }

            ListView {
                width: parent.width
                height: parent.height - 42 * root.s
                clip: true
                model: Needle.sessions
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded; motionEnabled: root.motionAllowed }
                delegate: Rectangle {
                    id: sessionRow
                    required property var modelData
                    width: ListView.view ? ListView.view.width : 0
                    height: 38 * root.s
                    radius: Tokens.radius * root.s
                    color: sessionHover.hovered ? Tokens.tint10 : "transparent"
                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Tokens.s3 * root.s
                        anchors.rightMargin: Tokens.s3 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: sessionRow.modelData.title && sessionRow.modelData.title.length ? sessionRow.modelData.title : I18n.tr("untitled")
                        elide: Text.ElideRight
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                    }
                    HoverHandler { id: sessionHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            Needle.switchSession(sessionRow.modelData.id);
                            root.historyOpen = false;
                        }
                    }
                }
            }
        }
    }

    function shortModel(id) {
        var text = String(id);
        var cut = text.lastIndexOf("/");
        if (cut < 0) cut = text.lastIndexOf(":");
        return cut >= 0 ? text.slice(cut + 1) : text;
    }

    function modelLabel() {
        var agent = String(Needle.currentAgent);
        var model = Needle.currentModel.length > 0 ? root.shortModel(Needle.currentModel) : "";
        if (agent.length > 0 && model.length > 0) return agent + " · " + model;
        return agent.length > 0 ? agent : model.length > 0 ? model : I18n.tr("Choose agent & model");
    }

    component ImageThumb: Rectangle {
        id: imageRoot
        property real s: 1
        property string path: ""
        width: Math.min(parent ? parent.width : 210 * imageRoot.s, 210 * imageRoot.s)
        height: Math.min(160 * imageRoot.s, width * (thumb.implicitHeight > 0 ? thumb.implicitHeight / Math.max(1, thumb.implicitWidth) : 0.6))
        radius: Tokens.radius * imageRoot.s
        color: Tokens.tint5
        border.width: Tokens.border
        border.color: Tokens.lineSoft
        clip: true
        Image {
            id: thumb
            anchors.fill: parent
            anchors.margins: 2 * imageRoot.s
            fillMode: Image.PreserveAspectFit
            source: "file://" + imageRoot.path
            asynchronous: true
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: Spawn.run(["xdg-open", imageRoot.path]) }
    }

    component ApprovalView: Rectangle {
        id: approvalRoot
        property real s: 1
        property var perm: null
        readonly property string command: approvalRoot.perm
            ? String(approvalRoot.perm.input || approvalRoot.perm.title || "") : ""
        readonly property var options: {
            if (!approvalRoot.perm || !approvalRoot.perm.options)
                return [];
            var opts = approvalRoot.perm.options.filter(option => String(option.kind || "") !== "reject_always");
            var hasReject = opts.some(option => String(option.kind || "").indexOf("reject") >= 0);
            return hasReject ? opts : opts.concat([{ id: "", name: I18n.tr("Decline"), kind: "reject_once" }]);
        }
        implicitHeight: approvalBody.implicitHeight + Tokens.s4 * approvalRoot.s * 2
        radius: Tokens.radius * approvalRoot.s
        color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.10)
        border.width: Tokens.border
        border.color: Tokens.sun

        Column {
            id: approvalBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.s4 * approvalRoot.s
            spacing: Tokens.s3 * approvalRoot.s
            Row {
                spacing: Tokens.s2 * approvalRoot.s
                Text {
                    font.family: "Material Symbols Rounded"
                    text: "shield"
                    color: Tokens.sun
                    font.pixelSize: Tokens.fBody * approvalRoot.s
                }
                Text {
                    text: I18n.tr("NEEDS YOUR OK")
                    color: Tokens.sun
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fSmall * approvalRoot.s
                    font.weight: Font.DemiBold
                    font.letterSpacing: Tokens.trackMark
                }
            }
            Text {
                width: parent.width
                visible: approvalRoot.command.length > 0
                text: approvalRoot.command
                color: Tokens.ink
                font.family: Tokens.mono
                font.pixelSize: Tokens.fSmall * approvalRoot.s
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 4
                elide: Text.ElideRight
            }
            Flow {
                width: parent.width
                spacing: Tokens.s2 * approvalRoot.s
                Repeater {
                    model: approvalRoot.options
                    delegate: SidebarButton {
                        s: approvalRoot.s
                        motionEnabled: root.motionAllowed
                        id: permissionButton
                        required property var modelData
                        text: String(permissionButton.modelData.name || permissionButton.modelData.id)
                        primary: String(permissionButton.modelData.kind || "").indexOf("reject") < 0
                        compact: true
                        onAct: Needle.answerPermission(approvalRoot.perm.requestId, permissionButton.modelData.id)
                    }
                }
            }
        }
    }

    component MessageView: Item {
        id: messageRoot
        property real s: 1
        property bool compact: false
        property string role: "agent"
        property string body: ""
        property string thought: ""
        property bool open: false
        property bool live: false
        property bool cont: false
        property bool failed: false
        property string imagesJson: "[]"
        property bool thoughtExpanded: false
        readonly property bool isUser: messageRoot.role === "user"
        readonly property var images: {
            try { return JSON.parse(messageRoot.imagesJson) || []; }
            catch (error) { return []; }
        }

        function messageBlocks(markdown) {
            if (!markdown)
                return [];
            var expression = /```(\w+)?\n([\s\S]*?)```/g;
            var blocks = [];
            var last = 0;
            var match;
            function addText(text) {
                if (text && text.trim().length)
                    blocks.push({ type: "text", content: text });
            }
            while ((match = expression.exec(markdown)) !== null) {
                if (match.index > last)
                    addText(markdown.slice(last, match.index));
                if (match[2] && match[2].trim().length)
                    blocks.push({ type: "code", lang: match[1] || "", content: match[2].replace(/\n+$/, "") });
                last = expression.lastIndex;
            }
            if (last < markdown.length) {
                var tail = markdown.slice(last);
                var fence = tail.indexOf("```");
                if (fence !== -1) {
                    addText(tail.slice(0, fence));
                    var unfinished = tail.slice(fence + 3);
                    var language = unfinished.match(/^(\w+)?\n/);
                    blocks.push({
                        type: "code",
                        lang: language ? language[1] || "" : "",
                        content: language ? unfinished.slice(language[0].length) : unfinished
                    });
                } else {
                    addText(tail);
                }
            }
            if (blocks.length === 0)
                addText(markdown);
            return blocks;
        }

        implicitHeight: messageColumn.implicitHeight

        Column {
            id: messageColumn
            width: parent.width
            spacing: 5 * messageRoot.s

            Text {
                visible: !messageRoot.cont
                anchors.right: messageRoot.isUser ? parent.right : undefined
                text: messageRoot.isUser ? I18n.tr("YOU") : I18n.tr("NEEDLE")
                color: messageRoot.isUser
                    ? Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                    : Theme.primary
                font.family: Theme.mono
                font.pixelSize: 7.5 * messageRoot.s
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
            }

            Rectangle {
                anchors.right: messageRoot.isUser ? parent.right : undefined
                width: messageRoot.isUser
                    ? Math.min(parent.width, (messageRoot.compact ? 290 : 360) * messageRoot.s)
                    : parent.width
                implicitHeight: messageBody.implicitHeight + 16 * messageRoot.s
                radius: Theme.radiusWidget
                color: messageRoot.isUser
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                    : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.05)
                border.width: Theme.borderWidth
                border.color: messageRoot.isUser
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.28)
                    : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.30)

                Column {
                    id: messageBody
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8 * messageRoot.s
                    spacing: 6 * messageRoot.s

                    Repeater {
                        model: messageRoot.images
                        delegate: ImageThumb {
                            required property string modelData
                            s: messageRoot.s
                            path: modelData
                        }
                    }

                    Rectangle {
                        visible: !messageRoot.isUser && messageRoot.thought.length > 0
                        width: parent.width
                        implicitHeight: thoughtColumn.implicitHeight + 12 * messageRoot.s
                        radius: 6 * messageRoot.s
                        color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.04)
                        border.width: Theme.borderWidth
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.25)
                        Column {
                            id: thoughtColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 6 * messageRoot.s
                            spacing: 4 * messageRoot.s
                            Item {
                                width: parent.width
                                height: thoughtLabel.implicitHeight
                                Text {
                                    id: thoughtLabel
                                    anchors.left: parent.left
                                    text: messageRoot.live ? I18n.tr("THINKING…") : I18n.tr("THOUGHT")
                                    color: messageRoot.live ? Theme.primary : root.dim
                                    font.family: Theme.mono
                                    font.pixelSize: 7.5 * messageRoot.s
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1
                                }
                                Text {
                                    anchors.right: parent.right
                                    visible: !messageRoot.live
                                    text: messageRoot.thoughtExpanded ? "⌃" : "⌄"
                                    color: root.dim
                                    font.family: Theme.mono
                                    font.pixelSize: 9 * messageRoot.s
                                }
                            }
                            TextEdit {
                                width: parent.width
                                visible: messageRoot.live || messageRoot.thoughtExpanded
                                text: messageRoot.thought
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                textFormat: TextEdit.PlainText
                                color: root.dim
                                font.family: Theme.fontPrimary
                                font.pixelSize: 10.5 * messageRoot.s
                                font.italic: true
                            }
                        }
                        HoverHandler { cursorShape: messageRoot.live ? Qt.ArrowCursor : Qt.PointingHandCursor }
                        TapHandler {
                            enabled: !messageRoot.live
                            onTapped: messageRoot.thoughtExpanded = !messageRoot.thoughtExpanded
                        }
                    }

                    TextEdit {
                        width: parent.width
                        visible: messageRoot.isUser && messageRoot.body.length > 0
                        text: messageRoot.isUser ? messageRoot.body : ""
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        color: messageRoot.failed ? Theme.vermLit : root.ink
                        selectionColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
                        font.family: Theme.fontPrimary
                        font.pixelSize: 12.5 * messageRoot.s
                    }

                    Column {
                        width: parent.width
                        visible: !messageRoot.isUser && messageRoot.body.length > 0
                        spacing: 6 * messageRoot.s
                        Repeater {
                            model: messageRoot.messageBlocks(messageRoot.body)
                            delegate: Item {
                                id: answerBlock
                                required property var modelData
                                readonly property bool code: answerBlock.modelData.type === "code"
                                width: parent.width
                                implicitHeight: answerBlock.code ? codeFrame.implicitHeight : answerText.implicitHeight

                                TextEdit {
                                    id: answerText
                                    visible: !answerBlock.code
                                    width: parent.width
                                    text: answerBlock.code ? "" : String(answerBlock.modelData.content).replace(/([^\n])\n(?!\n)/g, "$1  \n")
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.Wrap
                                    textFormat: TextEdit.MarkdownText
                                    color: messageRoot.failed ? Theme.vermLit : root.ink
                                    selectionColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
                                    font.family: Theme.fontPrimary
                                    font.pixelSize: 12.5 * messageRoot.s
                                    onLinkActivated: url => Spawn.run(["xdg-open", url])
                                }

                                Rectangle {
                                    id: codeFrame
                                    visible: answerBlock.code
                                    width: parent.width
                                    implicitHeight: codeBody.implicitHeight + 12 * messageRoot.s
                                    radius: 6 * messageRoot.s
                                    color: Qt.rgba(0, 0, 0, 0.30)
                                    border.width: Theme.borderWidth
                                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35)
                                    Column {
                                        id: codeBody
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 6 * messageRoot.s
                                        spacing: 5 * messageRoot.s
                                        Item {
                                            width: parent.width
                                            height: 18 * messageRoot.s
                                            Text {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: answerBlock.modelData.lang || I18n.tr("code")
                                                color: root.dim
                                                font.family: Theme.mono
                                                font.pixelSize: 8 * messageRoot.s
                                            }
                                            Text {
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: I18n.tr("COPY")
                                                color: root.dim
                                                font.family: Theme.mono
                                                font.pixelSize: 7.5 * messageRoot.s
                                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                                TapHandler { onTapped: Needle.copyText(answerBlock.modelData.content) }
                                            }
                                        }
                                        TextEdit {
                                            width: parent.width
                                            text: answerBlock.code ? answerBlock.modelData.content : ""
                                            readOnly: true
                                            selectByMouse: true
                                            wrapMode: TextEdit.WrapAnywhere
                                            textFormat: TextEdit.PlainText
                                            color: root.ink
                                            selectionColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
                                            font.family: Theme.mono
                                            font.pixelSize: 11 * messageRoot.s
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: !messageRoot.isUser && !messageRoot.open && messageRoot.body.length > 0
                        text: I18n.tr("COPY")
                        color: root.dim
                        font.family: Theme.mono
                        font.pixelSize: 7.5 * messageRoot.s
                        font.letterSpacing: 0.8
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Needle.copyText(messageRoot.body) }
                    }
                }
            }
        }
    }

    component ToolView: Item {
        id: toolRoot
        property real s: 1
        property string title: ""
        property string tkind: ""
        property string status: "pending"
        property string input: ""
        property string output: ""
        property string diffsJson: "[]"
        property bool auto: false
        property string permJson: ""
        property bool expanded: false
        readonly property bool running: toolRoot.status !== "completed" && toolRoot.status !== "failed"
        readonly property bool failed: toolRoot.status === "failed"
        readonly property var diffs: {
            try { return JSON.parse(toolRoot.diffsJson) || []; }
            catch (error) { return []; }
        }
        readonly property var perm: {
            if (toolRoot.permJson.length === 0) return null;
            try { return JSON.parse(toolRoot.permJson); }
            catch (error) { return null; }
        }
        readonly property bool hasPreview: toolRoot.output.trim().length > 0 || toolRoot.diffs.length > 0
        readonly property string kindGlyph: {
            switch (toolRoot.tkind) {
            case "read": return "description";
            case "edit": return "edit_note";
            case "execute": return "terminal";
            case "search": return "search";
            case "fetch": return "public";
            case "delete": return "delete";
            case "move": return "drive_file_move";
            case "think": return "psychology";
            default: return "build";
            }
        }
        readonly property var outputLines: toolRoot.output.replace(/\s+$/, "").split("\n")
        implicitHeight: toolColumn.implicitHeight

        Column {
            id: toolColumn
            width: parent.width
            spacing: Tokens.s2 * toolRoot.s

            Rectangle {
                width: parent.width
                height: 40 * toolRoot.s
                radius: Tokens.radius * toolRoot.s
                color: toolHover.hovered ? Tokens.tint10 : Tokens.tint5
                border.width: Tokens.border
                border.color: toolRoot.failed ? Tokens.alert : Tokens.lineSoft

                Text {
                    font.family: "Material Symbols Rounded"
                    id: toolGlyph
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.s3 * toolRoot.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: toolRoot.kindGlyph
                    color: toolRoot.failed ? Tokens.alert : Tokens.sun
                    font.pixelSize: Tokens.fBody * toolRoot.s
                }
                Column {
                    anchors.left: toolGlyph.right
                    anchors.right: toolStatus.left
                    anchors.leftMargin: Tokens.s3 * toolRoot.s
                    anchors.rightMargin: Tokens.s2 * toolRoot.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Text {
                        width: parent.width
                        text: toolRoot.title.length > 0 ? toolRoot.title : toolRoot.tkind.length > 0 ? toolRoot.tkind : I18n.tr("tool")
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * toolRoot.s
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        visible: toolRoot.input.length > 0 && toolRoot.title.indexOf(toolRoot.input) < 0
                        text: toolRoot.input
                        color: Tokens.inkMuted
                        font.family: Tokens.mono
                        font.pixelSize: Tokens.fSmall * toolRoot.s
                        elide: Text.ElideMiddle
                    }
                }
                Row {
                    id: toolStatus
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.s3 * toolRoot.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.s2 * toolRoot.s
                    Text {
                        visible: toolRoot.auto
                        text: I18n.tr("AUTO")
                        color: Tokens.inkFaint
                        font.family: Tokens.mono
                        font.pixelSize: Tokens.fSmall * toolRoot.s
                    }
                    Text {
                        font.family: "Material Symbols Rounded"
                        text: toolRoot.running ? "progress_activity" : toolRoot.failed ? "error" : "check"
                        color: toolRoot.failed ? Tokens.alert : Tokens.sun
                        font.pixelSize: Tokens.fSmall * toolRoot.s
                        RotationAnimation on rotation {
                            running: root.open && root.tabActive
                                && toolRoot.running && root.motionAllowed
                            from: 0
                            to: 360
                            duration: 900
                            loops: Animation.Infinite
                        }
                    }
                    Text {
                        font.family: "Material Symbols Rounded"
                        visible: toolRoot.hasPreview
                        text: "expand_more"
                        rotation: toolRoot.expanded ? 180 : 0
                        color: Tokens.inkMuted
                        font.pixelSize: Tokens.fSmall * toolRoot.s
                    }
                }
                HoverHandler { id: toolHover; enabled: toolRoot.hasPreview; cursorShape: Qt.PointingHandCursor }
                TapHandler { enabled: toolRoot.hasPreview; onTapped: toolRoot.expanded = !toolRoot.expanded }
            }

            Rectangle {
                width: parent.width
                visible: toolRoot.expanded && toolRoot.output.trim().length > 0
                implicitHeight: outputText.implicitHeight + Tokens.s4 * toolRoot.s * 2
                radius: Tokens.radius * toolRoot.s
                color: Tokens.paper
                border.width: Tokens.border
                border.color: Tokens.lineSoft
                TextEdit {
                    id: outputText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.s4 * toolRoot.s
                    text: toolRoot.outputLines.slice(0, 12).join("\n")
                        + (toolRoot.outputLines.length > 12 ? "\n" + I18n.tr("+%1 more lines").arg(toolRoot.outputLines.length - 12) : "")
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    color: Tokens.inkDim
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fSmall * toolRoot.s
                }
            }

            Repeater {
                model: toolRoot.expanded ? toolRoot.diffs : []
                delegate: Rectangle {
                    id: diffRow
                    required property var modelData
                    width: parent.width
                    implicitHeight: diffBody.implicitHeight + Tokens.s3 * toolRoot.s * 2
                    radius: Tokens.radius * toolRoot.s
                    color: Tokens.paper
                    border.width: Tokens.border
                    border.color: Tokens.lineSoft
                    Column {
                        id: diffBody
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Tokens.s3 * toolRoot.s
                        spacing: Tokens.s1 * toolRoot.s
                        Text {
                            width: parent.width
                            text: String(diffRow.modelData.path || "")
                            color: Tokens.sun
                            font.family: Tokens.mono
                            font.pixelSize: Tokens.fSmall * toolRoot.s
                            elide: Text.ElideMiddle
                        }
                        Text {
                            width: parent.width
                            visible: String(diffRow.modelData.old || "").length > 0
                            text: "− " + String(diffRow.modelData.old || "").replace(/\s+$/, "").split("\n").slice(0, 4).join("\n− ")
                            color: Tokens.alert
                            font.family: Tokens.mono
                            font.pixelSize: Tokens.fSmall * toolRoot.s
                            wrapMode: Text.WrapAnywhere
                        }
                        Text {
                            width: parent.width
                            visible: String(diffRow.modelData.new || "").length > 0
                            text: "+ " + String(diffRow.modelData.new || "").replace(/\s+$/, "").split("\n").slice(0, 4).join("\n+ ")
                            color: Tokens.ink
                            font.family: Tokens.mono
                            font.pixelSize: Tokens.fSmall * toolRoot.s
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }

            Loader {
                width: parent.width
                active: toolRoot.perm !== null
                visible: active
                sourceComponent: ApprovalView {
                    width: toolColumn.width
                    s: toolRoot.s
                    perm: toolRoot.perm
                }
            }
        }
    }

    component ComposerView: Item {
        id: composerRoot
        property real s: 1
        property var pendingImages: []
        readonly property int maxImages: 3
        readonly property real minInputHeight: 24 * composerRoot.s
        readonly property real maxInputHeight: 130 * composerRoot.s
        property int paletteIndex: 0
        property bool paletteDismissed: false
        readonly property bool slashMode: composerInput.text.length > 0 && composerInput.text.charAt(0) === "/"
            && composerInput.text.indexOf(" ") === -1 && !composerRoot.paletteDismissed
        readonly property var slashMatches: {
            if (!composerRoot.slashMode) return [];
            var prefix = composerInput.text.slice(1).toLowerCase();
            var commands = (Needle.commands || []).map(command => ({ name: String(command.name), description: String(command.description || "") }));
            return prefix === "" ? commands : commands.filter(command => command.name.toLowerCase().indexOf(prefix) === 0);
        }
        readonly property bool paletteOpen: composerRoot.slashMode && composerRoot.slashMatches.length > 0
        implicitHeight: inputFrame.implicitHeight

        function forceFocus() { Qt.callLater(composerInput.forceActiveFocus); }
        function setText(text) {
            composerInput.text = String(text);
            composerInput.cursorPosition = composerInput.text.length;
            composerInput.forceActiveFocus();
        }
        function isImagePath(path) { return /\.(png|jpe?g|webp|gif|bmp|avif|svg)$/i.test(String(path)); }
        function addImage(value) {
            var path = String(value).replace(/^file:\/\//, "");
            if (path.length === 0 || composerRoot.pendingImages.length >= composerRoot.maxImages || composerRoot.pendingImages.indexOf(path) >= 0)
                return;
            composerRoot.pendingImages = composerRoot.pendingImages.concat([path]);
        }
        function addDropUrl(url) { if (composerRoot.isImagePath(url)) composerRoot.addImage(url); }
        function removeImage(index) { composerRoot.pendingImages = composerRoot.pendingImages.filter((_, i) => i !== index); }
        function submit() {
            var text = composerInput.text.trim();
            if ((text.length === 0 && composerRoot.pendingImages.length === 0) || Needle.busy)
                return;
            Needle.send(text, composerRoot.pendingImages);
            composerInput.text = "";
            composerRoot.pendingImages = [];
        }
        function acceptSlash() {
            if (composerRoot.slashMatches.length === 0) return;
            var index = Math.max(0, Math.min(composerRoot.paletteIndex, composerRoot.slashMatches.length - 1));
            composerInput.text = "/" + composerRoot.slashMatches[index].name + " ";
            composerInput.cursorPosition = composerInput.text.length;
        }

        Process {
            id: imagePicker
            command: ["zenity", "--file-selection", "--title=" + I18n.tr("Attach an image"),
                "--file-filter=" + I18n.tr("Images") + " | *.png *.jpg *.jpeg *.webp *.gif *.bmp *.avif",
                "--file-filter=" + I18n.tr("All files") + " | *"]
            stdout: StdioCollector {
                id: pickerOutput
                onStreamFinished: {
                    var path = String(pickerOutput.text).trim();
                    if (path.length > 0 && composerRoot.isImagePath(path)) composerRoot.addImage(path);
                }
            }
        }

        Process {
            id: pasteImage
            command: ["sh", "-c",
                "t=$(wl-paste --list-types 2>/dev/null | grep -m1 -E '^image/'); [ -z \"$t\" ] && exit 0; "
                + "d=\"${XDG_RUNTIME_DIR:-/tmp}/ryoku-chat\"; mkdir -p \"$d\"; ext=${t#image/}; "
                + "case \"$ext\" in jpeg) ext=jpg;; svg+xml) ext=svg;; esac; "
                + "f=\"$d/paste-$(date +%s%N).$ext\"; wl-paste --type \"$t\" > \"$f\" 2>/dev/null && printf '%s' \"$f\""]
            stdout: StdioCollector {
                id: pasteOutput
                onStreamFinished: {
                    var path = String(pasteOutput.text).trim();
                    if (path.length > 0) composerRoot.addImage(path);
                }
            }
        }

        Rectangle {
            id: commandPalette
            visible: composerRoot.paletteOpen
            anchors.left: inputFrame.left
            anchors.right: inputFrame.right
            anchors.bottom: inputFrame.top
            anchors.bottomMargin: 6 * composerRoot.s
            height: Math.min(composerRoot.slashMatches.length * 30 * composerRoot.s, 180 * composerRoot.s) + 8 * composerRoot.s
            radius: 10 * composerRoot.s
            color: Qt.rgba(Theme.effectiveSurface.r, Theme.effectiveSurface.g, Theme.effectiveSurface.b, 0.98)
            border.width: Theme.borderWidth
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
            z: 4
            clip: true

            ListView {
                anchors.fill: parent
                anchors.margins: 4 * composerRoot.s
                model: composerRoot.slashMatches
                currentIndex: composerRoot.paletteIndex
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded; motionEnabled: root.motionAllowed }
                delegate: Rectangle {
                    id: commandRow
                    required property var modelData
                    required property int index
                    width: ListView.view ? ListView.view.width : 0
                    height: 30 * composerRoot.s
                    radius: 6 * composerRoot.s
                    color: composerRoot.paletteIndex === commandRow.index
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                        : "transparent"
                    Text {
                        id: commandName
                        anchors.left: parent.left
                        anchors.leftMargin: 8 * composerRoot.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: 82 * composerRoot.s
                        text: "/" + commandRow.modelData.name
                        color: Theme.primary
                        font.family: Theme.mono
                        font.pixelSize: 11 * composerRoot.s
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors.left: commandName.right
                        anchors.right: parent.right
                        anchors.rightMargin: 8 * composerRoot.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: commandRow.modelData.description
                        color: root.dim
                        font.family: Theme.fontPrimary
                        font.pixelSize: 10.5 * composerRoot.s
                        elide: Text.ElideRight
                    }
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered) composerRoot.paletteIndex = commandRow.index
                    }
                    TapHandler {
                        onTapped: {
                            composerRoot.paletteIndex = commandRow.index;
                            composerRoot.acceptSlash();
                            composerInput.forceActiveFocus();
                        }
                    }
                }
            }
        }

        Rectangle {
            id: inputFrame
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            implicitHeight: inputColumn.implicitHeight + 14 * composerRoot.s
            radius: Theme.radiusWidget
            color: Theme.surface
            border.width: Theme.borderWidth
            border.color: composerInput.activeFocus ? Theme.primary : Theme.outline
            Behavior on border.color {
                enabled: root.motionAllowed
                ColorAnimation { duration: Motion.fast }
            }

            Column {
                id: inputColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 7 * composerRoot.s
                spacing: 7 * composerRoot.s

                Flow {
                    width: parent.width
                    spacing: 6 * composerRoot.s
                    visible: composerRoot.pendingImages.length > 0
                    Repeater {
                        model: composerRoot.pendingImages
                        delegate: Rectangle {
                            id: pendingImage
                            required property int index
                            required property string modelData
                            width: 46 * composerRoot.s
                            height: width
                            radius: 6 * composerRoot.s
                            color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.06)
                            clip: true
                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: "file://" + pendingImage.modelData
                                asynchronous: true
                            }
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                width: 16 * composerRoot.s
                                height: width
                                radius: width / 2
                                color: Qt.rgba(0, 0, 0, 0.65)
                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: "white"
                                    font.pixelSize: 11 * composerRoot.s
                                }
                                TapHandler { onTapped: composerRoot.removeImage(pendingImage.index) }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(26 * composerRoot.s, inputScroll.height)

                    Rectangle {
                        id: attachButton
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        width: 26 * composerRoot.s
                        height: width
                        radius: width / 2
                        enabled: composerRoot.pendingImages.length < composerRoot.maxImages
                        opacity: enabled ? 1 : 0.4
                        color: attachHover.hovered
                            ? Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.10)
                            : "transparent"
                        Behavior on color {
                            enabled: root.motionAllowed
                            ColorAnimation { duration: Motion.fast }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "add_photo_alternate"
                            color: root.dim
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15 * composerRoot.s
                        }
                        HoverHandler { id: attachHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: if (attachButton.enabled) imagePicker.running = true }
                    }

                    ScrollView {
                        id: inputScroll
                        anchors.left: attachButton.right
                        anchors.right: sendButton.left
                        anchors.leftMargin: 6 * composerRoot.s
                        anchors.rightMargin: 6 * composerRoot.s
                        anchors.verticalCenter: parent.verticalCenter
                        height: Math.min(composerRoot.maxInputHeight, Math.max(composerRoot.minInputHeight, composerInput.implicitHeight))
                        clip: true
                        TextArea {
                            id: composerInput
                            background: null
                            padding: 0
                            wrapMode: TextArea.Wrap
                            placeholderText: I18n.tr("Message the needle")
                            placeholderTextColor: root.dim
                            color: root.ink
                            selectionColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
                            selectByMouse: true
                            font.family: Theme.fontPrimary
                            font.pixelSize: 12.5 * composerRoot.s
                            onTextChanged: {
                                composerRoot.paletteIndex = 0;
                                composerRoot.paletteDismissed = false;
                            }
                            Keys.onPressed: event => {
                                if (composerRoot.paletteOpen && event.key === Qt.Key_Down) {
                                    composerRoot.paletteIndex = Math.min(composerRoot.paletteIndex + 1, composerRoot.slashMatches.length - 1);
                                    event.accepted = true;
                                } else if (composerRoot.paletteOpen && event.key === Qt.Key_Up) {
                                    composerRoot.paletteIndex = Math.max(composerRoot.paletteIndex - 1, 0);
                                    event.accepted = true;
                                } else if (composerRoot.paletteOpen && (event.key === Qt.Key_Tab || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                                    composerRoot.acceptSlash();
                                    event.accepted = true;
                                } else if (composerRoot.slashMode && event.key === Qt.Key_Escape) {
                                    composerRoot.paletteDismissed = true;
                                    event.accepted = true;
                                } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                                    composerRoot.submit();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape && Needle.busy) {
                                    Needle.cancel();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_V && (event.modifiers & Qt.ControlModifier)) {
                                    pasteImage.running = true;
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: sendButton
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        width: 26 * composerRoot.s
                        height: width
                        radius: width / 2
                        readonly property bool ready: composerInput.text.trim().length > 0 || composerRoot.pendingImages.length > 0
                        color: Needle.busy
                            ? Qt.rgba(Theme.vermLit.r, Theme.vermLit.g, Theme.vermLit.b, 0.18)
                            : sendButton.ready ? Theme.primary
                            : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.08)
                        Behavior on color {
                            enabled: root.motionAllowed
                            ColorAnimation { duration: Motion.fast }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: Needle.busy ? "stop" : "arrow_upward"
                            color: Needle.busy ? Theme.vermLit
                                : sendButton.ready ? Theme.inkOn(Theme.primary, Theme.onPrimary)
                                : root.dim
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15 * composerRoot.s
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Needle.busy ? Needle.cancel() : composerRoot.submit() }
                    }
                }
            }
        }
    }

    component ModelPickerView: Item {
        id: pickerRoot
        property real s: 1
        property bool open: false
        property bool wide: false
        signal closed()
        visible: opacity > 0.01
        enabled: pickerRoot.open
        opacity: pickerRoot.open ? 1 : 0
        z: 70
        Behavior on opacity {
            enabled: root.motionAllowed
            NumberAnimation { duration: Tokens.dur(140); easing.type: Tokens.ease }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.58)
            TapHandler { onTapped: pickerRoot.closed() }
        }
        Rectangle {
            id: pickerPanel
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Tokens.s5 * pickerRoot.s
            width: Math.min(parent.width - Tokens.s6 * pickerRoot.s,
                (pickerRoot.wide ? 520 : 330) * pickerRoot.s)
            height: Math.min(500 * pickerRoot.s, parent.height - Tokens.s6 * pickerRoot.s)
            radius: Tokens.radius * pickerRoot.s
            color: Tokens.paperLift
            border.width: Tokens.border
            border.color: Tokens.lineStrong
            TapHandler { }

            readonly property string query: modelSearch.text.trim().toLowerCase()
            readonly property var filteredModels: {
                var all = Needle.models || [];
                var current = Needle.currentModel;
                var out = [];
                var pinned = null;
                for (var i = 0; i < all.length; i++) {
                    var model = all[i];
                    var name = String(model.name || model.id).toLowerCase();
                    var id = String(model.id).toLowerCase();
                    if (pickerPanel.query.length > 0 && name.indexOf(pickerPanel.query) < 0 && id.indexOf(pickerPanel.query) < 0)
                        continue;
                    if (model.id === current) pinned = model;
                    else out.push(model);
                }
                if (pinned) out.unshift(pinned);
                return out;
            }
            function provider(id) {
                var text = String(id);
                var cut = text.indexOf("/");
                return cut >= 0 ? text.slice(0, cut) : "";
            }

            Column {
                anchors.fill: parent
                anchors.margins: Tokens.s4 * pickerRoot.s
                spacing: Tokens.s2 * pickerRoot.s

                Text {
                    text: I18n.tr("AGENT")
                    color: Tokens.inkMuted
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fSmall * pickerRoot.s
                    font.letterSpacing: Tokens.trackMark
                }
                Repeater {
                    model: Needle.backends
                    delegate: Rectangle {
                        id: backendRow
                        required property var modelData
                        width: parent.width
                        height: 34 * pickerRoot.s
                        radius: Tokens.radius * pickerRoot.s
                        readonly property bool active: backendRow.modelData.active === true
                        readonly property bool available: backendRow.modelData.available === true
                        color: backendHover.hovered && backendRow.available ? Tokens.tint10
                            : backendRow.active ? Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.13) : "transparent"
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.s3 * pickerRoot.s
                            anchors.right: backendState.left
                            anchors.rightMargin: Tokens.s2 * pickerRoot.s
                            anchors.verticalCenter: parent.verticalCenter
                            text: backendRow.modelData.name || backendRow.modelData.id
                            color: backendRow.active ? Tokens.sun : backendRow.available ? Tokens.ink : Tokens.inkFaint
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall * pickerRoot.s
                            font.weight: backendRow.active ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }
                        Text {
                            id: backendState
                            anchors.right: parent.right
                            anchors.rightMargin: Tokens.s3 * pickerRoot.s
                            anchors.verticalCenter: parent.verticalCenter
                            text: backendRow.active ? "✓" : backendRow.available ? "" : I18n.tr("needs adapter")
                            color: backendRow.active ? Tokens.sun : Tokens.inkFaint
                            font.family: Tokens.mono
                            font.pixelSize: Tokens.fSmall * pickerRoot.s
                        }
                        HoverHandler { id: backendHover; enabled: backendRow.available; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            enabled: backendRow.available
                            onTapped: {
                                Needle.setBackend(backendRow.modelData.id);
                                pickerRoot.closed();
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Tokens.lineSoft; visible: Needle.models.length > 0 }

                Field {
                    id: modelSearch
                    width: parent.width
                    visible: Needle.models.length > 0
                    placeholder: I18n.tr("Filter models")
                }

                ListView {
                    width: parent.width
                    height: parent.height - y
                    visible: Needle.models.length > 0
                    clip: true
                    model: pickerPanel.filteredModels
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: 900
                    ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded; motionEnabled: root.motionAllowed }
                    delegate: Rectangle {
                        id: modelRow
                        required property var modelData
                        width: ListView.view ? ListView.view.width : 0
                        height: 38 * pickerRoot.s
                        radius: Tokens.radius * pickerRoot.s
                        readonly property bool current: Needle.currentModel === modelRow.modelData.id
                        color: modelRowHover.hovered ? Tokens.tint10
                            : modelRow.current ? Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.13) : "transparent"
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.s3 * pickerRoot.s
                            anchors.right: providerTag.left
                            anchors.rightMargin: Tokens.s2 * pickerRoot.s
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelRow.modelData.name || modelRow.modelData.id
                            color: modelRow.current ? Tokens.sun : Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall * pickerRoot.s
                            font.weight: modelRow.current ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }
                        Text {
                            id: providerTag
                            anchors.right: parent.right
                            anchors.rightMargin: Tokens.s3 * pickerRoot.s
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelRow.current ? "✓" : pickerPanel.provider(modelRow.modelData.id)
                            color: modelRow.current ? Tokens.sun : Tokens.inkFaint
                            font.family: Tokens.mono
                            font.pixelSize: Tokens.fTiny * pickerRoot.s
                        }
                        HoverHandler { id: modelRowHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                Needle.setModel(modelRow.modelData.id);
                                pickerRoot.closed();
                            }
                        }
                    }
                }
            }
        }
    }
}
