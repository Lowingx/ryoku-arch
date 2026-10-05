<script lang="ts">
  import Empty from "$lib/ui/Empty.svelte";

  export interface RecentAsk {
    at: string;
    kind?: string;
    q: string;
    a: string;
  }

  interface Props {
    asks: RecentAsk[];
    error?: string;
    onrecall: (ask: RecentAsk) => void;
  }

  let { asks, error = "", onrecall }: Props = $props();

  function ago(value: string): string {
    const elapsed = (Date.now() - new Date(value).getTime()) / 1000;
    if (!Number.isFinite(elapsed) || elapsed < 0) return "recently";
    if (elapsed < 90) return "moments ago";
    if (elapsed < 3600) return `${Math.round(elapsed / 60)} min ago`;
    if (elapsed < 86400) return `${Math.round(elapsed / 3600)} h ago`;
    return `${Math.round(elapsed / 86400)} d ago`;
  }
</script>

<section class="recent" aria-labelledby="recent-title">
  <header>
    <h2 id="recent-title">Recent asks</h2>
    <span class="t-jp">履歴</span>
  </header>
  {#if error}
    <Empty title="Recent asks are unavailable" body="Start the Rashin daemon, then return here to load the shared history." />
  {:else if asks.length === 0}
    <Empty title="No recent asks" body="Answers you finish here will be ready to recall without another model call." />
  {:else}
    <div class="plates">
      {#each asks as ask (ask.at + ask.q)}
        <button class="plate" type="button" onclick={() => onrecall(ask)}>
          <span class="question">{ask.q}</span>
          <time datetime={ask.at}>{ago(ask.at)}</time>
        </button>
      {/each}
    </div>
  {/if}
</section>

<style>
  .recent { min-width: 0; }
  header { display: flex; align-items: baseline; gap: var(--s2); margin-bottom: var(--s3); }
  h2 { color: var(--ink); font-size: var(--f-row); font-weight: 500; }
  .question { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  time { flex: none; font-family: var(--mono); font-size: var(--f-tiny); letter-spacing: var(--track-label); text-transform: uppercase; color: var(--ink-faint); }
</style>
