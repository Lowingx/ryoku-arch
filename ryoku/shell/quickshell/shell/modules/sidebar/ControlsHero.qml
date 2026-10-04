pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Quickshell
import Ryoku.Blobs
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root
    required property var monitor
    required property bool active
    required property real s
    readonly property color memoryColor: Tokens.role("secondary", Tokens.inkDim)
    readonly property color gpuColor: Tokens.role("tertiary", Tokens.inkMuted)
    implicitHeight: 160 * s

    function uptime(): string {
        const minutes = Math.floor(root.monitor.uptimeSeconds / 60);
        return minutes < 60 ? I18n.tr("Up %1m").arg(minutes)
            : I18n.tr("Up %1h %2m").arg(Math.floor(minutes / 60)).arg(minutes % 60);
    }

    SystemClock { id: clock; precision: SystemClock.Minutes; enabled: root.active }
    Column {
        id: identity
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 164 * root.s
        spacing: 3 * root.s
        Row {
            spacing: 7 * root.s
            Rectangle {
                width: 27 * root.s; height: width; radius: width / 2
                color: Tokens.role("primaryContainer", Tokens.tint10)
                Text {
                    anchors.centerIn: parent
                    text: root.monitor.userName.slice(0, 1).toUpperCase()
                    color: Tokens.role("onPrimaryContainer", Tokens.ink)
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                    font.weight: Font.DemiBold
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: identity.width - 34 * root.s
                text: root.monitor.userName
                textFormat: Text.PlainText
                color: Tokens.ink
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * root.s
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
        Item { width: 1; height: 2 * root.s }
        Text {
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: Tokens.ink
            font.family: Tokens.ui
            font.pixelSize: Tokens.fHero * root.s * 1.1
            font.letterSpacing: -1.5 * root.s
            font.weight: Font.Light
        }
        Text {
            width: parent.width
            text: Qt.formatDateTime(clock.date, "dddd, MMM d")
            color: Tokens.inkDim
            font.family: Tokens.ui
            font.pixelSize: Tokens.fSmall * root.s
            elide: Text.ElideRight
        }
        Item { width: 1; height: 2 * root.s }
        Text {
            width: parent.width
            text: root.monitor.hostName
            textFormat: Text.PlainText
            color: Tokens.inkFaint
            font.family: Tokens.mono
            font.pixelSize: Tokens.fMicro * root.s
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: (root.monitor.storageTotalGiB > 0 ? I18n.tr("Disk %1% · ").arg(Math.round(root.monitor.storageUsedGiB / root.monitor.storageTotalGiB * 100)) : "") + root.uptime()
            elide: Text.ElideRight
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: Tokens.fMicro * root.s
        }
    }
    Item {
        id: plot
        anchors.left: identity.right
        anchors.leftMargin: 18 * root.s
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        Text {
            anchors.left: parent.left
            text: I18n.tr("System activity")
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: Tokens.fMicro * root.s
        }
        Row {
            anchors.right: parent.right
            spacing: 5 * root.s
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 4 * root.s; height: width; radius: width / 2
                color: Tokens.sun
            }
            Text {
                text: I18n.tr("Live · %1s").arg(graph.windowSeconds)
                color: Tokens.inkFaint
                font.family: Tokens.ui
                font.pixelSize: Tokens.fMicro * root.s
            }
        }
        SystemGraph {
            id: graph
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 26 * root.s
            anchors.bottom: meters.top
            anchors.bottomMargin: 14 * root.s
            source: root.monitor
            active: root.active
            animated: !Motion.reduce && !Tokens.reduceMotion
            cpuColor: Tokens.sun
            memoryColor: root.memoryColor
            gpuColor: root.gpuColor
            gridColor: Tokens.lineSoft
            lineWidth: 1.6 * root.s
        }
        Row {
            id: meters
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 14 * root.s
            component Meter: Item {
                id: meter
                required property string label
                required property real value
                required property bool available
                required property color accent
                required property string hint
                width: (meters.width - meters.spacing * 2) / 3
                height: 35 * root.s
                Text {
                    anchors.left: parent.left
                    text: meter.label
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fMicro * root.s
                }
                Text {
                    anchors.right: parent.right
                    text: meter.available ? Math.round(meter.value) + "%" : "—"
                    color: Tokens.ink
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fMicro * root.s
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 3 * root.s
                    radius: height / 2
                    color: Tokens.tint10
                    Rectangle {
                        width: parent.width * (meter.available ? Math.max(0, Math.min(100, meter.value)) / 100 : 0)
                        height: parent.height
                        radius: parent.radius
                        color: meter.accent
                        Behavior on width { enabled: !Motion.reduce && !Tokens.reduceMotion; NumberAnimation { duration: Tokens.swap; easing.type: Tokens.ease } }
                    }
                }
                QQC.ToolTip.visible: hover.hovered
                QQC.ToolTip.text: meter.hint
                QQC.ToolTip.delay: 600
                HoverHandler { id: hover }
            }
            Meter { label: I18n.tr("CPU"); value: root.monitor.cpuPercent; available: root.monitor.cpuAvailable; accent: Tokens.sun; hint: root.monitor.cpuName }
            Meter { label: I18n.tr("Memory"); value: root.monitor.memoryPercent; available: root.monitor.memoryAvailable; accent: root.memoryColor; hint: I18n.tr("%1 / %2 GiB").arg(root.monitor.memoryUsedGiB.toFixed(1)).arg(root.monitor.memoryTotalGiB.toFixed(1)) }
            Meter { label: I18n.tr("GPU"); value: root.monitor.gpuPercent; available: root.monitor.gpuAvailable; accent: root.gpuColor; hint: root.monitor.gpuAvailable ? root.monitor.gpuName : I18n.tr("GPU asleep or utilization unavailable") }
        }
    }
}
