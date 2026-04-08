import { describe, it, expect } from "vitest";
import {
  memberSchema,
  assignmentSchema,
  certSchema,
  dailyCrewSchema,
} from "@/lib/team/schemas";

const UUID_A = "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d";
const UUID_B = "f1e2d3c4-b5a6-4978-8b6c-5d4e3f2a1b0c";

describe("TEAM-01: team member schema", () => {
  it("rejects empty name", () => {
    const r = memberSchema.safeParse({ kind: "internal", name: "" });
    expect(r.success).toBe(false);
  });

  it("rejects whitespace-only name after trim", () => {
    const r = memberSchema.safeParse({ kind: "internal", name: "   " });
    expect(r.success).toBe(false);
  });

  it("rejects invalid kind", () => {
    const r = memberSchema.safeParse({ kind: "ghost", name: "Jane" });
    expect(r.success).toBe(false);
  });

  it("accepts a valid internal member with trade/role", () => {
    const r = memberSchema.safeParse({
      kind: "internal",
      name: "Jane Foreman",
      role: "Superintendent",
      trade: "Concrete",
    });
    expect(r.success).toBe(true);
  });

  it("accepts a subcontractor with company and email", () => {
    const r = memberSchema.safeParse({
      kind: "subcontractor",
      name: "Acme Electric",
      company: "Acme LLC",
      email: "ops@acme.example",
    });
    expect(r.success).toBe(true);
  });

  it("rejects malformed email", () => {
    const r = memberSchema.safeParse({
      kind: "vendor",
      name: "Bad Email Co",
      email: "not-an-email",
    });
    expect(r.success).toBe(false);
  });
});

describe("TEAM-02: project assignment schema", () => {
  it("requires uuid project_id", () => {
    const r = assignmentSchema.safeParse({
      project_id: "not-a-uuid",
      member_id: UUID_A,
    });
    expect(r.success).toBe(false);
  });

  it("requires uuid member_id", () => {
    const r = assignmentSchema.safeParse({
      project_id: UUID_A,
      member_id: "bogus",
    });
    expect(r.success).toBe(false);
  });

  it("accepts minimal valid assignment and defaults status to active", () => {
    const r = assignmentSchema.safeParse({
      project_id: UUID_A,
      member_id: UUID_B,
    });
    expect(r.success).toBe(true);
    if (r.success) expect(r.data.status).toBe("active");
  });

  it("rejects invalid status enum", () => {
    const r = assignmentSchema.safeParse({
      project_id: UUID_A,
      member_id: UUID_B,
      status: "archived",
    });
    expect(r.success).toBe(false);
  });

  it("rejects malformed start_date", () => {
    const r = assignmentSchema.safeParse({
      project_id: UUID_A,
      member_id: UUID_B,
      start_date: "2026/01/02",
    });
    expect(r.success).toBe(false);
  });
});

describe("TEAM-03: certification schema", () => {
  it("rejects bad expires_at date format", () => {
    const r = certSchema.safeParse({
      member_id: UUID_A,
      name: "OSHA 30",
      expires_at: "5/8/2026",
    });
    expect(r.success).toBe(false);
  });

  it("accepts optional document_id uuid (FK to cs_documents)", () => {
    const r = certSchema.safeParse({
      member_id: UUID_A,
      name: "OSHA 30",
      expires_at: "2026-05-08",
      document_id: UUID_B,
    });
    expect(r.success).toBe(true);
  });

  it("rejects non-uuid document_id", () => {
    const r = certSchema.safeParse({
      member_id: UUID_A,
      name: "OSHA 30",
      document_id: "not-a-uuid",
    });
    expect(r.success).toBe(false);
  });

  it("accepts cert without document_id (optional FK)", () => {
    const r = certSchema.safeParse({
      member_id: UUID_A,
      name: "First Aid/CPR",
    });
    expect(r.success).toBe(true);
  });

  it("rejects empty cert name", () => {
    const r = certSchema.safeParse({ member_id: UUID_A, name: "" });
    expect(r.success).toBe(false);
  });
});

describe("TEAM-05: daily crew schema", () => {
  it("requires assignment_date in YYYY-MM-DD", () => {
    const r = dailyCrewSchema.safeParse({
      assignment_date: "2026/04/08",
      member_ids: [],
    });
    expect(r.success).toBe(false);
  });

  it("defaults member_ids to []", () => {
    const r = dailyCrewSchema.safeParse({ assignment_date: "2026-04-08" });
    expect(r.success).toBe(true);
    if (r.success) expect(r.data.member_ids).toEqual([]);
  });

  it("accepts valid payload with member uuids and notes", () => {
    const r = dailyCrewSchema.safeParse({
      assignment_date: "2026-04-08",
      member_ids: [UUID_A, UUID_B],
      notes: "Pour deck 3",
    });
    expect(r.success).toBe(true);
  });

  it("rejects non-uuid member id", () => {
    const r = dailyCrewSchema.safeParse({
      assignment_date: "2026-04-08",
      member_ids: ["not-a-uuid"],
    });
    expect(r.success).toBe(false);
  });
});
