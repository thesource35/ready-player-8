"use client";

// Placeholder — full implementation lands in Plan 17-03 Task 2.
type Task = {
  id: string;
  project_id: string;
  name: string;
  start_date: string;
  end_date: string;
  trade?: string | null;
  percent_complete: number;
  is_critical: boolean;
};
type Dep = {
  id: string;
  predecessor_task_id: string;
  successor_task_id: string;
  dep_type: "FS" | "SS" | "FF" | "SF";
  lag_days: number;
};
type Milestone = {
  project_id: string;
  type: "start" | "end" | "bid_due" | "inspection";
  date: string;
  label: string;
  source_id: string;
};

export default function GanttChart(_props: {
  projectId: string;
  projectName: string;
  tasks: Task[];
  dependencies: Dep[];
  milestones: Milestone[];
  rangeStart: string;
  rangeEnd: string;
}) {
  return <div>Gantt (placeholder)</div>;
}
