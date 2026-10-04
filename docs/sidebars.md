# Sidebars

Ryoku has one pair of compact corner panels, shared by every bar style and both
supported compositors:

- `Super+Escape` opens **Controls** in the top-left corner.
- `Super+S` opens **Today** in the top-right corner.

They open on the focused display and stay clear of its bar and other screen
rails. Opening either closes the other. Repeat the shortcut, press Escape, use
the close button, or click outside to dismiss the panel. They do not reserve
screen space or move windows.

## Controls

The header shows the user, time, uptime, and root-disk usage alongside a live
CPU, memory, and GPU graph. Wi-Fi and Bluetooth tiles open their device lists.
Volume and brightness have labelled sliders; the action row contains the audio
mixer, night light, keep awake, do-not-disturb, and microphone mute.

The mixer provides separate output-device, microphone, playback-app, and
recording-app controls. Each source has mute, a slider, an editable percentage,
and 1% steps. Changing a level preserves mute; **Use** selects a default device.

Lock, sleep, logout, restart, and power off sit in a separate bottom row. Session
confirmation uses the shell's existing confirmation dialog. The camera button
opens screenshot and recording controls. Gaming mode appears only when the
running provider supports it, or when it is already enabled.

## Today

The calendar anchors the left column. Current weather and the next hours sit
above the media player on the right, followed by today's activity and
notifications. Forecast and notification buttons open their detailed views.

**Tools**, **Chat**, and **View activity** open normal, resizable windows rather
than expanding the corner panel. Tools retains downloads, compression,
installation, and their file pickers. Chat uses the existing Rashin conversation
view; Activity shows the full usage history.

Installed `sidebarCard` plugins appear under the Extensions button on their
chosen side. Enable and place them in **Ryoku Hub > Add-ons**. The built-in panel
layout is fixed: there is no sidebar style, size, pinning, or contents editor.
Wallpaper, widget, and visualizer editing remains in **Ryoku Hub > Desktop Scene**.

## Rendering and lifecycle

`Sidebar.qml` owns a small layer-shell content window and a transparent
click-away window. Both use overlay-layer keyboard focus so clicks inside and
outside work consistently. Their namespaces are `ryoku-sidebar-left`,
`ryoku-sidebar-right`, and `ryoku-corner-dismiss`; their exclusive zone is zero.
The click-away input region excludes the panel and the display's rails.

Controls is 688 logical pixels wide and Today is 640 before per-display UI
scaling. Each fits its content and clamps to the space available on its display.
They share the current wallpaper palette and shell typography. Opening fades
and settles the panel from its top corner; reduced motion disables that animation.

The root shell asynchronously loads a panel on first use and unloads it after
its closing animation. Detailed pages load only when selected. Plugin discovery
and its file watches run only while the owning panel is active.

`SystemMonitor` and `SystemGraph`, in `Ryoku.Blobs`, own the native graph.
The monitor samples once per second on a worker thread and keeps a bounded
history. The scene graph animates those real samples in a 10–60 second window,
without QML Canvas or per-frame subprocesses. Unavailable metrics are not drawn
as fabricated zero readings. Sampling stops when inactive; graph frames stop
when inactive, hidden, unexposed, or reduced-motion animation is disabled.

## Commands and migration

`quicksettings` still routes to the left panel and `stash` to the right. These
are the compositor keybind commands, not layout choices. Screenshot requests
open Capture; compress and install requests open Tools on their file picker.

`SidebarState.qml` owns per-display open state, selected details, and utility
window routing. The shell daemon remains the only writer of persistent shell
settings. `ryoku doctor` removes the retired `sidebars` object and the old
`frameBars.menus.quick-settings` and `frameBars.surfaces.stash/system` records,
without changing neighbouring settings.

## Contributor map

All panel components below live under
`ryoku/shell/quickshell/shell/modules/sidebar/`:

| File | Responsibility |
|---|---|
| `Sidebar.qml` | Corner placement, screen bounds, input regions, and dismissal |
| `SidebarFrame.qml` | Shared palette-matched surface |
| `SidebarChrome.qml` | Header, navigation, and lazy board selection |
| `ControlsBoard.qml`, `ControlsHero.qml` | Controls layout and native graph presentation |
| `TodayBoard.qml`, `Today*.qml` | Calendar, weather, media, activity, and notifications |
| `CornerButton.qml`, `CornerConnection.qml`, `CornerSlider.qml` | Shared compact controls |
| `UtilityWindow.qml` | Normal window sizing and shared header |
| `ToolsWindow.qml`, `ChatWindow.qml`, `ActivityWindow.qml` | Full utility views |
| `cards/` | Reusable detail views and their controls |
| `ExtensionsBoard.qml`, `SidebarCardHost.qml`, `SidebarPlugins.qml` | Plugin discovery, ordering, and runtime contract |

The state owner is
`ryoku/shell/quickshell/shell/services/SidebarState.qml`. Native sampling and
rendering live in `ryoku/shell/plugin/systemmonitor.{hpp,cpp}` and
`ryoku/shell/plugin/systemgraph.{hpp,cpp}`. New built-in views belong in the
appropriate board or utility window; do not add another layout catalogue or
persist panel geometry.

Contributor plugins use the public
[`sidebarCard` contract](plugins.md#4-sidebar-card---lives-in-a-global-sidebar).
