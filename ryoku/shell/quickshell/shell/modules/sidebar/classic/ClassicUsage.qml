pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root

    required property real s
    required property bool open
    required property real reveal
    required property bool tabActive
    property int index: 0
    property bool compact: false
    property real viewportHeight: 0
    signal requestClose()

    readonly property bool motionAllowed: !Motion.reduce && !Tokens.reduceMotion
    readonly property color ink: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface)
    readonly property color dim: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)

    implicitHeight: col.implicitHeight + 30 * root.s

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.open && root.tabActive
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 15 * root.s
        spacing: 14 * root.s

        Column {
            width: parent.width
            spacing: 2 * root.s

            Item {
                width: parent.width
                height: eyebrow.implicitHeight

                Text {
                    id: eyebrow
                    anchors.left: parent.left
                    text: I18n.tr("SCREEN TIME")
                    color: root.dim
                    font.family: Theme.fontPrimary
                    font.pixelSize: 6.5 * root.s
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2
                }
                Text {
                    anchors.right: parent.right
                    anchors.baseline: eyebrow.baseline
                    text: Qt.formatDate(clock.date, "ddd, MMM d")
                    color: root.dim
                    font.family: Theme.mono
                    font.pixelSize: 6.5 * root.s
                }
            }

            Text {
                text: ScreenTime.fmtDuration(ScreenTime.activeToday)
                color: root.ink
                font.family: Theme.mono
                font.pixelSize: 18 * root.s
                font.weight: Font.Medium
            }
            Text {
                text: I18n.tr("active today")
                color: root.dim
                font.family: Theme.fontPrimary
                font.pixelSize: 8 * root.s
            }
        }

        Column {
            width: parent.width
            visible: !root.compact
            spacing: 10 * root.s

            Text {
                text: I18n.tr("THIS WEEK")
                color: root.dim
                font.family: Theme.fontPrimary
                font.pixelSize: 6.5 * root.s
                font.weight: Font.DemiBold
                font.letterSpacing: 2
            }

            Row {
                id: weekRow
                width: parent.width
                height: 80 * root.s
                readonly property real cellW: (width - 6 * spacing) / 7
                readonly property real maxBarH: height - 20 * root.s
                spacing: 7 * root.s

                Repeater {
                    model: ScreenTime.weekly
                    delegate: Item {
                        id: day
                        required property var modelData
                        width: weekRow.cellW
                        height: weekRow.height

                        Rectangle {
                            anchors.bottom: dayLabel.top
                            anchors.bottomMargin: 6 * root.s
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width * 0.66
                            radius: 3 * root.s
                            height: day.modelData.total > 0
                                ? Math.max(3 * root.s, weekRow.maxBarH * day.modelData.total / Math.max(1, ScreenTime.weeklyMax))
                                : 0
                            color: day.modelData.isToday ? Theme.primary
                                : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.22)
                            Behavior on height {
                                enabled: root.motionAllowed
                                NumberAnimation { duration: Motion.fast }
                            }
                        }
                        Text {
                            id: dayLabel
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: I18n.tr(day.modelData.label)
                            color: day.modelData.isToday ? root.ink : root.dim
                            font.family: Theme.mono
                            font.pixelSize: 6.5 * root.s
                            font.weight: day.modelData.isToday ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 7 * root.s

            Text {
                text: I18n.tr("MOST USED")
                color: root.dim
                font.family: Theme.fontPrimary
                font.pixelSize: 6.5 * root.s
                font.weight: Font.DemiBold
                font.letterSpacing: 2
            }

            Text {
                width: parent.width
                visible: ScreenTime.topApps.length === 0
                text: I18n.tr("Nothing tracked yet. Usage builds as you work.")
                wrapMode: Text.WordWrap
                color: root.dim
                font.family: Theme.fontPrimary
                font.pixelSize: 8 * root.s
            }

            Repeater {
                model: root.compact ? ScreenTime.topApps.slice(0, 3) : ScreenTime.topApps
                delegate: Item {
                    id: appRow
                    required property var modelData
                    width: parent.width
                    height: 33 * root.s

                    Image {
                        id: appIcon
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.topMargin: 2 * root.s
                        width: 15 * root.s
                        height: 15 * root.s
                        visible: appRow.modelData.icon !== ""
                        source: appRow.modelData.icon
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                        smooth: true
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.topMargin: 2 * root.s
                        width: 15 * root.s
                        height: 15 * root.s
                        radius: 5 * root.s
                        visible: appRow.modelData.icon === ""
                        color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.08)
                        Text {
                            anchors.centerIn: parent
                            text: appRow.modelData.name.charAt(0).toUpperCase()
                            color: root.dim
                            font.family: Theme.mono
                            font.pixelSize: 8 * root.s
                        }
                    }

                    Text {
                        id: appName
                        anchors.left: appIcon.right
                        anchors.leftMargin: 10 * root.s
                        anchors.right: appTime.left
                        anchors.rightMargin: 10 * root.s
                        anchors.top: parent.top
                        anchors.topMargin: 4 * root.s
                        text: appRow.modelData.name
                        elide: Text.ElideRight
                        color: root.ink
                        font.family: Theme.fontPrimary
                        font.pixelSize: 8.5 * root.s
                    }
                    Text {
                        id: appTime
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 4 * root.s
                        text: ScreenTime.fmtDuration(appRow.modelData.seconds)
                        color: root.dim
                        font.family: Theme.mono
                        font.pixelSize: 7.5 * root.s
                    }

                    Rectangle {
                        anchors.left: appName.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3 * root.s
                        height: 3 * root.s
                        radius: 1.5 * root.s
                        color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.10)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(0.03, appRow.modelData.seconds / Math.max(1, ScreenTime.topSeconds))
                            radius: parent.radius
                            color: Theme.primary
                            Behavior on width {
                                enabled: root.motionAllowed
                                NumberAnimation { duration: Motion.fast }
                            }
                        }
                    }
                }
            }
        }
    }
}
