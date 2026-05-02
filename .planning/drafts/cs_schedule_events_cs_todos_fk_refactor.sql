-- DRAFT MIGRATION — DO NOT APPLY UNTIL REVIEWED + APPROVED.
--
-- Author: drafted 2026-05-02 by AI session.
-- Status: NOT in supabase/migrations/ yet on purpose. Move + rename to
--         supabase/migrations/<YYYYMMDDXXX>_cs_todos_schedule_fk_refactor.sql
--         only after the open questions below are answered.
--
-- Goal: convert text-based soft references on cs_todos and cs_schedule_events
-- to real UUID foreign keys so these tables can switch from user-personal
-- RLS to proper org-scoped RLS (matching the rest of the multi-tenancy
-- migration series shipped 2026-04-28).
--
-- Source-of-truth audit (per 20260428006 closing notes):
--   cs_schedule_events:
--     - project_ref text         -> should become project_id uuid FK to cs_projects(id)
--     - attendees   text[]       -> should become a junction table cs_event_attendees
--     - user_id     uuid         -> already correct, kept as creator/owner
--   cs_todos:
--     - project_ref text         -> project_id uuid FK to cs_projects(id)
--     - assigned_to text         -> assigned_user_id uuid FK to auth.users(id)
--     - user_id     uuid         -> already correct, kept as creator/owner
--
-- Approach: ADDITIVE. Add new uuid columns alongside the existing text columns.
-- Backfill where text is castable to uuid; leave NULL otherwise. Add FKs.
-- Update RLS to use the new columns when present, fall back to user_id when not.
-- Do NOT drop the old text columns in this migration — defer to a future
-- migration once iOS clients have migrated to writing the new columns.
--
-- =============================================================================
-- OPEN QUESTIONS (must be answered before applying)
-- =============================================================================
--
-- Q1: How many existing rows have project_ref / assigned_to populated, and what
--     fraction are uuid-castable vs free-form text? Run on prod:
--       select count(*) total,
--              count(*) filter (where project_ref ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') uuid_like
--         from cs_todos;
--     If most existing values are NOT uuid-castable, the backfill is mostly
--     NULL and existing iOS users would lose project linkage. Need a UI/flow
--     to re-link manually or a richer text->uuid mapping.
--
-- Q2: For cs_schedule_events.attendees text[] — are existing values email-like
--     strings, free-form names, or already user_ids? If emails, we can join to
--     auth.users on email. If free-form, no migration possible — add the
--     junction table empty.
--
-- Q3: Should the org-scoped RLS continue to allow the row's user_id (creator)
--     full control independent of org membership? E.g., the creator can always
--     see their own todo even if they leave the org. Recommended: YES, fall
--     back to user_id = auth.uid() OR org via project_id chain.
--
-- Q4: Cascade behavior — if a project is deleted, what happens to its todos
--     and schedule_events? Current policy on Group B tables: ON DELETE CASCADE
--     for project_id. Same here? Or RESTRICT to prevent accidental data loss?
--
-- =============================================================================
-- 1. cs_todos — add uuid columns
-- =============================================================================

alter table cs_todos
  add column if not exists project_id uuid references cs_projects(id) on delete set null,
  add column if not exists assigned_user_id uuid references auth.users(id) on delete set null;

create index if not exists cs_todos_project_idx on cs_todos(project_id);
create index if not exists cs_todos_assigned_user_idx on cs_todos(assigned_user_id);

-- Backfill: copy text -> uuid where the text value is uuid-shaped.
-- The regex tolerates upper/lower case hex.
update cs_todos
   set project_id = project_ref::uuid
 where project_id is null
   and project_ref is not null
   and project_ref ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

update cs_todos
   set assigned_user_id = assigned_to::uuid
 where assigned_user_id is null
   and assigned_to is not null
   and assigned_to ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- =============================================================================
-- 2. cs_schedule_events — add project_id; attendees handled separately
-- =============================================================================

alter table cs_schedule_events
  add column if not exists project_id uuid references cs_projects(id) on delete set null;

create index if not exists cs_schedule_events_project_idx on cs_schedule_events(project_id);

update cs_schedule_events
   set project_id = project_ref::uuid
 where project_id is null
   and project_ref is not null
   and project_ref ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- =============================================================================
-- 3. cs_event_attendees junction table (new)
-- =============================================================================

create table if not exists cs_event_attendees (
  event_id uuid not null references cs_schedule_events(id) on delete cascade,
  user_id  uuid not null references auth.users(id) on delete cascade,
  role     text not null default 'attendee' check (role in ('organizer', 'attendee', 'optional')),
  responded_at timestamptz null,
  response text null check (response is null or response in ('accepted', 'declined', 'tentative')),
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

create index if not exists cs_event_attendees_user_idx on cs_event_attendees(user_id);

alter table cs_event_attendees enable row level security;

-- An attendee can see their own attendance row.
-- The event creator (user_id on cs_schedule_events) can see all attendee rows
-- for their events. Org-scoped extensions deferred until Q3 is answered.
drop policy if exists cs_event_attendees_select on cs_event_attendees;
create policy cs_event_attendees_select on cs_event_attendees for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from cs_schedule_events e
       where e.id = cs_event_attendees.event_id
         and e.user_id = auth.uid()
    )
  );

