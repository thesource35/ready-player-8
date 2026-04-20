// @vitest-environment jsdom
// Owner: 29-08-PLAN.md Wave 4 — LIVE-04 (web): ProjectSwitcher persists LastSelectedProjectId + Fleet toggle
import { describe, it, expect, beforeEach, afterEach, beforeAll } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { useState } from "react";

// Rule 3 auto-fix: vitest 4 + jsdom 29 sometimes exposes a bare `{}` as
// `window.localStorage` (no Storage prototype). Install an in-memory shim
// before any production code loads.
beforeAll(() => {
  const store = new Map<string, string>();
  const shim: Storage = {
    get length() {
      return store.size;
    },
    clear: () => store.clear(),
    getItem: (key: string) => (store.has(key) ? store.get(key)! : null),
    setItem: (key: string, value: string) => {
      store.set(key, String(value));
    },
    removeItem: (key: string) => {
      store.delete(key);
    },
    key: (i: number) => Array.from(store.keys())[i] ?? null,
  };
  Object.defineProperty(window, "localStorage", {
    configurable: true,
    value: shim,
  });
  Object.defineProperty(globalThis, "localStorage", {
    configurable: true,
    value: shim,
  });
});

import { ProjectSwitcher } from "../ProjectSwitcher";
import { LiveFeedClient } from "../LiveFeedClient";
import { LIVE_FEED_KEYS } from "../livefeed-storage";

function SwitcherHarness() {
  const [sel, setSel] = useState("p1");
  return (
    <ProjectSwitcher
      projects={[
        { id: "p1", name: "Alpha", client: null },
        { id: "p2", name: "Bravo", client: null },
      ]}
      selectedProjectId={sel}
      onSelect={setSel}
    />
  );
}

describe("ProjectSwitcher persistence", () => {
  beforeEach(() => {
    localStorage.clear();
  });
  afterEach(() => {
    cleanup();
  });

  it("opens dropdown on button click", () => {
    render(<SwitcherHarness />);
    const btn = screen.getByRole("button", { name: /project switcher/i });
    fireEvent.click(btn);
    expect(screen.getByRole("listbox")).toBeDefined();
  });

  it("writes selected project id to localStorage on selection", () => {
    render(<SwitcherHarness />);
    const btn = screen.getByRole("button", { name: /project switcher/i });
    fireEvent.click(btn);
    const option = screen.getByRole("option", { name: "Bravo" });
    fireEvent.click(option);
    expect(localStorage.getItem(LIVE_FEED_KEYS.lastSelectedProjectId)).toBe("p2");
  });

  it("filters project list by prefix on typing", () => {
    render(<SwitcherHarness />);
    fireEvent.click(screen.getByRole("button", { name: /project switcher/i }));
    const input = screen.getByLabelText(/filter projects/i);
    fireEvent.change(input, { target: { value: "br" } });
    expect(screen.getByRole("option", { name: "Bravo" })).toBeDefined();
    expect(screen.queryByRole("option", { name: "Alpha" })).toBeNull();
  });

  it("storage key constants match iOS AppStorage namespace", () => {
    expect(LIVE_FEED_KEYS.lastSelectedProjectId).toBe(
      "ConstructOS.LiveFeed.LastSelectedProjectId",
    );
    expect(LIVE_FEED_KEYS.lastFleetSelection).toBe(
      "ConstructOS.LiveFeed.LastFleetSelection",
    );
  });

  it("Fleet toggle persists to localStorage under LastFleetSelection", () => {
    render(
      <LiveFeedClient
        projects={[{ id: "p1", name: "Alpha", client: null }]}
      />,
    );
    const fleetBtn = screen.getByRole("button", {
      name: /Switch to Fleet view/i,
    });
    fireEvent.click(fleetBtn);
    expect(localStorage.getItem(LIVE_FEED_KEYS.lastFleetSelection)).toBe("true");

    const backBtn = screen.getByRole("button", {
      name: /Switch to Per-Project view/i,
    });
    fireEvent.click(backBtn);
    expect(localStorage.getItem(LIVE_FEED_KEYS.lastFleetSelection)).toBe("false");
  });
});
