pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "Singletons"
import "../stage/Singletons" as StageCfg
import "../../components"
import Ryoku.Ui.Singletons

// The Edit widgets bar: one floating instrument placed in the output's work area
// while the desktop is lifted for editing. Its host window sets exclusiveZone 0,
// so the bar sits clear of the frame band, the bar-style island and the dock on
// every bar style; it rests bottom-centre, above the dock. It replaces the old
// add-drop-down toolbar with the smoother iRiS layout, redrawn in Ryoku's paper
// and ink: a masthead, the grid controls, a scrolling rail of the whole roster
// (a tile per widget, bone plate when placed, quiet when not), then Reset/Done.
//
// The session state (selection, dirty, escape ladder) stays in StageSession;
// this owns only the bar and reports host actions as signals. Grid snap and
// step live on stage.json so an unknown key never reaches the Hub's save.
Item {
    id: ed
    anchors.fill: parent

    property string monitor: ""
    // The roster: [{ id, label, icon, enabled, group }].
    property var items: []

    signal done()
    signal addToggle(string id)

    readonly property var ses: StageCfg.StageSession
    readonly property var grid: StageCfg.Config
    // Exposed so the host window can mask input to just the bar (RecordIsland
    // idiom): clicks off the bar fall through to the widgets for dragging.
    property alias barItem: bar


    // A compact tool: a glyph over an optional value, a quiet tile that washes on
    // hover and inverts to a bone plate when it reports an on state.
    component Tool: Item {
        id: tb
        property string icon: ""
        property string value: ""
        property bool on: false
        signal act()
        implicitWidth: Math.max(Theme.ctlH + 8, tbRow.implicitWidth + Theme.s3)
        implicitHeight: Theme.ctlH + 8
        readonly property color content: tb.on ? Theme.inkOnBone
            : (tbMa.containsMouse ? Theme.ink : Theme.inkDim)
        scale: tbMa.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Theme.ease } }
        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusTile
            color: tb.on ? Theme.bone
                : tbMa.pressed ? Theme.tilePress
                : tbMa.containsMouse ? Theme.tileHover : Theme.tile
            border.width: 1
            border.color: tb.on ? Theme.bone : Theme.line
            Behavior on color { ColorAnimation { duration: Theme.quick } }
        }
        Row {
            id: tbRow
            anchors.centerIn: parent
            spacing: Theme.s1
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: tb.icon
                font.pixelSize: 18
                fill: tb.on ? 1 : 0
                color: tb.content
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: tb.value.length > 0
                text: tb.value
                color: tb.content
                font.family: Theme.mono
                font.pixelSize: Theme.fSmall
                font.weight: Font.DemiBold
            }
        }
        MouseArea {
            id: tbMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tb.act()
        }
    }

    // A hairline divider between clusters.
    component Div: Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: Theme.ctlH
        Layout.alignment: Qt.AlignVCenter
        color: Theme.line
    }

    // A roster tile: icon + name, bone plate when the widget is placed, a quiet
    // tile when it is not. Click toggles it on the desktop.
    component Pill: Item {
        id: pl
        required property var entry
        readonly property bool on: pl.entry.enabled === true
        implicitWidth: plRow.implicitWidth + Theme.s3 * 2
        implicitHeight: Theme.ctlH + 8
        readonly property color content: pl.on ? Theme.inkOnBone
            : (plMa.containsMouse ? Theme.ink : Theme.inkDim)
        scale: plMa.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Theme.ease } }
        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusTile
            color: pl.on ? Theme.bone
                : plMa.pressed ? Theme.tilePress
                : plMa.containsMouse ? Theme.tileHover : Theme.tile
            border.width: 1
            border.color: pl.on ? Theme.bone : Theme.line
            Behavior on color { ColorAnimation { duration: Theme.quick } }
        }
        Row {
            id: plRow
            anchors.centerIn: parent
            spacing: Theme.s2
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: pl.entry.icon || "widgets"
                font.pixelSize: 18
                fill: pl.on ? 1 : 0
                color: pl.content
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr(pl.entry.label || pl.entry.id)
                color: pl.content
                font.family: Theme.font
                font.pixelSize: Theme.fSmall
                font.weight: pl.on ? Font.DemiBold : Font.Medium
            }
        }
        MouseArea {
            id: plMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ed.addToggle(pl.entry.id)
        }
    }

    MultiEffect {
        source: bar
        anchors.fill: bar
        visible: !Performance.shadowsDisabled
        shadowEnabled: true
        shadowColor: Theme.shadow
        shadowBlur: 1.0
        shadowVerticalOffset: 10
        blurMax: 40
        autoPaddingEnabled: true
    }

    Rectangle {
        id: bar
        x: Math.round((ed.width - width) / 2)
        y: ed.height - height - Theme.s3
        width: Math.min(ed.width - Theme.s5 * 2, Math.max(560, row.implicitWidth + Theme.s4 * 2))
        height: Theme.s7 + Theme.s1
        radius: Theme.menuRadius
        color: Theme.surface
        border.width: 1
        border.color: Theme.line

        // Swallow presses on the bar chrome so a click between controls never
        // leaks to a widget or the wallpaper beneath the lifted desktop.
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: Theme.s4
            anchors.rightMargin: Theme.s4
            spacing: Theme.s3

            // Masthead: kanji seal + tracked scope, the desktop-menu idiom.
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.s2
                Text {
                    text: "\u90e8\u54c1"
                    color: Theme.faint
                    font.family: Theme.fontJp
                    font.pixelSize: Theme.fBody
                }
                Text {
                    text: I18n.tr("Edit widgets").toUpperCase()
                    color: Theme.inkDim
                    font.family: Theme.font
                    font.pixelSize: Theme.fMicro
                    font.weight: Font.DemiBold
                    font.letterSpacing: Theme.trackMark
                }
            }

            Div {}

            Tool {
                Layout.alignment: Qt.AlignVCenter
                icon: "grid_on"
                on: ed.grid.editGridSnap
                onAct: ed.grid.toggleEditGridSnap()
            }
            Tool {
                Layout.alignment: Qt.AlignVCenter
                icon: "grid_4x4"
                value: ed.grid.editGridSize + ""
                onAct: ed.grid.cycleEditGridSize()
            }

            Div {}

            // The roster rail: scroll with the wheel/touchpad or a flick/drag,
            // its edges fading to hint there is more (no arrow buttons to click).
            Item {
                id: railBox
                Layout.fillWidth: true
                Layout.minimumWidth: Theme.s7 * 2
                Layout.preferredWidth: Math.min(railRow.implicitWidth, 720)
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Theme.ctlH + 8

                Flickable {
                    id: rail
                    anchors.fill: parent
                    contentWidth: railRow.implicitWidth
                    contentHeight: height
                    clip: true
                    interactive: contentWidth > width
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick

                    // Vertical wheel maps to horizontal so a plain mouse scrolls
                    // the rail; the touchpad's own horizontal axis wins when larger.
                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: e => {
                            const d = Math.abs(e.angleDelta.x) > Math.abs(e.angleDelta.y) ? -e.angleDelta.x : -e.angleDelta.y;
                            const maxX = Math.max(0, rail.contentWidth - rail.width);
                            rail.contentX = Math.max(0, Math.min(maxX, rail.contentX + (d > 0 ? Theme.s6 : -Theme.s6)));
                            e.accepted = true;
                        }
                    }

                    Row {
                        id: railRow
                        height: rail.height
                        spacing: Theme.s2
                        Repeater {
                            model: ed.items
                            delegate: Pill {
                                required property var modelData
                                entry: modelData
                            }
                        }
                    }
                }

                // Edge fades: a wash from the bar surface to clear, shown only on
                // the side that still has roster to scroll to. Input-transparent,
                // so the flick/wheel underneath is untouched.
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: Theme.s5
                    opacity: rail.contentX > 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.quick } }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.surface }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }
                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: Theme.s5
                    opacity: rail.contentX < rail.contentWidth - rail.width - 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.quick } }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: Theme.surface }
                    }
                }
            }

            Div {}

            Tool {
                Layout.alignment: Qt.AlignVCenter
                icon: "restart_alt"
                opacity: ed.ses.dirty ? 1 : 0
                enabled: ed.ses.dirty
                onAct: ed.ses.reset()
                Behavior on opacity { NumberAnimation { duration: Theme.quick } }
            }

            // Done: the one bone plate, spelled out.
            Item {
                id: doneBtn
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: doneText.implicitWidth + Theme.s5
                implicitHeight: Theme.ctlH + 8
                scale: doneMa.pressed ? 0.95 : 1
                Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Theme.ease } }
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusTile
                    color: Theme.bone
                    opacity: doneMa.containsMouse ? 1 : 0.92
                    Behavior on opacity { NumberAnimation { duration: Theme.quick } }
                }
                Text {
                    id: doneText
                    anchors.centerIn: parent
                    text: I18n.tr("Done")
                    color: Theme.inkOnBone
                    font.family: Theme.font
                    font.pixelSize: Theme.fSmall
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: doneMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ed.done()
                }
            }
        }
    }
}
