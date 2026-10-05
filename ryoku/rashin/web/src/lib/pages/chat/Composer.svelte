<script lang="ts">
  import { tick } from "svelte";
  import type { CommandInfo, ModelInfo, PromptImage } from "$lib/chat/protocol";
  import BorderBeam from "$lib/fx/BorderBeam.svelte";
  import ThinkingOrb from "$lib/fx/ThinkingOrb.svelte";
  import Button from "$lib/ui/Button.svelte";
  import IconButton from "$lib/ui/IconButton.svelte";
  import Popover from "$lib/ui/Popover.svelte";
  import Seg from "$lib/ui/Seg.svelte";
  import Select from "$lib/ui/Select.svelte";
  import Tooltip from "$lib/ui/Tooltip.svelte";
  import { tokenLabel } from "./presentation";

  interface Props {
    draft: string;
    busy: boolean;
    connected: boolean;
    activity: string;
    commands: CommandInfo[];
    models: ModelInfo[];
    currentModel: string;
    agent: string;
    approvals: "ask" | "read-only";
    usage: { size: number; used: number } | null;
    focusTarget?: HTMLTextAreaElement;
    ondraft: (value: string) => void;
    onsend: (text: string, images: PromptImage[]) => void;
    oncancel: () => void;
    onmodel: (id: string) => void;
    onapprovals: (mode: "ask" | "read-only") => void;
  }

  let {
    draft,
    busy,
    connected,
    activity,
    commands,
    models,
    currentModel,
    agent,
    approvals,
    usage,
    focusTarget = $bindable(),
    ondraft,
    onsend,
    oncancel,
    onmodel,
    onapprovals,
  }: Props = $props();

  let filePicker: HTMLInputElement | undefined = $state();
  let images: PromptImage[] = $state([]);
  let commandOpen = $state(false);
  let commandIndex = $state(0);

  const commandMatch = $derived(draft.match(/^\/([^\s]*)$/));
  const commandQuery = $derived(commandMatch ? (commandMatch[1] ?? "").toLowerCase() : null);
  const commandMatches = $derived(commandQuery === null ? [] : commands
    .filter((command) => command.name.toLowerCase().includes(commandQuery) || command.description.toLowerCase().includes(commandQuery))
    .slice(0, 8));
  const modelOptions = $derived(models.map((model) => ({ value: model.id, label: model.name, hint: model.description })));
  const usagePercent = $derived(usage && usage.size > 0 ? Math.min(100, (usage.used / usage.size) * 100) : 0);


  function resizeField() {
    if (!focusTarget) return;
    focusTarget.style.height = "auto";
    const lineHeight = Number.parseFloat(getComputedStyle(focusTarget).lineHeight) || 22;
    focusTarget.style.height = `${Math.min(focusTarget.scrollHeight, lineHeight * 8)}px`;
  }

  function submit() {
    if (busy) {
      oncancel();
      return;
    }
    if (!draft.trim() && images.length === 0) return;
    onsend(draft, images);
    images = [];
    void tick().then(resizeField);
  }

  function completeCommand(command: CommandInfo) {
    const name = command.name.startsWith("/") ? command.name : `/${command.name}`;
    ondraft(`${name} `);
    commandOpen = false;
    void tick().then(() => {
      focusTarget?.focus();
      resizeField();
    });
  }

  function handleKey(event: KeyboardEvent) {
    if (event.key === "Escape" && busy) {
      event.preventDefault();
      event.stopPropagation();
      oncancel();
      return;
    }
    if (commandOpen && commandMatches.length) {
      if (event.key === "ArrowDown") {
        event.preventDefault();
        commandIndex = (commandIndex + 1) % commandMatches.length;
        return;
      }
      if (event.key === "ArrowUp") {
        event.preventDefault();
        commandIndex = (commandIndex - 1 + commandMatches.length) % commandMatches.length;
        return;
      }
      if (event.key === "Enter") {
        event.preventDefault();
        completeCommand(commandMatches[commandIndex]!);
        return;
      }
      if (event.key === "Escape") {
        event.preventDefault();
        commandOpen = false;
        return;
      }
    }
    if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
      event.preventDefault();
      submit();
    }
  }

  function readImages(files: File[]) {
    for (const file of files) {
      if (!file.type.startsWith("image/")) continue;
      const reader = new FileReader();
      reader.addEventListener("load", () => {
        const encoded = String(reader.result ?? "");
        const comma = encoded.indexOf(",");
        if (comma < 0) return;
        images = [...images, { data: encoded.slice(comma + 1), mimeType: file.type }];
      });
      reader.readAsDataURL(file);
    }
  }

  function handlePaste(event: ClipboardEvent) {
    const files = Array.from(event.clipboardData?.files ?? []).filter((file) => file.type.startsWith("image/"));
    if (files.length === 0) return;
    event.preventDefault();
    readImages(files);
  }

  $effect(() => {
    commandOpen = commandQuery !== null && commandMatches.length > 0;
    commandIndex = Math.min(commandIndex, Math.max(0, commandMatches.length - 1));
  });

  $effect(() => {
    if (commandOpen && (commandQuery === null || commandMatches.length === 0)) commandOpen = false;
  });

  $effect(() => {
    void draft;
    void tick().then(resizeField);
  });
