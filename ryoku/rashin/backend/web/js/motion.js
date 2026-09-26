// One motion authority for the whole dashboard. The rail switch toggles a
// body class; CSS turns transitions and wipes off under it, JS canvases
// (hero, orbit graph) read motion.on() and idle to a still frame instead of
// burning a rAF loop. The OS-level prefers-reduced-motion query forces the
// off state on load and can still be overridden by hand, because someone
// who turned animations off globally and opens this page may still want
// the graph to move, and that is their call, not ours.

const KEY = "***";

const hasDOM = typeof document !== "undefined";

const mq = () =>
  typeof matchMedia !== "undefined" &&
  matchMedia("(prefers-reduced-motion: reduce)").matches;

const stored = () => {
  try {
    return hasDOM && localStorage.getItem(KEY);
  } catch (err) {
    return null;
  }
};

export const motion = {
  on: stored() ? stored() === "on" : !mq(),
  listeners: new Set(),
  onChange(fn) {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  },
  apply() {
    if (!hasDOM) return;
    document.body.classList.toggle("no-motion", !this.on);
    try {
      localStorage.setItem(KEY, this.on ? "on" : "off");
    } catch (err) {
      /* private mode: the session simply starts fresh */
    }
    const btn = document.querySelector("[data-motion-toggle]");
    if (btn) {
      btn.setAttribute("aria-pressed", String(this.on));
      btn.classList.toggle("off", !this.on);
    }
    this.listeners.forEach((fn) => fn(this.on));
  },
  set(on) {
    this.on = on;
    this.apply();
  },
  toggle() {
    this.set(!this.on);
  },
};

// reduced() is the cheap check for render loops: motion off, or the OS says so.
export function reduced() {
  return !motion.on;
}

export function initMotion() {
  motion.apply();
  const btn = document.querySelector("[data-motion-toggle]");
  if (btn) btn.addEventListener("click", () => motion.toggle());
  // A live OS preference change flips the switch back off; the user can
  // still override per session afterwards.
  if (typeof matchMedia !== "undefined") {
    const m = matchMedia("(prefers-reduced-motion: reduce)");
    if (m.addEventListener) {
      m.addEventListener("change", (e) => {
        if (e.matches) motion.set(false);
      });
    }
  }
}
