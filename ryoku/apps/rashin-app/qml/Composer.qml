import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import RashinApp

// The chat composer: a growing field over a bone send button, with image
// attachments and slash-command completion. Enter sends, Shift+Enter is a
// newline, and the draft rides Preferences so a closed app never eats a half
// written message. The busy state is the daemon's, never a local guess.
Rectangle {
    id: composer

    property alias text: field.text
    property var attachments: []
    readonly property bool motionAllowed: !Theme.reduceMotion

    signal send(string text, var images)
    signal cancelRequested()

    implicitHeight: 64 + (attachments.length > 0 ? 44 : 0)
    radius: Theme.radiusLg
    color: Theme.paperLift
    border.width: Theme.border
    border.color: field.activeFocus ? Theme.lineStrong : Theme.line
    Behavior on border.color { ColorAnimation { duration: Theme.snap } }

    function focusField() {
        Qt.callLater(() => field.forceActiveFocus());
    }

    function submit() {
        const t = field.text.trim();
        if (t.length === 0 && attachments.length === 0)
            return;
        composer.send(t, attachments);
        field.text = "";
        attachments = [];
    }

    function removeAttachment(index) {
        const list = attachments.slice();
        list.splice(index, 1);
        attachments = list;
    }

    FileDialog {
        id: filePick
        title: qsTr("Attach an image")
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.gif)"]
        fileMode: FileDialog.OpenFiles
        onAccepted: {
            const list = composer.attachments.slice();
            for (const url of selectedFiles) {
                const p = url.toString();
                list.push(p.startsWith("file://") ? decodeURIComponent(p.slice(7)) : p);
            }
            composer.attachments = list;
        }
    }

    // Slash commands the agent advertised: typing "/" opens the list, Tab or
    // Enter completes the current one.
    Popup {
        id: slashPop
        parent: Overlay.overlay
        x: {
            const at = composer.mapToGlobal(0, 0);
            return Math.max(8, Math.min(at.x, (parent ? parent.width : 1000) - width - 8));
        }
        y: composer.mapToGlobal(0, 0).y - height - 8
        width: 320
        padding: Theme.s2
        visible: slashList.count > 0 && field.text.startsWith("/") && !field.text.includes(" ")
        modal: false
        closePolicy: Popup.NoAutoClose
        background: Rectangle {
            radius: Theme.radius
            color: Theme.paperLift
            border.width: Theme.border
            border.color: Theme.lineStrong
        }
        contentItem: ListView {
            id: slashList
            width: 312
            height: Math.min(contentHeight, 180)
            clip: true
            model: ChatBridge.commands
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                required property var modelData
                width: slashList.width
                height: 34
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.s3
                    spacing: Theme.s2
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "/" + (modelData.name || "")
                        color: Theme.ink
                        font.family: Theme.mono
                        font.pixelSize: Theme.fSmallPx
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.parent.width - implicitWidth - Theme.s6
                        text: modelData.description || ""
                        color: Theme.inkMuted
                        font.family: Theme.ui
                        font.pixelSize: Theme.fTinyPx
                        elide: Text.ElideRight
                    }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        field.text = "/" + (modelData.name || "") + " ";
                        field.cursorPosition = field.text.length;
                    }
                }
            }
        }
    }

    Row {
        id: attachRow
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Theme.s3
        visible: attachments.length > 0
        spacing: Theme.s2
        Repeater {
            model: attachments
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: 40
                height: width
                radius: Theme.radiusSm
                clip: true
                color: Theme.tint5
                border.width: Theme.border
                border.color: Theme.line
                Image {
                    anchors.fill: parent
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 2
                    width: 16
                    height: width
                    radius: 8
                    color: Theme.paper
                    border.width: 1
                    border.color: Theme.lineStrong
                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        color: Theme.inkDim
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 11
                    }
                    TapHandler { onTapped: composer.removeAttachment(index) }
                }
            }
        }
    }

    IconBtn {
        id: attachBtn
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Theme.s3
        glyph: "attach_file"
        onAct: filePick.open()
    }

    Flickable {
        id: scroll
        anchors.left: attachBtn.right
        anchors.right: sendCol.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: attachments.length > 0 ? 56 : Theme.s3
        anchors.leftMargin: Theme.s2
        anchors.rightMargin: Theme.s2
        contentHeight: field.height
        clip: true

        TextArea {
            id: field
            width: scroll.width
            color: Theme.ink
            placeholderText: qsTr("Message Rashin…")
            placeholderTextColor: Theme.inkFaint
            font.family: Theme.ui
            font.pixelSize: Theme.fBodyPx
            wrapMode: TextArea.Wrap
            leftPadding: 0
            rightPadding: 0
            topPadding: Theme.s2
            bottomPadding: Theme.s2
            // Grow with the text, cap at five lines so the window never
            // slides out from under it.
            height: Math.min(implicitHeight, Theme.ctlH * 5)
            onTextChanged: Preferences.setDraft("new", field.text)

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                    if (!slashPop.visible) {
                        composer.submit();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Tab && slashPop.visible && slashList.count > 0) {
                    const first = ChatBridge.commands[0];
                    field.text = "/" + (first.name || "") + " ";
                    field.cursorPosition = field.text.length;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape && ChatBridge.busy) {
                    composer.cancelRequested();
                    event.accepted = true;
                }
            }
        }
    }

    Column {
        id: sendCol
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.s3
        spacing: Theme.s1

        Rectangle {
            id: sendBtn
            width: 38
            height: width
            radius: 12
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property bool live: field.text.trim().length > 0 || attachments.length > 0
            color: live ? Theme.bone : Theme.tint5
            border.width: Theme.border
            border.color: live ? Theme.bone : Theme.line
            Behavior on color { ColorAnimation { duration: Theme.swap } }
            Text {
                anchors.centerIn: parent
                text: ChatBridge.busy ? "stop" : "arrow_upward"
                color: ChatBridge.busy ? Theme.alert : sendBtn.live ? Theme.inkOnBone : Theme.inkFaint
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                Behavior on color { ColorAnimation { duration: Theme.swap } }
            }
            scale: tap.pressed ? 0.92 : 1
            Behavior on scale {
                enabled: composer.motionAllowed
                NumberAnimation { duration: Theme.snap; easing.type: Easing.OutCubic }
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler {
                id: tap
                onTapped: {
                    if (ChatBridge.busy)
                        composer.cancelRequested();
                    else
                        composer.submit();
                }
            }
        }
    }
}
