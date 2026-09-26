// Code intelligence card on the overview panel. Prefers the live Prowl API
// proxy (/api/code/*: fresh index counts, clusters, doctor score) and falls
// back to the daemon's cached report (/api/prowl) when the api service is not
// reachable, so the card answers on any box with an index even before the
// api daemon exists. Installed-but-unindexed shows an init hint; not installed
// (or any fetch failure) leaves the card hidden. Never throws.

import { escapeHtml } from "./markdown.js";
import { api } from "./api.js";

function base(p) {
  const s = String(p || "");
  const parts = s.replace(/\/+$/, "").split("/");
  return parts[parts.length - 1] || s;
}

export function initCode(root) {
  const card = root.querySelector("[data-code-card]");
  const repoEl = root.querySelector("[data-code-repo]");
  const bodyEl = root.querySelector("[data-code-body]");
  if (!card) return;

  function stamp(cls, letter, n) {
    return '<span class="stamp ' + cls + '">' + letter + " " + (Number(n) || 0) + "</span>";
  }

  function renderFromLive(ov, st) {
    const c = ov.counts || {};
    const langs = Object.entries(c.langs || {})
      .sort((a, b) => b[1] - a[1])
      .slice(0, 4)
      .map(([l, n]) => l + " " + n)
      .join(" · ");
    const clusters = (ov.clusters || []).slice(0, 4);
    const score = st.doctorScore;
    bodyEl.innerHTML =
      '<div class="code-stamps">' +
      stamp("stamp-ok", "FILES", c.files) +
      stamp("stamp-idle", "SYMBOLS", c.symbols) +
      stamp("stamp-idle", "EDGES", c.edges) +
      (Number.isFinite(score) ? stamp(score >= 80 ? "stamp-ok" : "stamp-warn", "SCORE", score) : "") +
      "</div>" +
      '<div class="code-counts">' +
      escapeHtml(langs || "indexed") +
      (ov.entrypoint_count ? " · " + ov.entrypoint_count + " entrypoints" : "") +
      "</div>" +
      (clusters.length
        ? '<div class="code-hot">' +
          clusters
            .map(
              (cl) =>
                '<div class="code-hot-row"><span class="code-hot-file dim">' +
                escapeHtml(cl.label || "") +
                '</span><span class="code-hot-in">' +
                (cl.files || 0) +
                "</span></div>"
            )
            .join("") +
          "</div>"
        : "");
  }

  function renderFromReport(d) {
    const doc = d.doctor || {};
    bodyEl.innerHTML =
      '<div class="code-stamps">' +
      stamp(doc.errors > 0 ? "stamp-vermillion" : "stamp-idle", "E", doc.errors) +
      stamp(doc.warns > 0 ? "stamp-warn" : "stamp-idle", "W", doc.warns) +
      stamp("stamp-idle", "I", doc.infos) +
      "</div>" +
      '<div class="code-counts">' +
      (Number(d.files) || 0) +
      " files / " +
      (Number(d.symbols) || 0) +
      " symbols</div>" +
      ((d.hotspots || []).length
        ? '<div class="code-hot">' +
          d.hotspots
            .slice(0, 5)
            .map(
              (h) =>
                '<div class="code-hot-row"><span class="code-hot-file dim">' +
                escapeHtml(h.file || "") +
                '</span><span class="code-hot-in">' +
                (Number(h.in) || 0) +
                "</span></div>"
            )
            .join("") +
          "</div>"
        : "");
  }

  async function load() {
    // live first: the api answers current counts straight off the index
    try {
      const st = await api.codeStatus();
      if (st && st.installed) {
        repoEl.textContent = base(st.repo) + (st.serving ? " · live" : " · cached");
        card.hidden = false;
        if (st.serving) {
          try {
            const ov = await api.code("overview");
            renderFromLive(ov, st);
            return;
          } catch (err) {
            /* fall through to the cached report */
          }
        }
      } else {
        card.hidden = true;
        return;
      }
    } catch (err) {
      /* pre-api daemons: the proxy route does not exist yet */
    }
    let d;
    try {
      d = await api.status ? await getJSON("/api/prowl") : null;
    } catch (err) {
      card.hidden = true;
      return;
    }
    if (!d || !d.installed) {
      card.hidden = true;
      return;
    }
    repoEl.textContent = base(d.repo);
    if (!d.indexed) {
      bodyEl.innerHTML = '<p class="dim">index missing: run <code>prowl init</code> in your repo</p>';
      return;
    }
    renderFromReport(d);
    card.hidden = false;
  }

  load();
}

async function getJSON(path) {
  const r = await fetch(path, { headers: { accept: "application/json" } });
  if (!r.ok) throw new Error(path + " -> " + r.status);
  return r.json();
}
