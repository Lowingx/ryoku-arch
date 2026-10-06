pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Ryoku.Ui.Singletons
import stage.services
import stage.modules.common
import stage.modules.common.widgets

// A folder's contents, not its menu: left-clicking a group opens this card
// beside the icon — the context dialog's surface language (same card colour,
// border, corner, scrim and reveal), but a grid of the apps inside, each
// launching on click. The context menu stays where it belongs: right-click.
FocusScope {
    id: root
    required property var entry
    // The tile's rect in this layer's coordinates, handed in by the layer so
    // the card can sit under it (or above it when the screen edge is closer).
    required property rect tileRect
    signal closeRequested()
    // The header's two group operations, carried to the layer that owns the
    // store: rename opens the context dialog on its rename page, ungroup
    // dissolves the members back onto the desktop.
    signal renameRequested()
    signal ungroupRequested()

    readonly property var apps: entry.apps ?? []
    readonly property int columns: Math.max(1, Math.min(4, apps.length))
    readonly property real cellWidth: Tokens.s7 + Tokens.s5 + Tokens.s1
    property real reveal: 0
    property bool closing: false
    // The mode's shrink, undone: this card is laid out and drawn in SCREEN
    // pixels (DesktopShortcutsLayer's counterScale; 1 outside the mode).
    // tileRect arrives in surface coordinates, so the anchor maths converts
    // it by 1/counterScale and converts the settled screen-space corner
    // back — with counterScale=1 every line below is the old one.
    property real counterScale: 1

    function dismiss() {
        if (closing)
            return;
        closing = true;
        revealMotion.stop();
        revealMotion.to = 0;
        revealMotion.start();
    }
    // The cascade of the item context dialog's own language, applied to the
    // grid: header first, then one slice per grid ROW (a per-cell cascade
    // would make a row's far cells lag their own line). One scalar, LINEAR,
    // pure arithmetic, exits in reverse for free — every slice eases itself
    // (smoothstep), and the two clocks are separate: the card lands in the
    // first slice and stands still while the grid waves in inside it.
    readonly property real bodySpan: 0.22
    readonly property real plateSpan: 0.22
    readonly property real rowLead: 0.2
    readonly property real rowSpan: 0.55
    readonly property int gridRows: Math.ceil(apps.length / columns)
    function ease(t: real): real {
        return t * t * (3 - 2 * t);
    }
    readonly property real bodyReveal: root.ease(Math.min(1, reveal / bodySpan))
    readonly property real plateReveal: root.ease(Math.min(1, reveal / plateSpan))

    function rowReveal(index: int, count: int): real {
        const step = count > 1
            ? Math.min(0.041, (1 - root.rowLead - root.rowSpan) / (count - 1)) : 0;
        const t = (root.reveal - root.rowLead - index * step) / root.rowSpan;
        return root.ease(Math.max(0, Math.min(1, t)));
    }
    function launch(app) {
        DesktopShortcuts.launch(app);
        root.dismiss();
    }

    focus: true
    Component.onCompleted: {
        root.forceActiveFocus();
        revealMotion.start();
    }
    Keys.onEscapePressed: event => {
        event.accepted = true;
        root.dismiss();
    }

    NumberAnimation {
        id: revealMotion
        target: root
        property: "reveal"
        to: 1
        duration: Tokens.reduceMotion ? 0 : (root.closing ? Tokens.snap : Tokens.move)
        easing.type: Tokens.ease
        onFinished: { if (root.closing) root.closeRequested(); }
    }

    // Click anywhere outside closes. The scrim covers the whole layer, so a
    // press on another icon closes the folder rather than launching through.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.dismiss()
        onWheel: wheel => wheel.accepted = true
    }

    // The card leaves its icon the way a folder opens: one below the tile
    // slides down out of it, one above slides up out of it, so the movement
    // reads as travel from the thing it belongs to, not as a generic fade.
    readonly property bool opensDownward: card.y > tileRect.y + tileRect.height / 2
    Rectangle {
        id: card
        readonly property real gap: Tokens.s2
        x: {
            const k = root.counterScale;
            const ts = root.tileRect;
            Math.max(card.gap, Math.min(root.width - width - card.gap,
                (ts.x + ts.width / 2) / k - width / 2)) * k
        }
        y: {
            const k = root.counterScale;
            const tsy = root.tileRect.y / k;
            const tsh = root.tileRect.height / k;
            (tsy + tsh + implicitHeight + 2 * card.gap > root.height
                ? Math.max(card.gap, tsy - implicitHeight - card.gap)
                : tsy + tsh + card.gap) * k
        }
        width: Math.min(root.width - 2 * card.gap,
            root.columns * root.cellWidth + (root.columns - 1) * Tokens.s1 + Tokens.s5)
        height: implicitHeight
        implicitHeight: cardLayout.implicitHeight + Tokens.s5
        radius: Tokens.radius
        color: Tokens.paper
        border.width: Tokens.border
        border.color: Tokens.line
        opacity: Math.min(1, root.reveal * 8)
        scale: root.counterScale * (0.94 + 0.06 * root.bodyReveal)
        transformOrigin: Item.TopLeft
        transform: Translate { y: (1 - root.bodyReveal) * (root.opensDownward ? -Tokens.s3 : Tokens.s3) }
        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: Tokens.s3
            anchors.topMargin: Tokens.s2
            spacing: Tokens.s1

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.s1
                Layout.rightMargin: Tokens.s1
                spacing: Tokens.s2
                opacity: root.plateReveal
                // The group's own face: the same 2×2 member mosaic the tile
                // draws, shrunk to header size, so the card is unmistakably
                // the icon you clicked.
                Grid {
                    Layout.alignment: Qt.AlignVCenter
                    columns: 2
                    spacing: Tokens.border * 2
                    Repeater {
                        model: root.apps.slice(0, 4)
                        delegate: IconImage {
                            required property var modelData
                            implicitSize: Tokens.fMicro
                            source: Quickshell.iconPath(modelData.icon, "image-missing")
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.entry.name || root.entry.id || ""
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall
                    font.weight: Font.Medium
                    color: Tokens.ink
                    elide: Text.ElideRight
                }
                Text {
                    visible: root.apps.length > 0
                    text: `${root.apps.length}`
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fTiny
                    color: Tokens.inkMuted
                }
                // Rename and ungroup, as small icon buttons at the header's
                // end — the grid stays about launching, the header about
                // managing. No borders, no plate; the hover circle is the
                // affordance.
                Rectangle {
                    implicitWidth: Tokens.s6
                    implicitHeight: Tokens.s6
                    radius: Tokens.radius
                    color: renameTap.pressed ? Tokens.tint16 : renameHover.hovered ? Tokens.tint10 : "transparent"
                    border.width: Tokens.border
                    border.color: renameHover.hovered ? Tokens.lineStrong : Tokens.line
                    activeFocusOnTab: true
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "edit"
                        iconSize: Tokens.s5
                        color: Tokens.inkDim
                    }
                    HoverHandler { id: renameHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: renameTap; onTapped: root.renameRequested() }
                    Keys.onReturnPressed: root.renameRequested()
                }
                Rectangle {
                    visible: !root.entry.stack
                    implicitWidth: Tokens.s6
                    implicitHeight: Tokens.s6
                    radius: Tokens.radius
                    color: ungroupTap.pressed ? Tokens.tint16 : ungroupHover.hovered ? Tokens.tint10 : "transparent"
                    border.width: Tokens.border
                    border.color: ungroupHover.hovered ? Tokens.lineStrong : Tokens.line
                    activeFocusOnTab: true
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "folder_off"
                        iconSize: Tokens.s5
                        color: Tokens.inkDim
                    }
                    HoverHandler { id: ungroupHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: ungroupTap; onTapped: root.ungroupRequested() }
                    Keys.onReturnPressed: root.ungroupRequested()
                }
            }

            Flickable {
                id: appFlickable
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Tokens.railW + Tokens.s6, appGrid.implicitHeight)
                visible: root.apps.length > 0
                contentHeight: appGrid.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                TouchpadScrollHandler {
                    flickable: appFlickable
                }
                GridLayout {
                    id: appGrid
                    width: parent.width
                    columns: root.columns
                    columnSpacing: Tokens.s1
                    rowSpacing: Tokens.s1
                    Repeater {
                        model: root.apps
                        delegate: Rectangle {
                            id: memberCell
                            required property var modelData
                            required property int index
                            readonly property real arrived: root.rowReveal(
                                Math.floor(index / root.columns), root.gridRows)
                            Layout.preferredWidth: root.cellWidth
                            Layout.preferredHeight: Tokens.s7 + Tokens.s6
                            radius: Tokens.radius
                            color: memberTap.pressed ? Tokens.tint16
                                : memberHover.hovered ? Tokens.tint10 : "transparent"
                            border.width: memberHover.hovered ? Tokens.border : 0
                            border.color: Tokens.lineStrong
                            activeFocusOnTab: true
                            opacity: arrived
                            scale: 0.965 + 0.035 * arrived
                            transformOrigin: Item.TopLeft
                            Behavior on color { ColorAnimation { duration: Tokens.snap } }
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: Tokens.s1
                                IconImage {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: Tokens.s2
                                    implicitSize: Tokens.s6
                                    source: Quickshell.iconPath(modelData.icon, "image-missing")
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Tokens.s1
                                    Layout.rightMargin: Tokens.s1
                                    text: modelData.name || modelData.id
                                    color: Tokens.ink
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fSmall
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                            HoverHandler { id: memberHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { id: memberTap; onTapped: root.launch(memberCell.modelData) }
                            Keys.onReturnPressed: root.launch(memberCell.modelData)
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.margins: Tokens.s1
                visible: root.apps.length === 0
                text: Translation.tr("No applications in this group")
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall
                color: Tokens.inkMuted
                wrapMode: Text.Wrap
            }
        }
    }
}
