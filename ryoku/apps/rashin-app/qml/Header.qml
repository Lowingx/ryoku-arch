import QtQuick
import QtQuick.Controls
import RashinApp

// The window's one status strip: what page you are on, whether the daemon is
// answering, the live model chip, and the daemon actions (reindex, open the
// dashboard). The connection lamp is honest: it reflects the follow bridge's
// state, not a hope.
Rectangle {
    id: header

    required property string page
    required property var pages
    height: 56
    color: Theme.surface
    property real s2: Theme.s2

    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.s5
        anchors.rightMargin: Theme.s4
        spacing: Theme.s3

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
                text: {
                    for (const p of header.pages)
                        if (p.id === header.page)
                            return p.label;
                    return "Rashin";
                }
                color: Theme.ink
                font.family: Theme.ui
                font.pixelSize: Theme.fValuePx
                font.weight: Font.DemiBold
            }
            Text {
                visible: header.page === "chat" && ChatBridge.sessionTitle.length > 0
                text: ChatBridge.sessionTitle
                color: Theme.inkMuted
                font.family: Theme.ui
                font.pixelSize: Theme.fTinyPx
                width: Math.min(implicitWidth, 420)
                elide: Text.ElideMiddle
            }
        }

        Item { width: 1; height: 1; anchors.verticalCenter: parent.verticalCenter }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.s2

            // The live model: a chip that opens the same drawer the Ask bar
            // wears, right here.
            ModelChip {
                anchors.verticalCenter: parent.verticalCenter
            }

            // The connection lamp: green when the bridge is up, amber while
            // starting, red when the daemon is off.
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.s2
                padding: Theme.s2
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: width
                    radius: 4
                    color: ChatBridge.bannerState === "dead" || !DaemonClient.online
                        ? Theme.alert
                        : ChatBridge.bannerState === "ready" || ChatBridge.bannerState === "busy"
                            ? Theme.ok : Theme.inkFaint
                    Behavior on color { ColorAnimation { duration: Theme.swap } }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: !DaemonClient.online ? qsTr("daemon off")
                        : ChatBridge.bannerState === "dead" ? qsTr("offline")
                        : ChatBridge.bannerState === "ready" ? qsTr("connected")
                        : ChatBridge.bannerState === "busy" ? qsTr("answering")
                        : qsTr("starting")
                    color: Theme.inkMuted
                    font.family: Theme.mono
                    font.pixelSize: Theme.fTinyPx
                }
            }

            IconBtn {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "refresh"
                onAct: DaemonClient.post("/api/index")
            }
            IconBtn {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "open_in_new"
                onAct: Qt.openUrlExternally("http://127.0.0.1:" + DaemonClient.port)
            }
        }
    }
}
