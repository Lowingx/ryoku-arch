pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import Ryoku.Ui.Singletons
import "../../stage/Singletons" as StageCfg
import "../../visualizer/Singletons" as VizCfg
import "../../../components"

Item {
    id: root

    required property real s
    required property bool open
    required property real reveal
    required property bool tabActive
    property int index: 0
    property bool compact: false
    property real viewportHeight: 0
    property string page: ""
    readonly property bool active: root.open && root.tabActive
    readonly property bool motionAllowed: !Motion.reduce && !Tokens.reduceMotion
    readonly property var backend: StageCfg.StageBackend
    readonly property var visualizer: VizCfg.Config
    readonly property string wallpaper: Session.wallpaper !== "" ? Session.wallpaper : root.backend.current
    readonly property bool videoWallpaper: /\.(mp4|webm|mkv|mov)$/i.test(root.wallpaper)
    readonly property string previewPath: root.videoWallpaper ? Session.livePoster : root.wallpaper
    readonly property string effect: root.backend.effectFor(root.wallpaper)
    readonly property int layerCount: root.backend.layerCountFor(root.wallpaper)
    readonly property real pad: 12 * root.s
    signal requestClose()

    implicitHeight: root.viewportHeight > 0
        ? root.viewportHeight
        : Math.max(280 * root.s, content.implicitHeight + root.pad * 2)

    function effectLabel(): string {
        if (root.effect === "parallax")
            return I18n.tr("Parallax");
        if (root.effect === "depth")
            return I18n.tr("Depth");
        return I18n.tr("Plain wallpaper");
    }

    function wallpaperName(): string {
        const parts = String(root.wallpaper || "").split("/");
        return parts.length > 0 && parts[parts.length - 1] !== ""
            ? parts[parts.length - 1] : I18n.tr("No wallpaper selected");
    }

    function openHub(route): void {
        root.requestClose();
        Spawn.run(["ryoku-shell", "hub", "open", route]);
    }

    component StatusTile: Rectangle {
        id: tile
        required property string icon
        required property string label
        required property string value
        implicitHeight: 70 * root.s
        radius: Theme.radiusWidget * root.s
        color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.06)
        border.width: Theme.borderWidth
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.30)
        Row {
            anchors.fill: parent
            anchors.margins: 10 * root.s
            spacing: 9 * root.s
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 34 * root.s
                height: width
                radius: width / 2
                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                MaterialIcon {
                    anchors.centerIn: parent
                    text: tile.icon
                    color: Theme.primary
                    font.pixelSize: 18 * root.s
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 34 * root.s - parent.spacing
                spacing: root.s
                Text {
                    width: parent.width
                    text: tile.label
                    color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                    font.family: Theme.fontPrimary
                    font.pixelSize: (Theme.fontSm - 2) * root.s
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: tile.value
                    color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface)
                    font.family: Theme.fontPrimary
                    font.pixelSize: Theme.fontSm * root.s
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }
    }

    component HubButton: Rectangle {
        id: button
        required property string icon
        required property string label
        required property string route
        implicitHeight: 42 * root.s
        radius: Theme.radiusWidget * root.s
        color: tap.containsMouse
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.20)
            : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.06)
        border.width: Theme.borderWidth
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.30)
        Behavior on color {
            enabled: root.motionAllowed
            ColorAnimation { duration: Motion.crossfade; easing.type: Motion.crossfadeCurve }
        }
        Row {
            anchors.centerIn: parent
            spacing: 7 * root.s
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: button.icon
                color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface, 3.0)
                font.pixelSize: 17 * root.s
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: button.label
                color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface)
                font.family: Theme.fontPrimary
                font.pixelSize: Theme.fontSm * root.s
                font.weight: Font.DemiBold
            }
        }
        MouseArea {
            id: tap
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openHub(button.route)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight + root.pad * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
            id: content
            x: root.pad
            y: root.pad
            width: Math.max(0, parent.width - root.pad * 2)
            spacing: 12 * root.s

            Item {
                width: parent.width
                implicitHeight: 26 * root.s
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 8 * root.s
                    Text {
                        id: sectionLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("STAGE")
                        color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                        font.family: Theme.fontPrimary
                        font.pixelSize: (Theme.fontSm - 3) * root.s
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2 * root.s
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - sectionLabel.width - parent.spacing
                        height: Theme.borderWidth
                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.25)
                    }
                }
            }

            Rectangle {
                width: parent.width
                implicitHeight: (root.compact ? 138 : 190) * root.s
                radius: Theme.radiusWidget * root.s
                clip: true
                color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.06)
                border.width: Theme.borderWidth
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.30)
                Image {
                    id: preview
                    anchors.fill: parent
                    source: root.active && root.previewPath !== "" ? "file://" + root.previewPath : ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    opacity: status === Image.Ready ? 0.82 : 0
                }
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.94) }
                    }
                }
                MaterialIcon {
                    visible: preview.status !== Image.Ready
                    anchors.centerIn: parent
                    text: "landscape"
                    color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                    font.pixelSize: 48 * root.s
                }
                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 12 * root.s
                    spacing: 2 * root.s
                    Text {
                        width: parent.width
                        text: root.effectLabel() + (root.layerCount > 0 ? I18n.tr(" · %1 layers").arg(root.layerCount) : "")
                        color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface)
                        font.family: Theme.fontPrimary
                        font.pixelSize: (Theme.fontMd + 2) * root.s
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: root.backend.busy ? I18n.tr("Building the scene · %1%").arg(root.backend.percent) : root.wallpaperName()
                        color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                        font.family: Theme.fontPrimary
                        font.pixelSize: (Theme.fontSm - 1) * root.s
                        elide: Text.ElideMiddle
                    }
                }
            }

            Grid {
                visible: !root.compact
                width: parent.width
                columns: 2
                columnSpacing: 8 * root.s
                rowSpacing: 8 * root.s
                height: visible ? implicitHeight : 0
                StatusTile {
                    width: (parent.width - parent.columnSpacing) / 2
                    icon: "layers"
                    label: I18n.tr("Wallpaper depth")
                    value: root.effectLabel()
                }
                StatusTile {
                    width: (parent.width - parent.columnSpacing) / 2
                    icon: "graphic_eq"
                    label: I18n.tr("Visualizer")
                    value: root.visualizer.enabled ? root.visualizer.styleId : I18n.tr("Off")
                }
            }

            Text {
                visible: !root.compact
                width: parent.width
                text: I18n.tr("Desktop, widget, depth and visualizer choices live in Ryoku Hub.")
                color: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
                font.family: Theme.fontPrimary
                font.pixelSize: Theme.fontSm * root.s
                wrapMode: Text.WordWrap
            }

            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 8 * root.s
                HubButton {
                    width: (parent.width - parent.columnSpacing) / 2
                    icon: "tune"
                    label: I18n.tr("Desktop")
                    route: "desktop-scene"
                }
                HubButton {
                    width: (parent.width - parent.columnSpacing) / 2
                    icon: "graphic_eq"
                    label: I18n.tr("Visualizer")
                    route: "desktop-scene-visualizer"
                }
            }
        }
    }
}
