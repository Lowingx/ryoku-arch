# Ryostage (舞台)

The desktop as a stage: the wallpaper is the backdrop, the subject and any
extra cut-outs are the layers, and the clock, widgets and the audio
visualizer are the cast, arranged in front of or behind them. Depth and
Parallax used to be two features with two engines, two settings files, two
sidebar tabs and two artifact folders. They are one thing: **Depth is a
stage with a single still layer in front of the widgets; Parallax is the
same stage with motion on.** Ryostage is that one thing.

Names, so the parts are findable:

| Part | Name | Where |
|---|---|---|
| The feature and settings page | **Stage** (Desktop Scene in Hub) | `quickshell/shell/modules/stage/`, `ryoku/hub/quickshell/pages/DesktopScenePage.qml` |
| The cut-out engine helper | **`ryostage`** | `ryoku/shell/scripts/ryostage`, shipped to `/usr/bin` |
| The daemon module | `stage` topic and verbs | `ryoku/shell/ipc/stage.go` |
| The settings | `~/.config/ryoku/stage.json` | user-owned, GUI-managed, never materialized |
| Per-wallpaper scene state | `~/.local/state/ryoku/stage-walls.json` | daemon-owned |
| Artifacts | `~/Pictures/Stage/<stem>/` | the user's files, one folder per wallpaper |
| Engine runtime and models | `~/.local/state/ryoku/ryostage/` | one venv, one model cache |

The two retired engine helpers (the old Depth and Parallax segmentation
scripts), `depth.json`, `parallax.json`, `depth-walls.json`, `~/Pictures/Depth`,
`~/Pictures/Parallax` and the `depth`/`parallax` tabs are retired; the doctor
migrates all of them (below).

## The mental model a user needs

One feature: **Depth**. It lifts the wallpaper's subject in front of your
widgets. **Parallax** is a switch inside Depth: the same cut, the same look,
now drifting with the pointer over an inpainted backdrop. Nothing is configured
twice.

Three places, each with one job:

- **The sidebar's Stage section** shows the current wallpaper, scene mode,
  enabled widgets, and visualizer state. Its buttons open the matching editor
  or Hub view rather than duplicating their controls.
- **Ryoku Hub > Desktop Scene** remains the settings view and owns the file
  picker used to add a layer from a picture. Its Stage Editor hand-offs open
  the exact catalogue they name.
- **The desktop** has one visible way into composition. Right-click bare
  wallpaper and choose **Edit desktop** to open the Stage Editor on that
  monitor. Widget menus remain local to the widget.

The Stage Editor is the shell's one desktop editor. The bar, dock, lockscreen
and menus keep their Hub pages.

## The desktop right-click menu

The quick row contains **Wallpaper** and **Search**. The single accent row,
**Edit desktop**, opens the Stage Editor on the monitor whose desktop was
clicked. Quick controls opens the left sidebar, Settings opens Hub, and Reload
shell reloads the shell.

Plain, Depth, and Parallax are chosen from the Stage Editor's Depth catalogue
or Hub's Scene view:

- Plain: `set-effect off`.
- Depth: `set-effect depth`.
- Parallax: `set-effect parallax`.

Depth and Parallax use the same cut-outs. The first enable cuts the current
wallpaper if necessary; progress and Stop stay visible while the engine runs.

## Hub settings

Open **Ryoku Hub > Desktop Scene** for the Scene, Visualizer, and Widgets views.
The page uses two columns when there is room and one on smaller windows, with a
scrolling viewport beneath the view selector.

### Scene

- **Preview and mode:** the current wallpaper and Plain, Depth, or Parallax.
  A running cut shows progress and a Stop button.
- **Cut and layers:** Draft, Standard, or Fine quality; selecting a different
  tier offers Download if its model is missing, then Re-cut. Layers can be
  placed behind or in front of widgets; Parallax adds a drift control.
  Cut a picture and Add a PNG add layers. Clear cut-outs asks for confirmation.
- **Look:** edge softness, shadow strength, and shadow direction. Reset look
  and motion restores those controls and motion settings, not cut quality,
  widget layer placement, or the editor grid.
- **Motion** (Parallax): Soft, Cinematic, or Beat presets; Subtle, Normal, or
  Strong amount; Still, Float, Breathe, or Sway idle motion with an idle-speed
  slider when moving; music response and pointer controls.
- **Composition:** the Stage Editor hand-off opens its Depth catalogue. The
  Depth catalogue's **Add a layer from a picture** row hands back to this Hub
  page because Hub owns the file picker.

### Visualizer and Widgets

