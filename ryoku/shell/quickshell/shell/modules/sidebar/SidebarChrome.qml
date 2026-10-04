pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root
    required property var screen
    required property string side
    required property real s
    required property bool active
    readonly property string page: SidebarState.activeTab(screen, side)
    readonly property bool detail: side === "left" ? page !== "controls" : page !== "today"
    readonly property real pad: 16 * s
    readonly property real fittedHeight: pad * 2 + header.height + 12 * s + (board.item ? board.item.implicitHeight : 380 * s)
    readonly property var pluginCards: pluginHost.cards(side)
    signal closeRequested()

    function home(): void { SidebarState.selectTab(root.side, root.screen, root.side === "left" ? "controls" : "today"); }
    SidebarPlugins { id: pluginHost; active: root.active }
    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.pad
        height: 30 * root.s
        CornerButton {
            id: back
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.detail
            s: root.s
            glyph: "arrow_back"
            subtle: true
            Accessible.name: root.side === "left" ? I18n.tr("Back to controls") : I18n.tr("Back to today")
            onClicked: root.home()
        }
        Text {
            anchors.left: back.visible ? back.right : parent.left
            anchors.leftMargin: back.visible ? 4 * root.s : 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.page === "plugins" ? I18n.tr("Extensions")
                : root.page === "weather" ? I18n.tr("Weather") : root.page === "media" ? I18n.tr("Now playing")
                : root.page === "notices" ? I18n.tr("Notifications") : root.page === "wifi" ? I18n.tr("Wi-Fi")
                : root.page === "bluetooth" ? I18n.tr("Bluetooth") : root.page === "audio" ? I18n.tr("Audio")
                : root.page === "capture" ? I18n.tr("Capture") : root.side === "left" ? I18n.tr("Controls") : I18n.tr("Today")
            color: Tokens.ink
            font.family: Tokens.ui
            font.pixelSize: Tokens.fBody * root.s
            font.weight: Font.DemiBold
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4 * root.s
            CornerButton {
                visible: root.side === "right"
                s: root.s; glyph: "construction"; text: I18n.tr("Tools"); subtle: true
                onClicked: SidebarState.openWindow("tools", root.screen, "")
            }
            CornerButton {
                visible: root.side === "right"
                s: root.s; glyph: "chat"; text: I18n.tr("Chat"); emphasis: true
                onClicked: SidebarState.openWindow("chat", root.screen, "")
            }
            CornerButton {
                visible: root.side === "left"
                s: root.s; glyph: "photo_camera"; subtle: true
                checked: root.page === "capture"
                Accessible.name: I18n.tr("Screenshot and recording")
                onClicked: SidebarState.selectTab(root.side, root.screen, root.page === "capture" ? "controls" : "capture")
            }
            CornerButton {
                visible: root.side === "left" && (Wm.caps.liveConfigEval === true || Toggles.gameMode)
                s: root.s; glyph: "sports_esports"; subtle: true
                checked: Toggles.gameMode
                Accessible.name: I18n.tr("Gaming mode")
                onClicked: Toggles.toggleGame()
            }
            CornerButton {
                visible: root.pluginCards.length > 0
                s: root.s; glyph: "extension"; subtle: true
                checked: root.page === "plugins"
                Accessible.name: I18n.tr("Extensions")
                onClicked: SidebarState.selectTab(root.side, root.screen, "plugins")
            }
            CornerButton {
                s: root.s; glyph: "tune"; subtle: true
                Accessible.name: I18n.tr("Ryoku Hub")
                onClicked: { root.closeRequested(); Spawn.run(["ryoku-shell", "hub", "open", "desktop"]); }
            }
            CornerButton {
                s: root.s; glyph: "close"; subtle: true
                Accessible.name: I18n.tr("Close")
                onClicked: root.closeRequested()
            }
        }
    }
    Loader {
        id: board
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        anchors.topMargin: 12 * root.s
        anchors.bottomMargin: root.pad
        sourceComponent: root.page === "plugins" ? extensions : root.side === "left" ? controls : today
    }
    Component {
        id: controls
        ControlsBoard { s: root.s; screen: root.screen; active: root.active; page: root.page; onRequestClose: root.closeRequested() }
    }
    Component {
        id: today
        TodayBoard { s: root.s; screen: root.screen; active: root.active; page: root.page; onRequestClose: root.closeRequested() }
    }
    Component {
        id: extensions
        ExtensionsBoard { s: root.s; plugins: root.pluginCards; active: root.active; onRequestClose: root.closeRequested() }
    }
}
