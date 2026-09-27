pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import Qt.labs.folderlistmodel
import inir.modules.common
import inir.modules.common.functions
import inir.services
import shell.services as Ryoku

// Wallpaper bridge for the vendored frame. Ryoku owns wallpaper application
// (the wallpaper daemon plus ryogami); this exposes the reference's read-side
// surface — the effective path, an image-safe still URL, the gallery scan and
// the freedesktop-style thumbnail cache — so the frame's glass, mood and
// preview consumers keep working without ever driving a second wallpaper
// backend. Apply/preview verbs are intentionally absent: the frame never
// changes the wallpaper, it only samples it.
Singleton {
    id: root

    // The active wallpaper file, straight from the daemon's state.
    readonly property string effectiveWallpaperPath: FileUtils.trimFileProtocol(Ryoku.Session.wallpaper)
    readonly property string effectiveWallpaperUrl: root.stillUrlFor(root.effectiveWallpaperPath)

    // Ryoku themes from the same file the desktop wears.
    function currentThemingWallpaperPath(monitorName = ""): string {
        return root.effectiveWallpaperPath
    }

    function currentMainWallpaperPath(monitorName = ""): string {
        return root.effectiveWallpaperPath
    }

    function isVideoFile(path: string): bool {
        const lower = String(path ?? "").toLowerCase()
        return lower.endsWith(".mp4") || lower.endsWith(".webm") || lower.endsWith(".mkv") || lower.endsWith(".mov") || lower.endsWith(".avi")
    }

    // ── Video stills ───────────────────────────────────────────────────────
    // The daemon already extracts a live poster for every clip; reuse it as the
    // image-safe still so glass surfaces sample exactly what the desktop shows.
    readonly property string livePoster: Ryoku.Session.livePoster
    property var videoFirstFrames: ({})

    function stillUrlFor(path: string): string {
        const clean = FileUtils.trimFileProtocol(String(path ?? ""))
        if (!clean)
            return ""
        if (!root.isVideoFile(clean))
            return "file://" + clean
        if (clean === root.effectiveWallpaperPath && root._fileExists(root.livePoster))
            return "file://" + root.livePoster
        const frame = root.videoFirstFrames[clean]
        if (frame)
            return frame.startsWith("file://") ? frame : "file://" + frame
        root.ensureVideoFirstFrame(clean)
        return ""
    }

    function internalPreviewFor(monitorName: string, fallbackPath: string): string {
        return fallbackPath
    }

    readonly property bool internalPreviewActive: false
    readonly property bool batteryPauseActive: false

    function videoMotionAllowedOn(outputName: string): bool {
        return true
    }

    // ── First-frame extraction ─────────────────────────────────────────────
    readonly property string _videoThumbDir: (Quickshell.env("XDG_CACHE_HOME")
        || (Quickshell.env("HOME") + "/.cache")) + "/ryoku/inir/video_thumbnails"

    function getVideoFirstFramePath(videoPath: string): string {
        const clean = FileUtils.trimFileProtocol(String(videoPath ?? ""))
        return root._videoThumbDir + "/" + Qt.md5(clean) + ".jpg"
    }

    function ensureVideoFirstFrame(videoPath: string): void {
        const clean = FileUtils.trimFileProtocol(String(videoPath ?? ""))
        if (!clean || !root.isVideoFile(clean))
            return
        const out = root.getVideoFirstFramePath(clean)
        if (root.videoFirstFrames[clean] || root._fileExists(out)) {
            root.videoFirstFrames = Object.assign({}, root.videoFirstFrames, { [clean]: out })
            return
        }
        if (root._ffPending[clean])
            return
        root._ffPending[clean] = true
        root._ffQueue = root._ffQueue.concat([{ video: clean, out: out }])
        root._processNextFF()
    }

    property var _ffPending: ({})
    property var _ffQueue: []

    function _processNextFF(): void {
        if (root._ffProc.running || root._ffQueue.length === 0)
            return
        const job = root._ffQueue[0]
        root._ffQueue = root._ffQueue.slice(1)
        root._ffProc.videoPath = job.video
        root._ffProc.outputPath = job.out
        root._ffProc.running = true
    }

    Process {
        id: _ffProc
        property string videoPath: ""
        property string outputPath: ""
        command: ["ffmpeg", "-y", "-i", videoPath, "-vf",
            "scale='min(1920,iw)':-2", "-frames:v", "1", outputPath]
        onExited: exitCode => {
            delete root._ffPending[root._ffProc.videoPath]
            if (exitCode === 0) {
                root.videoFirstFrames = Object.assign({}, root.videoFirstFrames,
                    { [root._ffProc.videoPath]: root._ffProc.outputPath })
            }
            root._processNextFF()
        }
    }

    function _fileExists(path: string): bool {
        if (!path)
            return false
        return Quickshell.fileExists(FileUtils.trimFileProtocol(path))
    }

    // ── Gallery scan ───────────────────────────────────────────────────────
    // The wallpaper directory ryogami browses; the frame's preview gallery
    // cycles through it read-only.
    readonly property string galleryDirectory: (Quickshell.env("XDG_PICTURES_DIR")
        || (Quickshell.env("HOME") + "/Pictures")) + "/Wallpapers"
    property list<string> wallpapers: []

    FolderListModel {
        id: folderModel
        folder: Qt.resolvedUrl("file://" + root.galleryDirectory)
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.avif", "*.bmp", "*.gif", "*.mp4", "*.webm", "*.mkv", "*.mov"]
        showDirs: false
        onCountChanged: root._rescan()
        onStatusChanged: if (status === FolderListModel.Ready) root._rescan()
    }

    function _rescan(): void {
        if (folderModel.status !== FolderListModel.Ready)
            return
        const out = []
        for (let i = 0; i < folderModel.count; i++) {
            const p = folderModel.get(i, "filePath")
                || FileUtils.trimFileProtocol(folderModel.get(i, "fileURL"))
            if (p)
                out.push(p)
        }
        root.wallpapers = out
    }

    Component.onCompleted: root._rescan()

    // ── Thumbnails (freedesktop cache) ─────────────────────────────────────
    // A tiny in-memory set so list delegates can fall back to the full-size
    // file when no cached thumbnail exists yet.
    property var _knownThumbnails: ({})
    readonly property bool thumbnailGenerationRunning: false

    function videoStillPath(filePath: string): string {
        return root.getVideoFirstFramePath(filePath)
    }

    function ensureVideoStill(filePath: string): void {
        root.ensureVideoFirstFrame(filePath)
    }

    function hasKnownThumbnail(path: string): bool {
        return root._knownThumbnails[FileUtils.trimFileProtocol(String(path ?? ""))] === true
    }

    function rememberThumbnail(path: string): void {
        const clean = FileUtils.trimFileProtocol(String(path ?? ""))
        if (!clean)
            return
        const next = Object.assign({}, root._knownThumbnails)
        next[clean] = true
        root._knownThumbnails = next
    }

    function forgetThumbnail(path: string): void {
        const clean = FileUtils.trimFileProtocol(String(path ?? ""))
        const next = Object.assign({}, root._knownThumbnails)
        delete next[clean]
        root._knownThumbnails = next
    }

    function ensureThumbnailForPath(filePath: string, size = "large"): void {
        // Thumbnails are a nicety; the frame reads full-size images otherwise.
    }
}