Visualizer opens the Stage Editor on the **Visualizer** catalogue. Widgets
opens it on **Widgets**. A successful hand-off closes Hub only after the shell
accepts the request; a failed hand-off leaves the page open with its error.

Hub reads the stores but is not their writer. Typed shell IPC updates the
canonical stage and visualizer settings; wallpaper effects and layers use the
daemon's stage commands.

## The Stage Editor

Editing the desktop frames one live monitor at a time. The desktop shrinks into
a rounded card while its live wallpaper is blurred and dimmed around it, with a
soft shadow lifting the card from the surround. `EditModeCard.qml` supplies
that treatment and `Desktop.qml` mounts it around the real wallpaper, stage,
widgets, desktop icons, and editor frames. The chrome follows ryogami's visual
language: 6 px corners, 1 px outlines, and inverted plates for selected rows.

The toolbar is **Desktop** (with the current monitor) | **Widgets** |
**Wallpaper** | **Style** | **Visualizer** | **Depth**, followed by snap,
undo, redo, and **Done**. Visualizer and Depth come from
`StageWidgetProvider.extraSections`; the provider passes them to the island
`Config.extraSections`, and `StageSheet` hosts `StageVisualizerPage` or
`StageDepthPage`. There is no lockscreen, bar, or dock editing in this mode.

Every enabled widget wears a frame with its name, Settings, and Remove. Drag a
widget to move it and use its corner grip to resize it. Shift-click or
Ctrl-click builds a selection; dragging a marquee on bare wallpaper can select
widgets and desktop icons. A selected group moves together. Arrow keys nudge
one step, or ten steps while Shift is held. Delete removes the selection.
Ctrl+A selects all, Ctrl+Z undoes, Ctrl+Shift+Z or Ctrl+Y redoes, and Ctrl+F
focuses catalogue search. An align bar appears for two or more widgets.

A widget's editor menu has a **Size** stepper from 50% to 200% and **Reset
size**. Duplicate is not offered because Ryoku desktop widgets are
single-instance.

There is no Save and no global Reset. The live desktop is the document, and
each catalogue edit, group move, nudge, alignment, wallpaper framing change,
style change, add, remove, resize, and scale joins the same undo stack. Done
leaves the editor. Escape closes the open panel, clears the selection, then
leaves the session one level at a time. A bare-wallpaper gesture starts a
selection marquee rather than closing the editor.

### Wallpaper

The Wallpaper catalogue shows ryogami's library and thumbnails. A per-screen
pick goes through `ryoku-stage-wallpaper --screen`, so ryogami remains the
wallpaper owner. On the card, drag to move the real wallpaper, use the wheel or
a pinch to zoom, and use the catalogue controls to rotate, mirror, centre, or
reset it. Framing is stored per monitor and wallpaper path in
`~/.config/ryoku/stage/stage-editor.json`, so returning to a picture restores
its framing.

### Style

Style switches light or dark mode and the colour scheme. It can save the
current wallpaper, mode, and scheme as a preset, then apply, rename, or delete
that preset. Presets live in
`~/.config/ryoku/stage/style-presets.json`.

### Desktop icons

The Widgets catalogue includes **Add apps to desktop** and **Desktop icons**.
Apps and files placed on the desktop are stored per output in
`~/.local/state/states.json` under `desktopShortcutsJson`. Their work area
keeps them clear of Ryoku's bar, frame, and dock.

### Per-display widgets

`widgets.json` keeps its existing top-level widget keys as the fallback and
adds output-keyed layout overrides under `monitors`:

```json
{
  "clockEnabled": true,
  "clockX": 72,
  "monitors": {
    "eDP-1": {
      "clockEnabled": true,
      "clockAnchor": "free",
      "clockX": 40,
      "clockY": 64,
      "clockScale": 1.15,
      "clockLocked": false
    }
  }
}
```

An output with no override reads the top-level keys exactly as before. Its
first Stage Editor layout change forks the effective enabled, anchor,
position, size, scale, and lock values into that output's map. Later layout
edits and undo or redo write only that fork. Designs, colours, time format,
face options, and other appearance settings stay global.

### Depth catalogue

The Depth catalogue has five tabs:

- **Cut:** Plain, Depth, or Parallax; Draft, Standard, or Fine; Download the
  model, Stop cutting, Re-cut, and a confirmed Clear cut-outs.
- **Layers:** show or hide each layer, put it behind or in front, adjust its
  distance, or remove added layers.
- **Look:** edge softness, shadow, shadow direction, and reset.
- **Parallax:** Use Parallax, amount, idle motion, speed, music, pointer,
  sensitivity, range, and backdrop drift.
