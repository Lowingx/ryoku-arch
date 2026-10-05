import QtQuick

// The app's text button: a pill on paper. `primary` inverts to the bone
// plate (emphasis is inversion, colour is data); `compact` shrinks it for
// inline rows.

Rectangle {
    id: pill

    property string text: ""
    property bool primary: false
    property bool armed: true
    property bool compact: false
    signal act()

    implicitWidth: label.implicitWidth + (compact ? Theme.s4 : Theme.s5) * 2
    implicitHeight: compact ? Theme.ctlH - 8 : Theme.ctlH
    radius: Theme.radiusSm
    opacity: armed ? 1 : 0.4
    color: primary ? Theme.bone
        : tap.pressed && armed ? Theme.tint16
        : hover.hovered && armed ? Theme.tint10 : "transparent"
    border.width: Theme.border
    border.color: primary ? Theme.bone : hover.hovered ? Theme.lineStrong : Theme.line
    Behavior on color { ColorAnimation { duration: Theme.snap } }
    Behavior on border.color { ColorAnimation { duration: Theme.snap } }

    Text {
        id: label
        anchors.centerIn: parent
        text: pill.text
        color: pill.primary ? Theme.inkOnBone : pill.armed ? Theme.ink : Theme.inkMuted
        font.family: Theme.ui
        font.pixelSize: pill.compact ? Theme.fSmallPx : 13
        font.weight: pill.primary ? Font.DemiBold : Font.Normal
    }
    HoverHandler { id: hover; enabled: pill.armed; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; enabled: pill.armed; onTapped: pill.act() }

    scale: tap.pressed && pill.armed ? 0.97 : 1
    Behavior on scale {
        enabled: !Theme.reduceMotion
        NumberAnimation { duration: Theme.snap; easing.type: Easing.OutCubic }
    }
}
