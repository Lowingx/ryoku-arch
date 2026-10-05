<script lang="ts">
  import Page from "$lib/app/Page.svelte";
  import Markdown from "$lib/content/Markdown.svelte";
  import ThinkingOrb from "$lib/fx/ThinkingOrb.svelte";
  import { api } from "$lib/api/client";
  import { router } from "$lib/app/router.svelte";
  import Button from "$lib/ui/Button.svelte";
  import AskComposer from "$lib/pages/ask/AskComposer.svelte";
  import RecentAsks, { type RecentAsk } from "$lib/pages/ask/RecentAsks.svelte";
  import { readAskStream } from "$lib/pages/ask/askstream";

  let question = $state("");
  let answer = $state("");
  let working = $state("");
  let permission = $state("");
  let error = $state("");
  let running = $state(false);
  let recent = $state<RecentAsk[]>([]);
  let recentError = $state("");
  let generation = 0;

  async function loadRecent() {
    try {
      const data = (await api.askRecent()) as unknown;
      recent = Array.isArray(data) ? (data as RecentAsk[]) : [];
      recentError = "";
    } catch {
      recentError = "The daemon did not answer.";
    }
  }

  async function ask() {
    const q = question.trim();
    if (!q || running) return;
    const ownGeneration = ++generation;
    answer = "";
    error = "";
    permission = "";
    working = "waking the quick lane";
    running = true;
    try {
      const response = await api.ask(q);
      if (!response.body) throw new Error("The daemon returned no stream.");
      await readAskStream(response.body, (marker) => {
        if (ownGeneration !== generation) return;
        if (marker.kind === "working") working = marker.detail;
        else if (marker.kind === "perm") permission = marker.detail;
        else if (marker.kind === "answer") answer = marker.detail;
        else if (marker.kind === "error") error = marker.detail;
      });
      if (answer) await loadRecent();
      else if (!error) error = "The answer stream ended early. Ask again.";
    } catch (cause) {
      error = cause instanceof Error ? cause.message : "The daemon did not answer. Try again.";
    } finally {
      if (ownGeneration === generation) running = false;
    }
  }

  async function stop() {
    if (!running) return;
    ++generation;
    running = false;
    working = "";
    try {
      await api.askCancel();
      error = "Stopped. The shared chat is ready for another turn.";
    } catch {
      error = "The stop request did not reach the daemon.";
    }
  }

  function recall(item: RecentAsk) {
    ++generation;
    question = item.q;
    answer = item.a;
    working = "";
    permission = "";
    error = "";
    running = false;
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  $effect(() => {
    void loadRecent();
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape" && running) {
        event.preventDefault();
        void stop();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });
</script>

<Page title="Ask" gloss="即答" lead="A short path from a question to the machine's shared agent transcript.">
  <div class="ask-layout">
    <AskComposer value={question} {running} oninput={(value) => question = value} onask={() => void ask()} onstop={() => void stop()} />

    {#if running}
      <section class="answer-state" aria-live="polite">
        <ThinkingOrb mode="working" size={64} label="Rashin is working" />
        <div>
          <span class="t-label">Working</span>
          <p>{working || "thinking"}</p>
        </div>
      </section>
    {/if}

    {#if permission}
      <aside class="permission" aria-live="polite">
        <span class="t-label">Permission needed in chat</span>
        <p>{permission}</p>
        <Button variant="line" size="sm" onclick={() => router.go("chat")}>Open chat</Button>
      </aside>
    {/if}

    {#if error}
      <div class="error" role="alert">
        <span class="t-label">Ask stopped</span>
        <p>{error}</p>
      </div>
    {/if}

    {#if answer}
      <article class="answer" aria-live="polite">
        <header>
          <div>
            <span class="t-label">Answer</span>
            <p class="asked">{question}</p>
          </div>
          <Button variant="line" size="sm" onclick={() => router.go("chat")}>Continue in chat</Button>
        </header>
        <Markdown source={answer} breaks />
      </article>
    {/if}

    <RecentAsks asks={recent} error={recentError} onrecall={recall} />
  </div>
</Page>

<style>
  .ask-layout { display: grid; gap: var(--s5); align-content: start; }
  .answer-state { display: flex; align-items: center; gap: var(--s4); min-height: 88px; padding: var(--s3) var(--s5); border-left: 1px solid var(--line-strong); }
  .answer-state div { display: grid; gap: var(--s1); }
  .answer-state p { color: var(--ink); font-size: var(--f-row); }
  .permission, .error { display: flex; align-items: center; gap: var(--s3); padding: var(--s3) var(--s4); border: 1px solid var(--line); border-radius: var(--radius); }
  .permission p, .error p { flex: 1; color: var(--ink-dim); }
  .error { border-color: color-mix(in srgb, var(--alert) 50%, transparent); }
  .error .t-label { color: var(--alert); }
  .answer { padding: var(--s5); border: 1px solid var(--line-soft); border-radius: var(--radius); animation: answer-in var(--t-mid) var(--ease-out); }
  .answer header { display: flex; align-items: flex-start; justify-content: space-between; gap: var(--s4); padding-bottom: var(--s4); margin-bottom: var(--s5); border-bottom: 1px solid var(--line-soft); }
  .answer header > div { min-width: 0; }
  .asked { margin-top: var(--s1); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--ink-mute); font-size: var(--f-small); }
  @keyframes answer-in { from { opacity: 0; transform: translateY(4px); } }
  @media (max-width: 640px) {
    .answer header { flex-direction: column; }
    .permission, .error { align-items: flex-start; flex-direction: column; }
  }
</style>
