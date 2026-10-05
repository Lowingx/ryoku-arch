import QtQuick
import QtQuick.Controls
import RashinApp

// The live model chip: what is answering right now, one click from the
// switcher. The drawer lists the agent's advertised models; a switch rides
// the daemon (set_model), and the chip only repaints when the models frame
// comes back confirming it.
Rectangle {
    id: chip

    property bool drawerOpen: false
    readonly property string shortName: {
        const text = ChatBridge.currentModel;
        const slash = Math.max(text.lastIndexOf("/"), text.lastIndexOf(":"));
        return slash >= 0 ? text.slice(slash + 1) : text;
    }

    width: Math.min(320, row.implicitWidth + Theme.s4 * 2)
    height: Theme.ctlH - 6
    radius: height / 2
    color: drawerOpen ? Theme.tint16 : hover.hovered ? Theme.tint5 : "transparent"
    border.width: Theme.border
    border.color: drawerOpen ? Theme.lineStrong : Theme.line
    Behavior on color { ColorAnimation { duration: Theme.snap } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.s2
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "bolt"
            color: Theme.primary
            font.family: "Material Symbols Rounded"
            font.pixelSize: Theme.fSmallPx
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.shortName.length > 0 ? chip.shortName : qsTr("Choose model")
            color: Theme.ink
            font.family: Theme.ui
            font.pixelSize: Theme.fSmallPx
            width: Math.min(implicitWidth, 220)
            elide: Text.ElideMiddle
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "expand_more"
            rotation: chip.drawerOpen ? 180 : 0
            color: Theme.inkMuted
            font.family: "Material Symbols Rounded"
            font.pixelSize: Theme.fSmallPx
            Behavior on rotation {
                enabled: !Theme.reduceMotion
                NumberAnimation { duration: Theme.move; easing.type: Easing.OutQuint }
            }
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: chip.drawerOpen = !chip.drawerOpen }

    // The dropdown: the agent's advertised models, current one marked.
    Popup {
        id: pop
        parent: Overlay.overlay
        // mapToGlobal is window-relative and the overlay covers the window,
        // so the popup hangs under the chip and never leaves the screen.
        x: {
            const at = chip.mapToGlobal(0, 0);
            return Math.max(8, Math.min(at.x, (parent ? parent.width : 1000) - width - 8));
        }
        y: chip.mapToGlobal(0, chip.height).y + 8
        width: 300
        padding: Theme.s2
        visible: chip.drawerOpen
        modal: false
        closePolicy: Popup.CloseOnPressOutside
        onAboutToHide: chip.drawerOpen = false
        background: Rectangle {
            radius: Theme.radius
            color: Theme.paperLift
            border.width: Theme.border
            border.color: Theme.lineStrong
        }
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.swap }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Theme.move; easing.type: Easing.OutQuint }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.snap }
        }

        contentItem: Column {
            spacing: Theme.s1
            Text {
                visible: list.count === 0
                text: qsTr("Chat models load with the agent. Send a message to fetch them.")
                wrapMode: Text.WordWrap
                width: parent.width
                color: Theme.inkMuted
                font.family: Theme.ui
                font.pixelSize: Theme.fSmallPx
            }
            ListView {
                id: list
                width: parent.width
                height: Math.min(contentHeight, 260)
                clip: true
                model: ChatBridge.models
                boundsBehavior: Flickable.StopAtBounds
                visible: count > 0
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    width: list.width
                    height: 36
                    radius: Theme.radiusSm
                    readonly property bool current: ChatBridge.currentModel === String(modelData.id || "")
                    color: rowHover.hovered ? Theme.tint10 : "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.s3
                        anchors.rightMargin: Theme.s3
                        spacing: Theme.s2
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "radio_button_checked"
                            visible: row.current
                            color: Theme.bone
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Theme.fBodyPx
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 26
                            text: modelData.name || String(modelData.id || "")
                            color: Theme.ink
                            font.family: Theme.ui
                            font.pixelSize: Theme.fSmallPx
                            elide: Text.ElideMiddle
                        }
                    }
                    HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            ChatBridge.setModel(String(row.modelData.id || ""));
                            pop.close();
                        }
                    }
                }
            }
        }
    }
}
