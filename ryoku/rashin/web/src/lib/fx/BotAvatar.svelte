<!-- The Needle's face: a Libraries.dev bot avatar in bone on black, so it is a
     bone plate that happens to blink. `working` while the agent runs,
     `sleeping` when the daemon is down, idle otherwise. -->
<script lang="ts">
  import { BotAvatar, type BotAvatarProps, type BotAvatarState, type BotAvatarType } from "bot-avatars";
  import { mountIsland, type Island } from "./island";

  interface Props {
    mood?: BotAvatarState;
    type?: BotAvatarType;
    size?: number;
    color?: string;
    ink?: string;
    shading?: BotAvatarProps["shading"];
    interactive?: boolean;
    seed?: number;
    label?: string;
  }

  let {
    mood = "default",
    type = "pebble",
    size = 40,
    color = "#cdc4ba",
    ink = "#000000",
    shading = "plastic",
    interactive = true,
    seed,
    label,
  }: Props = $props();

  let host: HTMLSpanElement | undefined = $state();
  let island: Island<BotAvatarProps> | null = null;

  $effect(() => {
    if (!host) return;
    island = mountIsland<BotAvatarProps>(host, BotAvatar);
    return () => {
      island?.destroy();
      island = null;
    };
  });

  $effect(() => {
    island?.render({
      state: mood,
      type,
      size,
      color,
      ink,
      shading,
      interactive,
      seed,
      theme: "dark",
      "aria-label": label,
    });
  });
</script>

<span class="avatar" bind:this={host} style:width="{size}px" style:height="{size}px"></span>

<style>
  .avatar {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex: none;
  }
</style>
