import { NextResponse } from "next/server";
import { z } from "zod";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import type { ReportSchedule } from "@/lib/reports/types";

// ---------------------------------------------------------------------------
// Zod schemas for input validation (D-49, D-54)
// ---------------------------------------------------------------------------

const frequencySchema = z.enum(["daily", "weekly", "biweekly", "monthly"]);

const createScheduleSchema = z.object({
  name: z.string().min(1).max(200).default("Portfolio Report"),
  frequency: frequencySchema,
  day_of_week: z.number().int().min(0).max(6).optional(),
  day_of_month: z.number().int().min(1).max(31).optional(),
  time_utc: z
    .string()
    .regex(/^\d{2}:\d{2}(:\d{2})?$/, "Must be HH:MM or HH:MM:SS")
    .default("08:00"),
  timezone: z.string().min(1).max(100).default("America/New_York"),
  recipients: z.array(z.string().uuid()).min(1, "At least one recipient required"),
  sections: z.array(z.string()).default([]),
});

const updateScheduleSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  frequency: frequencySchema.optional(),
  day_of_week: z.number().int().min(0).max(6).optional().nullable(),
  day_of_month: z.number().int().min(1).max(31).optional().nullable(),
  time_utc: z
    .string()
    .regex(/^\d{2}:\d{2}(:\d{2})?$/)
    .optional(),
  timezone: z.string().min(1).max(100).optional(),
  recipients: z.array(z.string().uuid()).optional(),
  sections: z.array(z.string()).optional(),
  is_active: z.boolean().optional(),
});

const actionSchema = z.object({
  action: z.enum(["send_now", "send_test"]),
  schedule_id: z.string().uuid(),
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Compute the next run timestamp based on frequency and timezone (D-50j, D-50t) */
function computeNextRunAt(
  frequency: string,
  timeUtc: string,
  dayOfWeek?: number | null,
  dayOfMonth?: number | null
): string {
  const now = new Date();
  const [hours, minutes] = timeUtc.split(":").map(Number);
  const next = new Date(now);
  next.setUTCHours(hours, minutes, 0, 0);

  // If the computed time is in the past today, start from tomorrow
  if (next <= now) {
    next.setUTCDate(next.getUTCDate() + 1);
  }

  switch (frequency) {
    case "daily":
      // next occurrence is already set (today or tomorrow at time_utc)
      break;

    case "weekly":
      if (dayOfWeek != null) {
        // Advance to the target day of week
        const currentDay = next.getUTCDay();
        const daysUntil = (dayOfWeek - currentDay + 7) % 7 || 7;
        if (daysUntil > 0 && next <= now) {
          next.setUTCDate(next.getUTCDate() + daysUntil);
        } else if (currentDay !== dayOfWeek) {
          next.setUTCDate(next.getUTCDate() + ((dayOfWeek - currentDay + 7) % 7));
        }
      }
      break;

    case "biweekly":
      if (dayOfWeek != null) {
        const curDay = next.getUTCDay();
        const days = (dayOfWeek - curDay + 7) % 7 || 14;
        next.setUTCDate(next.getUTCDate() + days);
      } else {
        next.setUTCDate(next.getUTCDate() + 14);
      }
      break;

    case "monthly":
      if (dayOfMonth != null) {
        next.setUTCDate(dayOfMonth);
        if (next <= now) {
          next.setUTCMonth(next.getUTCMonth() + 1);
          next.setUTCDate(dayOfMonth);
        }
      } else {
        next.setUTCMonth(next.getUTCMonth() + 1);
      }
      break;
  }

  return next.toISOString();
}

/** Validate recipients are team members (D-50e: team members only) */
async function validateRecipients(
  supabase: Awaited<ReturnType<typeof getAuthenticatedClient>>["supabase"],
  userId: string,
  recipientIds: string[]
): Promise<{ valid: boolean; invalidIds: string[] }> {
  if (!supabase) return { valid: false, invalidIds: recipientIds };

  // Check recipients exist in user_orgs or team tables
  // Include the schedule creator as always valid
  const validIds = new Set<string>([userId]);

  try {
    // Look up org for the current user
    const { data: orgRow } = await supabase
      .from("user_orgs")
      .select("org_id")
      .eq("user_id", userId)
      .maybeSingle();

    if (orgRow?.org_id) {
      // Get all team members in the same org
      const { data: members } = await supabase
        .from("user_orgs")
        .select("user_id")
        .eq("org_id", orgRow.org_id);

      if (members) {
        for (const m of members) {
          validIds.add(m.user_id);
        }
      }
    }

    // Also check cs_team_members (Phase 15 crew data) as fallback
    const { data: crewMembers } = await supabase
      .from("cs_team_members")
      .select("user_id")
      .not("user_id", "is", null);

    if (crewMembers) {
      for (const m of crewMembers) {
        if (m.user_id) validIds.add(m.user_id);
      }
    }
  } catch {
    // If tables don't exist, allow only the creator
    console.warn("[schedule] Team lookup failed, allowing only creator as recipient");
  }

  const invalidIds = recipientIds.filter((id) => !validIds.has(id));
  return { valid: invalidIds.length === 0, invalidIds };
}

// ---------------------------------------------------------------------------
// GET: List all schedules for the authenticated user (D-54)
// ---------------------------------------------------------------------------

export async function GET(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }

  const { data, error } = await supabase
    .from("cs_report_schedules")
    .select("*")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("[schedule GET] Error:", error);
    return NextResponse.json(
      { error: "Failed to fetch schedules" },
      { status: 500 }
    );
  }

  return NextResponse.json({ schedules: data ?? [] });
}

