pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root

    required property real s
    required property bool active

    readonly property var locale: Qt.locale()
    readonly property int weekStart: root.locale.firstDayOfWeek % 7
    readonly property date today: clock.date
    readonly property int offset: {
        const first = new Date(root.viewYear, root.viewMonth, 1).getDay();
        return (first - root.weekStart + 7) % 7;
    }
    readonly property int monthLength: new Date(root.viewYear, root.viewMonth + 1, 0).getDate()
    readonly property int previousMonthLength: new Date(root.viewYear, root.viewMonth, 0).getDate()
    readonly property string todayKey: root.dateKey(root.today.getFullYear(), root.today.getMonth(), root.today.getDate())
    readonly property var todayEvents: root.active ? Events.forDate(root.todayKey) : []

    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    property int rolloverKey: -1

    implicitHeight: Math.round(228 * root.s)

    function pad(value) {
        return value < 10 ? "0" + value : String(value);
    }

    function dateKey(year, month, day) {
        return year + "-" + root.pad(month + 1) + "-" + root.pad(day);
    }

    function shiftMonth(delta) {
        const shifted = new Date(root.viewYear, root.viewMonth + delta, 1);
        root.viewYear = shifted.getFullYear();
        root.viewMonth = shifted.getMonth();
    }

    function resetMonth() {
        root.viewYear = root.today.getFullYear();
        root.viewMonth = root.today.getMonth();
    }

    function isToday(day) {
        return day === root.today.getDate()
            && root.viewMonth === root.today.getMonth()
            && root.viewYear === root.today.getFullYear();
    }

    onTodayChanged: {
        const key = root.today.getFullYear() * 10000 + root.today.getMonth() * 100 + root.today.getDate();
        if (key !== root.rolloverKey) {
            root.rolloverKey = key;
            root.resetMonth();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.active
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radius * root.s * 1.5
        color: Tokens.role("surfaceContainerLow", Tokens.paperLift)
        border.width: Tokens.border
        border.color: Tokens.line

        Column {
            anchors.fill: parent
            anchors.margins: Tokens.s2 * root.s
            spacing: Tokens.s1 * root.s

            Item {
                width: parent.width
                height: Math.round(37 * root.s)

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        text: Qt.formatDate(root.today, "dddd")
                        color: Tokens.role("primary", Tokens.sun)
                        font.family: Tokens.display
                        font.pixelSize: Tokens.fValue * root.s
                        font.weight: Font.Medium
                    }
                    Text {
                        text: Qt.formatDate(root.today, "MMMM d")
                            + (root.todayEvents.length > 0 ? I18n.tr(" · %1 planned").arg(root.todayEvents.length) : "")
                        color: Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.today.getDate()
                    color: Tokens.ink
                    font.family: Tokens.display
                    font.pixelSize: Tokens.fHero * root.s
                    font.weight: Font.Medium
                    font.features: ({ "tnum": 1 })
                }
            }

            Rectangle {
                width: parent.width
                height: Tokens.border
                color: Tokens.lineSoft
            }

            Item {
                width: parent.width
                height: Math.round(36 * root.s)

                CornerButton {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    glyph: "chevron_left"
                    subtle: true
                    Accessible.name: I18n.tr("Previous month")
                    onClicked: root.shiftMonth(-1)
                }

                Text {
                    anchors.centerIn: parent
                    text: root.locale.standaloneMonthName(root.viewMonth, Locale.LongFormat) + " " + root.viewYear
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                    font.weight: Font.DemiBold
                }

                CornerButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    glyph: "chevron_right"
                    subtle: true
                    Accessible.name: I18n.tr("Next month")
                    onClicked: root.shiftMonth(1)
                }
            }

            Row {
                id: weekdays
                width: parent.width
                height: Math.round(14 * root.s)

                Repeater {
                    model: 7
                    delegate: Text {
                        required property int index
                        width: weekdays.width / 7
                        text: root.locale.standaloneDayName((root.weekStart + index) % 7, Locale.NarrowFormat)
                        color: Tokens.inkFaint
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fTiny * root.s
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Grid {
                id: grid
                width: parent.width
                columns: 7
                rowSpacing: Math.round(2 * root.s)

                Repeater {
                    model: 42
                    delegate: Item {
                        id: dayCell
                        required property int index

                        readonly property int day: index - root.offset + 1
                        readonly property bool inMonth: day >= 1 && day <= root.monthLength
                        readonly property int shownDay: day < 1 ? root.previousMonthLength + day
                            : day > root.monthLength ? day - root.monthLength : day
                        readonly property bool current: inMonth && root.isToday(day)
                        readonly property string key: inMonth ? root.dateKey(root.viewYear, root.viewMonth, day) : ""
                        readonly property bool hasEvents: root.active && inMonth && Events.hasEvents(key)

                        width: grid.width / 7
                        height: Math.round(16 * root.s)

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.round(16 * root.s)
                            height: width
                            radius: width / 2
                            color: dayCell.current
                                ? Tokens.role("primary", Tokens.sun)
                                : dayCell.hasEvents ? Tokens.role("secondaryContainer", Tokens.tint10) : "transparent"
                        }
                        Text {
                            anchors.centerIn: parent
                            text: dayCell.shownDay
                            color: dayCell.current
                                ? Tokens.role("onPrimary", Tokens.inkOnBone)
                                : dayCell.inMonth ? Tokens.ink : Tokens.inkFaint
                            opacity: dayCell.inMonth ? 1 : 0.46
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny * root.s
                            font.weight: dayCell.current ? Font.DemiBold : Font.Normal
                            font.features: ({ "tnum": 1 })
                        }
                    }
                }
            }
        }
    }
}
