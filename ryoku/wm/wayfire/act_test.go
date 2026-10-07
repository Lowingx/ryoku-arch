package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// The act file's method names and payloads are pinned without a compositor:
// the request choke point is replaced with canned replies and a record, so a
// wayfire protocol change reads as a failing test rather than as an action
// that silently stopped working.

type actCall struct {
	method string
	data   any
}

func stubAct(t *testing.T, replies map[string]string) *[]actCall {
	t.Helper()
	originalReq, originalAlive := request, aliveCheck
	var calls []actCall
	request = func(method string, data any) (json.RawMessage, error) {
		calls = append(calls, actCall{method: method, data: data})
		body, ok := replies[method]
		if !ok {
			// Anything the fixture does not model is a mutation: the
			// compositor would answer ok and the reply is never read.
			return json.RawMessage(`{"result":"ok"}`), nil
		}
		return json.RawMessage(body), nil
	}
	aliveCheck = func(string) bool { return true }
	t.Cleanup(func() {
		request, aliveCheck = originalReq, originalAlive
	})
	return &calls
}

func wantCallN(t *testing.T, calls []actCall, method string, n int, payload string) {
	t.Helper()
	seen := 0
	for _, c := range calls {
		if c.method != method {
			continue
		}
		if seen == n {
			body, err := json.Marshal(c.data)
			if err != nil {
				t.Fatalf("marshal %s payload: %v", method, err)
			}
			if string(body) != payload {
				t.Errorf("%s payload = %s, want %s", method, body, payload)
			}
			return
		}
		seen++
	}
	t.Errorf("no %s call #%d among %v", method, n, callMethods(calls))
}

func wantCall(t *testing.T, calls []actCall, method, payload string) {
	t.Helper()
	wantCallN(t, calls, method, 0, payload)
}

func wantNoCall(t *testing.T, calls []actCall, method string) {
	t.Helper()
	for _, c := range calls {
		if c.method == method {
			t.Errorf("unexpected %s call: %v", method, c.data)
			return
		}
	}
}

// wantOrder asserts the mutations happened in sequence; the state queries
// that stand between them are allowed anywhere.
func wantOrder(t *testing.T, calls []actCall, want ...expectedCall) {
	t.Helper()
	pos := 0
	for _, expected := range want {
		found := false
		for ; pos < len(calls); pos++ {
			if calls[pos].method != expected.method {
				continue
			}
			body, err := json.Marshal(calls[pos].data)
			if err != nil {
				t.Fatalf("marshal %s payload: %v", expected.method, err)
			}
			if string(body) != expected.payload {
				break
			}
			found = true
			pos++
			break
		}
		if !found {
			t.Fatalf("want %s %s in order, got %v", expected.method, expected.payload, callMethods(calls))
		}
	}
}

// expectedCall pairs a method with its JSON payload for wantOrder.
type expectedCall struct {
	method  string
	payload string
}

func callMethods(calls []actCall) []string {
	out := make([]string, 0, len(calls))
	for _, c := range calls {
		out = append(out, c.method)
	}
	return out
}

func TestWindowActs(t *testing.T) {
	t.Run("focus", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"window.focus", "7"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "window-rules/focus-view", `{"id":7}`)
	})

	t.Run("close", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"window.close", "7"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "window-rules/close-view", `{"id":7}`)
	})

	t.Run("fullscreen toggles from the held state", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"window.fullscreen", "7"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "wm-actions/set-fullscreen", `{"id":7,"state":true}`)
	})

	t.Run("float toggles to the full-workspace tile", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"window.float", "7"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "window-rules/configure-view", `{"id":7,"tiled-edges":15}`)
	})

	t.Run("missing id names the argument", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"window.focus"})
		if err == nil || !strings.Contains(err.Error(), "missing window id") {
			t.Errorf("got %v, want a missing window id error", err)
		}
	})

	t.Run("unknown window refuses instead of falling to the focused one", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"window.fullscreen", "99"})
		if err == nil || !strings.Contains(err.Error(), "does not exist") {
			t.Errorf("got %v, want a does-not-exist error", err)
		}
	})
}

