---
quick_id: 260510-snz
type: execute
wave: 1
depends_on: []
files_modified:
  - supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql
  - ready player 8/SupabaseService.swift
  - .planning/ROADMAP.md
autonomous: true
requirements:
  - 999.5-i  # DB integrity recovery follow-on (RLS recursion + per-row decode resilience)
  - 999.5-j  # APNs real-device test prerequisite (signup flow unblock)

must_haves:
  truths:
    - "Migration 20260509001 lands as its own atomic commit with no other files staged."
    - "SupabaseService.swift fetchTable<T> per-row decode rewrite (DecodableSurvivor wrapper + decode-each-row site) lands as a single atomic commit independent of the signup hunk."
    - "SupabaseService.swift signUp() access-token-may-be-null acceptance lands as its own atomic commit, applied AFTER the fetchTable commit so the file's hunks can be staged piecewise."
    - "ROADMAP.md backlog 999.5 entry gains two human-readable closure notes — one under (i) for the RLS+decode fixes, one under (j) for the signup unblock — committed as docs."
    - "git log --oneline -5 shows the four commits in order: A migration, B fetchTable, C signup, D docs."
    - "After all four commits land, `git status` for the listed files is clean (nothing left unstaged in supabase/migrations/ or in the SupabaseService.swift hunks targeted by this plan)."
    - "project.pbxproj signing churn remains untouched in this plan — its modified state in the working tree is preserved, NOT staged into any of the four commits."
  artifacts:
    - path: "supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql"
      provides: "SECURITY DEFINER public.user_org_ids() helper + 4 non-recursive user_orgs RLS policies replacing the recursive originals from 20260413001"
      contains: "create or replace function public.user_org_ids"
    - path: "ready player 8/SupabaseService.swift"
      provides: "DecodableSurvivor<T> wrapper + per-row resilient decode in fetchTable<T> + access-token-nullable signup acceptance"
      contains: "DecodableSurvivor"
    - path: ".planning/ROADMAP.md"
      provides: "Closure annotations on backlog 999.5 (i) and 999.5 (j)"
      contains: "20260509001"
  key_links:
    - from: "Commit A (migration)"
      to: "user_orgs RLS policies on remote DB"
      via: "supabase db push (out-of-band, NOT part of this plan — applied by user when ready)"
      pattern: "create or replace function public.user_org_ids"
    - from: "Commit B (fetchTable)"
      to: "Commit C (signUp) staging"
      via: "Both hunks live in the same file; commit B must stage and land its two hunks (~line 132 wrapper + ~line 716 call site) before commit C stages the remaining ~line 262 signup hunk"
      pattern: "git diff --cached 'ready player 8/SupabaseService.swift' is EMPTY between commits B and C until C's git add -p run"
    - from: "Commit D (docs)"
      to: "Commits A+B+C"
      via: "ROADMAP.md notes reference the migration filename and the SupabaseService.swift behavior changes the prior commits shipped"
      pattern: "Append-only edits to existing 999.5 paragraph; no other ROADMAP lines touched"
---

<objective>
Land 3 already-implemented production-readiness bug fixes from the working tree as 4 atomic commits (3 fixes + 1 docs). The code changes are pre-authored and validated by the user; this plan formalizes them into independently-revertable commits with conventional-commit messages, then annotates backlog 999.5 (i)+(j) in ROADMAP.md.

Purpose: Each fix closes a distinct user-facing production blocker — (1) HTTP 500 / 42P17 infinite-recursion on every authenticated query touching user_orgs (Maps, Projects, multi-tenant tabs); (2) "data could not be read because it is missing" alerts dropping entire lists when one row predates a non-optional Codable field added by the multi-tenancy rollout; (3) signup false-positive blocking new accounts on the production launch project because Supabase's email-confirmation flow returns access_token=null. Atomic commits matter so any single fix can be reverted independently if a regression surfaces post-launch.

Output: 4 commits on `main` (3 fix commits + 1 docs commit), ROADMAP.md backlog 999.5 entries (i)+(j) annotated as closed, project.pbxproj signing churn left untouched in the working tree per orchestrator instruction.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
@CLAUDE.md
@supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql

