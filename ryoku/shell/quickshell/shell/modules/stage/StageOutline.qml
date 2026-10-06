pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.Ui.Singletons

// The body observes presses without stealing drags. Only the action strip and
// selected corner handles take an exclusive pointer grab.
Item {
    id: outline
    anchors.fill: parent

    property rect box: Qt.rect(0, 0, 0, 0)
    property string title: ""
    property bool selected: false
    property bool primary: false
    property bool inputBlocked: false
    property real radius: Tokens.radius
    property real counterScale: 1
    property var targetItem: null

    signal picked()
    signal settings()
    signal remove()

    visible: outline.box.width > 1 && outline.box.height > 1
    enabled: !outline.inputBlocked

    readonly property bool engaged: outline.selected || frameHover.hovered
    readonly property real chromeScale: Math.max(0.1, outline.counterScale)
    readonly property real handleSize: Tokens.s3 * outline.chromeScale
    readonly property real stripGap: Tokens.s2 * outline.chromeScale
    readonly property real stripHeight: (Tokens.s6 + Tokens.s1) * outline.chromeScale
    readonly property real stripWidth: Math.min(outline.width,
        Math.max(Tokens.s7 * 5 * outline.chromeScale,
            Math.min(outline.box.width, Tokens.s7 * 8 * outline.chromeScale)))
    readonly property bool stripBelow: outline.box.y
        < outline.stripHeight + outline.stripGap
    readonly property real stripX: Math.max(0, Math.min(
        outline.box.x, outline.width - outline.stripWidth))
    readonly property real stripY: outline.stripBelow
        ? Math.min(outline.height - outline.stripHeight,
            outline.box.y + outline.box.height + outline.stripGap)
        : outline.box.y - outline.stripHeight - outline.stripGap

    Rectangle {
        id: frame
        x: outline.box.x
        y: outline.box.y
        width: outline.box.width
        height: outline.box.height
        radius: outline.radius
        color: "transparent"
        border.width: Tokens.border
        border.color: outline.selected ? Tokens.ink : Tokens.lineStrong
        opacity: outline.engaged ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Tokens.dur(140); easing.type: Easing.OutCubic }
        }

        HoverHandler { id: frameHover }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: mouse => {
                outline.picked();
                mouse.accepted = false;
            }
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.DragThreshold
            onDoubleTapped: outline.settings()
        }
        TapHandler {
            acceptedButtons: Qt.RightButton
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: outline.settings()
        }
    }

    Repeater {
        model: outline.selected && outline.targetItem
            && outline.targetItem.locked !== true
            && typeof outline.targetItem.stageBeginResize === "function"
                ? ["tl", "tr", "bl", "br"] : []
        delegate: Rectangle {
            id: corner
            required property string modelData
            readonly property bool leftSide: corner.modelData.indexOf("l") >= 0
            readonly property bool topSide: corner.modelData.indexOf("t") >= 0
            x: outline.box.x + (corner.leftSide ? -width / 2
                : outline.box.width - width / 2)
            y: outline.box.y + (corner.topSide ? -height / 2
                : outline.box.height - height / 2)
            width: outline.handleSize
            height: outline.handleSize
            radius: width / 2
            color: handleArea.containsMouse || (outline.targetItem
                && outline.targetItem.resizing) ? Tokens.bone : Tokens.paper
            border.width: Tokens.border
            border.color: Tokens.ink

            MouseArea {
                id: handleArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                preventStealing: true
                cursorShape: corner.modelData === "tl" || corner.modelData === "br"
                    ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                onPressed: mouse => {
                    outline.picked();
                    if (!outline.targetItem
                            || typeof outline.targetItem.stageBeginResize !== "function")
                        return;
                    const p = handleArea.mapToItem(outline.targetItem.parent,
                        mouse.x, mouse.y);
                    outline.targetItem.stageBeginResize(corner.modelData, p,
                        mouse.modifiers);
                }
                onPositionChanged: mouse => {
                    if (!outline.targetItem
                            || typeof outline.targetItem.stageUpdateResize !== "function")
                        return;
                    const p = handleArea.mapToItem(outline.targetItem.parent,
                        mouse.x, mouse.y);
                    outline.targetItem.stageUpdateResize(p, mouse.modifiers);
                }
                onReleased: {
                    if (outline.targetItem
                            && typeof outline.targetItem.stageEndResize === "function")
                        outline.targetItem.stageEndResize();
                }
                onCanceled: {
                    if (outline.targetItem
                            && typeof outline.targetItem.stageCancelResize === "function")
                        outline.targetItem.stageCancelResize();
                }
                onDoubleClicked: {
                    if (outline.targetItem
                            && typeof outline.targetItem.stageResetScale === "function")
                        outline.targetItem.stageResetScale();
                }
            }
        }
    }

    Rectangle {
        id: actionStrip
        visible: outline.selected && outline.primary
        x: outline.stripX
        y: outline.stripY
        width: outline.stripWidth
        height: outline.stripHeight
        radius: Tokens.radius * outline.chromeScale
        color: Tokens.paper
        border.width: Tokens.border
        border.color: Tokens.line

        Row {
            id: stripRow
            anchors {
                fill: parent
                leftMargin: Tokens.s3 * outline.chromeScale
                rightMargin: Tokens.s1 * outline.chromeScale
            }
            spacing: Tokens.s2 * outline.chromeScale

            Text {
                width: Math.max(0, actionStrip.width
                    - settingsButton.width - removeButton.width
                    - stripRow.spacing * 2
                    - (Tokens.s3 + Tokens.s1) * outline.chromeScale)
                height: actionStrip.height
                verticalAlignment: Text.AlignVCenter
                text: outline.title
                color: Tokens.ink
                elide: Text.ElideRight
                maximumLineCount: 1
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * outline.chromeScale
                font.weight: Font.DemiBold
            }

            StripButton {
                id: settingsButton
                label: qsTr("Settings")
                onAct: outline.settings()
            }
            StripButton {
                id: removeButton
                label: qsTr("Remove")
                destructive: true
                onAct: outline.remove()
            }
        }
    }

    Rectangle {
        visible: outline.targetItem && outline.targetItem.resizing === true
        x: Math.max(0, Math.min(outline.width - width,
            outline.box.x + outline.box.width - width))
        y: outline.stripBelow
            ? Math.max(0, outline.box.y - height - outline.stripGap)
            : Math.min(outline.height - height,
                outline.box.y + outline.box.height + outline.stripGap)
        width: sizeText.implicitWidth + Tokens.s3 * 2 * outline.chromeScale
        height: Tokens.s6 * outline.chromeScale
        radius: Tokens.radius * outline.chromeScale
        color: Tokens.bone

        Text {
            id: sizeText
            anchors.centerIn: parent
            text: Math.round((outline.targetItem
                && outline.targetItem.effectiveScale !== undefined
                    ? outline.targetItem.effectiveScale : 1) * 100) + "%"
            color: Tokens.inkOnBone
            font.family: Tokens.mono
            font.pixelSize: Tokens.fMicro * outline.chromeScale
            font.weight: Font.DemiBold
        }
    }

    component StripButton: Rectangle {
        id: button
        property string label: ""
        property bool destructive: false
        signal act()

        width: buttonText.implicitWidth + Tokens.s3 * 2 * outline.chromeScale
        height: actionStrip.height
        color: buttonArea.pressed ? Tokens.tint16
            : buttonArea.containsMouse ? Tokens.tint10 : "transparent"

        Text {
            id: buttonText
            anchors.centerIn: parent
            text: button.label
            color: button.destructive && buttonArea.containsMouse
                ? Tokens.alert : Tokens.inkDim
            font.family: Tokens.ui
            font.pixelSize: Tokens.fMicro * outline.chromeScale
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.act()
        }
    }
}
