// Hash router for the console shell: swaps the visible panel, marks the nav
// item, and titles the header. No transition theater; the panel simply shows.

const PANELS = {
  overview: ["Overview", "the machine at rest"],
  system: ["System", "live inventory, read-only"],
  vault: ["Vault", "the maintained map"],
  memory: ["Memory", "what the agent knows"],
  skills: ["Skills", "procedures on the shelf"],
  agents: ["Agents", "who can read this system"],
  models: ["Models", "provider pool"],
  chat: ["Chat", "ask the needle"],
  about: ["About", "what rashin is"],
};
const SHEET_NO = { overview: 1, system: 2, vault: 3, memory: 4, skills: 5, agents: 6, models: 7, chat: 8, about: 9 };

function current() {
  const h = location.hash.replace(/^#\/?/, "");
  return h in PANELS ? h : "overview";
}

export function initRouter(onChange) {
  const panels = document.querySelectorAll("[data-panel]");
  const links = document.querySelectorAll("[data-nav]");
  const title = document.querySelector("[data-top-title]");
  const sub = document.querySelector("[data-sheet-sub]");
  const no = document.querySelector("[data-sheet-no]");

  function show(name) {
    panels.forEach((p) => {
      p.hidden = p.dataset.panel !== name;
    });
    links.forEach((l) => l.classList.toggle("active", l.dataset.nav === name));
    if (title) title.textContent = PANELS[name][0];
    if (sub) sub.textContent = PANELS[name][1];
    if (no) no.textContent = "sheet " + String(SHEET_NO[name]).padStart(2, "0") + "/09";
    if (onChange) onChange(name);
  }

  addEventListener("hashchange", () => show(current()));
  show(current());
}
