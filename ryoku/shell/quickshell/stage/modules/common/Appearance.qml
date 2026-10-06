// Stage keeps the shell's compatibility token names, but resolves their visual
// values through Ryoku's live palette and the same quiet paper-and-ink language
// as Ryogami. Existing pages inherit the look without owning a second theme.
pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import stage.modules.common.functions
import stage.services
import shell.services as RTheme
import Ryoku.Ui.Singletons


Singleton {
    id: root
    property QtObject m3colors
    property QtObject animation
    property QtObject animationCurves
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes
    property string syntaxHighlightingTheme

    function withAlpha(value, alpha) {
        return Qt.rgba(value.r, value.g, value.b, alpha);
    }

    readonly property int windowRounding: {
        let rv = Config.options.appearance.roundingValue;
        if (rv <= 0)
            return 0;
        return Math.round(18 * rv / 24.0);
    }
    // Transparency. The quadratic functions were derived from analysis of hand-picked transparency values.
    ColorQuantizer {
        id: wallColorQuant
        property string wallpaperPath: Config.options?.background?.wallpaperPath ?? ""
        property bool wallpaperIsVideo: wallpaperPath !== "" && (wallpaperPath.endsWith(".mp4") || wallpaperPath.endsWith(".webm") || wallpaperPath.endsWith(".mkv") || wallpaperPath.endsWith(".avi") || wallpaperPath.endsWith(".mov"))
        source: wallpaperPath !== "" ? Qt.resolvedUrl(wallpaperIsVideo ? Config.options?.background?.thumbnailPath ?? "" : wallpaperPath) : ""
        depth: 0 // 2^0 = 1 color
        rescaleSize: 10
    }
    property real wallpaperVibrancy: (wallColorQuant.colors[0]?.hslSaturation + wallColorQuant.colors[0]?.hslLightness) / 2
    property real autoBackgroundTransparency: { // y = 0.5768x^2 - 0.759x + 0.2896
        let x = wallpaperVibrancy;
        let y = 0.5768 * (x * x) - 0.759 * (x) + 0.2896;
        return Math.max(0, Math.min(0.22, y)) - 0.12 * (m3colors.darkmode ? 0 : 1);
    }
    property real autoContentTransparency: 0.9
    property real backgroundTransparency: Config?.options.appearance.transparency.enable ? Config?.options.appearance.transparency.automatic ? autoBackgroundTransparency : Config?.options.appearance.transparency.backgroundTransparency : 0
    property real contentTransparency: Config?.options.appearance.transparency.enable ? (Config?.options.appearance.transparency.automatic ? autoContentTransparency : Config?.options.appearance.transparency.contentTransparency) : 0

    // The Material 3 role palette, sourced from Ryoku's live theme (the same
    // three-layer chain the rest of the desktop paints with: named scheme, then
    // the wallpaper, then the compiled base). The colour derivation below is the
    // reference's verbatim; only this source is Ryoku's, so the editor wears the
    // desktop's palette rather than a second one.
    m3colors: QtObject {
        property bool darkmode: RTheme.Theme.surface.lightness < 0.5
        property bool transparent: false
        property color m3background: RTheme.Theme.surface
        property color m3onBackground: RTheme.Theme.onSurface
        property color m3surface: RTheme.Theme.surface
        property color m3surfaceDim: Qt.darker(RTheme.Theme.surface, 1.1)
        property color m3surfaceBright: Qt.lighter(RTheme.Theme.surface, 1.3)
        property color m3surfaceContainerLowest: RTheme.Theme.surfaceContainerLowest
        property color m3surfaceContainerLow: RTheme.Theme.surfaceContainerLow
        property color m3surfaceContainer: RTheme.Theme.surfaceContainer
        property color m3surfaceContainerHigh: RTheme.Theme.surfaceContainerHigh
        property color m3surfaceContainerHighest: RTheme.Theme.surfaceContainerHighest
        property color m3onSurface: RTheme.Theme.onSurface
        property color m3surfaceVariant: RTheme.Theme.surfaceVariant
        property color m3onSurfaceVariant: RTheme.Theme.onSurfaceVariant
        property color m3inverseSurface: RTheme.Theme.inverseSurface
        property color m3inverseOnSurface: RTheme.Theme.inverseOnSurface
        property color m3outline: RTheme.Theme.outline
        property color m3outlineVariant: RTheme.Theme.outlineVariant
        property color m3shadow: RTheme.Theme.shadow
        property color m3scrim: RTheme.Theme.scrim
        property color m3surfaceTint: RTheme.Theme.surfaceTint
        property color m3primary: RTheme.Theme.primary
        property color m3onPrimary: RTheme.Theme.onPrimary
        property color m3primaryContainer: RTheme.Theme.primaryContainer
        property color m3onPrimaryContainer: RTheme.Theme.onPrimaryContainer
        property color m3inversePrimary: RTheme.Theme.primary
        property color m3secondary: RTheme.Theme.secondary
        property color m3onSecondary: RTheme.Theme.onSecondary
        property color m3secondaryContainer: RTheme.Theme.secondaryContainer
        property color m3onSecondaryContainer: RTheme.Theme.onSecondaryContainer
        property color m3tertiary: RTheme.Theme.tertiary
        property color m3onTertiary: RTheme.Theme.onTertiary
        property color m3tertiaryContainer: RTheme.Theme.tertiaryContainer
        property color m3onTertiaryContainer: RTheme.Theme.onTertiaryContainer
        property color m3error: RTheme.Theme.error
        property color m3onError: RTheme.Theme.onError
        property color m3errorContainer: RTheme.Theme.errorContainer
        property color m3onErrorContainer: RTheme.Theme.onErrorContainer
        property color m3primaryFixed: RTheme.Theme.primaryContainer
        property color m3primaryFixedDim: RTheme.Theme.primary
        property color m3onPrimaryFixed: RTheme.Theme.onPrimaryContainer
        property color m3onPrimaryFixedVariant: RTheme.Theme.onPrimaryContainer
        property color m3secondaryFixed: RTheme.Theme.secondaryContainer
        property color m3secondaryFixedDim: RTheme.Theme.secondary
        property color m3onSecondaryFixed: RTheme.Theme.onSecondaryContainer
        property color m3onSecondaryFixedVariant: RTheme.Theme.onSecondaryContainer
        property color m3tertiaryFixed: RTheme.Theme.tertiaryContainer
        property color m3tertiaryFixedDim: RTheme.Theme.tertiary
        property color m3onTertiaryFixed: RTheme.Theme.onTertiaryContainer
        property color m3onTertiaryFixedVariant: RTheme.Theme.onTertiaryContainer
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"
    }

    // The two border/blur/gap tokens the reference's compositor writers read are
    // kept as plain values (no compositor write): Ryoku owns the compositor's
    // look through its own config, and the editor only needs the numbers.
    property bool borderless: false
    property int borderWidth: 2

    colors: QtObject {
        // Ryogami's paper and ink roles. The numbered layer names remain as
        // compatibility aliases for the imported Stage pages.
        property color colSubtext: root.withAlpha(m3colors.m3onSurface, 0.66)
        property color colLayer0Base: m3colors.m3surface
        property color colLayer0: root.withAlpha(m3colors.m3surface, 0.99)
        property color colOnLayer0: m3colors.m3onSurface
        property color colLayer0Hover: root.withAlpha(m3colors.m3onSurface, 0.05)
        property color colLayer0Active: root.withAlpha(m3colors.m3onSurface, 0.09)
        property color colLayer0Border: root.withAlpha(m3colors.m3outline, 0.55)
        property color colLayer1Base: m3colors.m3surface
        property color colLayer1: root.withAlpha(m3colors.m3surface, 0.965)
        property color colOnLayer1: m3colors.m3onSurface
        property color colOnLayer1Inactive: root.withAlpha(m3colors.m3onSurface, 0.58)
        property color colLayer1Hover: root.withAlpha(m3colors.m3onSurface, 0.05)
        property color colLayer1Active: root.withAlpha(m3colors.m3onSurface, 0.09)
        property color colLayer2Base: m3colors.m3surfaceContainer
        property color colLayer2: root.withAlpha(m3colors.m3surfaceContainer, 0.99)
        property color colLayer2Hover: root.withAlpha(m3colors.m3onSurface, 0.05)
        property color colLayer2Active: root.withAlpha(m3colors.m3onSurface, 0.09)
        property color colLayer2Disabled: root.withAlpha(m3colors.m3surfaceContainer, 0.4)
        property color colOnLayer2: m3colors.m3onSurface
        property color colOnLayer2Disabled: root.withAlpha(m3colors.m3onSurface, 0.35)
        // Raised controls use one surface-container role instead of inventing
        // additional elevations from Material's larger container ladder.
        property color colLayer3Base: m3colors.m3surfaceContainer
        property color colLayer3: root.withAlpha(m3colors.m3surfaceContainer, 0.99)
        property color colLayer3Hover: root.withAlpha(m3colors.m3onSurface, 0.05)
        property color colLayer3Active: root.withAlpha(m3colors.m3onSurface, 0.09)
        property color colOnLayer3: m3colors.m3onSurface
        property color colLayer4Base: m3colors.m3surfaceContainer
        property color colLayer4: root.withAlpha(m3colors.m3surfaceContainer, 0.99)
        property color colLayer4Hover: root.withAlpha(m3colors.m3onSurface, 0.05)
        property color colLayer4Active: root.withAlpha(m3colors.m3onSurface, 0.09)
        property color colOnLayer4: m3colors.m3onSurface
        // Accent is reserved for emphasis and desktop guides; selected controls
        // use the inverted surfaceText plate instead.
        property color colPrimary: m3colors.m3primary
        property color colOnPrimary: m3colors.m3onPrimary
        property color colPrimaryHover: ColorUtils.mix(m3colors.m3primary, m3colors.m3onPrimary, 0.91)
        property color colPrimaryActive: ColorUtils.mix(m3colors.m3primary, m3colors.m3onPrimary, 0.82)
        property color colPrimaryContainer: root.withAlpha(m3colors.m3primary, 0.16)
        property color colPrimaryContainerHover: root.withAlpha(m3colors.m3primary, 0.22)
        property color colPrimaryContainerActive: root.withAlpha(m3colors.m3primary, 0.3)
        property color colOnPrimaryContainer: m3colors.m3onSurface
        // Legacy secondary tokens are the Ryogami inverted control pair.
        property color colSecondary: m3colors.m3onSurface
        property color colSecondaryHover: m3colors.m3onSurface
        property color colSecondaryActive: root.withAlpha(m3colors.m3onSurface, 0.9)
        property color colOnSecondary: m3colors.m3surface
        property color colSecondaryContainer: m3colors.m3onSurface
        property color colSecondaryContainerHover: m3colors.m3onSurface
        property color colSecondaryContainerActive: root.withAlpha(m3colors.m3onSurface, 0.9)
        property color colOnSecondaryContainer: m3colors.m3surface
        property color colTertiary: m3colors.m3tertiary
        property color colTertiaryHover: ColorUtils.mix(m3colors.m3tertiary, m3colors.m3onTertiary, 0.91)
        property color colTertiaryActive: ColorUtils.mix(m3colors.m3tertiary, m3colors.m3onTertiary, 0.82)
        property color colTertiaryContainer: root.withAlpha(m3colors.m3tertiary, 0.16)
        property color colTertiaryContainerHover: root.withAlpha(m3colors.m3tertiary, 0.22)
        property color colTertiaryContainerActive: root.withAlpha(m3colors.m3tertiary, 0.3)
        property color colOnTertiary: m3colors.m3onTertiary
        property color colOnTertiaryContainer: m3colors.m3onSurface
        property color colBackgroundSurfaceContainer: root.withAlpha(m3colors.m3surfaceContainer, 0.99)
        property color colBackgroundSurfaceContainerAccent: root.withAlpha(m3colors.m3surfaceContainer, 0.99)
        property color colSurfaceContainerLow: root.withAlpha(m3colors.m3surface, 0.965)
        property color colSurfaceContainer: root.withAlpha(m3colors.m3surfaceContainer, 0.99)
        property color colSurfaceContainerHigh: root.withAlpha(m3colors.m3onSurface, 0.05)
        property color colSurfaceContainerHighest: root.withAlpha(m3colors.m3onSurface, 0.09)
        property color colSurfaceContainerHighestHover: root.withAlpha(m3colors.m3onSurface, 0.09)
        property color colSurfaceContainerHighestActive: root.withAlpha(m3colors.m3onSurface, 0.16)
        property color colOnSurface: m3colors.m3onSurface
        property color colOnSurfaceVariant: root.withAlpha(m3colors.m3onSurface, 0.74)
        property color colTooltip: root.withAlpha(m3colors.m3surfaceContainer, 0.99)
        property color colOnTooltip: m3colors.m3onSurface
        property color colScrim: root.withAlpha(m3colors.m3scrim, 0.68)
        property color colShadow: root.withAlpha(m3colors.m3shadow, 0.42)
        property color colOutline: root.withAlpha(m3colors.m3outline, 0.55)
        property color colOutlineVariant: root.withAlpha(m3colors.m3outline, 0.4)
        property color colError: m3colors.m3error
        property color colErrorHover: ColorUtils.mix(m3colors.m3error, m3colors.m3onError, 0.91)
        property color colErrorActive: ColorUtils.mix(m3colors.m3error, m3colors.m3onError, 0.82)
        property color colOnError: m3colors.m3onError
        property color colErrorContainer: root.withAlpha(m3colors.m3error, 0.16)
        property color colErrorContainerHover: root.withAlpha(m3colors.m3error, 0.22)
        property color colErrorContainerActive: root.withAlpha(m3colors.m3error, 0.3)
        property color colOnErrorContainer: m3colors.m3onSurface
    }

    rounding: QtObject {
        // Sharp mode remains a user preference; otherwise every Stage surface
        // uses Ryogami's single six-pixel corner.
        property real scale: Config.options.appearance.sharpMode ? 0 : 1
        readonly property int standard: scale === 0 ? 0 : 6
        property int unsharpen: standard
        property int unsharpenmore: standard
        property int verysmall: standard
        property int small: standard
        property int normal: standard
        property int large: standard
        property int verylarge: standard
        property int full: scale === 0 ? 0 : 9999
        property int screenRounding: standard
        property int windowRounding: standard
    }

    font: QtObject {
        property QtObject family: QtObject {
            property string main: "Roboto Condensed"
            property string numbers: "Fraunces"
            property string title: "Fraunces"
            property string iconMaterial: "Material Symbols Rounded"
            property string iconNerd: "Symbols Nerd Font"
            property string monospace: "SpaceMono Nerd Font"
            property string reading: "Roboto Condensed"
            property string expressive: "Space Grotesk"
            property string jp: "Noto Sans CJK JP"
        }
        property QtObject variableAxes: QtObject {
            property var main: ({ "wght": 700 })
            property var numbers: ({ "wght": 600 })
            property var title: ({ "wght": 600 })
            property var rounded: ({ "wght": 700 })
            property var titleRounded: ({ "wght": 600 })
        }
        property QtObject pixelSize: QtObject {
            property real smallest: 8
            property real smaller: 11
            property real smallie: 12
            property real small: 13
            property real normal: 14
            property real large: 16
            property real larger: 20
            property real huge: 22
            property real hugeass: 31
            property real title: 20
        }
    }

    // Global animation speed multiplier — driven by Config.options.appearance.animationMultiplier
    readonly property real animMultiplier: Config.options?.appearance?.animationMultiplier ?? 1.0
    // Below this the shell skips animations outright rather than running them absurdly fast (the
    // sidebars' own convention); Edit Mode reads it as one flag instead of repeating the test.
    readonly property bool reducedMotion: root.animMultiplier <= 0.25

    animationCurves: QtObject {
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1] // Default, 350ms
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1] // Default, 500ms
        readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1] // Default, 650ms
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1] // Default, 200ms
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedFirstHalf: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82]
        readonly property list<real> emphasizedLastHalf: [5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property real expressiveFastSpatialDuration: 350
        readonly property real expressiveDefaultSpatialDuration: 500
        readonly property real expressiveSlowSpatialDuration: 650
        readonly property real expressiveEffectsDuration: 200
    }

    animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: Math.round(250 * root.animMultiplier)
            property int type: Easing.InOutQuad
            property list<real> bezierCurve: animationCurves.standard
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
        }

        property QtObject elementMoveSmall: QtObject {
            property int duration: Math.round(180 * root.animMultiplier)
            property int type: Easing.InOutQuad
            property list<real> bezierCurve: animationCurves.standard
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveSmall.duration
                    easing.type: root.animation.elementMoveSmall.type
                    easing.bezierCurve: root.animation.elementMoveSmall.bezierCurve
                }
            }
        }

        property QtObject elementMoveEnter: QtObject {
            property int duration: Math.round(400 * root.animMultiplier)
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        property QtObject elementMoveExit: QtObject {
            property int duration: Math.round(200 * root.animMultiplier)
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedAccel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveExit.duration
                    easing.type: root.animation.elementMoveExit.type
                    easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
                }
            }
        }

        // Context menus and popups opening under the cursor: the WINDOW the
        // cascade lives in. The reveal scalar runs LINEAR and every slice
        // eases its own arrival — the sidebar's rhythm (StaggeredEntrance:
        // 26 ms stagger, ~400 ms fade per row). Two clocks, strictly
        // separate: the card body + plate land in the first ~22% (the menu
        // pops in and STANDS STILL), and the rows wave in inside it from
        // there to 100%. One global curve over the scalar was the blink
        // (emphasizedDecel is ~85% done at 30% of its time — every row
        // flashed at once); a body that grows across the whole window makes
        // the menu itself perform as a cascade item and hides the rows'
        // wave behind its drift. The exit stays short and flat: a menu
        // waving away, not a page leaving.
        // Duration only: the scalar runs Linear and the slices carry the
        // easing, so there is no curve to hand out. Kept short: 640 ms read
        // well once, then made a menu opened many times a day feel stuck.
        property QtObject popupEnter: QtObject {
            property int duration: Math.round(280 * root.animMultiplier)
        }

        property QtObject popupExit: QtObject {
            property int duration: Math.round(150 * root.animMultiplier)
        }

        property QtObject elementMoveSlow: QtObject {
            property int duration: Math.round(450 * root.animMultiplier)
            property int type: Easing.InOutQuad
            property list<real> bezierCurve: animationCurves.standard
            property int velocity: 850
            property Component colorAnimation: Component {
                ColorAnimation {
                    duration: root.animation.elementMoveSlow.duration
                    easing.type: root.animation.elementMoveSlow.type
                    easing.bezierCurve: root.animation.elementMoveSlow.bezierCurve
                }
            }
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveSlow.duration
                    easing.type: root.animation.elementMoveSlow.type
                    easing.bezierCurve: root.animation.elementMoveSlow.bezierCurve
                }
            }
        }

        property QtObject elementMoveFast: QtObject {
            property int duration: Math.round(180 * root.animMultiplier)
            property int type: Easing.InOutQuad
            property list<real> bezierCurve: animationCurves.standard
            property int velocity: 850
            property Component colorAnimation: Component {
                ColorAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
        }

        /**
         * A selection that follows the keyboard (Alt+Tab's highlight). Shorter than
         * elementMoveFast so a held key reads as one motion, and deliberately without
         * `alwaysRunToEnd`: a Behavior retargets from wherever the value is, and running
         * each leg to its end would queue every press behind the last one.
         */
        property QtObject elementMoveSnap: QtObject {
            property int duration: Math.round(150 * root.animMultiplier)
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveFastSpatial
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveSnap.duration
                    easing.type: root.animation.elementMoveSnap.type
                    easing.bezierCurve: root.animation.elementMoveSnap.bezierCurve
                }
            }
        }

        property QtObject elementResize: QtObject {
            property int duration: Math.round(300 * root.animMultiplier)
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasized
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementResize.duration
                    easing.type: root.animation.elementResize.type
                    easing.bezierCurve: root.animation.elementResize.bezierCurve
                }
            }
        }

        // Every size change that happens *inside* the bar reads from here: the
        // widgets and the island backgrounds that wrap them have to reach their
        // new size at the same instant, and they only do that if they share one
        // duration and one curve. A widget that animates its own implicitWidth
        // faster than the island around it makes the island look like it is
        // chasing the content (and vice versa).
        // 280ms is the duration the Dynamic Island already used; the fast
        // spatial curve keeps its slight overshoot without the OutBack tail.
        property QtObject barResize: QtObject {
            property int duration: Math.round(280 * root.animMultiplier)
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveFastSpatial
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.barResize.duration
                    easing.type: root.animation.barResize.type
                    easing.bezierCurve: root.animation.barResize.bezierCurve
                }
            }
        }

        // Dashboard indicators use a staged transition: the slot changes size
        // before/after the icon pop. Keep these slower and softer than the
        // global barResize clock without slowing every other responsive widget.
        property QtObject dashboardIndicatorResize: QtObject {
            property int duration: Math.round(420 * root.animMultiplier)
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.standard
        }

        property QtObject dashboardIndicatorPop: QtObject {
            property int enterDuration: Math.round(360 * root.animMultiplier)
            property int exitDuration: Math.round(280 * root.animMultiplier)
            property int cueDelay: Math.round(90 * root.animMultiplier)
            property int exitHoldDuration: Math.round(220 * root.animMultiplier)
            property int enterType: Easing.OutBack
            property real enterOvershoot: 1.18
            property int exitType: Easing.BezierSpline
            property list<real> exitCurve: animationCurves.emphasizedAccel
        }

        // The bar and the wrapped frame leaving the screen together: a
        // fullscreen window taking over, media mode, or a placement swap. The
        // exit accelerates away and the entrance decelerates in, so a swap does
        // not read as two halves of the same easing.
        property QtObject shellEdgeSlide: QtObject {
            property int exitDuration: Math.round(260 * root.animMultiplier)
            property int enterDuration: Math.round(420 * root.animMultiplier)
            property int swapHold: Math.round(90 * root.animMultiplier)
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.shellEdgeSlide.enterDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.animationCurves.emphasized
                }
            }
        }

        // Sidebars sliding in and out, and the wallpaper parallax that follows them.
        // No overshoot anywhere: expressive spatial curves kick off at ~3x linear speed and
        // bounce the wallpaper past its rest, which reads as hard. The sidebar enters on M3
        // emphasized (gentle start, long settle) and leaves accelerating, like end4's layer
        // animations; the wallpaper runs its own, longer emphasized clock in both directions,
        // since an accelerating exit is invisible for a sidebar but stops the wallpaper dead.
        property QtObject sidebarSlide: QtObject {
            property int enterDuration: Math.round(500 * root.animMultiplier)
            property int exitDuration: Math.round(500 * root.animMultiplier)
            property list<real> enterCurve: root.animationCurves.emphasized
            property list<real> exitCurve: root.animationCurves.emphasized
            property int parallaxDuration: Math.round(700 * root.animMultiplier)
            property list<real> parallaxCurve: root.animationCurves.emphasized
        }

        property QtObject clickBounce: QtObject {
            property int duration: Math.round(400 * root.animMultiplier)
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveDefaultSpatial
            property int velocity: 850
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.clickBounce.duration
                    easing.type: root.animation.clickBounce.type
                    easing.bezierCurve: root.animation.clickBounce.bezierCurve
                }
            }
        }

        // One lens shared by every dock icon. pointerLag smooths the pointer the
        // lens follows (critically damped, never overshoots); strengthDuration
        // is how long the lens takes to grow in on enter. Past the window edge
        // there are no pointer samples, so the exit is timed: exitDuration, on
        // a curve that starts and ends gently.
        property QtObject dockMagnificationScale: QtObject {
            property QtObject fast: QtObject {
                property real pointerLag: 0
                property int strengthDuration: Math.round(90 * root.animMultiplier)
                property int exitDuration: Math.round(220 * root.animMultiplier)
            }
            property QtObject balanced: QtObject {
                property real pointerLag: 28
                property int strengthDuration: Math.round(150 * root.animMultiplier)
                property int exitDuration: Math.round(280 * root.animMultiplier)
            }
            property QtObject smooth: QtObject {
                property real pointerLag: 60
                property int strengthDuration: Math.round(220 * root.animMultiplier)
                property int exitDuration: Math.round(340 * root.animMultiplier)
            }
            property int hoverExitGrace: 90
        }

        // Retained for discrete magnification feedback in secondary popups.
        property QtObject dockMagnification: QtObject {
            property int duration: Math.round(220 * root.animMultiplier)
            property int type: Easing.OutBack
            property real overshoot: 1.35
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.dockMagnification.duration
                    easing.type: root.animation.dockMagnification.type
                    easing.overshoot: root.animation.dockMagnification.overshoot
                }
            }
        }

        property QtObject scroll: QtObject {
            property int duration: Math.round(200 * root.animMultiplier)
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: root.animationCurves.standardDecel
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.scroll.duration
                    easing.type: root.animation.scroll.type
                    easing.bezierCurve: root.animation.scroll.bezierCurve
                }
            }
        }

        property QtObject menuDecel: QtObject {
            property int duration: Math.round(350 * root.animMultiplier)
            property int type: Easing.OutExpo
        }
    }

    sizes: QtObject {
        // A finger needs a bigger target than a cursor. A touch-first family raises the
        // bar's FLOOR rather than replacing the value: a bar the user configured taller
        // than this stays taller, and the stored preference is never rewritten.
        //
        // This is deliberately here and not a per-window scale. Scaling the bar window was
        // tried and reverted — every widget inside sizes itself off barHeight, so the window
        // grew while the content did not, and backgrounds, hit targets and popup anchors all
        // measured against a bar that was not the one on screen.
        // Material's minimum touch target, and the Pixel Tablet's status bar height.
        property real minimumTouchTarget: 48
        // Ryogami's spacing scale. New Stage chrome reads these names while
        // older pages keep their established geometry contracts.
        readonly property real space1: 4
        readonly property real space2: 7
        readonly property real space3: 9
        readonly property real space4: 13
        readonly property real space5: 20
        readonly property real space6: 28
        readonly property real controlHeight: 30


        // Snap step for desktop widgets and icons on the wallpaper canvas.
        //
        // Ten pixels is a fine-positioning aid for a mouse: it takes the jitter out of a
        // drag without really constraining where something lands. A finger cannot place
        // anything that precisely, and a home screen is supposed to look laid out on a
        // grid rather than merely tidy — so a touch-first family snaps to a step coarse
        // enough to read as cells, the way Android's home screen does.
        // What this family wants when nothing is configured. Kept separate from the
        // resolved value below so a settings control can offer it as the fallback without
        // reading a property that depends on the very key it writes — that was a binding
        // loop, and the page it was on rendered empty.
        readonly property real familyWidgetGridStep: PanelFamily.touchFirst ? 40 : 10

        property real widgetGridStep: {
            const configured = Config.options?.background?.widgets?.gridStep ?? 0;
            return configured > 0 ? configured : root.sizes.familyWidgetGridStep;
        }
        property real baseBarHeight: PanelFamily.touchFirst
            ? Math.max(root.sizes.minimumTouchTarget, Config.options.bar.sizes.height)
            : Config.options.bar.sizes.height
        property real barHeight: BarInteraction.cornerStyle === 1 ? (baseBarHeight + root.sizes.hyprlandGapsOut * 2) : baseBarHeight
        // Bar widgets were drawn against a 40px horizontal bar and a 44px vertical one, and
        // most of them size their outer plate off the bar while leaving the glyph inside at
        // the number it was drawn with. On a touch-first family the bar is taller than that
        // by definition, so those widgets became big plates around small icons. Scaling the
        // insides by the same ratio is a no-op at the default and correct everywhere else.
        readonly property real barReferenceHeight: 40
        readonly property real barReferenceWidth: 44
        readonly property real barContentScale: root.sizes.baseBarHeight / root.sizes.barReferenceHeight
        readonly property real verticalBarContentScale: root.sizes.verticalBarWidth / root.sizes.barReferenceWidth

        property real barCenterSideModuleWidth: Config.options?.bar.verbose ? 360 : 140
        property real barCenterSideModuleWidthShortened: 280
        property real barCenterSideModuleWidthHellaShortened: 190
        property real barShortenScreenWidthThreshold: 1200 // Shorten if screen width is at most this value
        property real barHellaShortenScreenWidthThreshold: 1000 // Shorten even more...
        property real elevationMargin: 10
        // The Stage toolbar adopts Ryogami's 58px FilterBar masthead.
        property real toolbarHeight: 58
        // Edit Mode's viewport: the gap between the shrunk desktop and what surrounds it, the
        // tighter gap between the chrome and the usable area's edge, and the width the widget
        // drawer opens into (reserved from the first frame so the desktop never resizes mid-edit).
        property real editModeMargin: 24
        property real editModeEdgeMargin: 12
        property real editModeDrawerWidth: 380
        property real fabShadowRadius: 5
        property real fabHoveredShadowRadius: 7
        property real hyprlandGapsOut: 5
        property real mediaControlsWidth: 440
        property real mediaControlsHeight: 160
        property real notificationPopupWidth: 410
        property real osdWidth: 200
        property real searchWidthCollapsed: 350
        property real searchWidth: 500
        property real sidebarWidth: 460
        property real sidebarWidthExtended: 750
        property real baseVerticalBarWidth: Config.options.bar.sizes.width
        property real verticalBarWidth: baseVerticalBarWidth
        property real verticalBarWindowWidth: BarInteraction.cornerStyle === 1 ? (baseVerticalBarWidth + root.sizes.hyprlandGapsOut * 2) : baseVerticalBarWidth
        property real wallpaperSelectorWidth: 1200
        property real wallpaperSelectorHeight: 690
        property real wallpaperSelectorSidebarWidth: 180
        property real wallpaperSelectorSidebarButtonHeight: 48
        property real wallpaperSelectorSidebarHorizontalPadding: 6
        property real wallpaperSelectorSidebarButtonSpacing: 3
        property real wallpaperSelectorSidebarGroupSpacing: 10
        property real wallpaperSelectorSearchWidth: 300
        property real wallpaperSelectorSortDialogWidth: 280
        property real wallpaperSelectorItemMargins: 8
        property real wallpaperSelectorItemPadding: 6
        property int dockButtonSize: Math.round((Config.options?.dock.height ?? 60) * 0.85)
    }

    syntaxHighlightingTheme: root.m3colors.darkmode ? "Monokai" : "ayu Light"
}
