/**
 * Phase 17 D-03: milestones are derived, not stored.
 * A milestone row in the timeline comes from one of four sources:
 *   - cs_projects.start_date  → "Project Start"
 *   - cs_projects.end_date    → "Project End"
 *   - cs_contracts.bid_due_date → "Bid Due"
 *   - cs_schedule_events (event_type='inspection') → "Inspection"
 */

import { isIsoDate } from "./dates";

export type MilestoneType = "start" | "end" | "bid_due" | "inspection";

export type Milestone = {
  project_id: string;
  type: MilestoneType;
  date: string; // YYYY-MM-DD
  label: string;
  source_id: string;
};

export type DeriveInput = {
  projects: Array<{
    id: string;
    name?: string | null;
    start_date?: string | null;
    end_date?: string | null;
  }>;
  contracts: Array<{
    id: string;
    project_id?: string | null;
    bid_due_date?: string | null;
  }>;
  events: Array<{
    id: string;
    project_id?: string | null;
    event_type?: string | null;
    date?: string | null;
    title?: string | null;
  }>;
};

/**
 * Pure function: collapses projects/contracts/events into a flat milestone list.
 * Filters falsy dates and non-inspection events. Safe to call with empty arrays.
 */
export function deriveMilestones(input: DeriveInput): Milestone[] {
  const out: Milestone[] = [];

  for (const p of input.projects ?? []) {
    if (isIsoDate(p.start_date)) {
      out.push({
        project_id: p.id,
        type: "start",
        date: p.start_date,
        label: p.name ? `${p.name} — Project Start` : "Project Start",
        source_id: p.id,
      });
    }
    if (isIsoDate(p.end_date)) {
      out.push({
        project_id: p.id,
        type: "end",
        date: p.end_date,
        label: p.name ? `${p.name} — Project End` : "Project End",
        source_id: p.id,
      });
    }
  }

  for (const c of input.contracts ?? []) {
    if (isIsoDate(c.bid_due_date) && c.project_id) {
      out.push({
        project_id: c.project_id,
        type: "bid_due",
        date: c.bid_due_date,
        label: "Bid Due",
        source_id: c.id,
      });
    }
  }

  for (const e of input.events ?? []) {
    if (
      (e.event_type ?? "").toLowerCase() === "inspection" &&
      isIsoDate(e.date) &&
      e.project_id
    ) {
      out.push({
        project_id: e.project_id,
        type: "inspection",
        date: e.date,
        label: e.title || "Inspection",
        source_id: e.id,
      });
    }
  }

  return out;
}
