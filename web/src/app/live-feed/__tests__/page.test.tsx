// @vitest-environment jsdom
// Owner: 29-08-PLAN.md Wave 4 — LIVE-03 (web): /live-feed renders 200
import { describe, it, expect, afterEach, beforeAll } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";

// Rule 3 auto-fix: vitest 4 + jsdom 29 sometimes exposes a bare `{}` as
// `window.localStorage` (no Storage prototype). Install an in-memory shim
// before any production code loads so `readBool`/`readString` in
// livefeed-storage.ts get a real Storage-shaped object.
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

import { LiveFeedClient } from "../LiveFeedClient";

afterEach(() => {
  cleanup();
  localStorage.clear();
});

describe("/live-feed page", () => {
  it("renders empty state when projects is empty", () => {
    render(<LiveFeedClient projects={[]} />);
    expect(screen.getByText(/No Projects/i)).toBeDefined();
  });

  it("renders LIVE FEED header when projects present", () => {
    render(
      <LiveFeedClient projects={[{ id: "p1", name: "Riverfront", client: null, org_id: "org_1" }]} />,
    );
    expect(screen.getByText(/LIVE FEED/i)).toBeDefined();
  });

  it("defaults to per-project view when Fleet toggle not persisted", () => {
    render(
      <LiveFeedClient projects={[{ id: "p1", name: "Riverfront", client: null, org_id: "org_1" }]} />,
    );
    // Button label reads PER-PROJECT when fleetMode is false (default).
    expect(screen.getByText(/PER-PROJECT/i)).toBeDefined();
  });
});
