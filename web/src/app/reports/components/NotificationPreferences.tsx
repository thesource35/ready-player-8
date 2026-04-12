"use client";

import { useState, useEffect, useCallback } from "react";
import type { NotificationPrefs } from "@/lib/reports/notifications-integration";
import { DEFAULT_NOTIFICATION_PREFS } from "@/lib/reports/notifications-integration";

// ---------------------------------------------------------------------------
// Notification Preferences Component (D-101)
// Per-type toggles + per-project granularity + daily digest mode option
// ---------------------------------------------------------------------------

type NotificationPreferencesProps = {
  /** List of projects for per-project overrides */
  projects: Array<{ id: string; name: string }>;
};

const STORAGE_KEY = "ConstructOS.Reports.NotificationPrefs";

const NOTIFICATION_TYPES: Array<{
  key: keyof Pick<
    NotificationPrefs,
    "healthChanges" | "deliveries" | "thresholdAlerts" | "sharedLinkAccess" | "batchExport"
  >;
  label: string;
  description: string;
}> = [
  {
    key: "healthChanges",
    label: "Health Score Changes",
    description: "Get notified when a project's health color transitions (green/gold/red)",
  },
  {
    key: "deliveries",
    label: "Report Deliveries",
    description: "Notifications when scheduled reports are delivered or fail",
  },
  {
    key: "thresholdAlerts",
    label: "Metric Threshold Alerts",
    description: "Alerts when metrics exceed your configured thresholds",
  },
  {
    key: "sharedLinkAccess",
    label: "Shared Link Views",
    description: "Know when someone accesses a report via shared link",
  },
  {
    key: "batchExport",
    label: "Batch Export Status",
    description: "Notifications when batch exports complete or fail",
  },
];

