# Phase 30 Plan 01 — Verification Evidence

**Date:** 2026-04-23
**Plan:** 30-01 (NOTIF-03 Server Action refactor)

## D-03 REST surface lock (iOS + programmatic callers)

| Check | File | Result |
|-------|------|--------|
| PATCH handler count | `web/src/app/api/notifications/[id]/route.ts` | 1 (unchanged) |
| DELETE handler count | `web/src/app/api/notifications/[id]/route.ts` | 1 (unchanged) |
| POST handler count | `web/src/app/api/notifications/mark-all-read/route.ts` | 1 (unchanged) |

Command:
```
grep -cE "^export async function PATCH" web/src/app/api/notifications/[id]/route.ts  # => 1
grep -cE "^export async function DELETE" web/src/app/api/notifications/[id]/route.ts # => 1
grep -cE "^export async function POST" web/src/app/api/notifications/mark-all-read/route.ts # => 1
```

## D-04 full vitest notifications suite

```
$ cd web && npx vitest run src/lib/notifications/

 Test Files  5 passed (5)
      Tests  19 passed (19)
```

Files:
- `dismiss.test.ts` — pre-existing (Phase 14)
- `markAllRead.test.ts` — pre-existing (Phase 14)
- `unread.test.ts` — pre-existing (Phase 14)
- `markReadAction.test.ts` — **new (Phase 30-01 D-01)**
- `markAllReadAction.test.ts` — **new (Phase 30-01 D-02)**

## D-01/D-02 page.tsx kludge removal

| Check | Result |
|-------|--------|
| `grep -c "_method" web/src/app/inbox/page.tsx` | 0 |
| `grep -c "from \"./actions\"" web/src/app/inbox/page.tsx` | 1 |
| `grep -c "action={markAllReadAction}" web/src/app/inbox/page.tsx` | 1 |
| `grep -c "action={markReadAction}" web/src/app/inbox/page.tsx` | 1 |

## ESLint

```
$ cd web && npx eslint src/app/inbox/page.tsx src/app/inbox/actions.ts \
    src/lib/notifications/markReadAction.test.ts src/lib/notifications/markAllReadAction.test.ts
$ echo $?
0
```

## TypeScript (tsc --noEmit)

Pre-existing `live-feed/generate-suggestion.ts:154` error (Phase 29 surface) is unchanged — confirmed on main via `git stash` / `npx tsc --noEmit` / `git stash pop` loop. Phase 30-01 introduces zero new tsc errors; the two previously-expected-to-fail imports (`@/app/inbox/actions` in the new test files) now resolve cleanly.

Logged to `deferred-items.md`.

## Conclusion

All D-01/D-02/D-03/D-04 verification criteria are satisfied with evidence. NOTIF-03 is closed: clicking READ on an unread row mutates `read_at` via the Server Action path and triggers `revalidatePath('/inbox')`. MARK ALL READ likewise. The REST surface at `/api/notifications/[id]` remains available for iOS and programmatic callers per D-03.