func TestWindowPlace(t *testing.T) {
	t.Run("one transaction moves sizes and floats", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"window.place", "7", "10", "20", "400", "300", "HEADLESS-1"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "window-rules/configure-view",
			`{"geometry":{"height":300,"width":400,"x":10,"y":20},"id":7,"output_id":1,"tiled-edges":0}`)
	})

	t.Run("coordinates are output-relative", func(t *testing.T) {
		replies := stageReplies()
		replies["window-rules/list-outputs"] = `[{"id":1,"name":"HEADLESS-1","geometry":{"x":1920,"y":1080,"width":1280,"height":720},"wset-index":1,"workspace":{"x":1,"y":0,"grid_width":3,"grid_height":3}}]`
		calls := stubAct(t, replies)
		if err := runAct([]string{"window.place", "7", "10", "20", "400", "300", "HEADLESS-1"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "window-rules/configure-view",
			`{"geometry":{"height":300,"width":400,"x":1930,"y":1100},"id":7,"output_id":1,"tiled-edges":0}`)
	})

	t.Run("unknown output", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"window.place", "7", "0", "0", "400", "300", "NOPE-1"})
		if err == nil || !strings.Contains(err.Error(), "does not exist") {
			t.Errorf("got %v, want a does-not-exist error", err)
		}
	})

	t.Run("negative size", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"window.place", "7", "0", "0", "-1", "300", "HEADLESS-1"})
		if err == nil || !strings.Contains(err.Error(), "must be positive") {
			t.Errorf("got %v, want a positive-size error", err)
		}
	})
}

func TestMoveToWorkspace(t *testing.T) {
	t.Run("same set sends and follows", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"window.moveToWorkspace", "7", "1:2:1"}); err != nil {
			t.Fatal(err)
		}
		wantOrder(t, *calls,
			expectedCall{"vswitch/send-view", `{"view-id":7,"x":2,"y":1}`},
			expectedCall{"window-rules/focus-view", `{"id":7}`})
		wantNoCall(t, *calls, "wsets/send-view-to-wset")
	})

	t.Run("another set changes sets first", func(t *testing.T) {
		replies := stageReplies()
		replies["window-rules/list-views"] = strings.Replace(
			replies["window-rules/list-views"], `"wset-index":1`, `"wset-index":2`, 1)
		calls := stubAct(t, replies)
		if err := runAct([]string{"window.moveToWorkspace", "7", "1:2:1"}); err != nil {
			t.Fatal(err)
		}
		wantOrder(t, *calls,
			expectedCall{"wsets/send-view-to-wset", `{"view-id":7,"wset-index":1}`},
			expectedCall{"vswitch/send-view", `{"view-id":7,"x":2,"y":1}`},
			expectedCall{"window-rules/focus-view", `{"id":7}`})
	})

	t.Run("handle must round-trip", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"window.moveToWorkspace", "7", "workspace-two"})
		if err == nil || !strings.Contains(err.Error(), "not set:cell:cell") {
			t.Errorf("got %v, want a handle error", err)
		}
	})
}

func TestSummonAndAppFocus(t *testing.T) {
	t.Run("summon pulls onto the focused cell", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"window.summon", "term"}); err != nil {
			t.Fatal(err)
		}
		wantOrder(t, *calls,
			expectedCall{"vswitch/send-view", `{"view-id":7,"x":1,"y":0}`},
			expectedCall{"window-rules/focus-view", `{"id":7}`})
	})

	t.Run("summon missing title", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"window.summon", "not-a-title"})
		if err == nil || !strings.Contains(err.Error(), "no window titled") {
			t.Errorf("got %v, want a no-window error", err)
		}
	})

	t.Run("app focus", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"app.focus", "kitty"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "window-rules/focus-view", `{"id":7}`)
	})

	t.Run("app focus missing app", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"app.focus", "firefox"})
		if err == nil || !strings.Contains(err.Error(), "no window of app") {
			t.Errorf("got %v, want a no-window error", err)
		}
	})
}