</script>

<div class="composer-shell">
  <BorderBeam size="line" active={busy} />
  <div class="composer-inner">
    {#if images.length}
      <div class="attachments" aria-label="Attached images">
        {#each images as image, index (`${image.data.slice(0, 20)}:${index}`)}
          <figure>
            <img src={`data:${image.mimeType};base64,${image.data}`} alt="Prompt attachment" />
            <IconButton icon="close" label="Remove image" size={22} tip={false} onclick={() => images = images.filter((_, at) => at !== index)} />
          </figure>
        {/each}
      </div>
    {/if}

    <Popover bind:open={commandOpen} side="top" align="start" width={440} focusContent={false}>
      {#snippet trigger({ props })}
        <div class="field" {...props}>
          <IconButton icon="image" label="Attach an image" size={30} onclick={() => filePicker?.click()} />
          <textarea
            bind:this={focusTarget}
            value={draft}
            rows="1"
            placeholder="Ask the Needle…"
            aria-label="Message the Needle"
            oninput={(event) => {
              ondraft(event.currentTarget.value);
              resizeField();
            }}
            onkeydown={handleKey}
            onpaste={handlePaste}
          ></textarea>
          <div class="send-swap">
            {#key busy}
              <Tooltip text={busy ? "Stop response" : "Send message"} side="top">
                <Button
                  variant="plate"
                  class="send-action"
                  icon={busy ? "stop" : "arrowUp"}
                  aria-label={busy ? "Stop response" : "Send message"}
                  armed={busy || Boolean(draft.trim()) || images.length > 0}
                  onclick={submit}
                />
              </Tooltip>
            {/key}
          </div>
        </div>
      {/snippet}
      <div class="command-menu" role="listbox" aria-label="Slash commands">
        {#each commandMatches as command, index (command.name)}
          <button
            type="button"
            role="option"
            aria-selected={index === commandIndex}
            class:active={index === commandIndex}
            onpointerenter={() => commandIndex = index}
            onclick={() => completeCommand(command)}
          >
            <span class="command-name">/{command.name.replace(/^\//, "")}</span>
            <span class="command-description">{command.description}</span>
            {#if command.hint}<span class="command-hint">{command.hint}</span>{/if}
          </button>
        {/each}
      </div>
    </Popover>

    <input
      class="file-picker"
      bind:this={filePicker}
      type="file"
      accept="image/*"
      multiple
      onchange={(event) => {
        readImages(Array.from(event.currentTarget.files ?? []));
        event.currentTarget.value = "";
      }}
    />

    <div class="status-line">
      <div class="activity" aria-live="polite">
        {#if busy}
          <ThinkingOrb mode="working" size={20} label="Working" />
          <span>{activity || "working"}</span>
        {:else if !connected}
          <span>reconnecting</span>
        {/if}
      </div>
      <div class="composer-controls">
        {#if usage}
          <div class="usage" title={`${tokenLabel(usage.used)} of ${tokenLabel(usage.size)} tokens used`}>
            <span>{tokenLabel(usage.used)}/{tokenLabel(usage.size)}</span>
            <span class="usage-bar"><i style:width={`${usagePercent}%`}></i></span>
          </div>
        {/if}
        <span class="agent-hint">{agent || "agent"}</span>
        <Select
          size="sm"
          label="Model"
          options={modelOptions}
          value={currentModel}
          placeholder="Model"
          onchange={onmodel}
        />
        <Seg
          size="sm"
          label="Tool approvals"
          options={[{ value: "ask", label: "Ask" }, { value: "read-only", label: "Read-only" }]}
          value={approvals}
          onchange={(value) => onapprovals(value as "ask" | "read-only")}
        />
      </div>
    </div>
  </div>
</div>

<style>
  .composer-shell { position: relative; z-index: 3; flex: none; border-top: 1px solid var(--line-soft); background: var(--paper); }
  .composer-inner { width: min(100%, var(--measure)); margin: 0 auto; padding: var(--s3) var(--s5) var(--s4); }
  .field { display: flex; align-items: flex-end; gap: var(--s2); padding: var(--s2); border: 1px solid var(--line); border-radius: var(--radius); background: var(--paper-lift); transition: border-color var(--t-fast) var(--ease); }
  .field:focus-within { border-color: var(--line-strong); }
  textarea { flex: 1; min-width: 0; min-height: 32px; max-height: 176px; resize: none; overflow-y: auto; padding: 5px var(--s1); border: 0; outline: 0; background: transparent; color: var(--ink); line-height: 22px; }
  textarea::placeholder { color: var(--ink-faint); }
  .send-swap { flex: none; }
  :global(.send-action) { width: 34px; padding: 0; animation: action-in var(--t-fast) var(--ease-out); }
  @keyframes action-in { from { opacity: 0; transform: scale(0.82) rotate(-8deg); } }
  .file-picker { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); }
  .attachments { display: flex; gap: var(--s2); margin-bottom: var(--s2); overflow-x: auto; }
  figure { position: relative; flex: none; width: 88px; height: 64px; }
  figure img { width: 100%; height: 100%; border: 1px solid var(--line); border-radius: var(--radius); object-fit: cover; }
  figure :global(.ib) { position: absolute; top: var(--s1); right: var(--s1); border-color: var(--line-strong); background: var(--paper-lift); }
  .status-line { display: flex; align-items: center; justify-content: space-between; gap: var(--s3); min-height: 30px; padding-top: var(--s2); }
  .activity { display: flex; align-items: center; gap: var(--s2); min-width: 120px; color: var(--ink-mute); font-size: var(--f-small); }
  .composer-controls { display: flex; align-items: center; justify-content: flex-end; gap: var(--s2); min-width: 0; }
  .agent-hint { color: var(--ink-faint); font-size: var(--f-micro); }
  .usage { display: grid; grid-template-columns: auto 56px; align-items: center; gap: var(--s2); color: var(--ink-faint); font-family: var(--mono); font-size: var(--f-tiny); }
  .usage-bar { position: relative; width: 56px; height: 3px; overflow: hidden; border-radius: 2px; background: var(--tint10); }
  .usage-bar i { position: absolute; inset: 0 auto 0 0; border-radius: inherit; background: var(--bone); transition: width var(--t-slow) var(--ease-out); }
  .command-menu { display: flex; flex-direction: column; width: 100%; }
  .command-menu button { display: grid; grid-template-columns: 112px minmax(0, 1fr) auto; align-items: center; gap: var(--s3); min-height: 38px; padding: var(--s2) var(--s3); border-radius: 4px; text-align: left; }
  .command-menu button.active { background: var(--tint10); }
  .command-name { color: var(--ink); font-family: var(--mono); font-size: var(--f-small); }
  .command-description { overflow: hidden; color: var(--ink-mute); font-size: var(--f-small); text-overflow: ellipsis; white-space: nowrap; }
  .command-hint { color: var(--ink-faint); font-family: var(--mono); font-size: var(--f-tiny); }
  @media (max-width: 760px) {
    .composer-inner { padding: var(--s3) var(--s4); }
    .status-line { align-items: flex-start; flex-direction: column; }
    .composer-controls { width: 100%; justify-content: flex-start; flex-wrap: wrap; }
    .agent-hint { display: none; }
  }
</style>
