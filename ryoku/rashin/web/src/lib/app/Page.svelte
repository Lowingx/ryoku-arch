<!-- A sheet's frame: the head sits on the body's grid (title, gloss, lead,
     tools), the body takes the width it is given and anchors to the top. -->
<script lang="ts">
  import type { Snippet } from "svelte";

  interface Props {
    title: string;
    gloss?: string;
    lead?: string;
    tools?: Snippet;
    children: Snippet;
    /** no padding or scroll: the sheet owns its own layout (chat) */
    bare?: boolean;
  }

  let { title, gloss, lead, tools, children, bare = false }: Props = $props();
</script>

<div class="page" class:bare>
  {#if !bare}
    <header class="page-head">
      <div class="page-name">
        <h1 class="t-title">{title}</h1>
        {#if gloss}<span class="page-gloss t-jp">{gloss}</span>{/if}
      </div>
      {#if lead}<p class="page-lead">{lead}</p>{/if}
      {#if tools}<div class="page-tools">{@render tools()}</div>{/if}
    </header>
  {/if}
  <div class="page-body">{@render children()}</div>
</div>

<style>
  .page {
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
    overflow: auto;
    padding: var(--s6) var(--s7) var(--s7);
    animation: page-in var(--t-mid) var(--ease-out);
  }
  .page.bare { padding: 0; overflow: hidden; }
  @keyframes page-in { from { opacity: 0; transform: translateY(6px); } }
  .page-head {
    display: grid;
    grid-template-columns: 1fr auto;
    grid-template-areas: "name tools" "lead tools";
    column-gap: var(--s5);
    row-gap: var(--s2);
    align-items: start;
    margin-bottom: var(--s6);
  }
  .page-name { grid-area: name; display: flex; align-items: baseline; gap: var(--s3); }
  .page-gloss { font-size: var(--f-row); }
  .page-lead { grid-area: lead; color: var(--ink-mute); max-width: 70ch; }
  .page-tools { grid-area: tools; display: flex; align-items: center; gap: var(--s2); }
  .page-body { flex: 1; min-height: 0; }
</style>
