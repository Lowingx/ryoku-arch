pragma ComponentBehavior: Bound
import QtQuick
import "../desktop"
import "../desktop/Singletons"
import Ryoku.Ui.Singletons
import stage.modules.common as StageIsland
import "Singletons" as StageCfg

// The depth stage, as a sectioned options column for the Stage Editor's Depth
// catalogue: the cut (plain, depth or parallax, the quality and its model,
// re-cut and clear), the layers the cut produced, how they are drawn, how
// they move, and which widgets rise in front of them. Every write goes
// through the same StageBackend verbs and stage Config setters the Hub's
// Desktop Scene page uses, so the two never disagree about what is stored;
// the Hub keeps adding a layer from a picture, which needs its file picker.
Column {
    id: opts

    width: parent ? parent.width : 0
    spacing: Theme.s1

    readonly property var backend: StageCfg.StageBackend
    readonly property var cfg: StageCfg.Config
    readonly property var provider: StageIsland.Config.widgetProvider
    // The wall this desktop shows: the daemon's verbs act on the current one.
    readonly property string wall: opts.provider && opts.provider.wallpaperPath
        ? opts.provider.wallpaperPath : opts.backend.current
    readonly property string effect: opts.backend.effectFor(opts.wall)
    readonly property bool parallax: opts.effect === "parallax"
    readonly property int layerCount: opts.backend.layerCountFor(opts.wall)
    readonly property var qualityModel: opts.backend.modelForQuality(opts.cfg.quality)
    readonly property bool qualityReady: opts.backend.qualityInstalled(opts.cfg.quality)
    // Clear deletes the cut-outs: the first press arms it, the second clears.
    property bool clearArmed: false

    function cap(s) { return (s && s.length > 0) ? s.charAt(0).toUpperCase() + s.slice(1) : s; }
    function pct(v) { return Math.round(v * 100) + "%"; }

    Component.onCompleted: if (!opts.backend.checked)
        opts.backend.recheck()

    // ── Cut ─────────────────────────────────────────────────────────────
    MenuSection { label: I18n.tr("Cut"); gloss: "切抜" }
    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        leftPadding: 13
        rightPadding: 13
        text: opts.backend.busy
            ? I18n.tr("Building layers · %1%").arg(opts.backend.percent)
            : opts.backend.notice !== "" && opts.effect !== "off"
                ? I18n.tr("The scene could not be cut: %1").arg(opts.backend.notice)
            : opts.effect === "off"
                ? I18n.tr("Plain: the wallpaper is drawn flat behind the widgets.")
            : opts.layerCount > 0
                ? I18n.tr("%1 layers cut from this wallpaper.").arg(opts.layerCount)
                : I18n.tr("This wallpaper has not been cut yet.")
        color: opts.backend.notice !== "" && !opts.backend.busy && opts.effect !== "off" ? Tokens.alert : Theme.inkDim
        font.family: Theme.font
        font.pixelSize: 11
    }
    Column {
        width: parent.width
        spacing: 4

        Flow {
            width: parent.width
            spacing: 4
            Repeater {
                model: [
                    { key: "off", label: I18n.tr("Plain") },
                    { key: "depth", label: I18n.tr("Depth") },
                    { key: "parallax", label: I18n.tr("Parallax") }
                ]
                delegate: MenuChip {
                    required property var modelData
                    minWidth: 64
                    width: Math.min(implicitWidth, parent.width)
                    label: modelData.label
                    selected: opts.effect === modelData.key
                    onClicked: opts.backend.setEffect(modelData.key)
                }
            }
        }

        Flow {
            width: parent.width
            spacing: 4
            Repeater {
                model: [
                    { key: "draft", label: I18n.tr("Draft") },
                    { key: "standard", label: I18n.tr("Standard") },
                    { key: "fine", label: I18n.tr("Fine") }
                ]
                delegate: MenuChip {
                    required property var modelData
                    minWidth: 64
                    width: Math.min(implicitWidth, parent.width)
                    label: modelData.label
                    selected: opts.cfg.quality === modelData.key
                    onClicked: opts.cfg.setQuality(modelData.key)
                }
            }
        }
    }
    MenuRow {
        visible: !opts.qualityReady
        label: opts.backend.installing ? I18n.tr("Downloading the cut model…") : I18n.tr("Download the model")
        value: opts.qualityModel ? (opts.qualityModel.size || "") : ""
        closeOnTrigger: false
        onTriggered: if (opts.qualityModel && !opts.backend.installing)
            opts.backend.install(opts.qualityModel.id)
    }
    MenuRow {
        visible: opts.backend.busy
        label: I18n.tr("Stop cutting")
        closeOnTrigger: false
        onTriggered: opts.backend.cancel()
    }
    MenuRow {
        visible: !opts.backend.busy && opts.effect !== "off" && opts.qualityReady
        label: I18n.tr("Re-cut this wallpaper")
        closeOnTrigger: false
        onTriggered: opts.backend.refresh()
    }
    MenuRow {
        visible: !opts.backend.busy && opts.layerCount > 0
        label: opts.clearArmed ? I18n.tr("Press again to delete the cut-outs") : I18n.tr("Clear cut-outs")
        on: opts.clearArmed
        closeOnTrigger: false
        onTriggered: {
            if (!opts.clearArmed) {
                opts.clearArmed = true;
                disarm.restart();
                return;
            }
            opts.clearArmed = false;
            opts.backend.clear();
        }
        Timer {
            id: disarm
            interval: 4000
            onTriggered: opts.clearArmed = false
        }
    }

    // ── Layers ──────────────────────────────────────────────────────────
    MenuSection { label: I18n.tr("Layers"); gloss: "層" }
    Text {
        visible: opts.layerCount === 0
        width: parent.width
        leftPadding: 13
        rightPadding: 13
        text: I18n.tr("Cut the wallpaper to create editable layers.")
        color: Theme.inkDim
        elide: Text.ElideRight
        maximumLineCount: 1
        font.family: Theme.font
        font.pixelSize: 11
    }
    Repeater {
        model: opts.layerCount
        delegate: Column {
            id: layer
            required property int index
            width: opts.width
            spacing: 4

            MenuRow {
                label: opts.backend.layerLabel(opts.wall, layer.index)
                value: opts.backend.layerEnabled(opts.wall, layer.index) ? I18n.tr("Shown") : I18n.tr("Hidden")
                on: opts.backend.layerEnabled(opts.wall, layer.index)
                closeOnTrigger: false
                onTriggered: opts.backend.setLayer(layer.index,
                    { enabled: !opts.backend.layerEnabled(opts.wall, layer.index) })
            }
            Flow {
                width: parent.width
                spacing: 4
                MenuChip {
                    minWidth: 64
                    width: Math.min(implicitWidth, parent.width)
                    label: I18n.tr("Behind")
                    selected: !opts.backend.layerFront(opts.wall, layer.index)
                    onClicked: opts.backend.setLayerFront(layer.index, false)
                }
                MenuChip {
                    minWidth: 64
                    width: Math.min(implicitWidth, parent.width)
                    label: I18n.tr("In front")
                    selected: opts.backend.layerFront(opts.wall, layer.index)
                    onClicked: opts.backend.setLayerFront(layer.index, true)
                }
                MenuChip {
                    visible: layer.index > 0
                    minWidth: 64
                    width: Math.min(implicitWidth, parent.width)
                    label: I18n.tr("Remove")
                    onClicked: opts.backend.removeLayer(layer.index)
                }
            }
            MenuSlider {
                id: depthSld
                enabled: opts.parallax
                opacity: enabled ? 1 : 0.4
                label: I18n.tr("Distance")
                from: 0; to: 1
                value: opts.backend.layerDepth(opts.wall, layer.index)
                valueText: opts.pct(depthSld.value)
                onMoved: (v) => opts.backend.setLayerDepth(layer.index, v)
                onReleased: (v) => opts.backend.setLayerDepth(layer.index, v)
            }
        }
    }

    // ── Look ────────────────────────────────────────────────────────────
    MenuSection { label: I18n.tr("Look"); gloss: "質感" }
    MenuSlider {
        id: edgeSld
        label: I18n.tr("Edge softness")
        from: 0; to: 1
        value: opts.cfg.edge
        valueText: opts.pct(edgeSld.value)
        onMoved: (v) => opts.cfg.setEdge(v)
        onReleased: (v) => opts.cfg.setEdge(v)
    }
    MenuSlider {
        id: shadowSld
        label: I18n.tr("Shadow")
        from: 0; to: 1
        value: opts.cfg.shadow
        valueText: opts.pct(shadowSld.value)
        onMoved: (v) => opts.cfg.setShadow(v)
        onReleased: (v) => opts.cfg.setShadow(v)
    }
    MenuSlider {
        id: angleSld
        label: I18n.tr("Shadow direction")
        from: 0; to: 359; step: 1; decimals: 0
        value: opts.cfg.shadowAngle
        valueText: Math.round(angleSld.value) + "\u00b0"
        onMoved: (v) => opts.cfg.setShadowAngle(v)
        onReleased: (v) => opts.cfg.setShadowAngle(v)
    }
    MenuRow {
        label: I18n.tr("Reset look and parallax")
        closeOnTrigger: false
        onTriggered: opts.cfg.resetLook()
    }

    // ── Parallax ────────────────────────────────────────────────────────
    MenuSection { label: I18n.tr("Parallax"); gloss: "視差" }
    MenuRow {
        label: I18n.tr("Use Parallax")
        value: opts.parallax ? I18n.tr("On") : I18n.tr("Off")
        on: opts.parallax
        closeOnTrigger: false
        onTriggered: if (!opts.parallax)
            opts.backend.setEffect("parallax")
    }
    Flow {
        enabled: opts.parallax
        opacity: enabled ? 1 : 0.4
        width: parent.width
        spacing: 4
        Repeater {
            model: ["subtle", "normal", "strong"]
            delegate: MenuChip {
                required property string modelData
                minWidth: 64
                width: Math.min(implicitWidth, parent.width)
                label: opts.cap(modelData)
                selected: opts.cfg.amount === modelData
                onClicked: opts.cfg.setAmount(modelData)
            }
        }
    }
    Flow {
        enabled: opts.parallax
        opacity: enabled ? 1 : 0.4
        width: parent.width
        spacing: 4
        Repeater {
            model: [
                { key: "none", label: I18n.tr("Still") },
                { key: "float", label: I18n.tr("Float") },
                { key: "breathe", label: I18n.tr("Breathe") },
                { key: "sway", label: I18n.tr("Sway") }
            ]
            delegate: MenuChip {
                required property var modelData
                minWidth: 64
                width: Math.min(implicitWidth, parent.width)
                label: modelData.label
                selected: opts.cfg.idle === modelData.key
                onClicked: opts.cfg.setIdle(modelData.key)
            }
        }
    }
    MenuSlider {
        id: speedSld
        enabled: opts.parallax && opts.cfg.idle !== "none"
        opacity: enabled ? 1 : 0.4
        label: I18n.tr("Idle speed")
        from: 0.25; to: 2
        value: opts.cfg.speed
        valueText: speedSld.value.toFixed(2) + "\u00d7"
        onMoved: (v) => opts.cfg.setSpeed(v)
        onReleased: (v) => opts.cfg.setSpeed(v)
    }
    MenuRow {
        enabled: opts.parallax
        opacity: enabled ? 1 : 0.4
        label: I18n.tr("Move with the music")
        value: opts.cfg.music ? I18n.tr("On") : I18n.tr("Off")
        on: opts.cfg.music
        closeOnTrigger: false
        onTriggered: opts.cfg.setMusic(!opts.cfg.music)
    }
    MenuSlider {
        id: musicSld
        enabled: opts.parallax && opts.cfg.music
        opacity: enabled ? 1 : 0.4
        label: I18n.tr("Music intensity")
        from: 0; to: 1
        value: opts.cfg.musicLevel
        valueText: opts.pct(musicSld.value)
        onMoved: (v) => opts.cfg.setMusicLevel(v)
        onReleased: (v) => opts.cfg.setMusicLevel(v)
    }
    MenuRow {
        enabled: opts.parallax
        opacity: enabled ? 1 : 0.4
        label: I18n.tr("Follow the pointer")
        value: opts.cfg.followMouse ? I18n.tr("On") : I18n.tr("Off")
        on: opts.cfg.followMouse
        closeOnTrigger: false
        onTriggered: opts.cfg.setMouse(!opts.cfg.followMouse)
    }
    MenuSlider {
        id: sensSld
        enabled: opts.parallax && opts.cfg.followMouse
        opacity: enabled ? 1 : 0.4
        label: I18n.tr("Sensitivity")
        from: 0; to: 2
        value: opts.cfg.sensitivity
        valueText: opts.pct(sensSld.value)
        onMoved: (v) => opts.cfg.setSensitivity(v)
        onReleased: (v) => opts.cfg.setSensitivity(v)
    }
    MenuSlider {
        id: rangeSld
        enabled: opts.parallax && opts.cfg.followMouse
        opacity: enabled ? 1 : 0.4
        label: I18n.tr("Range")
        from: 0; to: 2
        value: opts.cfg.range
        valueText: opts.pct(rangeSld.value)
        onMoved: (v) => opts.cfg.setRange(v)
        onReleased: (v) => opts.cfg.setRange(v)
    }
    MenuSlider {
        id: driftSld
        enabled: opts.parallax && opts.cfg.followMouse
        opacity: enabled ? 1 : 0.4
        label: I18n.tr("Backdrop drift")
        from: 0; to: 1
        value: opts.cfg.backdrop
        valueText: opts.pct(driftSld.value)
        onMoved: (v) => opts.cfg.setBackdrop(v)
        onReleased: (v) => opts.cfg.setBackdrop(v)
    }

    // ── In front ────────────────────────────────────────────────────────
    // Which placed widgets rise above the in-front cut-outs: the same lift a
    // widget's own Depth row toggles, for all of them in one list.
    MenuSection { visible: opts.layerCount > 0; label: I18n.tr("In front"); gloss: "前面" }
    Repeater {
        model: opts.layerCount > 0 && opts.provider ? opts.provider.rows.filter(r => r.enabled) : []
        delegate: MenuRow {
            id: liftRow
            required property var modelData
            // The lift list keys a plugin tile by its plugin id, not the
            // catalogue's "plugin:" instance id (WidgetMenu/PluginWidgetMenu).
            readonly property string liftId: modelData.id.indexOf("plugin:") === 0 ? modelData.id.slice(7) : modelData.id
            label: modelData.label
            value: opts.cfg.isFront(liftRow.liftId) ? I18n.tr("In front") : I18n.tr("Behind")
            on: opts.cfg.isFront(liftRow.liftId)
            closeOnTrigger: false
            onTriggered: opts.cfg.setFront(liftRow.liftId, !opts.cfg.isFront(liftRow.liftId))
        }
    }
}