func TestWorkspaceFocusAndCycle(t *testing.T) {
	t.Run("current set only navigates", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"workspace.focus", "1:1:0"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "vswitch/set-workspace", `{"output-id":1,"x":1,"y":0}`)
		wantNoCall(t, *calls, "wsets/set-output-wset")
	})

	t.Run("another set is selected first", func(t *testing.T) {
		replies := stageReplies()
		replies["window-rules/list-wsets"] = `[
			{"index":1,"name":"a","output-id":1,"output-name":"HEADLESS-1","workspace":{"x":1,"y":0,"grid_width":3,"grid_height":3}},
			{"index":2,"name":"b","output-id":1,"output-name":"HEADLESS-1","workspace":{"x":0,"y":0,"grid_width":3,"grid_height":3}}]`
		calls := stubAct(t, replies)
		if err := runAct([]string{"workspace.focus", "2:0:0"}); err != nil {
			t.Fatal(err)
		}
		wantOrder(t, *calls,
			expectedCall{"wsets/set-output-wset", `{"output-id":1,"wset-index":2}`},
			expectedCall{"vswitch/set-workspace", `{"output-id":1,"x":0,"y":0}`})
	})

	t.Run("detached set refuses", func(t *testing.T) {
		replies := stageReplies()
		replies["window-rules/list-wsets"] = `[{"index":1,"name":"a","output-id":0,"output-name":"null","workspace":{"x":1,"y":0,"grid_width":3,"grid_height":3}}]`
		stubAct(t, replies)
		err := runAct([]string{"workspace.focus", "1:1:0"})
		if err == nil || !strings.Contains(err.Error(), "not attached to an output") {
			t.Errorf("got %v, want a detached error", err)
		}
	})

	t.Run("cycle steps row-major", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"workspace.cycle", "1"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "vswitch/set-workspace", `{"output-id":1,"x":2,"y":0}`)
	})

	t.Run("cycle wraps", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"workspace.cycle", "-2"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "vswitch/set-workspace", `{"output-id":1,"x":2,"y":2}`)
	})

	t.Run("cycle rejects a non-integer", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"workspace.cycle", "sideways"})
		if err == nil || !strings.Contains(err.Error(), "delta must be an integer") {
			t.Errorf("got %v, want a delta error", err)
		}
	})
}

func TestWorkspaceMoveToOutput(t *testing.T) {
	replies := func() map[string]string {
		r := stageReplies()
		r["window-rules/list-outputs"] = `[{"id":1,"name":"HEADLESS-1","geometry":{"x":0,"y":0,"width":1280,"height":720},"wset-index":1,"workspace":{"x":1,"y":0,"grid_width":3,"grid_height":3}},
			{"id":2,"name":"HDMI-A-1","geometry":{"x":1280,"y":0,"width":1920,"height":1080},"wset-index":2,"workspace":{"x":0,"y":0,"grid_width":3,"grid_height":3}}]`
		return r
	}

	t.Run("each window of the cell moves", func(t *testing.T) {
		calls := stubAct(t, replies())
		if err := runAct([]string{"workspace.moveToOutput", "1:0:0", "HDMI-A-1"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "window-rules/configure-view", `{"id":7,"output_id":2}`)
	})

	t.Run("unknown output", func(t *testing.T) {
		stubAct(t, replies())
		err := runAct([]string{"workspace.moveToOutput", "1:0:0", "NOPE-1"})
		if err == nil || !strings.Contains(err.Error(), "does not exist") {
			t.Errorf("got %v, want a does-not-exist error", err)
		}
	})
}

func TestKeyboardCycle(t *testing.T) {
	t.Run("next layout", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"keyboard.cycleLayout"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "wayfire/set-keyboard-state", `{"layout-index":1}`)
	})

	t.Run("wraps to the first", func(t *testing.T) {
		replies := stageReplies()
		replies["wayfire/get-keyboard-state"] = `{"possible-layouts":["us","br"],"layout":"br"}`
		calls := stubAct(t, replies)
		if err := runAct([]string{"keyboard.cycleLayout"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "wayfire/set-keyboard-state", `{"layout-index":0}`)
	})

	t.Run("no layouts", func(t *testing.T) {
		replies := stageReplies()
		replies["wayfire/get-keyboard-state"] = `{"possible-layouts":[],"layout":"unknown"}`
		stubAct(t, replies)
		err := runAct([]string{"keyboard.cycleLayout"})
		if err == nil || !strings.Contains(err.Error(), "no layouts") {
			t.Errorf("got %v, want a no-layouts error", err)
		}
	})
}

