package main

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
)

// fixsession.go opens a Fix with AI session on the shared chat: a fresh
// conversation (the fix is its own task, not a tangent in whatever the user was
// discussing) whose first turn carries the brief. Every dashboard tab, the
// terminal, and the Hub all land on the same live transcript.

// startFix clears the chat, starts a new agent session, and sends the brief.
// It returns once the session switch is under way; the conversation itself
// streams to every chat client, including ones that join later.
func (h *chatHub) startFix(display, brief string) error {
	h.mu.Lock()
	spawned := h.ensureConnLocked()
	conn := h.conn
	if conn == nil {
		errText := h.last.Error
		h.mu.Unlock()
		if errText == "" {
			errText = "the chat agent is not running"
		}
		return errors.New(errText)
	}
	h.transcript = nil
	h.introduced = true
	h.mu.Unlock()

	h.broadcast(wsOut{Type: "replay_start"})
	h.broadcast(wsOut{Type: "replay_end"})
	h.broadcast(wsOut{Type: "user_text", Text: display})
	h.broadcast(wsOut{Type: "state", State: "busy"})
	go func() {
		// A process spawned just now opens its own first session during
		// Initialize; asking for another would race it.
		if !spawned {
			if err := conn.NewSession(); err != nil {
				h.broadcast(wsOut{Type: "state", State: "dead", Error: err.Error()})
				return
			}
		}
		conn.Prompt(needleIdentity+"[fix: "+brief+"] "+display, nil)
	}()
	return nil
}

// handleFix is POST /api/fix. It drives an agent that can change the machine,
// so a page on another site must not reach it: the Origin must be this
// dashboard, and the JSON content type forces a CORS preflight the daemon
// never grants.
func (h *chatHub) handleFix(w http.ResponseWriter, r *http.Request) {
	if !loopbackOrigin(r) || !strings.HasPrefix(r.Header.Get("Content-Type"), "application/json") {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req fixRequest
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(&req); err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	req.Kind = strings.TrimSpace(req.Kind)
	display, brief, err := buildFix(req)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnprocessableEntity)
		_ = json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}
	if err := h.startFix(display, brief); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusServiceUnavailable)
		_ = json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, map[string]any{"ok": true, "display": display})
}
