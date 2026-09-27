// Hash router for the console shell: swaps the visible panel, marks the nav
// item, and titles the header. No transition theater; the panel simply shows.

const PANELS = {
  overview: "Overview",
  system: "System",
  vault: "Vault",
  memory: "Memory",
  skills: "Skills",
  agents: "Agents",
  models: "Models",
  chat: "Chat",
  about: "About",
};

function current() {
  const h = location.hash.replace(/^#\/?/, "");
  return h in PANELS ? h : "overview";
}

export function initRouter(onChange) {
  const panels = document.querySelectorAll("[data-panel]");
  const links = document.querySelectorAll("[data-nav]");
  const title = document.querySelector("[data-top-title]");

  function show(name) {
    panels.forEach((p) => {
      p.hidden = p.dataset.panel !== name;
    });
    links.forEach((l) => l.classList.toggle("active", l.dataset.nav === name));
    if (title) title.textContent = PANELS[name];
    if (onChange) onChange(name);
  }

  addEventListener("hashchange", () => show(current()));
  show(current());
}