<!-- Reference only — DO NOT modify outside the hunks specified per task. -->
@ready player 8/SupabaseService.swift

<background>
Backlog 999.4 (multi-tenancy rollout, 2026-04-27) shipped migration 20260413001 which created the user_orgs table and four RLS policies whose USING/WITH CHECK clauses reference user_orgs itself. Postgres rejects this with SQLSTATE 42P17 ("infinite recursion detected in policy for relation user_orgs") on every authenticated query — surfaced 2026-05-09 as HTTP 500s wiping out Maps, Projects, and most multi-tenant iOS tabs.

Backlog 999.5 (i) is the catch-all "DB integrity recovery from 999.4" sub-item — already mostly closed, but the RLS recursion + per-row decode resilience are direct follow-ons to that recovery work. Backlog 999.5 (j) is the APNs real-device push UAT for NOTIF-05, blocked on a fresh signup completing on a physical iPhone — the signup access-token false-positive directly blocked that.

The user has already authored, tested, and staged all three fixes in the working tree. This plan does not design code; it formalizes the landing.
</background>

<staging_strategy>
Two of the three code changes live in the same file (`ready player 8/SupabaseService.swift`) but represent independent logical commits. The plan stages them piecewise via `git add -p` (or `git add` with explicit hunks):

- Commit A stages ONLY the new migration file.
- Commit B stages TWO hunks of SupabaseService.swift: the new `DecodableSurvivor<T>` wrapper struct (~line 132-145) and the rewritten `fetchTable<T>` decode-each-row site (~line 716-735). Both belong to the same logical change ("per-row resilient decode") even though they sit in different locations.
- Commit C then stages the REMAINING unstaged hunk: the `signUp()` body changes (~line 262-280) accepting access_token=null.
- Commit D stages ONLY the ROADMAP.md edits.

After commit C, `git diff "ready player 8/SupabaseService.swift"` MUST be empty for the lines this plan targets. Anything else still showing as modified (project.pbxproj, etc.) is intentionally untouched per orchestrator constraint.
</staging_strategy>

<commit_message_drafts>

**Commit A:**
```
fix(supabase): break user_orgs RLS infinite recursion via SECURITY DEFINER helper

Migration 20260413001 defined user_orgs RLS policies whose USING/WITH
CHECK clauses queried user_orgs itself, triggering Postgres 42P17
infinite-recursion detection on every authenticated query. Maps,
Projects, and most multi-tenant tabs were returning HTTP 500 in iOS.

Replace the four recursive policies with a SECURITY DEFINER
public.user_org_ids(filter_roles text[]) helper. Function bodies
bypass RLS, so the org-membership lookup runs once at call time
without re-triggering the parent policy. Closes follow-on under
backlog 999.5 (i).
```

**Commit B:**
```
fix(ios): per-row resilient decode in fetchTable so one bad row doesn't drop the list

After the multi-tenancy rollout added non-optional Codable fields to
SupabaseProject and friends, rows that pre-dated the migration began
producing "data could not be read because it is missing" alerts on
every tab that hit those tables. Pre-fix decoder.decode([T].self)
fails the whole array on the first bad row.

Wrap each row in a fileprivate DecodableSurvivor<T> that uses
try? T(from: decoder), then compactMap to surviving values. Drop
counts are reported via CrashReporter so silent data loss is still
visible in telemetry. Closes follow-on under backlog 999.5 (i).
```

**Commit C:**
```
fix(ios): accept Supabase email-confirmation signup response (access_token may be null)

Supabase Auth's /signup endpoint returns the user object with
access_token set to null when the project has email confirmation
enabled — the access token only materializes after the user clicks
the confirmation link. The previous guard "Auth succeeded but no
access token returned" surfaced as a false-positive failure that
blocked all new signups on the production launch project.

Treat user-object-present as success; throw only when the response
is genuinely missing the user object. The UI flow already handles
the post-confirmation sign-in via the existing signIn() path.
Unblocks backlog 999.5 (j) APNs real-device test setup.
```

**Commit D (docs):**
```
docs(backlog): note 999.5 (i)+(j) closures from RLS recursion + signup fixes
```
</commit_message_drafts>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Commit A — migration 20260509001 (RLS recursion fix) as atomic commit</name>
  <files>supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql</files>
  <action>
