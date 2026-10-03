pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import shell.services
import Ryoku.Ui.Singletons
import "../../../components" as Components
import "../../bar" as Bar
import "../../bar/framebars/menus" as Menus
import "../cards" as Cards
import "." as Classic

Item {
    id: root

    required property real s
    required property bool open
    required property real reveal
    required property bool tabActive
    property int index: 0
    property bool compact: false
    property real viewportHeight: 0
    property string page: ""
    property string detailPage: "overview"
    readonly property bool active: root.open && root.tabActive
    readonly property bool overviewActive: root.active && root.detailPage === "overview"
    readonly property bool motionAllowed: !Motion.reduce && !Tokens.reduceMotion
    readonly property real pad: 12 * root.s
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property string wifiSummary: !Network.wifiPresent ? I18n.tr("No adapter")
        : !Network.wifiRadio ? I18n.tr("Off")
        : Network.activeSsid !== "" ? Network.activeSsid
        : Network.wifiConnectivity === "Connecting" ? I18n.tr("Connecting…")
        : I18n.tr("On")
    readonly property string bluetoothSummary: !root.btAdapter ? I18n.tr("No adapter")
        : root.btAdapter.enabled ? I18n.tr("On") : I18n.tr("Off")
    signal requestClose()

    implicitHeight: root.viewportHeight > 0 ? root.viewportHeight : (root.compact ? 520 : 720) * root.s

    onOpenChanged: if (!root.open) root.detailPage = "overview"
    onPageChanged: {
        if (root.page === "wifi" || root.page === "network")
            root.detailPage = "wifi";
        else if (root.page === "bluetooth")
            root.detailPage = "bluetooth";
        else if (root.page === "audio" || root.page === "audio-out" || root.page === "audio-in")
            root.detailPage = "audio";
    }

    function awakeFor(): string {
        const since = Flags.keepAwakeSince;
        if (!since || since <= 0)
            return "";
        const minutes = Math.floor((Date.now() - since) / 60000);
        if (minutes < 1)
            return "";
        if (minutes < 60)
            return " " + I18n.tr("for %1m").arg(minutes);
        if (minutes < 1440)
            return " " + I18n.tr("for %1h").arg(Math.floor(minutes / 60));
        return " " + I18n.tr("for %1d").arg(Math.floor(minutes / 1440));
    }

    function setVolume(value): void {
        if (!Audio.sink || !Audio.sink.audio)
            return;
        const next = Math.max(0, Math.min(1, value));
        if (Audio.sink.audio.muted && next > 0)
            Audio.sink.audio.muted = false;
        Audio.sink.audio.volume = next;
    }

    function setMicVolume(value): void {
        if (!Audio.source || !Audio.source.audio)
            return;
        const next = Math.max(0, Math.min(1, value));
        if (Audio.source.audio.muted && next > 0)
            Audio.source.audio.muted = false;
        Audio.source.audio.volume = next;
    }

    function sessionAction(action): void {
        root.requestClose();
        ShellState.askSessionAction(action, "");
    }

    component SectionLabel: Item {
        id: section
        required property string label
        implicitHeight: 26 * root.s
        Row {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 8 * root.s
            Text {
                id: sectionText
                anchors.verticalCenter: parent.verticalCenter
                text: section.label.toUpperCase()
                color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                font.family: Theme.fontPrimary
                font.pixelSize: (Theme.fontSm - 3) * root.s
                font.weight: Font.DemiBold
                font.letterSpacing: 2 * root.s
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - sectionText.width - parent.spacing
                height: Theme.borderWidth
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.25)
            }
        }
    }

    component SessionButton: Rectangle {
        id: button
        required property string icon
        required property string accessibleName
        required property var action
        implicitWidth: 34 * root.s
        implicitHeight: 34 * root.s
        radius: Theme.radiusWidget * root.s
        color: tap.containsMouse
            ? Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.12)
            : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.06)
        border.width: Theme.borderWidth
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.28)
        scale: tap.pressed ? 0.92 : 1
        Accessible.name: button.accessibleName
        Behavior on color {
            enabled: root.motionAllowed
            ColorAnimation { duration: Motion.crossfade; easing.type: Motion.crossfadeCurve }
        }
        Behavior on scale {
            enabled: root.motionAllowed
            NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack }
        }
        Components.MaterialIcon {
            anchors.centerIn: parent
            text: button.icon
            color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface, 3.0)
            font.pixelSize: 17 * root.s
        }
        MouseArea {
            id: tap
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.action()
        }
    }

    component MixerButton: Rectangle {
        id: button
        implicitHeight: 36 * root.s
        radius: Theme.radiusWidget * root.s
        color: tap.containsMouse
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
            : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.06)
        border.width: Theme.borderWidth
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.30)
        Behavior on color {
            enabled: root.motionAllowed
            ColorAnimation { duration: Motion.crossfade; easing.type: Motion.crossfadeCurve }
        }
        Row {
            anchors.centerIn: parent
            spacing: 7 * root.s
            Components.MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "equalizer"
                color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface, 3.0)
                font.pixelSize: 17 * root.s
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Audio mixer")
                color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface)
                font.family: Theme.fontPrimary
                font.pixelSize: Theme.fontSm * root.s
                font.weight: Font.DemiBold
            }
            Components.MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_right"
                color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                font.pixelSize: 16 * root.s
            }
        }
        MouseArea {
            id: tap
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detailPage = "audio"
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.active
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Column {
        id: header
        visible: root.detailPage === "overview"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        anchors.topMargin: 10 * root.s
        spacing: 3 * root.s
        height: visible ? implicitHeight : 0

        Item {
            width: parent.width
            height: 42 * root.s
            Text {
                anchors.left: parent.left
                anchors.right: sessionActions.left
                anchors.rightMargin: 8 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface)
                font.family: Theme.fontPrimary
                font.pixelSize: 32 * root.s
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            Row {
                id: sessionActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4 * root.s
                SessionButton {
                    icon: "logout"
                    accessibleName: I18n.tr("Log out")
                    action: () => root.sessionAction("logout")
                }
                SessionButton {
                    icon: "lock"
                    accessibleName: I18n.tr("Lock")
                    action: () => {
                        root.requestClose();
                        Spawn.run(["ryoku-shell", "lock"]);
                    }
                }
                SessionButton {
                    icon: "restart_alt"
                    accessibleName: I18n.tr("Restart")
                    action: () => root.sessionAction("reboot")
                }
                SessionButton {
                    icon: "power_settings_new"
                    accessibleName: I18n.tr("Shut down")
                    action: () => root.sessionAction("poweroff")
                }
            }
        }

        Item {
            width: parent.width
            height: 24 * root.s
            Text {
                anchors.left: parent.left
                anchors.right: batteryPill.visible ? batteryPill.left : parent.right
                anchors.rightMargin: batteryPill.visible ? 6 * root.s : 0
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.locale().toString(clock.date, "dddd") + ", " + Qt.formatDate(clock.date, "MMM d, yyyy")
                color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                font.family: Theme.fontPrimary
                font.pixelSize: Theme.fontSm * root.s
                elide: Text.ElideRight
            }
            Rectangle {
                id: batteryPill
                visible: Battery.present
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: batteryRow.implicitWidth + 14 * root.s
                height: 22 * root.s
                radius: height / 2
                color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.07)
                border.width: Theme.borderWidth
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.25)
                Row {
                    id: batteryRow
                    anchors.centerIn: parent
                    spacing: 4 * root.s
                    Components.MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Battery.charging ? "bolt" : "battery_full"
                        color: Battery.charging ? Theme.primary : Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                        font.pixelSize: 13 * root.s
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Battery.pct + "%"
                        color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface)
                        font.family: Theme.fontPrimary
                        font.pixelSize: (Theme.fontSm - 2) * root.s
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    Column {
        id: powerDock
        visible: root.detailPage === "overview" && PowerProfiles.available
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        anchors.bottomMargin: 10 * root.s
        spacing: 5 * root.s
        height: visible ? implicitHeight : 0
        Rectangle {
            width: parent.width
            height: Theme.borderWidth
            color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.10)
        }
        SectionLabel { width: parent.width; label: I18n.tr("Power") }
        Menus.QsSeg {
            width: parent.width
            height: 38 * root.s
            current: PowerProfiles.profile
            options: PowerProfiles.profiles.map(profile => ({
                id: profile,
                label: profile === "power-saver" ? I18n.tr("Saver")
                    : profile === "balanced" ? I18n.tr("Balanced") : I18n.tr("Performance")
            }))
            onChose: profile => PowerProfiles.setProfile(profile)
        }
    }

    Flickable {
        id: scroller
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: powerDock.top
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        anchors.topMargin: root.detailPage === "overview" ? 10 * root.s : root.pad
        anchors.bottomMargin: root.detailPage === "overview" && powerDock.visible ? 8 * root.s : root.pad
        contentWidth: width
        contentHeight: pageContent.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
            id: pageContent
            width: parent.width
            spacing: 12 * root.s

            Column {
                id: overview
                visible: root.detailPage === "overview"
                width: parent.width
                spacing: 12 * root.s
                height: visible ? implicitHeight : 0

                SectionLabel { width: parent.width; label: I18n.tr("Connect") }
                Grid {
                    id: tileGrid
                    width: parent.width
                    columns: 2
                    columnSpacing: 8 * root.s
                    rowSpacing: 8 * root.s
                    readonly property real tileWidth: (width - columnSpacing) / 2

                    Classic.ClassicTile {
                        width: tileGrid.tileWidth
                        s: root.s
                        icon: Network.kind === "ethernet" ? "lan" : "wifi"
                        label: I18n.tr("Wi-Fi")
                        sub: root.wifiSummary
                        on: Network.wifiRadio
                        available: Network.wifiPresent
                        hasPage: true
                        pageTip: I18n.tr("Wi-Fi networks")
                        onToggled: Toggles.toggleWifi()
                        onPageRequested: root.detailPage = "wifi"
                    }
                    Classic.ClassicTile {
                        width: tileGrid.tileWidth
                        s: root.s
                        icon: "bluetooth"
                        label: I18n.tr("Bluetooth")
                        sub: root.bluetoothSummary
                        on: !!root.btAdapter && root.btAdapter.enabled
                        available: !!root.btAdapter
                        hasPage: true
                        pageTip: I18n.tr("Bluetooth devices")
                        onToggled: Toggles.toggleBt()
                        onPageRequested: root.detailPage = "bluetooth"
                    }
                    Classic.ClassicTile {
                        width: tileGrid.tileWidth
                        s: root.s
                        icon: "flight"
                        label: I18n.tr("Airplane")
                        sub: Network.wifiRadio ? I18n.tr("Off") : I18n.tr("On")
                        on: !Network.wifiRadio
                        available: Network.wifiPresent
                        onToggled: Toggles.toggleWifi()
                    }
                    Classic.ClassicTile {
                        visible: Wm.caps.nightLight === true
                        width: tileGrid.tileWidth
                        s: root.s
                        icon: "bedtime"
                        label: I18n.tr("Night light")
                        sub: Toggles.nightOn ? I18n.tr("On") : I18n.tr("Off")
                        on: Toggles.nightOn
                        onToggled: Toggles.toggleNight()
                    }
                    Classic.ClassicTile {
                        width: tileGrid.tileWidth
                        s: root.s
                        icon: "coffee"
                        label: I18n.tr("Keep awake")
                        sub: Toggles.keepAwake ? I18n.tr("On") + root.awakeFor() : I18n.tr("Off")
                        on: Toggles.keepAwake
                        onToggled: Toggles.toggleCaffeine()
                    }
                    Classic.ClassicTile {
                        width: tileGrid.tileWidth
                        s: root.s
                        icon: "do_not_disturb_on"
                        label: I18n.tr("Do not disturb")
                        sub: Toggles.dnd ? I18n.tr("On") : I18n.tr("Off")
                        on: Toggles.dnd
                        onToggled: Toggles.toggleDnd()
                    }
                    Classic.ClassicTile {
                        visible: Wm.caps.liveConfigEval === true || Toggles.gameMode
                        width: tileGrid.tileWidth
                        s: root.s
                        icon: "sports_esports"
                        label: I18n.tr("Gaming")
                        available: Toggles.gameMode || Battery.onAc
                        sub: !available ? I18n.tr("Needs AC") : Toggles.gameMode ? I18n.tr("On") : I18n.tr("Off")
                        on: Toggles.gameMode
                        onToggled: Toggles.toggleGame()
                    }
                }

                SectionLabel { width: parent.width; label: I18n.tr("Sound & display") }
                Column {
                    width: parent.width
                    spacing: 4 * root.s
                    Classic.ClassicSlider {
                        width: parent.width
                        s: root.s
                        icon: "speaker"
                        lit: root.overviewActive
                        value: Audio.sink && Audio.sink.audio ? Audio.sink.audio.volume : 0
                        muted: Audio.sink && Audio.sink.audio ? Audio.sink.audio.muted : false
                        valueLabel: !Audio.sink || !Audio.sink.audio ? ""
                            : Audio.sink.audio.muted ? I18n.tr("off") : Math.round(Audio.sink.audio.volume * 100) + "%"
                        peakNode: Audio.sink
                        peakEnabled: root.overviewActive && !!Audio.sink
                        onMoved: value => root.setVolume(value)
                        onCommitted: value => root.setVolume(value)
                        onIconTapped: if (Audio.sink && Audio.sink.audio) Audio.sink.audio.muted = !Audio.sink.audio.muted
                    }
                    Classic.ClassicSlider {
                        width: parent.width
                        s: root.s
                        icon: "mic"
                        lit: root.overviewActive
                        value: Audio.source && Audio.source.audio ? Audio.source.audio.volume : 0
                        muted: Audio.source && Audio.source.audio ? Audio.source.audio.muted : false
                        valueLabel: !Audio.source || !Audio.source.audio ? ""
                            : Audio.source.audio.muted ? I18n.tr("off") : Math.round(Audio.source.audio.volume * 100) + "%"
                        peakNode: Audio.source
                        peakEnabled: root.overviewActive && !!Audio.source
                        onMoved: value => root.setMicVolume(value)
                        onCommitted: value => root.setMicVolume(value)
                        onIconTapped: if (Audio.source && Audio.source.audio) Audio.source.audio.muted = !Audio.source.audio.muted
                    }
                    MixerButton { width: parent.width }
                    Bar.BrightnessControl {
                        width: parent.width
                        s: root.s
                        active: root.overviewActive
                    }
                }

                Menus.MenuMedia {
                    visible: !root.compact && implicitHeight > 0
                    width: parent.width
                    height: visible ? implicitHeight : 0
                    s: root.s
                    open: root.overviewActive && !root.compact
                }

                SectionLabel {
                    visible: !root.compact
                    width: parent.width
                    height: visible ? implicitHeight : 0
                    label: I18n.tr("Calendar")
                }
                Menus.QsCalendarEmbed {
                    visible: !root.compact
                    width: parent.width
                    height: visible ? implicitHeight : 0
                    s: root.s
                    open: root.overviewActive && !root.compact
                }

                SectionLabel {
                    visible: !root.compact
                    width: parent.width
                    height: visible ? implicitHeight : 0
                    label: I18n.tr("System")
                }
                Components.SysMonitor {
                    visible: !root.compact
                    width: parent.width
                    height: visible ? implicitHeight : 0
                    s: root.s
                    active: root.overviewActive && !root.compact
                }
            }

            Cards.SystemWifiPage {
                visible: root.detailPage === "wifi"
                width: parent.width
                implicitHeight: childrenRect.height
                height: visible ? implicitHeight : 0
                s: root.s
                active: visible && root.active
                onBackRequested: root.detailPage = "overview"
            }

            Cards.SystemBluetoothPage {
                visible: root.detailPage === "bluetooth"
                width: parent.width
                height: visible ? implicitHeight : 0
                s: root.s
                active: visible && root.active
                onBackRequested: root.detailPage = "overview"
            }

            Cards.SystemAudioPage {
                visible: root.detailPage === "audio"
                width: parent.width
                height: visible ? implicitHeight : 0
                s: root.s
                active: visible && root.active
                onBackRequested: root.detailPage = "overview"
            }
        }
    }
}