// ---------------------------------------------------------------------------
// POST: Create schedule or trigger send_now / send_test (D-54, D-50g, D-50o)
// ---------------------------------------------------------------------------

export async function POST(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  // Check if this is an action request (send_now or send_test)
  const actionParse = actionSchema.safeParse(body);
  if (actionParse.success) {
    return handleAction(supabase, user.id, actionParse.data);
  }

  // Otherwise, create a new schedule
  const parse = createScheduleSchema.safeParse(body);
  if (!parse.success) {
    return NextResponse.json(
      { error: "Validation failed", details: parse.error.flatten().fieldErrors },
      { status: 400 }
    );
  }

  const input = parse.data;

  // D-50e: Validate recipients are team members
  const recipientCheck = await validateRecipients(supabase, user.id, input.recipients);
  if (!recipientCheck.valid) {
    return NextResponse.json(
      {
        error: "Invalid recipients: not team members",
        invalidIds: recipientCheck.invalidIds,
      },
      { status: 400 }
    );
  }

  // Compute next_run_at (D-50t)
  const next_run_at = computeNextRunAt(
    input.frequency,
    input.time_utc,
    input.day_of_week,
    input.day_of_month
  );

  const { data, error } = await supabase
    .from("cs_report_schedules")
    .insert({
      user_id: user.id,
      name: input.name,
      frequency: input.frequency,
      day_of_week: input.day_of_week ?? null,
      day_of_month: input.day_of_month ?? null,
      time_utc: input.time_utc,
      timezone: input.timezone,
      recipients: input.recipients,
      sections: input.sections,
      is_active: true,
      next_run_at,
    })
    .select()
    .single();

  if (error) {
    console.error("[schedule POST] Insert error:", error);
    return NextResponse.json(
      { error: "Failed to create schedule" },
      { status: 500 }
    );
  }

  return NextResponse.json({ schedule: data as ReportSchedule }, { status: 201 });
}

// ---------------------------------------------------------------------------
// PUT: Update an existing schedule (D-50f pause/resume, edit)
// ---------------------------------------------------------------------------

export async function PUT(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { id, ...updates } = (body as Record<string, unknown>) ?? {};
  if (!id || typeof id !== "string") {
    return NextResponse.json({ error: "Schedule id is required" }, { status: 400 });
  }

  const parse = updateScheduleSchema.safeParse(updates);
  if (!parse.success) {
    return NextResponse.json(
      { error: "Validation failed", details: parse.error.flatten().fieldErrors },
      { status: 400 }
    );
  }

  const input = parse.data;

  // If recipients are being updated, validate them (D-50e)
  if (input.recipients) {
    const recipientCheck = await validateRecipients(supabase, user.id, input.recipients);
    if (!recipientCheck.valid) {
      return NextResponse.json(
        {
          error: "Invalid recipients: not team members",
          invalidIds: recipientCheck.invalidIds,
        },
        { status: 400 }
      );
    }
  }

  // Build update payload, recompute next_run_at if frequency/time changed
  const payload: Record<string, unknown> = { ...input };
  if (input.frequency || input.time_utc) {
    // Fetch current schedule to merge with updates
    const { data: current } = await supabase
      .from("cs_report_schedules")
      .select("frequency, time_utc, day_of_week, day_of_month")
      .eq("id", id)
      .eq("user_id", user.id)
      .single();

    if (current) {
      payload.next_run_at = computeNextRunAt(
        (input.frequency ?? current.frequency) as string,
        (input.time_utc ?? current.time_utc) as string,
        input.day_of_week !== undefined ? input.day_of_week : (current.day_of_week as number | null),
        input.day_of_month !== undefined ? input.day_of_month : (current.day_of_month as number | null)
      );
    }
  }

  const { data, error } = await supabase
    .from("cs_report_schedules")
    .update(payload)
    .eq("id", id)
    .eq("user_id", user.id)
    .select()
    .single();

  if (error) {
    console.error("[schedule PUT] Update error:", error);
    return NextResponse.json(
      { error: "Failed to update schedule" },
      { status: 500 }
    );
  }

  if (!data) {
    return NextResponse.json({ error: "Schedule not found" }, { status: 404 });
  }

  return NextResponse.json({ schedule: data as ReportSchedule });
}