Stage and commit ONLY the new migration file. The file is currently untracked (`?? supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql` in `git status`). Do NOT touch the SupabaseService.swift hunks yet — they belong to commits B and C.

Steps:

1. Verify the migration file is the ONLY thing being staged for this commit:
   ```bash
   cd "/Users/beverlyhunter/Desktop/ready player 8"
   git status --short supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql
   # expect: "?? supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql"
   ```

2. Stage the migration file by exact path (NEVER `git add .` or `git add -A`):
   ```bash
   git add supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql
   ```

3. Confirm staging is scoped exactly to this one file:
   ```bash
   git diff --cached --name-only
   # expect EXACTLY one line: supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql
   ```
   If anything else appears, run `git reset HEAD <file>` to unstage and retry.

4. Commit with the conventional-commit message from `<commit_message_drafts>` Commit A. Use a HEREDOC for clean formatting:
   ```bash
   git commit -m "$(cat <<'EOF'
   fix(supabase): break user_orgs RLS infinite recursion via SECURITY DEFINER helper

   Migration 20260413001 defined user_orgs RLS policies whose USING/WITH
   CHECK clauses queried user_orgs itself, triggering Postgres 42P17
   infinite-recursion detection on every authenticated query. Maps,
   Projects, and most multi-tenant tabs were returning HTTP 500 in iOS.

   Replace the four recursive policies with a SECURITY DEFINER
   public.user_org_ids(filter_roles text[]) helper. Function bodies
   bypass RLS, so the org-membership lookup runs once at call time
   without re-triggering the parent policy. Closes follow-on under
   backlog 999.5 (i).

   Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```

NOTE: This plan does NOT run `supabase db push` — applying the migration to the remote DB is an out-of-band step the user runs when ready. The commit just lands the SQL file.
  </action>
  <verify>
    <automated>cd "/Users/beverlyhunter/Desktop/ready player 8" && git log -1 --format="%s%n---%nFiles:%n%n" && git show --stat HEAD | head -10</automated>
  </verify>
  <done>
- `git log -1 --name-only` shows exactly ONE file in the latest commit: `supabase/migrations/20260509001_fix_user_orgs_rls_recursion.sql`
- Commit subject is exactly `fix(supabase): break user_orgs RLS infinite recursion via SECURITY DEFINER helper`
- `git status` no longer shows the migration as untracked
- SupabaseService.swift, project.pbxproj, ROADMAP.md remain unstaged
  </done>
</task>

<task type="auto">
  <name>Task 2: Commit B — SupabaseService.swift fetchTable per-row resilient decode (2 hunks, atomic)</name>
  <files>ready player 8/SupabaseService.swift</files>
  <action>
Stage the TWO hunks belonging to the per-row resilient decode change, leave the signUp() hunk unstaged for Task 3, and commit.

The two hunks for this commit (per `git diff "ready player 8/SupabaseService.swift"`):
- HUNK 1 (~line 132-145): adds `// MARK: - Per-row resilient decode wrapper` block with the fileprivate `DecodableSurvivor<T: Decodable>` struct
- HUNK 2 (~line 716-735): rewrites `fetchTable<T>` to decode `[DecodableSurvivor<T>].self`, compactMap surviving values, and report drop counts via `CrashReporter.shared.reportError`

The hunk to LEAVE UNSTAGED (belongs to Task 3):
- HUNK MIDDLE (~line 262-280): `signUp()` changes — `userObj` extraction, `currentUserEmail` rewire, replaced guard from `accessToken != nil` to `userObj != nil`

Steps:

1. Verify only `ready player 8/SupabaseService.swift` is currently modified (besides the project.pbxproj churn that we never touch):
   ```bash
   cd "/Users/beverlyhunter/Desktop/ready player 8"
   git status --short "ready player 8/SupabaseService.swift"
   # expect: " M ready player 8/SupabaseService.swift"
   ```