- **In front:** choose which enabled widgets rise over the front cut-outs.

Adding a layer from a picture opens **Ryoku Hub > Desktop Scene**, where the
file picker lives.

## The visualizer in the Stage Editor

Visualizer is a provider catalogue on `StageSheet` with **Look**, **Place**,
**Colour**, **Playback**, **Shape**, and **Field** tabs. Place exposes width,
height, across, down, and turn, plus Centre, Square, Full width, Top, Middle,
and Bottom actions. These controls are undoable like direct gestures.

The live look is a framed widget on the card. Drag it to move, use the corner
grip or Ctrl+wheel to size it, and use the top handle to turn it. The Field
look fills the screen and is tuned from the same catalogue. `visualizer place`
and `Super+Alt+M` turn the visualizer on when necessary and open this catalogue
with the look selected.

## Session model

`modules/stage/Singletons/StageSession.qml` owns one edit session. `mode` is
`""` or `"widgets"`; `monitor` names the framed output; `selection` is the
ordered set of selected widget ids and `selected` is its primary, final member;
`panel` names the open toolbar panel; and `section` is the catalogue path.
`StageEditorHost.showSection()` splits paths such as `wallpaper/wallpapers`
into the drawer section and page.

The IPC entry point is:

```
qs -c shell ipc call desktop editSection <section>[/<page>] [monitor]
```

It opens the editor on catalogues such as `visualizer`, `depth`, `wallpaper`,
or `wallpaper/wallpapers`, using the focused monitor when none is supplied.
`editWidgets` is an alias for `editSection widgets`. The `visualizer place`
command and `Super+Alt+M` use the same session path with section
`visualizer`. When the editor is already open on that monitor, another request
switches its catalogue in place.

Entering the session opens the chrome through `StageEditorHost`; leaving either
side closes the other. `escapeStep()` unwinds the panel, the selection, and the
session in that order.

## Models: one catalogue, visible provenance

`ryostage` owns the curated list, and the UI renders it instead of hardcoding
tiers:

```
ryostage models --json
[
  {"id":"u2netp","label":"Draft","tier":"draft","size":"4.6 MB","installed":true,
   "licence":"Apache-2.0 (mirrored weights)","upstream":"https://github.com/xuebinqin/U-2-Net"},
  {"id":"birefnet-general-lite","label":"Fine","tier":"fine","size":"224 MB","installed":false,
   "licence":"MIT","upstream":"https://github.com/ZhengPeng7/BiRefNet"}
]
```

The Quality control maps Draft -> `u2netp`, Standard -> `u2netp` with alpha
matting, Fine -> `birefnet-general-lite` with matting. Picking a tier whose
model is not installed shows the size and a **Download** button in place;
`Remove` frees it again. The runtime (`rembg[cpu]`, MIT, on ONNX Runtime,
MIT) installs once, on the first enable, into the shared cache. Nothing ML
ships in the base image. Both scripts' licence notes live in the engine's
header and here, so a packager can check them.

## Engine: `ryostage`

