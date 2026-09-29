package doctor

import (
	"encoding/json"
	"testing"
)

// The strip drops the paper.awww object and a paper.engine left on the retired
// "awww", keeps every other paper key (a live engine selection included), and
// no-ops once both are gone.
func TestStripRetiredAwwwKeys(t *testing.T) {
	full := []byte(`{"paper":{"engine":"awww","videoEngine":"in_shell","awww":{"filter":"Lanczos3","transitionType":"wipe"}},"general":{"uiScale":1}}`)
	out, changed, err := stripRetiredAwwwKeys(full)
	if err != nil || !changed {
		t.Fatalf("retired awww keys must be stripped: changed=%v err=%v", changed, err)
	}
	var cfg map[string]any
	if err := json.Unmarshal(out, &cfg); err != nil {
		t.Fatalf("stripped JSON does not parse: %v", err)
	}
	paper, ok := cfg["paper"].(map[string]any)
	if !ok {
		t.Fatalf("paper namespace lost: %v", cfg)
	}
	if _, present := paper["awww"]; present {
		t.Errorf("fix did not strip paper.awww")
	}
	if _, present := paper["engine"]; present {
		t.Errorf("retired engine value must be dropped so the schema default applies, got %v", paper["engine"])
	}
	if paper["videoEngine"] != "in_shell" {
		t.Errorf("live paper key videoEngine was lost or altered: %v", paper)
	}
	if _, present := cfg["general"]; !present {
		t.Errorf("passthrough key general was lost: %v", cfg)
	}

	// stripping is idempotent: the cleaned store is now a no-op.
	if _, changed, err := stripRetiredAwwwKeys(out); err != nil || changed {
		t.Errorf("re-stripping a clean store must be a no-op: changed=%v err=%v", changed, err)
	}

	// a live engine selection survives untouched.
	live := []byte(`{"paper":{"engine":"skwd-paper","awww":{"filter":"Lanczos3"}}}`)
	out, changed, err = stripRetiredAwwwKeys(live)
	if err != nil || !changed {
		t.Fatalf("the retired object must be stripped even with a live engine: changed=%v err=%v", changed, err)
	}
	var live2 map[string]any
	if err := json.Unmarshal(out, &live2); err != nil {
		t.Fatalf("stripped JSON does not parse: %v", err)
	}
	if got := live2["paper"].(map[string]any)["engine"]; got != "skwd-paper" {
		t.Errorf("live engine was altered: %v", got)
	}

	// a paper namespace left empty after the strip is removed whole.
	only := []byte(`{"paper":{"engine":"awww"},"bars":{}}`)
	out, changed, err = stripRetiredAwwwKeys(only)
	if err != nil || !changed {
		t.Fatalf("changed=%v err=%v", changed, err)
	}
	var only2 map[string]any
	if err := json.Unmarshal(out, &only2); err != nil {
		t.Fatalf("stripped JSON does not parse: %v", err)
	}
	if _, present := only2["paper"]; present {
		t.Errorf("an emptied paper namespace must be dropped, got %v", only2["paper"])
	}

	// a store with no paper namespace is untouched.
	if _, changed, err := stripRetiredAwwwKeys([]byte(`{"bars":{}}`)); err != nil || changed {
		t.Errorf("a store with no paper namespace must be untouched: changed=%v err=%v", changed, err)
	}
}
