package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestFixPromptReplaysAsItsDisplayLine(t *testing.T) {
	tip := Tip{ID: "x", Severity: "act", Title: "unit [a] failed", Detail: "log says ] then [b] ", Command: "journalctl -u a] "}
	display, brief := fixTipBrief(tip)
	prompt := needleIdentity + "[fix: " + brief + "] " + display
	if got := stripIdentityPreamble(prompt); got != display {
		t.Fatalf("replay shows %q, want the display line %q", got, display)
	}
	if got := cleanTitle(prompt); got != display {
		t.Fatalf("session title %q, want %q", got, display)
	}

	issues := []DoctorFinding{{Name: "pacnew", Status: "warn", Detail: "2 files]", Remedy: "sudo pacdiff] "}}
	display, brief = fixDoctorBrief(issues, "/tmp/r]eport.txt")
	if got := stripIdentityPreamble(needleIdentity + "[fix: " + brief + "] " + display); got != display {
		t.Fatalf("doctor replay shows %q, want %q", got, display)
	}
}

func TestCleanTitleDropsATitleCutInsideANote(t *testing.T) {
	cases := map[string]string{
		"plain question":                     "plain question",
		"[system: you are the Needle and so": "",
		"[system: x] [fix: half a brief":     "",
		"[system: x] why is my disk full":    "why is my disk full",
	}
	for in, want := range cases {
		if got := cleanTitle(in); got != want {
			t.Errorf("cleanTitle(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestParseFixArgs(t *testing.T) {
	cases := []struct {
		args     []string
		want     fixRequest
		wantOpen bool
		wantErr  bool
	}{
		{[]string{"doctor"}, fixRequest{Kind: "doctor"}, true, false},
		{[]string{"doctor", "failed", "services", "--no-open"}, fixRequest{Kind: "doctor", Name: "failed services"}, false, false},
		{[]string{"tip", "disk-/"}, fixRequest{Kind: "tip", ID: "disk-/"}, true, false},
		{[]string{"app", "firefox", "crashes", "on", "start"}, fixRequest{Kind: "app", App: "firefox", Note: "crashes on start"}, true, false},
		{[]string{"tip"}, fixRequest{}, true, true},
		{[]string{"app"}, fixRequest{}, true, true},
		{[]string{"reboot"}, fixRequest{}, true, true},
		{nil, fixRequest{}, true, true},
	}
	for _, c := range cases {
		got, open, err := parseFixArgs(c.args)
		if (err != nil) != c.wantErr {
			t.Errorf("%v: err = %v, want error %v", c.args, err, c.wantErr)
			continue
		}
		if c.wantErr {
			continue
		}
		if got != c.want || open != c.wantOpen {
			t.Errorf("%v: got %+v open=%v, want %+v open=%v", c.args, got, open, c.want, c.wantOpen)
		}
	}
}

func TestFixAppRejectsAnythingButAName(t *testing.T) {
	for _, bad := range []string{"", "../etc/passwd", "a b", "$(rm -rf ~)", "x;y", "/usr/bin/firefox", strings.Repeat("a", 65)} {
		if _, _, err := buildFix(fixRequest{Kind: "app", App: bad}); err == nil {
			t.Errorf("app %q was accepted", bad)
		}
	}
	for _, ok := range []string{"firefox", "org.gnome.Nautilus", "ryoku-shell", "wireplumber@", "c++"} {
		if _, _, err := buildFix(fixRequest{Kind: "app", App: ok}); err != nil {
			t.Errorf("app %q rejected: %v", ok, err)
		}
	}
}

func TestDoctorIssuesAreWhatDoctorCouldNotSettle(t *testing.T) {
	scan := DoctorScan{Findings: []DoctorFinding{
		{Name: "a", Status: "ok"}, {Name: "b", Status: "note"}, {Name: "c", Status: "fixed"},
		{Name: "d", Status: "todo"}, {Name: "e", Status: "warn"}, {Name: "f", Status: "fail"},
	}}
	var names []string
	for _, f := range scan.Issues() {
		names = append(names, f.Name)
	}
	if strings.Join(names, ",") != "d,e,f" {
		t.Fatalf("issues = %v, want d,e,f", names)
	}
}

func TestFixEndpointRefusesOtherSites(t *testing.T) {
	h := newChatHub()
	cases := []struct {
		name, origin, ctype string
		want                int
	}{
		{"another site", "https://evil.example", "application/json", http.StatusForbidden},
		{"a form post", "", "text/plain", http.StatusForbidden},
		{"the dashboard, bad kind", "http://127.0.0.1:3600", "application/json", http.StatusUnprocessableEntity},
		{"the CLI, bad kind", "", "application/json; charset=utf-8", http.StatusUnprocessableEntity},
	}
	for _, c := range cases {
		req := httptest.NewRequest(http.MethodPost, "/api/fix", strings.NewReader(`{"kind":"nope"}`))
		if c.origin != "" {
			req.Header.Set("Origin", c.origin)
		}
		req.Header.Set("Content-Type", c.ctype)
		rec := httptest.NewRecorder()
		h.handleFix(rec, req)
		if rec.Code != c.want {
			t.Errorf("%s: status %d, want %d", c.name, rec.Code, c.want)
		}
	}
}
