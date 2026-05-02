import { spawnSync } from "node:child_process";
import { writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..");

const args = process.argv.slice(2);
const jsonOutput = args.includes("--json");
const reportPathFlagIndex = args.indexOf("--report");
const reportPath = reportPathFlagIndex >= 0 ? args[reportPathFlagIndex + 1] : process.env.LINK_REPORT_PATH;

const rgArgs = [
  "-n",
  "https?://",
  "-S",
  repoRoot,
  "-g",
  "!**/package-lock.json",
  "-g",
  "!**/pnpm-lock.yaml",
  "-g",
  "!**/yarn.lock",
  "-g",
  "!**/bun.lockb",
  "-g",
  "!**/node_modules/**",
  "-g",
  "!**/.git/**",
  "-g",
  "!**/web/.next/**",
  "-g",
  "!**/web/public/**",
  "-g",
  "!**/*.svg",
  "-g",
  "!**/*.png",
  "-g",
  "!**/*.jpg",
  "-g",
  "!**/*.jpeg",
  "-g",
  "!**/*.gif",
];

const rg = spawnSync("rg", rgArgs, { encoding: "utf8" });
if (rg.status !== 0 && rg.status !== 1) {
  console.error("Failed to scan links with rg.");
  console.error(rg.stderr);
  process.exit(1);
}

const urlRegex = /https?:\/\/[^\s'"`)\]]+/g;
const urls = new Set();

rg.stdout.split("\n").forEach((line) => {
  const matches = line.match(urlRegex);
  if (!matches) return;
  matches.forEach((match) => {
    const cleaned = match.replace(/[),.;:]+$/, "");
    if (shouldSkipUrl(cleaned)) return;
    urls.add(cleaned);
  });
});

const urlList = Array.from(urls);
const results = await checkAll(urlList, 8);

if (jsonOutput) {
  const payload = JSON.stringify({ count: results.length, results }, null, 2);
  if (reportPath) {
    writeFileSync(reportPath, payload);
  } else {
    console.log(payload);
  }
  process.exit(0);
}

const summary = results.reduce(
  (acc, result) => {
    acc[result.status] = (acc[result.status] || 0) + 1;
    return acc;
  },
  {},
);

console.log(`Checked ${results.length} links.`);
Object.entries(summary).forEach(([status, count]) => {
  if (status === "blocked") {
    console.log(`blocked: ${count} (treated as ok)`);
  } else {
    console.log(`${status}: ${count}`);
  }
});

const blocked = results.filter((result) => result.status === "blocked");
const failures = results.filter((result) => !["ok", "redirect", "blocked"].includes(result.status));

if (blocked.length > 0 && process.env.LINKCHECK_SHOW_BLOCKED !== "0") {
  console.log("\nBlocked by remote host (often anti-bot protections):");
  blocked.forEach((result) => {
    console.log(`- ${result.url} (${result.statusCode ? `HTTP ${result.statusCode}` : result.status})`);
  });
}

if (failures.length > 0) {
  console.log("\nBroken or unreachable links:");
  failures.forEach((result) => {
    console.log(`- ${result.url} (${result.status}${result.statusCode ? ` ${result.statusCode}` : ""})`);
  });
  process.exitCode = 1;
}

async function checkAll(list, concurrency) {
  const results = new Array(list.length);
  let cursor = 0;

  await Promise.all(
    Array.from({ length: concurrency }, async () => {
      while (true) {
        const index = cursor++;
        if (index >= list.length) return;
        results[index] = await checkUrl(list[index]);
      }
    }),
  );

  return results;
}

async function checkUrl(url) {
  const startedAt = Date.now();
  try {
    let response = await fetchWithTimeout(url, "HEAD");
    if (!response.ok || response.status === 405 || response.status === 403) {
      response = await fetchWithTimeout(url, "GET");
    }
    return {
      url,
      status: response.status >= 200 && response.status < 300
        ? "ok"
        : response.status >= 300 && response.status < 400
          ? "redirect"
          : [401, 403, 405].includes(response.status)
            ? "blocked"
            : "error",
      statusCode: response.status,
      responseTimeMs: Date.now() - startedAt,
      finalUrl: response.url,
      checkedAt: new Date().toISOString(),
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    const status = message.toLowerCase().includes("aborted") ? "timeout" : "error";
    return {
      url,
      status,
      responseTimeMs: Date.now() - startedAt,
      checkedAt: new Date().toISOString(),
      error: message,
    };
  }
}

async function fetchWithTimeout(url, method) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);

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

function shouldSkipUrl(url) {
  if (url.includes("${") || url.includes("\\(")) return true;
  if (url.endsWith("\\")) return true;
  if (isLocalHost(url)) return true;
  if (isPlaceholderHost(url)) return true;
  return false;
}

// Placeholder URLs that appear in source code (docs, .env.example, sample
// configs, default placeholder text in form fields) should not be validated.
// They never resolve and cluttering the link-health report with them hides
// real drift in legitimate external references.
function isPlaceholderHost(url) {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.toLowerCase();
    // RFC 2606 reserved test/example TLDs
    if (host === "example.com" || host.endsWith(".example.com")) return true;
    if (host === "example.org" || host.endsWith(".example.org")) return true;
    if (host === "example.net" || host.endsWith(".example.net")) return true;
    if (host === "example" || host.endsWith(".example")) return true;
    if (host === "test" || host.endsWith(".test")) return true;
    if (host === "invalid" || host.endsWith(".invalid")) return true;
    // Common placeholder hostnames (one-character or template-literal-ish)
    if (host.length <= 1) return true;
    if (host.startsWith("...")) return true;
    if (host.startsWith("your-")) return true;
    // Specific known placeholders used in BackendConfigSheet field hints,
    // .env.example, and sample documentation
    if (host === "abc.supabase.co") return true;
    return false;
  } catch {
    return false;
  }
}

function isLocalHost(url) {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.toLowerCase();
    if (host === "localhost" || host.endsWith(".local")) return true;
    if (host === "0.0.0.0" || host === "127.0.0.1" || host === "::1") return true;
    if (/^\\d{1,3}(\\.\\d{1,3}){3}$/.test(host)) {
      const parts = host.split(".").map((part) => Number(part));
      if (parts.some((part) => Number.isNaN(part))) return false;
      const [a, b] = parts;
      if (a === 10) return true;
      if (a === 127) return true;
      if (a === 192 && b === 168) return true;
      if (a === 172 && b >= 16 && b <= 31) return true;
    }
    return false;
  } catch {
    return false;
  }
}
