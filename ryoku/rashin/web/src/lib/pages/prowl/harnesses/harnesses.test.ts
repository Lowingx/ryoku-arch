import { describe, expect, it } from "vitest";
import type { Harness } from "$lib/pages/skills/harnesses";
import type { HarnessRow } from "../types";
import { connectionState, mergeHarnesses } from "./harnesses";

function ledger(overrides: Partial<Harness> = {}): Harness {
  return {
    id: "claude",
    name: "Claude Code",
    present: true,
    wired: true,
    skillCount: 3,
    sessions: 2,
    routing: { supported: true, injected: true, active: true, pending: false },
    ...overrides,
  };
}

function setup(overrides: Partial<HarnessRow> = {}): HarnessRow {
  return {
    id: "claude",
    name: "Claude Code",
    detected: true,
    injected: true,
    active: true,
    files: ["~/.claude/settings.json"],
    skills: "current",
    ...overrides,
  };
}

describe("connectionState", () => {
  it("covers not connected, pending, and active transitions", () => {
    expect(connectionState({ supported: true, injected: false, active: false })).toBe("not-connected");
    expect(connectionState({ supported: true, injected: true, active: false })).toBe("pending");
    expect(connectionState({ supported: true, injected: true, active: true })).toBe("active");
  });

  it("keeps unsupported harnesses out of the routing state machine", () => {
    expect(connectionState({ supported: false, injected: true, active: true })).toBe("unsupported");
  });
});

describe("mergeHarnesses", () => {
  it("merges Rashin wiring with Prowl routing and skills", () => {
    const [merged] = mergeHarnesses(
      [ledger({ model: "sonnet", provider: "anthropic" })],
      [setup({ active: false, note: "No available model", skills: "update" })],
    );

    expect(merged).toMatchObject({
      id: "claude",
      installed: true,
      rashinWired: true,
      injected: true,
      active: true,
      pending: false,
      state: "active",
      reason: "No available model",
      skills: "update",
      model: "sonnet",
      provider: "anthropic",
    });
  });

  it("retains rows present in only one source", () => {
    const merged = mergeHarnesses(
      [ledger({ id: "gemini", name: "Gemini CLI", wired: false, routing: { supported: false, injected: false, active: false, pending: false, note: "No compatible endpoint" } })],
      [setup({ id: "omp", name: "OMP", detected: false, injected: false, active: false, files: [], skills: "install" })],
    );

    expect(merged.map((row) => row.id).sort()).toEqual(["gemini", "omp"]);
    expect(merged.find((row) => row.id === "gemini")).toMatchObject({ state: "unsupported", reason: "No compatible endpoint" });
    expect(merged.find((row) => row.id === "omp")).toMatchObject({ installed: false, state: "not-connected", skills: "install" });
  });

  it("uses active routing evidence from either source", () => {
    const [merged] = mergeHarnesses(
      [ledger({ routing: { supported: true, injected: true, active: false, pending: true } })],
      [setup({ active: true })],
    );
    expect(merged).toMatchObject({ active: true, pending: false, state: "active" });
  });
});
