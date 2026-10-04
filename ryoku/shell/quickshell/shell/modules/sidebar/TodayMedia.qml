pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root

    required property real s
    required property bool active
    property bool detailed: false
    signal requestDetail()

    readonly property var player: root.active ? Media.player : null
    readonly property real length: root.player && root.player.length > 0 ? root.player.length : 0
    readonly property real position: root.player ? Math.max(0, root.player.position || 0) : 0
    readonly property real progress: root.length > 0 ? Math.max(0, Math.min(1, root.position / root.length)) : 0
    readonly property bool motionAllowed: !Tokens.reduceMotion && !Motion.reduce

    implicitHeight: Math.round((root.detailed ? 332 : 108) * root.s)

    function artist() {
        if (!root.player) return "";
        if (root.player.trackArtists && root.player.trackArtists.length > 0)
            return root.player.trackArtists.join(", ");
        return root.player.trackArtist || "";
    }

    function formatTime(value) {
        const seconds = Math.max(0, Math.floor(value || 0));
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const rest = seconds % 60;
        const padded = rest < 10 ? "0" + rest : String(rest);
        return hours > 0 ? hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + padded : minutes + ":" + padded;
    }

    Timer {
        interval: 500
        repeat: true
        running: root.active && root.visible && root.player !== null && root.player.isPlaying
        onTriggered: if (root.player) root.player.positionChanged()
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radius * root.s * 1.5
        color: Tokens.role("secondaryContainer", Tokens.paperLift)
        border.width: Tokens.border
        border.color: Tokens.role("secondary", Tokens.lineStrong)
        clip: true

        Image {
            id: backgroundArt
            anchors.fill: parent
            source: root.active && root.player ? root.player.trackArtUrl || "" : ""
            sourceSize.width: Math.round(width * 1.5)
            sourceSize.height: Math.round(height * 1.5)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: status === Image.Ready
            opacity: root.detailed ? 0.18 : 0.12
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Tokens.role("secondaryContainer", Tokens.paperLift) }
                GradientStop { position: 1; color: Qt.rgba(Tokens.paper.r, Tokens.paper.g, Tokens.paper.b, 0.72) }
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: Tokens.s3 * root.s

            Rectangle {
                id: artwork
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: progressArea.top
                anchors.bottomMargin: root.detailed ? Tokens.s3 * root.s : Tokens.s1 * root.s
                width: height
                radius: Tokens.radius * root.s
                color: Tokens.role("tertiaryContainer", Tokens.tint10)
                clip: true

                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.active && root.player ? root.player.trackArtUrl || "" : ""
                    sourceSize.width: Math.round(width * 2)
                    sourceSize.height: Math.round(height * 2)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.player || cover.status !== Image.Ready
                    text: root.player && root.player.trackTitle ? root.player.trackTitle.charAt(0).toUpperCase() : "•"
                    color: Tokens.role("onTertiaryContainer", Tokens.ink)
                    font.family: Tokens.display
                    font.pixelSize: (root.detailed ? Tokens.fHero : Tokens.fValue) * root.s
                    font.weight: Font.Medium
                }
            }

            Column {
                anchors.left: artwork.right
                anchors.right: parent.right
                anchors.leftMargin: Tokens.s3 * root.s
                anchors.top: parent.top
                anchors.bottom: progressArea.top
                anchors.bottomMargin: root.detailed ? Tokens.s3 * root.s : Tokens.s1 * root.s
                spacing: Tokens.s1 * root.s

                Text {
                    width: parent.width
                    text: root.player ? root.player.trackTitle || I18n.tr("Untitled") : I18n.tr("Nothing is playing")
                    color: Tokens.role("onSecondaryContainer", Tokens.ink)
                    font.family: root.detailed ? Tokens.display : Tokens.ui
                    font.pixelSize: (root.detailed ? Tokens.fValue : Tokens.fRow) * root.s
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: root.player ? root.artist() : I18n.tr("Start music in any MPRIS player")
                    color: Tokens.role("onSecondaryContainer", Tokens.inkMuted)
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                    elide: Text.ElideRight
                }
                Text {
                    visible: root.detailed && root.player !== null
                    width: parent.width
                    text: root.player ? root.player.identity || root.player.dbusName || "" : ""
                    color: Tokens.role("onSecondaryContainer", Tokens.inkFaint)
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny * root.s
                    elide: Text.ElideRight
                }

                Item { width: 1; height: Math.max(0, parent.height - controls.height - parent.children[0].height - parent.children[1].height - (parent.children[2].visible ? parent.children[2].height : 0) - parent.spacing * 3) }

                Row {
                    id: controls
                    spacing: Tokens.s1 * root.s

                    CornerButton {
                        s: root.detailed ? root.s : root.s * 0.88
                        glyph: "skip_previous"
                        enabled: !!(root.player && root.player.canGoPrevious)
                        subtle: true
                        Accessible.name: I18n.tr("Previous")
                        onClicked: if (root.player) root.player.previous()
                    }
                    CornerButton {
                        s: root.detailed ? root.s : root.s * 0.88
                        glyph: root.player && root.player.isPlaying ? "pause" : "play_arrow"
                        enabled: !!(root.player && root.player.canTogglePlaying)
                        emphasis: true
                        Accessible.name: root.player && root.player.isPlaying ? I18n.tr("Pause") : I18n.tr("Play")
                        onClicked: if (root.player) root.player.togglePlaying()
                    }
                    CornerButton {
                        s: root.detailed ? root.s : root.s * 0.88
                        glyph: "skip_next"
                        enabled: !!(root.player && root.player.canGoNext)
                        subtle: true
                        Accessible.name: I18n.tr("Next")
                        onClicked: if (root.player) root.player.next()
                    }
                    CornerButton {
                        visible: !root.detailed
                        s: root.s * 0.88
                        glyph: "open_in_full"
                        subtle: true
                        Accessible.name: I18n.tr("Open media")
                        onClicked: root.requestDetail()
                    }
                }
            }

            Item {
                id: progressArea
                visible: root.player !== null
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: visible ? Math.round((root.detailed ? 43 : 6) * root.s) : 0

                Rectangle {
                    id: progressTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: Math.round(5 * root.s)
                    radius: height / 2
                    color: Tokens.role("onSecondaryContainer", Tokens.lineSoft)

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: parent.radius
                        color: Tokens.role("secondary", Tokens.sun)
                        Behavior on width {
                            enabled: root.motionAllowed
                            NumberAnimation { duration: Tokens.flap; easing.type: Tokens.ease }
                        }
                    }

                    TapHandler {
                        enabled: !!(root.player && root.player.canSeek && root.length > 0)
                        cursorShape: Qt.PointingHandCursor
                        onTapped: eventPoint => {
                            const at = Math.max(0, Math.min(progressTrack.width, eventPoint.position.x));
                            root.player.position = root.length * at / Math.max(1, progressTrack.width);
                        }
                    }
                }

                Text {
                    visible: root.detailed
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    text: root.formatTime(root.position)
                    color: Tokens.role("onSecondaryContainer", Tokens.inkMuted)
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fTiny * root.s
                    font.features: ({ "tnum": 1 })
                }
                Text {
                    visible: root.detailed
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: root.formatTime(root.length)
                    color: Tokens.role("onSecondaryContainer", Tokens.inkMuted)
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fTiny * root.s
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }
}
