-- Phase 16: Field Tools — Step 1 of 2
-- Extend cs_entity_type enum to support new field entity types.
-- MUST be its own migration: Postgres forbids using a newly-added enum value
-- in the same transaction that adds it (see Phase 16 RESEARCH §2).

ALTER TYPE cs_entity_type ADD VALUE IF NOT EXISTS 'daily_log';
ALTER TYPE cs_entity_type ADD VALUE IF NOT EXISTS 'safety_incident';
ALTER TYPE cs_entity_type ADD VALUE IF NOT EXISTS 'punch_item';
