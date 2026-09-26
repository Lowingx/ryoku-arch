// The SYSTEM panel: this machine as a home server, read-only. Seven sections
// from one /api/system snapshot plus the deterministic tips. Every command
// shown is a copy target for the reader's own terminal: the page exposes no
// start/stop/prune button anywhere, because rashin watching your machine must
// never be rashin touching it. Sections stamp their own collection time and
// mark stale instead of hiding an old value or pretending it is fresh.

import { escapeHtml } from "./markdown.js";
import { api } from "./api.js";
import { humanBytes } from "./format.js";

const REFRESH_MS = 30_000;

function stampAge(iso) {
  if (!iso) return "";
  const s = Math.max(0, (Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 45) return "just now";
  if (s < 3600) return Math.round(s / 60) + " min ago";
  return Math.round(s / 3600) + " h ago";
}

function stale(meta) {
  if (!meta || !meta.collectedAt) return true;
  return (Date.now() - new Date(meta.collectedAt).getTime()) / 1000 > 120;
}

function table(rows, cols) {
  if (!rows || !rows.length) return "";
  return (
    '<table class="sys-t"><thead><tr>' +
    cols.map((c) => "<th>" + c[0] + "</th>").join("") +
    "</tr></thead><tbody>" +
    rows
      .map(
        (r) =>
          "<tr>" +
          cols.map((c) => "<td" + (c[2] ? ' class="' + c[2] + '"' : "") + ">" + c[1](r) + "</td>").join("") +
          "</tr>"
      )
      .join("") +
      "</tbody></table>"
  );
}

function note(text) {
  return text ? '<p class="sys-note dim">' + escapeHtml(text) + "</p>" : "";
}

function stateChip(active, sub) {
  const cls = active === "active" && sub === "running" ? "ok" : active === "failed" ? "bad" : active === "active" ? "exited" : "off";
  return '<span class="s-chip ' + cls + '">' + escapeHtml(active + (sub && sub !== active ? " / " + sub : "")) + "</span>";
}

function esc(s) {
  return escapeHtml(String(s == null ? "" : s));
}

function shortRFC(s) {
  if (!s || s === "-") return "-";
  const d = new Date(s);
  if (isNaN(d)) return s;
  return d.toLocaleString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
}

export function renderSystem(root, inv) {
  const sections = {
    services: renderServices,
    timers: renderTimers,
    schedules: renderSchedules,
    containers: renderContainers,
    listeners: renderListeners,
    processes: renderProcesses,
    mounts: renderMounts,
  };
  for (const [key, fn] of Object.entries(sections)) {
    const body = root.querySelector('[data-body="' + key + '"]');
    const count = root.querySelector('[data-count="' + key + '"]');
    if (!body) continue;
    try {
      fn(body, count, inv[key], inv);
    } catch (err) {
      body.innerHTML = '<p class="stamp-bad">this section could not be rendered</p>';
    }
  }
  renderTips(root.querySelector("[data-sys-tips]"), inv.tips);
  const stampEl = root.querySelector("[data-sys-stamp]");
  if (stampEl) {
    stampEl.textContent = "snapshot " + stampAge(inv.collectedAt);
    stampEl.classList.toggle("stale", stale(inv));
  }
}

let serviceFilter = "running";

export function bindSystemFilters(root, inv) {
  root.querySelectorAll("[data-filter=services] .chip").forEach((btn) => {
    btn.addEventListener("click", () => {
      serviceFilter = btn.dataset.state;
      root.querySelectorAll("[data-filter=services] .chip").forEach((b) => b.classList.toggle("active", b === btn));
      if (inv) renderServices(root.querySelector('[data-body="services"]'), root.querySelector('[data-count="services"]'), inv.services, inv);
    });
  });
}

function renderServices(body, count, s, inv) {
  if (!body) return;
  if (!s || !s.totalN) {
    body.innerHTML = note(s && s.note ? s.note : "no service data");
    if (count) count.textContent = "";
    return;
  }
  const rows =
    serviceFilter === "running" ? s.running || [] : serviceFilter === "user" ? s.userOnly || [] : s.stopped || [];
  if (count) count.textContent = s.runningN + " running / " + s.totalN + " units" + (s.userOnly ? " · " + s.userOnly.length + " user" : "");
  body.innerHTML =
    (s.note && serviceFilter !== "running" ? note(s.note) : "") +
    (rows.length
      ? table(rows, [
          ["UNIT", (r) => esc(r.name), "mono"],
          ["", (r) => stateChip(r.activeState, r.subState)],
          ["WHAT", (r) => esc(r.description)],
        ])
      : '<p class="dim">' + (serviceFilter === "user" ? "no user services" : "none") + "</p>");
}

function renderTimers(body, count, t) {
  if (!body) return;
  const active = (t && t.active) || [];
  const passive = (t && t.passive) || [];
  if (!active.length && !passive.length) {
    body.innerHTML = note((t && t.note) || "no systemd timers");
    if (count) count.textContent = "";
    return;
  }
  if (count) count.textContent = active.length + " firing" + (passive.length ? " · " + passive.length + " passive" : "");
  body.innerHTML =
    table(active, [
      ["TIMER", (r) => esc(r.unit), "mono"],
      ["NEXT", (r) => (r.left ? esc(r.left) + " <span class='dim'>/ " + shortRFC(r.nextRun) + "</span>" : shortRFC(r.nextRun))],
      ["LAST", (r) => shortRFC(r.last)],
      ["FIRES", (r) => esc(r.activates || "-"), "mono dim"],
    ]) +
    (passive.length
      ? note("dormant: loaded, enabled-looking, never firing") +
        table(passive, [
          ["TIMER", (r) => esc(r.unit), "mono"],
          ["NEXT", () => "-"],
          ["LAST", (r) => shortRFC(r.last)],
          ["FIRES", (r) => esc(r.activates || "-"), "mono dim"],
        ])
      : "");
}

function renderSchedules(body, count, s) {
  if (!body) return;
  const rows = [
    ...(s.crontabs || []).map((e) => ({ ...e, kind: "cron" })),
    ...(s.anacron || []).map((e) => ({ ...e, kind: "periodic" })),
    ...(s.atJobs || []).map((e) => ({ ...e, kind: "at" })),
  ];
  if (count) count.textContent = rows.length + " entries" + (s.cronActive === false ? " · cron daemon stopped" : s.cronActive ? " · daemon up" : "");
  if (!rows.length && !s.note) {
    body.innerHTML = '<p class="dim">no crontab, anacron, or at entries</p>';
    return;
  }
  const daemon =
    s.cronActive === false
      ? '<p class="sys-note stamp-bad">the cron daemon is not running: none of these fire</p>'
      : "";
  body.innerHTML =
    daemon +
    note(s.note || "") +
    table(rows, [
      ["SCHEDULE", (r) => esc(r.schedule), "mono"],
      ["KIND", (r) => esc(r.kind)],
      ["COMMAND", (r) => esc(r.command), "mono"],
      ["FROM", (r) => esc(r.origin), "dim"],
    ]);
}

function renderContainers(body, count, c) {
  if (!body) return;
  if (count) count.textContent = c ? (c.runningN || 0) + " up / " + (c.totalN || 0) + " total" : "";
  if (!c || !c.installed) {
    body.innerHTML = note((c && c.note) || "docker not installed");
    return;
  }
  if (!c.rows || !c.rows.length) {
    body.innerHTML = note(c.note || "the daemon answers; no containers exist");
    return;
  }
  body.innerHTML =
    note(c.note || "") +
    table(c.rows, [
      ["NAME", (r) => esc(r.name), "mono"],
      ["", (r) => '<span class="s-chip ' + (r.state === "running" ? "ok" : "off") + '">' + esc(r.state) + "</span>"],
      ["IMAGE", (r) => esc(r.image), "dim"],
      ["STATUS", (r) => esc(r.status), "mono"],
      ["CREATED", (r) => esc(r.created), "dim"],
    ]);
}

function renderListeners(body, count, l) {
  if (!body) return;
  const rows = (l && l.rows) || [];
  const loop = rows.filter((r) => r.loopback).length;
  if (count) count.textContent = rows.length + " sockets · " + loop + " loopback";
  body.innerHTML =
    note(l && l.note ? l.note : "") +
    table(rows, [
      ["PROTO", (r) => esc(r.proto), "mono"],
      ["ADDRESS", (r) => esc(r.address) + ":" + esc(r.port), "mono"],
      ["REACH", (r) =>
        r.loopback
          ? '<span class="s-chip ok">this machine</span>'
          : r.address === "*" || r.address === "::" || r.address === "0.0.0.0"
            ? '<span class="s-chip exited">any interface</span>'
            : '<span class="s-chip bad">' + "named interface" + "</span>"],
      ["PROCESS", (r) => esc(r.process || "-"), "dim"],
    ]);
}

function renderProcesses(body, count, p) {
  if (!body) return;
  if (count) count.textContent = ((p && p.rows) || []).length ? "top " + p.rows.length : "";
  body.innerHTML =
    note(p && p.note ? p.note : "") +
    table((p && p.rows) || [], [
      ["CPU %", (r) => Number(r.cpuPct).toFixed(1), "mono num"],
      ["PID", (r) => esc(r.pid), "mono dim"],
      ["PROCESS", (r) => esc(r.command), "mono"],
      ["RSS", (r) => humanBytes(r.memRss), "num dim"],
    ]);
}

function renderMounts(body, count, m) {
  if (!body) return;
  const rows = (m && m.rows) || [];
  if (count) count.textContent = rows.length + " filesystems";
  body.innerHTML =
    note(m && m.note ? m.note : "") +
    table(rows, [
      ["MOUNT", (r) => esc(r.mountpoint), "mono"],
      ["FS", (r) => esc(r.fstype), "dim"],
      ["SIZE", (r) => humanBytes(r.size), "num"],
      ["USED", (r) => humanBytes(r.used), "num"],
      [
        "",
        (r) =>
          '<span class="bar' + (r.usePct >= 90 ? " hot" : r.usePct >= 75 ? " warm" : "") + '"><i style="width:' + Math.min(100, r.usePct).toFixed(0) + '%"></i></span>' +
          '<span class="bar-label num">' + r.usePct.toFixed(0) + "%</span>",
      ],
    ]);
}

function renderTips(body, tips) {
  if (!body) return;
  if (!tips || !tips.length) {
    body.innerHTML = '<p class="dim">nothing asks for attention. the inventory above is current.</p>';
    return;
  }
  body.innerHTML =
    '<h3 class="panel-sub">TIPS <span class="dim">/ read-only advice; the commands are yours to run</span></h3>' +
    tips
      .map(
        (t) =>
          '<article class="tip tip-' + esc(t.severity) + '" data-tip="' + esc(t.id) + '">' +
          '<span class="tip-sev" aria-hidden="true">' + (t.severity === "act" ? "要" : t.severity === "watch" ? "視" : "情") + "</span>" +
          "<div><b>" +
          esc(t.title) +
          "</b><p>" +
          esc(t.detail) +
          "</p>" +
          (t.command
            ? '<button class="cmd" type="button" data-copy="' + esc(t.command) + '" title="copy command"><code>' +
              esc(t.command) +
              "</code><span class='cmd-copy dim'>COPY</span></button>"
            : "") +
          "</div></article>"
      )
      .join("");
}

export function copyButtons(root) {
  root.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-copy]");
    if (!btn) return;
    const text = btn.getAttribute("data-copy");
    (navigator.clipboard ? navigator.clipboard.writeText(text) : Promise.reject()).then(
      () => {
        const s = btn.querySelector(".cmd-copy");
        if (s) {
          s.textContent = "COPIED";
          setTimeout(() => (s.textContent = "COPY"), 1200);
        }
      },
      () => {}
    );
  });
}

