export type LinkHealthStatus = "ok" | "redirect" | "error" | "timeout" | "invalid" | "blocked";

export type LinkHealthResult = {
  url: string;
  status: LinkHealthStatus;
  statusCode?: number;
  checkedAt: string;
  responseTimeMs?: number;
  finalUrl?: string;
  error?: string;
};

const CACHE_TTL_MS = 5 * 60 * 1000;
const REQUEST_TIMEOUT_MS = 8000;
const linkCache = new Map<string, LinkHealthResult>();
const inflight = new Map<string, Promise<LinkHealthResult>>();

type BatchOptions = {
  force?: boolean;
  concurrency?: number;
};

export async function getLinkHealth(url: string, options: { force?: boolean } = {}) {
  const normalized = normalizeUrl(url);

  if (!isHttpUrl(normalized)) {
    return {
      url: normalized,
      status: "invalid",
      checkedAt: new Date().toISOString(),
      error: "Only http(s) URLs are supported.",
    } satisfies LinkHealthResult;
  }

  const cached = linkCache.get(normalized);
  if (!options.force && cached && !isExpired(cached)) {
    return cached;
  }

  const existing = inflight.get(normalized);
  if (existing) return existing;

  const promise = checkLink(normalized).finally(() => inflight.delete(normalized));
  inflight.set(normalized, promise);
  const result = await promise;
  linkCache.set(normalized, result);
  return result;
}

export async function getLinkHealthBatch(urls: string[], options: BatchOptions = {}) {
  const unique = Array.from(new Set(urls.map(normalizeUrl).filter(Boolean)));
  const limit = Math.max(1, Math.min(options.concurrency ?? 6, 12));
  const results = new Array<LinkHealthResult>(unique.length);
  let cursor = 0;

  await Promise.all(
    Array.from({ length: limit }, async () => {
      while (true) {
        const index = cursor++;
        if (index >= unique.length) return;
        results[index] = await getLinkHealth(unique[index], { force: options.force });
      }
    }),
  );

  return results;
}

function isExpired(result: LinkHealthResult) {
  const checkedAt = Date.parse(result.checkedAt);
  if (Number.isNaN(checkedAt)) return true;
  return Date.now() - checkedAt > CACHE_TTL_MS;
}

function isHttpUrl(url: string) {
  return url.startsWith("http://") || url.startsWith("https://");
}

function normalizeUrl(url: string) {
  const trimmed = url.trim();
  try {
    return new URL(trimmed).toString();
  } catch {
    return trimmed;
  }
}

function isBlockedHost(url: URL) {
  const hostname = url.hostname.toLowerCase();
  if (hostname === "localhost" || hostname.endsWith(".local")) return true;
  if (hostname === "0.0.0.0") return true;
  if (hostname === "127.0.0.1" || hostname === "::1") return true;
  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(hostname)) {
    const parts = hostname.split(".").map((part) => Number(part));
    if (parts.some((part) => Number.isNaN(part))) return false;
    const [a, b] = parts;
    if (a === 10) return true;
    if (a === 127) return true;
    if (a === 192 && b === 168) return true;
    if (a === 172 && b >= 16 && b <= 31) return true;
  }
  if (hostname.startsWith("fc") || hostname.startsWith("fd")) return true;
  return false;
}

async function checkLink(url: string): Promise<LinkHealthResult> {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return {
      url,
      status: "invalid",
      checkedAt: new Date().toISOString(),
      error: "Invalid URL.",
    };
  }

  if (isBlockedHost(parsed)) {
    return {
      url,
      status: "blocked",
      checkedAt: new Date().toISOString(),
      error: "Blocked host.",
    };
  }

  const startedAt = Date.now();

  try {
    let response = await fetchWithTimeout(url, "HEAD");

    if (!response.ok || response.status === 405 || response.status === 403) {
      response = await fetchWithTimeout(url, "GET");
    }

    return toResult(url, response, Date.now() - startedAt);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error.";
    const status = message.toLowerCase().includes("aborted") ? "timeout" : "error";
    return {
      url,
      status,
      checkedAt: new Date().toISOString(),
      responseTimeMs: Date.now() - startedAt,
      error: message,
    };
  }
}

async function fetchWithTimeout(url: string, method: "HEAD" | "GET") {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    return await fetch(url, {
      method,
      redirect: "follow",
      cache: "no-store",
      signal: controller.signal,
      headers: method === "GET" ? { Range: "bytes=0-0" } : undefined,
    });
  } finally {
    clearTimeout(timeout);
  }
}

function toResult(url: string, response: Response, responseTimeMs: number): LinkHealthResult {
  const statusCode = response.status;
  let status: LinkHealthStatus = "error";
  if (statusCode >= 200 && statusCode < 300) status = "ok";
  if (statusCode >= 300 && statusCode < 400) status = "redirect";
  if (statusCode === 401 || statusCode === 403 || statusCode === 405) status = "blocked";

  return {
    url,
    status,
    statusCode,
    checkedAt: new Date().toISOString(),
    responseTimeMs,
    finalUrl: response.url,
  };
}
