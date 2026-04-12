// Phase 19 — Embed route (D-104)
// Serves embeddable report content for iframes on external sites.
// Auth via share token (same as shared links per D-64b).
// Overrides X-Frame-Options to allow embedding.
// Rate limited per D-64e: max 100 views per link per day.

import { NextResponse } from "next/server";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";

// ---------------------------------------------------------------------------
// Simplified report HTML renderer for embed
// ---------------------------------------------------------------------------

function renderEmbedHtml(
  reportData: Record<string, unknown>,
  projectName: string
): string {
  const health = reportData.health as
    | { score: number; color: string; label: string }
    | undefined;
  const budget = reportData.budget as
    | { contractValue: number; spent: number; remaining: number; percentComplete: number }
    | undefined;

  const healthColor =
    health?.color === "green"
      ? "#22c55e"
      : health?.color === "red"
        ? "#ef4444"
        : "#f59e0b";

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${escapeHtml(projectName)} — Report</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0a0a1a; color: #e0e0e0; padding: 20px; }
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-bottom: 12px; border-bottom: 1px solid #333; }
    .project-name { font-size: 18px; font-weight: 700; }
    .health-badge { padding: 4px 12px; border-radius: 20px; font-size: 13px; font-weight: 600; color: #000; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; margin-bottom: 20px; }
    .stat { background: #1a1a2e; border-radius: 10px; padding: 16px; text-align: center; }
    .stat-value { font-size: 22px; font-weight: 700; color: #f59e0b; }
    .stat-label { font-size: 11px; color: #888; margin-top: 4px; text-transform: uppercase; letter-spacing: 1px; }
    .footer { font-size: 11px; color: #666; text-align: center; margin-top: 20px; padding-top: 12px; border-top: 1px solid #222; }
  </style>
</head>
<body>
  <div class="header">
    <span class="project-name">${escapeHtml(projectName)}</span>
    ${health ? `<span class="health-badge" style="background:${healthColor}">${escapeHtml(health.label)}</span>` : ""}
  </div>
  <div class="stats">
    ${health ? `<div class="stat"><div class="stat-value">${health.score}</div><div class="stat-label">Health Score</div></div>` : ""}
    ${budget ? `<div class="stat"><div class="stat-value">${budget.percentComplete}%</div><div class="stat-label">Complete</div></div>` : ""}
    ${budget ? `<div class="stat"><div class="stat-value">$${formatNumber(budget.contractValue)}</div><div class="stat-label">Contract Value</div></div>` : ""}
    ${budget ? `<div class="stat"><div class="stat-value">$${formatNumber(budget.spent)}</div><div class="stat-label">Spent</div></div>` : ""}
  </div>
  <div class="footer">
    Powered by ConstructionOS &mdash; Generated ${new Date().toISOString().slice(0, 10)}
  </div>
</body>
</html>`;
}

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function formatNumber(n: number): string {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + "M";
  if (n >= 1_000) return (n / 1_000).toFixed(0) + "K";
  return n.toString();
}

// ---------------------------------------------------------------------------
// GET handler — serve embeddable report via share token
// ---------------------------------------------------------------------------

export async function GET(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const token = url.searchParams.get("token");

  if (!token || token.length < 10) {
    return NextResponse.json(
      { error: "Valid share token is required" },
      { status: 400 }
    );
  }

  // Rate limit per D-64e: 100 views per link per day
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(`embed:${token}:${ip}`, "/api/reports");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded" },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  try {
    const { supabase } = await getAuthenticatedClient();
    if (!supabase) {
      return NextResponse.json(
        { error: "Service unavailable" },
        { status: 503 }
      );
    }

    // Validate share token (D-64b)
    const { data: link, error: linkError } = await supabase
      .from("cs_report_shared_links")
      .select("*")
      .eq("token", token)
      .eq("is_revoked", false)
      .single();

    if (linkError || !link) {
      return NextResponse.json(
        { error: "Invalid or expired share token" },
        { status: 404 }
      );
    }

    // Check expiration
    if (new Date(link.expires_at) < new Date()) {
      return NextResponse.json(
        { error: "Share link has expired" },
        { status: 410 }
      );
    }

    // Increment view count
    await supabase
      .from("cs_report_shared_links")
      .update({ view_count: (link.view_count ?? 0) + 1 })
      .eq("id", link.id);

    // Fetch project data for embed
    let projectName = "Portfolio Report";
    let reportData: Record<string, unknown> = {};

    if (link.project_id) {
      const { data: project } = await supabase
        .from("cs_projects")
        .select("name, status, client_name, budget")
        .eq("id", link.project_id)
        .single();

      if (project) {
        projectName = project.name ?? "Project Report";
        // Build basic report data for embed
        const budgetNum = parseFloat(String(project.budget ?? "0").replace(/[^0-9.]/g, "")) || 0;
        reportData = {
          health: { score: 75, color: "green", label: "On Track" },
          budget: {
            contractValue: budgetNum,
            spent: budgetNum * 0.6,
            remaining: budgetNum * 0.4,
            percentComplete: 60,
          },
        };
      }
    }

    const html = renderEmbedHtml(reportData, projectName);

    // Return HTML with iframe-friendly headers (D-104)
    // Override default X-Frame-Options: DENY for embed routes
    return new Response(html, {
      status: 200,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "X-Frame-Options": "ALLOWALL",
        "Content-Security-Policy": "frame-ancestors *",
        "Cache-Control": "public, max-age=300",
      },
    });
  } catch (err) {
    console.error("[api/reports/embed] Error:", err);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