export function initSystem(root) {
  if (!root) return;
  let inv = null;
  let timer = 0;
  copyButtons(root);

  async function refresh() {
    try {
      inv = await api.system();
      renderSystem(root, inv);
      bindSystemFilters(root, inv);
      paintOverviewStrip(inv);
    } catch (err) {
      const body = root.querySelector('[data-body="services"]');
      if (body) body.innerHTML = '<p class="stamp-bad">the daemon is not answering /api/system</p>';
    }
  }

  function start() {
    if (timer) return;
    refresh();
    timer = setInterval(refresh, REFRESH_MS);
  }
  function stop() {
    clearInterval(timer);
    timer = 0;
  }
  start();
  document.addEventListener("visibilitychange", () => (document.hidden ? stop() : start()));
}

// Overview strip: the same snapshot feeds the summary row on the poster page.
export function paintOverviewStrip(inv) {
  const get = (k) => document.querySelector('[data-sys="' + k + '"]');
  if (!get("services")) return;
  get("services").textContent = inv.services ? inv.services.runningN + "/" + inv.services.totalN : "--";
  get("timers").textContent = inv.timers ? (inv.timers.active || []).length + ((inv.timers.passive || []).length ? " +" + inv.timers.passive.length + " idle" : "") : "--";
  get("containers").textContent = inv.containers ? (inv.containers.runningN || 0) + "/" + (inv.containers.totalN || 0) : "--";
  get("listeners").textContent = inv.listeners ? (inv.listeners.rows || []).length : "--";
  get("tips").textContent = inv.tips ? inv.tips.length : "--";
  const tipsEl = get("tips");
  if (tipsEl) {
    const act = (inv.tips || []).filter((t) => t.severity === "act").length;
    tipsEl.textContent = act ? act + " act · " + (inv.tips || []).length : String((inv.tips || []).length);
  }
}
