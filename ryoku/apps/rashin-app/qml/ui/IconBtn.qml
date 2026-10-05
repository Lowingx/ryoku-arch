pragma ComponentBehavior: Bound

import QtQuick

// The app's square utility button: a Material Symbols glyph on paper, with
// hover/press tints and an armed state. The one button for icons; text
// buttons live in Pill.
Rectangle {
    id: btn

    property string glyph: ""
    property bool armed: true
    property bool active: false
    property real size: Theme.ctlH - 6
    signal act()

    implicitWidth: size
    implicitHeight: size
    radius: Theme.radiusSm
    opacity: armed ? 1 : 0.35
    color: active ? Theme.bone
        : tap.pressed && armed ? Theme.tint16
        : hover.hovered && armed ? Theme.tint10 : "transparent"
    border.width: Theme.border
    border.color: active ? Theme.bone : hover.hovered ? Theme.lineStrong : Theme.line
    Behavior on color { ColorAnimation { duration: Theme.snap } }
    Behavior on border.color { ColorAnimation { duration: Theme.snap } }

    Text {
        anchors.centerIn: parent
        text: btn.glyph
        color: btn.active ? Theme.inkOnBone : Theme.inkDim
        font.family: "Material Symbols Rounded"
        font.pixelSize: btn.size * 0.52
        Behavior on color { ColorAnimation { duration: Theme.snap } }
    }
    HoverHandler { id: hover; enabled: btn.armed; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; enabled: btn.armed; onTapped: btn.act() }

    // A soft scale on press is the whole micro-animation budget here.
    scale: tap.pressed && btn.armed ? 0.94 : 1
    Behavior on scale {
        enabled: !Theme.reduceMotion
        NumberAnimation { duration: Theme.snap; easing.type: Easing.OutCubic }
    }
}
