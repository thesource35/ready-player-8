"use client";

import { useEffect, useState, useCallback } from "react";
import ScheduleManagement from "../components/ScheduleManagement";
import type { ReportSchedule } from "@/lib/reports/types";

// ---------------------------------------------------------------------------
// Schedule Management Page (D-50b: dedicated section in Reports tab)
// ---------------------------------------------------------------------------

export default function SchedulesPage() {
  const [schedules, setSchedules] = useState<ReportSchedule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSchedules = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const res = await fetch("/api/reports/schedule");
      if (!res.ok) {
        const data = await res.json();
        setError(data.error || "Failed to load schedules");
        return;
      }
      const data = await res.json();
      setSchedules(data.schedules ?? []);
    } catch {
      setError("Network error loading schedules");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSchedules();
  }, [fetchSchedules]);

  if (loading) {
    return (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          gap: 8,
        }}
      >
        {/* Skeleton loading cards */}
        {[1, 2, 3].map((i) => (
          <div
            key={i}
            style={{
              background: "var(--surface)",
              borderRadius: 10,
              padding: 16,
              height: 100,
              animation: "pulse 1.5s ease-in-out infinite",
            }}
          />
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div
        style={{
          background: "var(--surface)",
          borderRadius: 10,
          padding: 24,
          textAlign: "center",
        }}
      >
        <div style={{ fontSize: 12, fontWeight: 800, color: "var(--red)", marginBottom: 8 }}>
          Error Loading Schedules
        </div>
        <div style={{ fontSize: 10, color: "var(--muted)", marginBottom: 16 }}>
          {error}
        </div>
        <button
          onClick={fetchSchedules}
          style={{
            padding: "8px 16px",
            fontSize: 10,
            fontWeight: 800,
            borderRadius: 6,
            border: "none",
            background: "var(--accent)",
            color: "var(--bg)",
            cursor: "pointer",
          }}
        >
          Retry
        </button>
      </div>
    );
  }

  return <ScheduleManagement schedules={schedules} onRefresh={fetchSchedules} />;
}