drop policy if exists cs_event_attendees_insert on cs_event_attendees;
create policy cs_event_attendees_insert on cs_event_attendees for insert to authenticated
  with check (
    exists (
      select 1 from cs_schedule_events e
       where e.id = cs_event_attendees.event_id
         and e.user_id = auth.uid()
    )
  );

drop policy if exists cs_event_attendees_update on cs_event_attendees;
create policy cs_event_attendees_update on cs_event_attendees for update to authenticated
  using (user_id = auth.uid());  -- only the attendee themselves can RSVP

drop policy if exists cs_event_attendees_delete on cs_event_attendees;
create policy cs_event_attendees_delete on cs_event_attendees for delete to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from cs_schedule_events e
       where e.id = cs_event_attendees.event_id
         and e.user_id = auth.uid()
    )
  );

-- =============================================================================
-- 4. RLS upgrade — cs_todos and cs_schedule_events from user-personal to
--    "user-personal OR project-org-scoped"
-- =============================================================================
--
-- Important: this REPLACES the policies set up by 20260428006_group_d_residue_*.
-- Existing rows with NULL project_id continue to work via the user_id branch.

-- ---- cs_todos ----

drop policy if exists cs_todos_select on cs_todos;
drop policy if exists cs_todos_insert on cs_todos;
drop policy if exists cs_todos_update on cs_todos;
drop policy if exists cs_todos_delete on cs_todos;

create policy cs_todos_select on cs_todos for select to authenticated
  using (
    user_id = auth.uid()
    or assigned_user_id = auth.uid()
    or (project_id is not null and project_id in (
      select id from cs_projects where org_id in (
        select org_id from user_orgs where user_id = auth.uid()
      )
    ))
  );

create policy cs_todos_insert on cs_todos for insert to authenticated
  with check (
    user_id = auth.uid()
    -- WITH CHECK on org branch: if a project_id is set, the user must be in
    -- the project's org. Prevents writing into another org's todos.
    and (project_id is null or project_id in (
      select id from cs_projects where org_id in (
        select org_id from user_orgs where user_id = auth.uid()
      )
    ))
  );

create policy cs_todos_update on cs_todos for update to authenticated
  using (
    user_id = auth.uid()
    or assigned_user_id = auth.uid()
    or (project_id is not null and project_id in (
      select id from cs_projects where org_id in (
        select org_id from user_orgs where user_id = auth.uid()
      )
    ))
  );

create policy cs_todos_delete on cs_todos for delete to authenticated
  using (
    user_id = auth.uid()  -- only creator can delete
    or (project_id is not null and project_id in (
      select id from cs_projects where org_id in (
        select org_id from user_orgs
         where user_id = auth.uid() and role in ('owner', 'admin')
      )
    ))
  );

-- ---- cs_schedule_events ----

drop policy if exists cs_schedule_events_select on cs_schedule_events;
drop policy if exists cs_schedule_events_insert on cs_schedule_events;
drop policy if exists cs_schedule_events_update on cs_schedule_events;
drop policy if exists cs_schedule_events_delete on cs_schedule_events;

create policy cs_schedule_events_select on cs_schedule_events for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from cs_event_attendees a
       where a.event_id = cs_schedule_events.id and a.user_id = auth.uid()
    )
    or (project_id is not null and project_id in (
      select id from cs_projects where org_id in (
        select org_id from user_orgs where user_id = auth.uid()
      )
    ))
  );

create policy cs_schedule_events_insert on cs_schedule_events for insert to authenticated
  with check (
    user_id = auth.uid()
    and (project_id is null or project_id in (
      select id from cs_projects where org_id in (
        select org_id from user_orgs where user_id = auth.uid()
      )
    ))
  );

create policy cs_schedule_events_update on cs_schedule_events for update to authenticated
  using (
    user_id = auth.uid()
    or (project_id is not null and project_id in (
      select id from cs_projects where org_id in (
        select org_id from user_orgs where user_id = auth.uid()
      )
    ))
  );

create policy cs_schedule_events_delete on cs_schedule_events for delete to authenticated
  using (
    user_id = auth.uid()
    or (project_id is not null and project_id in (
      select id from cs_projects where org_id in (
        select org_id from user_orgs
         where user_id = auth.uid() and role in ('owner', 'admin')
      )
    ))
  );

-- =============================================================================
-- iOS side (separate change, not in this SQL file)
-- =============================================================================
--
-- 1. Update SupabaseService DTOs:
--      SupabaseScheduleEvent: add `projectId: UUID?` (Codable key project_id)
--      SupabaseTodo:          add `projectId: UUID?` and `assignedUserId: UUID?`
--    Keep the existing `projectRef: String?` / `assignedTo: String?` properties
--    so old code keeps working during the transition.
--
-- 2. Update CalendarView / TodosView writers to populate BOTH the old text
--    field AND the new uuid field on insert/update. Reads can prefer the uuid
--    column when non-null, fall back to text otherwise.
--
-- 3. Add a Vitest-style integration test (web/src/__tests__/multi-tenancy/)
--    or extend rls-isolation.test.ts to verify the org-scoped predicate works
--    for cs_todos: User A creates a todo in their project → User B in same org
--    sees it via the project_id chain → User C in different org does NOT see it.
--
-- 4. Future migration (separate file, separate session):
--      - Drop the old text columns once iOS clients have all migrated
--      - Optionally enforce NOT NULL on project_id (for new rows)
