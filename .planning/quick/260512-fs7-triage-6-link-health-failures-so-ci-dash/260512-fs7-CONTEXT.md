# Quick Task 260512-fs7: link-health triage - Context

**Gathered:** 2026-05-12
**Status:** Ready for planning

<domain>
## Task Boundary

CI link-health job (`web/scripts/link-health.mjs`, ripgrep-driven repo-wide URL extractor) currently fails on 7 URLs. `continue-on-error: true` keeps the workflow green, but job-level red is dashboard noise. Goal: link-health job conclusion = `success` on next CI run, WITHOUT weakening the script's ability to surface future real drift.

The 7 failing URLs are all NOT placeholder text in the existing `isPlaceholderHost()` sense — they're real hosts being used in real production code/tests/configs. They fail for distinct reasons that map to distinct fixes.

</domain>

<decisions>
## Implementation Decisions

### Skip-list architecture

**Decision: Explicit `knownExceptions` array per URL inside `link-health.mjs`.**

Add a `const knownExceptions: { url: string, reason: string, expires?: string }[]` near the top of the file. URLs that exactly-match an entry are treated as `ok` (or a new `skipped` status). Each entry MUST have a stated reason. Optional `expires` field surfaces the URL back into checks after a date — used for deferred-domain URLs that should resurface when 999.8 ships.

**Why this over alternatives**:
- Extending `isPlaceholderHost()` would conflate "real-host-treated-as-placeholder-text" with the existing example.com/*.example.test patterns; risks masking future real drift on those same hosts.
- HEAD-method retry would catch script-side false positives (Fly.io POST endpoints, Supabase REST roots) but doesn't help the deferred-domain class.
- Hybrid (HEAD retry + knownExceptions) was the cleanest but more code than needed for 7 URLs.

### Per-URL classification

**Source-fix (3 URLs):**
1. `dozr.com/equipment-rental?ref=constructionos` in `ready player 8/RentalSearchView.swift:121` → change to `https://dozr.com/rent?ref=constructionos` (verified HTTP 200 via curl; the `/equipment-rental` path is a dead URL from dozr's older site structure)
2. `https://app.constructionos.world/reports` in `web/src/lib/reports/__tests__/email.test.ts` (fixture) → change to `https://example.com/reports` (already filtered by `isPlaceholderHost()` RFC 2606 rule)

**knownExceptions entries (5 URLs):**
| URL | Reason | expires |
|---|---|---|
| `https://constructionos-video-worker.fly.dev/transcode` | POST-only Fly.io worker endpoint; GET returns error, but the URL is correct and active | — |
| `https://nzdbphddnrfybwecvsvq.supabase.co` | Supabase project root returns 404 by design (REST APIs require /rest/v1/ path); the URL is correct | — |
| `https://hooks.zapier.com/hooks/catch/` | Zapier base URL used as placeholder UI text in `WebhookConfig.tsx`; real hooks attach a path suffix | — |
| `https://company.com` | Sample placeholder text in security/page.tsx + ThemeEditor.tsx + email.test.ts; the real domain is owned by someone unrelated (timeouts due to bot-block) | — |
| `https://docs.constructionos.world/reports` | Help link in `HelpSection.tsx`; awaiting 999.8 domain registration. Set `expires: "2027-01-01"` so it resurfaces after a reasonable window for 999.8 to ship | 2027-01-01 |

**Why dozr is a source-fix (not knownException):** the URL is genuinely dead (404 on dozr.com itself), not a false positive. Fixing the source URL preserves the link-health value of catching future real drift on dozr.com paths.

### Why not also add `app.constructionos.world` to knownExceptions?

The test fixture should use unambiguous placeholders (RFC 2606 example.com), not production-shape URLs that depend on future domain reg. This decouples the test from 999.8 and matches general best practice for test fixtures.

### Claude's Discretion

- **Status field for skipped URLs**: introduce a new `skipped` status (alongside `ok/redirect/blocked/error/timeout`) so the summary line reports them honestly ("skipped: 5 (knownExceptions)"). Bookkeeping clarity. Surfaces if knownExceptions grows unwieldy.
- **Output behavior**: print the `knownExceptions` list at the bottom of the report (like `blocked` URLs are listed) so reviewers can audit them at a glance.
- **Whether to also handle the dozr `/rent/mini-excavators` (301) and `/rent/cranes` (301) URLs in externalLinks.ts**: NO — link-health treats 301 as `redirect` (counted as ok). Out of scope for this task.

</decisions>

<specifics>
## Specific Ideas

### `knownExceptions` shape (proposed)

```javascript
const knownExceptions = [
  {
    url: "https://constructionos-video-worker.fly.dev/transcode",
    reason: "POST-only Fly.io worker endpoint; GET returns error but URL is correct (worker/README.md)",
  },
  {
    url: "https://nzdbphddnrfybwecvsvq.supabase.co",
    reason: "Supabase project root returns 404 by design; REST APIs require /rest/v1/ path",
  },
  {
    url: "https://hooks.zapier.com/hooks/catch/",
    reason: "Zapier base URL placeholder in WebhookConfig.tsx; real hooks attach a path",
  },
  {
    url: "https://company.com",
    reason: "Sample placeholder text (security/page.tsx, ThemeEditor.tsx, email.test.ts); real domain blocks bots",
  },
  {
    url: "https://docs.constructionos.world/reports",
    reason: "Help link in HelpSection.tsx; awaiting 999.8 domain registration",
    expires: "2027-01-01",
  },
];
```

### Filter integration point

Inside `checkLink(url)` (or at the top, alongside `isPlaceholderHost(url)`), add early-return:

```javascript
function findKnownException(url) {
  return knownExceptions.find((e) => e.url === url);
}

// Inside checkLink, BEFORE the actual HTTP check:
const exception = findKnownException(url);
if (exception) {
  if (exception.expires && new Date() > new Date(exception.expires)) {
    // expired — fall through to real check
  } else {
    return { url, status: "skipped", reason: exception.reason };
  }
}
```

### Source-fix locations

- `ready player 8/RentalSearchView.swift:121`: change `"https://dozr.com/equipment-rental?ref=constructionos"` → `"https://dozr.com/rent?ref=constructionos"`
- `web/src/lib/reports/__tests__/email.test.ts`: change `https://app.constructionos.world/reports` → `https://example.com/reports` (use `grep -n "constructionos.world" web/src/lib/reports/__tests__/email.test.ts` to find exact line; may be multiple occurrences)

</specifics>

<canonical_refs>
## Canonical References

- `web/scripts/link-health.mjs:48` — ripgrep file crawl (`repoRoot = path.resolve(__dirname, "..", "..")` → entire repo)
- `web/scripts/link-health.mjs:218-247` — existing `isPlaceholderHost()` filter (canonical pattern reference)
- `web/scripts/link-health.mjs:80-110` — results bucketing + summary output (knownExceptions should integrate here)
- `worker/README.md` — Fly.io worker URL canonical source
- `web/src/lib/links/externalLinks.ts` — DOZR partner link registry (line 24 root URL works; line 37/39 `/rent/<plural>` 301-redirect to singular — out of scope)
- CI run 25743599585 — the green-workflow + red-link-health-job that surfaced this task

</canonical_refs>
