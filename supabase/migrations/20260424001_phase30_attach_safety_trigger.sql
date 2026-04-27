-- Phase 30 follow-up: attach emit_activity_event_trg to tables created after Phase 14
--
-- Phase 14 (20260407_phase14_notifications.sql) hardcoded the source_tables array
-- to the 5 tables that existed at that time. cs_safety_incidents + cs_submittals
-- were explicitly deferred (per Phase 14 SCHEMA-AUDIT footer).
--
-- Phase 26 (20260418002_phase26_stub_entity_tables.sql) later created
-- cs_safety_incidents and cs_submittals but did NOT re-run the trigger attach
-- loop. Without this follow-up, an INSERT into cs_safety_incidents does not
-- produce a cs_activity_events row, which means no notification, no push,
-- and Phase 30 NOTIF-05 UAT Category 2 (safety_alert) would not fire.
--
-- Pattern mirrors the Phase 14 attach block verbatim — conditional on
-- pg_tables existence so the migration is safe to re-run.

do $$
declare
  t text;
  source_tables text[] := array[
    'cs_safety_incidents',
    'cs_submittals'
  ];
begin
  foreach t in array source_tables loop
    if exists (select 1 from pg_tables where schemaname = 'public' and tablename = t) then
      execute format('drop trigger if exists emit_activity_event_trg on %I', t);
      execute format($f$
        create trigger emit_activity_event_trg
        after insert or update or delete on %I
        for each row execute function emit_activity_event()
      $f$, t);
    end if;
  end loop;
end $$;