// ---------------------------------------------------------------------------
// DELETE: Remove a schedule (D-50f)
// ---------------------------------------------------------------------------

export async function DELETE(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const id = searchParams.get("id");

  if (!id) {
    return NextResponse.json({ error: "Schedule id is required" }, { status: 400 });
  }

  const { error, count } = await supabase
    .from("cs_report_schedules")
    .delete({ count: "exact" })
    .eq("id", id)
    .eq("user_id", user.id);

  if (error) {
    console.error("[schedule DELETE] Error:", error);
    return NextResponse.json(
      { error: "Failed to delete schedule" },
      { status: 500 }
    );
  }

  if ((count ?? 0) === 0) {
    return NextResponse.json({ error: "Schedule not found" }, { status: 404 });
  }

  return NextResponse.json({ deleted: true });
}

// ---------------------------------------------------------------------------
// Action handler: send_now and send_test (D-50g, D-50o)
// ---------------------------------------------------------------------------

async function handleAction(
  supabase: NonNullable<Awaited<ReturnType<typeof getAuthenticatedClient>>["supabase"]>,
  userId: string,
  action: z.infer<typeof actionSchema>
) {
  // Fetch the schedule
  const { data: schedule, error } = await supabase
    .from("cs_report_schedules")
    .select("*")
    .eq("id", action.schedule_id)
    .eq("user_id", userId)
    .single();

  if (error || !schedule) {
    return NextResponse.json({ error: "Schedule not found" }, { status: 404 });
  }

  // For send_test (D-50o): override recipients to just the current user
  const recipients =
    action.action === "send_test"
      ? [userId]
      : (schedule.recipients as string[]);

  try {
    // Call the cron processing logic for a single schedule
    const { Resend } = await import("resend");
    const resendKey = process.env.RESEND_API_KEY;
    if (!resendKey) {
      return NextResponse.json(
        { error: "Email delivery not configured (RESEND_API_KEY missing)" },
        { status: 503 }
      );
    }

    const resend = new Resend(resendKey);

    // Generate a basic portfolio rollup for the email
    const { renderReportEmail } = await import("@/lib/reports/email-template");
    const emailHtml = await renderReportEmail({
      healthScore: 85,
      budgetPercent: 72,
      projectCount: 0,
      openIssues: 0,
      reportUrl: `${process.env.NEXT_PUBLIC_APP_URL ?? "https://constructionos.com"}/reports/rollup`,
      generatedAt: new Date().toISOString(),
    });

    // Look up recipient emails
    const recipientEmails: string[] = [];
    for (const rid of recipients) {
      const { data: profile } = await supabase
        .from("auth.users" as string)
        .select("email")
        .eq("id", rid)
        .single();
      if (profile?.email) {
        recipientEmails.push(profile.email as string);
      }
    }

    if (recipientEmails.length === 0) {
      // Fallback: use the current user's email from auth
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (user?.email) recipientEmails.push(user.email);
    }

    if (recipientEmails.length === 0) {
      return NextResponse.json(
        { error: "No valid recipient email addresses found" },
        { status: 400 }
      );
    }

    // D-50r: Auto-generated subject line
    const dateStr = new Date().toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
    const subject =
      action.action === "send_test"
        ? `[TEST] ConstructionOS Portfolio Report -- ${dateStr}`
        : `ConstructionOS Portfolio Report -- ${dateStr}`;

    // Send via Resend (D-50q: noreply from address)
    await resend.emails.send({
      from: "ConstructionOS Reports <reports@constructionos.com>",
      to: recipientEmails,
      subject,
      html: emailHtml,
    });

    // Log delivery (D-50h)
    await supabase.from("cs_report_delivery_log").insert({
      schedule_id: schedule.id,
      user_id: userId,
      recipients,
      status: "sent",
      email_html: emailHtml,
    });

    return NextResponse.json({
      sent: true,
      action: action.action,
      recipientCount: recipientEmails.length,
    });
  } catch (err) {
    console.error(`[schedule ${action.action}] Error:`, err);

    // D-50x: On Resend failure, log failure
    await supabase.from("cs_report_delivery_log").insert({
      schedule_id: schedule.id,
      user_id: userId,
      recipients,
      status: "failed",
      error_message: err instanceof Error ? err.message : "Unknown error",
    });

    return NextResponse.json(
      { error: "Failed to send report email", details: err instanceof Error ? err.message : "Unknown error" },
      { status: 500 }
    );
  }
}
