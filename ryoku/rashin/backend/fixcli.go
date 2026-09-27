package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os/exec"
	"strings"
	"time"
)

const fixUsage = `usage: ryoku-rashin fix doctor [finding name]
       ryoku-rashin fix tip <id>
       ryoku-rashin fix app <name> [what happened...]

Hands the problem to Rashin's agent in a fresh chat and opens it in the
dashboard. The agent reads the logs itself, explains the cause, and asks
before it changes anything. Add --no-open to skip opening the browser.`

// fixKinds are the problems Fix with AI knows how to brief.
var fixKinds = map[string]bool{"doctor": true, "tip": true, "app": true}

// parseFixArgs maps the command line onto a fix request.
func parseFixArgs(args []string) (req fixRequest, open bool, err error) {
	open = true
	var rest []string
	for _, a := range args {
		if a == "--no-open" {
			open = false
			continue
		}
		rest = append(rest, a)
	}
	if len(rest) == 0 {
		return req, open, errors.New(fixUsage)
	}
	req.Kind = rest[0]
	switch req.Kind {
	case "doctor":
		req.Name = strings.Join(rest[1:], " ")
	case "tip":
		if len(rest) < 2 {
			return req, open, errors.New(fixUsage)
		}
		req.ID = rest[1]
	case "app":
		if len(rest) < 2 {
			return req, open, errors.New(fixUsage)
		}
		req.App = rest[1]
		req.Note = strings.Join(rest[2:], " ")
	default:
		return req, open, errors.New(fixUsage)
	}
	return req, open, nil
}

func cmdFix(args []string) error {
	req, open, err := parseFixArgs(args)
	if err != nil {
		return err
	}
	cfg := LoadConfig()
	body, _ := json.Marshal(req)
	// A doctor fix may run the health check first, which takes a few seconds.
	client := &http.Client{Timeout: 2 * time.Minute}
	resp, err := client.Post(fmt.Sprintf("http://127.0.0.1:%d/api/fix", cfg.Port), "application/json", bytes.NewReader(body))
	if err != nil {
		return errors.New("the Rashin daemon is not running; start it with `ryoku-rashin enable`")
	}
	defer resp.Body.Close()
	var out struct {
		Display string `json:"display"`
		Error   string `json:"error"`
	}
	_ = json.NewDecoder(resp.Body).Decode(&out)
	if resp.StatusCode != http.StatusOK {
		if out.Error == "" {
			out.Error = resp.Status
		}
		return errors.New(out.Error)
	}
	chat := fmt.Sprintf("http://127.0.0.1:%d/#/chat", cfg.Port)
	fmt.Printf("%s\nFollow it in the chat: %s\n", out.Display, chat)
	if open {
		if bin, err := exec.LookPath("xdg-open"); err == nil {
			_ = exec.Command(bin, chat).Start()
		}
	}
	return nil
}
