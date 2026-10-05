import QtQuick
import QtQuick.Controls
import RashinApp

// The agents page: every coding agent the machine detected, whether the
// vault points at it, and one-click wire/unwire. The daemon owns the wiring
// state (GET /api/agents); this page only asks for it and requests changes.
Item {
    id: page

    property var agents: []
    property var harnesses: []

    Connections {
        target: DaemonClient
        function onReply(path, ok, value) {
            if (!ok)
                return;
            if (path === "/api/agents")
                page.agents = value["value"] || [];
            else if (path === "/api/harnesses")
                page.harnesses = value["harnesses"] || [];
        }
    }
    Component.onCompleted: refresh()
    function refresh() {
        DaemonClient.get("/api/agents");
        DaemonClient.get("/api/harnesses");
    }

    function wire(id) {
        DaemonClient.post("/api/agents/wire", { id: id });
        settleTimer.restart();
    }
    function unwire(id) {
        DaemonClient.post("/api/agents/unwire", { id: id });
        settleTimer.restart();
    }
    Timer {
        id: settleTimer
        interval: 1200
        onTriggered: page.refresh()
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
            spacing: Theme.s4

            Row {
                width: parent.width
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("AGENTS")
                    color: Theme.inkMuted
                    font.family: Theme.mono
                    font.pixelSize: Theme.fMicroPx
                    font.letterSpacing: Theme.trackMark
                }
                Item { width: parent.width - 120; height: 1 }
                Pill {
                    compact: true
                    text: qsTr("Refresh")
                    onAct: page.refresh()
                }
            }

            Repeater {
                model: page.agents
                delegate: Rectangle {
                    required property var modelData
                    width: col.width
                    height: agentRow.implicitHeight + Theme.s4 * 2
                    radius: Theme.radius
                    color: Theme.paperLift
                    border.width: Theme.border
                    border.color: Theme.line

                    Row {
                        id: agentRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.s4
                        spacing: Theme.s3

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10
                            height: width
                            radius: 5
                            color: !modelData.present ? Theme.inkFaint
                                : modelData.wired ? Theme.ok : Theme.inkMuted
                            Behavior on color { ColorAnimation { duration: Theme.swap } }
                        }
                        Column {
                            width: parent.width - 10 - 200 - agentRow.spacing * 2
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: modelData.name || modelData.id || ""
                                color: Theme.ink
                                font.family: Theme.ui
                                font.pixelSize: Theme.fBodyPx
                                font.weight: Font.DemiBold
                            }
                            Text {
                                visible: String(modelData.file || "").length > 0
                                text: modelData.file
                                color: Theme.inkFaint
                                font.family: Theme.mono
                                font.pixelSize: Theme.fMicroPx
                                width: parent.width
                                elide: Text.ElideMiddle
                            }
                        }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.s2
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: Boolean(modelData.skillWired)
                                text: qsTr("skill")
                                color: Theme.inkMuted
                                font.family: Theme.mono
                                font.pixelSize: Theme.fMicroPx
                            }
                            Pill {
                                compact: true
                                visible: Boolean(modelData.present)
                                primary: !modelData.wired
                                text: modelData.wired ? qsTr("Unwire") : qsTr("Wire")
                                onAct: modelData.wired ? page.unwire(String(modelData.id || ""))
                                                       : page.wire(String(modelData.id || ""))
                            }
                        }
                    }
                }
            }

            Text {
                visible: page.agents.length === 0
                text: qsTr("No agents detected.")
                color: Theme.inkFaint
                font.family: Theme.ui
                font.pixelSize: Theme.fSmallPx
            }

            // The harness ledger: each agent's own model, sessions, skills,
            // and the credential sources it carries (names only).
            Column {
                visible: page.harnesses.length > 0
                width: parent.width
                spacing: Theme.s3
                Item { width: 1; height: Theme.s2 }
                Text {
                    text: qsTr("ON THIS BOX")
                    color: Theme.inkMuted
                    font.family: Theme.mono
                    font.pixelSize: Theme.fMicroPx
                    font.letterSpacing: Theme.trackMark
                }
                Repeater {
                    model: page.harnesses
                    delegate: Rectangle {
                        required property var modelData
                        width: col.width
                        height: harnessCol.implicitHeight + Theme.s4 * 2
                        radius: Theme.radius
                        color: Theme.tint5
                        border.width: Theme.border
                        border.color: Theme.line
                        Column {
                            id: harnessCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Theme.s4
                            spacing: Theme.s1
                            Text {
                                text: modelData.name || modelData.id || ""
                                color: Theme.ink
                                font.family: Theme.ui
                                font.pixelSize: Theme.fSmallPx
                                font.weight: Font.DemiBold
                            }
                            Flow {
                                width: parent.width
                                spacing: Theme.s2
                                Repeater {
                                    model: {
                                        const bits = [];
                                        if (modelData.model)
                                            bits.push(qsTr("model: %1").arg(modelData.model));
                                        if ((modelData.sessions || 0) > 0)
                                            bits.push(qsTr("%1 sessions").arg(modelData.sessions));
                                        if ((modelData.skillCount || 0) > 0)
                                            bits.push(qsTr("%1 skills").arg(modelData.skillCount));
                                        if (modelData.version)
                                            bits.push(modelData.version);
                                        for (const c of (modelData.creds || []))
                                            bits.push(c.name || "");
                                        return bits;
                                    }
                                    delegate: Text {
                                        required property var modelData
                                        visible: String(modelData).length > 0
                                        text: modelData
                                        color: Theme.inkMuted
                                        font.family: Theme.mono
                                        font.pixelSize: Theme.fTinyPx
                                    }
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
