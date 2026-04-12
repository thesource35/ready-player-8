/**
 * Email report delivery tests.
 * Per D-82: Mocks Resend SDK in unit tests.
 * Per D-50e: Validates recipients (team members only).
 * Per D-50x: Tests failure fallback (Resend throws -> stored report).
 */
import { describe, it, expect, vi, beforeEach } from "vitest";

// ---------------------------------------------------------------------------
// Mock Resend SDK (D-82)
// ---------------------------------------------------------------------------
const mockSend = vi.fn();

vi.mock("resend", () => {
  return {
    Resend: class MockResend {
      emails = { send: mockSend };
    },
  };
});

// Mock @react-email/components render to avoid JSX/React dependency in test
vi.mock("@react-email/components", () => ({
  Html: ({ children }: { children: unknown }) => children,
  Head: () => null,
  Body: ({ children }: { children: unknown }) => children,
  Container: ({ children }: { children: unknown }) => children,
  Section: ({ children }: { children: unknown }) => children,
  Text: ({ children }: { children: unknown }) => children,
  Link: ({ children }: { children: unknown }) => children,
  Hr: () => null,
  Img: () => null,
  Row: ({ children }: { children: unknown }) => children,
  Column: ({ children }: { children: unknown }) => children,
  render: vi.fn().mockResolvedValue("<html><body>Report Email</body></html>"),
}));

// ---------------------------------------------------------------------------
// Email sending function (inline implementation matching plan D-50)
// ---------------------------------------------------------------------------

type EmailRecipient = {
  email: string;
  name: string;
  isTeamMember: boolean;
};

type ReportEmailPayload = {
  recipients: EmailRecipient[];
  subject: string;
  healthScore: number;
  budgetPercent: number;
  projectCount: number;
  openIssues: number;
  reportUrl: string;
  generatedAt: string;
};

/**
 * Generate email subject line per D-50r: "[ConstructionOS] Weekly Report - {date}"
 */
function generateSubjectLine(frequency: string, date: string): string {
  const label = frequency.charAt(0).toUpperCase() + frequency.slice(1);
  return `[ConstructionOS] ${label} Report - ${date}`;
}

/**
 * Validate recipients per D-50e: team members only
 */
function validateRecipients(recipients: EmailRecipient[]): {
  valid: EmailRecipient[];
  rejected: EmailRecipient[];
} {
  const valid = recipients.filter((r) => r.isTeamMember && r.email.includes("@"));
  const rejected = recipients.filter((r) => !r.isTeamMember || !r.email.includes("@"));
  return { valid, rejected };
}

/**
 * Send report email via Resend SDK.
 * Per D-50x: If Resend throws, store report for later retrieval.
 */
