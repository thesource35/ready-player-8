---
id: SEED-002
status: dormant
planted: 2026-04-22
planted_during: v2.1 Gap Closure — end of Phase 21
trigger_when: International expansion milestone, OR a "compliance / regulatory" milestone, OR a "knowledge-base" or "postgres-brain" milestone
scope: large
---

# SEED-002: Global Construction Framework — Postgres-Brain Building Code Knowledge Base

## Why This Matters

User raised this during Phase 21: implementing a global construction framework requires
adhering to **local, site-specific building codes** rather than a single universal standard.
Primary construction types (wood-frame in North America/Japan, concrete/masonry in
Europe/Africa, steel-frame globally) each comply with local/national regulations
(Eurocodes, Indian NBC) or adopted international standards.

ConstructionOS today is implicitly US-centric. To serve international contractors —
or even multi-jurisdictional US contractors crossing state lines — the app needs a
**structured, queryable knowledge base of building codes per jurisdiction**, with
identifiers the rest of the app (Projects, Contracts, Angelic AI chat, Compliance
checks) can reference consistently.

The user framed this as a "postgres brain":
1. **Schema** — tables + columns modeling jurisdiction, code corpus, code clause, amendment, adoption
2. **Loading order** — deterministic, idempotent ingest (codes change, jurisdictions update adoptions, clauses get amended)
3. **One sync per data source** — every source (ICC, Eurocodes, Indian NBC, state amendments, city amendments) gets exactly one sync job with its own schedule + provenance tracking

This pattern is the right abstraction for the whole app, not just building codes —
same "postgres brain" shape would serve OSHA rules, ASHRAE standards, material
spec databases, trade-union pay scales, etc.

## When to Surface

**Trigger:** Any milestone involving:
- International expansion or multi-jurisdiction contractor support
- Compliance features (Compliance tab, inspection workflows, permit tracking)
- AI assistant (Angelic AI) upgrades that need grounded code citations
- "Knowledge base" / "postgres brain" / "code citations" scope
- A move toward a multi-tenant SaaS where each tenant is a different jurisdiction

This seed should be presented during `/gsd-new-milestone` when the milestone scope
matches any of these conditions:
- Mentions "building code", "compliance", "jurisdiction", "international", "regulatory"
- Mentions "knowledge base", "RAG", "AI grounding", "citations"
- Mentions "postgres brain" or "canonical data"
- Milestone would ship into a non-US market

## Scope Estimate

**Large** — a full milestone, likely 4-6 phases:

1. **Schema design** — `cs_jurisdictions`, `cs_code_corpora`, `cs_code_clauses`,
   `cs_code_amendments`, `cs_jurisdiction_adoptions` (join: which jurisdiction adopted
   which corpus + amendments + effective dates). Include `provenance` (source URL,
   fetched_at, checksum) on every row for audit and re-sync idempotency.
2. **Loading order contract** — deterministic topological load: corpora before adoptions,
   adoptions before amendments; every row carries a `source_id` FK to the sync job that
   produced it. Re-sync writes new rows + marks old rows `superseded_by` (tamper-proof,
   append-only pattern already used in `cs_equipment_locations`).
3. **Per-source sync jobs** — one sync job per source (`sync_icc_irc`, `sync_eurocodes`,
   `sync_indian_nbc`, `sync_ca_title24`, etc). Each sync runs on its own cadence, owns
   its own source rows, and never touches rows owned by another sync. This is the
   "one sync per data source" constraint the user specified.
4. **Query layer** — typed accessors: `getApplicableCodes(jurisdiction_id, construction_type, effective_date)`.
   Handles jurisdictional overlay (state amends federal, city amends state).
5. **AI integration** — Angelic AI chat can cite clauses by canonical ID (e.g. `IRC-2021 §R301.1`)
   and link back to the source corpus.
6. **UI surfaces** — Compliance tab panels showing applicable codes per project based on
   project location + construction type; PDF export with citation trail.

## Breadcrumbs

Related code and decisions in the current codebase:

- Existing "brain"-shaped patterns:
  - `supabase/migrations/20260412001_phase21_equipment_tables.sql` — append-only + provenance columns pattern
  - `supabase/migrations/20260412002_phase21_equipment_rls.sql` — RLS by org_id pattern (jurisdictions likely need similar isolation)
- Existing AI integration points:
  - `ready player 8/AngelicAIView.swift` (Anthropic Claude API, `claude-haiku-4-5-20251001`)
  - `web/src/app/api/chat/route.ts` (server-side streaming)
  - These will need tool-use wiring to query the postgres brain during response generation
- Existing jurisdictional touchpoints (shallow):
  - `ready player 8/ContentView.swift` — Projects model has `location` field, not structured jurisdiction
  - `web/src/lib/supabase/types.ts` — `Project` type same shape
- Phase 21 D-09 precedent: server-boundary policy lookups based on config state —
  jurisdiction-aware UI gating would follow the same pattern

## Notes

User's exact framing: "i need a postgres brain: 1. schema <table + columns> 2. loading order 3. one sync per data source"

The three-part framing is itself the design contract. Any implementation that doesn't
satisfy all three is incomplete. Specifically:
- **Schema first** — no ad-hoc JSONB dumps; every code clause gets a typed row with canonical IDs
- **Loading order is part of the schema** — topological FK chain + append-only semantics enforce order at the DB level, not the sync job
- **One sync per source** — no shared mutation paths; each sync owns its rows; re-running sync N must be a no-op if source content unchanged (checksum-based idempotency)

International construction types mentioned by user (surface in code-type taxonomy):
- **Wood-frame** — common in North America, Japan; codes: IRC (US), Japanese Wood Frame Construction Act
- **Concrete/masonry** — common in Europe, Africa; codes: Eurocode 2, Eurocode 6
- **Steel-frame** — global; codes: Eurocode 3, AISC 360 (US), IS 800 (India)

Adopted international standards commonly referenced: **ISO 6707** (building and civil
engineering vocabulary), **ISO 19650** (information management for BIM).

This seed pairs well with (but is distinct from) any future AI RAG upgrade —
the postgres brain IS the retrieval corpus for jurisdictional grounding.
