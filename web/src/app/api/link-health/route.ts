import { NextResponse } from "next/server";
import { getExternalLinkRegistry } from "@/lib/links/externalLinks";
import { getLinkHealth, getLinkHealthBatch } from "@/lib/links/linkHealth";
import { checkRateLimit } from "@/lib/rate-limit";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const ip = req.headers.get("x-forwarded-for") ?? "unknown";
  if (!checkRateLimit(ip, 10)) return NextResponse.json({ error: "Too many requests" }, { status: 429 });

  const { searchParams } = new URL(req.url);
  const url = searchParams.get("url");
  const force = searchParams.get("force") === "1";

  if (url) {
    const result = await getLinkHealth(url, { force });
    return NextResponse.json(result);
  }

  const registry = getExternalLinkRegistry();
  const results = await getLinkHealthBatch(registry, { force });

  return NextResponse.json({
    count: results.length,
    results,
  });
}