func TestTouchpadAct(t *testing.T) {
	devices := func(pad bool) map[string]string {
		r := stageReplies()
		list := `[{"id":7,"name":"Logitech Mouse","type":"pointer","enabled":true},
			{"id":9,"name":"AT Translated Set 2 keyboard","type":"keyboard","enabled":true}]`
		if pad {
			list = `[{"id":42,"name":"ELAN1200:00 04f3:3098 Touchpad","type":"pointer","enabled":true},
				{"id":7,"name":"Logitech Mouse","type":"pointer","enabled":true},
				{"id":9,"name":"AT Translated Set 2 keyboard","type":"keyboard","enabled":true}]`
		}
		r["input/list-devices"] = list
		return r
	}

	silence := func(t *testing.T) *bytes.Buffer {
		t.Helper()
		var buf bytes.Buffer
		originalOut, originalNotify := stdout, touchpadNotify
		stdout = bufio.NewWriter(&buf)
		touchpadNotify = func(string, string) {}
		t.Cleanup(func() { stdout, touchpadNotify = originalOut, originalNotify })
		return &buf
	}

	t.Run("status reads the device", func(t *testing.T) {
		stubAct(t, devices(true))
		buf := silence(t)
		if err := runAct([]string{"input.touchpad", "status"}); err != nil {
			t.Fatal(err)
		}
		stdout.Flush()
		if buf.String() != "on\n" {
			t.Errorf("status printed %q, want on", buf.String())
		}
	})

	t.Run("toggle locks only the pad", func(t *testing.T) {
		calls := stubAct(t, devices(true))
		silence(t)
		if err := runAct([]string{"input.touchpad", "toggle"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "input/configure-device", `{"enabled":false,"id":42}`)
		// Only the pad moves: the mouse and the keyboard stay untouched.
		count := 0
		for _, c := range *calls {
			if c.method == "input/configure-device" {
				count++
			}
		}
		if count != 1 {
			t.Errorf("configure-device called %d times, want 1", count)
		}
	})

	t.Run("no touchpad names it", func(t *testing.T) {
		stubAct(t, devices(false))
		err := runAct([]string{"input.touchpad", "toggle"})
		if err == nil || !strings.Contains(err.Error(), "no touchpad") {
			t.Errorf("got %v, want a no-touchpad error", err)
		}
	})

	t.Run("restore re-asserts nothing", func(t *testing.T) {
		calls := stubAct(t, devices(true))
		if err := runAct([]string{"input.touchpad", "restore"}); err != nil {
			t.Fatal(err)
		}
		wantNoCall(t, *calls, "input/configure-device")
	})

	t.Run("bad mode", func(t *testing.T) {
		stubAct(t, devices(true))
		err := runAct([]string{"input.touchpad", "perhaps"})
		if err == nil || !strings.Contains(err.Error(), "mode must be") {
			t.Errorf("got %v, want a mode error", err)
		}
	})
}

func TestBorderColors(t *testing.T) {
	t.Run("pushes both colours as runtime values", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		wayfireHome(t)
		if err := runAct([]string{"decoration.borderColors", "#AABBCC", "112233"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "wayfire/set-config-options",
			`{"decoration/active_color":"#aabbccff","decoration/inactive_color":"#112233ff"}`)
	})

	t.Run("garbage colours", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"decoration.borderColors", "salad", "mayo"})
		if err == nil || !strings.Contains(err.Error(), "no usable colour") {
			t.Errorf("got %v, want a colour error", err)
		}
	})

	t.Run("missing argument", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"decoration.borderColors"})
		if err == nil || !strings.Contains(err.Error(), "missing active colour") {
			t.Errorf("got %v, want a missing-argument error", err)
		}
	})

	t.Run("a fixed border colour wins over the wallpaper", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		wayfireHome(t)
		if err := os.MkdirAll(filepath.Join(configHome(), "ryoku"), 0o755); err != nil {
			t.Fatal(err)
		}
		store := filepath.Join(configHome(), "ryoku", "desktop.json")
		body := `{"desktop":{"appearance":{"borderFollowsPalette":false}}}`
		if err := os.WriteFile(store, []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
		if err := runAct([]string{"decoration.borderColors", "#AABBCC", "112233"}); err != nil {
			t.Fatal(err)
		}
		if len(*calls) != 0 {
			t.Errorf("gate off must not push, got %v", *calls)
		}
		if _, err := os.Stat(borderPalettePath()); !os.IsNotExist(err) {
			t.Errorf("gate off must not write the palette file, got err %v", err)
		}
	})

	t.Run("the palette file hands the composer both colours", func(t *testing.T) {
		stubAct(t, stageReplies())
		wayfireHome(t)
		if err := runAct([]string{"decoration.borderColors", "#AABBCC", "112233"}); err != nil {
			t.Fatal(err)
		}
		active, inactive, ok := borderPaletteColors()
		if !ok || active != "#aabbcc" || inactive != "#112233" {
			t.Errorf("palette file = %q/%q, %v; want #aabbcc/#112233, true", active, inactive, ok)
		}
	})

	t.Run("one unusable side keeps the stored one", func(t *testing.T) {
		stubAct(t, stageReplies())
		wayfireHome(t)
		prev := `{"active":"#111111","inactive":"#222222"}`
		if err := os.MkdirAll(filepath.Dir(borderPalettePath()), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(borderPalettePath(), []byte(prev), 0o644); err != nil {
			t.Fatal(err)
		}
		if err := runAct([]string{"decoration.borderColors", "#AABBCC", "salad"}); err != nil {
			t.Fatal(err)
		}
		active, inactive, ok := borderPaletteColors()
		if !ok || active != "#aabbcc" || inactive != "#222222" {
			t.Errorf("palette file = %q/%q, %v; want #aabbcc/#222222, true", active, inactive, ok)
		}
	})
}

