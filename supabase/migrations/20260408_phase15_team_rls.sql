-- Phase 15 RLS — scope via cs_project_members membership
alter table cs_team_members         enable row level security;
alter table cs_project_assignments  enable row level security;
alter table cs_certifications       enable row level security;
alter table cs_daily_crew           enable row level security;

-- cs_team_members: any authenticated user may read; mutations by authenticated (v1 permissive, matches Phase 13)
create policy cs_team_members_select on cs_team_members for select to authenticated using (true);
create policy cs_team_members_write  on cs_team_members for all    to authenticated using (true) with check (true);

-- cs_project_assignments: visible to project members; mutations by project members
create policy cs_project_assignments_select on cs_project_assignments for select to authenticated
  using (exists (select 1 from cs_project_members m where m.project_id = cs_project_assignments.project_id and m.user_id = auth.uid()));
create policy cs_project_assignments_write on cs_project_assignments for all to authenticated
  using (exists (select 1 from cs_project_members m where m.project_id = cs_project_assignments.project_id and m.user_id = auth.uid()))
  with check (exists (select 1 from cs_project_members m where m.project_id = cs_project_assignments.project_id and m.user_id = auth.uid()));

-- cs_certifications: visible to (a) member's linked user, (b) any user with active assignment touching the member
create policy cs_certifications_select on cs_certifications for select to authenticated
  using (
    exists (select 1 from cs_team_members tm where tm.id = cs_certifications.member_id and tm.user_id = auth.uid())
    or exists (
      select 1 from cs_project_assignments pa
      join cs_project_members m on m.project_id = pa.project_id
      where pa.member_id = cs_certifications.member_id and m.user_id = auth.uid()
    )
  );
create policy cs_certifications_write on cs_certifications for all to authenticated
  using (true) with check (true);

-- cs_daily_crew: visible + writable to project members
create policy cs_daily_crew_select on cs_daily_crew for select to authenticated
  using (exists (select 1 from cs_project_members m where m.project_id = cs_daily_crew.project_id and m.user_id = auth.uid()));
create policy cs_daily_crew_write on cs_daily_crew for all to authenticated
  using (exists (select 1 from cs_project_members m where m.project_id = cs_daily_crew.project_id and m.user_id = auth.uid()))
  with check (exists (select 1 from cs_project_members m where m.project_id = cs_daily_crew.project_id and m.user_id = auth.uid()));
