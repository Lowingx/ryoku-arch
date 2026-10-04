pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root

    required property real s
    required property var screen
    required property bool active
    property string page: "today"
    property string currentPage: "overview"
    signal requestClose()

    implicitWidth: Math.round(640 * root.s)
    implicitHeight: Math.round(430 * root.s)

    function normalizedPage(value) {
        const key = String(value || "").toLowerCase();
        if (key === "weather" || key === "media" || key === "notices")
            return key;
        return "overview";
    }

    function showPage(value) {
        root.currentPage = root.normalizedPage(value);
        SidebarState.selectTab("right", root.screen, root.currentPage === "overview" ? "today" : root.currentPage);
    }


    onPageChanged: root.showPage(root.page)
    onActiveChanged: if (root.active) root.showPage(root.page)
    Component.onCompleted: root.showPage(root.page)


    Item {
        id: body
        anchors.fill: parent

        Item {
            id: overview
            anchors.fill: parent
            visible: root.currentPage === "overview"

            Item {
                id: overviewTop
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.round(228 * root.s)

                TodayCalendar {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.round((parent.width - Tokens.s2 * root.s) * 0.49)
                    s: root.s
                    active: root.active && overview.visible
                }

                Column {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.round((parent.width - Tokens.s2 * root.s) * 0.51)
                    spacing: Tokens.s2 * root.s

                    TodayWeather {
                        width: parent.width
                        height: Math.round(108 * root.s)
                        s: root.s
                        active: root.active && overview.visible
                        onRequestDetail: root.showPage("weather")
                    }
                    TodayMedia {
                        width: parent.width
                        height: Math.round(112 * root.s)
                        s: root.s
                        active: root.active && overview.visible
                        onRequestDetail: root.showPage("media")
                    }
                }
            }

            TodayActivity {
                id: activity
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: overviewTop.bottom
                anchors.topMargin: Tokens.s2 * root.s
                height: Math.round(46 * root.s)
                s: root.s
                active: root.active && overview.visible
                onOpenActivity: SidebarState.openWindow("activity", root.screen, "")
            }

            TodayNotifications {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: activity.bottom
                anchors.bottom: parent.bottom
                anchors.topMargin: Tokens.s2 * root.s
                s: root.s
                active: root.active && overview.visible
                onRequestDetail: root.showPage("notices")
                onRequestClose: root.requestClose()
            }
        }

        TodayWeather {
            anchors.fill: parent
            visible: root.currentPage === "weather"
            s: root.s
            active: root.active && visible
            detailed: true
        }

        TodayMedia {
            anchors.fill: parent
            visible: root.currentPage === "media"
            s: root.s
            active: root.active && visible
            detailed: true
        }

        TodayNotifications {
            anchors.fill: parent
            visible: root.currentPage === "notices"
            s: root.s
            active: root.active && visible
            detailed: true
            onRequestClose: root.requestClose()
        }
    }
}
