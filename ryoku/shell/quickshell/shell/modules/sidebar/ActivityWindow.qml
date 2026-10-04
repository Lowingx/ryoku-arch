pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services

UtilityWindow {
    id: root

    windowTitle: I18n.tr("Ryoku Activity")
    heading: I18n.tr("Activity")
    subtitle: I18n.tr("Private, on-device screen time")

    readonly property var week: root.active ? ScreenTime.weekly : []
    readonly property var todayEntry: root.active ? ScreenTime.todayEntry : null
    readonly property var hours: root.todayEntry && root.todayEntry.hours ? root.todayEntry.hours : []
    readonly property int weekTotal: {
        let total = 0;
        for (let i = 0; i < root.week.length; i++) total += root.week[i].total || 0;
        return total;
    }
    readonly property int hourMax: {
        let value = 1;
        for (let i = 0; i < root.hours.length; i++) value = Math.max(value, root.hours[i] || 0);
        return value;
    }
    readonly property var apps: {
        if (!root.active || !root.todayEntry || !root.todayEntry.apps)
            return [];
        const rows = [];
        for (const cls in root.todayEntry.apps) {
            const entry = (typeof DesktopEntries !== "undefined" && DesktopEntries.heuristicLookup)
                ? DesktopEntries.heuristicLookup(cls) : null;
            rows.push({
                cls: cls,
                seconds: root.todayEntry.apps[cls] || 0,
                name: entry && entry.name ? entry.name : ScreenTime.prettyClass(cls),
                icon: entry && entry.icon ? Icons.path(entry.icon, true) : ""
            });
        }
        rows.sort((a, b) => b.seconds - a.seconds);
        return rows;
    }
    readonly property int appMax: root.apps.length > 0 ? Math.max(1, root.apps[0].seconds) : 1

    body: [
    Item {
        anchors.fill: parent

        Item {
            id: summary
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.round(116 * root.s)

            Rectangle {
                id: todayTile
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.round((parent.width - Tokens.s3 * root.s) * 0.52)
                radius: Tokens.radius * root.s * 1.5
                color: Tokens.role("primaryContainer", Tokens.paperLift)
                border.width: Tokens.border
                border.color: Tokens.role("primary", Tokens.lineStrong)

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Tokens.s4 * root.s
                    anchors.rightMargin: Tokens.s4 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.s1 * root.s

                    Text {
                        width: parent.width
                        text: I18n.tr("ACTIVE TODAY")
                        color: Tokens.role("onPrimaryContainer", Tokens.inkMuted)
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fTiny * root.s
                        font.weight: Font.DemiBold
                        font.letterSpacing: Tokens.trackMark
                    }
                    Text {
                        width: parent.width
                        text: ScreenTime.fmtDuration(root.active ? ScreenTime.activeToday : 0)
                        color: Tokens.role("onPrimaryContainer", Tokens.ink)
                        font.family: Tokens.display
                        font.pixelSize: Tokens.fHero * root.s
                        font.weight: Font.Medium
                        font.features: ({ "tnum": 1 })
                    }
                    Text {
                        width: parent.width
                        text: root.apps.length > 0
                            ? I18n.tr("Most used: %1").arg(root.apps[0].name)
                            : I18n.tr("Usage builds while a real app is focused")
                        color: Tokens.role("onPrimaryContainer", Tokens.inkMuted)
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                anchors.left: todayTile.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: Tokens.s3 * root.s
                radius: Tokens.radius * root.s * 1.5
                color: Tokens.role("secondaryContainer", Tokens.paperLift)
                border.width: Tokens.border
                border.color: Tokens.role("secondary", Tokens.lineStrong)

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Tokens.s4 * root.s
                    anchors.rightMargin: Tokens.s4 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.s1 * root.s

                    Text {
                        width: parent.width
                        text: I18n.tr("LAST 7 DAYS")
                        color: Tokens.role("onSecondaryContainer", Tokens.inkMuted)
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fTiny * root.s
                        font.weight: Font.DemiBold
                        font.letterSpacing: Tokens.trackMark
                    }
                    Text {
                        width: parent.width
                        text: ScreenTime.fmtDuration(root.weekTotal)
                        color: Tokens.role("onSecondaryContainer", Tokens.ink)
                        font.family: Tokens.display
                        font.pixelSize: Tokens.fHero * root.s
                        font.weight: Font.Medium
                        font.features: ({ "tnum": 1 })
                    }
                    Text {
                        width: parent.width
                        text: I18n.tr("Local history, never uploaded")
                        color: Tokens.role("onSecondaryContainer", Tokens.inkMuted)
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                    }
                }
            }
        }

        Row {
            id: charts
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: summary.bottom
            anchors.topMargin: Tokens.s3 * root.s
            height: Math.round(196 * root.s)
            spacing: Tokens.s3 * root.s

            Rectangle {
                width: Math.round((parent.width - parent.spacing) * 0.5)
                height: parent.height
                radius: Tokens.radius * root.s * 1.5
                color: Tokens.role("surfaceContainerLow", Tokens.paperLift)
                border.width: Tokens.border
                border.color: Tokens.line

                Column {
                    anchors.fill: parent
                    anchors.margins: Tokens.s4 * root.s
                    spacing: Tokens.s2 * root.s

                    Text {
                        width: parent.width
                        text: I18n.tr("Daily totals")
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fRow * root.s
                        font.weight: Font.DemiBold
                    }

                    Row {
                        id: weekBars
                        width: parent.width
                        height: parent.height - y

                        Repeater {
                            model: root.week
                            delegate: Item {
                                id: weekDay
                                required property var modelData
                                width: weekBars.width / Math.max(1, root.week.length)
                                height: weekBars.height

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    text: ScreenTime.fmtDuration(weekDay.modelData.total)
                                    color: weekDay.modelData.isToday ? Tokens.role("primary", Tokens.sun) : Tokens.inkMuted
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fTiny * root.s
                                }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: label.top
                                    anchors.bottomMargin: Tokens.s2 * root.s
                                    width: Math.max(5 * root.s, Math.round(weekDay.width * 0.26))
                                    height: weekDay.modelData.total > 0
                                        ? Math.max(3 * root.s, (weekBars.height - 45 * root.s) * weekDay.modelData.total / Math.max(1, ScreenTime.weeklyMax))
                                        : 0
                                    radius: width / 2
                                    color: weekDay.modelData.isToday
                                        ? Tokens.role("primary", Tokens.sun)
                                        : Tokens.role("secondary", Tokens.inkMuted)
                                    opacity: weekDay.modelData.isToday ? 1 : 0.62
                                }
                                Text {
                                    id: label
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    text: I18n.tr(weekDay.modelData.label)
                                    color: weekDay.modelData.isToday ? Tokens.role("primary", Tokens.sun) : Tokens.inkMuted
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fSmall * root.s
                                    font.weight: weekDay.modelData.isToday ? Font.DemiBold : Font.Normal
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - parent.children[0].width - parent.spacing
                height: parent.height
                radius: Tokens.radius * root.s * 1.5
                color: Tokens.role("surfaceContainerLow", Tokens.paperLift)
                border.width: Tokens.border
                border.color: Tokens.line

                Column {
                    anchors.fill: parent
                    anchors.margins: Tokens.s4 * root.s
                    spacing: Tokens.s2 * root.s

                    Text {
                        width: parent.width
                        text: I18n.tr("Today by hour")
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fRow * root.s
                        font.weight: Font.DemiBold
                    }

                    Row {
                        id: hourBars
                        width: parent.width
                        height: parent.height - y

                        Repeater {
                            model: 24
                            delegate: Item {
                                id: hour
                                required property int index
                                readonly property int seconds: root.hours.length > hour.index ? root.hours[hour.index] || 0 : 0
                                width: hourBars.width / 24
                                height: hourBars.height

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: hourLabel.top
                                    anchors.bottomMargin: Tokens.s1 * root.s
                                    width: Math.max(2 * root.s, hour.width * 0.55)
                                    height: hour.seconds > 0
                                        ? Math.max(2 * root.s, (hourBars.height - 24 * root.s) * hour.seconds / root.hourMax)
                                        : 0
                                    radius: width / 2
                                    color: Tokens.role("tertiary", Tokens.sun)
                                    opacity: hour.index === new Date().getHours() ? 1 : 0.62
                                }
                                Text {
                                    id: hourLabel
                                    visible: hour.index % 6 === 0
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    text: String(hour.index).padStart(2, "0")
                                    color: Tokens.inkFaint
                                    font.family: Tokens.mono
                                    font.pixelSize: Tokens.fTiny * root.s
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: charts.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: Tokens.s3 * root.s
            radius: Tokens.radius * root.s * 1.5
            color: Tokens.role("surfaceContainerLow", Tokens.paperLift)
            border.width: Tokens.border
            border.color: Tokens.line

            Column {
                anchors.fill: parent
                anchors.margins: Tokens.s4 * root.s
                spacing: Tokens.s2 * root.s

                Item {
                    width: parent.width
                    height: Math.round(25 * root.s)
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("Apps today")
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fRow * root.s
                        font.weight: Font.DemiBold
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("%1 tracked").arg(root.apps.length)
                        color: Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                    }
                }

                Item {
                    visible: root.apps.length === 0
                    width: parent.width
                    height: parent.height - y
                    Text {
                        anchors.centerIn: parent
                        text: I18n.tr("Nothing tracked yet")
                        color: Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                    }
                }

                ListView {
                    visible: root.apps.length > 0
                    width: parent.width
                    height: parent.height - y
                    model: root.apps
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    QQC.ScrollBar.vertical: ScrollRail {
                        policy: QQC.ScrollBar.AsNeeded
                        motionEnabled: !Tokens.reduceMotion && !Motion.reduce
                    }

                    delegate: Item {
                        id: app
                        required property var modelData
                        required property int index
                        width: ListView.view ? ListView.view.width : 0
                        height: Math.round(50 * root.s)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: Tokens.border
                            visible: app.index > 0
                            color: Tokens.lineSoft
                        }
                        Image {
                            id: appIcon
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(28 * root.s)
                            height: width
                            source: app.modelData.icon
                            sourceSize.width: width * 2
                            sourceSize.height: height * 2
                            visible: source.toString().length > 0
                        }
                        Rectangle {
                            anchors.fill: appIcon
                            visible: !appIcon.visible
                            radius: Tokens.radius * root.s
                            color: Tokens.role("tertiaryContainer", Tokens.tint10)
                            Text {
                                anchors.centerIn: parent
                                text: String(app.modelData.name).charAt(0).toUpperCase()
                                color: Tokens.role("onTertiaryContainer", Tokens.ink)
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fSmall * root.s
                                font.weight: Font.DemiBold
                            }
                        }
                        Text {
                            id: appName
                            anchors.left: appIcon.right
                            anchors.right: appTime.left
                            anchors.leftMargin: Tokens.s3 * root.s
                            anchors.rightMargin: Tokens.s3 * root.s
                            anchors.top: parent.top
                            anchors.topMargin: Tokens.s2 * root.s
                            text: app.modelData.name
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall * root.s
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Text {
                            id: appTime
                            anchors.right: parent.right
                            anchors.baseline: appName.baseline
                            text: ScreenTime.fmtDuration(app.modelData.seconds)
                            color: Tokens.inkMuted
                            font.family: Tokens.mono
                            font.pixelSize: Tokens.fSmall * root.s
                            font.features: ({ "tnum": 1 })
                        }
                        Rectangle {
                            anchors.left: appName.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: Tokens.s2 * root.s
                            height: Math.round(3 * root.s)
                            radius: height / 2
                            color: Tokens.lineSoft
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, app.modelData.seconds / root.appMax))
                                height: parent.height
                                radius: parent.radius
                                color: Tokens.role("primary", Tokens.sun)
                            }
                        }
                    }
                }
            }
        }
    }
    ]
}
