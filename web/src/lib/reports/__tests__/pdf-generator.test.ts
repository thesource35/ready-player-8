// @vitest-environment jsdom

// Tests for PDF generator — Phase 19 Plan 07
// Mocks jsPDF and html2canvas to validate logic without DOM rendering

import { describe, it, expect, vi, beforeEach } from "vitest";

// ---------- Mock html2canvas ----------

const mockCanvas = {
  width: 800,
  height: 1200,
  toDataURL: vi.fn(() => "data:image/png;base64,FAKE"),
  getContext: vi.fn(() => ({
    drawImage: vi.fn(),
  })),
};

vi.mock("html2canvas", () => ({
  default: vi.fn(() => Promise.resolve(mockCanvas)),
}));

// ---------- Mock jsPDF ----------

// GState must be a real constructor function for `new doc.GState(...)` to work
function MockGState() { return {}; }

const mockDoc = {
  setFontSize: vi.fn(),
  setFont: vi.fn(),
  setTextColor: vi.fn(),
  setDrawColor: vi.fn(),
  setLineWidth: vi.fn(),
  text: vi.fn(),
  textWithLink: vi.fn(),
  line: vi.fn(),
  rect: vi.fn(),
  link: vi.fn(),
  addImage: vi.fn(),
  addPage: vi.fn(),
  output: vi.fn(() => new Blob(["fake-pdf"], { type: "application/pdf" })),
  saveGraphicsState: vi.fn(),
  restoreGraphicsState: vi.fn(),
  setGState: vi.fn(),
  splitTextToSize: vi.fn((text: string) => [text]),
  outline: {
    add: vi.fn(),
  },
  GState: MockGState,
};

// Store constructor args for inspection
let lastConstructorArgs: Record<string, unknown> = {};

// Use a real constructor function so `new jsPDF(...)` works
function MockJsPDF(this: Record<string, unknown>, opts: Record<string, unknown>) {
  lastConstructorArgs = opts || {};
  Object.assign(this, mockDoc);
}
vi.mock("jspdf", () => ({
  default: MockJsPDF,
  __esModule: true,
}));

// ---------- Import after mocks ----------

import {
  generateReportPDF,
  generateRollupPDF,
  detectPaperSize,
  detectOrientation,
  generateFilename,
} from "../pdf-generator";
import html2canvas from "html2canvas";

// ---------- Helpers ----------

function makeElement(): HTMLElement {
  const el = document.createElement("div");
  el.textContent = "Report content";
  return el;
}

// ---------- Tests ----------

