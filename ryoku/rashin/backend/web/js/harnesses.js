// The harness ledger: every installed coding agent, what it knows, where it
// keeps it. Backs both the Agents panel ledger and the Skills panel "by
// harness" strip from one /api/harnesses fetch. Credential rows show names
// only, because the daemon reports names only: an agent OS that leaked keys
// through its own dashboard would be a joke.

import { escapeHtml } from "./markdown.js";
import { humanBytes } from "./format.js";
import { api } from "./api.js";

export const harnessCache = { data: null, at: 0, promise: null };

// loadHarnesses shares one in-flight fetch between the two panels so a panel
// swap never doubles the scan; 60s freshness matches the daemon TTL.
export function loadHarnesses() {
  const now = Date.now();
  if (harnessCache.data && now - harnessCache.at < 60_000) return Promise.resolve(harnessCache.data);
  if (!harnessCache.promise) {
    harnessCache.promise = api
      .harnesses()
      .then((d) => {
        harnessCache.data = d.harnesses || [];
        harnessCache.at = Date.now();
        harnessCache.promise = null;
        return harnessCache.data;
      })
      .catch((err) => {
        harnessCache.promise = null;
        throw err;
      });
  }
  return harnessCache.promise;
}

function ago(iso) {
  if (!iso) return "";
  const s = (Date.now() - new Date(iso).getTime()) / 1000;
  if (!Number.isFinite(s) || s < 0) return "";
  if (s < 90) return "moments ago";
  if (s < 3600) return Math.round(s / 60) + " min ago";
  if (s < 86400) return Math.round(s / 3600) + " h ago";
  return Math.round(s / 86400) + " d ago";
}

const esc = (s) => escapeHtml(String(s == null ? "" : s));

function kindIcon(kind) {
  return kind === "db" ? "▤" : kind === "dir" ? "▣" : "▢";
}

export function renderLedger(root, rows) {
  if (!root) return;
  const present = rows.filter((h) => h.present);
  if (!present.length) {
    root.innerHTML = '<p class="dim">no coding agents detected on this machine.</p>';
    return;
  }
  root.innerHTML = present
    .map((h) => {
      const skills = h.skills || [];
      const origins = {};
      skills.forEach((s) => (origins[s.origin] = (origins[s.origin] || 0) + 1));
      const chips = Object.entries(origins)
        .map(([k, v]) => '<span class="h-chip">' + esc(k) + " " + v + "</span>")
        .join("");
      const mem = (h.memories || [])
        .map(
          (m) =>
            '<li title="' + esc(m.path) + '"><span class="dim">' + kindIcon(m.kind) + "</span> " +
            esc(m.name) +
            (m.bytes ? ' <span class="dim">' + humanBytes(m.bytes) + "</span>" : "") +
            (m.entries ? ' <span class="dim">' + m.entries + " files</span>" : "") +
            (m.modified ? ' <span class="dim">' + ago(m.modified) + "</span>" : "") +
            "</li>"
        )
        .join("");
      const creds = (h.creds || []).map((c) => '<code class="cred">' + esc(c.label) + "</code>").join(" ");
      return (
        '<article class="h-card' + (h.wired ? " wired" : "") + '" data-harness="' + esc(h.id) + '">' +
        '<header><b>' + esc(h.name) + "</b>" +
        '<span class="dim">' + esc(h.version || "") + "</span>" +
        '<span class="h-state">' + (h.wired ? "WIRED" : "PRESENT") + "</span></header>" +
        '<p class="h-meta"><em>' + esc(h.home) + "</em>" +
        (h.model ? ' · model <code>' + esc(h.model) + "</code>" : "") +
        (h.provider ? ' <span class="dim">(' + esc(h.provider) + ")</span>" : "") +
        (h.sessions ? ' · ' + h.sessions + " sessions" + (h.lastActive ? ' <span class="dim">' + ago(h.lastActive) + "</span>" : "") : "") +
        "</p>" +
        '<div class="h-skills"><b>' + (h.skillCount || 0) + "</b> skills " + chips + "</div>" +
        (mem ? '<ul class="h-mem">' + mem + "</ul>" : "") +
        (creds ? '<p class="h-creds"><em>keys by name only</em> ' + creds + "</p>" : "") +
        "</article>"
      );
    })
    .join("");
}

export function renderHarnessSkills(root, rows) {
  if (!root) return;
  const present = rows.filter((h) => h.present && (h.skillCount || 0) > 0);
  if (!present.length) {
    root.innerHTML = '<p class="dim">no harness skills found.</p>';
    return;
  }
  root.innerHTML = present
    .map(
      (h) =>
        '<a class="h-skill-cell" href="#/skills" data-harness-skill="' + esc(h.id) + '">' +
        "<b>" + esc(h.name) + "</b><span>" + h.skillCount + " skills</span>" +
        '<span class="dim">' +
        (h.skills || [])
          .slice(0, 4)
          .map((s) => esc(s.name))
          .join(" · ") +
        ((h.skills || []).length > 4 ? " …" : "") +
        "</span></a>"
    )
    .join("");
}

export function initLedger(container) {
  if (!container) return;
  loadHarnesses()
    .then((rows) => renderLedger(container, rows))
    .catch(() => {
      container.innerHTML = '<p class="dim">the daemon did not answer /api/harnesses.</p>';
    });
}
