---
quick_id: 260510-snz
type: execute
wave: 1
status: complete
completed_date: 2026-05-10
tasks_completed: 4
duration_minutes: 8
commits:
  - hash: 1e5c8b3
    subject: "fix(supabase): break user_orgs RLS infinite recursion via SECURITY DEFINER helper"
    files: [supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql]
  - hash: 704df94
    subject: "fix(ios): per-row resilient decode in fetchTable so one bad row doesn't drop the list"
    files: ["ready player 8/SupabaseService.swift"]
  - hash: 6f2fa5e
    subject: "fix(ios): accept Supabase email-confirmation signup response (access_token may be null)"
    files: ["ready player 8/SupabaseService.swift"]
  - hash: fe266a6
    subject: "docs(backlog): note 999.5 (i)+(j) closures from RLS recursion + signup fixes"
    files: [.planning/ROADMAP.md]
requirements_satisfied:
  - 999.5-i  # DB integrity recovery follow-on (RLS recursion + per-row decode resilience)
  - 999.5-j  # APNs real-device test prerequisite (signup flow unblock)
key_files:
  created:
    - supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql
  modified:
    - ready player 8/SupabaseService.swift  # +DecodableSurvivor wrapper, +per-row resilient decode in fetchTable, signUp() now treats user-object-present as success
    - .planning/ROADMAP.md  # 999.5 (i) + (j) closure annotations
deferred_and_correct:
  - "ready player 8.xcodeproj/project.pbxproj"  # signing churn explicitly out of scope per orchestrator instruction
---

# Quick Task 260510-snz: Land 3 Post-Multi-Tenancy Production Fixes

## One-liner

Landed three pre-authored production-readiness fixes from the working tree as four atomic, independently-revertable commits: SECURITY DEFINER helper migration that breaks `user_orgs` RLS infinite recursion (HTTP 500 / 42P17 on every authenticated query), `DecodableSurvivor<T>` per-row resilient decode in `fetchTable` (stops one bad row from dropping the whole list after multi-tenancy added non-optional Codable fields), and signup-flow acceptance of `access_token=null` when Supabase email confirmation is enabled (unblocks new signups + APNs real-device push UAT).

## Commits Landed

| # | Hash | Subject | Files | Net |
|---|------|---------|-------|-----|
| A | `1e5c8b3` | `fix(supabase): break user_orgs RLS infinite recursion via SECURITY DEFINER helper` | `supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql` (new) | +68 / -0 |
| B | `704df94` | `fix(ios): per-row resilient decode in fetchTable so one bad row doesn't drop the list` | `ready player 8/SupabaseService.swift` | +30 / -1 |
| C | `6f2fa5e` | `fix(ios): accept Supabase email-confirmation signup response (access_token may be null)` | `ready player 8/SupabaseService.swift` | +9 / -3 |
| D | `fe266a6` | `docs(backlog): note 999.5 (i)+(j) closures from RLS recursion + signup fixes` | `.planning/ROADMAP.md` | +1 / -1 |

`git log --oneline -4` confirms the order is: docs (HEAD), signup, fetchTable, migration.

## Atomicity Audit (per plan Phase 2 verification)

| Check | Expected | Actual |
|-------|----------|--------|
| Commit A (migration) touches `20260509001_*.sql` exactly once | 1 | 1 |
| Commit A touches `SupabaseService.swift` | 0 | 0 |
| Commit B touches `SupabaseService.swift` | 1 | 1 |
| Commit B contains `DecodableSurvivor` | ≥3 | 3 |
| Commit B contains `userObj` (signup hunk) | 0 | 0 |
| Commit C touches `SupabaseService.swift` | 1 | 1 |
| Commit C contains `userObj` | ≥2 | 3 |
| Commit C contains `DecodableSurvivor` | 0 | 0 |
| Commit D touches `ROADMAP.md` | 1 | 1 |

Each fix commit is independently revertable — confirmed via `git revert --no-commit ... && git revert --abort` dry-run on HEAD~2 and HEAD~1; both produce only the auto-merge fast-path with no conflict markers.

## Working-Tree Final State

```
$ git status --short
 M .planning/STATE.md                              ← orchestrator handles in Step 7
 M "ready player 8.xcodeproj/project.pbxproj"     ← deferred per orchestrator (signing churn out of scope)
```

