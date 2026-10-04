pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root

    required property real s
    required property bool active
    property bool detailed: false
    signal requestDetail()
    signal requestClose()

    readonly property var notices: root.active ? Notifs.history : []
    readonly property int shownCount: root.detailed ? root.notices.length : Math.min(2, root.notices.length)

    implicitHeight: Math.round((root.detailed ? 388 : 126) * root.s)

    function actions(notification) {
        const source = notification && notification.actions ? notification.actions : [];
        const out = [];
        for (let i = 0; i < source.length; i++) {
            const action = source[i];
            if (action && action.identifier !== "default" && String(action.text || "").length > 0)
                out.push(action);
        }
        return out;
    }

    function defaultAction(notification) {
        const source = notification && notification.actions ? notification.actions : [];
        for (let i = 0; i < source.length; i++) {
            if (source[i] && source[i].identifier === "default")
                return source[i];
        }
        return null;
    }

    function invoke(action) {
        if (action && typeof action.invoke === "function") {
            action.invoke();
            root.requestClose();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radius * root.s * 1.5
        color: Tokens.role("surfaceContainerLow", Tokens.paperLift)
        border.width: Tokens.border
        border.color: Tokens.line
        clip: true

        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.s3 * root.s
            height: Math.round(36 * root.s)

            Column {
                anchors.left: parent.left
                anchors.right: headerActions.left
                anchors.rightMargin: Tokens.s2 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    width: parent.width
                    text: I18n.tr("Notifications")
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fRow * root.s
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: root.notices.length === 0 ? I18n.tr("All clear") : I18n.tr("%1 recent").arg(root.notices.length)
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny * root.s
                    elide: Text.ElideRight
                }
            }

            Row {
                id: headerActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.s1 * root.s

                CornerButton {
                    s: root.s
                    glyph: Flags.dnd ? "notifications_off" : "notifications_active"
                    text: root.detailed ? I18n.tr("DND") : ""
                    checked: Flags.dnd
                    subtle: !Flags.dnd
                    Accessible.name: I18n.tr("Do not disturb")
                    onClicked: Toggles.toggleDnd()
                }
                CornerButton {
                    visible: root.detailed
                    s: root.s
                    glyph: "clear_all"
                    text: I18n.tr("Clear")
                    subtle: true
                    enabled: root.notices.length > 0
                    Accessible.name: I18n.tr("Clear notifications")
                    onClicked: Notifs.clearAll()
                }
                CornerButton {
                    visible: !root.detailed
                    s: root.s
                    glyph: "arrow_forward"
                    subtle: true
                    Accessible.name: I18n.tr("View all notifications")
                    onClicked: root.requestDetail()
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.leftMargin: Tokens.s3 * root.s
            anchors.rightMargin: Tokens.s3 * root.s
            anchors.topMargin: Tokens.s2 * root.s
            height: Tokens.border
            color: Tokens.lineSoft
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: Tokens.s3 * root.s
            anchors.rightMargin: Tokens.s3 * root.s
            anchors.topMargin: Tokens.s3 * root.s
            anchors.bottomMargin: Tokens.s2 * root.s

            Item {
                visible: root.notices.length === 0
                width: parent.width
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: I18n.tr("Nothing needs your attention")
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                }
            }

            ListView {
                id: list
                visible: root.notices.length > 0
                width: parent.width
                height: parent.height
                model: root.notices.slice(0, root.shownCount)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 0
                QQC.ScrollBar.vertical: ScrollRail {
                    policy: root.detailed ? QQC.ScrollBar.AsNeeded : QQC.ScrollBar.AlwaysOff
                    motionEnabled: !Tokens.reduceMotion && !Motion.reduce
                }

                delegate: QQC.AbstractButton {
                    id: notice
                    required property var modelData
                    required property int index

                    readonly property var openAction: root.defaultAction(notice.modelData)
                    readonly property var extraActions: root.actions(notice.modelData)
                    readonly property string appName: notice.modelData ? notice.modelData.appName || I18n.tr("Notification") : I18n.tr("Notification")
                    readonly property bool groupStart: notice.index === 0
                        || String(root.notices[notice.index - 1].appName || "") !== String(notice.appName)
                    readonly property real groupHeight: root.detailed && notice.groupStart ? Math.round(20 * root.s) : 0

                    width: ListView.view ? ListView.view.width : 0
                    height: Math.round((root.detailed ? 82 : 38) * root.s) + notice.groupHeight
                    hoverEnabled: true
                    Accessible.name: (notice.modelData.summary || notice.appName) + " " + (notice.modelData.body || "")
                    onClicked: root.invoke(notice.openAction)

                    background: Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: notice.groupHeight
                        radius: Tokens.radius * root.s
                        color: notice.down ? Tokens.tint16 : notice.hovered ? Tokens.tint5 : "transparent"
                        Behavior on color {
                            enabled: !Tokens.reduceMotion && !Motion.reduce
                            ColorAnimation { duration: Tokens.snap }
                        }
                    }

                    contentItem: Item {
                        Text {
                            visible: root.detailed && notice.groupStart
                            anchors.left: parent.left
                            anchors.top: parent.top
                            height: notice.groupHeight
                            text: notice.appName
                            color: Tokens.role("primary", Tokens.sun)
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny * root.s
                            font.weight: Font.DemiBold
                            font.letterSpacing: Tokens.trackLabel
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: actionsRow.left
                            anchors.leftMargin: Tokens.s2 * root.s
                            anchors.rightMargin: Tokens.s2 * root.s
                            anchors.top: parent.top
                            anchors.topMargin: notice.groupHeight + Tokens.s1 * root.s
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: Tokens.s1 * root.s
                            spacing: 0

                            Text {
                                width: parent.width
                                text: notice.modelData ? notice.modelData.summary || notice.appName : ""
                                color: Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fSmall * root.s
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: root.detailed
                                width: parent.width
                                text: notice.modelData ? notice.modelData.body || "" : ""
                                textFormat: Text.PlainText
                                color: Tokens.inkMuted
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fTiny * root.s
                                maximumLineCount: 2
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: !root.detailed
                                width: parent.width
                                text: notice.appName + " · " + Notifs.timeLabel(notice.modelData)
                                color: Tokens.inkMuted
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fTiny * root.s
                                elide: Text.ElideRight
                            }
                        }

                        Row {
                            id: actionsRow
                            anchors.right: parent.right
                            anchors.rightMargin: Tokens.s1 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: notice.groupHeight / 2
                            spacing: Tokens.s1 * root.s

                            Repeater {
                                model: root.detailed ? notice.extraActions : []
                                delegate: CornerButton {
                                    required property var modelData
                                    s: root.s
                                    text: modelData.text
                                    subtle: true
                                    onClicked: root.invoke(modelData)
                                }
                            }
                            CornerButton {
                                s: root.s
                                glyph: "close"
                                subtle: true
                                Accessible.name: I18n.tr("Dismiss notification")
                                onClicked: Notifs.dismiss(notice.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
