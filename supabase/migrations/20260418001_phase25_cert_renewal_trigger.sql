-- Phase 25: Certification Expiry Notifications
-- Creates emit_cert_renewal_event() trigger function for cert renewal activity events
-- Creates cleanup_cert_notifications() trigger function for orphaned notification cleanup
--
-- Decisions: D-30 (cert renewal emits activity event), D-32 (cert deleted mid-escalation cleanup)
-- D-34 (delivery_channels in payload for channel-agnostic fanout)
-- Threat mitigations: T-25-05 (trigger fires on legitimate UPDATE only; RLS prevents unauthorized writes)

-- =============================================================================
-- emit_cert_renewal_event() -- fires when cert status flips to 'active' (renewal)
-- =============================================================================
CREATE OR REPLACE FUNCTION emit_cert_renewal_event()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM 'active' AND NEW.status = 'active' THEN
    INSERT INTO cs_activity_events (project_id, entity_type, entity_id, action, category, summary, payload)
    SELECT pa.project_id, 'certifications', NEW.id, 'UPDATE', 'assigned_task',
           'Certification renewed: ' || NEW.name,
           jsonb_build_object(
             'detail', 'cert_renewed',
             'cert_id', NEW.id,
             'cert_name', NEW.name,
             'member_id', NEW.member_id,
             'expires_at', NEW.expires_at,
             'delivery_channels', jsonb_build_array('push', 'inbox')
           )
    FROM cs_project_assignments pa
    WHERE pa.member_id = NEW.member_id AND pa.status = 'active'
    LIMIT 1;
  END IF;
  RETURN NEW;
END;
$$;

-- =============================================================================
-- Attach renewal trigger to cs_certifications
-- =============================================================================
DROP TRIGGER IF EXISTS trg_cert_renewal_event ON cs_certifications;
CREATE TRIGGER trg_cert_renewal_event
  AFTER UPDATE ON cs_certifications
  FOR EACH ROW
  EXECUTE FUNCTION emit_cert_renewal_event();

-- =============================================================================
-- cleanup_cert_notifications() -- marks orphaned notifications as dismissed
-- when a cert is deleted mid-escalation (D-32)
-- =============================================================================
CREATE OR REPLACE FUNCTION cleanup_cert_notifications()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  UPDATE cs_notifications
  SET dismissed_at = now()
  WHERE entity_type = 'certifications'
    AND entity_id = OLD.id
    AND dismissed_at IS NULL;
  RETURN OLD;
END;
$$;

-- =============================================================================
-- Attach cleanup trigger to cs_certifications
-- =============================================================================
DROP TRIGGER IF EXISTS trg_cleanup_cert_notifications ON cs_certifications;
CREATE TRIGGER trg_cleanup_cert_notifications
  BEFORE DELETE ON cs_certifications
  FOR EACH ROW
  EXECUTE FUNCTION cleanup_cert_notifications();
