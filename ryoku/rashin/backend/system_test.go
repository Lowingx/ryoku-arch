package main

import (
	"strings"
	"testing"
)

func TestParseUnitJSON(t *testing.T) {
	out := `[{"unit":"ssh.service","load":"loaded","active":"active","sub":"running","description":"OpenSSH daemon"},` +
		`{"unit":"foo.service","load":"loaded","active":"failed","sub":"failed","description":"Foo"}]`
	rows := parseUnitJSON(out)
	if len(rows) != 2 {
		t.Fatalf("rows = %d, want 2", len(rows))
	}
	if rows[0].Name != "ssh.service" || rows[0].ActiveState != "active" || rows[0].SubState != "running" {
		t.Errorf("row 0 = %+v", rows[0])
	}
	if rows[1].ActiveState != "failed" {
		t.Errorf("row 1 active = %q, want failed", rows[1].ActiveState)
	}
	if parseUnitJSON("not json") != nil {
		t.Error("garbage input must yield nil")
	}
}

func TestParseUnitRowsFallback(t *testing.T) {
	out := `  ssh.service loaded active running OpenSSH daemon
foo.service loaded failed failed Foo thing
`
	rows := parseUnitRows(out)
	if len(rows) != 2 {
		t.Fatalf("rows = %d, want 2", len(rows))
	}
	if rows[0].Description != "OpenSSH daemon" {
		t.Errorf("desc = %q", rows[0].Description)
	}
}

func TestParseTimerJSON(t *testing.T) {
	// next=0 is the loaded-but-never-fires case the panel must surface.
	out := `[{"next":1790460203678729,"last":1790456603677543,"unit":"snapper-cleanup.timer","activates":"snapper-cleanup.service"},` +
		`{"next":0,"last":0,"unit":"shadow.timer","activates":"shadow.service"}]`
	rows := parseTimerJSON(out)
	if len(rows) != 2 {
		t.Fatalf("rows = %d, want 2", len(rows))
	}
	if rows[0].Passive || rows[0].NextRun == "-" || rows[0].Activates != "snapper-cleanup.service" {
		t.Errorf("active row = %+v", rows[0])
	}
	if !rows[1].Passive || rows[1].NextRun != "-" {
		t.Errorf("passive row = %+v", rows[1])
	}
	if rows[0].Left == "" {
		t.Error("active timer must carry a countdown")
	}
}

func TestParseSSListener(t *testing.T) {
	cases := []struct {
		line        string
		wantProto   string
		wantAddr    string
		wantPort    int
		wantProcess string
		wantLoop    bool
		wantOK      bool
	}{
		{`tcp LISTEN 0 4096 127.0.0.1:3600 0.0.0.0:* users:(("ryoku-rashin",pid=944,fd=6))`, "tcp", "127.0.0.1", 3600, "ryoku-rashin", true, true},
		{`udp UNCONN 0 0 0.0.0.0:41641 0.0.0.0:*`, "udp", "0.0.0.0", 41641, "", false, true},
		{`tcp LISTEN 0 128 [::]:22 [::]:*`, "tcp", "::", 22, "", false, true},
		{`tcp LISTEN 0 511 127.0.0.1:6463 0.0.0.0:* users:(("electron",pid=2,fd=119))`, "tcp", "127.0.0.1", 6463, "electron", true, true},
		{`Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:Port`, "", "", 0, "", false, false},
	}
	for _, c := range cases {
		row, ok := parseSSListener(c.line)
		if ok != c.wantOK {
			t.Errorf("parseSSListener(%q) ok = %v, want %v", c.line, ok, c.wantOK)
			continue
		}
		if !ok {
			continue
		}
		if row.Proto != c.wantProto || row.Address != c.wantAddr || row.Port != c.wantPort ||
			row.Process != c.wantProcess || row.Loopback != c.wantLoop {
			t.Errorf("parseSSListener(%q) = %+v", c.line, row)
		}
	}
}

func TestParseCrontab(t *testing.T) {
	out := `# a comment
MAILTO=root
*/5 * * * * /usr/bin/thing --run
@daily /usr/bin/purge
`
	entries := parseCrontab(out, "test")
	if len(entries) != 2 {
		t.Fatalf("entries = %d, want 2: %+v", len(entries), entries)
	}
	if entries[0].Schedule != "*/5 * * * *" || entries[0].Command != "/usr/bin/thing --run" {
		t.Errorf("entry 0 = %+v", entries[0])
	}
	if !strings.HasPrefix(entries[1].Schedule, "@daily") {
		t.Errorf("entry 1 = %+v", entries[1])
	}
}

func TestHumanSpan(t *testing.T) {
	if got := humanSpan(0); got != "0s" && got != "s" {
		// zero duration falls through the unit checks to the seconds clause
		if !strings.HasSuffix(got, "s") {
			t.Errorf("humanSpan(0) = %q", got)
		}
	}
	if got := humanSpan(33 * 60 * 1e9); !strings.Contains(got, "min") {
		t.Errorf("33min = %q", got)
	}
	if got := humanSpan(8*24*3600*1e9 + 3*3600*1e9); !strings.HasPrefix(got, "1w") {
		t.Errorf("week span = %q", got)
	}
}

func TestDeriveTipsGrounded(t *testing.T) {
	inv := &SystemInventory{
		Services: ServiceSection{Stopped: []UnitRow{
			{Name: "broken.service", ActiveState: "failed", LoadState: "loaded"},
			{Name: "ghost.service", ActiveState: "not-found", LoadState: "not-found"},
		}},
		Containers: ContainerSection{Rows: []ContainerRow{
			{Name: "loop", State: "running", Status: "Restarting (1) 2 seconds ago"},
			{Name: "old", State: "exited", Status: "Exited (0) 8 days ago"},
		}},
		Listeners: ListenerSection{Rows: []ListenerRow{
			{Proto: "tcp", Address: "127.0.0.1", Port: 3600, Process: "rashin", Loopback: true},
			{Proto: "tcp", Address: "0.0.0.0", Port: 22},
			{Proto: "tcp", Address: "10.0.0.5", Port: 8080, Process: "serve"},
		}},
	}
	tips := DeriveTips(inv)
	byID := map[string]Tip{}
	for _, tip := range tips {
		byID[tip.ID] = tip
	}
	if _, ok := byID["failed-broken.service"]; !ok {
		t.Error("failed unit must tip")
	}
	if _, ok := byID["dead-ghost.service"]; !ok {
		t.Error("not-found unit must tip as dead")
	}
	if _, ok := byID["container-restart-loop"]; !ok {
		t.Error("crash-looping container must tip")
	}
	if _, ok := byID["exposed-tcp-8080"]; !ok {
		t.Error("named-interface listener must tip")
	}
	if _, ok := byID["exposed-tcp-3600"]; ok {
		t.Error("loopback listener must never tip as exposed")
	}
	if _, ok := byID["wildcard-bind"]; !ok {
		t.Error("wildcard bind must tip once")
	}
	// act ranks before watch before info
	for i := 1; i < len(tips); i++ {
		if sevRank(tips[i-1].Severity) > sevRank(tips[i].Severity) {
			t.Fatalf("tips not severity-ordered at %d: %+v", i, tips)
		}
	}
	for _, tip := range tips {
		if tip.Command == "" || tip.Title == "" {
			t.Errorf("tip without actionable content: %+v", tip)
		}
	}
}