export default function NotificationPreferences({
  projects,
}: NotificationPreferencesProps) {
  const [prefs, setPrefs] = useState<NotificationPrefs>(DEFAULT_NOTIFICATION_PREFS);
  const [saved, setSaved] = useState(false);

  // Load from localStorage on mount
  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as Partial<NotificationPrefs>;
        setPrefs({ ...DEFAULT_NOTIFICATION_PREFS, ...parsed });
      }
    } catch {
      // Ignore parse errors, use defaults
    }
  }, []);

  const savePrefs = useCallback(
    (updated: NotificationPrefs) => {
      setPrefs(updated);
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        setSaved(true);
        setTimeout(() => setSaved(false), 2000);
      } catch {
        // Storage full or unavailable
      }
    },
    []
  );

  const toggleType = (key: keyof NotificationPrefs) => {
    const updated = { ...prefs, [key]: !prefs[key as keyof NotificationPrefs] };
    savePrefs(updated as NotificationPrefs);
  };

  const toggleProject = (projectId: string) => {
    const current = prefs.projectOverrides[projectId];
    const updated: NotificationPrefs = {
      ...prefs,
      projectOverrides: {
        ...prefs.projectOverrides,
        [projectId]: { enabled: !current?.enabled },
      },
    };
    savePrefs(updated);
  };

  const toggleDigest = () => {
    savePrefs({ ...prefs, dailyDigest: !prefs.dailyDigest });
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
      {/* Header */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <div>
          <h3 style={{ margin: 0, fontSize: 18, fontWeight: 700, color: "var(--text, #fff)" }}>
            Report Notifications
          </h3>
          <p style={{ margin: "4px 0 0", fontSize: 13, color: "var(--muted, #888)" }}>
            Choose which report events send you notifications
          </p>
        </div>
        {saved && (
          <span
            style={{
              fontSize: 13,
              color: "var(--green, #22c55e)",
              fontWeight: 600,
            }}
            role="status"
          >
            Saved
          </span>
        )}
      </div>

      {/* Per-type toggles (D-101) */}
      <section>
        <h4
          style={{
            fontSize: 14,
            fontWeight: 600,
            color: "var(--muted, #888)",
            textTransform: "uppercase",
            letterSpacing: 1,
            margin: "0 0 12px",
          }}
        >
          Notification Types
        </h4>
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 8,
            background: "var(--surface, #1a1a2e)",
            borderRadius: 12,
            padding: 16,
          }}
        >
          {NOTIFICATION_TYPES.map((type) => (
            <label
              key={type.key}
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                padding: "10px 0",
                borderBottom: "1px solid var(--border, #333)",
                cursor: "pointer",
              }}
            >
              <div style={{ flex: 1 }}>
                <div
                  style={{
                    fontSize: 14,
                    fontWeight: 600,
                    color: "var(--text, #fff)",
                  }}
                >
                  {type.label}
                </div>
                <div
                  style={{
                    fontSize: 12,
                    color: "var(--muted, #888)",
                    marginTop: 2,
                  }}
                >
                  {type.description}
                </div>
              </div>
              <input
                type="checkbox"
                checked={!!prefs[type.key]}
                onChange={() => toggleType(type.key)}
                aria-label={`Toggle ${type.label} notifications`}
                style={{ width: 18, height: 18, cursor: "pointer" }}
              />
            </label>
          ))}
        </div>
      </section>

      {/* Daily digest mode (D-101) */}
      <section>
        <h4
          style={{
            fontSize: 14,
            fontWeight: 600,
            color: "var(--muted, #888)",
            textTransform: "uppercase",
            letterSpacing: 1,
            margin: "0 0 12px",
          }}
        >
          Delivery Mode
        </h4>
        <label
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            background: "var(--surface, #1a1a2e)",
            borderRadius: 12,
            padding: 16,
            cursor: "pointer",
          }}
        >
          <div>
            <div
              style={{
                fontSize: 14,
                fontWeight: 600,
                color: "var(--text, #fff)",
              }}
            >
              Daily Digest
            </div>
            <div
              style={{
                fontSize: 12,
                color: "var(--muted, #888)",
                marginTop: 2,
              }}
            >
              Batch all report notifications into a single daily summary
            </div>
          </div>
          <input
            type="checkbox"
            checked={prefs.dailyDigest}
            onChange={toggleDigest}
            aria-label="Toggle daily digest mode"
            style={{ width: 18, height: 18, cursor: "pointer" }}
          />
        </label>
      </section>

      {/* Per-project granularity (D-101) */}
      {projects.length > 0 && (
        <section>
          <h4
            style={{
              fontSize: 14,
              fontWeight: 600,
              color: "var(--muted, #888)",
              textTransform: "uppercase",
              letterSpacing: 1,
              margin: "0 0 12px",
            }}
          >
            Per-Project Overrides
          </h4>
          <p style={{ fontSize: 12, color: "var(--muted, #888)", margin: "0 0 8px" }}>
            Disable notifications for specific projects
          </p>
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              gap: 4,
              background: "var(--surface, #1a1a2e)",
              borderRadius: 12,
              padding: 16,
              maxHeight: 300,
              overflowY: "auto",
            }}
          >
            {projects.map((p) => {
              const enabled = prefs.projectOverrides[p.id]?.enabled !== false;
              return (
                <label
                  key={p.id}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    padding: "8px 0",
                    borderBottom: "1px solid var(--border, #333)",
                    cursor: "pointer",
                  }}
                >
                  <span
                    style={{
                      fontSize: 14,
                      color: enabled ? "var(--text, #fff)" : "var(--muted, #888)",
                    }}
                  >
                    {p.name}
                  </span>
                  <input
                    type="checkbox"
                    checked={enabled}
                    onChange={() => toggleProject(p.id)}
                    aria-label={`Toggle notifications for ${p.name}`}
                    style={{ width: 18, height: 18, cursor: "pointer" }}
                  />
                </label>
              );
            })}
          </div>
        </section>
      )}
    </div>
  );
}
