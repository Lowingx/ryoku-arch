package doctor

import (
	"encoding/json"
	"os"
	"path/filepath"

	"ryoku-cli/internal/sys"

	i18n "ryoku-i18n"
)

// awww is gone from the [ryoku] repo and from Ryogami's engine list, but a
// machine that used it still carries paper.awww.* and may still name awww in
// paper.engine. A stored engine the schema no longer offers makes the picker
// show a dead selection, so this drops the retired object and clears the
// engine back to the shell default. Surgical and idempotent: a store already
// free of both is left alone.
func reconcileRetiredAwwwKeys(checkOnly bool) recResult {
	path := filepath.Join(sys.ConfigHome(), "ryoku", "ryogami.json")
	raw, err := os.ReadFile(path)
	if err != nil {
		return okRes(i18n.T("no ryogami.json yet (seeded on first picker run)"))
	}
	migrated, changed, err := stripRetiredAwwwKeys(raw)
	if err != nil {
		return warnRes(i18n.T("ryogami.json does not parse (%v); Ryogami falls back to defaults"), err).
			withFix(i18n.T("delete %s to re-seed it"), path)
	}
	if !changed {
		return okRes(i18n.T("ryogami.json carries no retired awww keys"))
	}
	if checkOnly {
		return wouldRes(i18n.T("ryogami.json still carries retired awww keys")).
			withFix(i18n.T("ryoku doctor strips them in place"))
	}
	tmp := path + ".ryoku-tmp"
	if err := os.WriteFile(tmp, migrated, 0o644); err != nil {
		return failRes(i18n.T("could not write %s: %v"), tmp, err)
	}
	if err := os.Rename(tmp, path); err != nil {
		os.Remove(tmp)
		return failRes(i18n.T("could not replace %s: %v"), path, err)
	}
	return fixedRes(i18n.T("stripped the retired awww keys from ryogami.json"))
}

// stripRetiredAwwwKeys drops the paper.awww object and a paper.engine left set
// to the retired "awww" from a Ryogami store, keeping every other key as its
// own raw bytes. An absent paper object, or one already free of both, is a
// no-op; a malformed paper object errors rather than being rewritten.
func stripRetiredAwwwKeys(raw []byte) (out []byte, changed bool, err error) {
	var top map[string]json.RawMessage
	if err = json.Unmarshal(raw, &top); err != nil {
		return nil, false, err
	}
	paperRaw, ok := top["paper"]
	if !ok {
		return nil, false, nil
	}
	var paper map[string]json.RawMessage
	if err = json.Unmarshal(paperRaw, &paper); err != nil {
		return nil, false, err
	}
	if _, ok := paper["awww"]; ok {
		delete(paper, "awww")
		changed = true
	}
	if engRaw, ok := paper["engine"]; ok {
		var eng string
		if json.Unmarshal(engRaw, &eng) == nil && eng == "awww" {
			delete(paper, "engine")
			changed = true
		}
	}
	if !changed {
		return nil, false, nil
	}
	if len(paper) == 0 {
		delete(top, "paper")
	} else {
		repacked, err := json.Marshal(paper)
		if err != nil {
			return nil, false, err
		}
		top["paper"] = repacked
	}
	out, err = json.MarshalIndent(top, "", "  ")
	if err != nil {
		return nil, false, err
	}
	return append(out, '\n'), true, nil
}
