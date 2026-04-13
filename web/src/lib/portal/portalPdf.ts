// Portal PDF export (D-22, D-67)
// Client-side branded PDF generation using jsPDF + html2canvas
// Extends Phase 19 pdf-generator.ts pattern for portal-specific branding

import jsPDF from "jspdf";
import html2canvas from "html2canvas";
import type { CompanyBranding } from "./types";

// ---------- Types ----------

type PortalPdfParams = {
  portalElement: HTMLElement;
  branding: CompanyBranding;
  projectName: string;
  generatedDate: string;
};

type PageDims = {
  width: number;
  height: number;
  margin: number;
  contentWidth: number;
  contentHeight: number;
};

// ---------- Helpers ----------

function getPageDims(): PageDims {
  // Letter paper in inches (default)
  const width = 8.5;
  const height = 11;
  const margin = 0.75;
  return {
    width,
    height,
    margin,
    contentWidth: width - margin * 2,
    contentHeight: height - margin * 2,
  };
}

/** Sanitize text for PDF (strip HTML, limit length) */
function sanitize(text: string, max = 200): string {
  return text.replace(/<[^>]*>/g, "").trim().slice(0, max);
}

// ---------- Cover Page ----------

function drawCoverPage(
  doc: jsPDF,
  dims: PageDims,
  branding: CompanyBranding,
  projectName: string,
  generatedDate: string,
  logoDataUrl?: string,
): void {
  // Brand color accent bar at top
  const brandColor = branding.theme_config.primary || "#2563EB";
  const r = parseInt(brandColor.slice(1, 3), 16);
  const g = parseInt(brandColor.slice(3, 5), 16);
  const b = parseInt(brandColor.slice(5, 7), 16);

  doc.setFillColor(r, g, b);
  doc.rect(0, 0, dims.width, 0.25, "F");

  // Company logo centered (D-67)
  const logoY = 2.5;
  if (logoDataUrl) {
    try {
      doc.addImage(logoDataUrl, "PNG", dims.width / 2 - 1, logoY, 2, 0.6);
    } catch {
      // Logo failed — show company name as fallback
      doc.setFontSize(20);
      doc.setFont("helvetica", "bold");
      doc.setTextColor(r, g, b);
      doc.text(sanitize(branding.company_name), dims.width / 2, logoY + 0.4, {
        align: "center",
      });
    }
  } else {
    // No logo — show company name text
    doc.setFontSize(20);
    doc.setFont("helvetica", "bold");
    doc.setTextColor(r, g, b);
    doc.text(sanitize(branding.company_name), dims.width / 2, logoY + 0.4, {
      align: "center",
    });
  }

  // Project name (large text)
  doc.setFontSize(28);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(30, 30, 30);
  const safeName = sanitize(projectName, 100);
  const nameLines = doc.splitTextToSize(safeName, dims.contentWidth);
  doc.text(nameLines, dims.width / 2, 4.5, { align: "center" });

  // Subtitle
  doc.setFontSize(14);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(100, 100, 100);
  doc.text("Project Progress Report", dims.width / 2, 5.5, {
    align: "center",
  });

  // Generated date
  doc.setFontSize(11);
  doc.setTextColor(140, 140, 140);
  doc.text(`Generated ${generatedDate}`, dims.width / 2, 6.2, {
    align: "center",
  });

  // Company contact info at bottom
  const contact = branding.contact_info;
  if (contact) {
    const lines: string[] = [];
    if (contact.email) lines.push(contact.email);
    if (contact.phone) lines.push(contact.phone);
    if (contact.website) lines.push(contact.website);
    if (contact.address) lines.push(contact.address);

    if (lines.length > 0) {
      doc.setFontSize(9);
      doc.setTextColor(120, 120, 120);
      const startY = dims.height - dims.margin - lines.length * 0.22;
      lines.forEach((line, i) => {
        doc.text(sanitize(line), dims.width / 2, startY + i * 0.22, {
          align: "center",
        });
      });
    }
  }

  // Brand color accent bar at bottom
  doc.setFillColor(r, g, b);
  doc.rect(0, dims.height - 0.15, dims.width, 0.15, "F");
}

// ---------- Page Header / Footer ----------

function drawPageHeader(
  doc: jsPDF,
  dims: PageDims,
  projectName: string,
  logoDataUrl?: string,
): void {
  const y = dims.margin * 0.4;

  // Small company logo top-left (D-67)
  if (logoDataUrl) {
    try {
      doc.addImage(logoDataUrl, "PNG", dims.margin, y * 0.5, 0.8, 0.26);
    } catch {
      // Skip if logo fails
    }
  }

  // Project name top-right
  doc.setFontSize(9);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(100, 100, 100);
  doc.text(
    sanitize(projectName, 60),
    dims.width - dims.margin,
    y + 0.1,
    { align: "right" },
  );

  // Separator line
  const lineY = dims.margin * 0.7;
  doc.setDrawColor(200, 200, 200);
  doc.setLineWidth(0.01);
  doc.line(dims.margin, lineY, dims.width - dims.margin, lineY);
}

