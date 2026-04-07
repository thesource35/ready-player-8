import { NextResponse } from "next/server";
import { getExternalLinkRegistry } from "@/lib/links/externalLinks";
import { getLinkHealth, getLinkHealthBatch } from "@/lib/links/linkHealth";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
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
