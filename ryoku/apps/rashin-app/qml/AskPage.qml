import QtQuick
import QtQuick.Controls
import RashinApp

// The ask page: the launcher's fast lane with room to breathe. One question
// in, one answer out, streamed by the daemon; the answer's action chips
// (copy, open file, open folder, run command, colour) do the obvious thing,
// and every completed ask lands in the history drawer on the right. Ask
// answers are quick; "Continue in chat" hands the thread to the shared
// session and jumps to the chat page.
Item {
    id: page

    property string question: ""
    property bool historyOpen: false
    property var recent: []
    readonly property var ask: askObj
    QuickAsk { id: askObj }

    Connections {
        target: askObj
        function onRecentReady(recent) {
            page.recent = recent;
        }
    }

    Component.onCompleted: askObj.loadRecent()

    function submit() {
        const t = question.trim();
        if (t.length === 0 || askObj.busy)
            return;
        askObj.ask(t);
    }

    function pickRecent(entry) {
        askObj.recall(entry);
        historyOpen = false;
    }

    function fireChip(chip) {
        const kind = String(chip.kind || "");
        const value = String(chip.value || "");
        if (kind === "cmd" || kind === "color")
            Clipboard.copy(value);
        else if (kind === "file")
            Qt.openUrlExternally("file://" + value);
        else if (kind === "dir" || kind === "url")
            Qt.openUrlExternally(value.startsWith("file://") || value.startsWith("http")
                ? value : "file://" + value);
    }

    // ---- layout ---------------------------------------------------------------
    Flickable {
        anchors.fill: parent
        anchors.margins: Theme.s6
        contentHeight: col.height
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: col
            width: parent.width
            spacing: Theme.s4

            Text {
                text: qsTr("QUICK ASK")
                color: Theme.inkMuted
                font.family: Theme.mono
                font.pixelSize: Theme.fMicroPx
                font.letterSpacing: Theme.trackMark
            }

            // The question field.
            Rectangle {
                id: field
                width: parent.width
                height: Math.max(56, qField.implicitHeight + Theme.s4 * 2)
                radius: Theme.radius
                color: Theme.paperLift
                border.width: Theme.border
                border.color: qField.activeFocus ? Theme.lineStrong : Theme.line
                Behavior on border.color { ColorAnimation { duration: Theme.snap } }

                TextArea {
                    id: qField
                    anchors.left: parent.left
                    anchors.right: goBtn.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.s4
                    anchors.rightMargin: Theme.s3
                    color: Theme.ink
                    placeholderText: qsTr("Ask anything…")
                    placeholderTextColor: Theme.inkFaint
                    font.family: Theme.ui
                    font.pixelSize: Theme.fValuePx
                    wrapMode: TextArea.Wrap
                    background: null
                    onTextChanged: page.question = text
                    Keys.onReturnPressed: event => {
                        if (!(event.modifiers & Qt.ShiftModifier)) {
                            page.submit();
                            event.accepted = true;
                        }
                    }
                }
                Rectangle {
                    id: goBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Theme.s3
                    width: 40
                    height: 40
                    radius: 12
                    readonly property bool live: page.question.trim().length > 0 && !askObj.busy
                    color: live ? Theme.bone : Theme.tint5
                    border.width: Theme.border
                    border.color: live ? Theme.bone : Theme.line
                    Behavior on color { ColorAnimation { duration: Theme.swap } }
                    Text {
                        anchors.centerIn: parent
                        text: askObj.busy ? "stop" : "arrow_forward"
                        color: askObj.busy ? Theme.alert : goBtn.live ? Theme.inkOnBone : Theme.inkFaint
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            if (askObj.busy)
                                askObj.cancel();
                            else
                                page.submit();
                        }
                    }
                }
            }

            // The working strip.
            Row {
                visible: askObj.busy
                spacing: Theme.s2
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "pending"
                    color: Theme.inkMuted
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Theme.fBodyPx
                    SequentialAnimation on rotation {
                        running: askObj.busy && !Theme.reduceMotion
                        loops: Animation.Infinite
                        NumberAnimation { from: 0; to: 360; duration: 1600 }
                        onStopped: rotation = 0
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: askObj.working.length > 0 ? askObj.working : qsTr("thinking…")
                    color: Theme.inkDim
                    font.family: Theme.ui
                    font.pixelSize: Theme.fSmallPx
                    SequentialAnimation on opacity {
                        running: askObj.busy && !Theme.reduceMotion
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.6; duration: Theme.dur; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.6; to: 1; duration: Theme.dur; easing.type: Easing.InOutSine }
                        onStopped: opacity = 1
                    }
                }
            }

            // The answer.
            TextEdit {
                visible: askObj.answerText.length > 0
                width: parent.width
                textFormat: Text.RichText
                text: Markdown.toHtml(askObj.answerText)
                color: Theme.ink
                font.family: Theme.ui
                font.pixelSize: Theme.fBodyPx
                wrapMode: Text.Wrap
                readOnly: true
                selectByMouse: true
                persistentSelection: true
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Row {
                visible: askObj.errorText.length > 0
                spacing: Theme.s2
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: width; radius: 3
                    color: Theme.alert
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: askObj.errorText
                    color: Theme.inkDim
                    font.family: Theme.ui
                    font.pixelSize: Theme.fSmallPx
                    wrapMode: Text.Wrap
                }
            }

            Flow {
                visible: askObj.done
                width: parent.width
                spacing: Theme.s2
                Pill {
                    compact: true
                    text: qsTr("Copy")
                    onAct: Clipboard.copy(askObj.answerText)
                }
                Repeater {
                    model: askObj.actions
                    delegate: Pill {
                        required property var modelData
                        compact: true
                        text: modelData.label || ""
                        onAct: page.fireChip(modelData)
                    }
                }
                Pill {
                    compact: true
                    primary: true
                    text: qsTr("Continue in chat")
                    onAct: {
                        const q = askObj.question;
                        ChatBridge.send(q);
                        const win = page.Window.window;
                        if (win)
                            win.navigate("chat");
                    }
                }
            }

            // Answer images.
            Flow {
                visible: askObj.images.length > 0
                width: parent.width
                spacing: Theme.s2
                Repeater {
                    model: askObj.images
                    delegate: Rectangle {
                        required property var modelData
                        width: 92
                        height: width
                        radius: Theme.radius
                        color: Theme.tint5
                        border.width: Theme.border
                        border.color: Theme.line
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: "file://" + modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Qt.openUrlExternally("file://" + modelData) }
                    }
                }
            }
        }
    }

    // ---- the history drawer ----------------------------------------------------
    // Recent asks slide in from the right edge; picking one recalls its stored
    // answer instantly, no model call.
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: page.historyOpen ? 320 : 0
        visible: width > 0
        clip: true
        color: Theme.surfaceLow
        Behavior on width {
            enabled: !Theme.reduceMotion
            NumberAnimation { duration: Theme.move; easing.type: Easing.OutQuint }
        }
        Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: Theme.line }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.s3
            spacing: Theme.s2
            Row {
                width: parent.width
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("HISTORY")
                    color: Theme.inkMuted
                    font.family: Theme.mono
                    font.pixelSize: Theme.fMicroPx
                    font.letterSpacing: Theme.trackMark
                }
                Item { width: parent.width - 70; height: 1 }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "close"
                    size: 24
                    onAct: page.historyOpen = false
                }
            }
            ListView {
                id: recList
                width: parent.width
                height: page.height - 120
                clip: true
                model: page.recent
                spacing: Theme.s1
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Rectangle {
                    required property var modelData
                    width: recList.width
                    height: 56
                    radius: Theme.radiusSm
                    color: recHover.hovered ? Theme.tint10 : "transparent"
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
                            text: String(modelData.q || "")
                            color: Theme.ink
                            font.family: Theme.ui
                            font.pixelSize: Theme.fSmallPx
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: String(modelData.a || "").replace(/\n/g, " ")
                            color: Theme.inkMuted
                            font.family: Theme.ui
                            font.pixelSize: Theme.fTinyPx
                            elide: Text.ElideRight
                        }
                    }
                    HoverHandler { id: recHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: page.pickRecent(modelData) }
                }
                Text {
                    anchors.centerIn: parent
                    visible: recList.count === 0
                    text: qsTr("No recent asks")
                    color: Theme.inkFaint
                    font.family: Theme.ui
                    font.pixelSize: Theme.fSmallPx
                }
            }
        }
    }

    IconBtn {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.s4
        glyph: "history"
        active: page.historyOpen
        onAct: {
            page.historyOpen = !page.historyOpen;
            if (page.historyOpen)
                askObj.loadRecent();
        }
    }
}