function drawPageFooter(
  doc: jsPDF,
  dims: PageDims,
  pageNum: number,
  totalPages: number,
  generatedDate: string,
): void {
  const y = dims.height - dims.margin * 0.3;

  // Page number center
  doc.setFontSize(9);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(140, 140, 140);
  doc.text(`Page ${pageNum} of ${totalPages}`, dims.width / 2, y, {
    align: "center",
  });

  // Generated date right
  doc.setFontSize(8);
  doc.text(generatedDate, dims.width - dims.margin, y, { align: "right" });
}

// ---------- Content Page Splitting ----------

function splitCanvasIntoPages(
  canvas: HTMLCanvasElement,
  contentWidthPx: number,
  contentHeightPx: number,
): HTMLCanvasElement[] {
  const scale = contentWidthPx / canvas.width;
  const pageHeightInCanvasPx = contentHeightPx / scale;
  const pages: HTMLCanvasElement[] = [];
  let yOffset = 0;

  while (yOffset < canvas.height) {
    const sliceHeight = Math.min(pageHeightInCanvasPx, canvas.height - yOffset);
    const sliceCanvas = document.createElement("canvas");
    sliceCanvas.width = canvas.width;
    sliceCanvas.height = sliceHeight;
    const ctx = sliceCanvas.getContext("2d");
    if (ctx) {
      ctx.drawImage(
        canvas,
        0, yOffset, canvas.width, sliceHeight,
        0, 0, canvas.width, sliceHeight,
      );
    }
    pages.push(sliceCanvas);
    yOffset += sliceHeight;
  }

  return pages;
}

// ---------- Main Export ----------

/**
 * Generate a branded portal PDF from the rendered portal DOM.
 * D-22: Full portal PDF with branding.
 * D-42: Full portal PDF only, not per-section.
 * D-67: Cover page with company name, logo, project title.
 *
 * This is a client-side utility — runs in the browser using the portal's
 * rendered DOM via html2canvas + jsPDF.
 */
export async function generatePortalPdf(params: PortalPdfParams): Promise<Blob> {
  const { portalElement, branding, projectName, generatedDate } = params;

  const dims = getPageDims();

  // Try to load company logo as data URL for embedding
  let logoDataUrl: string | undefined;
  if (branding.logo_light_path) {
    try {
      const res = await fetch(branding.logo_light_path);
      if (res.ok) {
        const blob = await res.blob();
        logoDataUrl = await new Promise<string>((resolve) => {
          const reader = new FileReader();
          reader.onload = () => resolve(reader.result as string);
          reader.readAsDataURL(blob);
        });
      }
    } catch {
      // Logo fetch failed — proceed without
    }
  }

  const doc = new jsPDF({
    orientation: "portrait",
    unit: "in",
    format: "letter",
  });

  // --- Page 1: Cover page ---
  drawCoverPage(doc, dims, branding, projectName, generatedDate, logoDataUrl);

  // --- Capture portal DOM sections via html2canvas ---
  const canvas = await html2canvas(portalElement, {
    scale: 2,
    useCORS: true,
    backgroundColor: "#FFFFFF",
  });

  // Calculate pixel dimensions for page splitting
  const pxPerInch = 96;
  const contentWidthPx = dims.contentWidth * pxPerInch * 2; // 2x scale
  const contentHeightPx = (dims.contentHeight - 0.8) * pxPerInch * 2; // reserve header/footer

  const pageSlices = splitCanvasIntoPages(canvas, contentWidthPx, contentHeightPx);
  const totalPages = pageSlices.length + 1; // +1 for cover page

  // Draw footer on cover page now that we know total pages
  drawPageFooter(doc, dims, 1, totalPages, generatedDate);

  // --- Content pages ---
  for (let i = 0; i < pageSlices.length; i++) {
    doc.addPage("letter", "portrait");
    const pageNum = i + 2;
    const slice = pageSlices[i];

    drawPageHeader(doc, dims, projectName, logoDataUrl);

    // Render captured slice
    const imgData = slice.toDataURL("image/png");
    const imgWidth = dims.contentWidth;
    const imgHeight = (slice.height / slice.width) * imgWidth;

    doc.addImage(
      imgData,
      "PNG",
      dims.margin,
      dims.margin,
      imgWidth,
      Math.min(imgHeight, dims.contentHeight - 0.8),
    );

    drawPageFooter(doc, dims, pageNum, totalPages, generatedDate);
  }

  return doc.output("blob");
}
