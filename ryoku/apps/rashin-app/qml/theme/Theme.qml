pragma Singleton

import QtQuick

// The app's look, in one place. The palette starts at the signature dark
// (the same defaults the rashin dashboard wears) and retints live from
// `GET /api/theme` on the daemon: the desktop's Material roles, resolved
// from the user's scheme or wallpaper. Colours are data; emphasis is
// inversion (a bone plate marks the active thing); the seal stays vermillion.
QtObject {
    id: theme

    // ---- surfaces and ink ---------------------------------------------------
    property color surface: "#000000"
    property color surfaceLow: "#0a0a0a"
    property color paper: "#0d0c0b"
    property color paperLift: "#141312"
    property color bone: "#cdc4ba"
    property color inkOnBone: "#0a0a0a"
    property color ink: "#e8e2da"
    property color inkDim: "#b0a9a0"
    property color inkMuted: "#7d766e"
    property color inkFaint: "#4d4842"
    property color line: Qt.rgba(1, 1, 1, 0.08)
    property color lineStrong: Qt.rgba(1, 1, 1, 0.16)
    property color primary: "#e2342a"
    property color alert: "#e2342a"
    property color ok: "#5dd39e"
    property color tint5: Qt.rgba(1, 1, 1, 0.04)
    property color tint10: Qt.rgba(1, 1, 1, 0.08)
    property color tint16: Qt.rgba(1, 1, 1, 0.13)

    // ---- shape and spacing ---------------------------------------------------
    readonly property real radius: 12
    readonly property real radiusSm: 8
    readonly property real radiusLg: 18
    readonly property real s1: 4
    readonly property real s2: 8
    readonly property real s3: 12
    readonly property real s4: 16
    readonly property real s5: 24
    readonly property real s6: 32
    readonly property real border: 1
    readonly property real ctlH: 36

    // ---- type -----------------------------------------------------------------
    readonly property string ui: "Space Grotesk, Inter, Noto Sans"
    readonly property string mono: "Space Mono, JetBrains Mono, monospace"
    readonly property real fMicroPx: 10
    readonly property real fTinyPx: 11
    readonly property real fSmallPx: 12.5
    readonly property real fBodyPx: 14
    readonly property real fValuePx: 16
    readonly property real fTitlePx: 20
    readonly property real trackMark: 1.6
    readonly property real trackLabel: 0.8

    // ---- motion ----------------------------------------------------------------
    readonly property int snap: 120
    readonly property int swap: 180
    readonly property int move: 260
    readonly property int rise: 380
    readonly property int spatial: 240
    readonly property int dur: 300
    readonly property int durLong: 600
    readonly property int easeOutQuint: Easing.OutQuint
    property bool reduceMotion: false

    // Apply the daemon's resolved Material roles; a missing role keeps the
    // default, so a half-written colors.json never paints the app black.
    function applyRoles(roles) {
        if (!roles)
            return;
        var v;
        v = roles["surface"];
        if (v) surface = v;
        v = roles["surfaceContainerLow"];
        if (v) surfaceLow = v;
        v = roles["onSurface"];
        if (v) ink = v;
        v = roles["onSurfaceVariant"];
        if (v) inkDim = v;
        v = roles["inverseSurface"];
        if (v) bone = v;
        v = roles["inverseOnSurface"];
        if (v) inkOnBone = v;
        v = roles["primary"];
        if (v) primary = v;
    }

    readonly property color paperElevated: Qt.lighter(paper, 1.35)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.5)
}
