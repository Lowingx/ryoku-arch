import QtQuick
import QtQuick.Controls
import RashinApp

// One transcript row: a user bubble, an agent reply (thinking folds to a
// line the reader can reopen), or a tool call (one row with a peek at its
// output, and the approval that waits on it inline). Rows are pure
// projections of the bridge's model; they never hold state the daemon owns.
Item {
    id: row

    required property int index
    required property string kind
    required property string role
    required property string body
    required property string thought
    required property bool cont
    required property bool live
    required property var images
    required property string title
    required property string toolKind
    required property string status
    required property string toolInput
    required property string toolOutput
    required property var diffs
    required property bool autoApproved
    required property var perm
    property real s: 1

    readonly property bool isTool: kind === "tool"
    readonly property bool isUser: role === "user"
    readonly property bool hasPerm: perm && Object.keys(perm).length > 0
    property bool thoughtOpen: false
    property bool outputOpen: false

    implicitHeight: content.implicitHeight
    width: parent.width

    // A row enters once, rising into place; streaming updates never re-trigger
    // it, so the timeline stays calm while text pours in.
    property bool entered: false
    opacity: entered ? 1 : 0
    transform: Translate { y: row.entered ? 0 : 10 * row.s }
    Component.onCompleted: {
        if (Theme.reduceMotion)
            entered = true;
        else
            enterTimer.start();
    }
    Timer {
        id: enterTimer
        interval: 16
        onTriggered: row.entered = true
    }
    Behavior on opacity {
        enabled: !Theme.reduceMotion
        NumberAnimation { duration: Theme.move; easing.type: Easing.OutQuint }
    }

    Column {
        id: content
        width: parent.width
        spacing: Theme.s2 * row.s

        Text {
            visible: !row.isTool && !row.cont
            anchors.right: row.isUser ? parent.right : undefined
            text: row.isUser ? qsTr("YOU") : qsTr("RASHIN")
            color: row.isUser ? Theme.inkMuted : Theme.inkDim
            font.family: Theme.mono
            font.pixelSize: Theme.fTinyPx * row.s
            font.letterSpacing: Theme.trackLabel
        }

        // ---- user bubble ------------------------------------------------------
        Rectangle {
            visible: !row.isTool && row.isUser
            anchors.right: parent.right
            width: Math.min(parent.width * 0.78, 560 * row.s)
            height: userText.implicitHeight + Theme.s3 * row.s * 2
            radius: Theme.radius * row.s
            color: Theme.bone
            TextEdit {
                id: userText
                anchors.fill: parent
                anchors.margins: Theme.s3 * row.s
                text: row.body
                color: Theme.inkOnBone
                font.family: Theme.ui
                font.pixelSize: Theme.fSmallPx * row.s
                wrapMode: TextEdit.Wrap
                readOnly: true
                selectByMouse: true
            }
        }

        // ---- attachments ------------------------------------------------------
        Flow {
            width: parent.width
            visible: !row.isTool && row.images.length > 0
            spacing: Theme.s2 * row.s
            Repeater {
                model: row.images
                delegate: Rectangle {
                    required property var modelData
                    readonly property string dataUrl: "data:"
                        + (modelData && modelData.mimeType ? modelData.mimeType : "image/png")
                        + ";base64," + (modelData && modelData.data ? modelData.data : "")
                    width: 72 * row.s
                    height: width
                    radius: Theme.radius * row.s
                    color: Theme.tint5
                    border.width: Theme.border
                    border.color: Theme.line
                    clip: true
                    // The base64 payload rides modelData.data; a data: URL is
                    // the only way QML paints it without a temp file.
                    Image {
                        anchors.fill: parent
                        source: parent.dataUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Qt.openUrlExternally(parent.dataUrl) }
                }
            }
        }

        // ---- thinking fold ------------------------------------------------------
        Column {
            visible: !row.isTool && !row.isUser && row.thought.length > 0
            width: parent.width
            spacing: Theme.s1 * row.s
            Row {
                spacing: Theme.s1 * row.s
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.thoughtOpen ? "expand_more" : "chevron_right"
                    color: Theme.inkMuted
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Theme.fSmallPx * row.s
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.live && row.body.length === 0 ? qsTr("thinking…") : qsTr("Thought")
                    color: Theme.inkMuted
                    font.family: Theme.ui
                    font.pixelSize: Theme.fTinyPx * row.s
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: row.thoughtOpen = !row.thoughtOpen }
            }
            Text {
                visible: row.thoughtOpen
                width: parent.width
                text: row.thought
                color: Theme.inkMuted
                font.family: Theme.ui
                font.pixelSize: Theme.fTinyPx * row.s
                wrapMode: Text.Wrap
                opacity: visible ? 1 : 0
                Behavior on opacity {
                    enabled: !Theme.reduceMotion
                    NumberAnimation { duration: Theme.swap }
                }
            }
        }

        // ---- agent reply --------------------------------------------------------
        TextEdit {
            id: agentText
            visible: !row.isTool && !row.isUser && row.body.length > 0
            width: parent.width
            textFormat: Text.RichText
            text: Markdown.toHtml(row.body)
            color: Theme.ink
            font.family: Theme.ui
            font.pixelSize: Theme.fBodyPx * row.s
            wrapMode: Text.Wrap
            readOnly: true
            selectByMouse: true
            persistentSelection: true
            onLinkActivated: link => Qt.openUrlExternally(link)
            // The live caret: a thin bone line while the answer streams.
            Rectangle {
                visible: row.live
                width: 2
                height: Theme.fBodyPx * row.s
                x: 0
                y: agentText.height - height
                radius: 1
                color: Theme.bone
                SequentialAnimation on opacity {
                    running: row.live && !Theme.reduceMotion
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.15; duration: Theme.dur; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.15; to: 1; duration: Theme.dur; easing.type: Easing.InOutSine }
                    onStopped: opacity = 1
                }
            }
        }

        // ---- tool row -----------------------------------------------------------
        Rectangle {
            visible: row.isTool
            width: parent.width
            height: toolCol.implicitHeight + Theme.s3 * row.s * 2
            radius: Theme.radius * row.s
            color: Theme.tint5
            border.width: Theme.border
            border.color: Theme.line
            Column {
                id: toolCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.s3 * row.s
                spacing: Theme.s1 * row.s

                Row {
                    width: parent.width
                    spacing: Theme.s2 * row.s
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.status === "completed" ? "check_circle"
                            : row.status === "failed" ? "error" : "pending"
                        color: row.status === "completed" ? Theme.ok
                            : row.status === "failed" ? Theme.alert : Theme.inkMuted
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Theme.fBodyPx * row.s
                        SequentialAnimation on rotation {
                            running: row.status === "pending" || row.status === "in_progress"
                            loops: Animation.Infinite
                            NumberAnimation { from: 0; to: 360; duration: 1600 }
                            onStopped: rotation = 0
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 60 * row.s
                        text: row.title.length > 0 ? row.title : (row.toolKind.length > 0 ? row.toolKind : qsTr("tool"))
                        color: Theme.ink
                        font.family: Theme.ui
                        font.pixelSize: Theme.fSmallPx * row.s
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.autoApproved
                        width: autoLabel.implicitWidth + Theme.s2 * row.s
                        height: 18 * row.s
                        radius: 9 * row.s
                        color: Theme.tint10
                        Text {
                            id: autoLabel
                            anchors.centerIn: parent
                            text: qsTr("AUTO")
                            color: Theme.inkMuted
                            font.family: Theme.mono
                            font.pixelSize: Theme.fMicroPx * row.s
                            font.letterSpacing: Theme.trackLabel
                        }
                    }
                }

                // The peek: output folds open; diffs list the files touched.
                Text {
                    visible: row.toolInput.length > 0 && row.outputOpen
                    width: parent.width
                    text: row.toolInput
                    color: Theme.inkDim
                    font.family: Theme.mono
                    font.pixelSize: Theme.fTinyPx * row.s
                    wrapMode: Text.Wrap
                    maximumLineCount: 8
                    elide: Text.ElideRight
                }
                Text {
                    visible: row.toolOutput.length > 0 && row.outputOpen
                    width: parent.width
                    text: row.toolOutput
                    color: Theme.inkMuted
                    font.family: Theme.mono
                    font.pixelSize: Theme.fTinyPx * row.s
                    wrapMode: Text.Wrap
                    maximumLineCount: 12
                    elide: Text.ElideRight
                }
                Repeater {
                    model: row.diffs
                    delegate: Row {
                        required property var modelData
                        spacing: Theme.s1 * row.s
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "description"
                            color: Theme.inkMuted
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Theme.fTinyPx * row.s
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.path || ""
                            color: Theme.inkDim
                            font.family: Theme.mono
                            font.pixelSize: Theme.fTinyPx * row.s
                        }
                    }
                }
                Row {
                    visible: row.toolOutput.length > 0 || row.toolInput.length > 0 || row.diffs.length > 0
                    spacing: Theme.s1 * row.s
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.outputOpen ? "expand_less" : "expand_more"
                        color: Theme.inkFaint
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Theme.fTinyPx * row.s
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.outputOpen ? qsTr("hide output") : qsTr("show output")
                        color: Theme.inkFaint
                        font.family: Theme.ui
                        font.pixelSize: Theme.fTinyPx * row.s
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: row.outputOpen = !row.outputOpen }
                }
            }
        }

        // ---- inline approval ------------------------------------------------------
        Rectangle {
            visible: row.isTool && row.hasPerm
            width: parent.width
            height: permCol.implicitHeight + Theme.s4 * row.s * 2
            radius: Theme.radius * row.s
            color: Theme.tint10
            border.width: Theme.border
            border.color: Theme.lineStrong
            Column {
                id: permCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.s4 * row.s
                spacing: Theme.s2 * row.s
                Text {
                    text: qsTr("RASHIN WANTS TO")
                    color: Theme.inkMuted
                    font.family: Theme.mono
                    font.pixelSize: Theme.fMicroPx * row.s
                    font.letterSpacing: Theme.trackLabel
                }
                Text {
                    width: parent.width
                    text: row.perm.title || ""
                    color: Theme.ink
                    font.family: Theme.ui
                    font.pixelSize: Theme.fSmallPx * row.s
                    wrapMode: Text.Wrap
                }
                Flow {
                    width: parent.width
                    spacing: Theme.s2 * row.s
                    Repeater {
                        model: row.perm.options || []
                        delegate: Pill {
                            required property var modelData
                            required property int index
                            compact: true
                            primary: index === 0
                            text: modelData.name || modelData.id || ""
                            onAct: ChatBridge.answerPermission(String(row.perm.requestId || ""), String(modelData.id || ""))
                        }
                    }
                    Pill {
                        compact: true
                        text: qsTr("Decline")
                        onAct: ChatBridge.answerPermission(String(row.perm.requestId || ""), "")
                    }
                }
            }
        }
    }
}
