---
id: SEED-003
status: dormant
planted: 2026-04-22
planted_during: v2.1 Gap Closure — end of Phase 21
trigger_when: Any milestone that adds a new data source (cameras, sensors, IoT, third-party feeds) OR a schema-refactor milestone OR international/multi-jurisdiction expansion
scope: large
---

# SEED-003: Unified Data-Fusion Ontology (Palantir-Style Foundry Pattern)

## Why This Matters

ConstructionOS today accretes tables per feature: `cs_equipment_locations`,
`cs_photos`, `cs_safety_incidents`, `cs_contracts`, etc. Each table is its own
silo with its own id space. When a user asks "show me everything happening at
1234 Broadway right now" the app has to union-query eight tables with eight
different join keys — and that gets worse with every new data source.

Palantir Foundry / Gotham solves this with an **ontology-first architecture**:
every data source attaches to a canonical entity, and sources are "observations"
of that entity, not the entity itself. A **location** is the entity; a DOT camera,
a satellite tile, a user photo, a safety incident, and an equipment check-in are
all observations of that location. Query once per entity, fuse many streams at
read time.

User raised this during Phase 21 close (2026-04-22): "Palantir Technologies use
the same technology for the sat feed and dot camera for traffic." That's the
pattern — the core insight is that it extends far past cameras. **Every future
data source we add should attach to the ontology instead of spawning a new silo.**

This seed is foundational. It shapes:
- SEED-001 (DOT cameras) — becomes an observation type, not a standalone table
- SEED-002 (postgres-brain building codes) — "jurisdiction" is an entity, code clauses/amendments/inspections are observations
- Phase 22 HLS video feeds — retrofit to become observations of a project-location entity
- Future IoT sensor work, drone capture, wearable-device telemetry — all become observation types on existing entities

## When to Surface

**Trigger:** Any milestone that:
- Adds a new primary data source (camera feed, sensor, IoT, third-party API)
- Proposes a new top-level table for geospatial or time-series data
- Requires cross-feature queries ("show me everything at X location", "show me all activity by crew Y")
- Involves schema refactoring or a "rewrite the data model" discussion
- Ships international / multi-jurisdiction support (each jurisdiction is an entity)

This seed should be presented during `/gsd-new-milestone` when the milestone scope
matches any of these conditions:
- Mentions "unified view", "data fusion", "single pane", "ontology", "entity resolution"
- Mentions "add a new data source" or "ingest from X"
- Mentions "cross-source query" or "location-first query"
- Schema-level refactor or foundation work

**Important:** This seed should be considered as a prerequisite or companion to
SEED-001 and SEED-002 when those surface. Building either one without this
foundation risks re-siloing data. Ideally SEED-003 lands *before* SEED-001 and
SEED-002, though it can also be retrofit.

## Scope Estimate

**Large** — a foundational milestone, likely 5-8 phases:

1. **Core ontology schema** — `cs_entities` (polymorphic entity types: `location`,
   `jurisdiction`, `project`, `crew`, `equipment_asset`, `contract`), `cs_observations`
   (polymorphic observation types with JSONB payload + typed `observation_type`
   discriminator), `cs_observation_sources` (provenance: which sync/sync-job produced
   the observation), `cs_entity_relationships` (location contains project, project
   employs crew, etc.)
2. **Entity resolution** — dedup + merge: two sources describing the same intersection
   (a DOT cam feed says lat/lng, a Mapbox address geocoder says address) resolve to
   the same `cs_entities` row. Uses deterministic hash + probabilistic matching for
   fuzzy cases.
3. **Observation ingest pipeline** — one pipeline abstraction, many adapters: each
   data source has an adapter that emits `{entity_ref, observation_type, payload, source_id, observed_at}`
   tuples. Ingest layer is content-agnostic.
4. **Query layer** — typed accessors: `getEntity(id)`, `getObservations(entity_id, types[], since)`,
   `getEntitiesInBounds(bbox, types[])`. Hide the polymorphic storage from callers.
5. **Retrofit existing tables** — map `cs_equipment_locations` to become observations
   of equipment-asset entities at location entities; map `cs_photos` similarly; etc.
   Use append-only views so legacy code doesn't break during migration.
