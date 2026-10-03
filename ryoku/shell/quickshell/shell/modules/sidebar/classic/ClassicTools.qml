pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services
import "../../../components"
import "../cards" as Cards

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
    signal requestClose()
    signal pick(string mode)

    property string urlText: ""
    property bool setupOpen: false
    property bool pickerOpen: false
    property string pickerMode: "compress"
    property string lastPage: ""

    readonly property bool motionAllowed: !Motion.reduce && !Tokens.reduceMotion
    readonly property color ink: Theme.inkOn(Theme.effectiveSurface, Theme.onSurface)
    readonly property color dim: Theme.inkOn(Theme.effectiveSurface, Theme.onSurfaceVariant, 3.0)
    readonly property bool engineNeedsSetup: Stash.dockerState === "setup" || Stash.dockerState === "missing"
    readonly property string engineSub: {
        if (Stash.setupState === "running") return I18n.tr("Setting up…");
        if (Stash.dockerState === "missing") return I18n.tr("Needs Docker. `ryoku update` installs it");
        if (Stash.dockerState === "setup") return I18n.tr("One-time setup: flip the switch to run it");
        if (Stash.dockerState === "denied") return I18n.tr("Docker is unreachable and the ryoku-docker helper is missing");
        switch (Stash.cobaltState) {
        case "starting": return Stash.cobaltMsg === "pulling"
            ? I18n.tr("Downloading cobalt image — first launch takes a minute and uses some memory & CPU")
            : I18n.tr("Starting cobalt…");
        case "running": return I18n.tr("On — downloads run through your local cobalt");
        case "error": return Stash.cobaltMsg.length > 0 ? Stash.cobaltMsg : I18n.tr("Failed to start");
        default: return I18n.tr("Off — using yt-dlp");
        }
    }
    readonly property var modes: [
        { id: "auto", label: I18n.tr("Auto") },
        { id: "audio", label: I18n.tr("Audio") },
        { id: "mute", label: I18n.tr("Mute") }
    ]

    implicitHeight: root.pickerOpen || root.setupOpen
        ? Math.max(240 * root.s, Math.min(560 * root.s, root.viewportHeight > 0 ? root.viewportHeight : 560 * root.s))
        : col.implicitHeight + 24 * root.s

    function startDownload() {
        if (root.urlText.trim().length === 0)
            return;
        Stash.enqueueDownload(root.urlText, Stash.dlMode);
        root.urlText = "";
    }

    function fileGlyph(name) {
        const ext = String(name).toLowerCase().split(".").pop();
        if (/^(png|jpe?g|webp|gif|bmp|tiff?|avif)$/.test(ext)) return "image";
        if (/^(mp4|mkv|webm|mov|avi|m4v)$/.test(ext)) return "movie";
        if (/^(mp3|flac|wav|ogg|opus|m4a|aac)$/.test(ext)) return "music_note";
        if (/^(zip|tar|gz|xz|zst|bz2|7z|rar|tgz)$/.test(ext)) return "folder_zip";
        if (/^(appimage|deb|rpm|flatpak|pkg)$/.test(ext)) return "deployed_code";
        return "draft";
    }

    function openPicker(mode) {
        root.pickerMode = mode;
        root.pickerOpen = true;
        root.pick(mode);
    }

    function applyPage() {
        if (!root.tabActive || root.page === root.lastPage)
            return;
        root.lastPage = root.page;
        if (root.page === "compress" || root.page === "install")
            root.openPicker(root.page);
    }

    onPageChanged: root.applyPage()
    onTabActiveChanged: if (root.tabActive) root.applyPage()
    Component.onCompleted: root.applyPage()

    Column {
        id: col
        visible: !root.pickerOpen && !root.setupOpen
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 18 * root.s
        anchors.rightMargin: 18 * root.s
        anchors.topMargin: 16 * root.s
        spacing: 10 * root.s

        ClassicSection { width: parent.width; label: I18n.tr("Download") }

        Rectangle {
            width: parent.width
            radius: Theme.radiusWidget
            color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.05)
            implicitHeight: engineRow.implicitHeight + 16 * root.s

            Item {
                id: engineRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 9 * root.s
                anchors.rightMargin: 9 * root.s
                implicitHeight: Math.max(engineText.implicitHeight, 18 * root.s)

                Column {
                    id: engineText
                    anchors.left: parent.left
                    anchors.right: engineRight.left
                    anchors.rightMargin: 8 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1 * root.s

                    Text {
                        text: I18n.tr("Cobalt engine")
                        color: root.ink
                        font.family: Theme.fontPrimary
                        font.pixelSize: 10 * root.s
                        font.weight: Font.DemiBold
                    }
                    Text {
                        width: parent.width
                        text: root.engineSub
                        wrapMode: Text.WordWrap
                        color: Stash.cobaltState === "error" ? Theme.vermLit : root.dim
                        font.family: Theme.fontPrimary
                        font.pixelSize: 8 * root.s
                    }
                }

                Row {
                    id: engineRight
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7 * root.s

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Stash.cobaltState === "starting"
                        text: "progress_activity"
                        font.pixelSize: 13 * root.s
                        color: root.dim
                        RotationAnimation on rotation {
                            running: root.open && root.tabActive && Stash.cobaltState === "starting" && root.motionAllowed
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 900
                        }
                    }
                    LinkToggle {
                        id: engineSwitch
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.s
                        readonly property bool engineOn: Stash.cobaltState === "running" || Stash.cobaltState === "starting"
                        on: engineOn
                        enabled: Stash.setupState !== "running"
                        onToggled: {
                            if (engineSwitch.engineOn) {
                                Stash.setEngine(false);
                            } else if (root.engineNeedsSetup || Stash.dockerState === "unknown") {
                                root.setupOpen = true;
                                Stash.startSetup();
                            } else {
                                Stash.setEngine(true);
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 26 * root.s
            radius: Theme.radiusWidget
            color: Theme.surface
            border.width: Theme.borderWidth
            border.color: urlInput.activeFocus ? Theme.primary : Theme.outline
            Behavior on border.color {
                enabled: root.motionAllowed
                ColorAnimation { duration: Motion.fast }
            }
            SumiEdge { }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12 * root.s
                anchors.rightMargin: 12 * root.s
                spacing: 9 * root.s

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 13 * root.s
                    text: "link"
                    color: root.dim
                }
                TextInput {
                    id: urlInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 27 * root.s - parent.spacing
                    text: root.urlText
                    onTextChanged: root.urlText = text
                    color: root.ink
                    font.family: Theme.fontPrimary
                    font.pixelSize: 10.5 * root.s
                    clip: true
                    selectByMouse: true
                    onAccepted: root.startDownload()
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: urlInput.text.length === 0
                        text: I18n.tr("Paste a link to download")
                        color: root.dim
                        font: urlInput.font
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 6 * root.s
            readonly property real segW: (width - 2 * spacing) / 3

            Repeater {
                model: root.modes
                delegate: Rectangle {
                    id: modeButton
                    required property var modelData
                    readonly property bool selected: Stash.dlMode === modelData.id
                    width: parent.segW
                    height: 22 * root.s
                    radius: Theme.radiusWidget
                    color: selected ? Theme.primary : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.05)
                    border.width: 1
                    border.color: selected ? "transparent" : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                    Behavior on color {
                        enabled: root.motionAllowed
                        ColorAnimation { duration: Motion.fast }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modeButton.modelData.label
                        color: modeButton.selected ? Theme.inkOn(Theme.primary, Theme.onPrimary) : root.dim
                        font.family: Theme.fontPrimary
                        font.pixelSize: 9 * root.s
                        font.weight: modeButton.selected ? Font.DemiBold : Font.Normal
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Stash.dlMode = modeButton.modelData.id
                    }
                }
            }
        }

        ClassicActionButton {
            width: parent.width
            label: I18n.tr("Download")
            icon: "download"
            primary: root.urlText.trim().length > 0
            enabled: root.urlText.trim().length > 0
            onTapped: root.startDownload()
        }

        Rectangle {
            width: parent.width
            visible: !root.compact
            radius: Theme.radiusWidget
            color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.04)
            border.width: Theme.borderWidth
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
            implicitHeight: sitesCol.implicitHeight + 18 * root.s

            Column {
                id: sitesCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 9 * root.s
                spacing: 4 * root.s
                Row {
                    spacing: 5 * root.s
                    MaterialIcon { anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 10 * root.s; text: "public"; color: root.dim }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Stash.cobaltState === "running"
                            ? I18n.tr("WORKS WITH %1 SITES").arg(Stash.supportedSites.length)
                            : I18n.tr("POWERED BY YT-DLP")
                        color: root.dim
                        font.family: Theme.fontPrimary
                        font.pixelSize: 6.5 * root.s
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.5
                    }
                }
                Text {
                    width: parent.width
                    text: Stash.cobaltState === "running"
                        ? Stash.supportedSites.map(site => site === "twitter" ? "x" : site).join("  ·  ")
                        : I18n.tr("Works with 1000+ sites, including YouTube, Twitter/X, Reddit, TikTok, and more.")
                    wrapMode: Text.WordWrap
                    color: root.ink
                    font.family: Theme.mono
                    font.pixelSize: 8.5 * root.s
                    lineHeight: 1.3
                }
            }
        }

        Column {
            width: parent.width
            spacing: 6 * root.s
            visible: Stash.queueModel.count > 0
            Repeater {
                model: Stash.queueModel
                delegate: Rectangle {
                    id: queueRow
                    required property var model
                    required property int index
                    width: parent.width
                    implicitHeight: queueBody.implicitHeight + 12 * root.s
                    radius: Theme.radiusWidget
                    color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.05)
                    Column {
                        id: queueBody
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6 * root.s
                        spacing: 5 * root.s
                        Item {
                            width: parent.width
                            height: queueName.implicitHeight
                            Text {
                                id: queueName
                                anchors.left: parent.left
                                anchors.right: queueActions.left
                                anchors.rightMargin: 8 * root.s
                                text: queueRow.model.name && queueRow.model.name.length > 0 ? queueRow.model.name : queueRow.model.arg
                                elide: Text.ElideMiddle
                                color: root.ink
                                font.family: Theme.fontPrimary
                                font.pixelSize: 9 * root.s
                            }
                            Row {
                                id: queueActions
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 7 * root.s
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: queueRow.model.state === "running" ? queueRow.model.pct + "%"
                                        : queueRow.model.state === "error" ? (queueRow.model.msg && queueRow.model.msg.length > 0 ? queueRow.model.msg : I18n.tr("failed"))
                                        : queueRow.model.state === "done" ? I18n.tr("done")
                                        : queueRow.model.state === "queued" ? I18n.tr("queued") : queueRow.model.state
                                    color: queueRow.model.state === "error" ? Theme.vermLit : root.dim
                                    font.family: Theme.mono
                                    font.pixelSize: 8 * root.s
                                }
                                MaterialIcon {
                                    visible: queueRow.model.state === "error"
                                    text: "refresh"
                                    font.pixelSize: 12 * root.s
                                    color: root.dim
                                    MouseArea { anchors.fill: parent; anchors.margins: -6 * root.s; cursorShape: Qt.PointingHandCursor; onClicked: Stash.retryJob(queueRow.index) }
                                }
                                MaterialIcon {
                                    visible: queueRow.model.state === "queued" || queueRow.model.state === "done" || queueRow.model.state === "error"
                                    text: "close"
                                    font.pixelSize: 12 * root.s
                                    color: root.dim
                                    MouseArea { anchors.fill: parent; anchors.margins: -6 * root.s; cursorShape: Qt.PointingHandCursor; onClicked: Stash.dismissJob(queueRow.index) }
                                }
                            }
                        }
                        Rectangle {
                            visible: queueRow.model.state === "running" || queueRow.model.state === "queued"
                            width: parent.width
                            height: 2
                            radius: 1
                            color: Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.1)
                            Rectangle {
                                height: parent.height
                                radius: 1
                                width: parent.width * Math.max(0, Math.min(1, (queueRow.model.pct || 0) / 100))
                                color: Theme.primary
                                Behavior on width {
                                    enabled: root.motionAllowed
                                    NumberAnimation { duration: Motion.fast }
                                }
                            }
                        }
                    }
                }
            }
        }

        ClassicSection { width: parent.width; visible: !root.compact; label: I18n.tr("Recently downloaded") }

        Text {
            width: parent.width
            visible: !root.compact && Stash.count === 0
            text: I18n.tr("Nothing downloaded yet. Links you grab land here.")
            wrapMode: Text.WordWrap
            color: root.dim
            font.family: Theme.fontPrimary
            font.pixelSize: 9 * root.s
        }

        Column {
            width: parent.width
            visible: !root.compact
            spacing: 6 * root.s
            Repeater {
                model: Stash.recentFiles
                delegate: Rectangle {
                    id: fileRow
                    required property var modelData
                    width: parent.width
                    height: 24 * root.s
                    radius: Theme.radiusWidget
                    color: fileHover.containsMouse
                        ? Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.08)
                        : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.04)
                    Behavior on color {
                        enabled: root.motionAllowed
                        ColorAnimation { duration: Motion.fast }
                    }
                    MouseArea {
                        id: fileHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Stash.openFile(fileRow.modelData.path)
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.right: removeButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12 * root.s
                        anchors.rightMargin: 6 * root.s
                        spacing: 10 * root.s
                        MaterialIcon { anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13 * root.s; text: root.fileGlyph(fileRow.modelData.name); color: root.dim }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 28 * root.s - parent.spacing
                            text: fileRow.modelData.name
                            elide: Text.ElideMiddle
                            color: root.ink
                            font.family: Theme.fontPrimary
                            font.pixelSize: 9 * root.s
                        }
                    }
                    MaterialIcon {
                        id: removeButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 10 * root.s
                        font.pixelSize: 13 * root.s
                        text: "close"
                        color: root.dim
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8 * root.s
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                mouse.accepted = true;
                                Stash.removeFile(fileRow.modelData.path);
                            }
                        }
                    }
                }
            }
        }

        ClassicSection { width: parent.width; label: I18n.tr("Convert & install") }
        ClassicActionButton { width: parent.width; label: I18n.tr("Compress video…"); icon: "compress"; onTapped: root.openPicker("compress") }
        ClassicActionButton { width: parent.width; label: I18n.tr("Install app…"); icon: "install_desktop"; onTapped: root.openPicker("install") }
        Item { width: 1; height: 6 * root.s }
    }

    Cards.FilePickerOverlay {
        anchors.fill: parent
        s: root.s
        open: root.pickerOpen
        mode: root.pickerMode
        onCancelled: root.pickerOpen = false
        onConfirmed: paths => {
            if (root.pickerMode === "install")
                Stash.install(paths);
            else
                Stash.compress(paths);
            root.pickerOpen = false;
        }
    }

    Cards.CobaltSetupOverlay {
        anchors.fill: parent
        s: root.s
        open: root.setupOpen
        onClosed: root.setupOpen = false
    }

    component ClassicSection: Text {
        property string label: ""
        text: label.toUpperCase()
        color: root.dim
        font.family: Theme.fontPrimary
        font.pixelSize: 6.5 * root.s
        font.weight: Font.DemiBold
        font.letterSpacing: 2
        topPadding: 2 * root.s
    }

    component ClassicActionButton: Item {
        id: actionButton
        property string label: ""
        property string icon: ""
        property bool primary: false
        signal tapped()

        implicitHeight: 24 * root.s
        opacity: enabled ? 1 : 0.4
        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusWidget
            color: actionButton.primary ? Theme.primary
                : actionArea.containsMouse ? Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.08)
                : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.04)
            border.width: actionButton.primary ? 0 : Theme.borderWidth
            border.color: Theme.outline
            Behavior on color {
                enabled: root.motionAllowed
                ColorAnimation { duration: Motion.fast }
            }
            SumiEdge { visible: actionButton.primary }
            Row {
                anchors.centerIn: parent
                spacing: 8 * root.s
                MaterialIcon {
                    visible: actionButton.icon.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 13 * root.s
                    text: actionButton.icon
                    color: actionButton.primary ? Theme.inkOn(Theme.primary, Theme.onPrimary) : root.ink
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: actionButton.label
                    color: actionButton.primary ? Theme.inkOn(Theme.primary, Theme.onPrimary) : root.ink
                    font.family: Theme.fontPrimary
                    font.pixelSize: 9 * root.s
                    font.weight: Font.DemiBold
                }
            }
        }
        scale: actionArea.pressed && enabled && root.motionAllowed ? 0.97 : 1
        Behavior on scale {
            enabled: root.motionAllowed
            NumberAnimation { duration: Motion.fast }
        }
        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionButton.tapped()
        }
    }
}
