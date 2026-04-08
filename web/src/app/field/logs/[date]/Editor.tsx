"use client";

// Phase 16 FIELD-04: client editor for a daily log.
//
// Renders sections from the frozen template_snapshot. Local state per
// section. Explicit Save button (CONTEXT chose explicit save over autosave).

import { useState, useTransition } from "react";
import { saveDailyLog } from "./actions";

type Section = { id: string; label: string; kind: string; visibility: string };
type Template = { sections: Section[] } | null | undefined;

type EditorProps = {
  logId: string;
  date: string;
  template: unknown;
  content: unknown;
};

export default function Editor({ logId, date, template, content }: EditorProps) {
  const tpl = (template as Template) ?? { sections: [] };
  const initial = (content as Record<string, unknown>) ?? {};
  const [values, setValues] = useState<Record<string, unknown>>(initial);
  const [pending, startTransition] = useTransition();
  const [status, setStatus] = useState<string | null>(null);

  function update(id: string, v: unknown) {
    setValues((prev) => ({ ...prev, [id]: v }));
  }

  function onSave() {
    setStatus(null);
    startTransition(async () => {
      const res = await saveDailyLog(logId, values);
      setStatus(res.ok ? "Saved" : `Error: ${res.error}`);
    });
  }

  return (
    <main style={{ padding: 24, maxWidth: 800, margin: "0 auto" }}>
      <h1 style={{ marginBottom: 4 }}>Daily Log — {date}</h1>
      <p style={{ color: "var(--muted)", marginBottom: 24 }}>Log ID: {logId}</p>

      {tpl.sections.map((s) => (
        <section
          key={s.id}
          style={{
            marginBottom: 16,
            padding: 12,
            background: "var(--surface)",
            borderRadius: 12,
          }}
        >
          <label style={{ display: "block", fontWeight: 700, marginBottom: 6 }}>
            {s.label} {s.visibility === "required" ? <span style={{ color: "var(--red)" }}>*</span> : null}
          </label>
          {renderField(s, values[s.id], (v) => update(s.id, v))}
        </section>
      ))}

      <button
        type="button"
        onClick={onSave}
        disabled={pending}
        style={{
          padding: "10px 20px",
          background: "var(--accent)",
          color: "#000",
          border: 0,
          borderRadius: 10,
          fontWeight: 800,
          cursor: pending ? "wait" : "pointer",
        }}
      >
        {pending ? "Saving…" : "Save Log"}
      </button>
      {status ? <p style={{ marginTop: 12 }}>{status}</p> : null}
    </main>
  );
}

function renderField(s: Section, value: unknown, onChange: (v: unknown) => void) {
  if (s.kind === "weather") {
    if (value && typeof value === "object" && "error" in (value as Record<string, unknown>)) {
      return (
        <p style={{ color: "var(--gold)" }}>
          Weather unavailable: {(value as { error: string }).error}
        </p>
      );
    }
    if (value && typeof value === "object" && "tempC" in (value as Record<string, unknown>)) {
      const w = value as { tempC: number; conditions: string };
      return (
        <p>
          {w.tempC}°C — {w.conditions}
        </p>
      );
    }
    return <p style={{ color: "var(--muted)" }}>No weather data</p>;
  }
  if (s.kind === "open_rfis" || s.kind === "open_punch_items") {
    return <p>{typeof value === "number" ? value : 0} open</p>;
  }
  if (s.kind === "crew_on_site") {
    const arr = Array.isArray(value) ? value : [];
    return <p>{arr.length} crew assigned</p>;
  }
  return (
    <textarea
      value={typeof value === "string" ? value : ""}
      onChange={(e) => onChange(e.target.value)}
      rows={3}
      style={{
        width: "100%",
        background: "var(--panel)",
        color: "var(--text)",
        border: "1px solid var(--border)",
        borderRadius: 8,
        padding: 8,
        fontFamily: "inherit",
      }}
    />
  );
}