2. Use `git add -p "ready player 8/SupabaseService.swift"` to interactively stage hunks. The diff has 3 hunks against this file — stage hunks 1 and 3, skip hunk 2:
   ```bash
   git add -p "ready player 8/SupabaseService.swift"
   ```
   For each hunk prompt:
   - Hunk 1 (the `DecodableSurvivor` wrapper at ~line 132): answer **`y`** (stage)
   - Hunk 2 (the `signUp()` body changes at ~line 262 — contains `userObj` and the guard rewrite): answer **`n`** (skip — Task 3 will get this one)
   - Hunk 3 (the `fetchTable<T>` decode rewrite at ~line 716 — contains `DecodableSurvivor<T>].self` and `compactMap(\.value)`): answer **`y`** (stage)

   IDENTIFICATION CRITERIA for each hunk if `git add -p` prompts are ambiguous:
   - Hunk to STAGE if it contains: `fileprivate struct DecodableSurvivor`
   - Hunk to SKIP if it contains: `let userObj = json?["user"] as? [String: Any]` or `Signup response missing user object`
   - Hunk to STAGE if it contains: `decoder.decode([DecodableSurvivor<T>].self`

3. Verify staged hunks are exactly the two intended:
   ```bash
   git diff --cached "ready player 8/SupabaseService.swift"
   ```
   The cached diff MUST contain BOTH `DecodableSurvivor` (the struct definition AND its use in `fetchTable`) AND the `CrashReporter.shared.reportError("fetchTable(...)...` line. It MUST NOT contain `userObj` or `Signup response missing user object`.

4. Verify the unstaged remainder is the signUp() hunk only:
   ```bash
   git diff "ready player 8/SupabaseService.swift"
   ```
   The unstaged diff MUST contain `userObj` and `Signup response missing user object` and nothing else.

5. If the staging boundaries are wrong (e.g., `git add -p` lumped hunks together), use `git reset HEAD "ready player 8/SupabaseService.swift"` to fully unstage, then retry. Alternative if `-p` keeps merging: `git add -p` supports the `s` (split) command at each prompt to break a hunk into smaller pieces; the `e` (edit) command to manually craft the patch as a last resort.

6. Commit with the Commit B message:
   ```bash
   git commit -m "$(cat <<'EOF'
   fix(ios): per-row resilient decode in fetchTable so one bad row doesn't drop the list

   After the multi-tenancy rollout added non-optional Codable fields to
   SupabaseProject and friends, rows that pre-dated the migration began
   producing "data could not be read because it is missing" alerts on
   every tab that hit those tables. Pre-fix decoder.decode([T].self)
   fails the whole array on the first bad row.

   Wrap each row in a fileprivate DecodableSurvivor<T> that uses
   try? T(from: decoder), then compactMap to surviving values. Drop
   counts are reported via CrashReporter so silent data loss is still
   visible in telemetry. Closes follow-on under backlog 999.5 (i).

   Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```
  </action>
  <verify>
    <automated>cd "/Users/beverlyhunter/Desktop/ready player 8" && git log -1 --format="%s" && git show HEAD -- "ready player 8/SupabaseService.swift" | grep -c "DecodableSurvivor" && git diff "ready player 8/SupabaseService.swift" | grep -c "userObj"</automated>
  </verify>
  <done>
- `git log -1 --format="%s"` shows exactly: `fix(ios): per-row resilient decode in fetchTable so one bad row doesn't drop the list`
- `git show HEAD -- "ready player 8/SupabaseService.swift" | grep -c "DecodableSurvivor"` returns at least 3 (struct definition + decode call site references)
- `git diff "ready player 8/SupabaseService.swift" | grep -c "userObj"` returns at least 2 (the signup hunk is still unstaged, waiting for Task 3)
- `git status --short "ready player 8/SupabaseService.swift"` still shows ` M` (one hunk remains)
  </done>
</task>

<task type="auto">
  <name>Task 3: Commit C — SupabaseService.swift signUp() access-token-nullable acceptance</name>
  <files>ready player 8/SupabaseService.swift</files>
  <action>
Stage the remaining unstaged hunk (the `signUp()` body changes at ~line 262-280) and commit.

After Task 2, the only unstaged hunk in SupabaseService.swift should be the signUp() one — making this commit a simple `git add` of the file (which will only have one hunk left to stage).