Confirmation: `project.pbxproj` was correctly NOT staged in any of the four commits. Its modified state in the working tree is preserved verbatim, exactly as the orchestrator instruction required. No file outside the four task targets was touched.

## ROADMAP Annotations (Commit D)

Two append-only edits to the existing `| 999.5 |` table row at `.planning/ROADMAP.md` line 317. Pipe-field count for the row remains `NF=6`, matching all 999.x sibling rows — table structure intact, no row-break inside the cell.

- **(i) follow-on:** "Follow-on closed 2026-05-10: RLS recursion bug in 20260413001 user_orgs policies (HTTP 500 / 42P17 on every authenticated query) fixed via SECURITY DEFINER helper in 20260509001; per-row resilient decode shipped in SupabaseService.swift fetchTable so rows pre-dating non-optional Codable fields no longer drop the whole list."
- **(j) follow-on:** "Signup-flow false-positive (\"Auth succeeded but no access token returned\" when email confirmation returns user but access_token=null) fixed in SupabaseService.swift signUp(); fresh signups on the production launch project no longer block on this."

## Out-of-Band Deploy Step (Not Run by This Plan)

The migration file `20260509001_fix_user_orgs_rls_recursion.sql` is committed but **not pushed to the remote DB**. Applying it via `supabase db push` is the user's responsibility when ready — the iOS-side fixes in commits B and C are independent of the migration's deploy state and ship value immediately on the next iOS build (decode resilience + signup unblock are local code paths, not RLS-dependent).

## Deviations from Plan

None on the four task scopes — all stage boundaries, commit messages, and file targets matched the plan verbatim.

One mechanical deviation worth noting:

- **`git add -p` not used.** The plan suggested `git add -p` for piecewise hunk staging on `SupabaseService.swift`, with the explicit caveat that any reliable atomic-by-commit mechanism is acceptable. I used the documented alternative: `git checkout HEAD -- "ready player 8/SupabaseService.swift"` to fully revert the file, then `Edit` tool to apply hunks 1+3 (commit B) → stage → commit, then `Edit` tool to apply hunk 2 (commit C) → stage → commit. This guarantees byte-faithful application without `git add -p` interactive-prompt brittleness in non-TTY shells. End-state file hash `5209a33` matches the original pre-task working-tree blob hash, confirming byte-faithful reproduction of the user's pre-authored changes.
- **`git add -f` for ROADMAP.md.** `.planning/` is gitignored project-wide, but ROADMAP.md is conventionally tracked (recent precedents: `4948775`, `32cbceb`, `4cecd32`, `b088708`). Used `git add -f .planning/ROADMAP.md` to bypass the ignore — single-file scope, matches established repo pattern.

## Lessons Learned

- **Atomic-by-commit invariant achievable without `git add -p` interactivity.** Reset-then-apply with the `Edit` tool is a reliable atomic-staging mechanism when the destination is well-bounded by unique anchor strings (the wrapper struct's location was anchored on the closing `}` of `SupabaseError` extension, and the fetchTable/signup hunks were anchored on stable adjacent lines). Useful pattern when interactive `git add -p` is impractical.
- **Hunk-2-skipped diff hash matches Hunk-2-applied original blob hash.** Verified mid-flight that after Task 2 + Task 3, `git diff` was empty and the file blob recovered the same SHA the user originally committed-into-working-tree (`5209a33` from the initial `git diff` shows up as the index hash on the post-Task-3 file). Strong confidence that no semantic drift occurred during the reset+reapply sequence.

## Self-Check: PASSED

- All 4 commits exist in `git log --oneline -4`: `1e5c8b3`, `704df94`, `6f2fa5e`, `fe266a6` ✓
- `supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql` exists and tracked ✓
- `ready player 8/SupabaseService.swift` contains both `DecodableSurvivor` (HEAD~2 commit B) and `userObj`/`Signup response missing user object` (HEAD~1 commit C) ✓
- `.planning/ROADMAP.md` contains both annotation strings (`Follow-on closed 2026-05-10` and `Signup-flow false-positive`) ✓
- Working tree shows only `STATE.md` (orchestrator-owned) and `project.pbxproj` (deferred) modifications — no other unstaged drift ✓
- 999.5 table row preserves `NF=6` pipe-field structure consistent with all 999.x sibling backlog rows ✓