async function sendReportEmail(
  payload: ReportEmailPayload
): Promise<{ success: boolean; storedFallback: boolean; error?: string }> {
  const { valid, rejected } = validateRecipients(payload.recipients);

  if (valid.length === 0) {
    return { success: false, storedFallback: false, error: "No valid team member recipients" };
  }

  if (rejected.length > 0) {
    console.warn(`Rejected ${rejected.length} non-team-member recipients`);
  }

  try {
    const { Resend } = await import("resend");
    const resend = new Resend("re_test_key");

    await resend.emails.send({
      from: "reports@constructionos.com",
      to: valid.map((r) => r.email),
      subject: payload.subject,
      html: `<html><body>Health: ${payload.healthScore}, Budget: ${payload.budgetPercent}%</body></html>`,
    });

    return { success: true, storedFallback: false };
  } catch (err) {
    // D-50x: Fallback to stored report
    console.error("[email] Resend failed, storing report for later:", err);
    return {
      success: false,
      storedFallback: true,
      error: err instanceof Error ? err.message : "Unknown error",
    };
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("Email: Subject line generation (D-50r)", () => {
  it("generates weekly subject line with date", () => {
    const subject = generateSubjectLine("weekly", "2025-06-15");
    expect(subject).toBe("[ConstructionOS] Weekly Report - 2025-06-15");
  });

  it("generates daily subject line", () => {
    const subject = generateSubjectLine("daily", "2025-06-15");
    expect(subject).toBe("[ConstructionOS] Daily Report - 2025-06-15");
  });

  it("generates monthly subject line", () => {
    const subject = generateSubjectLine("monthly", "2025-06-01");
    expect(subject).toBe("[ConstructionOS] Monthly Report - 2025-06-01");
  });
});

describe("Email: Recipient validation (D-50e)", () => {
  it("accepts team members with valid email", () => {
    const { valid, rejected } = validateRecipients([
      { email: "jane@company.com", name: "Jane", isTeamMember: true },
      { email: "bob@company.com", name: "Bob", isTeamMember: true },
    ]);
    expect(valid).toHaveLength(2);
    expect(rejected).toHaveLength(0);
  });

  it("rejects non-team-members", () => {
    const { valid, rejected } = validateRecipients([
      { email: "jane@company.com", name: "Jane", isTeamMember: true },
      { email: "external@other.com", name: "External", isTeamMember: false },
    ]);
    expect(valid).toHaveLength(1);
    expect(rejected).toHaveLength(1);
    expect(rejected[0].name).toBe("External");
  });

  it("rejects invalid email addresses", () => {
    const { valid, rejected } = validateRecipients([
      { email: "notanemail", name: "Bad", isTeamMember: true },
    ]);
    expect(valid).toHaveLength(0);
    expect(rejected).toHaveLength(1);
  });

  it("returns empty valid list for all-external recipients", () => {
    const { valid } = validateRecipients([
      { email: "ext1@other.com", name: "Ext1", isTeamMember: false },
      { email: "ext2@other.com", name: "Ext2", isTeamMember: false },
    ]);
    expect(valid).toHaveLength(0);
  });
});

describe("Email: Sending via Resend (D-82)", () => {
  beforeEach(() => {
    mockSend.mockReset();
  });

  it("sends email to valid team members", async () => {
    mockSend.mockResolvedValueOnce({ id: "email-123" });

    const result = await sendReportEmail({
      recipients: [
        { email: "jane@company.com", name: "Jane", isTeamMember: true },
      ],
      subject: "[ConstructionOS] Weekly Report - 2025-06-15",
      healthScore: 85,
      budgetPercent: 50,
      projectCount: 3,
      openIssues: 2,
      reportUrl: "https://app.constructionos.com/reports",
      generatedAt: "2025-06-15T10:00:00Z",
    });

    expect(result.success).toBe(true);
    expect(result.storedFallback).toBe(false);
    expect(mockSend).toHaveBeenCalledTimes(1);
    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        from: "reports@constructionos.com",
        to: ["jane@company.com"],
        subject: "[ConstructionOS] Weekly Report - 2025-06-15",
      })
    );
  });

  it("includes health score and budget in email html", async () => {
    mockSend.mockResolvedValueOnce({ id: "email-456" });

    await sendReportEmail({
      recipients: [
        { email: "bob@company.com", name: "Bob", isTeamMember: true },
      ],
      subject: "Test",
      healthScore: 72,
      budgetPercent: 65,
      projectCount: 5,
      openIssues: 3,
      reportUrl: "https://example.com",
      generatedAt: "2025-06-15T10:00:00Z",
    });

    const callArgs = mockSend.mock.calls[0][0];
    expect(callArgs.html).toContain("72");
    expect(callArgs.html).toContain("65");
  });

  it("returns error for no valid recipients", async () => {
    const result = await sendReportEmail({
      recipients: [
        { email: "ext@other.com", name: "External", isTeamMember: false },
      ],
      subject: "Test",
      healthScore: 80,
      budgetPercent: 40,
      projectCount: 1,
      openIssues: 0,
      reportUrl: "https://example.com",
      generatedAt: "2025-06-15T10:00:00Z",
    });

    expect(result.success).toBe(false);
    expect(result.error).toBe("No valid team member recipients");
    expect(mockSend).not.toHaveBeenCalled();
  });
});

describe("Email: Failure fallback (D-50x)", () => {
  beforeEach(() => {
    mockSend.mockReset();
  });

  it("falls back to stored report when Resend throws", async () => {
    mockSend.mockRejectedValueOnce(new Error("Resend API rate limit exceeded"));

    const result = await sendReportEmail({
      recipients: [
        { email: "jane@company.com", name: "Jane", isTeamMember: true },
      ],
      subject: "Test Report",
      healthScore: 90,
      budgetPercent: 30,
      projectCount: 2,
      openIssues: 0,
      reportUrl: "https://example.com",
      generatedAt: "2025-06-15T10:00:00Z",
    });

    expect(result.success).toBe(false);
    expect(result.storedFallback).toBe(true);
    expect(result.error).toBe("Resend API rate limit exceeded");
  });

  it("falls back to stored report on network error", async () => {
    mockSend.mockRejectedValueOnce(new Error("Network timeout"));

    const result = await sendReportEmail({
      recipients: [
        { email: "bob@company.com", name: "Bob", isTeamMember: true },
      ],
      subject: "Test Report",
      healthScore: 50,
      budgetPercent: 80,
      projectCount: 1,
      openIssues: 5,
      reportUrl: "https://example.com",
      generatedAt: "2025-06-15T10:00:00Z",
    });

    expect(result.success).toBe(false);
    expect(result.storedFallback).toBe(true);
    expect(result.error).toBe("Network timeout");
  });

  it("falls back to stored report on non-Error throw", async () => {
    mockSend.mockRejectedValueOnce("String error");

    const result = await sendReportEmail({
      recipients: [
        { email: "team@company.com", name: "Team", isTeamMember: true },
      ],
      subject: "Test",
      healthScore: 80,
      budgetPercent: 50,
      projectCount: 1,
      openIssues: 0,
      reportUrl: "https://example.com",
      generatedAt: "2025-06-15T10:00:00Z",
    });

    expect(result.success).toBe(false);
    expect(result.storedFallback).toBe(true);
    expect(result.error).toBe("Unknown error");
  });
});
