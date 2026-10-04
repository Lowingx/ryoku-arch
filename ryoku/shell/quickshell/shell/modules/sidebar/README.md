# Sidebar module

- `Sidebar.qml` owns both screen-edge overlays, screen bounds, input regions,
  and outside-click dismissal.
- `SidebarFrame.qml` draws the shared boundary with the selected Modern or
  Classic theme treatment.
- `SidebarChrome.qml` selects the layout's chrome and owns section navigation,
  the shared content viewport, and the Customize in Hub action.
- Sidebar customization lives in
  `ryoku/hub/quickshell/pages/SidebarsPage.qml`; `SidebarWriter.qml` waits for
  the daemon reply and settings-frame confirmation before accepting a save.
- `SidebarButton.qml`, `SidebarToggle.qml`, and `SidebarSegments.qml` provide
  the sidebar's labelled interaction controls.
- `SidebarCatalog.js` registers the nine built-in sections.
- `SidebarCardHost.qml` loads built-ins and plugins and binds their runtime
  contract. Plugin `compact` and `viewportHeight` properties are optional.
  Built-ins load their catalog `source` for Modern or `classicSource` for Classic.
- `SidebarCardShell.qml` is the built-in heading and content-layout scaffold;
  it does not paint an outer plate.
- `ryoku/shell/framebars/Sidebars.js` normalizes the persisted settings through
  the shared `Ryoku.FrameBars.Sidebars` module.
- `SidebarPlugins.qml` discovers installed `sidebarCard` plugins.
- `cards/` contains the Modern built-in views and shared detail pages.
- `classic/` restores the original compact built-in views, reusing the same
  services and Wi-Fi, Bluetooth, and per-source audio detail pages.

To add a built-in section, create its Modern view in `cards/` and its Classic
view in `classic/`. Declare the host properties and `requestClose()` signal,
then register both sources in `SidebarCatalog.js`. Add its id to
`ryoku/shell/framebars/Sidebars.js` defaults only when it should ship selected.

Contributor plugins use the `sidebarCard` host documented in
[`docs/plugins.md`](../../../../../../docs/plugins.md#4-sidebar-card---lives-in-a-global-sidebar).