func TestOutputCycleAndEnable(t *testing.T) {
	twoClass := func() map[string]string {
		r := stageReplies()
		r["window-rules/list-outputs"] = `[{"id":1,"name":"eDP-1","geometry":{"x":0,"y":0,"width":1920,"height":1080},"wset-index":1,"workspace":{"x":0,"y":0,"grid_width":3,"grid_height":3}},
			{"id":2,"name":"HDMI-A-1","geometry":{"x":1920,"y":0,"width":1920,"height":1080},"wset-index":2,"workspace":{"x":0,"y":0,"grid_width":3,"grid_height":3}}]`
		return r
	}

	t.Run("two classes rotate internal first then external", func(t *testing.T) {
		t.Setenv("XDG_STATE_HOME", t.TempDir())
		calls := stubAct(t, twoClass())
		if err := runAct([]string{"output.cycle"}); err != nil {
			t.Fatal(err)
		}
		// Position 1 is internal only: the target comes on before the
		// other goes off, so no step blanks every screen.
		wantCallN(t, *calls, "wayfire/set-config-options", 0, `{"output:eDP-1/mode":"auto"}`)
		wantCallN(t, *calls, "wayfire/set-config-options", 1, `{"output:HDMI-A-1/mode":"off"}`)
		if err := runAct([]string{"output.cycle"}); err != nil {
			t.Fatal(err)
		}
		wantCallN(t, *calls, "wayfire/set-config-options", 2, `{"output:HDMI-A-1/mode":"auto"}`)
		wantCallN(t, *calls, "wayfire/set-config-options", 3, `{"output:eDP-1/mode":"off"}`)
	})

	t.Run("one class stays all on", func(t *testing.T) {
		state := t.TempDir()
		t.Setenv("XDG_STATE_HOME", state)
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"output.cycle"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "wayfire/set-config-options", `{"output:HEADLESS-1/mode":"auto"}`)
		b, err := os.ReadFile(filepath.Join(state, "ryoku", "wayfire-output-cycle"))
		if err != nil || string(b) != "0" {
			t.Errorf("cycle position = %q (%v), want 0", b, err)
		}
	})

	t.Run("enable and disable", func(t *testing.T) {
		calls := stubAct(t, stageReplies())
		if err := runAct([]string{"output.enable", "HDMI-A-1", "off"}); err != nil {
			t.Fatal(err)
		}
		wantCall(t, *calls, "wayfire/set-config-options", `{"output:HDMI-A-1/mode":"off"}`)
		if err := runAct([]string{"output.enable", "HDMI-A-1", "on"}); err != nil {
			t.Fatal(err)
		}
		wantCallN(t, *calls, "wayfire/set-config-options", 1, `{"output:HDMI-A-1/mode":"auto"}`)
	})

	t.Run("enable rejects a bad state", func(t *testing.T) {
		stubAct(t, stageReplies())
		err := runAct([]string{"output.enable", "HDMI-A-1", "banana"})
		if err == nil || !strings.Contains(err.Error(), "state must be on or off") {
			t.Errorf("got %v, want a state error", err)
		}
	})
}

