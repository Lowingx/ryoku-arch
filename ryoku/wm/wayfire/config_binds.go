package main

import (
	"fmt"
	"strconv"
	"strings"
)

// The neutral chord to wayfire's activator spelling, and the store's keybind
// rows onto the command plugin's compound binding options. The sibling of
// niri's config_binds.go: same input rows, wayfire's own output language.

// wayfireModifiers maps the neutral modifier tokens to wayfire's bracket
// spellings, lower-cased on the way in.
var wayfireModifiers = map[string]string{
	"super": "<super>",
	"ctrl":  "<ctrl>",
	"alt":   "<alt>",
	"shift": "<shift>",
}

// wayfireKeys maps the awkward neutral keysym names to wayfire's KEY_ codes.
// Everything else follows two regular shapes: a letter or digit is KEY_<it>,
// and an XF86 keysym is KEY_ plus its upper case. Mouse entries and family
// placeholders have no activator spelling and fall through as unmatched.
var wayfireKeys = map[string]string{
	"Return": "KEY_ENTER", "Enter": "KEY_ENTER",
	"Escape": "KEY_ESC", "Esc": "KEY_ESC",
	"Tab": "KEY_TAB", "BackSpace": "KEY_BACKSPACE", "Delete": "KEY_DELETE",
	"Insert": "KEY_INSERT", "Home": "KEY_HOME", "End": "KEY_END",
	"Prior": "KEY_PAGEUP", "Next": "KEY_PAGEDOWN",
	"PageUp": "KEY_PAGEUP", "PageDown": "KEY_PAGEDOWN",
	"Left": "KEY_LEFT", "Right": "KEY_RIGHT", "Up": "KEY_UP", "Down": "KEY_DOWN",
	"space": "KEY_SPACE", "Space": "KEY_SPACE",
	"grave": "KEY_GRAVE", "minus": "KEY_MINUS", "equal": "KEY_EQUAL",
	"comma": "KEY_COMMA", "period": "KEY_DOT", "slash": "KEY_SLASH",
	"backslash": "KEY_BACKSLASH", "semicolon": "KEY_SEMICOLON",
	"apostrophe":  "KEY_APOSTROPHE",
	"bracketleft": "KEY_LEFTBRACE", "bracketright": "KEY_RIGHTBRACE",
	"Print": "KEY_SYSRQ", "Pause": "KEY_PAUSE",
	"Caps_Lock": "KEY_CAPSLOCK", "Num_Lock": "KEY_NUMLOCK",
	"Scroll_Lock": "KEY_SCROLLLOCK",
	"KP_Enter":    "KEY_KPENTER", "KP_Add": "KEY_KPPLUS",
	"KP_Subtract": "KEY_KPMINUS", "KP_Multiply": "KEY_KPASTERISK",
	"KP_Divide": "KEY_KPSLASH", "KP_Decimal": "KEY_KPDOT",
	"KP_Separator": "KEY_KPDOT",
}

// toWayfireActivator converts a neutral chord ("Super+Shift+Left") into the
// activator wayfire parses ("<super> <shift> KEY_LEFT"). ok is false for a
// chord with no wayfire spelling, so apply reports it rather than writing a
// bind that never fires.
func toWayfireActivator(chord string) (string, bool) {
	parts := strings.Split(chord, "+")
	tokens := make([]string, 0, len(parts))
	for i, p := range parts {
		tok := strings.TrimSpace(p)
		if tok == "" {
			return "", false
		}
		if i < len(parts)-1 {
			m, ok := wayfireModifiers[strings.ToLower(tok)]
			if !ok {
				return "", false
			}
			tokens = append(tokens, m)
			continue
		}
		k, ok := wayfireKey(tok)
		if !ok {
			return "", false
		}
		tokens = append(tokens, k)
	}
	return strings.Join(tokens, " "), true
}

// wayfireKey spells the chord's final token: a modifier on its own (the bare
// "Super" chord), a mapped keysym, a letter or digit, an XF86 keysym, or a
// function key.
func wayfireKey(tok string) (string, bool) {
	if m, ok := wayfireModifiers[strings.ToLower(tok)]; ok {
		return m, true
	}
	if k, ok := wayfireKeys[tok]; ok {
		return k, true
	}
	upper := strings.ToUpper(tok)
	if len(tok) == 1 {
		c := tok[0]
		switch {
		case c >= 'a' && c <= 'z', c >= 'A' && c <= 'Z', c >= '0' && c <= '9':
			return "KEY_" + upper, true
		}
	}
	if strings.HasPrefix(tok, "XF86") {
		return "KEY_" + upper, true
	}
	if strings.HasPrefix(tok, "F") && len(tok) > 1 && len(tok) <= 3 {
		if _, err := strconv.Atoi(tok[1:]); err == nil {
			return "KEY_" + upper, true
		}
	}
	if strings.HasPrefix(tok, "KP_") {
		if d := strings.TrimPrefix(tok, "KP_"); len(d) == 1 && d[0] >= '0' && d[0] <= '9' {
			return "KEY_KP" + d, true
		}
	}
	return "", false
}

// keybindWhy is the reason a store row has no wayfire spelling, or "" when it
// does. An unset chord is not a loss: the row is simply empty, the way the
// sibling writers treat it.
func keybindWhy(k Keybind) string {
	if strings.TrimSpace(k.Keys) == "" {
		return ""
	}
	if k.Action != "exec" {
		return fmt.Sprintf("wayfire binds shell commands; it cannot bind the %q action.", k.Action)
	}
	if strings.TrimSpace(k.Value) == "" {
		return "an exec bind needs a command to run."
	}
	if _, ok := toWayfireActivator(k.Keys); !ok {
		return fmt.Sprintf("wayfire cannot bind the chord %q.", k.Keys)
	}
	return ""
}

// genWayfireBinds renders the store's keybind rows into the command plugin's
// compound options: a command_<id> and a binding_<id> pair per exec bind (or a
// release_binding_<id> variant for a release bind), grouped by the shared id.
// Rows with no spelling are skipped here and named by unhonoredKeybinds, which
// asks keybindWhy the same question, so the two lists can never disagree.
func genWayfireBinds(s wayfireStore) iniDoc {
	var d iniDoc
	for i, k := range s.Keybinds {
		if strings.TrimSpace(k.Keys) == "" {
			continue
		}
		if keybindWhy(k) != "" {
			continue
		}
		activator, _ := toWayfireActivator(k.Keys)
		id := fmt.Sprintf("ryoku_%d", i)
		d.set("command", "command_"+id, strings.TrimSpace(k.Value))
		binding := "binding_" + id
		if k.Release {
			binding = "release_binding_" + id
		}
		d.set("command", binding, activator)
	}
	return d
}
