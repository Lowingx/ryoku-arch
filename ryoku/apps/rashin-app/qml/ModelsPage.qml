import QtQuick
import QtQuick.Controls
import RashinApp

// The models page: the two halves of inference. The fast lane (the provider
// quick asks run on, switchable with one click) and the chat models the
// agent advertises. The directory of providers Prowl ships rides below as
// context. The daemon owns every switch; this page only requests them.
Item {
    id: page

    property var quick: null
    property var providers: []

    Connections {
        target: DaemonClient
        function onReply(path, ok, value) {
            if (!ok)
                return;
            if (path === "/api/quick")
                page.quick = value;
            else if (path === "/api/providers")
                page.providers = value["value"] || [];
        }
    }
    Component.onCompleted: {
        DaemonClient.get("/api/quick");
        DaemonClient.get("/api/providers");
    }

    function setLane(provider) {
        DaemonClient.post("/api/quick?provider=" + encodeURIComponent(provider));
        settleTimer.restart();
    }
    Timer {
        id: settleTimer
        interval: 1000
        onTriggered: DaemonClient.get("/api/quick")
    }

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
            spacing: Theme.s5

            // ---- the fast lane -------------------------------------------------
            Column {
                width: parent.width
                spacing: Theme.s3
                Text {
                    text: qsTr("FAST LANE")
                    color: Theme.inkMuted
                    font.family: Theme.mono
                    font.pixelSize: Theme.fMicroPx
                    font.letterSpacing: Theme.trackMark
                }
                Text {
                    width: parent.width
                    text: qsTr("The provider quick asks answer from. One tool loop, a few seconds, read-only tools.")
                    color: Theme.inkFaint
                    font.family: Theme.ui
                    font.pixelSize: Theme.fTinyPx
                    wrapMode: Text.Wrap
                }

                Rectangle {
                    visible: page.quick !== null
                    width: parent.width
                    height: laneCol.implicitHeight + Theme.s5 * 2
                    radius: Theme.radius
                    color: Theme.paperLift
                    border.width: Theme.border
                    border.color: Theme.line
                    Column {
                        id: laneCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.s5
                        spacing: Theme.s2
                        Row {
                            spacing: Theme.s2
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: laneDot.implicitWidth + Theme.s3
                                height: 22
                                radius: 11
                                color: page.quick && page.quick.sessionLane ? Theme.tint10 : Theme.bone
                                Text {
                                    id: laneDot
                                    anchors.centerIn: parent
                                    text: page.quick && page.quick.sessionLane ? qsTr("session lane") : String(page.quick ? page.quick.label || "" : "")
                                    color: page.quick && page.quick.sessionLane ? Theme.inkDim : Theme.inkOnBone
                                    font.family: Theme.mono
                                    font.pixelSize: Theme.fTinyPx
                                }
                            }
                        }
                        Text {
                            visible: page.quick && page.quick.sessionLane
                            width: parent.width
                            text: (page.quick && page.quick.reason) || ""
                            color: Theme.inkMuted
                            font.family: Theme.ui
                            font.pixelSize: Theme.fTinyPx
                            wrapMode: Text.Wrap
                        }
                        Text {
                            visible: page.quick && !page.quick.sessionLane && String(page.quick.endpoint || "").length > 0
                            text: String(page.quick.endpoint || "")
                            color: Theme.inkFaint
                            font.family: Theme.mono
                            font.pixelSize: Theme.fMicroPx
                        }

                        Item { width: 1; height: Theme.s2 }
                        Flow {
                            width: parent.width
                            spacing: Theme.s2
                            Pill {
                                compact: true
                                primary: page.quick && !page.quick.provider
                                text: qsTr("Follow Hermes")
                                onAct: Runner.run("ryoku-rashin", ["backend", "auto"])
                            }
                            Repeater {
                                model: page.quick ? (page.quick.available || []) : []
                                delegate: Pill {
                                    required property var modelData
                                    compact: true
                                    primary: page.quick && String(page.quick.provider || "") === String(modelData)
                                    text: String(modelData)
                                    onAct: page.setLane(String(modelData))
                                }
                            }
                        }
                    }
                }
            }

            // ---- the chat models -------------------------------------------------
            Column {
                width: parent.width
                spacing: Theme.s3
                Text {
                    text: qsTr("CHAT MODELS")
                    color: Theme.inkMuted
                    font.family: Theme.mono
                    font.pixelSize: Theme.fMicroPx
                    font.letterSpacing: Theme.trackMark
                }
                Text {
                    width: parent.width
                    text: qsTr("What the shared session answers with. The list arrives when the agent starts; pick one and every chat surface follows.")
                    color: Theme.inkFaint
                    font.family: Theme.ui
                    font.pixelSize: Theme.fTinyPx
                    wrapMode: Text.Wrap
                }
                Column {
                    width: parent.width
                    spacing: Theme.s1
                    Repeater {
                        model: ChatBridge.models
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 54
                            radius: Theme.radiusSm
                            readonly property bool current: ChatBridge.currentModel === String(modelData.id || "")
                            color: current ? Theme.tint16 : mHover.hovered ? Theme.tint5 : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.snap } }
                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.s4
                                anchors.rightMargin: Theme.s4
                                spacing: Theme.s3
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.parent.current ? "radio_button_checked" : "radio_button_unchecked"
                                    color: parent.parent.current ? Theme.bone : Theme.inkFaint
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: Theme.fBodyPx
                                }
                                Column {
                                    width: parent.width - 60
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        width: parent.width
                                        text: modelData.name || String(modelData.id || "")
                                        color: Theme.ink
                                        font.family: Theme.ui
                                        font.pixelSize: Theme.fSmallPx
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        visible: String(modelData.description || "").length > 0
                                        width: parent.width
                                        text: modelData.description || ""
                                        color: Theme.inkFaint
                                        font.family: Theme.ui
                                        font.pixelSize: Theme.fMicroPx
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                            HoverHandler { id: mHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: ChatBridge.setModel(String(modelData.id || "")) }
                        }
                    }
                    Text {
                        visible: ChatBridge.models.length === 0
                        text: qsTr("Chat models load with the agent. Send a chat message to fetch them.")
                        color: Theme.inkFaint
                        font.family: Theme.ui
                        font.pixelSize: Theme.fSmallPx
                    }
                }
            }

            // ---- the directory -----------------------------------------------------
            Column {
                visible: page.providers.length > 0
                width: parent.width
                spacing: Theme.s3
                Text {
                    text: qsTr("PROVIDER DIRECTORY")
                    color: Theme.inkMuted
                    font.family: Theme.mono
                    font.pixelSize: Theme.fMicroPx
                    font.letterSpacing: Theme.trackMark
                }
                Flow {
                    width: parent.width
                    spacing: Theme.s2
                    Repeater {
                        model: page.providers
                        delegate: Rectangle {
                            required property var modelData
                            width: provCol.implicitWidth + Theme.s4 * 2
                            height: provCol.implicitHeight + Theme.s3 * 2
                            radius: Theme.radiusSm
                            color: Theme.tint5
                            border.width: Theme.border
                            border.color: Theme.line
                            Column {
                                id: provCol
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    text: modelData.name || modelData.id || ""
                                    color: Theme.ink
                                    font.family: Theme.ui
                                    font.pixelSize: Theme.fSmallPx
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: [modelData.tier || modelData.class, Array.isArray(modelData.models) ? qsTr("%1 models").arg(modelData.models.length) : ""].filter(Boolean).join(" · ")
                                    color: Theme.inkFaint
                                    font.family: Theme.mono
                                    font.pixelSize: Theme.fMicroPx
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    OfflineNotice { anchors.centerIn: parent; visible: !DaemonClient.online }
}
