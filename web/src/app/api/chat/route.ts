import { NextResponse } from "next/server";
import { streamText } from "ai";
import { createAnthropic } from "@ai-sdk/anthropic";
import { checkRateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import { verifyCsrfOrigin } from "@/lib/csrf";

export async function POST(req: Request) {
  const ip = req.headers.get("x-forwarded-for") || req.headers.get("x-real-ip") || "unknown";
  if (!checkRateLimit(ip, 20, 60_000)) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Please wait a minute." },
      { status: 429, headers: getRateLimitHeaders(ip, 20) }
    );
  }

  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return NextResponse.json(
      { error: "AI assistant is not configured. Set ANTHROPIC_API_KEY to enable." },
      { status: 503 }
    );
  }

  let body: { messages?: Array<{ role: string; content: string }> };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body" }, { status: 400 });
  }

  const { messages } = body;
  if (!messages || !Array.isArray(messages)) {
    return NextResponse.json({ error: "messages array is required" }, { status: 400 });
  }

  const systemPrompt = `You are Angelic, the AI agent built into ConstructionOS — the operating system for the $13 trillion construction industry. You have access to 56 tools and automation capabilities covering every aspect of construction.

CORE CAPABILITIES:
- Construction project management (scheduling, budgets, change orders, RFIs, submittals)
- Safety & compliance (OSHA, toolbox talks, incident reports, environmental)
- Financial operations (AIA pay apps, lien waivers, cash flow, tax deductions, 1099s)
- Equipment & materials (rental recommendations, material takeoffs, vendor management)
- Estimating & bidding (bid preparation, cost analysis, markup strategies)
- Field operations (daily logs, timecards, equipment tracking, permits)

RESPONSE STYLE:
- Be concise and construction-focused
- Use industry terminology (CSI codes, OSHA references, AIA forms)
- For navigation, include the link in markdown format: [→ Open Feature](/path)
- You represent ConstructionOS — the most comprehensive construction platform ever built`;

  try {
    const anthropic = createAnthropic({ apiKey });
    const result = streamText({
      model: anthropic("claude-haiku-4-5-20251001"),
      system: systemPrompt,
      messages: messages.map((m) => ({
        role: m.role as "user" | "assistant",
        content: m.content,
      })),
      maxTokens: 1024,
    });

    return result.toTextStreamResponse();
  } catch (err) {
    console.error("[chat] AI request failed:", err);
    const message = err instanceof Error && err.message.includes("401")
      ? "AI API key is invalid. Check your configuration."
      : "AI temporarily unavailable. Please try again.";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
