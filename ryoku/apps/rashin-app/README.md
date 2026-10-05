# rashin-app

The Rashin companion window: the daemon's whole surface as a normal desktop
app. It opens like any window (Super+Alt+Space, the app launcher, or
`rashin-app`), and it is a first-class client of the rashin daemon, never a
second brain: every fact, run, approval, and model switch is the daemon's, and
this app only asks and paints.

It is the "compiled Qt app" shape of `ryoku/apps/`: a plain Qt6 Quick
application (no Quickshell, no compositor dependency) that builds to
`/usr/bin/rashin-app`. The stack is deliberately small and the seams are
deliberately wide, so the app can be lifted out of the tree intact.

## What's inside

| Page | Key | It holds |
|---|---|---|
| Chat | Ctrl+1 | The shared agent session: streaming replies, thinking folds, tool rows with output peeks and diffs, inline approvals, the session drawer, model + agent + approvals switchers |
| Ask | Ctrl+2 | The launcher's fast lane with room: one question, one streamed answer, action chips, the recent-asks drawer, Continue in chat |
| Vault | Ctrl+3 | The knowledge base: grouped file tree, rendered markdown, reindex |
| Agents | Ctrl+4 | Detected coding agents, wire/unwire, the harness ledger (model, sessions, skills, credential names) |
| Models | Ctrl+5 | The fast-lane provider switch, the chat model list, the provider directory |
| System | Ctrl+6 | Live vitals and the doctor's findings, each with Fix with AI |

Ctrl+N starts a chat, Ctrl+K focuses the composer, Ctrl+B toggles the rail,
Ctrl+Q quits.

## Layout

```
rashin-app/
├── CMakeLists.txt      the one build: binary + embedded QML module (RashinApp)
├── main.cpp            process identity, engine boot
├── rashin-app.desktop  launcher entry
├── src/                the C++ half: every daemon contract
│   ├── chatbridge.*    the shared session over `ryoku-rashin chat --follow`
│   │                   (the v3 reducer, ported from the shell's chatstate.js)
│   ├── daemonclient.*  the HTTP plane: GET/POST on 127.0.0.1:<port>
│   ├── quickask.*      one fast-lane ask (the CLI marker protocol)
│   ├── markdown.*      agent text -> safe Qt rich text (escape first)
│   ├── preferences.*   UI-owned state only (page, size, drafts)
│   ├── notify.*        freedesktop notifications over DBus
│   ├── clipboard.*     the one copy path
│   └── runner.*        detached desktop commands (enable, backend, fix)
└── qml/                the QML half: presentation only
    ├── Main.qml        the window: rail + header + page host + shortcuts
    ├── Rail.qml Header.qml ModelChip.qml OfflineNotice.qml
    ├── ChatPage.qml MessageRow.qml Composer.qml   the chat surface
    ├── AskPage.qml VaultPage.qml AgentsPage.qml
    ├── ModelsPage.qml SystemPage.qml              the daemon pages
    ├── ui/             IconBtn, Pill (the two buttons)
    └── theme/          Theme.qml (the look, retinted live from /api/theme)
```

## The two hard rules

1. **Pages never reach the transport.** QML calls the C++ singletons
   (`ChatBridge.send`, `DaemonClient.get`, `QuickAsk.ask`, `Runner.run`); the
   C++ owns sockets, processes, and JSON. A reusable component takes props
   and emits signals; only pages and the window touch a bridge.
2. **UI state is never authority.** The transcript, the model list, the
   session history, the approval verdicts, the daemon's online state: all of
   it is the daemon's answer projected. `Preferences` holds exactly four
   kinds of thing -- last page, window size, rail collapse, per-thread drafts
   -- and the daemon never reads them.

## The protocol

The app speaks the daemon's existing wire, unchanged:

- **Chat** rides `ryoku-rashin chat --follow`: newline JSON both ways, the
  same bridge the shell's Ask chat and the sidebar ride. The daemon replays
  the live transcript on join, so a conversation started anywhere is already
  on screen here, and a turn started here keeps running if the window closes.
- **Everything else** rides the daemon's HTTP API on `127.0.0.1:<port>`
  (port from `~/.config/ryoku/rashin.json`): `/api/theme`, `/api/vault`,
  `/api/agents`, `/api/harnesses`, `/api/quick`, `/api/providers`,
  `/api/vitals`, `/api/doctor`, `/api/fix`, `/api/index`.
- **The fast lane** rides `ryoku-rashin ask` (the marker protocol:
  `@working`/`@perm`/`@answer`/`@error`), the same CLI the launcher uses.

There is no bespoke protocol to keep in sync: the daemon already versioned
its own, and this app is one more client of it.

## Build

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build          # -> build/rashin-app
```

Requires `qt6-declarative` and `qt6-base` (Quick, Network, DBus). At runtime
it needs `ryoku-rashin` on PATH for the chat bridge and the ask lane; every
HTTP page degrades to an honest offline notice when the daemon is off.

## Exporting

The directory has no references into the rest of the tree: no Ryoku.Ui
import, no Quickshell, no compositor. `cp -a rashin-app/ <new repo>` and
adjust only the desktop-file name and the packaging hook.
