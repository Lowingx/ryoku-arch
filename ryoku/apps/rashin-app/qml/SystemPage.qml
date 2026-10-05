import QtQuick
import QtQuick.Controls
import RashinApp

// The system page: the machine as the daemon sees it. Live vitals (CPU,
// memory, disk, GPU) from /api/vitals, and the doctor's findings from
// /api/doctor -- every finding that needs a person, with Fix with AI handed
// to the daemon's own actuator. The page never runs anything itself; the
// daemon is the one that knows.
Item {
    id: page

    property var vitals: null
    property var doctor: null

    Connections {
        target: DaemonClient
        function onReply(path, ok, value) {
            if (!ok)
                return;
            if (path === "/api/vitals")
                page.vitals = value;
            else if (path.startsWith("/api/doctor"))
                page.doctor = value;
        }
    }
    Timer {
        interval: 2000
        running: DaemonClient.online
        repeat: true
        onTriggered: DaemonClient.get("/api/vitals")
    }
    Component.onCompleted: {
        DaemonClient.get("/api/vitals");
        DaemonClient.get("/api/doctor");
    }

    function fmtBytes(n) {
        if (!n || n <= 0)
            return "";
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        let v = n;
        while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
        return (i === 0 ? v : v.toFixed(1)) + units[i];
    }

    function pctOf(id) {
        const v = page.vitals;
        if (!v)
            return 0;
        if (id === "cpu")
            return Math.min(1, (v.cpu?.percent || 0) / 100);
        if (id === "mem")
            return Math.min(1, (v.mem?.used || 0) / Math.max(1, v.mem?.total || 1));
        if (id === "disk")
            return Math.min(1, (v.disks?.[0]?.used || 0) / Math.max(1, v.disks?.[0]?.total || 1));
        return v.gpu ? Math.min(1, (v.gpu.percent || 0) / 100) : 0;
    }

    function valueOf(id) {
        const v = page.vitals;
        if (!v)
            return "--";
        if (id === "cpu")
            return Math.round(v.cpu?.percent || 0) + "%";
        if (id === "gpu" && !v.gpu)
            return "--";
        return Math.round(pctOf(id) * 100) + "%";
    }

    function subOf(id) {
        const v = page.vitals;
        if (!v)
            return "";
        if (id === "cpu")
            return String(v.cpu?.model || "").slice(0, 28);
        if (id === "mem")
            return fmtBytes((v.mem?.used || 0) * 1024) + " / " + fmtBytes((v.mem?.total || 0) * 1024);
        if (id === "disk")
            return String(v.disks?.[0]?.mount || "");
        return v.gpu ? String(v.gpu.model || "").slice(0, 28) : qsTr("none");
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

            // ---- vitals ---------------------------------------------------------
            Row {
                width: parent.width
                spacing: Theme.s3
                Repeater {
                    model: [
                        { id: "cpu", label: qsTr("CPU") },
                        { id: "mem", label: qsTr("Memory") },
                        { id: "disk", label: qsTr("Disk") },
                        { id: "gpu", label: qsTr("GPU") }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: (col.width - Theme.s3 * 3) / 4
                        height: 110
                        radius: Theme.radius
                        color: Theme.paperLift
                        border.width: Theme.border
                        border.color: Theme.line
                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.s4
                            spacing: Theme.s2
                            Text {
                                text: modelData.label
                                color: Theme.inkMuted
                                font.family: Theme.mono
                                font.pixelSize: Theme.fMicroPx
                                font.letterSpacing: Theme.trackLabel
                            }
                            Text {
                                text: page.valueOf(modelData.id)
                                color: Theme.ink
                                font.family: Theme.ui
                                font.pixelSize: Theme.fTitlePx
                                font.weight: Font.DemiBold
                            }
                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Theme.tint10
                                Rectangle {
                                    width: parent.width * page.pctOf(modelData.id)
                                    height: parent.height
                                    radius: 2
                                    color: page.pctOf(modelData.id) > 0.85 ? Theme.alert : Theme.bone
                                    Behavior on width {
                                        enabled: !Theme.reduceMotion
                                        NumberAnimation { duration: Theme.move; easing.type: Easing.OutQuint }
                                    }
                                    Behavior on color { ColorAnimation { duration: Theme.swap } }
                                }
                            }
                            Text {
                                text: page.subOf(modelData.id)
                                color: Theme.inkFaint
                                font.family: Theme.mono
                                font.pixelSize: Theme.fMicroPx
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            // ---- the host line ---------------------------------------------------
            Row {
                width: parent.width
                spacing: Theme.s2
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.vitals ? String(page.vitals.host || "") : ""
                    color: Theme.inkDim
                    font.family: Theme.mono
                    font.pixelSize: Theme.fTinyPx
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.vitals ? String(page.vitals.kernel || "") : ""
                    color: Theme.inkFaint
                    font.family: Theme.mono
                    font.pixelSize: Theme.fTinyPx
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: page.vitals && (page.vitals.uptime || 0) > 0
                    text: page.vitals ? "up " + Math.round(page.vitals.uptime / 3600) + "h" : ""
                    color: Theme.inkFaint
                    font.family: Theme.mono
                    font.pixelSize: Theme.fTinyPx
                }
            }

            // ---- the doctor --------------------------------------------------------
            Column {
                width: parent.width
                spacing: Theme.s3
                Row {
                    width: parent.width
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("DOCTOR")
                        color: Theme.inkMuted
                        font.family: Theme.mono
                        font.pixelSize: Theme.fMicroPx
                        font.letterSpacing: Theme.trackMark
                    }
                    Item { width: parent.width - 90; height: 1 }
                    Pill {
                        compact: true
                        text: qsTr("Re-run")
                        onAct: DaemonClient.get("/api/doctor?refresh=1")
                    }
                }
                Text {
                    visible: !page.doctor
                    text: qsTr("Running the health check…")
                    color: Theme.inkFaint
                    font.family: Theme.ui
                    font.pixelSize: Theme.fTinyPx
                }
                Text {
                    visible: page.doctor && (page.doctor.findings || []).length === 0
                    text: qsTr("Nothing needs you. The machine is healthy.")
                    color: Theme.ok
                    font.family: Theme.ui
                    font.pixelSize: Theme.fSmallPx
                }
                Repeater {
                    model: page.doctor ? (page.doctor.findings || []) : []
                    delegate: Rectangle {
                        required property var modelData
                        width: col.width
                        height: findCol.implicitHeight + Theme.s4 * 2
                        radius: Theme.radius
                        color: Theme.paperLift
                        border.width: Theme.border
                        border.color: Theme.line
                        Column {
                            id: findCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Theme.s4
                            spacing: Theme.s2
                            Row {
                                width: parent.width
                                spacing: Theme.s2
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 8
                                    height: width
                                    radius: 4
                                    color: modelData.status === "fail" ? Theme.alert : Theme.inkFaint
                                }
                                Text {
                                    width: parent.width - 16
                                    text: String(modelData.name || "")
                                    color: Theme.ink
                                    font.family: Theme.ui
                                    font.pixelSize: Theme.fSmallPx
                                    wrapMode: Text.Wrap
                                }
                            }
                            Text {
                                visible: String(modelData.detail || "").length > 0
                                width: parent.width
                                text: modelData.detail
                                color: Theme.inkMuted
                                font.family: Theme.ui
                                font.pixelSize: Theme.fTinyPx
                                wrapMode: Text.Wrap
                            }
                            Flow {
                                width: parent.width
                                spacing: Theme.s2
                                Pill {
                                    compact: true
                                    primary: true
                                    text: qsTr("Fix with AI")
                                    onAct: DaemonClient.post("/api/fix", {
                                        kind: "doctor",
                                        name: String(modelData.name || "")
                                    })
                                }
                                Pill {
                                    visible: String(modelData.remedy || "").length > 0
                                    compact: true
                                    text: qsTr("Copy remedy")
                                    onAct: Clipboard.copy(String(modelData.remedy || ""))
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
