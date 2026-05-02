"use client";

import { useState, useCallback } from "react";
import type { ReportSchedule } from "@/lib/reports/types";

// ---------------------------------------------------------------------------
// Schedule Management Component (D-50b, D-50f, D-50g, D-50o, D-110)
// ---------------------------------------------------------------------------

type ScheduleManagementProps = {
  schedules: ReportSchedule[];
  onRefresh: () => void;
};

const FREQUENCY_LABELS: Record<string, string> = {
  daily: "Daily",
  weekly: "Weekly",
  biweekly: "Every 2 Weeks",
  monthly: "Monthly",
};

const DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

// ---------------------------------------------------------------------------
// Create Schedule Modal
// ---------------------------------------------------------------------------

type CreateModalProps = {
  open: boolean;
  onClose: () => void;
  onCreated: () => void;
};

function CreateScheduleModal({ open, onClose, onCreated }: CreateModalProps) {
  const [name, setName] = useState("Portfolio Report");
  const [frequency, setFrequency] = useState<"daily" | "weekly" | "biweekly" | "monthly">("weekly");
  const [dayOfWeek, setDayOfWeek] = useState(1); // Monday
  const [dayOfMonth, setDayOfMonth] = useState(1);
  const [timeUtc, setTimeUtc] = useState("08:00");
  const [timezone, setTimezone] = useState(
    Intl.DateTimeFormat().resolvedOptions().timeZone || "America/New_York"
  );
  const [recipientInput, setRecipientInput] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleCreate = async () => {
    setError(null);
    const recipients = recipientInput
      .split(",")
      .map((r) => r.trim())
      .filter(Boolean);

    if (recipients.length === 0) {
      setError("At least one recipient UUID is required");
      return;
    }

    setSaving(true);
    try {
      const body: Record<string, unknown> = {
        name,
        frequency,
        time_utc: timeUtc,
        timezone,
        recipients,
        sections: [],
      };

      if (frequency === "weekly" || frequency === "biweekly") {
        body.day_of_week = dayOfWeek;
      }
      if (frequency === "monthly") {
        body.day_of_month = dayOfMonth;
      }

      const res = await fetch("/api/reports/schedule", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      if (!res.ok) {
        const data = await res.json();
        setError(data.error || "Failed to create schedule");
        return;
      }

      onCreated();
      onClose();
    } catch {
      setError("Network error");
    } finally {
      setSaving(false);
    }
  };

  if (!open) return null;

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 1000,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: "rgba(0,0,0,0.6)",
      }}
      onClick={onClose}
    >
      <div
        style={{
          background: "var(--surface)",
          borderRadius: 14,
          padding: 24,
          width: 440,
          maxHeight: "80vh",
          overflow: "auto",
          border: "1px solid rgba(105,210,148,0.12)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div
          style={{
            fontSize: 14,
            fontWeight: 800,
            marginBottom: 16,
          }}
        >
          Create Schedule
        </div>

        {error && (
          <div
            style={{
              background: "rgba(239,68,68,0.1)",
              color: "var(--red)",
              padding: 8,
              borderRadius: 6,
              fontSize: 10,
              marginBottom: 12,
            }}
          >
            {error}
          </div>
        )}

        {/* Name */}
        <label style={labelStyle}>Schedule Name</label>
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          style={inputStyle}
        />

        {/* Frequency (D-49) */}
        <label style={labelStyle}>Frequency</label>
        <select
          value={frequency}
          onChange={(e) => setFrequency(e.target.value as typeof frequency)}
          style={inputStyle}
        >
          <option value="daily">Daily</option>
          <option value="weekly">Weekly</option>
          <option value="biweekly">Every 2 Weeks</option>
          <option value="monthly">Monthly</option>
        </select>

        {/* Day picker */}
        {(frequency === "weekly" || frequency === "biweekly") && (
          <>
            <label style={labelStyle}>Day of Week</label>
            <select
              value={dayOfWeek}
              onChange={(e) => setDayOfWeek(Number(e.target.value))}
              style={inputStyle}
            >
              {DAY_NAMES.map((d, i) => (
                <option key={i} value={i}>
                  {d}
                </option>
              ))}
            </select>
          </>
        )}

        {frequency === "monthly" && (
          <>
            <label style={labelStyle}>Day of Month</label>
            <select
              value={dayOfMonth}
              onChange={(e) => setDayOfMonth(Number(e.target.value))}
              style={inputStyle}
            >
              {Array.from({ length: 31 }, (_, i) => i + 1).map((d) => (
                <option key={d} value={d}>
                  {d}
                </option>
              ))}
            </select>
          </>
        )}

        {/* Time picker */}
        <label style={labelStyle}>Time (UTC)</label>
        <input
          type="time"
          value={timeUtc}
          onChange={(e) => setTimeUtc(e.target.value)}
          style={inputStyle}
        />

        {/* Timezone (D-50j) */}
        <label style={labelStyle}>Timezone</label>
        <input
          type="text"
          value={timezone}
          onChange={(e) => setTimezone(e.target.value)}
          placeholder="America/New_York"
          style={inputStyle}
        />

        {/* Recipients (D-50e) */}
        <label style={labelStyle}>Recipients (comma-separated UUIDs)</label>
        <input
          type="text"
          value={recipientInput}
          onChange={(e) => setRecipientInput(e.target.value)}
          placeholder="uuid-1, uuid-2"
          style={inputStyle}
        />
        <div style={{ fontSize: 8, color: "var(--muted)", marginBottom: 12 }}>
          Team members only. Enter user UUIDs from your organization.
        </div>

        <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
          <button onClick={onClose} style={secondaryBtnStyle}>
            Cancel
          </button>
          <button onClick={handleCreate} disabled={saving} style={primaryBtnStyle}>
            {saving ? "Creating..." : "Create Schedule"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Mini Calendar (D-118)
// ---------------------------------------------------------------------------

function MiniCalendar({ schedules }: { schedules: ReportSchedule[] }) {
  const today = new Date();
  const days: Date[] = [];
  for (let i = 0; i < 14; i++) {
    const d = new Date(today);
    d.setDate(d.getDate() + i);
    days.push(d);
  }

  // Map next_run_at dates to schedule names
  const deliveryMap = new Map<string, string[]>();
  for (const s of schedules) {
    if (s.next_run_at && s.is_active) {
      const key = new Date(s.next_run_at).toISOString().slice(0, 10);
      const existing = deliveryMap.get(key) ?? [];
      existing.push(s.frequency);
      deliveryMap.set(key, existing);
    }
  }

  return (
    <div
      style={{
        background: "var(--surface)",
        borderRadius: 10,
        padding: 16,
        marginBottom: 8,
        border: "1px solid rgba(105,210,148,0.08)",
      }}
    >
      <div
        style={{
          fontSize: 10,
          fontWeight: 800,
          marginBottom: 12,
          color: "var(--text)",
        }}
      >
        Upcoming Deliveries
      </div>
      <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
        {days.map((d) => {
          const key = d.toISOString().slice(0, 10);
          const hasDelivery = deliveryMap.has(key);
          const isToday = key === today.toISOString().slice(0, 10);
          return (
            <div
              key={key}
              title={
                hasDelivery
                  ? `${deliveryMap.get(key)!.length} delivery(ies)`
                  : "No deliveries"
              }
              style={{
                width: 36,
                height: 36,
                borderRadius: 6,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                background: hasDelivery
                  ? "rgba(0,212,255,0.15)"
                  : "rgba(255,255,255,0.03)",
                border: isToday
                  ? "1px solid var(--accent)"
                  : "1px solid transparent",
                fontSize: 8,
                fontWeight: hasDelivery ? 800 : 400,
                color: hasDelivery ? "var(--cyan)" : "var(--muted)",
              }}
            >
              <span>{DAY_NAMES[d.getDay()]}</span>
              <span>{d.getDate()}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Schedule Card
// ---------------------------------------------------------------------------

type CardProps = {
  schedule: ReportSchedule;
  selected: boolean;
  onToggleSelect: (id: string) => void;
  onAction: (id: string, action: string) => void;
  loading: boolean;
};

function ScheduleCard({
  schedule,
  selected,
  onToggleSelect,
  onAction,
  loading,
}: CardProps) {
  const nextRun = schedule.next_run_at
    ? new Date(schedule.next_run_at).toLocaleString()
    : "Not scheduled";

  const lastRun = schedule.last_run_at
    ? new Date(schedule.last_run_at).toLocaleString()
    : "Never";

  return (
    <div
      style={{
        background: "var(--surface)",
        borderRadius: 10,
        padding: 16,
        marginBottom: 8,
        border: selected
          ? "1px solid var(--accent)"
          : "1px solid rgba(105,210,148,0.08)",
        opacity: loading ? 0.6 : 1,
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          marginBottom: 8,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          {/* Bulk selection checkbox (D-110) */}
          <input
            type="checkbox"
            checked={selected}
            onChange={() => onToggleSelect(schedule.id)}
            style={{ accentColor: "var(--accent)" }}
            aria-label={`Select ${schedule.id}`}
          />

          {/* Schedule name: fontSize 12, fontWeight 800 */}
          <span style={{ fontSize: 12, fontWeight: 800 }}>
            {(schedule as Record<string, unknown>).name as string || "Portfolio Report"}
          </span>
        </div>

        {/* Status indicator (D-50f) */}
        <span
          style={{
            fontSize: 8,
            fontWeight: 800,
            color: schedule.is_active ? "var(--green)" : "var(--gold)",
            textTransform: "uppercase",
          }}
        >
          {schedule.is_active ? "Active" : "Paused"}
        </span>
      </div>

      {/* Frequency label */}
      <div style={{ fontSize: 8, color: "var(--muted)", marginBottom: 4 }}>
        {FREQUENCY_LABELS[schedule.frequency] || schedule.frequency}
        {schedule.day_of_week != null &&
          (schedule.frequency === "weekly" || schedule.frequency === "biweekly") &&
          ` on ${DAY_NAMES[schedule.day_of_week]}`}
        {schedule.day_of_month != null &&
          schedule.frequency === "monthly" &&
          ` on the ${schedule.day_of_month}${getOrdinalSuffix(schedule.day_of_month)}`}
        {" at "}
        {schedule.time_utc} UTC
      </div>

      {/* Next run (D-50t) */}
      <div style={{ fontSize: 8, fontWeight: 800, color: "var(--cyan)", marginBottom: 4 }}>
        Next: {nextRun}
      </div>

      {/* Last delivery status (D-50t) */}
      <div style={{ fontSize: 8, color: "var(--muted)", marginBottom: 8 }}>
        Last run: {lastRun}
      </div>

      {/* Recipients */}
      <div style={{ fontSize: 8, color: "var(--muted)", marginBottom: 12 }}>
        {schedule.recipients.length} recipient(s)
      </div>

      {/* Actions: Pause/Resume, Send Now, Send Test, Delete (D-50f, D-50g, D-50o) */}
      <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
        <button
          onClick={() =>
            onAction(
              schedule.id,
              schedule.is_active ? "pause" : "resume"
            )
          }
          disabled={loading}
          style={smallBtnStyle}
        >
          {schedule.is_active ? "Pause" : "Resume"}
        </button>
        <button
          onClick={() => onAction(schedule.id, "send_now")}
          disabled={loading || !schedule.is_active}
          style={smallBtnStyle}
        >
          Send Now
        </button>
        <button
          onClick={() => onAction(schedule.id, "send_test")}
          disabled={loading}
          style={smallBtnStyle}
        >
          Send Test
        </button>
        <button
          onClick={() => onAction(schedule.id, "delete")}
          disabled={loading}
          style={{
            ...smallBtnStyle,
            color: "var(--red)",
            borderColor: "rgba(239,68,68,0.3)",
          }}
        >
          Delete
        </button>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Main Component
// ---------------------------------------------------------------------------

export default function ScheduleManagement({
  schedules,
  onRefresh,
}: ScheduleManagementProps) {
  const [showCreate, setShowCreate] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [loadingIds, setLoadingIds] = useState<Set<string>>(new Set());
  const [sortBy, setSortBy] = useState<"next_run" | "name" | "frequency">("next_run");

  const toggleSelect = useCallback((id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const toggleSelectAll = useCallback(() => {
    if (selectedIds.size === schedules.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(schedules.map((s) => s.id)));
    }
  }, [selectedIds.size, schedules]);

  // Sort schedules (D-118: sortable list)
  const sortedSchedules = [...schedules].sort((a, b) => {
    switch (sortBy) {
      case "next_run":
        return (
          new Date(a.next_run_at ?? "9999").getTime() -
          new Date(b.next_run_at ?? "9999").getTime()
        );
      case "name": {
        const aName = ((a as Record<string, unknown>).name as string) ?? "";
        const bName = ((b as Record<string, unknown>).name as string) ?? "";
        return aName.localeCompare(bName);
      }
      case "frequency":
        return a.frequency.localeCompare(b.frequency);
      default:
        return 0;
    }
  });

  const handleAction = async (id: string, action: string) => {
    setLoadingIds((prev) => new Set(prev).add(id));

    try {
      if (action === "delete") {
        if (!confirm("Delete this schedule? This cannot be undone.")) return;
        await fetch(`/api/reports/schedule?id=${id}`, { method: "DELETE" });
      } else if (action === "pause" || action === "resume") {
        const updateRes = await fetch("/api/reports/schedule", {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ id, is_active: action === "resume" }),
        });
        if (!updateRes.ok) throw new Error(`HTTP ${updateRes.status}`);
      } else if (action === "send_now" || action === "send_test") {
        const sendRes = await fetch("/api/reports/schedule", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ action, schedule_id: id }),
        });
        if (!sendRes.ok) throw new Error(`HTTP ${sendRes.status}`);
      }
      onRefresh();
    } catch (err) {
      // 999.5 (d) audit: previously the await fetch above had no res.ok
      // check, so non-2xx responses were treated as success. Now: HTTP
      // failures throw and land here; we still console.error (no UI
      // error surface in this component yet -- TODO follow-up to add a
      // visible error toast to ScheduleManagement).
      console.error(`Schedule action ${action} failed:`, err);
    } finally {
      setLoadingIds((prev) => {
        const next = new Set(prev);
        next.delete(id);
        return next;
      });
    }
  };

  // Bulk operations (D-110)
  const handleBulkAction = async (action: "pause" | "resume" | "delete") => {
    const ids = Array.from(selectedIds);
    if (ids.length === 0) return;

    if (action === "delete" && !confirm(`Delete ${ids.length} schedule(s)?`)) return;

    for (const id of ids) {
      await handleAction(id, action);
    }
    setSelectedIds(new Set());
  };

  return (
    <div>
      <CreateScheduleModal
        open={showCreate}
        onClose={() => setShowCreate(false)}
        onCreated={onRefresh}
      />

      {/* Header with Create button */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          marginBottom: 12,
        }}
      >
        <div style={{ fontSize: 12, fontWeight: 800 }}>
          Email Schedules ({schedules.length})
        </div>
        <button onClick={() => setShowCreate(true)} style={primaryBtnStyle}>
          + Create Schedule
        </button>
      </div>

      {/* Mini Calendar (D-118) */}
      <MiniCalendar schedules={schedules} />

      {/* Toolbar: bulk ops + sort (D-110, D-118) */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 8,
          marginBottom: 8,
          flexWrap: "wrap",
        }}
      >
        <label style={{ display: "flex", alignItems: "center", gap: 4, fontSize: 8 }}>
          <input
            type="checkbox"
            checked={selectedIds.size === schedules.length && schedules.length > 0}
            onChange={toggleSelectAll}
            style={{ accentColor: "var(--accent)" }}
            aria-label="Select all schedules"
          />
          Select All
        </label>

        {selectedIds.size > 0 && (
          <>
            <button
              onClick={() => handleBulkAction("pause")}
              style={smallBtnStyle}
            >
              Pause ({selectedIds.size})
            </button>
            <button
              onClick={() => handleBulkAction("resume")}
              style={smallBtnStyle}
            >
              Resume ({selectedIds.size})
            </button>
            <button
              onClick={() => handleBulkAction("delete")}
              style={{
                ...smallBtnStyle,
                color: "var(--red)",
                borderColor: "rgba(239,68,68,0.3)",
              }}
            >
              Delete ({selectedIds.size})
            </button>
          </>
        )}

        <div style={{ marginLeft: "auto" }}>
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as typeof sortBy)}
            style={{
              ...inputStyle,
              width: "auto",
              marginBottom: 0,
              padding: "4px 8px",
              fontSize: 8,
            }}
          >
            <option value="next_run">Sort: Next Run</option>
            <option value="name">Sort: Name</option>
            <option value="frequency">Sort: Frequency</option>
          </select>
        </div>
      </div>

      {/* Schedule Cards */}
      {sortedSchedules.length === 0 ? (
        <div
          style={{
            background: "var(--surface)",
            borderRadius: 10,
            padding: 32,
            textAlign: "center",
          }}
        >
          <div style={{ fontSize: 12, fontWeight: 800, marginBottom: 8 }}>
            No Schedules Yet
          </div>
          <div style={{ fontSize: 10, color: "var(--muted)", marginBottom: 16 }}>
            Create a schedule to automatically email portfolio reports to your team.
          </div>
          <button onClick={() => setShowCreate(true)} style={primaryBtnStyle}>
            + Create Your First Schedule
          </button>
        </div>
      ) : (
        sortedSchedules.map((s) => (
          <ScheduleCard
            key={s.id}
            schedule={s}
            selected={selectedIds.has(s.id)}
            onToggleSelect={toggleSelect}
            onAction={handleAction}
            loading={loadingIds.has(s.id)}
          />
        ))
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Shared styles
// ---------------------------------------------------------------------------

const labelStyle: React.CSSProperties = {
  display: "block",
  fontSize: 8,
  fontWeight: 800,
  color: "var(--muted)",
  marginBottom: 4,
  textTransform: "uppercase",
  letterSpacing: 0.5,
};

const inputStyle: React.CSSProperties = {
  width: "100%",
  padding: "8px 10px",
  fontSize: 10,
  borderRadius: 6,
  border: "1px solid rgba(255,255,255,0.1)",
  background: "rgba(255,255,255,0.04)",
  color: "var(--text)",
  marginBottom: 12,
  outline: "none",
};

const primaryBtnStyle: React.CSSProperties = {
  padding: "8px 16px",
  fontSize: 10,
  fontWeight: 800,
  borderRadius: 6,
  border: "none",
  background: "var(--accent)",
  color: "var(--bg)",
  cursor: "pointer",
};

const secondaryBtnStyle: React.CSSProperties = {
  padding: "8px 16px",
  fontSize: 10,
  fontWeight: 800,
  borderRadius: 6,
  border: "1px solid rgba(255,255,255,0.1)",
  background: "transparent",
  color: "var(--text)",
  cursor: "pointer",
};

const smallBtnStyle: React.CSSProperties = {
  padding: "4px 10px",
  fontSize: 8,
  fontWeight: 600,
  borderRadius: 4,
  border: "1px solid rgba(255,255,255,0.1)",
  background: "transparent",
  color: "var(--text)",
  cursor: "pointer",
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function getOrdinalSuffix(n: number): string {
  const s = ["th", "st", "nd", "rd"];
  const v = n % 100;
  return s[(v - 20) % 10] || s[v] || s[0];
}
