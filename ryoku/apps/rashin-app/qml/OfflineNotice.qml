import QtQuick
import RashinApp

// The honest offline state: the daemon is off or unreachable, and every page
// that needs it shows this instead of pretending. The actions are the real
// fix, named exactly: enable it from here, or from a terminal.
Rectangle {
    id: notice

    width: 380
    height: col.implicitHeight + Theme.s6 * 2
    radius: Theme.radiusLg
    color: Theme.paperLift
    border.width: Theme.border
    border.color: Theme.lineStrong
    property string why: qsTr("The Rashin daemon is not answering.")

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Theme.s6
        spacing: Theme.s3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "cloud_off"
            color: Theme.inkFaint
            font.family: "Material Symbols Rounded"
            font.pixelSize: 34
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: notice.why
            color: Theme.ink
            font.family: Theme.ui
            font.pixelSize: Theme.fBodyPx
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Start it and this page fills in.")
            color: Theme.inkMuted
            font.family: Theme.ui
            font.pixelSize: Theme.fTinyPx
        }
        Item { width: 1; height: Theme.s1 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.s2
            Pill {
                compact: true
                primary: true
                text: qsTr("Start daemon")
                onAct: {
                    Runner.run("ryoku-rashin", ["enable"]);
                    retryTimer.restart();
                }
            }
            Pill {
                compact: true
                text: qsTr("Retry")
                onAct: {
                    DaemonClient.probe();
                    retryTimer.restart();
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "ryoku-rashin enable"
            color: Theme.inkFaint
            font.family: Theme.mono
            font.pixelSize: Theme.fMicroPx
        }
    }

    // After an enable the daemon needs a moment to bind; re-probe on a beat.
    Timer {
        id: retryTimer
        interval: 1500
        repeat: true
        running: false
        onTriggered: {
            DaemonClient.probe();
            if (DaemonClient.online)
                stop();
        }
    }
}
