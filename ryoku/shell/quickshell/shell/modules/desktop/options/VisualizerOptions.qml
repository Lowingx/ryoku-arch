pragma ComponentBehavior: Bound
import QtQuick
import ".."
import "../Singletons"
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "../../visualizer/Singletons" as VizCfg

// Options for the desktop visualiser, hosted by the Stage Editor's inspector:
// the catalogue and the tuning. The old standalone placement bar folded its
// knobs in here (look, colour, playback, shape, and the edge field's surface);
// the look's box itself is aimed with the grip on the desktop.
//
// Reads come off the active instance (VizCfg.Config.instance, already
// normalised) except the three globals (enabled, fps, adaptive); writes go
// through Config so the active-vs-extra routing stays single-sourced. Rows
// that only mean something for one look family hide rather than dim: the
// inspector slices this panel into tabs, and a dead tab reads worse than a
// missing one.
Column {
    id: opts

    // Set by the inspector loader to the widget scope; unused here (the
    // visualiser keys are fixed) but kept so every options panel shares one API.
    property string widget: ""
    // The look gallery, expanded inline under the Style rows.
    property bool galleryOpen: false

    readonly property var cfg: VizCfg.Config
    readonly property var inst: VizCfg.Config.instance
    readonly property string sid: VizCfg.Config.styleId
    readonly property bool aura: VizCfg.Config.isAura
    readonly property bool shapeSet: ["bars", "split", "dots", "segments", "frame", "radial", "spiral"].indexOf(opts.sid) >= 0
    readonly property bool growSet: ["bars", "split", "dots", "segments", "wave", "ribbon", "curtain", "line"].indexOf(opts.sid) >= 0
    readonly property bool polarSet: ["radial", "orb", "spiral"].indexOf(opts.sid) >= 0
    readonly property bool bloomSet: ["bars", "split", "dots", "segments", "wave", "ribbon", "curtain", "line", "frame", "radial", "orb", "spiral"].indexOf(opts.sid) >= 0
    readonly property bool segSet: opts.sid === "segments"
    readonly property bool reflSet: opts.growSet && opts.inst.grow === "up"

    width: parent ? parent.width : 0
    spacing: Theme.s1

    function cap(s) { return (s && s.length > 0) ? s.charAt(0).toUpperCase() + s.slice(1) : s; }
    function cycle(list, cur) { const i = list.indexOf(cur); return list[(i + 1) % list.length]; }
    function hexOf(c) {
        return "#" + [c.r, c.g, c.b].map(function (x) {
            const s = Math.round(x * 255).toString(16);
            return s.length === 1 ? "0" + s : s;
        }).join("").toUpperCase();
    }
    // Turning a gradient on needs both stops to exist, or it cannot paint: pin
    // the current colour as the base and a lighter twin as the second.
    function ensureStops() {
        if (!opts.cfg.hasCustomColor)
            opts.cfg.setColor(opts.hexOf(Theme.accent));
        if (!opts.cfg.hasColor2)
            opts.cfg.setColor2(opts.hexOf(Qt.lighter(opts.cfg.hasCustomColor
                ? opts.cfg.customColor : Theme.accent, 1.5)));
    }

    // ── Look ───────────────────────────────────────────────────────────
    MenuSection { label: I18n.tr("Look"); gloss: "音波" }
    MenuRow {
        label: I18n.tr("Style")
        value: opts.cap(opts.sid)
        closeOnTrigger: false
        onTriggered: opts.cfg.cycleStyle(1)
    }
    MenuRow {
        label: I18n.tr("Walk back")
        value: opts.cfg.knownStyles.length > 0
            ? opts.cap(opts.cfg.knownStyles[(opts.cfg.knownStyles.indexOf(opts.sid)
                + opts.cfg.knownStyles.length - 1) % opts.cfg.knownStyles.length])
            : ""
        closeOnTrigger: false
        onTriggered: opts.cfg.cycleStyle(-1)
    }
    MenuRow {
        label: I18n.tr("Look gallery")
        value: opts.galleryOpen ? I18n.tr("Close") : I18n.tr("Open")
        closeOnTrigger: false
        onTriggered: opts.galleryOpen = !opts.galleryOpen
    }
    MenuRow {
        label: I18n.tr("Instance")
        value: (opts.cfg.active + 1) + " / " + opts.cfg.count
        closeOnTrigger: false
        onTriggered: opts.cfg.setActive((opts.cfg.active + 1) % opts.cfg.count)
    }
    MenuRow {
        label: I18n.tr("Add instance")
        value: opts.cfg.count < opts.cfg.maxVisualizers ? "" : I18n.tr("At the limit")
        closeOnTrigger: false
        onTriggered: opts.cfg.addVisualizer()
    }
    MenuRow {
        visible: opts.cfg.count > 1
        label: I18n.tr("Remove instance")
        closeOnTrigger: false
        onTriggered: opts.cfg.removeVisualizer(opts.cfg.active)
    }
    // The gallery expands inline under the rows: the sheet is already its own
    // surface, and the same silhouette painter the Hub's catalogue uses draws
    // what the looks look like here and there.
    Rectangle {
        visible: opts.galleryOpen
        width: parent.width
        implicitHeight: gal.implicitHeight + Theme.s4
        radius: Theme.radius
        color: Theme.tileHover
        Gallery {
            id: gal
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            options: VizStyles.styles.map(function (s) {
                return { key: s.key, origin: s.kind, draw: s.key };
            })
            painter: VizStyles
            current: opts.sid
            onChose: key => { opts.cfg.setStyle(key); opts.galleryOpen = false; }
        }
    }
    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        leftPadding: Theme.s3
        rightPadding: Theme.s3
        text: opts.aura ? I18n.tr("The field fills the screen: tune it here.")
            : I18n.tr("Aim the look on the desktop: drag the box to move it, the corner to size it, the dot to turn it, Ctrl+wheel to scale.")
        color: Theme.inkDim
        font.family: Theme.font
        font.pixelSize: Theme.fSmall
    }

    // ── Colour ──────────────────────────────────────────────────────────
    MenuSection { label: I18n.tr("Colour"); gloss: "彩色" }
    MenuRow {
        label: I18n.tr("Gradient")
        value: opts.cfg.gradient ? I18n.tr("On") : I18n.tr("Off")
        on: opts.cfg.gradient
        closeOnTrigger: false
        onTriggered: {
            if (!opts.cfg.gradient)
                opts.ensureStops();
            opts.cfg.setGradient(!opts.cfg.gradient);
        }
    }
    MenuRow {
        visible: opts.cfg.hasCustomColor
        label: I18n.tr("Auto")
        value: I18n.tr("Follow the wallpaper")
        closeOnTrigger: false
        onTriggered: {
            opts.cfg.setGradient(false);
            opts.cfg.clearColor();
        }
    }
    MenuInkPicker {
        id: vizInk
        // The base and gradient stops, plus the field's triad when the field
        // is on: one picker, one surface for every colour the look wears.
        roles: opts.aura ? [
            { key: "color", label: I18n.tr("Base"), fallback: "" },
            { key: "color2", label: I18n.tr("Second"), fallback: "" },
            { key: "aura2", label: I18n.tr("Field 2"), fallback: "#FFFFFF" },
            { key: "aura3", label: I18n.tr("Field 3"), fallback: "#FFFFFF" }
        ] : [
            { key: "color", label: I18n.tr("Base"), fallback: "" },
            { key: "color2", label: I18n.tr("Second"), fallback: "" }
        ]
        readColor: (key, fb) => {
            if (key === "color")
                return opts.cfg.hasCustomColor ? opts.cfg.colorHex : fb;
            if (key === "color2")
                return opts.cfg.hasColor2 ? opts.cfg.color2Hex : fb;
            if (key === "aura2")
                return opts.inst.auraColor2 || fb;
            return opts.inst.auraColor3 || fb;
        }
        writeColor: (key, hex) => {
            if (key === "color")
                opts.cfg.setColor(hex);
            else if (key === "color2")
                opts.cfg.setColor2(hex);
            else if (key === "aura2")
                opts.cfg.poke("auraColor2", hex);
            else
                opts.cfg.poke("auraColor3", hex);
        }
        // Re-seed when the active look changes under the picker, so the square
        // always starts on what the look actually wears.
        Connections {
            target: opts.cfg
            function onActiveChanged() { vizInk.seedFromRole(); }
        }
    }

    // ── Playback ────────────────────────────────────────────────────────
    MenuSection { label: I18n.tr("Playback"); gloss: "再生" }
    MenuRow {
        label: I18n.tr("Idle wave")
        value: opts.inst.idleWave ? I18n.tr("On") : I18n.tr("Off")
        on: opts.inst.idleWave
        closeOnTrigger: false
        onTriggered: opts.cfg.poke("idleWave", !opts.inst.idleWave)
    }
    Grid {
        width: parent.width
        columns: 4
        columnSpacing: Theme.s1
        rowSpacing: Theme.s1
        readonly property real cw: (width - 3 * columnSpacing) / 4
        Repeater {
            model: ["30", "45", "60"]
            delegate: MenuChip {
                required property string modelData
                width: parent.cw; height: Theme.ctlH
                label: modelData
                selected: String(opts.cfg.fps) === modelData
                onClicked: opts.cfg.setFps(parseInt(modelData))
            }
        }
        MenuChip {
            width: parent.cw; height: Theme.ctlH
            label: I18n.tr("Adaptive")
            selected: opts.cfg.adaptive
            onClicked: opts.cfg.setAdaptive(!opts.cfg.adaptive)
        }
    }
    Text {
        // A light caution: each visualiser is its own full-screen pass.
        visible: opts.cfg.count >= 2
        width: parent.width
        leftPadding: Theme.s3
        text: "~" + opts.cfg.ramEstimateMB + " MB"
        color: opts.cfg.count >= 3 ? Theme.error : Theme.inkDim
        font.family: Theme.mono
        font.pixelSize: Theme.fSmall
    }

    // ── Shape ─────────────────────────────────────────────────────────
    MenuSection { label: I18n.tr("Shape"); gloss: "形状" }
    MenuRow {
        visible: opts.shapeSet
        label: I18n.tr("Corners")
        value: opts.cap(opts.inst.shape)
        closeOnTrigger: false
        onTriggered: opts.cfg.poke("shape", opts.cycle(["rounded", "flat"], opts.inst.shape))
    }
    MenuSlider {
        id: segsSld
        visible: opts.segSet
        label: I18n.tr("Segments")
        from: 3; to: 24; step: 1; decimals: 0
        value: opts.inst.segments
        valueText: String(Math.round(segsSld.value))
        onMoved: (v) => opts.cfg.poke("segments", Math.round(v))
        onReleased: (v) => opts.cfg.poke("segments", Math.round(v))
    }
    MenuSlider {
        id: thickSld
        visible: opts.shapeSet
        label: I18n.tr("Bar width")
        from: 0.2; to: 1
        value: opts.inst.thickness
        onMoved: (v) => opts.cfg.poke("thickness", v)
        onReleased: (v) => opts.cfg.poke("thickness", v)
    }
    MenuRow {
        visible: opts.growSet
        label: I18n.tr("Grows")
        value: opts.cap(opts.inst.grow)
        closeOnTrigger: false
        onTriggered: opts.cfg.poke("grow",
            opts.cycle(["up", "down", "center", "left", "right"], opts.inst.grow))
    }
    MenuSlider {
        id: spinSld
        visible: opts.polarSet
        label: I18n.tr("Rotation")
        from: 0; to: 30; step: 1; decimals: 0
        value: opts.inst.spin
        valueText: String(Math.round(spinSld.value))
        onMoved: (v) => opts.cfg.poke("spin", v)
        onReleased: (v) => opts.cfg.poke("spin", v)
    }
    MenuSlider {
        id: reflSld
        visible: opts.reflSet
        label: I18n.tr("Reflection")
        from: 0; to: 0.3
        value: opts.inst.reflection
        onMoved: (v) => opts.cfg.poke("reflection", v)
        onReleased: (v) => opts.cfg.poke("reflection", v)
    }
    MenuSlider {
        id: bloomSld
        visible: opts.bloomSet
        label: I18n.tr("Bloom")
        from: 0; to: 1
        value: opts.inst.bloom
        onMoved: (v) => opts.cfg.poke("bloom", v)
        onReleased: (v) => opts.cfg.poke("bloom", v)
    }
    Grid {
        width: parent.width
        columns: 3
        columnSpacing: Theme.s1
        rowSpacing: Theme.s1
        readonly property real cw: (width - 2 * columnSpacing) / 3
        MenuChip {
            width: parent.cw; height: Theme.ctlH
            label: I18n.tr("Mirror"); selected: opts.inst.mirror
            onClicked: opts.cfg.toggleMirror()
        }
        MenuChip {
            width: parent.cw; height: Theme.ctlH
            label: I18n.tr("Peaks"); selected: opts.inst.peaks
            onClicked: opts.cfg.togglePeaks()
        }
        MenuChip {
            width: parent.cw; height: Theme.ctlH
            label: I18n.tr("Flip"); selected: false
            onClicked: opts.cfg.flip()
        }
    }
    MenuSlider {
        id: gainSld
        label: I18n.tr("Gain")
        from: 0.5; to: 2
        value: opts.inst.gain
        valueText: Math.round(gainSld.value * 100) + "%"
        onMoved: (v) => opts.cfg.setGain(v)
        onReleased: (v) => opts.cfg.setGain(v)
    }
    MenuSlider {
        id: smoothSld
        label: I18n.tr("Smoothing")
        from: 0; to: 1
        value: opts.inst.smoothing
        valueText: Math.round(smoothSld.value * 100) + "%"
        onMoved: (v) => opts.cfg.setSmoothing(v)
        onReleased: (v) => opts.cfg.setSmoothing(v)
    }
    MenuSlider {
        id: tiltXSld
        label: I18n.tr("Lean X")
        from: -opts.cfg.tiltMax; to: opts.cfg.tiltMax; step: 1; decimals: 0
        value: opts.inst.tiltX
        valueText: Math.round(tiltXSld.value) + "\u00b0"
        onMoved: (v) => opts.cfg.setTiltX(v)
        onReleased: (v) => opts.cfg.setTiltX(v)
    }
    MenuSlider {
        id: tiltYSld
        label: I18n.tr("Lean Y")
        from: -opts.cfg.tiltMax; to: opts.cfg.tiltMax; step: 1; decimals: 0
        value: opts.inst.tiltY
        valueText: Math.round(tiltYSld.value) + "\u00b0"
        onMoved: (v) => opts.cfg.setTiltY(v)
        onReleased: (v) => opts.cfg.setTiltY(v)
    }
    MenuRow {
        label: I18n.tr("Level lean")
        closeOnTrigger: false
        onTriggered: opts.cfg.levelTilt()
    }

    // ── Field ──────────────────────────────────────────────────────────
    // The edge field's own surface: it owns the whole screen, so the grips
    // never apply and every knob here is about the current, not a box.
    MenuSection { visible: opts.aura; label: I18n.tr("Field"); gloss: "光流" }
    MenuRow {
        visible: opts.aura
        label: I18n.tr("Movement")
        value: opts.cap(opts.inst.auraShape)
        closeOnTrigger: false
        onTriggered: opts.cfg.poke("auraShape",
            opts.cycle(["flow", "ribbon", "cells", "filament"], opts.inst.auraShape))
    }
    MenuRow {
        visible: opts.aura
        label: I18n.tr("Effect")
        value: opts.cap(opts.inst.auraEffect)
        closeOnTrigger: false
        onTriggered: opts.cfg.poke("auraEffect",
            opts.cycle(["clean", "shimmer", "echo", "prism", "bloom", "caustic", "afterglow"],
                opts.inst.auraEffect))
    }
    MenuSlider {
        id: effSld
        visible: opts.aura
        label: I18n.tr("Effect strength")
        from: 0; to: 1
        value: opts.inst.auraEffectStrength
        onMoved: (v) => opts.cfg.poke("auraEffectStrength", v)
        onReleased: (v) => opts.cfg.poke("auraEffectStrength", v)
    }
    MenuRow {
        visible: opts.aura
        label: I18n.tr("Colour mode")
        value: opts.cap(opts.inst.auraColorMode)
        closeOnTrigger: false
        onTriggered: opts.cfg.poke("auraColorMode",
            opts.cycle(["flow", "spectrum", "pulse", "static"], opts.inst.auraColorMode))
    }
    MenuSlider {
        id: driftSld
        visible: opts.aura
        label: I18n.tr("Colour drift")
        from: 0; to: 1
        value: opts.inst.auraColorSpeed
        onMoved: (v) => opts.cfg.poke("auraColorSpeed", v)
        onReleased: (v) => opts.cfg.poke("auraColorSpeed", v)
    }
    MenuRow {
        visible: opts.aura
        label: I18n.tr("Corners")
        value: opts.cap(opts.inst.auraJoin)
        closeOnTrigger: false
        onTriggered: opts.cfg.poke("auraJoin",
            opts.inst.auraJoin === "auto" ? "separate" : "auto")
    }
    MenuRow {
        visible: opts.aura
        label: I18n.tr("Flow")
        value: opts.cap(opts.inst.auraFlow)
        closeOnTrigger: false
        onTriggered: opts.cfg.poke("auraFlow",
            opts.inst.auraFlow === "clockwise" ? "counterclockwise" : "clockwise")
    }
    MenuSlider {
        id: spanSld
        visible: opts.aura
        label: I18n.tr("Span")
        from: 0.2; to: 1
        value: opts.inst.auraSpan
        onMoved: (v) => opts.cfg.poke("auraSpan", v)
        onReleased: (v) => opts.cfg.poke("auraSpan", v)
    }
    MenuSlider {
        id: taperSld
        visible: opts.aura
        label: I18n.tr("Taper")
        from: 0; to: 0.5
        value: opts.inst.auraTaper
        onMoved: (v) => opts.cfg.poke("auraTaper", v)
        onReleased: (v) => opts.cfg.poke("auraTaper", v)
    }
    MenuSlider {
        id: cornerSld
        visible: opts.aura
        label: I18n.tr("Corner radius")
        from: 0; to: 64; step: 1; decimals: 0
        value: opts.inst.auraCornerRadius
        valueText: Math.round(cornerSld.value) + "px"
        onMoved: (v) => opts.cfg.poke("auraCornerRadius", Math.round(v))
        onReleased: (v) => opts.cfg.poke("auraCornerRadius", Math.round(v))
    }
    MenuSlider {
        id: blendSld
        visible: opts.aura
        label: I18n.tr("Corner blend")
        from: 0; to: 1
        value: opts.inst.auraCornerBlend
        onMoved: (v) => opts.cfg.poke("auraCornerBlend", v)
        onReleased: (v) => opts.cfg.poke("auraCornerBlend", v)
    }
    MenuRow {
        visible: opts.aura
        label: I18n.tr("Frequency profile")
        value: opts.cap(opts.inst.auraProfile)
        closeOnTrigger: false
        onTriggered: opts.cfg.poke("auraProfile",
            opts.cycle(["flat", "bass", "warm", "vocal", "treble", "smile"], opts.inst.auraProfile))
    }
    MenuSlider {
        id: accentSld
        visible: opts.aura
        label: I18n.tr("Profile accent")
        from: 0; to: 1
        value: opts.inst.auraAccent
        onMoved: (v) => opts.cfg.poke("auraAccent", v)
        onReleased: (v) => opts.cfg.poke("auraAccent", v)
    }
    MenuSlider {
        id: fieldOpSld
        visible: opts.aura
        label: I18n.tr("Field opacity")
        from: 0.2; to: 1
        value: opts.inst.auraOpacity
        onMoved: (v) => opts.cfg.poke("auraOpacity", v)
        onReleased: (v) => opts.cfg.poke("auraOpacity", v)
    }
    MenuSlider {
        id: bodyOpSld
        visible: opts.aura
        label: I18n.tr("Body opacity")
        from: 0; to: 1
        value: opts.inst.auraBodyOpacity
        onMoved: (v) => opts.cfg.poke("auraBodyOpacity", v)
        onReleased: (v) => opts.cfg.poke("auraBodyOpacity", v)
    }
    MenuSlider {
        id: crestSld
        visible: opts.aura
        label: I18n.tr("Crest strength")
        from: 0; to: 1
        value: opts.inst.auraCrestStrength
        onMoved: (v) => opts.cfg.poke("auraCrestStrength", v)
        onReleased: (v) => opts.cfg.poke("auraCrestStrength", v)
    }
    MenuSlider {
        id: glowSld
        visible: opts.aura
        label: I18n.tr("Glow")
        from: 0; to: 1
        value: opts.inst.auraGlow
        onMoved: (v) => opts.cfg.poke("auraGlow", v)
        onReleased: (v) => opts.cfg.poke("auraGlow", v)
    }
    MenuSlider {
        id: glowSpreadSld
        visible: opts.aura
        label: I18n.tr("Glow spread")
        from: 0; to: 1
        value: opts.inst.auraGlowSpread
        onMoved: (v) => opts.cfg.poke("auraGlowSpread", v)
        onReleased: (v) => opts.cfg.poke("auraGlowSpread", v)
    }
    MenuSlider {
        id: rangeSld
        visible: opts.aura
        label: I18n.tr("Audio range")
        from: 0; to: 1
        value: opts.inst.auraAudioRange
        onMoved: (v) => opts.cfg.poke("auraAudioRange", v)
        onReleased: (v) => opts.cfg.poke("auraAudioRange", v)
    }
    MenuSlider {
        id: bodyWidSld
        visible: opts.aura
        label: I18n.tr("Body width")
        from: 0.05; to: 0.6
        value: opts.inst.auraThickness
        onMoved: (v) => opts.cfg.poke("auraThickness", v)
        onReleased: (v) => opts.cfg.poke("auraThickness", v)
    }
    MenuSlider {
        id: detailSld
        visible: opts.aura
        label: I18n.tr("Detail")
        from: 0; to: 1
        value: opts.inst.auraDetail
        onMoved: (v) => opts.cfg.poke("auraDetail", v)
        onReleased: (v) => opts.cfg.poke("auraDetail", v)
    }
    MenuSlider {
        id: bassSld
        visible: opts.aura
        label: I18n.tr("Bass drive")
        from: 0; to: 1.5
        value: opts.inst.auraBassDrive
        onMoved: (v) => opts.cfg.poke("auraBassDrive", v)
        onReleased: (v) => opts.cfg.poke("auraBassDrive", v)
    }
    MenuSlider {
        id: trebleSld
        visible: opts.aura
        label: I18n.tr("Treble drive")
        from: 0; to: 1.5
        value: opts.inst.auraTrebleDrive
        onMoved: (v) => opts.cfg.poke("auraTrebleDrive", v)
        onReleased: (v) => opts.cfg.poke("auraTrebleDrive", v)
    }
    MenuSlider {
        id: transientSld
        visible: opts.aura
        label: I18n.tr("Transient kick")
        from: 0; to: 1
        value: opts.inst.auraTransient
        onMoved: (v) => opts.cfg.poke("auraTransient", v)
        onReleased: (v) => opts.cfg.poke("auraTransient", v)
    }
    MenuSlider {
        id: beatSld
        visible: opts.aura
        label: I18n.tr("Beat glow")
        from: 0; to: 1
        value: opts.inst.auraBeatGlow
        onMoved: (v) => opts.cfg.poke("auraBeatGlow", v)
        onReleased: (v) => opts.cfg.poke("auraBeatGlow", v)
    }
    MenuSlider {
        id: compSld
        visible: opts.aura
        label: I18n.tr("Compression")
        from: 0; to: 1
        value: opts.inst.auraCompression
        onMoved: (v) => opts.cfg.poke("auraCompression", v)
        onReleased: (v) => opts.cfg.poke("auraCompression", v)
    }
    MenuSlider {
        id: sensSld
        visible: opts.aura
        label: I18n.tr("Sensitivity")
        from: 0; to: 2
        value: opts.inst.auraSensitivity
        onMoved: (v) => opts.cfg.poke("auraSensitivity", v)
        onReleased: (v) => opts.cfg.poke("auraSensitivity", v)
    }
    MenuSlider {
        id: speedSld
        visible: opts.aura
        label: I18n.tr("Motion speed")
        from: 0; to: 3
        value: opts.inst.auraMotionSpeed
        onMoved: (v) => opts.cfg.poke("auraMotionSpeed", v)
        onReleased: (v) => opts.cfg.poke("auraMotionSpeed", v)
    }
    MenuSlider {
        id: idleSld
        visible: opts.aura
        label: I18n.tr("Idle drift")
        from: 0; to: 1
        value: opts.inst.auraIdleMotion
        onMoved: (v) => opts.cfg.poke("auraIdleMotion", v)
        onReleased: (v) => opts.cfg.poke("auraIdleMotion", v)
    }
    MenuSlider {
        id: attackSld
        visible: opts.aura
        label: I18n.tr("Attack")
        from: 0.2; to: 3
        value: opts.inst.auraAttack
        onMoved: (v) => opts.cfg.poke("auraAttack", v)
        onReleased: (v) => opts.cfg.poke("auraAttack", v)
    }
    MenuSlider {
        id: releaseSld
        visible: opts.aura
        label: I18n.tr("Release")
        from: 0.2; to: 3
        value: opts.inst.auraRelease
        onMoved: (v) => opts.cfg.poke("auraRelease", v)
        onReleased: (v) => opts.cfg.poke("auraRelease", v)
    }
    // The field's edge toggles: which edges the current flows along.
    Grid {
        visible: opts.aura
        width: parent.width
        columns: 4
        columnSpacing: Theme.s1
        rowSpacing: Theme.s1
        readonly property real cw: (width - 3 * columnSpacing) / 4
        Repeater {
            model: ["top", "right", "bottom", "left"]
            delegate: MenuChip {
                required property string modelData
                width: parent.cw; height: Theme.ctlH
                label: opts.cap(modelData)
                selected: (opts.inst.auraEdges || []).indexOf(modelData) >= 0
                onClicked: opts.cfg.toggleAuraEdge(modelData)
            }
        }
    }
    MenuRow {
        visible: opts.aura
        label: I18n.tr("Material")
        value: opts.cap(opts.inst.auraMaterial)
        closeOnTrigger: false
        onTriggered: opts.cfg.cycleAuraMaterial()
    }
    MenuSlider {
        id: reachSld
        visible: opts.aura
        label: I18n.tr("Reach")
        from: 0; to: 1
        value: opts.inst.auraDepth
        onMoved: (v) => opts.cfg.setAuraDepth(v)
        onReleased: (v) => opts.cfg.setAuraDepth(v)
    }
}
