import { NextResponse } from "next/server";
import { streamText, stepCountIs } from "ai";
import { createAnthropic } from "@ai-sdk/anthropic";
import { verifyCsrfOrigin } from "@/lib/csrf";
import { createServerSupabase } from "@/lib/supabase/server";
import { createConstructionTools } from "./tools";

export async function POST(req: Request) {
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

  // Create Supabase client and construction tools for AI tool calling
  const supabase = await createServerSupabase();
  const tools = createConstructionTools(supabase);

  const systemPrompt = `You are Angelic, the AI agent built into ConstructionOS — the operating system for the $13 trillion construction industry.

CAPABILITIES:
- Query live project, contract, RFI, change order, punch list, and daily log data
- Generate draft RFI documents for user review
- Draft change orders from natural language descriptions
- Analyze bid competitiveness against market data

RULES:
- Always use tools to fetch current data before answering questions about projects, contracts, or bids
- When generating documents (RFI, Change Order), present the draft clearly and ask the user to confirm before any action
- For bid analysis, explain the comparison methodology and data sources
- Be concise and use construction industry terminology (CSI codes, OSHA, AIA forms)
- For navigation, use markdown links: [Open Feature](/path)`;

  try {
    const anthropic = createAnthropic({ apiKey });
    const result = streamText({
      model: anthropic("claude-haiku-4-5-20251001"),
      system: systemPrompt,
      messages: messages.map((m) => ({
        role: m.role as "user" | "assistant",
        content: m.content,
      })),
      tools,
      stopWhen: stepCountIs(5),
      maxOutputTokens: 2048,
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
