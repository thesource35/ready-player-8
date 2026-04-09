import { describe, it, expect } from "vitest";
import { deriveMilestones } from "../derive-milestones";
import { isIsoDate, parseDateOnly, daysBetween, addDays } from "../dates";

describe("dates helpers", () => {
  it("isIsoDate matches YYYY-MM-DD only", () => {
    expect(isIsoDate("2026-04-08")).toBe(true);
    expect(isIsoDate("2026-4-8")).toBe(false);
    expect(isIsoDate("2026-04-08T00:00:00Z")).toBe(false);
    expect(isIsoDate("")).toBe(false);
    expect(isIsoDate(null as unknown as string)).toBe(false);
  });

  it("parseDateOnly is local-time (no UTC drift)", () => {
    const d = parseDateOnly("2026-04-08");
    expect(d.getFullYear()).toBe(2026);
    expect(d.getMonth()).toBe(3);
    expect(d.getDate()).toBe(8);
  });

  it("daysBetween + addDays are inclusive and reversible", () => {
    expect(daysBetween("2026-04-08", "2026-04-08")).toBe(0);
    expect(daysBetween("2026-04-08", "2026-04-11")).toBe(3);
    expect(addDays("2026-04-08", 3)).toBe("2026-04-11");
    expect(addDays("2026-04-11", -3)).toBe("2026-04-08");
  });
});

describe("deriveMilestones", () => {
  it("merges projects, contracts, inspection events into one flat list", () => {
    const result = deriveMilestones({
      projects: [
        { id: "p1", name: "Tower A", start_date: "2026-04-01", end_date: "2026-12-31" },
        { id: "p2", name: "Tower B", start_date: null, end_date: "2026-11-30" },
      ],
      contracts: [
        { id: "c1", project_id: "p1", bid_due_date: "2026-03-15" },
        { id: "c2", project_id: "p1", bid_due_date: null },
      ],
      events: [
        { id: "e1", project_id: "p1", event_type: "inspection", date: "2026-06-10", title: "Framing Insp." },
        { id: "e2", project_id: "p1", event_type: "meeting", date: "2026-06-11" },
      ],
    });

    const types = result.map((m) => m.type).sort();
    expect(types).toEqual(["bid_due", "end", "end", "inspection", "start"]);

    const insp = result.find((m) => m.type === "inspection");
    expect(insp?.label).toBe("Framing Insp.");
    expect(insp?.project_id).toBe("p1");
  });

  it("returns empty array for empty input", () => {
    expect(deriveMilestones({ projects: [], contracts: [], events: [] })).toEqual([]);
  });
});
