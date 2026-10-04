# Sidebar module

Controls and Today are compact top-corner panels shared by all bar styles.

- `Sidebar.qml` owns placement, the small content window, and click-away input.
- `SidebarFrame.qml` and `SidebarChrome.qml` provide the shared surface and header.
- `ControlsBoard.qml` arranges connectivity, sliders, actions, and detail pages;
  `ControlsHero.qml` presents the native `SystemMonitor` and `SystemGraph`.
- `TodayBoard.qml` arranges the calendar, weather, media, activity, and notices.
- `CornerButton.qml`, `CornerConnection.qml`, and `CornerSlider.qml` are the
  shared compact controls.
- `UtilityWindow.qml` supplies normal-window chrome for Tools, Chat, and Activity.
- `cards/` contains their reusable full views and the panels' detail pages.
- `ExtensionsBoard.qml` uses `SidebarCardHost.qml` for installed plugins;
  `SidebarPlugins.qml` discovers and orders them while the panel is open.
- `shell/services/SidebarState.qml` owns per-display state and surface routing.

The root shell loads panels asynchronously and unloads them after closing.
Keep live work gated by the owning surface's active state. Built-in layout is
fixed; do not add style variants or sidebar settings to Hub.

See [`docs/sidebars.md`](../../../../../../docs/sidebars.md) for behavior and the
[`sidebarCard` contract](../../../../../../docs/plugins.md#4-sidebar-card---lives-in-a-global-sidebar)
for contributor plugins. Plugin placement remains in Hub's Add-ons page.
