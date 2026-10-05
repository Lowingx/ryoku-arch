// Hash routes, so the console works from the daemon's static server and the
// companion window alike with no fallback handler: #/chat, #/vault/path...
// A sheet is a route's first segment; the rest is the sheet's own business.

export interface Sheet {
  id: string;
  label: string;
  /** the real Japanese word, sealed beside the Latin name */
  gloss: string;
}

export const SHEETS: readonly Sheet[] = [
  { id: "chat", label: "Chat", gloss: "対話" },
  { id: "ask", label: "Ask", gloss: "即答" },
  { id: "overview", label: "Overview", gloss: "概要" },
  { id: "system", label: "System", gloss: "演算" },
  { id: "vault", label: "Vault", gloss: "書庫" },
  { id: "memory", label: "Memory", gloss: "記憶" },
  { id: "skills", label: "Skills", gloss: "技" },
  { id: "agents", label: "Agents", gloss: "五人衆" },
  { id: "models", label: "Models", gloss: "モデル" },
  { id: "about", label: "About", gloss: "案内" },
];

export const DEFAULT_SHEET = "chat";

function parse(hash: string): { sheet: string; rest: string[] } {
  const parts = hash.replace(/^#\/?/, "").split("/").filter(Boolean).map(decodeURIComponent);
  const sheet = parts[0] && SHEETS.some((s) => s.id === parts[0]) ? parts[0] : DEFAULT_SHEET;
  return { sheet, rest: parts.slice(1) };
}

export class Router {
  sheet = $state(DEFAULT_SHEET);
  rest = $state<string[]>([]);

  start(): void {
    const sync = () => {
      const { sheet, rest } = parse(location.hash);
      this.sheet = sheet;
      this.rest = rest;
    };
    sync();
    window.addEventListener("hashchange", sync);
  }

  go(sheet: string, ...rest: string[]): void {
    location.hash = "#/" + [sheet, ...rest].map(encodeURIComponent).join("/");
  }
}

export const router = new Router();