One bash helper, the only place model logic lives. Backend resolution is
unchanged from the old Depth engine (the managed venv first, then a system Python in
rembg's range, `uv` provisioning a managed 3.13 otherwise).

| Subcommand | Contract |
|---|---|
| `check [model]` | exit 0 and print `available` when the runtime and (with a model named) that model, else (without) at least one curated model, are present; otherwise a one-line reason (`runtime missing`, `model <id> missing`, `missing`) and non-zero |
| `models [--json]` | the curated catalogue: ids one per line, or the JSON above |
| `install [model...]` | provision the runtime and fetch the named models (default `u2netp`); opt-in, streams progress |
| `remove <model>` | drop a cached model |
| `cut <in> <out.png> [--model id] [--matting]` | the subject as an alpha-matted PNG; never writes a partial file |
| `inpaint <image> <mask> <out.png>` | fill the cut-out's hole with the surrounding colour (the parallax backdrop) |

Cache: `~/.local/state/ryoku/ryostage/{venv,models}`. On first run the
helper adopts a pre-split `~/.local/state/ryoku/depth` or `.../parallax` tree by
rename (same filesystem, no re-download); a leftover second tree is reported
by the doctor as reclaimable space.

`inpaint` makes the Parallax backdrop from the one cut: the subject's hole
(the matte grown outward so no subject pixel seeds the fill) is filled from its
surroundings by normalized convolution, growing inward until covered, then the
whole image is softened as the far plane (a 4 px blur, a touch darker). A
drifting subject therefore reveals the colours around it, never a flat plate
or its own silhouette. Half resolution above 1600 px keeps a 4K wallpaper at a
few seconds. Backdrops made before this land are regenerated by a re-cut or
Refresh.

## Daemon: `ipc/stage.go`

One worker, one registry (below), one topic.

- **Artifacts** `~/Pictures/Stage/<stem>/`: `subject.png` (the cut),
  `background.png` (the inpainted backdrop, made once the first time
  Parallax is chosen for that wallpaper), `layer-NN.png` (added layers),
  `.index.json` (mtime + quality reuse).
- **Topic** `stage`: `{ current, busy, stage: "cut"|"inpaint"|"", percent,
  notice, walls: { <path>: { effect, subject, background, rev, layers: [...] } } }`,
  published on every change and on each generation phase. QML renders from it
  and nothing else. `subject`/`background` are absolute paths ("" until fresh);
  `rev` is the max mtime across the wall's `subject.png`/`background.png`/
  `layer-NN.png`, so the shell busts every url with the one revision. The frame
  layers carry `{out, label, enabled, front, depth}` and no per-layer rev, and
  `layers[0]` is always the subject slot. `notice` names why the last reconcile
  could not produce a cut (the engine's reason, e.g. `model u2netp missing`);
  it is "" whenever the pipeline is fine, and the UI shows it instead of a
  silently dead toggle.
- **Verbs** (`ryoku-shell stage ...`): `set-effect <off|depth|parallax>`,
  `set-layer <index> <json>` (enabled/front/depth), `add-layer <png>`,
  `cut-layer <picture>` (runs the engine on another picture and adds the
  result), `remove-layer <index>`, `refresh` (re-cut), `cancel`, `clear`
  (delete the current wall's cut-outs and take the wall back to Plain),
  `status`, `models`.
- **Rules**: a wallpaper switch reconciles and never generates; a stage is
  per wallpaper; videos are skipped; an effect switch never re-cuts (only
  Parallax's first use on a wallpaper adds the inpaint); a wall left on whose
  artifacts vanished is re-cut by the next wake (the registry is the intent);
  a blocked or failed cut keeps the effect recorded, logs the reason, and
  publishes it as the frame's `notice`. The subject is still handed to ryogami
  as `depth` for the Depth effect only, unchanged on the wire.

## Settings: `~/.config/ryoku/stage.json`

Global only; anything per-wallpaper is in the registry.

| Key | Default | What it is |
|---|---|---|
| `quality` | `draft` | `draft` / `standard` / `fine`, the model + matting pair |
| `edge` | `0.15` | edge softness of every cut-out (0..1) |
| `shadow` | `0` | drop shadow behind every layer (0..1) |
| `shadowAngle` | `90` | shadow direction in degrees, 0 = right, 90 = down |
| `motion.amount` | `normal` | `subtle` / `normal` / `strong`: cursor drift, and the idle amplitude |
| `motion.idle` | `none` | `none` / `float` / `breathe` / `sway` |
| `motion.music` | `false` | layers react to the shared spectrum |
| `motion.musicLevel` | `0.6` | how hard the music pushes (0..1) |
| `motion.speed` | `1.0` | idle motion speed (0.25..2) |
| `motion.mouse` | `true` | Parallax follows the pointer at all |
| `motion.sensitivity` | `1.0` | the pointer's pull (0..2) |
| `motion.range` | `1.0` | how far a layer may travel (0..2) |
| `motion.backdrop` | `0` | the inpainted backdrop's own drift (0..1); above 0 a sliver of the base wallpaper shows at the trailing edge |
| `front` | `[]` | widget ids (built-in, plugin tile, or `visualizer`) drawn above the layers marked "in front"; written by the Depth catalogue's **In front** tab |

The daemon reads `quality`; the shell reads the rest. On the first start after
v2 a v1 `stage.json` (one still carrying `feather`, `lift`, `preset` or the
`motion.{mouse,sensitivity,range,wallpaper}` sub-knobs) is folded once and
rewritten atomically: `feather` -> `edge`, `lift` and `preset` dropped, and the
motion sub-knobs reduce to `motion.amount` (`mouse: false` -> `subtle`,
else `sensitivity >= 1.5` -> `strong`, else `normal`) with `motion.idle`/
`motion.music` defaulted. An already-v2 file is left alone; the daemon never
creates the GUI-owned file. A stable box that skipped v1 has no `stage.json` but
still carries the retired `depth.json`/`parallax.json`; those are folded instead
(model+matting -> `quality`, higher tier winning; `feather` -> `edge`;
`shadow`/`shadowAngle` scalars kept, per-layer arrays skipped).

## Registry: per-wallpaper stage

`~/.local/state/ryoku/stage-walls.json`:

```
{ "current": "<path>",
  "walls": { "<path>": {
      "effect": "off|depth|parallax",
      "layers": [ { "out": "<png>", "label": "Subject", "enabled": true,
                    "front": true, "depth": 0.5 }, ... ] } } }
```

`layers[0]` is always the subject the engine cut (`subject.png`); every
later entry is a picture the user added (`layer-NN.png`, cut from a picture
or dropped in as a PNG). `front` is behind/in front of the widgets; `depth`
0..1 is near..far for Parallax drift. The v1 registry is folded once, gated by
`~/.local/state/ryoku/migrations/ryostage-v2`: `effect: subject` becomes
`depth`, a `scene` order reduces to each layer's `front` (a layer listed after
any `widget:*` token is `front: true`), a v1 `depthFactor` becomes `depth`, and
`mode`, `scene` and the other per-layer knobs are dropped. A v1 manual wall's
`layer-NN.png` entries are kept after a prepended subject slot. Under the same
marker and before the v1 fold, the retired Depth (`depth-walls.json` +
`~/Pictures/Depth`) and Parallax (`layers.pz` + `~/Pictures/Parallax`) state a
stable box still carries is folded in for walls v1 has not claimed, its
artifacts moved by rename into `~/Pictures/Stage/<stem>/`, so both upgrade paths
converge on one registry.

## Rendering: `modules/stage/`

One surface, one stack. The desktop surface draws, back to front:
`StageBackdrop.qml` (Parallax only: the inpainted `background.png`, sized with
the wallpaper's own fit and drifting with the cursor, so it covers the
wallpaper's baked subject and can never misalign with ryogami's surface), then
the layers marked behind the widgets (z 2), then the widgets (z 3), then the
layers marked in front (`StageLayer.qml`: edge, shadow and angle from the global
look, drift by the layer's `depth` x the shared motion Amount x Sensitivity x
Range while Follow mouse is on, idle and music; z 4), then any widget the user
lifted into `front` (z 5). Depth is the same
stack with `motionEnabled: false` and no backdrop, so the still cut is
pixel-locked over the wallpaper's own subject. While the stage is on and the
visualizer is `On desktop`, the desktop hosts the visualizer inside this stack
(`InlineVisualizer` at z 1.5: above the backdrop, below every cut-out and
widget) and the visualizer's own surface is suppressed (cava keeps running);
`Above windows` keeps that surface outside the editor. There is no second
subject renderer, and no path that can draw the subject twice.
While the engine cuts, the subject layer dims and draws its own progress ring.

Hub's Desktop Scene page sits beside the stack, not in it. It reads stage.json
and sends typed `stage-settings` IPC requests to the shell's canonical
`modules/stage/Singletons/Config.qml`; per-wallpaper changes go through the
daemon's `StageBackend` contract. Drag updates coalesce before being sent.
The desktop mounts the widget outlines and lifts to the Top layer for the edit
session; the chrome itself lives on its own surfaces under
`shell/modules/stage/`. Each undo step writes a store as one update
(`setMany`, or one place-tool command): bursts of single-key writes can
interleave with a watcher's reload of an older version and put an old value
back.

## Delivery

`ryostage` ships in `ryoku-shell` (`/usr/bin/ryostage`) and via `deploy.sh`;
the QML in `ryoku-desktop`. `tests/shell-tool-availability.sh` gates
`[stage-engine]=ryostage` is not needed (the runtime is opt-in), but the helper
must be on both install paths, which the delivery check enforces.

## Verification

- Daemon: `go build ./...` and its unit tests: the `stage` topic carries the
  frame fields, the worker coalesces off the wallpaper hot path, and the registry
  parses.
- Doctor: hermetic Go tests for the rail migration (retired `depth`/`parallax`
  fold to one `stage` tab, idempotent), the settings migration, and the
  `ryostage cache` reclaim.
- QML: `qmllint` on the new and edited `modules/stage/` files.
- Engine: `bash -n` + shellcheck on `ryostage`; `check`, `models --json` and a
  `cut` against a provisioned cache.
- Delivery: `ryostage` is on both install paths (`deploy.sh` and the
  `ryoku-shell` PKGBUILD), enforced by the delivery check.
- The live visual result and real cut quality need a running session with the
  engine provisioned, exercised on the dev box via `dev-run.sh`.
