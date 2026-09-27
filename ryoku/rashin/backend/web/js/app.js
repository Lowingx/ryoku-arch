// Console entry point: boots the router and each panel controller once, and
// paints the header status chips from /api/status + /api/code/status.
// Everything degrades to dim placeholders when the daemon is absent.

import { initRouter } from "./router.js";
import { initVitals } from "./vitals.js";
import { initVault } from "./vault.js";
import { initAgents } from "./agents.js";
import { initMemory } from "./memory.js";
import { initSkills } from "./skills.js";
import { initAbout } from "./about.js";
import { initCode } from "./code.js";
import { initSystem, paintOverviewStrip } from "./system.js";
import { initModels } from "./models.js";
import { api } from "./api.js";
import "./chat.js";

function chip(sel, ok) {
  const el = document.querySelector(sel);
  if (!el) return;
  el.classList.toggle("ok", !!ok);
  el.classList.toggle("bad", ok === false);
}

async function paintStatus() {
  try {
    const s = await api.status();
    chip("[data-s=daemon]", s.running);
    const h = s.hermes || {};
    chip("[data-s=hermes]", h.installed && h.wired);
  } catch (err) {
    chip("[data-s=daemon]", false);
    chip("[data-s=hermes]", false);
  }
  try {
    const c = await api.codeStatus();
    chip("[data-s=prowl]", c.installed && c.serving);
  } catch (err) {
    chip("[data-s=prowl]", false);
  }
  const dot = document.querySelector("[data-live-dot]");
  if (dot) dot.classList.toggle("live", document.visibilityState === "visible");
}

function boot() {
  const started = {};
  initRouter((name) => {
    if (started[name]) return;
    started[name] = true;
    if (name === "system") initSystem(document.querySelector('[data-panel="system"]'));
    else if (name === "vault") initVault(document.querySelector('[data-panel="vault"]'));
    else if (name === "memory") initMemory(document.querySelector('[data-panel="memory"]'));
    else if (name === "skills") initSkills(document.querySelector('[data-panel="skills"]'));
    else if (name === "about") initAbout(document.querySelector('[data-panel="about"]'));
    else if (name === "agents") initAgents(document.querySelector('[data-panel="agents"]'));
    else if (name === "models") initModels(document.querySelector('[data-panel="models"]'));
    else if (name === "chat") {
      const el = document.querySelector('[data-panel="chat"]');
      if (typeof window.initChat === "function") window.initChat(el);
    }
  });
  initVitals(document.querySelector('[data-panel="overview"]'));
  initCode(document.querySelector('[data-panel="overview"]'));
  api.system().then(paintOverviewStrip).catch(() => {});
  const host = document.querySelector("[data-hostname]");
  if (host) host.textContent = location.hostname;
  paintStatus();
  setInterval(paintStatus, 5000);
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", boot);
} else {
  boot();
}
