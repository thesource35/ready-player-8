---
phase: 26-documents-rls-table-reconciliation
plan: 04
subsystem: ui
tags: [nextjs, swiftui, supabase, picker, documents, entity-type, drift-guard]

# Dependency graph
requires:
  - phase: 26-documents-rls-table-reconciliation
    plan: 01
    provides: 5 stub tables (cs_rfis, cs_submittals, cs_change_orders, cs_safety_incidents, cs_punch_items) the helper's HEAD-count queries target
  - phase: 26-documents-rls-table-reconciliation
    plan: 03
    provides: ENTITY_TYPES (7) + ENTITY_TABLE_MAP + DocumentEntityType on web; iOS enum was at 7 cases since Phase 16
  - phase: 13-documents
    provides: UploadButton + AttachmentList + VersionHistory component triad the prop widening extends
  - phase: 16-field-schema
    provides: DocumentEntityType 3 new cases (daily_log, safety_incident, punch_item) the widened prop union now admits
provides:
  - "web: nonEmptyEntityTypes(SupabaseClient) → Promise<DocumentEntityType[]> — batched 7-HEAD-count picker helper"
  - "web: shouldEnableAttachment(currentEntityType, nonEmpty) → boolean — sync component-side guard that always admits 'project' and the current entity context"
  - "web: UploadButton.Props.entityType and AttachmentList.Props.entityType widened from 4-value inline union to DocumentEntityType (7 values)"
  - "iOS: DocumentSyncManager.nonEmptyEntityTypes() async → [DocumentEntityType] — TaskGroup parity of the web helper, safe when SupabaseService not configured (returns allCases so picker is permissive)"
  - "T-26-NPL-UI mitigation: both helpers bound their request count to 7 parallel HEAD-shaped reads — no per-row fetch, no recursive N+1"
  - "T-26-SQLI defense-in-depth for the picker: web reuses hard-coded ENTITY_TABLE_MAP literal; iOS switches on DocumentEntityType returning string literals — no user input flows into table-name position"
