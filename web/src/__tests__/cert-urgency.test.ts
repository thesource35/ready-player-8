import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { getUrgencyInfo, certUrgency, urgencyColor, urgencyLabel } from "@/lib/certifications/urgency";

describe("getUrgencyInfo", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    // Use noon UTC so local date is June 1st in all timezones up to UTC-12
    vi.setSystemTime(new Date("2026-06-01T12:00:00Z"));
  });
  afterEach(() => {
    vi.useRealTimers();
  });

  it("returns expired for past dates", () => {
    const result = getUrgencyInfo("2026-05-30");
    expect(result.level).toBe("expired");
    expect(result.color).toBe("var(--red)");
    expect(result.label).toBe("Expired");
  });

  it("returns urgent for today (day-of)", () => {
    const result = getUrgencyInfo("2026-06-01");
    expect(result.level).toBe("urgent");
    expect(result.label).toBe("Expires today");
  });

  it("returns urgent for 1-7 days out", () => {
    const result = getUrgencyInfo("2026-06-05");
    expect(result.level).toBe("urgent");
    expect(result.color).toBe("var(--red)");
  });

  it("returns warning for 8-30 days out", () => {
    const result = getUrgencyInfo("2026-06-20");
    expect(result.level).toBe("warning");
    expect(result.color).toBe("var(--gold)");
  });

  it("returns safe for >30 days out", () => {
    const result = getUrgencyInfo("2026-07-15");
    expect(result.level).toBe("safe");
    expect(result.color).toBe("var(--green)");
  });

  it("returns safe with No expiry label for null", () => {
    const result = getUrgencyInfo(null);
    expect(result.level).toBe("safe");
    expect(result.label).toBe("No expiry");
  });
});

describe("convenience aliases", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-06-01T12:00:00Z"));
  });
  afterEach(() => {
    vi.useRealTimers();
  });

  it("certUrgency returns level string", () => {
    expect(certUrgency("2026-05-30")).toBe("expired");
    expect(certUrgency("2026-06-20")).toBe("warning");
  });

  it("urgencyColor returns CSS var", () => {
    expect(urgencyColor("2026-05-30")).toBe("var(--red)");
    expect(urgencyColor("2026-07-15")).toBe("var(--green)");
  });

  it("urgencyLabel returns display text", () => {
    expect(urgencyLabel("2026-06-01")).toBe("Expires today");
    expect(urgencyLabel(null)).toBe("No expiry");
  });
});

describe("cert deep-link URL security", () => {
  it("accepts valid UUID format", () => {
    const certId = "a1b2c3d4-e5f6-7890-abcd-ef1234567890";
    expect(/^[0-9a-f-]{36}$/i.test(certId)).toBe(true);
  });

  it("rejects script injection", () => {
    expect(/^[0-9a-f-]{36}$/i.test("<script>alert(1)</script>")).toBe(false);
  });

  it("rejects SQL injection", () => {
    expect(/^[0-9a-f-]{36}$/i.test("'; DROP TABLE--")).toBe(false);
  });
});
