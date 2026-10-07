package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	wm "ryoku-wm"
)

// apply is pure store -> ini, so these exercise the composer directly: the
// layer order the F1 contract pinned, the store's own sections, the switch cost
// list a user reads, and the report shape. The composed file itself is proven
// by byte-pinned merges rather than by running wayfire, since wayfire has no
// validate verb and the nested-session proof lives in the E2E suite.

// wayfireHome points the provider's config and overlay trees at a temp dir and
// pins the state dir, so the palette file and the greeter hand-off cannot leak
// in from the dev box.
func wayfireHome(t *testing.T) string {
	t.Helper()
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	return wayfireConfigDir()
}

// withDefaults points the shipped-defaults layer at a fixture body and restores
// the package path afterwards.
func withDefaults(t *testing.T, body string) {
	t.Helper()
	p := filepath.Join(t.TempDir(), "wayfire.ini")
	if err := os.WriteFile(p, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
	prev := shareDefaultsPath
	shareDefaultsPath = p
	t.Cleanup(func() { shareDefaultsPath = prev })
}

func writeStore(t *testing.T, body string) string {
	t.Helper()
	p := filepath.Join(t.TempDir(), "desktop.json")
	if err := os.WriteFile(p, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
	return p
}

func writeSeed(t *testing.T, dir, name, body string) {
	t.Helper()
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, name), []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
}

// capApply runs apply with stdout captured and returns the decoded report.
func capApply(t *testing.T, args ...string) wm.ApplyReport {
	t.Helper()
	var buf bytes.Buffer
	prev := stdout
	stdout = bufio.NewWriter(&buf)
	defer func() { stdout = prev }()
	if err := runApply(args); err != nil {
		t.Fatalf("runApply(%v): %v", args, err)
	}
	stdout.Flush()
	var rep wm.ApplyReport
	if err := json.Unmarshal(buf.Bytes(), &rep); err != nil {
		t.Fatalf("decode report: %v\n%s", err, buf.String())
	}
	return rep
}

func readGen(t *testing.T, dir, name string) string {
	t.Helper()
	b, err := os.ReadFile(filepath.Join(dir, name))
	if err != nil {
		t.Fatalf("read %s: %v", name, err)
	}
	return string(b)
}

// The composition order is the F1 contract: defaults, store, seeds with
// user.ini last, each layer winning per key. The expected body is exact, so a
// change in ordering or spelling has to be a deliberate edit here.
func TestComposeLastWins(t *testing.T) {
	dir := wayfireHome(t)
	withDefaults(t, "[core]\nvwidth = 3\nplugins = animate blur grid\n\n[decoration]\nborder_size = 8\n")
	writeSeed(t, dir, "keyboard.ini", "[input]\nxkb_layout = us\n")
	writeSeed(t, dir, "user.ini", "[decoration]\nborder_size = 1\n")
	store := writeStore(t, `{"desktop":{"appearance":{"borderSize":4,"activeBorder":"#112233","inactiveBorder":"#445566","borderFollowsPalette":false,"animations":true,"blurEnabled":true},"input":{"kbLayout":"de"}}}`)

	got := string(compose(loadStore(store)))
	want := generatedHeader + `
[core]
vwidth = 3
plugins = animate blur grid

[decoration]
border_size = 1
active_color = \#112233FF
inactive_color = \#445566FF

[input]
xkb_layout = us
xkb_variant = 
xkb_options = 
kb_numlock_default_state = false
mouse_cursor_speed = 0
mouse_accel_profile = default
left_handed_mode = false
mouse_natural_scroll = false
mouse_scroll_speed = 1
natural_scroll = true
touchpad_scroll_speed = 1
tap_to_click = true
tap_and_drag = true
click_method = buttonareas
middle_emulation = false
disable_touchpad_while_typing = true
kb_repeat_rate = 25
kb_repeat_delay = 600
cursor_theme = Bibata-Modern-Ice
cursor_size = 24

[vswipe]
enable_vertical = false
enable_horizontal = false
fingers = 3

[vswitch]
duration = 300ms circle

[animate]
duration = 400ms circle

[grid]
duration = 300ms circle

[depthdeck]
enabled = true
scatter = true
card_edge_scatter = true
card_scatter_reshuffle = true
card_peek_min = 24
card_peek_max = 80
animation_ms = 200
layer_1_opacity = 0.85
layer_1_scale = 0.7
layer_2_opacity = 0.7
layer_2_scale = 0.5
max_layers = 8
maximized_front_scale = 0.9
`
	if got != want {
		t.Errorf("composed body differs from the pinned golden:\n--- want ---\n%s\n--- got ---\n%s", want, got)
	}
}

// The shipped plugin list is written with backslash continuations; the composer
// glues those lines into one value, so the generated file carries the same list
// on a single line and the store's toggles can still carve a plugin out of it.
func TestContinuationSeedsGlued(t *testing.T) {
	dir := wayfireHome(t)
	withDefaults(t, "")
	writeSeed(t, dir, "user.ini", "[core]\nplugins = \\\n  animate \\\n  blur \\\n  zoom\n")
	store := writeStore(t, `{"desktop":{"appearance":{"borderFollowsPalette":false,"animations":false,"blurEnabled":true}}}`)
	body := string(compose(loadStore(store)))
	if !strings.Contains(body, "plugins = blur zoom") {
		t.Errorf("a continued plugin list must glue into one line, then lose animate:\n%s", body)
	}
}

// Determinism: two runs over the same layers are byte-equal, which is what
// lets doctor diff the file without flapping.
func TestComposeDeterministic(t *testing.T) {
	wayfireHome(t)
	withDefaults(t, "[core]\nplugins = animate blur\n")
	store := writeStore(t, `{"desktop":{"appearance":{"borderSize":4,"borderFollowsPalette":false}}}`)
	s := loadStore(store)
	if a, b := compose(s), compose(s); !bytes.Equal(a, b) {
		t.Fatalf("two runs differ:\n%s\n---\n%s", a, b)
	}
}

func TestApplyWritesWayfireIni(t *testing.T) {
	dir := wayfireHome(t)
	withDefaults(t, "[core]\nplugins = animate blur\n")
	store := writeStore(t, `{"desktop":{"appearance":{"borderSize":6,"borderFollowsPalette":false,"animations":true,"blurEnabled":true}}}`)

	rep := capApply(t, store)
	if len(rep.Written) != 1 || rep.Written[0] != filepath.Join(dir, "wayfire.ini") {
		t.Fatalf("written = %v, want the live wayfire.ini", rep.Written)
	}
	if rep.ReloadNeeded {
		t.Fatal("wayfire reloads its own config; ReloadNeeded must be false")
	}
	live := readGen(t, dir, "wayfire.ini")
	if !strings.Contains(live, "border_size = 6") {
		t.Errorf("composed file misses the store:\n%s", live)
	}
	overlay := readGen(t, userEditsWayfireDir(), "wayfire.ini")
	if overlay != live {
		t.Error("the user_edits copy must match the live file byte for byte")
	}
}

func TestPreviewWritesNothing(t *testing.T) {
	dir := wayfireHome(t)
	withDefaults(t, "[core]\nplugins = animate\n")
	store := writeStore(t, `{"desktop":{"appearance":{"borderSize":6,"borderFollowsPalette":false}}}`)
	rep := capApply(t, "--preview", store)
	if len(rep.Written) != 0 {
		t.Fatalf("preview wrote %v", rep.Written)
	}
	if _, err := os.Stat(filepath.Join(dir, "wayfire.ini")); err == nil {
		t.Fatal("preview must leave no file behind")
	}
}

// The switch cost: every desktop.* key without a wayfire spelling gets its own
// line with a wayfire-specific reason, a foreign namespace collapses to one,
// and the honoured keys stay quiet.
func TestUnhonoredNamesLosses(t *testing.T) {
	wayfireHome(t)
	store := writeStore(t, `{
	  "desktop": {
	    "appearance": {"gapsIn": 16, "rounding": 8, "blurSize": 12, "borderSize": 4},
	    "input": {"followMouse": 1, "middleClickPaste": false, "swipeDistance": 300, "kbLayout": "us"},
	    "env": [{"key": "FOO", "value": "bar"}],
	    "windows": {"tameMaximizeOnOpen": true},
	    "apps": {"terminal": "alacritty"},
	    "keybindRebinds": {"Super+T": "Super+Y"},
	    "autostart": [{"command": "sleep 1"}]
	  },
	  "wm": {"niri": {"preferNoCsd": true}}
	}`)
	got := map[string]string{}
	for _, u := range unhonored(store) {
		got[u.Key] = u.Reason
	}
	for key, want := range map[string]string{
		"desktop.appearance.gapsIn":   "wayfire windows float; there are no gaps between them.",
		"desktop.appearance.rounding": "wayfire's decorations are square; there is no corner radius.",
		"desktop.input.followMouse":   "wayfire has no focus-follows-mouse mode.",
		"desktop.env":                 "wayfire takes its environment from the session, not from the store.",
		"desktop.windows":             "wayfire lets apps open themselves maximised; there is no tame-on-open.",
		"desktop.apps":                "wayfire takes its environment from the session, not from the store.",
		"desktop.keybindRebinds":      "wayfire's shipped binds are seed entries; change a chord in user.ini instead.",
		"wm.niri":                     "These Niri-only settings have no wayfire equivalent. They stay in the store and return if you switch back.",
	} {
		if got[key] != want {
			t.Errorf("%s = %q, want %q", key, got[key], want)
		}
	}
	if _, ok := got["desktop.appearance.borderSize"]; ok {
		t.Error("an emitted leaf must not be reported")
	}
	for key := range got {
		if strings.HasPrefix(key, "desktop.autostart") {
			t.Errorf("autostart translates whole; it must not be reported: %s", key)
		}
	}
	if _, ok := got["desktop.input.swipeInvert"]; ok {
		// swipeDistance is reported; swipeInvert was not set, so it stays quiet.
		t.Error("an unset leaf must not be reported")
	}
	if got["desktop.input.swipeDistance"] == "" {
		t.Error("swipeDistance has no wayfire spelling and must be reported")
	}
}

// The colour gate, both ways: with the palette following, the recorded wallpaper
// colours land in the file; pinned, the store's own colours do and the palette
// file is ignored.
func TestPaletteGateInCompose(t *testing.T) {
	wayfireHome(t)
	withDefaults(t, "")
	pin := writeStore(t, `{"desktop":{"appearance":{"borderSize":4,"activeBorder":"#111111","inactiveBorder":"#222222","borderFollowsPalette":false}}}`)
	follow := writeStore(t, `{"desktop":{"appearance":{"borderSize":4,"activeBorder":"#111111","inactiveBorder":"#222222","borderFollowsPalette":true}}}`)

	pal := filepath.Join(os.Getenv("XDG_STATE_HOME"), "ryoku", "wayfire-border-palette.json")
	if err := os.MkdirAll(filepath.Dir(pal), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(pal, []byte(`{"active":"#aabbcc","inactive":"#ddeeff"}`), 0o644); err != nil {
		t.Fatal(err)
	}

	pinned := string(compose(loadStore(pin)))
	if !strings.Contains(pinned, "active_color = \\#111111FF") {
		t.Errorf("a pinned border must ignore the palette:\n%s", pinned)
	}
	following := string(compose(loadStore(follow)))
	if !strings.Contains(following, "active_color = \\#AABBCCFF") ||
		!strings.Contains(following, "inactive_color = \\#DDEEFFFF") {
		t.Errorf("a palette-following border must take the recorded colours:\n%s", following)
	}
}

// The two plugin-presence toggles carve their plugin out of the composed list
// and nothing else moves; both on leaves the defaults' list untouched.
func TestPluginsAdjustedByStore(t *testing.T) {
	wayfireHome(t)
	withDefaults(t, "[core]\nplugins =   animate   blur   grid  \n")

	off := writeStore(t, `{"desktop":{"appearance":{"animations":false,"blurEnabled":true,"borderFollowsPalette":false}}}`)
	body := string(compose(loadStore(off)))
	if strings.Contains(body, "plugins = animate") || !strings.Contains(body, "plugins = blur grid") {
		t.Errorf("animations off must drop animate only:\n%s", body)
	}

	on := writeStore(t, `{"desktop":{"appearance":{"animations":true,"blurEnabled":true,"borderFollowsPalette":false}}}`)
	body = string(compose(loadStore(on)))
	if !strings.Contains(body, "plugins = animate   blur   grid") {
		t.Errorf("both toggles on must leave the defaults list's inner spacing alone:\n%s", body)
	}
}

func TestDefaultsCarryWayfireNamespace(t *testing.T) {
	var buf bytes.Buffer
	prev := stdout
	stdout = bufio.NewWriter(&buf)
	defer func() { stdout = prev }()
	if err := runDefaults(); err != nil {
		t.Fatalf("runDefaults: %v", err)
	}
	stdout.Flush()
	var top map[string]json.RawMessage
	if err := json.Unmarshal(buf.Bytes(), &top); err != nil {
		t.Fatalf("decode defaults: %v\n%s", err, buf.String())
	}
	var wmNS map[string]json.RawMessage
	if err := json.Unmarshal(top["wm"], &wmNS); err != nil {
		t.Fatalf("decode wm namespace: %v\n%s", err, buf.String())
	}
	own, ok := wmNS[wm.ProviderWayfire]
	if !ok {
		t.Fatalf("defaults miss wm.wayfire: %s", buf.String())
	}
	var ownLeaves map[string]json.RawMessage
	if err := json.Unmarshal(own, &ownLeaves); err != nil {
		t.Fatalf("decode wm.wayfire: %v", err)
	}
	if _, ok := ownLeaves["depthdeck"]; !ok {
		t.Errorf("wm.wayfire must carry depthdeck")
	}
	var desktop map[string]json.RawMessage
	if err := json.Unmarshal(top["desktop"], &desktop); err != nil {
		t.Fatalf("decode desktop: %v", err)
	}
	if _, ok := desktop["appearance"]; !ok {
		t.Errorf("defaults must carry the neutral appearance baseline")
	}
	if _, ok := desktop["env"]; ok {
		t.Error("wayfire does not model env; the defaults must not offer it")
	}
}

// The rule language: an honoured row renders verbatim, a lost one names the
// part that has no spelling.
func TestWindowRuleRendering(t *testing.T) {
	for _, tc := range []struct {
		rule WindowRule
		want string
	}{
		{WindowRule{Class: "kitty", Action: "maximize"},
			`on created if app_id is "kitty" then maximize`},
		{WindowRule{Title: "Player", Action: "pin"},
			`on created if title is "Player" then set sticky true`},
		{WindowRule{Class: "mpv", Action: "opacity", Value: "0.9"},
			`on created if app_id is "mpv" then set alpha 0.9`},
		{WindowRule{Class: "mail", Action: "workspace", Value: "2 0"},
			`on created if app_id is "mail" then assign_workspace 2 0`},
		{WindowRule{Class: "term", Title: "shell", Action: "maximize"},
			`on created if app_id is "term" & title is "shell" then maximize`},
	} {
		got, ok := wayfireRule(tc.rule)
		if !ok || got != tc.want {
			t.Errorf("wayfireRule(%+v) = %q, %v; want %q", tc.rule, got, ok, tc.want)
		}
	}
	lost := []WindowRule{
		{Class: "x", Action: "float"},
		{Class: "x", Action: "opacity", Value: "2"},
		{Class: "x", Action: "workspace", Value: "next"},
		{Class: "x", Action: "workspace", Value: "3"},
		{Action: "maximize"},
	}
	for _, r := range lost {
		if rule, ok := wayfireRule(r); ok {
			t.Errorf("wayfireRule(%+v) must be lost, got %q", r, rule)
		}
	}
	if _, why := renderRule("x", "", "float", ""); !strings.Contains(why, `no "float" action`) {
		t.Errorf("an unknown action must name it, got %q", why)
	}
	if _, why := renderRule("", "", "maximize", ""); !strings.Contains(why, "app id or title") {
		t.Errorf("an unanchored rule must say so, got %q", why)
	}
	if _, why := renderRule("x", "", "workspace", "3"); !strings.Contains(why, "grid coordinates") {
		t.Errorf("a linear workspace index must name the grid format, got %q", why)
	}
}

// The bind path: an exec chord lands as a command/binding pair in wayfire's
// spelling, a release bind takes the release prefix, and every loss is named.
func TestBindsEmitted(t *testing.T) {
	s := defaultStore()
	s.Keybinds = []Keybind{
		{Keys: "Super+T", Action: "exec", Value: "alacritty"},
		{Keys: "Super+Shift+Y", Action: "exec", Value: "say hi", Release: true},
		{Keys: "Super+Q", Action: "close"},
		{Keys: "mouse:272", Action: "exec", Value: "click"},
	}
	d := genWayfireBinds(s)
	got := map[string]string{}
	for _, sec := range d.sections {
		for _, k := range sec.keys {
			got[sec.name+"/"+k.name] = k.value
		}
	}
	if got["command/command_ryoku_0"] != "alacritty" || got["command/binding_ryoku_0"] != "<super> KEY_T" {
		t.Errorf("exec bind: %v", got)
	}
	if got["command/release_binding_ryoku_1"] != "<super> <shift> KEY_Y" {
		t.Errorf("release bind chord: %v", got)
	}
	if _, ok := got["command/command_ryoku_2"]; ok {
		t.Error("a non-exec bind has no wayfire spelling and must not be emitted")
	}
}

func TestBindsUnhonored(t *testing.T) {
	wayfireHome(t)
	store := writeStore(t, `{"desktop":{"keybinds":[
	  {"keys":"Super+Q","action":"close"},
	  {"keys":"mouse:272","action":"exec","value":"x"},
	  {"keys":"Super+T","action":"exec","value":""},
	  {"keys":"Super+R","action":"exec","value":"rofi"}
	]}}`)
	got := map[string]string{}
	for _, u := range unhonored(store) {
		got[u.Key] = u.Reason
	}
	if !strings.Contains(got["desktop.keybinds[0]"], `cannot bind the "close" action`) {
		t.Errorf("keybinds[0] = %q", got["desktop.keybinds[0]"])
	}
	if !strings.Contains(got["desktop.keybinds[1]"], "cannot bind the chord") {
		t.Errorf("keybinds[1] = %q", got["desktop.keybinds[1]"])
	}
	if !strings.Contains(got["desktop.keybinds[2]"], "needs a command") {
		t.Errorf("keybinds[2] = %q", got["desktop.keybinds[2]"])
	}
	if _, ok := got["desktop.keybinds[3]"]; ok {
		t.Error("a bind wayfire honours must stay quiet")
	}
}

// The input, cursor, swipe, autostart and depthdeck sections arrive with the
// neutral values in wayfire's spelling.
func TestStoreSectionsEmitted(t *testing.T) {
	wayfireHome(t)
	withDefaults(t, "")
	store := writeStore(t, `{
	  "desktop": {
	    "appearance": {"borderFollowsPalette": false, "animations": true, "blurEnabled": true},
	    "input": {"kbLayout": "br", "sensitivity": 0.4, "accelProfile": "flat",
	              "clickfinger": true, "workspaceSwipe": true, "swipeFingers": 4},
	    "cursor": {"theme": "Adwaita", "size": 32},
	    "autostart": [{"command": "nm-applet"}]
	  },
	  "wm": {"wayfire": {"depthdeck": {"maximizedFrontScale": 0.95, "animationMs": 250}}}
	}`)
	body := string(compose(loadStore(store)))
	for _, want := range []string{
		"xkb_layout = br",
		"mouse_cursor_speed = 0.4",
		"mouse_accel_profile = flat",
		"click_method = clickfinger",
		"enable_vertical = true",
		"fingers = 4",
		"cursor_theme = Adwaita",
		"cursor_size = 32",
		"ryoku_00 = nm-applet",
		"maximized_front_scale = 0.95",
		"animation_ms = 250",
	} {
		if !strings.Contains(body, want) {
			t.Errorf("composed file misses %q:\n%s", want, body)
		}
	}
}

// The greeter hand-off rides apply, the same way the sibling providers publish
// it, so login and the session agree on the keypad.
func TestApplyPublishesGreeterNumlock(t *testing.T) {
	wayfireHome(t)
	file := filepath.Join(t.TempDir(), "greeter-numlock")
	t.Setenv("RYOKU_GREETER_NUMLOCK_FILE", file)
	store := writeStore(t, `{"desktop":{"input":{"numlockByDefault":true}}}`)
	capApply(t, store)
	b, err := os.ReadFile(file)
	if err != nil {
		t.Fatalf("apply wrote no greeter numlock hand-off: %v", err)
	}
	if got := strings.TrimSpace(string(b)); got != "on" {
		t.Fatalf("hand-off = %q, want on", got)
	}
}