affects: [26-05-schema-push-and-verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pattern: batched HEAD-count picker helper — Promise.all (web) / withTaskGroup (iOS) over a finite enum of entity types, each resolving to a cheap existence check (`select('id', { count: 'exact', head: true })` on web; `select=id&limit=1` on iOS), returning only the subset whose table has rows visible to the current user. Bounded, RLS-respecting, zero row transfer."
    - "Pattern: prop-type widening as a superset — the old narrow 4-value union is a strict subset of DocumentEntityType, so every existing caller continues to compile without modification; the widening is evidence that downstream code is now aware of all 7 entity types even though picker UI hasn't landed yet."
    - "Pattern: shared table-name source of truth — both the web pre-flight (Plan 03) and the web picker (Plan 04) read from the same ENTITY_TABLE_MAP constant; on iOS both the DocumentSyncManager.preflightEntityExists switch and the new nonEmptyEntityTypes switch return byte-identical string literals. A future enum addition MUST update both call sites (drift-guard tests from Plan 03 already pin the enum-level invariant)."
    - "Pattern: offline-permissive picker on iOS — when SupabaseService.isConfigured == false, nonEmptyEntityTypes returns allCases rather than []. Rationale: the user is in demo / offline mode and there's no meaningful 'what's populated?' signal; the server-side pre-flight (Plan 03) will still catch bogus entity ids when connectivity returns."

key-files:
  created:
    - web/src/lib/documents/entityPickerQuery.ts
    - web/src/lib/documents/entityPickerQuery.test.ts
  modified:
    - web/src/components/documents/UploadButton.tsx
    - web/src/components/documents/AttachmentList.tsx
    - ready player 8/DocumentSyncManager.swift

key-decisions:
  - "D-12 shared helper lands now even without a visible picker UI — components import DocumentEntityType so any future caller automatically uses the full 7-value vocabulary; when the picker UI is introduced (future phase), the helper is ready."
  - "UploadButton / AttachmentList are scoped as prop-widening only, not behavior change — the plan explicitly notes that introducing new picker UI is out-of-scope for this plan; components continue to operate on whatever entityType they receive."
  - "VersionHistory.tsx left untouched — its existing narrow 4-value union is still a subset of DocumentEntityType and compiles unchanged under the UploadButton widening (which is a superset). Plan scope is strictly UploadButton + AttachmentList + iOS. No regression risk."
  - "iOS helper's offline-permissive fallback (allCases) chosen over empty array so the picker UX is not crippled in demo mode; server pre-flight from Plan 03 is the authoritative gate when connectivity returns."
  - "iOS DocumentAttachmentsView.swift has zero switch statements on DocumentEntityType — 'non-exhaustive switch warning' acceptance is trivially satisfied without view changes (verified by grep)."
  - "The helper's batched-count implementation counts rows via Supabase's built-in `count: 'exact', head: true` option — this is the cheapest existence check available on the client (no row bytes transferred), already used across the codebase."

patterns-established:
  - "Pattern: Future-proof prop union widening — when a discriminated union literal appears in a component prop, prefer importing the single source-of-truth type (DocumentEntityType, here from validation.ts) over inlining the union, so a later enum extension propagates automatically."
  - "Pattern: Cross-platform helper parity — when a web helper is shipped for an upcoming feature, land an iOS-named sibling (same function name, same semantics, same concurrency model — Promise.all maps to withTaskGroup) in the same plan so neither platform lags when the feature UI lands."

requirements-completed: [DOC-03, DOC-04]
gap_closure: [INT-01]

# Metrics
duration: 15min
completed: 2026-04-18
---

# Phase 26 Plan 04: UI Picker Empty-Table Filter Summary

**Shared picker-helper + prop-union widening across web and iOS: `nonEmptyEntityTypes` returns the subset of DocumentEntityType whose backing table has rows visible to the current user (batched 7-HEAD-count, RLS-respecting, bounded); UploadButton / AttachmentList / DocumentSyncManager now speak the full 7-value vocabulary so when a future phase ships picker UI, the empty-table filter applies automatically.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-18T21:34:54Z
- **Completed:** 2026-04-18T21:50:03Z
- **Tasks:** 2
- **Files created:** 2
- **Files modified:** 3

## Accomplishments

- Authored `web/src/lib/documents/entityPickerQuery.ts`:
  - `nonEmptyEntityTypes(supabase)` — exactly 7 parallel `select('id', { count: 'exact', head: true })` requests via `Promise.all`, one per `ENTITY_TYPES` member; returns `DocumentEntityType[]` filtered to rows with `count > 0` under RLS. Per-table errors are logged and that type is excluded rather than failing the whole call.
  - `shouldEnableAttachment(currentEntityType, nonEmpty)` — pure sync guard for component use. Returns `true` if the current entity type is in the non-empty set OR the current type is `project` (project is the anchor and is populated before any dependent entity can exist).
- Authored `web/src/lib/documents/entityPickerQuery.test.ts` — 6 vitest cases covering:
  - `nonEmptyEntityTypes` returns only types whose table has rows
  - `nonEmptyEntityTypes` returns `[]` when every table is empty
  - `nonEmptyEntityTypes` makes exactly 7 queries (no N+1) — verified by counting `from(table)` calls on the mock client
  - `shouldEnableAttachment` admits the current entity when it's in the non-empty set
  - `shouldEnableAttachment` admits `project` regardless of global state
  - `shouldEnableAttachment` rejects `rfi` when the non-empty set is empty
- Widened `web/src/components/documents/UploadButton.tsx` `Props.entityType` from the 4-value inline union `"project" | "rfi" | "submittal" | "change_order"` to `DocumentEntityType` (imported from `@/lib/documents/validation`). Existing callers (`projects/[id]`, `rfis/[id]`, `submittals/[id]`, `change-orders/[id]`, `VersionHistory`) pass string literals that remain valid under the widened union.
- Widened `web/src/components/documents/AttachmentList.tsx` `Props.entityType` identically. The 4 existing page-level callers continue to compile unchanged.
- Added `DocumentSyncManager.nonEmptyEntityTypes() async -> [DocumentEntityType]` to `ready player 8/DocumentSyncManager.swift` — iOS parity:
  - Uses `withTaskGroup` to fan out 7 parallel `SupabaseService.fetch(table, query: ["select": "id", "limit": "1"], orderBy: nil)` requests
  - Table name resolved through a hard-coded switch on `DocumentEntityType` (no `@unknown default`) — the T-26-SQLI iOS parity
  - Returns `DocumentEntityType.allCases` when `SupabaseService.shared.isConfigured == false` so the picker doesn't collapse in demo mode; server pre-flight (Plan 03) stays authoritative when connectivity returns
- Confirmed DocumentAttachmentsView.swift has zero `switch` statements on DocumentEntityType — the plan's "no non-exhaustive switch warning" acceptance is trivially satisfied with no view changes required.

## Helper Signatures

### Web

```ts
// web/src/lib/documents/entityPickerQuery.ts
export async function nonEmptyEntityTypes(
  supabase: SupabaseClient,
): Promise<DocumentEntityType[]>;

export function shouldEnableAttachment(
  currentEntityType: DocumentEntityType,
  nonEmpty: DocumentEntityType[],
): boolean;
```

### iOS

```swift
// ready player 8/DocumentSyncManager.swift
@MainActor
final class DocumentSyncManager: ObservableObject {
    func nonEmptyEntityTypes() async -> [DocumentEntityType]
}
```

## Prop-Union Widening Evidence

| File | Before | After |
|------|--------|-------|
| `web/src/components/documents/UploadButton.tsx` | `entityType: "project" \| "rfi" \| "submittal" \| "change_order"` (4 values, inline) | `entityType: DocumentEntityType` (7 values, from `@/lib/documents/validation`) |
| `web/src/components/documents/AttachmentList.tsx` | same 4-value inline union | `DocumentEntityType` imported type |

Existing callers — `web/src/app/projects/[id]/page.tsx`, `rfis/[id]/page.tsx`, `submittals/[id]/page.tsx`, `change-orders/[id]/page.tsx`, `web/src/components/documents/VersionHistory.tsx`, `web/src/app/documents/[chainId]/versions/page.tsx` — continue to compile unchanged because every literal they pass (`"project"`, `"rfi"`, `"submittal"`, `"change_order"`) is a valid `DocumentEntityType` member.

## Dependency on Plans 01 / 03 Honored

- Web helper's `ENTITY_TABLE_MAP[t]` lookup resolves to one of 7 table names: `cs_projects` (Phase 1), `cs_rfis` / `cs_submittals` / `cs_change_orders` / `cs_safety_incidents` / `cs_punch_items` (Plan 01), `cs_daily_logs` (Phase 16). Every target table exists in the migration chain, so the helper is free of defensive guards.
- iOS helper's hard-coded switch returns byte-identical strings to the iOS pre-flight switch in `DocumentSyncManager.preflightEntityExists` (added in Plan 03). Both call sites will need to move in lock-step on any future enum extension — the Plan 03 drift-guard tests are the canonical gate.

## Task Commits

Each task was committed atomically:

1. **Task 1 (TDD): Shared web helper `nonEmptyEntityTypes` + wire into UploadButton/AttachmentList** — `16c29c5` (feat)
2. **Task 2: iOS parity — `nonEmptyEntityTypes` helper** — `76a9289` (feat)

TDD flow on Task 1: RED (test file written, `vitest run` failed with "Cannot find module") then GREEN (helper file written, `vitest run` passed 6/6). Both tasks committed as single atomic commits covering both RED and GREEN, matching the pattern used in Plan 03.

## Files Created/Modified

**Created:**

- `web/src/lib/documents/entityPickerQuery.ts` (59 lines) — 2 exports, JSDoc on both, T-26-SQLI rationale inline.
- `web/src/lib/documents/entityPickerQuery.test.ts` (61 lines) — 6 vitest cases, shape-compatible SupabaseClient mock counting `from(table)` calls.

**Modified:**

- `web/src/components/documents/UploadButton.tsx` — 1 import added (`type DocumentEntityType`), 1 prop type widened, 6-line Phase 26 Plan 04 rationale comment.
- `web/src/components/documents/AttachmentList.tsx` — 1 import added, 1 prop type widened, 5-line rationale comment.
- `ready player 8/DocumentSyncManager.swift` — 1 new `// MARK: - Phase 26 D-12 picker helper` section with `nonEmptyEntityTypes()` (53 lines including doc comment). Placed immediately before the existing `// MARK: - Phase 26 pre-flight` section for logical grouping.

## Verification Results

- `cd web && npx vitest run src/lib/documents` — **2 files, 21 tests, all passing** (15 in validation.test.ts from Plan 03 + 6 new in entityPickerQuery.test.ts).
- `cd web && npx vitest run src/lib/documents src/components/documents src/app/api/documents` — **8 files, 64 tests passed + 6 todo, no regressions** across documents subsystem.
- `cd web && npx tsc --noEmit` — exit 0 (no TypeScript errors across entire web project).
- `npx eslint` on the 4 modified/new files — 0 errors, 2 warnings (underscore-prefixed mock parameters in the test file; consistent with `daily-log-create.test.ts` style in the codebase; non-blocking).
- `swiftc -parse ready\ player\ 8/DocumentSyncManager.swift` — exit 0 (no syntax errors).
- `swiftc -parse ready\ player\ 8/DocumentAttachmentsView.swift` — exit 0 (no changes needed, parses clean).
- Grep acceptance (Task 1): `DocumentEntityType` present in both components; the 4-value inline union is REMOVED from both files.
- Grep acceptance (Task 2): `nonEmptyEntityTypes` + `cs_safety_incidents` + `cs_punch_items` + `cs_change_orders` all present in DocumentSyncManager.swift.
- Exhaustiveness: The new iOS switch has 7 explicit cases (`.project`, `.rfi`, `.submittal`, `.changeOrder`, `.dailyLog`, `.safetyIncident`, `.punchItem`) with no `@unknown default`.

## Threat Mitigations Verified

| Threat ID | Mitigation | Evidence |
|-----------|-----------|----------|
| T-26-NPL-UI | Bounded parallel requests | Web: `Promise.all(ENTITY_TYPES.map(...))` — exactly 7 elements. iOS: `withTaskGroup` iterating `DocumentEntityType.allCases` — exactly 7 tasks. Vitest test case `makes exactly one query per entity type (no N+1)` asserts `m.calls.length === 7` at runtime. |
| T-26-LEAK-UI | RLS-respecting counts | Both helpers go through the Supabase client which enforces RLS on the `count` HEAD request. A user only sees non-zero `hasRow` for types whose rows they are permitted to SELECT — no cross-org probing surface. (Accept disposition — no new leak.) |
| T-26-STALE-UI | Per-mount hydration | Accept. Picker state hydrates per call; a user who just created the first RFI may need to refresh to see RFI enable. Documented in plan threat model. |
| T-26-SQLI (picker parity) | Hard-coded table-name lookup | Web: helper uses `ENTITY_TABLE_MAP[t]` — object-literal keyed by DocumentEntityType; TypeScript prevents non-enum keys at compile time. iOS: `tableFor` closure returns string literals via an exhaustive 7-branch switch on DocumentEntityType; no string concatenation, no user input. |

## Decisions Made

Followed plan as specified. Design decisions D-12 (picker filter), Plan-04 scope ("prop widening + helper only, no new picker UI"), and T-26-SQLI iOS parity are asserted in inline comments at each site.

Sub-decisions asserted while authoring:

- Kept the web helper's per-table error path as `console.error + return hasRow: false` (silently excludes that type) rather than throwing — matches Plan 03 pre-flight tolerance where a transient lookup failure should not break the whole picker. The plan spec called for this verbatim.
- Used type-only import (`import type { DocumentEntityType }`) in both widened components — keeps the runtime bundle lean and avoids a circular import risk.
- Added a brief Phase 26 Plan 04 rationale comment block above each widened Props type so future readers see why the union changed from 4 to 7 values without having to chase the phase number through git blame.
- Did NOT widen `VersionHistory.tsx` or the `documents/[chainId]/versions/page.tsx` caller even though they still hold the original 4-value union. They remain subsets of DocumentEntityType so they compile unchanged under the Plan 04 widening; widening them would have been scope creep beyond the plan's 2-file component list.
- Chose `DocumentEntityType.allCases` (not `[]`) as the iOS offline-fallback return. Rationale: demo mode without Supabase should not collapse the picker; server pre-flight (Plan 03) provides the authoritative gate when connectivity returns. Documented in the helper's doc comment.
- No XCTest drift-guard was added for the iOS helper — the Plan 03 `DocumentSyncManagerPreflightTests.test_documentEntityType_allCases_matchesDBEnum` already pins `DocumentEntityType.allCases` set-equality against the canonical 7 strings; a second XCTest on `nonEmptyEntityTypes` would be redundant (it reads the same enum). Plan 04 explicitly marks XCTest coverage for this helper as "not required".

## Deviations from Plan

None — plan executed exactly as written.

The plan supplied exact TypeScript/Swift snippets for every modification, and the committed diffs are byte-faithful transcriptions. All automated acceptance checks pass:

| Check | Required | Actual |
|-------|----------|--------|
| `entityPickerQuery.ts` exists with both exports | yes | yes |
| `entityPickerQuery.test.ts` exists with 3 `nonEmptyEntityTypes` + 3 `shouldEnableAttachment` cases | yes | yes (6/6 pass) |
| `cd web && npx vitest run src/lib/documents/entityPickerQuery.test.ts` exits 0 | yes | yes (6 passed) |
| UploadButton.tsx uses `entityType: DocumentEntityType` | yes | yes |
| AttachmentList.tsx uses `entityType: DocumentEntityType` | yes | yes |
| Inline 4-value union REMOVED from UploadButton.tsx | yes | yes (grep returns 0 matches) |
| Inline 4-value union REMOVED from AttachmentList.tsx | yes | yes (grep returns 0 matches) |
| Existing callers still compile | yes | `tsc --noEmit` exit 0 |
| `grep -q "func nonEmptyEntityTypes" DocumentSyncManager.swift` | yes | yes |
| `grep -q "cs_safety_incidents" DocumentSyncManager.swift` | yes | yes (also cs_punch_items + cs_change_orders) |
| Switch in iOS helper is exhaustive across 7 DocumentEntityType cases with no `@unknown default` | yes | yes |
| DocumentAttachmentsView.swift has no non-exhaustive switch on DocumentEntityType | yes | yes (zero switch statements on this enum) |

## Issues Encountered

None.

## User Setup Required

None — pure library / helper / prop-type changes. No external service configuration, no migrations, no env var additions.

## Next Phase Readiness

- **Plan 05** (schema push + verification) — UNBLOCKED and unchanged. Plan 04 is independent of Plan 05 by design; the helper landing before the migration push does not affect push ordering. Plan 05's verification can optionally include a live call to `nonEmptyEntityTypes` after `supabase db push` to assert that all 5 stub tables return `hasRow: false` when freshly provisioned.
- **Future picker UI phase** — when a `<EntityTypePicker />` component is introduced, it can `import { nonEmptyEntityTypes, shouldEnableAttachment } from "@/lib/documents/entityPickerQuery"` on day one; the helper is production-shaped. iOS equivalents will call `await DocumentSyncManager.shared.nonEmptyEntityTypes()`.
- **INT-01** — UI layer closure now complements the schema (Plans 01/02) and application (Plan 03) closures. A picker surface that respects the empty-table invariant is one component-level change away. No remaining gap-closure work at the UI-library layer.

## Self-Check: PASSED

Verified:

- File exists: `FOUND: web/src/lib/documents/entityPickerQuery.ts`
- File exists: `FOUND: web/src/lib/documents/entityPickerQuery.test.ts`
- File exists: `FOUND: web/src/components/documents/UploadButton.tsx` (modified)
- File exists: `FOUND: web/src/components/documents/AttachmentList.tsx` (modified)
- File exists: `FOUND: ready player 8/DocumentSyncManager.swift` (modified)
- Commit exists: `FOUND: 16c29c5` (Task 1)
- Commit exists: `FOUND: 76a9289` (Task 2)
- Test suite: `2 files, 21 tests, 0 failures` on `cd web && npx vitest run src/lib/documents`
- Broader documents suite: `8 files, 64 passed + 6 todo, 0 failures` on `cd web && npx vitest run src/lib/documents src/components/documents src/app/api/documents`
- TypeScript: `tsc --noEmit` exit 0 across entire `web/`
- swiftc -parse: clean on DocumentSyncManager.swift and DocumentAttachmentsView.swift

---
*Phase: 26-documents-rls-table-reconciliation*
*Completed: 2026-04-18*
