pragma ComponentBehavior: Bound
import QtQuick
import shell.services
import "../../components"
import "../desktop/Singletons" as DesktopStyle

// The overlay passes body presses through to the live widget; only its two
// actions take an exclusive press, so restyling the frame cannot break dragging.
Item {
    id: outline
    anchors.fill: parent

    property rect box: Qt.rect(0, 0, 0, 0)
    property string title: ""
    property bool selected: false
    property real radius: 6

    signal picked()
    signal settings()
    signal remove()

    visible: outline.box.width > 1 && outline.box.height > 1

    readonly property real headerHeight: 26
    readonly property real headerGap: 7
    readonly property real availableNameWidth: Math.max(0,
        outline.headerRight - outline.headerLeft - buttons.width - outline.headerGap)
    readonly property real headerWidth: Math.min(outline.box.width,
        buttons.width + (nameChip.visible ? outline.headerGap + nameChip.width : 0))
    // The header row's span, clamped to the desktop: a box that reaches past an
    // edge (the visualiser's full-width or turned footprint) keeps its name and
    // buttons on screen instead of cut by the card's edge.
    readonly property real headerLeft: Math.max(0, outline.box.x)
    readonly property real headerRight: Math.min(outline.width > 0 ? outline.width : outline.box.x + outline.box.width,
        outline.box.x + outline.box.width)

    // A colliding pair moves into its own frames, where the bounded headers can
    // no longer cover each other.
    function headerHasRoom() {
        if (outline.box.y <= outline.headerHeight + 13 || !outline.parent)
            return false;

        const candidateY = outline.box.y - outline.headerHeight - outline.headerGap;
        const siblings = outline.parent.children;
        for (let i = 0; i < siblings.length; ++i) {
            const other = siblings[i];
            if (other === outline || !other.visible
                    || other.box === undefined || other.headerWidth === undefined)
                continue;

            const otherY = other.box.y > outline.headerHeight + 13
                ? other.box.y - outline.headerHeight - outline.headerGap
                : other.box.y + outline.headerGap;
            const overlapsY = candidateY < otherY + outline.headerHeight
                && candidateY + outline.headerHeight > otherY;
            const otherWidth = Math.min(other.box.width, other.headerWidth);
            const overlapsX = outline.box.x < other.box.x + otherWidth
                && outline.box.x + outline.headerWidth > other.box.x;
            if (overlapsX && overlapsY)
                return false;
        }
        return true;
    }

    readonly property bool headerInside: !outline.headerHasRoom()
    readonly property real headerY: outline.headerInside
        ? outline.box.y + outline.headerGap
        : outline.box.y - outline.headerHeight - outline.headerGap

    Rectangle {
        id: frame
        x: outline.box.x
        y: outline.box.y
        width: outline.box.width
        height: outline.box.height
        radius: outline.radius
        color: "transparent"
        border.width: outline.selected ? 2 : 1
        border.color: outline.selected
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.95)
            : hover.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.55)
            : Qt.rgba(DesktopStyle.Theme.ink.r, DesktopStyle.Theme.ink.g,
                DesktopStyle.Theme.ink.b, 0.55)
        Behavior on border.color { ColorAnimation { duration: 180 } }

        HoverHandler { id: hover }

        // An exclusive pointer grab here would starve the widget's move grip.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: false
            onPressed: mouse => {
                outline.picked();
                mouse.accepted = false;
            }
        }
    }

    Rectangle {
        id: nameChip
        visible: outline.title.length > 0 && outline.availableNameWidth > 0
        x: Math.round(outline.headerLeft)
        y: Math.round(outline.headerY)
        width: Math.min(nameText.implicitWidth + 18, outline.availableNameWidth)
        height: outline.headerHeight
        radius: 6
        color: outline.selected ? DesktopStyle.Theme.bone
            : Qt.rgba(DesktopStyle.Theme.surface.r, DesktopStyle.Theme.surface.g,
                DesktopStyle.Theme.surface.b, 0.99)
        border.width: 1
        border.color: outline.selected ? DesktopStyle.Theme.bone
            : Qt.rgba(DesktopStyle.Theme.ink.r, DesktopStyle.Theme.ink.g,
                DesktopStyle.Theme.ink.b, 0.4)

        Text {
            id: nameText
            anchors {
                fill: parent
                leftMargin: 9
                rightMargin: 9
            }
            verticalAlignment: Text.AlignVCenter
            text: outline.title
            color: outline.selected ? DesktopStyle.Theme.inkOnBone : DesktopStyle.Theme.ink
            elide: Text.ElideRight
            maximumLineCount: 1
            font.family: DesktopStyle.Theme.font
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
        }
    }

    Row {
        id: buttons
        spacing: outline.headerGap
        x: Math.round(outline.headerRight - width)
        y: Math.round(outline.headerY)
        FrameBtn { icon: "tune"; onAct: outline.settings() }
        FrameBtn { icon: "delete"; danger: true; onAct: outline.remove() }
    }

    component FrameBtn: Rectangle {
        id: fb
        property string icon: ""
        property bool danger: false
        signal act()

        width: outline.headerHeight
        height: outline.headerHeight
        radius: 6
        color: fbMa.containsMouse
            ? (fb.danger ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.9)
                : DesktopStyle.Theme.bone)
            : Qt.rgba(DesktopStyle.Theme.surface.r, DesktopStyle.Theme.surface.g,
                DesktopStyle.Theme.surface.b, 0.99)
        border.width: 1
        border.color: fbMa.containsMouse && !fb.danger
            ? DesktopStyle.Theme.bone
            : Qt.rgba(DesktopStyle.Theme.ink.r, DesktopStyle.Theme.ink.g,
                DesktopStyle.Theme.ink.b, 0.4)
        scale: fbMa.pressed ? 0.94 : 1
        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutBack
                easing.overshoot: 2.2
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: fb.icon
            font.pixelSize: 16
            color: fb.danger && fbMa.containsMouse
                ? Theme.onError
                : fbMa.containsMouse ? DesktopStyle.Theme.inkOnBone
                : DesktopStyle.Theme.ink
        }

        MouseArea {
            id: fbMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fb.act()
        }
    }
}
