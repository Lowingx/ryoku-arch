// The one chat connection the console holds. Frames from /ws/chat fold into
// the shell's reducer; every chat surface is a projection of `state`. The
// daemon decides what a run, a tool or an approval is; this store only
// renders optimistically what the user just typed.

import { JsonSocket } from "$lib/api/socket";
import { applyEvent, initialState, type ChatState } from "$chatstate";
import type { ApprovalsMode, PromptImage, WsIn, WsOut } from "./protocol";

const DRAFT_KEY = "rashin.chat.draft";

export class ChatStore {
  state = $state.raw<ChatState>(initialState());
  connected = $state(false);
  draft = $state(localStorage.getItem(DRAFT_KEY) ?? "");
  /** turns typed while the socket was down, sent in order once it is up */
  private outbox: WsIn[] = [];
  private socket: JsonSocket<WsOut> | null = null;

  open(): void {
    if (this.socket) return;
    this.socket = new JsonSocket<WsOut>({
      path: "/ws/chat",
      onFrame: (f) => this.apply(f),
      onOpen: () => {
        this.connected = true;
        const queued = this.outbox;
        this.outbox = [];
        for (const q of queued) this.socket?.send(q);
      },
      onClose: () => {
        this.connected = false;
      },
    });
    this.socket.open();
  }

  close(): void {
    this.socket?.close();
    this.socket = null;
    this.connected = false;
  }

  apply(frame: WsOut): void {
    this.state = applyEvent(this.state, frame);
  }

  private post(cmd: WsIn): void {
    if (!this.socket?.send(cmd)) this.outbox.push(cmd);
  }

  send(text: string, images: PromptImage[] = []): void {
    const trimmed = text.trim();
    if (trimmed.length === 0 && images.length === 0) return;
    this.apply({ type: "user", text: trimmed, images });
    this.post({ type: "user", text: trimmed, images: images.length ? images : undefined });
    this.setDraft("");
  }

  setDraft(text: string): void {
    this.draft = text;
    if (text) localStorage.setItem(DRAFT_KEY, text);
    else localStorage.removeItem(DRAFT_KEY);
  }

  cancel(): void {
    this.post({ type: "cancel" });
  }

  newChat(): void {
    this.post({ type: "new" });
  }

  loadSessions(): void {
    this.post({ type: "history" });
  }

  switchSession(id: string): void {
    if (id) this.post({ type: "load", sessionId: id });
  }

  setModel(id: string): void {
    if (id && id !== this.state.currentModel) this.post({ type: "set_model", modelId: id });
  }

  setApprovals(mode: ApprovalsMode): void {
    this.post({ type: "approvals", mode });
  }

  answerPermission(requestId: string, optionId: string): void {
    this.post({ type: "permission", requestId, optionId });
  }
}

export const chat = new ChatStore();
