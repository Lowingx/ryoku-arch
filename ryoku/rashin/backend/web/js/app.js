// Dashboard entry point. Boots the router and each panel controller, and paints
// the overview daemon/hermes status stamps from /api/status. Everything degrades
// to dim placeholders when the daemon is absent.

import { initRouter } from "./router.js";
import { initVitals } from "./vitals.js";
import { initVault } from "./vault.js";
import { initAgents } from "./agents.js";
import { initMemory } from "./memory.js";
import { initSkills } from "./skills.js";
import { initAbout } from "./about.js";
import { initCode } from "./code.js";
import { initSystem } from "./system.js";
import { initModels } from "./models.js";
import { initMotion } from "./motion.js";
import { initHero } from "./hero3d.js";
import { paintOverviewStrip } from "./system.js";
import { api } from "./api.js";
import { motion } from "./motion.js";
import "./chat.js";
import { animate, stagger } from "../vendor/anime.min.js";

function stamp(el, ok, okText, badText) {
  if (!el) return;
  el.textContent = ok ? okText : badText;
  el.className = "stamp " + (ok ? "stamp-ok" : "stamp-bad");
}

async function paintStatus() {
  try {
    const s = await api.status();
    stamp(document.querySelector("[data-s=daemon]"), s.running, "OK", "DOWN");
    const h = s.hermes || {};
    stamp(document.querySelector("[data-s=hermes]"), h.installed && h.wired, "OK", "MISSING");
  } catch (err) {
    stamp(document.querySelector("[data-s=daemon]"), false, "OK", "DOWN");
    stamp(document.querySelector("[data-s=hermes]"), false, "OK", "MISSING");
  }
}

// One orchestrated entrance on the poster page: stat blocks and the system
// strip land staggered, like a print sheet being set by hand. It runs once
// per session, never under the motion switch, and touches nothing else.
let revealed = false;
function revealOverview() {
  if (revealed || !motion.on) return;
  revealed = true;
  const targets = document.querySelectorAll('[data-panel="overview"] .stat, [data-panel="overview"] .sys-strip > div, [data-panel="overview"] .code-card');
  animate(targets, {
    opacity: [0, 1],
    translateY: [14, 0],
    delay: stagger(55),
    duration: 520,
    ease: "outExpo",
  });
}

function boot() {
  initMotion();
  initHero(document.querySelector("[data-hero-3d]"));
  const started = {};
  initRouter((name) => {
    if (started[name]) return;
    started[name] = true;
    if (name === "overview") revealOverview();
    if (name === "vault") initVault(document.querySelector('[data-panel="vault"]'));
    else if (name === "system") initSystem(document.querySelector('[data-panel="system"]'));
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
  paintStatus();
  setInterval(paintStatus, 5000);
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", boot);
} else {
  boot();
}
