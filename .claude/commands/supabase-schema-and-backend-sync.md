---
name: supabase-schema-and-backend-sync
description: Workflow command scaffold for supabase-schema-and-backend-sync in ready-player-8.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /supabase-schema-and-backend-sync

Use this workflow when working on **supabase-schema-and-backend-sync** in `ready-player-8`.

## Goal

Adds or updates database tables and synchronizes backend models/services, ensuring schema and code are in sync.

## Common Files

- `docs/supabase-schema.sql`
- `ready player 8/SupabaseService.swift`
- `ready player 8/SupabaseCRUDWiring.swift`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Edit docs/supabase-schema.sql to add or update tables.
- Update or create corresponding DTOs and backend sync logic in ready player 8/SupabaseService.swift or related files.
- Enable RLS and set up policies as needed.
- Wire up new tables to app panels or sync managers.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.