Steps:

1. Confirm only the signup hunk is unstaged:
   ```bash
   cd "/Users/beverlyhunter/Desktop/ready player 8"
   git diff "ready player 8/SupabaseService.swift"
   ```
   Expected output: a single hunk centered on the `signUp()` function, containing the `userObj` extraction, the rewired `currentUserEmail = userObj?["email"]`, and the replaced guard from `accessToken != nil` to `userObj != nil` with new error message `"Signup response missing user object"`.

2. Stage by file path (only one hunk left, so `git add` without `-p` is fine — but `-p` with `y` to the single prompt is also fine and slightly safer):
   ```bash
   git add "ready player 8/SupabaseService.swift"
   ```

3. Verify staged diff is exclusively the signup hunk:
   ```bash
   git diff --cached "ready player 8/SupabaseService.swift"
   # expect to see: userObj, currentUserEmail = userObj?["email"], guard userObj != nil, "Signup response missing user object"
   # MUST NOT see: DecodableSurvivor, CrashReporter.shared.reportError("fetchTable
   ```

4. Verify nothing else is staged or unstaged for SupabaseService.swift:
   ```bash
   git diff "ready player 8/SupabaseService.swift"
   # expect: empty
   ```

5. Commit with the Commit C message:
   ```bash
   git commit -m "$(cat <<'EOF'
   fix(ios): accept Supabase email-confirmation signup response (access_token may be null)

   Supabase Auth's /signup endpoint returns the user object with
   access_token set to null when the project has email confirmation
   enabled — the access token only materializes after the user clicks
   the confirmation link. The previous guard "Auth succeeded but no
   access token returned" surfaced as a false-positive failure that
   blocked all new signups on the production launch project.

   Treat user-object-present as success; throw only when the response
   is genuinely missing the user object. The UI flow already handles
   the post-confirmation sign-in via the existing signIn() path.
   Unblocks backlog 999.5 (j) APNs real-device test setup.

   Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```
  </action>
  <verify>
    <automated>cd "/Users/beverlyhunter/Desktop/ready player 8" && git log -1 --format="%s" && git show HEAD -- "ready player 8/SupabaseService.swift" | grep -c "userObj" && git diff "ready player 8/SupabaseService.swift" | wc -l | tr -d ' '</automated>
  </verify>
  <done>
