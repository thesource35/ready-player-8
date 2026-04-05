# Supabase Migrations

## Running Migrations

Migrations are in `migrations/` and must be run in filename order.

### Prerequisites
- Supabase project with Auth enabled
- At least one user account created (for backfill migration)

### Order
1. `20260405000001_add_user_id_columns.sql` — Adds user_id column to any table missing it
2. `20260405000002_backfill_user_id.sql` — Assigns existing rows to the first registered user
3. `20260405000003_enable_rls_policies.sql` — Enables RLS and creates per-user access policies

### Running via Supabase CLI
```bash
supabase db push
```

### Running manually
Execute each file in order via the Supabase SQL Editor (Dashboard > SQL Editor).

### CRITICAL: Migration Order
**NEVER** enable RLS (migration 3) before running the backfill (migration 2).
Enabling RLS on a table where rows have no valid user_id makes those rows invisible to all users.
