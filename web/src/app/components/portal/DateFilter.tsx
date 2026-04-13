"use client";

// Portal date filter for photo timeline (D-51)
// Two date inputs with Apply/Clear filter controls

import { useState } from "react";

type DateFilterProps = {
  onFilter: (range: { start: string; end: string } | null) => void;
};

export default function DateFilter({ onFilter }: DateFilterProps) {
  const [start, setStart] = useState("");
  const [end, setEnd] = useState("");

  function handleApply() {
    if (!start && !end) return;
    onFilter({
      start: start || "1970-01-01",
      end: end || "2099-12-31",
    });
  }

  function handleClear() {
    setStart("");
    setEnd("");
    onFilter(null);
  }

  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 8,
        flexWrap: "wrap",
        padding: "8px 0",
      }}
    >
      <label
        style={{
          fontSize: 13,
          fontWeight: 500,
          color: "#374151",
        }}
      >
        Filter by date:
      </label>

      <input
        type="date"
        value={start}
        onChange={(e) => setStart(e.target.value)}
        aria-label="Start date"
        style={{
          padding: "6px 10px",
          fontSize: 13,
          border: "1px solid #D1D5DB",
          borderRadius: 6,
          outline: "none",
          color: "#1F2937",
          background: "#FFFFFF",
          minHeight: 36,
        }}
      />

      <span style={{ fontSize: 12, color: "#9CA3AF" }}>to</span>

      <input
        type="date"
        value={end}
        onChange={(e) => setEnd(e.target.value)}
        aria-label="End date"
        style={{
          padding: "6px 10px",
          fontSize: 13,
          border: "1px solid #D1D5DB",
          borderRadius: 6,
          outline: "none",
          color: "#1F2937",
          background: "#FFFFFF",
          minHeight: 36,
        }}
      />

      <button
        onClick={handleApply}
        disabled={!start && !end}
        style={{
          padding: "6px 14px",
          fontSize: 13,
          fontWeight: 500,
          background:
            start || end
              ? "var(--portal-primary, #2563EB)"
              : "#D1D5DB",
          color: start || end ? "#FFFFFF" : "#6B7280",
          border: "none",
          borderRadius: 6,
          cursor: start || end ? "pointer" : "default",
          minHeight: 36,
        }}
      >
        Apply
      </button>

      {(start || end) && (
        <button
          onClick={handleClear}
          style={{
            padding: "6px 10px",
            fontSize: 12,
            fontWeight: 500,
            background: "transparent",
            color: "var(--portal-primary, #2563EB)",
            border: "none",
            cursor: "pointer",
            textDecoration: "underline",
          }}
        >
          Clear filter
        </button>
      )}
    </div>
  );
}