describe("pdf-generator", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    lastConstructorArgs = {};
    // Reset createElement to support canvas creation in splitCanvasIntoPages
    vi.spyOn(document, "createElement").mockImplementation((tag: string) => {
      if (tag === "canvas") {
        return {
          width: 0,
          height: 0,
          getContext: vi.fn(() => ({ drawImage: vi.fn() })),
          toDataURL: vi.fn(() => "data:image/png;base64,SLICE"),
        } as unknown as HTMLCanvasElement;
      }
      return document.createElementNS("http://www.w3.org/1999/xhtml", tag) as HTMLElement;
    });
  });

  describe("detectPaperSize", () => {
    it("returns letter or a4 based on locale", () => {
      const result = detectPaperSize();
      expect(["letter", "a4"]).toContain(result);
    });
  });

  describe("detectOrientation", () => {
    it("returns landscape for rollup", () => {
      expect(detectOrientation(true)).toBe("landscape");
    });

    it("returns portrait for single project", () => {
      expect(detectOrientation(false)).toBe("portrait");
    });
  });

  describe("generateFilename", () => {
    it("matches pattern {ProjectName}-Report-{YYYY-MM-DD}.pdf", () => {
      const name = generateFilename("My Project 123");
      expect(name).toMatch(/^My-Project-123-Report-\d{4}-\d{2}-\d{2}\.pdf$/);
    });

    it("strips special characters from project name", () => {
      const name = generateFilename("Test/Project@#$%");
      expect(name).toMatch(/^TestProject-Report-\d{4}-\d{2}-\d{2}\.pdf$/);
    });
  });

  describe("generateReportPDF", () => {
    it("produces a Blob", async () => {
      const blob = await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Test Project",
      });
      expect(blob).toBeInstanceOf(Blob);
    });

    it("calls html2canvas with white background and scale 2", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Test",
      });
      expect(html2canvas).toHaveBeenCalledWith(
        expect.any(HTMLElement),
        expect.objectContaining({
          scale: 2,
          useCORS: true,
          backgroundColor: "#ffffff",
        }),
      );
    });

    it("creates jsPDF with correct orientation and format", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Test",
        paperSize: "a4",
        landscape: true,
      });
      expect(lastConstructorArgs).toEqual(
        expect.objectContaining({
          orientation: "landscape",
          unit: "in",
          format: "a4",
        }),
      );
    });

    it("applies DRAFT watermark when isDraft is true", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Draft Report",
        isDraft: true,
      });
      // DRAFT watermark calls text with "DRAFT" and angle 45
      const draftCalls = mockDoc.text.mock.calls.filter(
        (call: unknown[]) => call[0] === "DRAFT",
      );
      expect(draftCalls.length).toBeGreaterThan(0);
      expect(draftCalls[0][3]).toEqual(
        expect.objectContaining({ angle: 45 }),
      );
    });

    it("does not apply DRAFT watermark when isDraft is false", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Final Report",
        isDraft: false,
      });
      const draftCalls = mockDoc.text.mock.calls.filter(
        (call: unknown[]) => call[0] === "DRAFT",
      );
      expect(draftCalls.length).toBe(0);
    });

    it("includes confidentiality footer when confidential is true", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Confidential Report",
        confidential: true,
        companyName: "Acme Corp",
      });
      const confCalls = mockDoc.text.mock.calls.filter(
        (call: unknown[]) =>
          typeof call[0] === "string" && call[0].includes("Confidential"),
      );
      expect(confCalls.length).toBeGreaterThan(0);
    });

    it("passes password to jsPDF encryption per D-34h", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Secure Report",
        password: "secret123",
      });
      expect(lastConstructorArgs).toEqual(
        expect.objectContaining({
          encryption: expect.objectContaining({
            userPassword: "secret123",
            ownerPassword: "secret123",
          }),
        }),
      );
    });

    it("does not add encryption when no password provided", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Open Report",
      });
      expect(lastConstructorArgs.encryption).toBeUndefined();
    });

    it("renders executive summary when provided per D-34g", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Summary Report",
        executiveSummary: "This project is on track.",
      });
      const summaryCalls = mockDoc.text.mock.calls.filter(
        (call: unknown[]) => call[0] === "Executive Summary",
      );
      expect(summaryCalls.length).toBe(1);
    });

    it("adds QR code area when reportUrl provided per D-34i", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "QR Report",
        reportUrl: "https://example.com/reports/123",
      });
      expect(mockDoc.link).toHaveBeenCalledWith(
        expect.any(Number),
        expect.any(Number),
        expect.any(Number),
        expect.any(Number),
        { url: "https://example.com/reports/123" },
      );
    });

    it("draws header with project name on each page", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Header Test",
      });
      const headerCalls = mockDoc.text.mock.calls.filter(
        (call: unknown[]) => call[0] === "Header Test",
      );
      expect(headerCalls.length).toBeGreaterThanOrEqual(1);
    });

    it("draws page numbers in footer", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Footer Test",
      });
      const pageCalls = mockDoc.text.mock.calls.filter(
        (call: unknown[]) =>
          typeof call[0] === "string" && call[0].startsWith("Page "),
      );
      expect(pageCalls.length).toBeGreaterThanOrEqual(1);
    });

    it("outputs blob via doc.output('blob')", async () => {
      await generateReportPDF({
        reportElement: makeElement(),
        projectName: "Blob Test",
      });
      expect(mockDoc.output).toHaveBeenCalledWith("blob");
    });
  });

  describe("generateRollupPDF", () => {
    it("calls generateReportPDF with landscape true", async () => {
      const blob = await generateRollupPDF({
        reportElement: makeElement(),
        projectName: "Portfolio Rollup",
      });
      expect(blob).toBeInstanceOf(Blob);
      expect(lastConstructorArgs).toEqual(
        expect.objectContaining({
          orientation: "landscape",
        }),
      );
    });
  });
});
