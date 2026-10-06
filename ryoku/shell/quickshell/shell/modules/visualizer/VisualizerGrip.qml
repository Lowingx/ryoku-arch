pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons as Ui
import "Singletons"
// The Stage Editor's placement grip for the visualiser: the corner grip and
// turn dot of the standalone placer, ported. Drag to move, the corner to size,
// the dot to turn, Ctrl+wheel to scale. It rides the desktop surface while the
// Stage Editor frames this monitor, so the look is aimed with every other
// widget rather than on a surface of its own; the outline, name and buttons
// are the shared edit frame's (StageOutline), which boxes the look's turned
// footprint through `boxItem`.
//
// The gestures are the placer's, easing included: a gesture aims at a target
// and the box eases toward it, so an unsteady hand still lands a clean size,
// and the easing outlives the release or letting go mid-drag would strand the
// box short of where the pointer asked. The box is fractions of the monitor,
// so the same numbers land on any screen.
Item {
    id: win

    // Whether the Stage Editor frames this desktop right now.
    required property bool composing

    // A gesture's walk-back is the desktop's to record: it started here and it
    // lands here, so the press and the eased settle raise these together.
    signal gestureStarted()
    signal gestureFinished()
    // Right-click on the look asks the desktop for its menu, like a slot does.
    signal menuRequested(real x, real y)
    // Keep the shared spectrum running while a look is being aimed, even under
    // Power Saver or silence, so it stays visible to place; released when the
    // editor leaves. The hold is the placer's, moved here with the gestures.
    readonly property bool holding: win.composing && Config.enabled
    onHoldingChanged: Spectrum.placementHolds += holding ? 1 : -1
    Component.onDestruction: if (holding) Spectrum.placementHolds -= 1

    anchors.fill: parent
    visible: win.composing && Config.enabled

    readonly property real handle: Ui.Tokens.s4
    // The look's box, in desktop px; the field's box is the screen.
    readonly property rect box: Config.isAura
        ? Qt.rect(0, 0, win.width, win.height)
        : Qt.rect(Config.x * win.width, Config.y * win.height,
                  Config.w * win.width, Config.h * win.height)
    // Rotation is about the box centre, which is the one point a turn never moves.
    readonly property real cx: win.box.x + win.box.width / 2
    readonly property real cy: win.box.y + win.box.height / 2
    readonly property real aspect: win.height > 0 ? win.width / win.height : 1

    // The guide colour: the look's own pinned colour, else the shell accent,
    // the way the placer matched its guides to the ramp.
    readonly property color guide: Config.hasCustomColor ? Config.customColor
        : (Scheme.accent.r !== Scheme.accent.g || Scheme.accent.g !== Scheme.accent.b
            ? Scheme.accent : "white")

    property string gesture: ""
    property real tx: 0
    property real ty: 0
    property real tw: 0
    property real th: 0
    property real tAngle: 0

    Timer {
        id: ease
        interval: 16
        repeat: true
        running: win.gesture !== ""
        onTriggered: {
            var k = 0.32;
            var eps = 0.0006;
            var done = false;
            if (win.gesture === "turn") {
                var d = PlaceMath.shortestTurn(Config.angle, win.tAngle);
                done = Math.abs(d) < 0.05;
                Config.rotate(done ? win.tAngle : Config.angle + d * k);
            } else if (win.gesture === "move") {
                done = Math.abs(win.tx - Config.x) < eps && Math.abs(win.ty - Config.y) < eps;
                if (done)
                    Config.moveBox(win.tx, win.ty, win.aspect);
                else
                    Config.moveBox(Config.x + (win.tx - Config.x) * k,
                                   Config.y + (win.ty - Config.y) * k,
                                   win.aspect);
            } else {
                done = Math.abs(win.tx - Config.x) < eps && Math.abs(win.ty - Config.y) < eps
                    && Math.abs(win.tw - Config.w) < eps && Math.abs(win.th - Config.h) < eps;
                if (done)
                    Config.setBox(win.tx, win.ty, win.tw, win.th, win.aspect);
                else
                    Config.setBox(Config.x + (win.tx - Config.x) * k,
                                  Config.y + (win.ty - Config.y) * k,
                                  Config.w + (win.tw - Config.w) * k,
                                  Config.h + (win.th - Config.h) * k,
                                  win.aspect);
            }
            // Over only once the hand is off and the box has caught up; the
            // desktop turns that into one undo entry.
            if (done && grab.mode === "") {
                win.gesture = "";
                win.gestureFinished();
            }
        }
    }

    // The look's turned footprint, axis-aligned: the edit frame (StageOutline)
    // boxes this the way it boxes every other widget, and the inspector docks
    // beside it. Same bounding-box maths the spectrum field uses for its cover
    // rect, so the frame hugs the look at any angle rather than its unturned w/h.
    readonly property rect outer: {
        var a = Config.angle * Math.PI / 180;
        var c = Math.abs(Math.cos(a)), s = Math.abs(Math.sin(a));
        var w = win.box.width * c + win.box.height * s;
        var h = win.box.width * s + win.box.height * c;
        return Qt.rect(win.cx - w / 2, win.cy - h / 2, w, h);
    }
    Item {
        id: footprint
        x: win.outer.x
        y: win.outer.y
        width: win.outer.width
        height: win.outer.height
    }
    // The turned footprint, exposed for the desktop: the edit frame boxes this
    // the way it boxes a slot, and the inspector docks beside it.
    readonly property Item boxItem: footprint

    // The handles ride a turned frame, so they sit where the look's own corner
    // and top edge actually are. The outline itself is the edit frame's job.
    Item {
        id: frame

        // The field owns the whole screen and has no box to aim: the edge
        // handles would ring the display with controls that edit nothing (the
        // placer treated it the same way), so the field rides handleless.
        visible: !Config.isAura
        x: win.box.x
        y: win.box.y
        width: win.box.width
        height: win.box.height
        rotation: Config.angle
        transformOrigin: Item.Center

        // the grip sits on the box's own corner, so it is always beside what it sizes
        Rectangle {
            id: grip
            width: win.handle
            height: win.handle
            radius: 2
            color: (grab.mode === "size" || grab.over === "size") ? win.guide : Qt.alpha(win.guide, 0.45)
            border.width: 1
            border.color: win.guide
            x: parent.width - width / 2
            y: parent.height - height / 2
        }

        // the turn handle stands off the top edge on a stem, so it reads as a lever
        // rather than another corner
        Rectangle {
            width: 1
            height: win.handle * 1.6
            color: Qt.alpha(win.guide, 0.55)
            x: parent.width / 2
            y: -height
        }
        Rectangle {
            id: spinner
            width: win.handle
            height: win.handle
            radius: width / 2
            color: (grab.mode === "turn" || grab.over === "turn") ? win.guide : Qt.alpha(win.guide, 0.45)
            border.width: 1
            border.color: win.guide
            x: parent.width / 2 - width / 2
            y: -win.handle * 1.6 - height / 2
        }
    }

    // Ctrl+wheel scales, the same chord every other widget in the editor uses.
    // A notch that repeats is one gesture: the walk-back opens on the first and
    // closes when the wheel settles, the way the slot's does.
    property bool wheelHold: false
    Timer {
        id: wheelSettle
        interval: 350
        onTriggered: {
            win.wheelHold = false;
            win.gestureFinished();
        }
    }

    // The press area is the box's turned footprint plus the handles' reach, so
    // a press on the look or its grips lands here and a press anywhere else
    // falls through to the desktop's own click-away.
    MouseArea {
        id: grab

        enabled: !Config.isAura
        x: Math.max(0, win.box.x - win.handle)
        y: Math.max(0, win.box.y - win.handle * 3)
        width: Math.min(win.width, win.box.width + 2 * win.handle)
        height: Math.min(win.height, win.box.height + 4 * win.handle)
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: grab.over === "size" ? Qt.SizeFDiagCursor
            : (grab.over === "turn" ? Qt.CrossCursor : Qt.SizeAllCursor)

        // The handles ride a turned frame, so map their centres rather than compute
        // them: a mapped centre is right at every angle.
        function near(it, mx, my) {
            var p = it.mapToItem(null, it.width / 2, it.height / 2);
            return Math.abs(mx - p.x) < win.handle && Math.abs(my - p.y) < win.handle;
        }
        readonly property string over: grab.near(spinner, grab.mouseX, grab.mouseY) ? "turn"
            : (grab.near(grip, grab.mouseX, grab.mouseY) ? "size" : "move")

        property string mode: ""
        property real pressX: 0
        property real pressY: 0
        property real baseX: 0
        property real baseY: 0
        property real baseW: 0
        property real baseH: 0
        property real baseAngle: 0
        property real pressAngle: 0

        onPressed: (m) => {
            if (m.button === Qt.RightButton) {
                win.menuRequested(win.box.x, win.box.y);
                return;
            }
            if (Config.isAura)
                return;
            grab.mode = grab.over;
            win.gesture = grab.over;
            win.gestureStarted();
            grab.pressX = m.x;
            grab.pressY = m.y;
            grab.baseX = Config.x;
            grab.baseY = Config.y;
            grab.baseW = Config.w;
            grab.baseH = Config.h;
            grab.baseAngle = Config.angle;
            grab.pressAngle = PlaceMath.angleAt(win.cx, win.cy, m.x, m.y);
            win.tx = Config.x;
            win.ty = Config.y;
            win.tw = Config.w;
            win.th = Config.h;
            win.tAngle = Config.angle;
        }
        onReleased: grab.mode = ""
        // Deltas from the press, never absolute positions, so nothing jumps.
        onPositionChanged: (m) => {
            if (!grab.pressed || grab.mode === "" || Config.isAura)
                return;
            if (grab.mode === "turn") {
                // Near the centre a pixel of travel is a wild swing.
                if (Math.hypot(m.x - win.cx, m.y - win.cy) < win.handle * 1.5)
                    return;
                var want = grab.baseAngle
                    + PlaceMath.angleAt(win.cx, win.cy, m.x, m.y) - grab.pressAngle;
                win.tAngle = PlaceMath.magnet(want, 15, 2.5);
                return;
            }
            var dx = m.x - grab.pressX;
            var dy = m.y - grab.pressY;
            if (grab.mode === "move") {
                win.tx = grab.baseX + dx / Math.max(1, win.width);
                win.ty = grab.baseY + dy / Math.max(1, win.height);
                return;
            }
            var out = PlaceMath.resize({ x: grab.baseX, y: grab.baseY, w: grab.baseW, h: grab.baseH },
                                       grab.baseAngle, dx, dy,
                                       { w: win.width, h: win.height }, { w: 0.04, h: 0.03 });
            win.tx = out.x;
            win.ty = out.y;
            win.tw = out.w;
            win.th = out.h;
        }
        // Ctrl+wheel scales over the same footprint as the press: a wheel
        // anywhere else still scrolls what is under it. The handler takes no
        // geometry of its own; nesting it in the area borrows the area's.
        WheelHandler {
            acceptedModifiers: Qt.ControlModifier
            onWheel: (w) => {
                if (!win.wheelHold) {
                    win.wheelHold = true;
                    win.gestureStarted();
                }
                var k = w.angleDelta.y > 0 ? 1.06 : 0.94;
                Config.sizeBox(Config.w * k, Config.h * k, win.aspect);
                wheelSettle.restart();
            }
        }
    }
}
