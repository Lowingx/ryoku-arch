<script lang="ts">
  import Button from "$lib/ui/Button.svelte";
  import Card from "$lib/ui/Card.svelte";
  import Chip from "$lib/ui/Chip.svelte";
  import Dialog from "$lib/ui/Dialog.svelte";
  import Empty from "$lib/ui/Empty.svelte";
  import type { ChatAgentInfo } from "./harnesses";

  interface Props {
    agents: ChatAgentInfo[];
    busy?: boolean;
    error?: string;
    onswitch: (id: string) => void;
  }

  let { agents, busy = false, error = "", onswitch }: Props = $props();
  let open = $state(false);
  let pending = $state<ChatAgentInfo | null>(null);

  function choose(agent: ChatAgentInfo) {
    if (!agent.available || agent.active) return;
    pending = agent;
    open = true;
  }

  function confirm() {
    if (!pending) return;
    onswitch(pending.id);
    open = false;
  }
</script>

<Card title="Rashin chat agent" gloss="対話" lead="Choose which connected harness answers Rashin's chat lane.">
  {#if error}
    <Empty title="Chat agents are unavailable" body={error} />
  {:else if agents.length === 0}
    <Empty title="No chat harness is connected" body="Connect a supported harness above, then return here to choose it for chat." />
  {:else}
    <div class="plates">
      {#each agents as agent (agent.id)}
        <button class="plate" class:on={agent.active} type="button" disabled={!agent.available || agent.active || busy} onclick={() => choose(agent)}>
          <span class="agent-name">{agent.name}</span>
          {#if agent.recommended}<Chip tone={agent.active ? "quiet" : "line"}>Recommended</Chip>{/if}
          <span class="state">{agent.active ? "Answering chat" : agent.available ? "Available" : "Not connected"}</span>
        </button>
      {/each}
    </div>
  {/if}
</Card>

<Dialog bind:open title="Switch the chat agent?" description="The running chat session restarts when the harness changes.">
  <p>The current transcript stays on disk. New turns will be answered by <strong>{pending?.name}</strong>.</p>
  {#snippet footer()}
    <Button variant="quiet" onclick={() => (open = false)}>Keep current</Button>
    <Button variant="plate" autofocus busy={busy} onclick={confirm}>Switch agent</Button>
  {/snippet}
</Dialog>

<style>
  .agent-name { flex: 1; color: inherit; font-weight: 500; }
  .state { min-width: 96px; text-align: right; color: var(--ink-faint); font-size: var(--f-small); }
  .plate.on .state { color: color-mix(in srgb, var(--ink-on-bone) 65%, transparent); }
  .plate:disabled:not(.on) { cursor: default; opacity: 0.5; }
  p { color: var(--ink-dim); }
  strong { color: var(--ink); font-weight: 500; }
  @media (max-width: 560px) { .state { min-width: 0; } }
</style>
