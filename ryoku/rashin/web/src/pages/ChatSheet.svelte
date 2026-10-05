<script lang="ts">
  import { onMount } from "svelte";
  import Page from "$lib/app/Page.svelte";
  import { chat } from "$lib/chat/store.svelte";
  import Composer from "$lib/pages/chat/Composer.svelte";
  import Inspector from "$lib/pages/chat/Inspector.svelte";
  import SessionsPane from "$lib/pages/chat/SessionsPane.svelte";
  import Transcript from "$lib/pages/chat/Transcript.svelte";
  import Icon from "$lib/ui/Icon.svelte";
  import Kbd from "$lib/ui/Kbd.svelte";

  const SESSIONS_KEY = "rashin.chat.sessions-open";
  const INSPECTOR_KEY = "rashin.chat.inspector-open";

  let sessionsOpen = $state(localStorage.getItem(SESSIONS_KEY) !== "0");
  let inspectorOpen = $state(localStorage.getItem(INSPECTOR_KEY) !== "0");
  let composerField: HTMLTextAreaElement | undefined = $state();
  let lastSessionStamp = `${chat.state.session.id}:${chat.state.session.title}`;

  const currentSession = $derived(chat.state.history.find((session) => session.id === chat.state.session.id));

  function setSessionsOpen(open: boolean) {
    sessionsOpen = open;
    localStorage.setItem(SESSIONS_KEY, open ? "1" : "0");
  }

  function setInspectorOpen(open: boolean) {
    inspectorOpen = open;
    localStorage.setItem(INSPECTOR_KEY, open ? "1" : "0");
  }

  function newChat() {
    chat.newChat();
  }

  function handleShortcut(event: KeyboardEvent) {
    if (event.key === "Escape" && chat.state.busy && !event.defaultPrevented) {
      event.preventDefault();
      chat.cancel();
      return;
    }
    if (!event.ctrlKey || event.altKey || event.metaKey) return;
    const key = event.key.toLowerCase();
    if (!["n", "k", "b", "i"].includes(key)) return;
    event.preventDefault();
    if (key === "n") newChat();
    else if (key === "k") composerField?.focus();
    else if (key === "b") setSessionsOpen(!sessionsOpen);
    else setInspectorOpen(!inspectorOpen);
  }

  $effect(() => {
    const stamp = `${chat.state.session.id}:${chat.state.session.title}`;
    if (!stamp || stamp === ":" || stamp === lastSessionStamp) return;
    lastSessionStamp = stamp;
    chat.loadSessions();
  });

  onMount(() => {
    chat.loadSessions();
    window.addEventListener("keydown", handleShortcut);
    return () => window.removeEventListener("keydown", handleShortcut);
  });
</script>

<Page title="Chat" gloss="対話" bare>
  <div class="workspace">
    {#if sessionsOpen}
      <SessionsPane
        sessions={chat.state.history}
        currentId={chat.state.session.id}
        onnew={newChat}
        onswitch={(id) => chat.switchSession(id)}
        oncollapse={() => setSessionsOpen(false)}
      />
    {/if}

    <section class="conversation" aria-label="Chat with the Needle">
      {#if !sessionsOpen || !inspectorOpen}
        <div class="pane-reveals">
          {#if !sessionsOpen}
            <button type="button" onclick={() => setSessionsOpen(true)}>
              <Icon name="sidebar" size={14} />
              Conversations
              <Kbd keys={["Ctrl", "B"]} />
            </button>
          {/if}
          <span></span>
          {#if !inspectorOpen}
            <button type="button" onclick={() => setInspectorOpen(true)}>
              Inspector
              <Kbd keys={["Ctrl", "I"]} />
              <Icon name="sliders" size={14} />
            </button>
          {/if}
        </div>
      {/if}

      <div class="transcript-wrap">
        <Transcript
          items={chat.state.items}
          permissions={chat.state.permissions}
          banner={chat.state.banner}
          replaying={chat.state.replaying}
          busy={chat.state.busy}
          onnew={newChat}
          onanswer={(requestId, optionId) => chat.answerPermission(requestId, optionId)}
          onsuggest={(text) => {
            chat.setDraft(text);
            composerField?.focus();
          }}
        />
      </div>

      <Composer
        bind:focusTarget={composerField}
        draft={chat.draft}
        busy={chat.state.busy}
        connected={chat.connected}
        activity={chat.state.activity}
        commands={chat.state.commands}
        models={chat.state.models}
        currentModel={chat.state.currentModel}
        agent={chat.state.agent}
        approvals={chat.state.approvals}
        usage={chat.state.usage}
        ondraft={(value) => chat.setDraft(value)}
        onsend={(text, images) => chat.send(text, images)}
        oncancel={() => chat.cancel()}
        onmodel={(id) => chat.setModel(id)}
        onapprovals={(mode) => chat.setApprovals(mode)}
      />
    </section>

    {#if inspectorOpen}
      <Inspector
        session={chat.state.session}
        cwd={currentSession?.cwd}
        agent={chat.state.agent}
        currentModel={chat.state.currentModel}
        models={chat.state.models}
        usage={chat.state.usage}
        items={chat.state.items}
        permissions={chat.state.permissions}
        commands={chat.state.commands}
        oncollapse={() => setInspectorOpen(false)}
      />
    {/if}
  </div>
</Page>

<style>
  .workspace { position: relative; display: grid; grid-template-columns: auto minmax(0, 1fr) auto; height: 100%; min-height: 0; overflow: hidden; }
  .conversation { display: flex; min-width: 0; min-height: 0; flex-direction: column; background: var(--paper); }
  .transcript-wrap { position: relative; display: flex; flex: 1; min-height: 0; }
  .pane-reveals { display: grid; grid-template-columns: auto 1fr auto; align-items: center; min-height: 44px; padding: var(--s2) var(--s3); border-bottom: 1px solid var(--line-soft); }
  .pane-reveals button { display: inline-flex; align-items: center; gap: var(--s2); min-height: 28px; padding: 0 var(--s2); border-radius: var(--radius); color: var(--ink-mute); font-size: var(--f-small); transition: color var(--t-fast) var(--ease), background-color var(--t-fast) var(--ease); }
  .pane-reveals button:hover { color: var(--ink); background: var(--tint5); }

  @container (max-width: 1050px) {
    .workspace { grid-template-columns: minmax(0, 1fr); }
    .workspace :global(.sessions), .workspace :global(.inspector) { position: absolute; inset-block: 0; z-index: 20; border-color: var(--line-strong); }
    .workspace :global(.sessions) { left: 0; }
    .workspace :global(.inspector) { right: 0; }
  }
</style>
