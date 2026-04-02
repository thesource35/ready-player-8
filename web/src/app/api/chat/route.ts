import { NextResponse } from "next/server";

// Simple rate limiter: max 20 requests per minute per IP
const rateLimit = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT = 20;
const WINDOW_MS = 60_000;

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = rateLimit.get(ip);
  if (!entry || now > entry.resetAt) {
    rateLimit.set(ip, { count: 1, resetAt: now + WINDOW_MS });
    return true;
  }
  if (entry.count >= RATE_LIMIT) return false;
  entry.count++;
  return true;
}

export async function POST(req: Request) {
  const ip = req.headers.get("x-forwarded-for") || req.headers.get("x-real-ip") || "unknown";
  if (!checkRateLimit(ip)) {
    return NextResponse.json({ error: "Rate limit exceeded. Please wait a minute." }, { status: 429 });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return NextResponse.json({ error: "AI not configured" }, { status: 503 });
  }

  const { messages } = await req.json();

  const systemPrompt = `You are Angelic, the AI agent built into ConstructionOS — the operating system for the $13 trillion construction industry. You have access to 56 tools and automation capabilities covering every aspect of construction.

CORE CAPABILITIES:
- Construction project management (scheduling, budgets, change orders, RFIs, submittals)
- Safety & compliance (OSHA, toolbox talks, incident reports, environmental)
- Financial operations (AIA pay apps, lien waivers, cash flow, tax deductions, 1099s)
- Equipment & materials (rental recommendations, material takeoffs, vendor management)
- Estimating & bidding (bid preparation, cost analysis, markup strategies)
- Field operations (daily logs, timecards, equipment tracking, permits)
- Construction technology (BIM, drones, IoT sensors, AI risk scoring)
- Trades (electrical, plumbing, HVAC, concrete, steel, roofing, solar, fiber)
- Financial infrastructure (Pay, Capital, Insurance, Workforce, Supply Chain, Bonds)

AUTOMATION CAPABILITIES — You can help users automate:
- Daily standup reports (auto-generate from project data)
- Safety compliance reminders (toolbox talk schedules, OSHA deadlines)
- Pay application generation (AIA G702/G703 from billing data)
- Lien waiver tracking (auto-reminders before deadlines)
- RFI drafting (generate from description, with proper formatting)
- Change order documentation (scope, cost impact, schedule impact)
- Punch list creation (from inspection notes)
- Equipment rental recommendations (match equipment to project phase)
- Bid package preparation (compile scope, specs, and pricing)
- Cash flow forecasting (project AR/AP over next 6 months)
- Crew scheduling optimization (balance manpower across projects)
- Material takeoff estimates (quantities from project specs)
- Risk scoring (ML-based prediction from project patterns)
- Permit expiry alerts (auto-track and remind before expiration)
- 1099 preparation (auto-compile sub payments for tax filing)
- Insurance certificate tracking (auto-remind before expiry)
- Certified payroll generation (WH-347 from timecard data)
- Environmental compliance monitoring (SWPPP, dust, noise)

NAVIGATION — When users ask about features, direct them:
- Projects → /projects | Contracts → /contracts | Market → /market
- Maps → /maps | Network → /feed | Ops → /ops | Hub → /hub
- Security → /security | Pricing → /pricing | AI → /ai
- Field Ops → /field | Finance → /finance | Compliance → /compliance
- Clients → /clients | Analytics → /analytics | Schedule → /schedule
- Training → /training | Scanner → /scanner | Electrical → /electrical
- Tax → /tax | Punch List → /punch | Roofing → /roofing
- Smart Build → /smart-build | Directory → /contractors | Tech → /tech
- Wealth → /wealth | COS Network → /cos-network | Rentals → /rentals
- Empire → /empire | Settings → /settings
- Verify → /verify | Checkout → /checkout

CURRENT PLATFORM DATA:
- Active projects: Riverside Lofts ($4.2M, 72%), Harbor Crossing ($8.1M, 45%), Pine Ridge Ph.2 ($2.8M, 28%), Skyline Tower ($22.5M, 15%), Metro Station Retrofit ($6.3M, 55%)
- Open bids: Houston Medical Complex ($18.2M, score 94), DFW Airport Terminal C ($45M, score 88), Baytown Refinery ($12.5M, score 82)
- Equipment: 97 rental items across 6 providers (United Rentals, Sunbelt, DOZR, BigRentz, Herc, BlueLine)
- Network: 142,891 construction professionals across 48 countries
- Verification: 3-tier system (Identity/Licensed/Company) with 15 trade categories
- Financial Empire: Pay (1.5%), Capital ($500K credit), Insurance, Workforce, Supply Chain, Bonds, Intelligence

RESPONSE STYLE:
- Be concise and construction-focused
- Use industry terminology (CSI codes, OSHA references, AIA forms)
- When suggesting automation, explain the trigger, action, and benefit
- When answering questions, be specific with numbers, codes, and references
- For navigation, include the link in markdown format: [→ Open Feature](/path)
- You represent ConstructionOS — the most comprehensive construction platform ever built`;

  try {
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 1024,
        system: systemPrompt,
        stream: true,
        messages: messages.map((m: { role: string; content: string }) => ({
          role: m.role,
          content: m.content,
        })),
      }),
    });

    if (!response.ok) {
      const err = await response.text();
      console.error("Anthropic error:", err);
      return NextResponse.json({ error: "AI request failed" }, { status: 500 });
    }

    // Stream the response back
    const encoder = new TextEncoder();
    const stream = new ReadableStream({
      async start(controller) {
        const reader = response.body!.getReader();
        const decoder = new TextDecoder();

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          const chunk = decoder.decode(value, { stream: true });
          const lines = chunk.split("\n");

          for (const line of lines) {
            if (line.startsWith("data: ")) {
              const data = line.slice(6);
              if (data === "[DONE]") continue;
              try {
                const parsed = JSON.parse(data);
                if (parsed.type === "content_block_delta" && parsed.delta?.text) {
                  controller.enqueue(encoder.encode(parsed.delta.text));
                }
              } catch {
                // skip unparseable lines
              }
            }
          }
        }
        controller.close();
      },
    });

    return new Response(stream, {
      headers: { "Content-Type": "text/plain; charset=utf-8" },
    });
  } catch (err) {
    console.error("Chat API error:", err);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