- `git log -1 --format="%s"` shows exactly: `fix(ios): accept Supabase email-confirmation signup response (access_token may be null)`
- `git show HEAD -- "ready player 8/SupabaseService.swift" | grep -c "userObj"` returns at least 2 (`let userObj` line + `guard userObj != nil` line)
- `git diff "ready player 8/SupabaseService.swift" | wc -l` returns 0 (the file has no remaining unstaged changes from this plan's scope — project.pbxproj is a different file and is intentionally untouched)
- `git log --oneline -3` shows the three fix commits in order: signup (HEAD), fetchTable (HEAD~1), migration (HEAD~2)
  </done>
</task>

<task type="auto">
  <name>Task 4: Commit D — annotate ROADMAP.md backlog 999.5 (i)+(j) closures</name>
  <files>.planning/ROADMAP.md</files>
  <action>
Append two short closure notes inside the existing 999.5 backlog paragraph (line 317 in ROADMAP.md as of plan authoring; use string-anchored Edit, not line-numbered). Both notes go inside the SAME table cell — no new table rows, no new columns — to keep the backlog table structure intact.

The 999.5 row is one giant pipe-delimited table cell. Find the two specific substrings inside it and append closure annotations.

Steps:

1. Read the current 999.5 table row:
   ```bash
   cd "/Users/beverlyhunter/Desktop/ready player 8"
   grep -n "^| 999.5 |" .planning/ROADMAP.md
   # confirms the line number; should be ~line 317
   ```

2. Use the Edit tool to append the (i) closure note. Find this exact substring inside the 999.5 row:
   ```
   **(i) DB integrity recovery from 999.4** — 6 multi-tenancy migrations shipped (`20260413001` foundation + `20260428002..006` Groups B/D/D-residue/E + org_id columns); 47/48 cs_* tables now have explicit RLS; Phase 22 video tables repaired and re-applied; `20260424001_phase30_attach_safety_trigger.sql` shipped.
   ```

   Replace with that same substring PLUS this appended sentence (single space separator, kept inside the same backlog cell):
   ```
    **Follow-on closed 2026-05-10:** RLS recursion bug in 20260413001 user_orgs policies (HTTP 500 / 42P17 on every authenticated query) fixed via SECURITY DEFINER helper in 20260509001; per-row resilient decode shipped in SupabaseService.swift fetchTable so rows pre-dating non-optional Codable fields no longer drop the whole list.
   ```

3. Use the Edit tool a second time to append the (j) closure note. Find this exact substring inside the same 999.5 row:
   ```
   **(j) APNs real-device push test** for NOTIF-05 — provisioning + capabilities ready; blocked on Supabase anon-key paste on physical iPhone (chicken-and-egg from a different angle: needs clean-copy via dashboard + iCloud Notes).
   ```

   Replace with that same substring PLUS this appended sentence:
   ```
    Signup-flow false-positive ("Auth succeeded but no access token returned" when email confirmation returns user but access_token=null) fixed in SupabaseService.swift signUp(); fresh signups on the production launch project no longer block on this.
   ```

4. Verify the edits landed cleanly and didn't break the table format:
   ```bash
   grep -c "Follow-on closed 2026-05-10" .planning/ROADMAP.md
   # expect 1
   grep -c "Signup-flow false-positive" .planning/ROADMAP.md
   # expect 1
   awk -F'|' 'NR==FNR && /^\| 999.5 \|/ { print NF; exit }' .planning/ROADMAP.md
   # expect a number consistent with other rows (5 fields between pipes for a backlog table row)
   ```

5. Stage and commit ONLY the ROADMAP.md change. The repo's `git status` will include other deferred working-tree files (project.pbxproj signing churn) — DO NOT stage those.
   ```bash
   git status --short .planning/ROADMAP.md
   # expect: " M .planning/ROADMAP.md"
   git add .planning/ROADMAP.md
   git diff --cached --name-only
   # expect EXACTLY one line: .planning/ROADMAP.md
   git commit -m "$(cat <<'EOF'
   docs(backlog): note 999.5 (i)+(j) closures from RLS recursion + signup fixes

   Annotate backlog 999.5 with the 2026-05-10 follow-on closures shipped
   in the prior three commits: SECURITY DEFINER helper migration that
   broke the user_orgs RLS recursion (i), per-row resilient decode in
   fetchTable that stops one bad row from dropping the whole list (i),
   and signup-flow access-token-nullable acceptance that unblocked
   APNs real-device push UAT (j).

   Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```

6. Final verification — confirm all four commits landed in the right order with the right scope:
   ```bash
   git log --oneline -4
   # expect (top to bottom):
   #   <hash> docs(backlog): note 999.5 (i)+(j) closures...
   #   <hash> fix(ios): accept Supabase email-confirmation signup response...
   #   <hash> fix(ios): per-row resilient decode in fetchTable...
   #   <hash> fix(supabase): break user_orgs RLS infinite recursion...
   git status --short
   # expect to still show:  M ready player 8.xcodeproj/project.pbxproj  (deferred per orchestrator)
   # MUST NOT show: any unstaged changes to ROADMAP.md, SupabaseService.swift, or migrations/
   ```
  </action>
  <verify>
    <automated>cd "/Users/beverlyhunter/Desktop/ready player 8" && git log --oneline -4 && grep -c "Follow-on closed 2026-05-10" .planning/ROADMAP.md && grep -c "Signup-flow false-positive" .planning/ROADMAP.md</automated>
  </verify>
  <done>
- `git log --oneline -4` shows the four commits in correct order: docs(backlog) at HEAD, then signup, then fetchTable, then migration
- `grep -c "Follow-on closed 2026-05-10" .planning/ROADMAP.md` returns 1
- `grep -c "Signup-flow false-positive" .planning/ROADMAP.md` returns 1
- `git status --short` shows project.pbxproj still unstaged (deferred per orchestrator); shows NO unstaged changes to ROADMAP.md, SupabaseService.swift, or supabase/migrations/
- The 999.5 table row still parses as a single Markdown table row (pipes balanced, no row-break inside the cell)
  </done>
</task>

</tasks>

<verification>

After all four tasks land:

```bash
cd "/Users/beverlyhunter/Desktop/ready player 8"

# Phase 1: Commit graph correctness
git log --oneline -4
# Expect 4 commits in this order (newest first):
#   docs(backlog): note 999.5 (i)+(j) closures from RLS recursion + signup fixes
#   fix(ios): accept Supabase email-confirmation signup response (access_token may be null)
#   fix(ios): per-row resilient decode in fetchTable so one bad row doesn't drop the list
#   fix(supabase): break user_orgs RLS infinite recursion via SECURITY DEFINER helper

# Phase 2: Each commit is atomic to its files
git show --stat HEAD~3 | grep -c "20260509001_fix_user_orgs_rls_recursion.sql"  # expect 1
git show --stat HEAD~3 | grep -cv "SupabaseService.swift"                       # expect non-zero (no Swift changes)
git show --stat HEAD~2 | grep -c "SupabaseService.swift"                        # expect 1
git show HEAD~2 -- "ready player 8/SupabaseService.swift" | grep -c "DecodableSurvivor"  # expect ≥3
git show HEAD~2 -- "ready player 8/SupabaseService.swift" | grep -c "userObj"   # expect 0
git show --stat HEAD~1 | grep -c "SupabaseService.swift"                        # expect 1
git show HEAD~1 -- "ready player 8/SupabaseService.swift" | grep -c "userObj"   # expect ≥2
git show HEAD~1 -- "ready player 8/SupabaseService.swift" | grep -c "DecodableSurvivor"  # expect 0
git show --stat HEAD   | grep -c "ROADMAP.md"                                   # expect 1

# Phase 3: Working tree state
git status --short
# Expect ONLY:
#   M ready player 8.xcodeproj/project.pbxproj
# (Deferred per orchestrator — signing churn explicitly NOT bundled.)

# Phase 4: Each commit is independently revertable
git revert --no-commit HEAD~2 && git revert --abort  # the fetchTable commit reverts cleanly
git revert --no-commit HEAD~1 && git revert --abort  # the signup commit reverts cleanly
# (Just dry-run sanity — abort, do not actually revert.)

# Phase 5: ROADMAP annotations present and well-formed
grep -A1 "Follow-on closed 2026-05-10" .planning/ROADMAP.md | head -3
grep -A1 "Signup-flow false-positive" .planning/ROADMAP.md | head -3
```

</verification>

<success_criteria>

- [ ] Four commits on `main`, in order: migration → fetchTable → signup → docs
- [ ] Commit A (migration) touches exactly 1 file
- [ ] Commit B (fetchTable) touches exactly 1 file (SupabaseService.swift) and contains `DecodableSurvivor` but NOT `userObj`
- [ ] Commit C (signup) touches exactly 1 file (SupabaseService.swift) and contains `userObj` but NOT `DecodableSurvivor`
- [ ] Commit D (docs) touches exactly 1 file (ROADMAP.md)
- [ ] `git status` final state: only project.pbxproj remains modified in the working tree (deferred per orchestrator)
- [ ] ROADMAP.md backlog 999.5 row contains both new annotations and still parses as one Markdown table row
- [ ] Each fix commit can be reverted individually without conflicts (dry-run only — verify, don't actually revert)
- [ ] No skipped pre-commit hooks (`--no-verify` not used anywhere)
- [ ] No `git add .` or `git add -A` was ever run; every stage was scoped by exact file path or `git add -p` hunk selection

</success_criteria>

<output>
After completion, create `.planning/quick/260510-snz-land-3-post-multi-tenancy-production-fix/260510-snz-SUMMARY.md` with:
- The 4 commit SHAs and full subjects
- Confirmation that project.pbxproj remains intentionally unstaged
- Pointer to backlog 999.5 (i) + (j) annotations in ROADMAP.md
- Note that `supabase db push` was NOT run by this plan — applying migration 20260509001 to the remote DB is an out-of-band step the user runs when ready, but the iOS-side fixes (commits B and C) are independent of the migration's deploy state and ship value immediately on the next build.
</output>
