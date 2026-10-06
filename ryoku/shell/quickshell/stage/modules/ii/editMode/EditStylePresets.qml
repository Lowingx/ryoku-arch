import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import stage
import stage.services
import stage.modules.common
import stage.modules.common.widgets
import stage.modules.common.functions

/**
 * Presets at the top of the Style catalogue. The standalone island keeps its
 * original preset script and store. Under Ryoku, that script is not shipped:
 * the editor keeps a small store beside stage-editor.json and records only the
 * settings the mounted desktop actually owns — wallpaper, light/dark mode and
 * matugen scheme.
 *
 * Applying a Ryoku preset goes back through the same wallpaper and settings
 * seam as the controls below. Nothing copies or replaces Ryoku's live stores,
 * and a saved look can be renamed or removed without leaving the editor.
 */
ColumnLayout {
    id: root

    // The name field needs the keyboard, and on this surface the keyboard is
    // held only on request (see EditModeDrawer's search field).
    signal fieldFocusRequested(Item field)
    signal fieldFocusReleased()

    spacing: 3

    property var presets: []
    property bool saving: false
    property string renamingPreset: ""
    property bool ryokuStoreReady: false
    property bool ryokuApplying: false
    property string ryokuApplyError: ""
    property var applyQueue: []
    property var ryokuSettings: ({})
    readonly property bool ryokuMounted: Config.widgetProvider !== null
    readonly property string presetsScript: `${Directories.scriptPath}/presets.sh`
    readonly property string ryokuPresetsPath: `${Directories.shellConfig}/style-presets.json`
    readonly property string ryokuSettingsPath: `${Directories.config}/ryoku/shell.json`
    readonly property string activePreset: root.ryokuMounted
        ? root.matchingRyokuPreset() : PresetStore.activePreset

    function cleanName(text) {
        return String(text ?? "").replace(/[\/\\"]/g, "").trim();
    }
    function currentDarkMode() {
        const mode = String(root.ryokuSettings?.theme?.matugen?.mode ?? "").toLowerCase();
        return mode === "dark" || mode === "light"
            ? mode === "dark" : Appearance.m3colors.darkmode;
    }

    function currentSchemeType() {
        const stored = String(root.ryokuSettings?.theme?.matugen?.scheme_type ?? "");
        if (stored !== "")
            return "scheme-" + stored.replace(/([a-z0-9])([A-Z])/g, "$1-$2")
                .replace(/_/g, "-").toLowerCase();
        return String(Config.options.appearance.palette.type ?? "scheme-auto");
    }


    function matchingRyokuPreset() {
        const wallpaper = String(Config.wallpaperPath ?? "");
        const dark = root.currentDarkMode();
        const scheme = root.currentSchemeType();
        for (const preset of root.presets) {
            if (String(preset.wallpaper ?? "") === wallpaper
                    && Boolean(preset.darkMode) === dark
                    && String(preset.schemeType ?? "scheme-auto") === scheme)
                return String(preset.name ?? "");
        }
        return "";
    }

    function refresh() {
        if (root.ryokuMounted) {
            ryokuPresetFile.reload();
            return;
        }
        listProc.running = false;
        listProc.running = true;
    }

    function writeRyokuPresets() {
        ryokuPresetFile.setText(JSON.stringify({
            version: 1,
            presets: root.presets
        }, null, 2) + "\n");
    }

    function save() {
        const name = root.cleanName(nameField.text);
        if (name === "")
            return;
        if (root.ryokuMounted) {
            const captured = {
                name: name,
                wallpaper: String(Config.wallpaperPath ?? ""),
                darkMode: root.currentDarkMode(),
                schemeType: root.currentSchemeType()
            };
            const updated = Array.from(root.presets);
            const index = updated.findIndex(preset => String(preset.name ?? "") === name);
            if (index >= 0)
                updated[index] = captured;
            else
                updated.push(captured);
            root.presets = updated;
            root.writeRyokuPresets();
        } else {
            Quickshell.execDetached([root.presetsScript, "save", name]);
            refreshTimer.restart();
        }
        nameField.text = "";
        root.saving = false;
        root.fieldFocusReleased();
    }

    function beginRename(name) {
        root.saving = false;
        nameField.text = "";
        root.renamingPreset = name;
        renameField.text = name;
        root.fieldFocusRequested(renameField);
    }

    function commitRename() {
        const oldName = root.renamingPreset;
        const newName = root.cleanName(renameField.text);
        if (oldName === "" || newName === "")
            return;
        const updated = Array.from(root.presets);
        if (updated.some(preset => String(preset.name ?? "") === newName
                && String(preset.name ?? "") !== oldName))
            return;
        const index = updated.findIndex(preset => String(preset.name ?? "") === oldName);
        if (index < 0)
            return;
        updated[index] = Object.assign({}, updated[index], { name: newName });
        root.presets = updated;
        root.renamingPreset = "";
        renameField.text = "";
        root.fieldFocusReleased();
        root.writeRyokuPresets();
    }

    function deletePreset(name) {
        root.presets = root.presets.filter(preset => String(preset.name ?? "") !== name);
        if (root.renamingPreset === name) {
            root.renamingPreset = "";
            renameField.text = "";
            root.fieldFocusReleased();
        }
        root.writeRyokuPresets();
    }

    function applyPreset(name) {
        if (root.activePreset === name || root.ryokuApplying
                || (!root.ryokuMounted && PresetStore.busy))
            return;
        if (!root.ryokuMounted) {
            PresetStore.applyPreset(name);
            return;
        }
        const preset = root.presets.find(entry => String(entry.name ?? "") === name);
        if (!preset)
            return;

        Config.options.appearance.palette.type = String(preset.schemeType ?? "scheme-auto");
        Config.saveOptionsNow();

        const helper = Directories.wallpaperSwitchScriptPath;
        const commands = [];
        const wallpaper = String(preset.wallpaper ?? "");
        const screen = String(Config.widgetProvider?.monitor ?? "");
        if (wallpaper !== "") {
            const wallpaperCommand = [helper, "--image", wallpaper];
            if (screen !== "")
                wallpaperCommand.push("--screen", screen);
            commands.push(wallpaperCommand);
        }
        commands.push([helper, "--mode", preset.darkMode ? "dark" : "light", "--noswitch"]);
        commands.push([helper, "--noswitch", "--type",
            String(preset.schemeType ?? "scheme-auto")]);

        root.ryokuApplyError = "";
        root.ryokuApplying = true;
        root.applyQueue = commands;
        root.runNextApplyCommand();
    }

    function runNextApplyCommand() {
        if (root.applyQueue.length === 0) {
            root.ryokuApplying = false;
            return;
        }
        ryokuApplyProc.command = root.applyQueue[0];
        root.applyQueue = root.applyQueue.slice(1);
        ryokuApplyProc.running = true;
    }

    Component.onCompleted: {
        if (root.ryokuMounted) {
            Quickshell.execDetached(["mkdir", "-p", Directories.shellConfig]);
            ryokuPresetFile.reload();
        } else {
            PresetStore.ensureLoaded();
            root.refresh();
        }
    }

    Connections {
        target: PresetStore
        enabled: !root.ryokuMounted
        function onPresetFilesChanged() {
            refreshTimer.restart();
        }
        function onApplyFinished(name, ok) {
            refreshTimer.restart();
        }
        function onRevertFinished(ok) {
            refreshTimer.restart();
        }
    }

    Timer {
        id: refreshTimer
        interval: 900
        repeat: false
        onTriggered: root.refresh()
    }
    FileView {
        id: ryokuSettingsFile
        path: root.ryokuMounted ? root.ryokuSettingsPath : ""
        watchChanges: root.ryokuMounted
        printErrors: false
        onLoaded: {
            try {
                root.ryokuSettings = JSON.parse(ryokuSettingsFile.text() || "{}");
            } catch (error) {
                root.ryokuSettings = ({});
            }
        }
        onLoadFailed: root.ryokuSettings = ({})
    }

    FileView {
        id: ryokuPresetFile
        path: root.ryokuMounted ? root.ryokuPresetsPath : ""
        watchChanges: root.ryokuMounted
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const document = JSON.parse(ryokuPresetFile.text() || "{}");
                root.presets = Array.isArray(document) ? document
                    : Array.isArray(document.presets) ? document.presets : [];
                root.ryokuStoreReady = true;
            } catch (error) {
                root.presets = [];
                root.ryokuStoreReady = true;
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.presets = [];
                root.ryokuStoreReady = true;
            }
        }
    }

    Process {
        id: ryokuApplyProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.applyQueue = [];
                root.ryokuApplying = false;
                root.ryokuApplyError = Translation.tr("The preset could not be applied.");
                return;
            }
            root.runNextApplyCommand();
        }
    }


    Process {
        id: listProc
        command: [root.presetsScript, "list"]
        property var collected: []
        onRunningChanged: {
            if (listProc.running)
                listProc.collected = [];
        }
        stdout: SplitParser {
            onRead: data => {
                // One JSON object per line - and a chunk may carry several
                // lines at once, so the payload is split before it is parsed.
                for (const line of String(data).split("\n")) {
                    const text = line.trim();
                    if (text === "")
                        continue;
                    try {
                        listProc.collected.push(JSON.parse(text));
                    } catch (e) {
                        console.log("[EditStylePresets] bad preset line:", text);
                    }
                }
            }
        }
        onExited: root.presets = listProc.collected
    }

    EditPanelSectionLabel {
        text: Translation.tr("Presets")
    }

    // ── Save ─────────────────────────────────────────────────────────────────
    EditPanelRow {
        Layout.fillWidth: true
        first: true
        last: !root.saving
        symbol: "save"
        title: Translation.tr("Save the current look")
        subtitle: root.ryokuMounted
            ? Translation.tr("Wallpaper, theme and colour scheme")
            : Translation.tr("Layout, wallpaper, colours and settings, as a preset")
        trailingKind: root.saving ? "none" : "add"
        selected: root.saving
        onActivated: {
            root.saving = !root.saving;
            if (root.saving) {
                root.renamingPreset = "";
                renameField.text = "";
                root.fieldFocusRequested(nameField);
            } else {
                root.fieldFocusReleased();
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.saving
        implicitHeight: 52
        color: Appearance.colors.colLayer1
        bottomLeftRadius: Appearance.rounding.normal
        bottomRightRadius: Appearance.rounding.normal

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            ToolbarTextField {
                id: nameField
                Layout.fillWidth: true
                Layout.fillHeight: true
                colBackground: Appearance.colors.colLayer2
                placeholderText: Translation.tr("Preset name")
                onPressed: root.fieldFocusRequested(nameField)
                onAccepted: root.save()
                Keys.onEscapePressed: event => {
                    if (nameField.text !== "") {
                        nameField.text = "";
                        return;
                    }
                    root.saving = false;
                    root.fieldFocusReleased();
                    event.accepted = true;
                }
            }

            RippleButton {
                Layout.fillHeight: true
                implicitWidth: 44
                buttonRadius: Appearance.rounding.small
                enabled: root.cleanName(nameField.text) !== ""
                colBackground: Appearance.colors.colSecondary
                colBackgroundHover: Appearance.colors.colSecondaryHover
                colRipple: Appearance.colors.colSecondaryActive
                onClicked: root.save()
                contentItem: MaterialSymbol {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "check"
                    iconSize: 20
                    color: Appearance.colors.colOnSecondary
                }
            }
        }
    }

    // ── The saved looks ──────────────────────────────────────────────────────
    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.topMargin: 6
        visible: root.presets.length === 0
            && (root.ryokuMounted ? root.ryokuStoreReady : !listProc.running)
        text: Translation.tr("Nothing saved yet.")
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colOnSurfaceVariant
    }

    Item {
        id: stripContainer
        Layout.fillWidth: true
        Layout.topMargin: 6
        implicitHeight: strip.implicitHeight
        visible: root.presets.length > 0

        ListView {
            id: strip
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: 10
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.presets

            readonly property real cardWidth: Math.min(160, Math.max(132, Math.floor((width - spacing) / 2)))
            readonly property real cardHeight: cardWidth * 0.8
            implicitHeight: cardHeight

            delegate: Rectangle {
                    id: presetItem
                    required property var modelData
                    width: strip.cardWidth
                    height: strip.cardHeight
                    radius: Appearance.rounding.small
                    color: presetItem.active
                        ? Appearance.colors.colSecondary : Appearance.colors.colSurfaceContainerLow
                    border.width: 1
                    border.color: presetItem.active ? Appearance.colors.colSecondary
                        : Appearance.colors.colOutline
                    opacity: presetBusy ? 0.5 : 1
                    scale: presetButton.down ? 0.96 : 1

                    readonly property string presetName: String(modelData.name ?? "")
                    readonly property string wallpaper: String(modelData.wallpaper ?? "")
                    readonly property bool active: root.activePreset === presetItem.presetName
                    readonly property bool presetBusy: root.ryokuMounted
                        ? root.ryokuApplying : PresetStore.busyFor(presetItem.presetName)
                    readonly property bool tooNew: !root.ryokuMounted
                        && Number(modelData.configVersion ?? 0) > 0
                        && Number(modelData.configVersion) > Config.currentConfigVersion

                    Behavior on scale {
                        enabled: !Appearance.reducedMotion
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(presetItem)
                    }

                    // The whole card is the single apply action. Keeping the
                    // real RippleButton above the image gives the pointer a
                    // hand cursor on every hover, including over the artwork.
                    RippleButton {
                        id: presetButton
                        anchors.fill: parent
                        enabled: !presetItem.active && !presetItem.presetBusy
                            && (root.ryokuMounted || !PresetStore.busy)
                        hoverEnabled: true
                        pointingHandCursor: true
                        buttonRadius: Appearance.rounding.small
                        borderWidth: 0
                        colBackground: "transparent"
                        colBackgroundHover: "transparent"
                        colRipple: Appearance.withAlpha(Appearance.m3colors.m3onSurface, 0.16)
                        onClicked: root.applyPreset(presetItem.presetName)

                        StyledToolTip {
                            text: presetItem.active
                                ? Translation.tr("Active preset") : Translation.tr("Apply preset")
                        }
                    }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        StyledImage {
                            id: previewImage
                            anchors.fill: parent
                            sourceSize: Qt.size(400, 400)
                            source: presetItem.wallpaper !== ""
                                ? presetItem.wallpaper
                                : `${Directories.assetsPath}/images/default_wallpaper.png`
                            fillMode: Image.PreserveAspectCrop
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: previewImage.width
                                    height: previewImage.height
                                    radius: Appearance.rounding.small
                                }
                            }
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            visible: presetItem.wallpaper === ""
                            text: "style"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 6
                            visible: presetItem.tooNew
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colErrorContainer

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "system_update_alt"
                                iconSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnErrorContainer
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 6
                            visible: presetItem.active
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colSecondary

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "check"
                                iconSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnSecondary
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 30

                        StyledText {
                            anchors.left: parent.left
                            anchors.right: presetActions.visible ? presetActions.left : parent.right
                            anchors.rightMargin: presetActions.visible ? 4 : 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: presetItem.presetName
                            color: presetItem.active
                                ? Appearance.colors.colOnSecondary : Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: presetItem.active ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        Row {
                            id: presetActions
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            visible: root.ryokuMounted

                            RippleButton {
                                implicitWidth: 24
                                implicitHeight: 24
                                buttonRadius: Appearance.rounding.small
                                borderWidth: 0
                                colBackground: "transparent"
                                colBackgroundHover: presetItem.active
                                    ? Appearance.withAlpha(Appearance.m3colors.m3surface, 0.12)
                                    : Appearance.colors.colLayer1Hover
                                onClicked: root.beginRename(presetItem.presetName)
                                contentItem: MaterialSymbol {
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: "edit"
                                    iconSize: 15
                                    color: presetItem.active
                                        ? Appearance.colors.colOnSecondary : Appearance.colors.colOnSurface
                                }
                            }

                            RippleButton {
                                implicitWidth: 24
                                implicitHeight: 24
                                buttonRadius: Appearance.rounding.small
                                borderWidth: 0
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colErrorContainer
                                onClicked: root.deletePreset(presetItem.presetName)
                                contentItem: MaterialSymbol {
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: "delete"
                                    iconSize: 15
                                    color: presetItem.active
                                        ? Appearance.colors.colOnSecondary : Appearance.colors.colError
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 6
        visible: root.ryokuMounted && root.renamingPreset !== ""
        implicitHeight: 52
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: Appearance.colors.colOutline

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            ToolbarTextField {
                id: renameField
                Layout.fillWidth: true
                Layout.fillHeight: true
                colBackground: Appearance.colors.colLayer2
                placeholderText: Translation.tr("Preset name")
                onPressed: root.fieldFocusRequested(renameField)
                onAccepted: root.commitRename()
                Keys.onEscapePressed: event => {
                    root.renamingPreset = "";
                    renameField.text = "";
                    root.fieldFocusReleased();
                    event.accepted = true;
                }
            }

            RippleButton {
                Layout.fillHeight: true
                implicitWidth: 40
                buttonRadius: Appearance.rounding.small
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: {
                    root.renamingPreset = "";
                    renameField.text = "";
                    root.fieldFocusReleased();
                }
                contentItem: MaterialSymbol {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "close"
                    iconSize: 18
                    color: Appearance.colors.colOnSurface
                }
            }

            RippleButton {
                Layout.fillHeight: true
                implicitWidth: 40
                buttonRadius: Appearance.rounding.small
                enabled: root.cleanName(renameField.text) !== ""
                colBackground: Appearance.colors.colSecondary
                colBackgroundHover: Appearance.colors.colSecondaryHover
                colRipple: Appearance.colors.colSecondaryActive
                onClicked: root.commitRename()
                contentItem: MaterialSymbol {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "check"
                    iconSize: 18
                    color: Appearance.colors.colOnSecondary
                }
            }
        }
    }

    EditPanelNotice {
        Layout.fillWidth: true
        Layout.topMargin: 6
        visible: root.ryokuApplyError !== ""
        symbol: "error"
        text: root.ryokuApplyError
    }

    // ── Undo, and the store ──────────────────────────────────────────────────
    EditPanelRow {
        Layout.fillWidth: true
        Layout.topMargin: 6
        visible: !root.ryokuMounted && root.activePreset !== ""
        first: true
        last: false
        rowEnabled: !PresetStore.busy
        symbol: "history"
        title: Translation.tr("Undo preset")
        subtitle: Translation.tr("Back to the settings from before %1").arg(root.activePreset)
        trailingKind: "none"
        onActivated: PresetStore.revert()
    }

    EditPanelRow {
        Layout.fillWidth: true
        Layout.topMargin: root.activePreset !== "" ? 0 : 6
        first: root.activePreset === ""
        last: true
        visible: !root.ryokuMounted
        symbol: "storefront"
        title: Translation.tr("Browse the store")
        subtitle: Translation.tr("Leaves Edit Mode")
        valueText: PresetStore.updateCount > 0
            ? Translation.tr("%1 updates").arg(String(PresetStore.updateCount)) : ""
        trailingKind: "chevron"
        onActivated: GlobalStates.openSettingsFromEditMode("presets", "store")
    }
}
