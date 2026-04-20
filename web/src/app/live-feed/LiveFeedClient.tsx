// Phase 29 LIVE-03 / LIVE-04 — client shell.
// Per-project default (D-06) + Fleet toggle (D-07). Persists to localStorage under ConstructOS.LiveFeed.*.
// Per-project content (video + scrubber + upload) filled by 29-09; suggestions/traffic/budget filled by 29-10.

"use client";

import { useState, useSyncExternalStore } from "react";
import type { CSSProperties } from "react";
import type { LiveFeedProject } from "./page";
import { ProjectSwitcher } from "./ProjectSwitcher";
import { FleetView } from "./FleetView";
import { LIVE_FEED_KEYS, readBool, readString, writeBool } from "./livefeed-storage";

// useSyncExternalStore snapshot returns true after hydration, false during SSR.
// This is the canonical React 19 pattern for "is this running on the client?"
// and it does not trigger react-hooks/set-state-in-effect.
function subscribe() {
  return () => {};
}
function getClientSnapshot(): boolean {
  return true;
}
function getServerSnapshot(): boolean {
  return false;
}

export function LiveFeedClient({ projects }: { projects: LiveFeedProject[] }) {
  const hydrated = useSyncExternalStore(subscribe, getClientSnapshot, getServerSnapshot);

  // Lazy initializers read localStorage on the client without scheduling a
  // post-render setState. On the server, readBool/readString short-circuit on
  // `typeof window === "undefined"`, so initial state is deterministic.
  const [fleetMode, setFleetMode] = useState<boolean>(() =>
    readBool(LIVE_FEED_KEYS.lastFleetSelection, false),
  );
  const [selectedProjectId, setSelectedProjectId] = useState<string>(() =>
    readString(LIVE_FEED_KEYS.lastSelectedProjectId, ""),
  );

  // Reconcile the persisted projectId against the projects prop.
  // If the stored project is no longer in the user's list, fall back to the first one.
  const effectiveProjectId =
    selectedProjectId && projects.some((p) => p.id === selectedProjectId)
      ? selectedProjectId
      : projects[0]?.id ?? "";

  function toggleFleet() {
    const next = !fleetMode;
    setFleetMode(next);
    writeBool(LIVE_FEED_KEYS.lastFleetSelection, next);
  }

  if (projects.length === 0) {
    return (
      <div style={{ padding: 48, textAlign: "center" }}>
        <h1 style={{ fontSize: 20, fontWeight: 800, color: "var(--text)" }}>No Projects</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>
          You don&apos;t have access to any projects yet. Contact your admin to be added.
        </p>
      </div>
    );
  }

  return (
    <div style={{ padding: 16, display: "flex", flexDirection: "column", gap: 16 }}>
      <header style={{ display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap" }}>
        <span
          style={{
            fontSize: 11,
            fontWeight: 800,
            letterSpacing: 2,
            color: "var(--accent)",
          }}
        >
          LIVE FEED
        </span>
        {!fleetMode && (
          <ProjectSwitcher
            projects={projects}
            selectedProjectId={effectiveProjectId}
            onSelect={setSelectedProjectId}
          />
        )}
        <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 8 }}>
          <button
            type="button"
            onClick={toggleFleet}
            style={{
              fontSize: 9,
              fontWeight: 800,
              letterSpacing: 2,
              padding: "6px 12px",
              borderRadius: 8,
              background: fleetMode ? "var(--accent)" : "var(--surface)",
              color: fleetMode ? "black" : "var(--muted)",
              border: "1px solid " + (fleetMode ? "var(--accent)" : "var(--surface)"),
              cursor: "pointer",
            }}
            aria-label={fleetMode ? "Switch to Per-Project view" : "Switch to Fleet view"}
          >
            {fleetMode ? "FLEET VIEW" : "PER-PROJECT"}
          </button>
        </div>
      </header>
      {!hydrated ? null : fleetMode ? (
        <FleetView projects={projects} />
      ) : (
        <PerProjectShell projectId={effectiveProjectId} />
      )}
    </div>
  );
}

// Per-project shell — 29-09 fills video/scrubber/upload; 29-10 fills suggestions/traffic/budget.
function PerProjectShell({ projectId }: { projectId: string }) {
  return (
    <section
      data-testid="live-feed-per-project"
      data-project-id={projectId}
      style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: 16 }}
    >
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        <div data-section="video-player" style={placeholderStyle(220)}>
          Video player — 29-09
        </div>
        <div data-section="scrubber" style={placeholderStyle(56)}>
          Scrubber — 29-09
        </div>
        <div data-section="traffic" style={placeholderStyle(120)}>
          Traffic — 29-10
        </div>
        <div data-section="minimap" style={placeholderStyle(240)}>
          Mini-map — 29-10 or follow-up
        </div>
        <div data-section="library" style={placeholderStyle(80)}>
          Drone Library — 29-09
        </div>
      </div>
      <aside data-section="suggestions-stream" style={placeholderStyle(420)}>
        Suggestion stream — 29-10
      </aside>
    </section>
  );
}

function placeholderStyle(h: number): CSSProperties {
  return {
    height: h,
    background: "var(--surface)",
    borderRadius: 14,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    color: "var(--muted)",
    fontSize: 12,
  };
}
