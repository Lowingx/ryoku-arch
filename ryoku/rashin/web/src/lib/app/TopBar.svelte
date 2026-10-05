<!-- The chrome every sheet inherits: three islands on the paper. The brand
     seal, the sheets (Latin named, kanji sealed), and the machine's presence:
     the Needle's face, what it is doing, and the three lamps. -->
<script lang="ts">
  import { router, SHEETS } from "./router.svelte";
  import { chat } from "$lib/chat/store.svelte";
  import { machine } from "$lib/state/machine.svelte";
  import BotAvatar from "$lib/fx/BotAvatar.svelte";
  import Lamp from "$lib/ui/Lamp.svelte";
  import Tooltip from "$lib/ui/Tooltip.svelte";

  const avatarState = $derived(!machine.online || chat.state.banner.state === "dead" ? "sleeping" : chat.state.busy ? "working" : "default");
  const presence = $derived.by(() => {
    if (!machine.online) return "daemon offline";
    const b = chat.state.banner;
    if (b.state === "dead") return "agent down";
    if (b.state === "starting") return "waking";
    if (chat.state.busy) return chat.state.activity || "working";
    return chat.connected ? "listening" : "connecting";
  });
  const hermesOk = $derived.by(() => {
    const h = machine.status?.hermes as { installed?: boolean; ready?: boolean } | undefined;
    return h?.installed ? (h.ready === false ? "idle" : "ok") : "bad";
  });

  const timeFmt = new Intl.DateTimeFormat(undefined, { hour: "2-digit", minute: "2-digit" });
  let now = $state(new Date());
  $effect(() => {
    const t = setInterval(() => (now = new Date()), 15000);
    return () => clearInterval(t);
  });
</script>

<header class="islands">
  <a class="island brand" href="#/overview" aria-label="Rashin overview">
    <span class="seal" aria-hidden="true">力</span>
    <span class="wordmark">Rashin</span>
    <span class="brand-gloss t-jp">羅針</span>
  </a>

  <nav class="island sheets" aria-label="Sheets">
    {#each SHEETS as s (s.id)}
      <a href="#/{s.id}" class="sheet" class:on={router.sheet === s.id} aria-current={router.sheet === s.id ? "page" : undefined}>
        <span class="sheet-name">{s.label}</span>
        <span class="sheet-gloss">{s.gloss}</span>
      </a>
    {/each}
  </nav>

  <div class="island presence">
    <a href="#/chat" class="needle" aria-label="The Needle: {presence}">
      <BotAvatar mood={avatarState} size={28} interactive={false} seed={0.42} label="The Needle" />
      <span class="needle-word">{presence}</span>
    </a>
    <span class="lamps" aria-label="Services">
      <Tooltip text="ryoku-rashin daemon"><Lamp state={machine.online ? "ok" : "bad"} /></Tooltip>
      <Tooltip text="hermes agent"><Lamp state={hermesOk} /></Tooltip>
      <Tooltip text="prowl code index"><Lamp state={machine.status?.ready ? "ok" : "idle"} /></Tooltip>
    </span>
    <span class="clock t-mono">{timeFmt.format(now)}</span>
  </div>
</header>

<style>
  .islands {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr) auto;
    gap: var(--s3);
    padding: var(--s3) var(--s4) 0;
    align-items: center;
  }
  .island {
    display: flex;
    align-items: center;
    height: 44px;
    padding: 0 var(--s3);
    border: 1px solid var(--line-soft);
    border-radius: var(--island-radius);
    background: var(--paper);
    min-width: 0;
  }

  .brand { gap: var(--s2); padding-right: var(--s4); }
  .seal {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 26px;
    height: 26px;
    border-radius: 6px;
    background: var(--sun);
    color: #fff;
    font-family: var(--jp);
    font-weight: 700;
    font-size: 15px;
    line-height: 1;
  }
  .wordmark { font-family: var(--display); font-size: 19px; color: var(--ink); letter-spacing: -0.01em; }
  .brand-gloss { font-size: var(--f-small); }

  .sheets { gap: 2px; padding: 0 var(--s2); overflow-x: auto; scrollbar-width: none; }
  .sheets::-webkit-scrollbar { display: none; }
  .sheet {
    display: inline-flex;
    align-items: baseline;
    gap: 6px;
    height: 30px;
    padding: 0 var(--s3);
    border-radius: 8px;
    color: var(--ink-mute);
    white-space: nowrap;
    transition: background-color var(--t-fast) var(--ease), color var(--t-fast) var(--ease);
  }
  .sheet-name { font-size: var(--f-body); font-weight: 500; line-height: 30px; }
  .sheet-gloss { font-family: var(--jp); font-size: var(--f-micro); color: var(--ink-faint); transition: color var(--t-fast) var(--ease); }
  .sheet:hover { color: var(--ink); background: var(--tint5); }
  .sheet.on { background: var(--bone); color: var(--ink-on-bone); }
  .sheet.on .sheet-gloss { color: color-mix(in srgb, var(--ink-on-bone) 60%, transparent); }
  @container (max-width: 1560px) { .sheet-gloss { display: none; } }

  .presence { gap: var(--s4); padding-left: var(--s2); }
  .needle { display: inline-flex; align-items: center; gap: var(--s2); color: var(--ink-dim); border-radius: 8px; padding: 2px var(--s2) 2px 2px; transition: background-color var(--t-fast) var(--ease); }
  .needle:hover { background: var(--tint5); color: var(--ink); }
  .needle-word { font-size: var(--f-small); white-space: nowrap; min-width: 6ch; }
  .lamps { display: inline-flex; gap: var(--s2); align-items: center; }
  .clock { font-size: var(--f-small); color: var(--ink-faint); font-variant-numeric: tabular-nums; }
</style>
