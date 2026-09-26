// The MODELS panel: every provider this machine's agent stack can reach, in
// one view. The free/credits/paid directory is Prowl's shipped catalogue
// (consolidated from the free-tier trackers), served through rashin's single
// origin at /api/providers. The "on this box" band shows what is actually
// usable right now: which provider env keys exist (names only) and what each
// harness is pointed at, joined from /api/harnesses. Counts and filters work
// over both. Nothing here is scraped live and nothing is invented: an absent
// daemon leaves the panel dim, and a provider with no free models says so.

import { escapeHtml } from "./markdown.js";
import { api } from "./api.js";
import { loadHarnesses } from "./harnesses.js";

const esc = (s) => escapeHtml(String(s == null ? "" : s));

const CLASS_LABEL = { free: "FREE", credits: "CREDITS", paid: "PAID" };

const state = { all: [], harnesses: [], filter: "all", query: "" };

function onBox() {
  const set = new Set();
  for (const h of state.harnesses) {
    (h.creds || []).forEach((c) => set.add(c.label.toUpperCase()));
  }
  return set;
}

function match(p, keys) {
  const cls = state.filter;
  if (cls === "free" && p.class !== "free") return false;
  if (cls === "credits" && p.class !== "credits") return false;
  if (cls === "paid" && p.class !== "paid") return false;
  if (cls === "on" && !(p.env && keys.has(p.env.toUpperCase()))) return false;
  if (state.query) {
    const hay = (p.name + " " + p.id + " " + (p.modalities || []).join(" ")).toLowerCase();
    if (!hay.includes(state.query)) return false;
  }
  return true;
}

function ctxLabel(n) {
  if (!n) return "";
  if (n >= 1e6) return (n / 1e6).toFixed(n % 1e6 ? 1 : 0) + "M";
  return Math.round(n / 1000) + "k";
}

function card(p, keys) {
  const here = p.env && keys.has(p.env.toUpperCase());
  const mods = (p.modalities || [])
    .slice(0, 6)
    .map((m) => '<span class="m-tag">' + esc(m) + "</span>")
    .join("");
  return (
    '<article class="prov' + (here ? " here" : "") + " prov-" + esc(p.class) + '">' +
    "<header><b>" +
    esc(p.name) +
    "</b>" +
    '<span class="prov-class">' +
    esc(CLASS_LABEL[p.class] || p.class) +
    "</span>" +
    (here ? '<span class="prov-here">KEY ON BOX</span>' : "") +
    "</header>" +
    '<div class="prov-num"><b>' +
    (p.freeModels || 0) +
    "</b><span>free models</span>" +
    (p.maxContext ? '<span class="dim">' + ctxLabel(p.maxContext) + " ctx</span>" : "") +
    "</div>" +
    '<p class="prov-sign"><em>signup</em> ' +
    esc(p.friction || "-") +
    (p.routable ? ' <span class="dim">· gateway-routable</span>' : ' <span class="dim">· not proxied</span>') +
    "</p>" +
    (mods ? '<div class="prov-mods">' + mods + "</div>" : "") +
    (p.apiKeyUrl
      ? '<a class="prov-key" href="' + esc(p.apiKeyUrl) + '" target="_blank" rel="noopener">GET A KEY ↗</a>'
      : '<span class="prov-key dim">no signup page published</span>') +
    "</article>"
  );
}

function render(root) {
  const keys = onBox();
  const list = root.querySelector("[data-models-list]");
  const counts = root.querySelector("[data-models-counts]");
  const shown = state.all.filter((p) => match(p, keys));
  const byClass = (c) => state.all.filter((p) => p.class === c).length;
  const withKey = state.all.filter((p) => p.env && keys.has(p.env.toUpperCase())).length;
  counts.innerHTML = [["all", state.all.length], ["free", byClass("free")], ["credits", byClass("credits")], ["paid", byClass("paid")], ["on", withKey]]
    .map(
      ([k, n]) =>
        '<button class="chip' +
        (state.filter === k ? " active" : "") +
        '" data-mfilter="' +
        k +
        '" type="button">' +
        (k === "on" ? "ON THIS BOX" : k.toUpperCase()) +
        " <b>" +
        n +
        "</b></button>"
    )
    .join("");
  list.innerHTML = shown.length ? shown.map((p) => card(p, keys)).join("") : '<p class="dim">nothing matches. clear the filter or the search.</p>';
  root.querySelectorAll("[data-mfilter]").forEach((b) =>
    b.addEventListener("click", () => {
      state.filter = b.dataset.mfilter;
      render(root);
    })
  );
}

export function initModels(root) {
  if (!root) return;
  const search = root.querySelector("[data-models-search]");
  if (search) {
    search.addEventListener("input", () => {
      state.query = search.value.trim().toLowerCase();
      if (state.all.length) render(root);
    });
  }
  Promise.all([api.providers().catch(() => []), loadHarnesses().catch(() => [])])
    .then(([providers, harnesses]) => {
      state.all = Array.isArray(providers) ? providers : [];
      state.harnesses = harnesses || [];
      if (!state.all.length) {
        root.querySelector("[data-models-list]").innerHTML =
          '<p class="dim">Prowl is not answering on this machine, so the provider directory has no source. Nothing here gets invented.</p>';
        return;
      }
      render(root);
    })
    .catch(() => {
      root.querySelector("[data-models-list]").innerHTML = '<p class="dim">the daemon is not answering.</p>';
    });
}