// The absences are half the contract: an action whose capability the
// manifest denies must say so by name instead of failing obscurely or,
// worse, pretending.
func TestDeniedAndUnknownActions(t *testing.T) {
	cases := []struct {
		args []string
		want string
	}{
		{[]string{"output.power", "off"}, "outputPower"},
		{[]string{"submap.enter"}, "submap"},
		{[]string{"overview.toggle"}, "nativeOverview"},
		{[]string{"config.reload"}, "configReload"},
		{[]string{"decoration.gameMode", "on"}, "liveConfigEval"},
		{[]string{"input.focusFollowsMouse", "off"}, "liveConfigEval"},
		{[]string{"decoration.screenShader", "on"}, "screenShader"},
		{[]string{"workspace.toggleSpecial"}, "specialWorkspace"},
		{[]string{"cursor.set"}, "cursorSet"},
		{[]string{"cursor.reassert"}, "config block"},
		{[]string{"frobnicate"}, "unknown action"},
	}
	for _, c := range cases {
		stubAct(t, map[string]string{})
		err := runAct(c.args)
		if err == nil || !strings.Contains(err.Error(), c.want) {
			t.Errorf("runAct(%v) = %v, want an error naming %q", c.args, err, c.want)
		}
	}
}

// Ending the session signals the process that owns the socket, so a path no
// process holds must refuse rather than signal something arbitrary.
func TestSessionExitNeedsAnOwner(t *testing.T) {
	t.Setenv("XDG_RUNTIME_DIR", t.TempDir())
	t.Setenv("WAYFIRE_SOCKET", filepath.Join(t.TempDir(), "absent.socket"))
	stubAct(t, map[string]string{})
	err := runAct([]string{"session.exit"})
	if err == nil || !strings.Contains(err.Error(), "no listener bound to") {
		t.Errorf("got %v, want a no-listener error", err)
	}
}

func TestNightlightTempClamps(t *testing.T) {
	cases := []struct {
		in   []string
		want int
	}{
		{nil, 4000},
		{[]string{"5000"}, 5000},
		{[]string{"500"}, 1000},
		{[]string{"99999"}, 25000},
		{[]string{"cold"}, 4000},
	}
	for _, c := range cases {
		if got := nightlightTemp(c.in); got != c.want {
			t.Errorf("nightlightTemp(%v) = %d, want %d", c.in, got, c.want)
		}
	}
}
