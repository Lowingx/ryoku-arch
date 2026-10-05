import QtQuick
import QtQuick.Controls
import RashinApp

// The vault page: the knowledge base every agent reads and writes, browsed
// as a grouped tree with a rendered reader. The daemon owns the files; this
// page only asks for them (GET /api/vault, GET /api/vault/file?p=) and paints
// what comes back. The reindex button asks the daemon to rebuild the maps.
Item {
    id: page

    property var tree: []
    property string selected: ""
    property string markdown: ""
    property bool loading: false

    // The groups the vault's files fall into, in reading order; anything
    // ungrouped lands in Maps.
    readonly property var groups: [
        { name: qsTr("Maps"), match: ["AGENTS.md", "CLAUDE.md", "system.md", "desktop.md", "packages.md", "ryoku-repo.md", "user.md", "habits.md", "ownership.md", "logs.md"] },
        { name: qsTr("Memory"), match: ["memory/"] },
        { name: qsTr("Journal"), match: ["journal/"] }
    ]

    Connections {
        target: DaemonClient
        function onReply(path, ok, value) {
            if (path === "/api/vault" && ok) {
                page.tree = value["files"] || [];
                if (page.selected.length === 0 && page.tree.length > 0)
                    page.openFile(String(page.tree[0].path || ""));
            } else if (path.startsWith("/api/vault/file") && ok) {
                page.markdown = String(value["text"] || "");
                page.loading = false;
            } else if (path.startsWith("/api/vault/file")) {
                page.markdown = "";
                page.loading = false;
            }
        }
    }

    function openFile(p) {
        page.selected = p;
        page.loading = true;
        DaemonClient.get("/api/vault/file?p=" + encodeURIComponent(p));
    }

    function grouped(path) {
        for (const g of groups)
            for (const m of g.match)
                if (path.startsWith(m) || path === m)
                    return g.name;
        return qsTr("Maps");
    }

    // A flat, sectioned list model: [{header}, {file}, ...]
    readonly property var rows: {
        const out = [];
        let lastGroup = "";
        const sorted = page.tree.slice().sort((a, b) => String(a.path).localeCompare(String(b.path)));
        for (const f of sorted) {
            const g = grouped(String(f.path || ""));
            if (g !== lastGroup) {
                out.push({ header: g });
                lastGroup = g;
            }
            out.push({ file: f });
        }
        return out;
    }

    Component.onCompleted: DaemonClient.get("/api/vault")

    Row {
        anchors.fill: parent
        spacing: 0

        // The tree.
        Rectangle {
            width: 280
            height: parent.height
            color: Theme.surfaceLow
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.line }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.s3
                spacing: Theme.s2
                Row {
                    width: parent.width
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("VAULT")
                        color: Theme.inkMuted
                        font.family: Theme.mono
                        font.pixelSize: Theme.fMicroPx
                        font.letterSpacing: Theme.trackMark
                    }
                    Item { width: parent.width - 100; height: 1 }
                    IconBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "refresh"
                        size: 24
                        onAct: {
                            DaemonClient.post("/api/index");
                            reindexTimer.restart();
                        }
                    }
                }
                Text {
                    visible: DaemonClient.online && page.tree.length === 0
                    text: qsTr("The vault is empty. Run `ryoku-rashin index`.")
                    wrapMode: Text.WordWrap
                    width: parent.width
                    color: Theme.inkFaint
                    font.family: Theme.ui
                    font.pixelSize: Theme.fTinyPx
                }
            }

            Timer {
                id: reindexTimer
                interval: 4000
                onTriggered: DaemonClient.get("/api/vault")
            }

            ListView {
                id: treeList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 64
                anchors.bottom: parent.bottom
                anchors.margins: Theme.s2
                clip: true
                model: page.rows
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Item {
                    required property var modelData
                    width: treeList.width
                    height: 34
                    Text {
                        visible: Boolean(modelData.header)
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.s2
                        text: modelData.header || ""
                        color: Theme.inkFaint
                        font.family: Theme.mono
                        font.pixelSize: Theme.fMicroPx
                        font.letterSpacing: Theme.trackLabel
                    }
                    Rectangle {
                        visible: !modelData.header
                        anchors.fill: parent
                        radius: Theme.radiusSm
                        readonly property bool current: page.selected === String(modelData.file?.path || "")
                        color: current ? Theme.tint16 : fileHover.hovered ? Theme.tint5 : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.snap } }
                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.s2
                            spacing: Theme.s2
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.file?.generated ? "auto_fix_high" : "description"
                                color: Theme.inkFaint
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: Theme.fTinyPx
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(modelData.file?.path || "")
                                color: Theme.inkDim
                                font.family: Theme.mono
                                font.pixelSize: Theme.fTinyPx
                                width: 200
                                elide: Text.ElideMiddle
                            }
                        }
                        HoverHandler { id: fileHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: page.openFile(String(modelData.file?.path || "")) }
                    }
                }
            }
        }

        // The reader.
        Flickable {
            width: parent.width - 280
            height: parent.height
            contentHeight: reader.implicitHeight + Theme.s6 * 2
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: reader
                x: Theme.s6
                width: parent.width - Theme.s6 * 2
                spacing: Theme.s3

                Item { width: 1; height: Theme.s4 }

                Row {
                    width: parent.width
                    spacing: Theme.s2
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.selected
                        color: Theme.ink
                        font.family: Theme.mono
                        font.pixelSize: Theme.fSmallPx
                        width: parent.width - copyBtn.width - parent.spacing
                        elide: Text.ElideMiddle
                    }
                    IconBtn {
                        id: copyBtn
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "content_copy"
                        size: 24
                        onAct: Clipboard.copy(page.markdown)
                    }
                }

                Text {
                    visible: page.loading
                    text: qsTr("loading…")
                    color: Theme.inkFaint
                    font.family: Theme.ui
                    font.pixelSize: Theme.fSmallPx
                }

                TextEdit {
                    width: parent.width
                    textFormat: Text.RichText
                    text: Markdown.toHtml(page.markdown)
                    color: Theme.inkDim
                    font.family: Theme.ui
                    font.pixelSize: Theme.fBodyPx
                    wrapMode: Text.Wrap
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }
    }

    OfflineNotice { anchors.centerIn: parent; visible: !DaemonClient.online }
}
