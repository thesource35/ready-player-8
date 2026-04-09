// @vitest-environment jsdom
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import React from "react";
import { render, screen, cleanup, fireEvent } from "@testing-library/react";
import GanttChart, {
  type GanttTask,
  type GanttDep,
} from "../GanttChart";
import { daysBetween, addDays } from "@/lib/calendar/dates";

// Ensure TZ is set before any Date construction below.
beforeEach(() => {
  process.env.TZ = "America/Los_Angeles";
});

afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});

function makeTask(partial: Partial<GanttTask> = {}): GanttTask {
  return {
    id: "t1",
    project_id: "p1",
    name: "Task 1",
    start_date: "2026-04-01",
    end_date: "2026-04-05",
    trade: null,
    percent_complete: 0,
    is_critical: false,
    ...partial,
  };
}

describe("Gantt", () => {
  it("renders one TaskBar per task in window", () => {
    const tasks = [
      makeTask({ id: "t1", name: "Alpha" }),
      makeTask({ id: "t2", name: "Beta", start_date: "2026-04-06", end_date: "2026-04-08" }),
      makeTask({ id: "t3", name: "Gamma", start_date: "2026-04-10", end_date: "2026-04-12" }),
    ];
    render(
      <GanttChart
        projectId="p1"
        tasks={tasks}
        dependencies={[]}
        milestones={[]}
        rangeStart="2026-04-01"
        rangeEnd="2026-04-30"
      />
    );
    expect(screen.getByTestId("task-bar-t1")).toBeTruthy();
    expect(screen.getByTestId("task-bar-t2")).toBeTruthy();
    expect(screen.getByTestId("task-bar-t3")).toBeTruthy();
  });

  it("pointer drag commits Math.round(deltaPx/dayWidth) day delta", async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, json: async () => ({}) });
    vi.stubGlobal("fetch", fetchMock);

    const task = makeTask({ id: "t1", start_date: "2026-04-01", end_date: "2026-04-05" });
    render(
      <GanttChart
        projectId="p1"
        tasks={[task]}
        dependencies={[]}
        milestones={[]}
        rangeStart="2026-04-01"
        rangeEnd="2026-04-30"
      />
    );
    const bar = screen.getByTestId("task-bar-t1") as HTMLElement;

    // jsdom doesn't implement setPointerCapture — stub it on the prototype so
    // React's synthetic event can call it on currentTarget.
    (HTMLElement.prototype as unknown as { setPointerCapture: (id: number) => void }).setPointerCapture =
      () => {};

    // DAY_WIDTH = 20. Drag +60px → +3 days.
    fireEvent.pointerDown(bar, { clientX: 100, pointerId: 1 });
    fireEvent.pointerMove(bar, { clientX: 160, pointerId: 1 });
    fireEvent.pointerUp(bar, { clientX: 160, pointerId: 1 });

    // Let microtasks flush (PATCH is async).
    await new Promise((r) => setTimeout(r, 10));

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0];
    expect(String(url)).toContain("/api/calendar/tasks/t1");
    expect(init.method).toBe("PATCH");
    const body = JSON.parse(init.body);
    expect(body.start_date).toBe("2026-04-04");
    expect(body.end_date).toBe("2026-04-08");
  });

  it("DST boundary drag in America/Los_Angeles preserves duration_days", () => {
    expect(process.env.TZ).toBe("America/Los_Angeles");

    // Spring-forward 2026: March 8, 2026 in America/Los_Angeles.
    // Pick a task that straddles the boundary on a 7-day drag.
    const originalStart = "2026-03-01";
    const originalEnd = "2026-03-05";
    const originalDuration = daysBetween(originalStart, originalEnd);

    const newStart = addDays(originalStart, 7); // crosses March 8
    const newEnd = addDays(originalEnd, 7);
    const newDuration = daysBetween(newStart, newEnd);

    expect(newStart).toBe("2026-03-08");
    expect(newEnd).toBe("2026-03-12");
    expect(newDuration).toBe(originalDuration);
  });
});