6. **UI surfaces** — one map, one timeline, one entity-detail panel that can render
   any entity with any observation set. Replaces the per-feature map/timeline/panel
   code scattered across the app today.
7. **AI grounding** — Angelic AI chat queries the ontology (not individual tables).
   "What's happening at Project Alpha?" becomes one query against the project entity.
8. **Source management** — admin UI to list all data sources, their sync health, and
   the observations they've produced. Directly serves SEED-002's "one sync per data
   source" contract.

## Breadcrumbs

Related code and decisions in the current codebase:

- Append-only + provenance precedent (Phase 21):
  - `supabase/migrations/20260412001_phase21_equipment_tables.sql` — `cs_equipment_locations` is already shaped like an observation stream (append-only, timestamped, tamper-proof). This is the pattern to generalize.
- Existing silo'd tables that would retrofit as observations:
  - `cs_projects`, `cs_contracts`, `cs_equipment`, `cs_equipment_locations`, `cs_market_data`, `cs_ai_messages`, `cs_wealth_*`, `cs_ops_*`, `cs_field_*`
  - Per `CLAUDE.md` Data layer section: `SupabaseCRUDWiring.swift` (DataSyncManager) already has a generic sync helper — this would become the ingest pipeline's iOS front.
- Cross-cutting consumers that today union-query silos:
  - `web/src/app/maps/page.tsx` — unions equipment + photos + routes + crews
  - `ready player 8/MapsView.swift` — same on iOS
  - `web/src/app/api/chat/route.ts` — Angelic AI server pulls "live project/contract data" into system prompt by stitching tables
- Seed companions:
  - **SEED-001** (DOT cameras) — camera becomes `observation_type: 'dot_camera_frame'` on a `location` entity
  - **SEED-002** (postgres-brain building codes) — jurisdiction becomes an entity, code clauses/amendments are observations with provenance

## Notes

User's framing: "Palantir Technologies use the same technology for the sat feed
and dot camera for traffic" — the ontology pattern unifying satellite tiles and
street-level cameras under one query surface is precisely the Palantir Foundry
approach. Worth naming explicitly in design docs for future readers.

**Architectural consequences to think through during discuss-phase:**

- **Schema cost:** Polymorphic JSONB observations lose type safety. Mitigate with
  strict per-observation-type schemas (zod/JSON-schema validation at ingest) and
  typed query accessors that cast on read.
- **Query cost:** Single-table observation scans can be slow. Mitigate with
  per-observation-type materialized views or typed sub-tables with a shared parent
  (Postgres inheritance). Phase 21's `cs_equipment_latest_positions` DISTINCT ON
  view pattern is the right primitive.
- **Migration cost:** Retrofitting 20+ silo tables is a large undertaking. Do it
  incrementally: map one silo at a time, keep legacy reads working via views until
  all callers migrate.
- **Ontology governance:** Adding a new entity type or observation type should
  require explicit review (these are API-like commitments). Consider a
  `cs_ontology_registry` table + migrations-only path for additions.

**Palantir-isms worth stealing:**

- Foundry's **object types** → our `entity_type`
- Foundry's **links** → our `cs_entity_relationships` with typed `relationship_type`
- Foundry's **datasets as immutable branches** → our append-only observation streams with `source_id` lineage
- Foundry's **ontology + actions** separation → we'd split read-path (observations, typed queries) from write-path (domain actions: check-in equipment, close contract, resolve safety incident). Actions produce observations.

**Not stealing from Palantir:**
- Foundry's frontend/workspace layer — too heavy for a construction app
- Gotham's investigative/analyst tooling — out of scope for contractors

**Ordering relative to SEED-001 and SEED-002:**

Prefer to land SEED-003 first if possible — DOT cameras and building codes both
retrofit more cheaply onto an existing ontology than each inventing its own
schema. If the timing is wrong (SEED-001 or SEED-002 surfaces before SEED-003's
milestone is planned), flag the retrofit cost during that plan's discuss-phase
and either (a) hold it until SEED-003 lands, or (b) implement the silo version
with the explicit contract that it will be migrated to observations later.
