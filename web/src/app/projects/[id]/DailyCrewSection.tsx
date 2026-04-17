"use client";
import { useEffect, useState } from "react";
import type { DailyCrew, TeamMember } from "@/lib/supabase/types";

export default function DailyCrewSection({ projectId }: { projectId: string }) {
  const [date, setDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [members, setMembers] = useState<TeamMember[]>([]);
  const [notes, setNotes] = useState("");
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState<string | null>(null);
  const [lastSaved, setLastSaved] = useState<{ selected: Set<string>; notes: string }>({
    selected: new Set(),
    notes: "",
  });
  const [error, setError] = useState<{ message: string; retryable: boolean } | null>(null);

  const isDirty = (() => {
    if (selected.size !== lastSaved.selected.size) return true;
    for (const id of selected) if (!lastSaved.selected.has(id)) return true;
    return notes !== lastSaved.notes;
  })();

  useEffect(() => {
    fetch("/api/team")
      .then((r) => (r.ok ? r.json() : []))
      .then((data: TeamMember[]) => setMembers(Array.isArray(data) ? data : []))
      .catch(() => setMembers([]));
  }, []);

  useEffect(() => {
    fetch(`/api/projects/${projectId}/daily-crew?date=${date}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((c: DailyCrew | null) => {
        setNotes(c?.notes ?? "");
        setSelected(new Set(c?.member_ids ?? []));
        setLastSaved({ selected: new Set(c?.member_ids ?? []), notes: c?.notes ?? "" });
      })
      .catch(() => {
        setNotes("");
        setSelected(new Set());
        setLastSaved({ selected: new Set(), notes: "" });
      });
  }, [projectId, date]);

  async function save() {
    setSaving(true);
    setStatus(null);
    setError(null);
    try {
      const res = await fetch(`/api/projects/${projectId}/daily-crew`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          assignment_date: date,
          member_ids: Array.from(selected),
          notes,
        }),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: "save failed" }));
        const isRetryable = res.status >= 500;
        setError({ message: err.error ?? "save failed", retryable: isRetryable });
        setStatus(null);
      } else {
        setStatus("Saved");
        setError(null);
        setLastSaved({ selected: new Set(selected), notes });
      }
    } finally {
      setSaving(false);
    }
  }

  return (
    <section
      style={{
        background: "var(--surface)",
        borderRadius: 14,
        padding: 16,
        marginTop: 24,
        border: "1px solid var(--border)",
      }}
    >
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      <h2
        id="daily-crew"
        style={{
          fontSize: 16,
          fontWeight: 800,
          letterSpacing: 2,
          color: "var(--text)",
          marginBottom: 16,
          textTransform: "uppercase",
        }}
      >
        Daily Crew
      </h2>
      <label style={{ fontSize: 12, color: "var(--muted)", display: "block", marginBottom: 8 }}>
        Date
      </label>
      <input
        type="date"
        value={date}
        aria-label="Crew assignment date"
        onChange={async (e) => {
          if (isDirty) {
            const confirmed = window.confirm("You have unsaved changes. Save before switching dates?");
            if (confirmed) await save();
          }
          setDate(e.target.value);
        }}
        style={{
          marginBottom: 16,
          padding: 8,
          borderRadius: 8,
          border: "1px solid var(--border)",
          background: "var(--bg)",
          color: "var(--text)",
          minHeight: 44,
        }}
      />
      {members.length === 0 ? (
        <p style={{ color: "var(--muted)", fontSize: 13 }}>
          No team members available. Add some under /team first.
        </p>
      ) : (
        <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
          {members.map((m) => (
            <li
              key={m.id}
              style={{
                minHeight: 44,
                display: "flex",
                alignItems: "center",
                gap: 8,
                borderTop: "1px solid var(--border)",
                padding: "4px 0",
              }}
            >
              <input
                type="checkbox"
                checked={selected.has(m.id)}
                onChange={(e) => {
                  const s = new Set(selected);
                  if (e.target.checked) s.add(m.id);
                  else s.delete(m.id);
                  setSelected(s);
                }}
                aria-label={`${m.name}${m.trade ? `, ${m.trade}` : ""}, ${selected.has(m.id) ? "assigned to crew" : "not assigned"}`}
                style={{ minWidth: 20, minHeight: 20 }}
              />
              <span style={{ color: "var(--text)", fontSize: 14 }}>{m.name}</span>
              {m.trade && (
                <span style={{ color: "var(--muted)", fontSize: 12 }}>&middot; {m.trade}</span>
              )}
            </li>
          ))}
        </ul>
      )}
      <textarea
        value={notes}
        onChange={(e) => setNotes(e.target.value)}
        placeholder="Scope notes"
        aria-label="Scope and notes for today's crew"
        style={{
          width: "100%",
          minHeight: 80,
          marginTop: 16,
          padding: 8,
          borderRadius: 8,
          border: "1px solid var(--border)",
          background: "var(--bg)",
          color: "var(--text)",
          fontFamily: "inherit",
        }}
      />
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginTop: 16 }}>
        <button
          onClick={save}
          disabled={saving}
          style={{
            padding: "10px 20px",
            background: saving ? "var(--muted)" : "var(--accent)",
            color: "var(--bg)",
            borderRadius: 8,
            border: "none",
            fontWeight: 600,
            cursor: saving ? "wait" : "pointer",
            minHeight: 44,
            display: "flex",
            alignItems: "center",
            gap: 8,
          }}
          aria-busy={saving}
          aria-label="Save crew assignments"
        >
          {saving && (
            <span
              style={{
                width: 14,
                height: 14,
                border: "2px solid transparent",
                borderTop: "2px solid var(--bg)",
                borderRadius: "50%",
                animation: "spin 0.6s linear infinite",
                display: "inline-block",
              }}
            />
          )}
          {saving ? "Saving..." : "Save"}
        </button>
        {status && !error && (
          <span style={{ fontSize: 12, color: "var(--green)" }} role="status" aria-live="polite">
            {status}
          </span>
        )}
        {error && (
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <span style={{ fontSize: 12, color: "var(--red)" }} role="alert">
              Error: {error.message}
            </span>
            {error.retryable && (
              <button
                onClick={save}
                disabled={saving}
                style={{
                  fontSize: 11,
                  fontWeight: 700,
                  color: "var(--accent)",
                  background: "none",
                  border: "1px solid var(--accent)",
                  borderRadius: 6,
                  padding: "4px 10px",
                  cursor: "pointer",
                }}
              >
                Retry
              </button>
            )}
          </div>
        )}
      </div>
    </section>
  );
}
