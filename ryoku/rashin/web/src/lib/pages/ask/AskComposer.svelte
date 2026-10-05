<script lang="ts">
  import Button from "$lib/ui/Button.svelte";

  interface Props {
    value: string;
    running: boolean;
    oninput: (value: string) => void;
    onask: () => void;
    onstop: () => void;
  }

  let { value, running, oninput, onask, onstop }: Props = $props();

  function keydown(event: KeyboardEvent) {
    if (event.key === "Escape" && running) {
      event.preventDefault();
      onstop();
      return;
    }
    if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
      event.preventDefault();
      if (!running && value.trim()) onask();
    }
  }
</script>

<div class="ask-field" class:running>
  <textarea
    value={value}
    rows="3"
    aria-label="Question"
    placeholder="What do you want to know about this machine?"
    oninput={(event) => oninput(event.currentTarget.value)}
    onkeydown={keydown}
  ></textarea>
  <div class="ask-foot">
    <p><kbd>Enter</kbd> ask <span>·</span> <kbd>Shift</kbd> + <kbd>Enter</kbd> new line</p>
    {#if running}
      <Button variant="line" size="sm" onclick={onstop}>Stop</Button>
    {:else}
      <Button variant="plate" size="sm" armed={Boolean(value.trim())} onclick={onask}>Ask</Button>
    {/if}
  </div>
</div>

<style>
  .ask-field {
    border: 1px solid var(--line-strong);
    border-radius: var(--radius);
    padding: var(--s5);
    background: var(--paper);
    transition: border-color var(--t-fast) var(--ease), background-color var(--t-fast) var(--ease);
  }
  .ask-field:focus-within, .ask-field.running { border-color: var(--bone); background: var(--tint5); }
  textarea {
    display: block;
    width: 100%;
    min-height: 112px;
    padding: 0;
    resize: vertical;
    border: 0;
    outline: 0;
    background: transparent;
    color: var(--ink);
    font-family: var(--display);
    font-size: clamp(24px, 3vw, var(--f-hero));
    font-weight: 300;
    line-height: 1.22;
  }
  textarea::placeholder { color: var(--ink-faint); opacity: 1; }
  .ask-foot { display: flex; align-items: center; justify-content: space-between; gap: var(--s4); margin-top: var(--s4); padding-top: var(--s3); border-top: 1px solid var(--line-soft); }
  .ask-foot p { color: var(--ink-faint); font-size: var(--f-micro); }
  .ask-foot span { padding: 0 var(--s1); }
  kbd { font-family: var(--mono); color: var(--ink-mute); }
  @media (max-width: 640px) {
    .ask-field { padding: var(--s4); }
    .ask-foot p { display: none; }
    .ask-foot { justify-content: flex-end; }
  }
</style>
