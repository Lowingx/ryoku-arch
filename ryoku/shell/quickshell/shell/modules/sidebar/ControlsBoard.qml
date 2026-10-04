pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Ryoku.Blobs
import Ryoku.Ui.Singletons
import shell.services
import "cards" as Cards

Item {
    id: root
    required property real s
    required property var screen
    required property bool active
    property string page: "controls"
    signal requestClose()
    readonly property string currentPage: ["wifi", "bluetooth", "audio", "capture"].indexOf(page) >= 0 ? page : "controls"
    readonly property bool overviewActive: active && currentPage === "controls"
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevices: Bluetooth.devices ? Bluetooth.devices.values.filter(device => device && device.connected) : []
    readonly property string wifiDetail: !Network.wifiPresent ? I18n.tr("No Wi-Fi adapter")
        : !Network.wifiRadio ? I18n.tr("Radio off") : Network.activeSsid || (Network.wifiConnectivity === "Connecting" ? I18n.tr("Connecting…") : I18n.tr("Not connected"))
    readonly property string bluetoothDetail: !adapter ? I18n.tr("No adapter") : !adapter.enabled ? I18n.tr("Radio off")
        : connectedDevices.length === 1 ? BtLink.label(connectedDevices[0]) : connectedDevices.length > 1 ? I18n.tr("%1 connected").arg(connectedDevices.length) : I18n.tr("No devices connected")
    readonly property string ddcBus: {
        const output = root.screen ? root.screen.name : Wm.focusedOutput;
        return (Devices.ddcMonitors || []).find(display => display.label === output)?.bus || "";
    }
    property real externalBrightness: -1
    property real pendingBrightness: -1
    readonly property bool brightnessAvailable: Devices.backlightAvailable || (ddcBus !== "" && externalBrightness >= 0)
    readonly property real brightnessValue: pendingBrightness >= 0 ? pendingBrightness
        : Math.max(0, Devices.backlightAvailable ? Devices.backlightPct / 100 : externalBrightness / 100)
    implicitHeight: currentPage === "controls" ? overview.implicitHeight : 380 * s

    function showPage(value): void { SidebarState.selectTab("left", root.screen, value); }
    function syncProbes(): void {
        if (root.overviewActive) {
            Devices.startProbes(root);
            root.readExternalBrightness();
        } else {
            Devices.stopProbes(root);
            externalRead.running = false;
        }
    }
    function readExternalBrightness(): void {
        if (!root.overviewActive || Devices.backlightAvailable || root.ddcBus === "" || externalRead.running)
            return;
        externalRead.command = ["timeout", "3", "ddcutil", "getvcp", "10", "--brief", "--bus", root.ddcBus];
        externalRead.running = true;
    }
    function session(action): void {
        root.requestClose();
        if (action === "lock" || action === "suspend")
            SessionActions.run(action);
        else
            ShellState.askSessionAction(action, root.screen ? root.screen.name : "");
    }
    function writeBrightness(): void {
        if (root.pendingBrightness < 0)
            return;
        const percent = Math.round(root.pendingBrightness * 100);
        if (Devices.backlightAvailable)
            Devices.setBacklight(percent);
        else if (root.ddcBus !== "") {
            Devices.setBrightness(root.ddcBus, percent);
            root.externalBrightness = percent;
        }
        root.pendingBrightness = -1;
    }
    onOverviewActiveChanged: root.syncProbes()
    onDdcBusChanged: { root.externalBrightness = -1; root.readExternalBrightness(); }
    Component.onCompleted: root.syncProbes()
    Component.onDestruction: { Devices.stopProbes(root); root.writeBrightness(); }
    SystemMonitor { id: monitor; active: root.overviewActive }
    Process {
        id: externalRead
        stdout: StdioCollector {
            onStreamFinished: {
                const value = Devices.parseBrightness(text);
                if (root.overviewActive && value >= 0)
                    root.externalBrightness = value;
            }
        }
    }
    Timer { id: brightnessWrite; interval: 90; onTriggered: root.writeBrightness() }

    Column {
        id: overview
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.currentPage === "controls"
        spacing: 10 * root.s
        ControlsHero { width: parent.width; s: root.s; monitor: monitor; active: root.overviewActive; height: implicitHeight }
        Row {
            width: parent.width
            spacing: 10 * root.s
            CornerConnection {
                width: (parent.width - parent.spacing) / 2
                height: 58 * root.s
                s: root.s
                label: I18n.tr("Wi-Fi")
                detail: root.wifiDetail
                glyph: Network.wifiRadio ? "wifi" : "wifi_off"
                connected: Network.activeSsid !== ""
                radioOn: Network.wifiRadio
                available: Network.wifiPresent
                onSelected: root.showPage("wifi")
                onToggleRequested: Toggles.toggleWifi()
            }
            CornerConnection {
                width: (parent.width - parent.spacing) / 2
                height: 58 * root.s
                s: root.s
                label: I18n.tr("Bluetooth")
                detail: root.bluetoothDetail
                glyph: root.adapter && root.adapter.enabled ? "bluetooth" : "bluetooth_disabled"
                connected: root.connectedDevices.length > 0
                radioOn: !!(root.adapter && root.adapter.enabled)
                available: root.adapter !== null
                onSelected: root.showPage("bluetooth")
                onToggleRequested: Toggles.toggleBt()
            }
        }
        Row {
            width: parent.width
            spacing: 18 * root.s
            CornerSlider {
                width: (parent.width - parent.spacing) / 2
                height: 54 * root.s
                s: root.s
                label: I18n.tr("Volume")
                glyph: muted ? "volume_off" : "volume_up"
                enabled: !!(Audio.sink && Audio.sink.audio)
                value: enabled ? Math.min(1, Audio.sink.audio.volume) : 0
                muted: enabled && Audio.sink.audio.muted
                muteEnabled: true
                onAdjusted: value => {
                    Audio.sink.audio.volume = value;
                    if (value > 0) Audio.sink.audio.muted = false;
                }
                onMuteRequested: Audio.sink.audio.muted = !Audio.sink.audio.muted
            }
            CornerSlider {
                width: (parent.width - parent.spacing) / 2
                height: 54 * root.s
                s: root.s
                label: I18n.tr("Brightness")
                glyph: "light_mode"
                enabled: root.brightnessAvailable
                from: 0.01
                value: root.brightnessValue
                onAdjusted: value => { root.pendingBrightness = value; brightnessWrite.restart(); }
            }
        }
        Row {
            width: parent.width
            spacing: 6 * root.s
            readonly property int count: Wm.caps.nightLight === true ? 5 : 4
            readonly property real buttonWidth: (width - spacing * (count - 1)) / count
            CornerButton {
                width: parent.buttonWidth; s: root.s; glyph: "equalizer"; text: I18n.tr("Mixer")
                onClicked: root.showPage("audio")
            }
            CornerButton {
                width: parent.buttonWidth; s: root.s; glyph: "bedtime"; text: I18n.tr("Night light")
                visible: Wm.caps.nightLight === true
                checked: Toggles.nightOn; onClicked: Toggles.toggleNight()
            }
            CornerButton {
                width: parent.buttonWidth; s: root.s; glyph: "coffee"; text: I18n.tr("Keep awake")
                checked: Toggles.keepAwake; onClicked: Toggles.toggleCaffeine()
            }
            CornerButton {
                width: parent.buttonWidth; s: root.s; glyph: "notifications_off"; text: I18n.tr("DND")
                checked: Toggles.dnd; onClicked: Toggles.toggleDnd()
            }
            CornerButton {
                width: parent.buttonWidth; s: root.s; glyph: Toggles.micMuted ? "mic_off" : "mic"; text: I18n.tr("Mic")
                enabled: !!(Audio.source && Audio.source.audio)
                checked: Toggles.micMuted; onClicked: Toggles.toggleMic()
            }
        }
        Rectangle { width: parent.width; height: Tokens.border; color: Tokens.lineSoft }
        Row {
            width: parent.width
            spacing: 6 * root.s
            Repeater {
                model: [
                    { action: "lock", glyph: "lock", label: I18n.tr("Lock") },
                    { action: "suspend", glyph: "dark_mode", label: I18n.tr("Sleep") },
                    { action: "logout", glyph: "logout", label: I18n.tr("Log out") },
                    { action: "reboot", glyph: "restart_alt", label: I18n.tr("Restart") },
                    { action: "shutdown", glyph: "power_settings_new", label: I18n.tr("Power off") }
                ]
                delegate: CornerButton {
                    required property var modelData
                    width: (overview.width - 24 * root.s) / 5
                    s: root.s
                    glyph: modelData.glyph
                    text: modelData.label
                    subtle: true
                    onClicked: root.session(modelData.action)
                }
            }
        }
    }
    QQC.ScrollView {
        id: detailScroll
        anchors.fill: parent
        visible: root.currentPage !== "controls"
        clip: true
        contentWidth: availableWidth
        QQC.ScrollBar.horizontal.policy: QQC.ScrollBar.AlwaysOff
        Loader {
            id: detail
            width: detailScroll.availableWidth
            active: root.currentPage !== "controls"
            sourceComponent: root.currentPage === "wifi" ? wifiPage : root.currentPage === "bluetooth" ? bluetoothPage
                : root.currentPage === "audio" ? audioPage : capturePage
        }
    }
    Component { id: wifiPage; Cards.SystemWifiPage { s: root.s; active: root.active; onBackRequested: root.showPage("controls") } }
    Component { id: bluetoothPage; Cards.SystemBluetoothPage { s: root.s; active: root.active; onBackRequested: root.showPage("controls") } }
    Component { id: audioPage; Cards.SystemAudioPage { s: root.s; active: root.active; onBackRequested: root.showPage("controls") } }
    Component {
        id: capturePage
        Cards.CaptureCard { s: root.s; open: root.active; tabActive: root.active; reveal: 1; compact: true; onRequestClose: root.requestClose() }
    }
}
