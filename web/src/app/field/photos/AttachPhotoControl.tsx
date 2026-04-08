"use client";

// Phase 16 FIELD-02: Client component for attaching a photo to a field entity.
// Receives only serializable props and invokes the attachPhoto Server Action.

import { useState, useTransition } from "react";
import { attachPhoto } from "../actions";

type EntityType = "punch_item" | "daily_log" | "safety_incident";

const ENTITY_LABELS: Record<EntityType, string> = {
  punch_item: "Punch Item",
  daily_log: "Daily Log",
  safety_incident: "Safety Incident",
};

export function AttachPhotoControl({ documentId }: { documentId: string }) {
  const [entityType, setEntityType] = useState<EntityType>("punch_item");
  const [entityId, setEntityId] = useState("");
  const [msg, setMsg] = useState<{ kind: "ok" | "err"; text: string } | null>(
    null
  );
  const [isPending, startTransition] = useTransition();

  function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setMsg(null);
    startTransition(async () => {
      const res = await attachPhoto(documentId, entityType, entityId.trim());
      if (res.ok) {
        setMsg({ kind: "ok", text: "Attached" });
        setEntityId("");
      } else {
        setMsg({ kind: "err", text: `${res.status}: ${res.error}` });
      }
    });
  }

  return (
    <form
      onSubmit={onSubmit}
      style={{
        display: "flex",
        gap: 6,
        marginTop: 6,
        flexWrap: "wrap",
        alignItems: "center",
      }}
    >
      <select
        value={entityType}
        onChange={(e) => setEntityType(e.target.value as EntityType)}
        style={{
          fontSize: 10,
          padding: "4px 6px",
          background: "var(--bg)",
          color: "var(--text)",
          border: "1px solid var(--border)",
          borderRadius: 4,
        }}
        aria-label="Entity type"
      >
        {(Object.keys(ENTITY_LABELS) as EntityType[]).map((k) => (
          <option key={k} value={k}>
            {ENTITY_LABELS[k]}
          </option>
        ))}
      </select>
      <input
        type="text"
        value={entityId}
        onChange={(e) => setEntityId(e.target.value)}
        placeholder="entity UUID"
        aria-label="Entity ID"
        style={{
          fontSize: 10,
          padding: "4px 6px",
          background: "var(--bg)",
          color: "var(--text)",
          border: "1px solid var(--border)",
          borderRadius: 4,
          flex: "1 1 140px",
          minWidth: 120,
        }}
      />
      <button
        type="submit"
        disabled={isPending || !entityId.trim()}
        style={{
          fontSize: 10,
          fontWeight: 800,
          letterSpacing: 1,
          padding: "4px 10px",
          background: "var(--accent)",
          color: "var(--bg)",
          border: "none",
          borderRadius: 4,
          cursor: isPending ? "wait" : "pointer",
          opacity: isPending ? 0.6 : 1,
        }}
      >
        {isPending ? "..." : "ATTACH"}
      </button>
      {msg && (
        <span
          role="status"
          style={{
            fontSize: 9,
            color: msg.kind === "ok" ? "var(--green)" : "var(--red)",
          }}
        >
          {msg.text}
        </span>
      )}
    </form>
  );
}
