-- Phase 22: create private 'videos' storage bucket + RLS (D-12, D-17, D-31).
-- Bucket layout mirrors Phase 13 documents (D-17): path prefix is org_id UUID,
-- enforced by storage.foldername(name)[1]::uuid ∈ user_orgs at RLS level.
-- Threat T-22-01-04 (cross-org path access) mitigated by RLS + unguessable UUIDs.
-- Threat T-22-01-06 (MIME spoofing) mitigated by allowed_mime_types + worker re-validation.
-- Threat T-22-01-07 (DoS via oversized upload) mitigated by 2 GB file_size_limit (D-31).
-- Service-role (ffmpeg worker, retention cron) bypasses these policies.

-- Create private videos bucket. 2 GB = 2147483648 bytes (D-31).
-- Allowed mime types:
--   video/mp4, video/quicktime, video/x-m4v  — user raw uploads (D-31)
--   application/vnd.apple.mpegurl            — HLS manifest written by ffmpeg worker
--   video/mp2t                               — HLS segment (.ts) written by worker
--   image/jpeg                               — poster / thumbnail written by worker
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'videos',
  'videos',
  false,
  2147483648,
  array[
    'video/mp4',
    'video/quicktime',
    'video/x-m4v',
    'application/vnd.apple.mpegurl',
    'video/mp2t',
    'image/jpeg'
  ]
)
on conflict (id) do nothing;

-- SELECT: org members can read any object whose first path segment is their org_id
create policy "videos: org members can read"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'videos'
    and (storage.foldername(name))[1]::uuid in (
      select org_id from user_orgs where user_id = auth.uid()
    )
  );

-- INSERT: org members can upload raw files under their own org prefix
create policy "videos: org members can upload raw"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'videos'
    and (storage.foldername(name))[1]::uuid in (
      select org_id from user_orgs where user_id = auth.uid()
    )
  );

-- DELETE: org members can delete objects in their org (service_role handles retention)
create policy "videos: org members can delete own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'videos'
    and (storage.foldername(name))[1]::uuid in (
      select org_id from user_orgs where user_id = auth.uid()
    )
  );

-- Note: service_role bypasses RLS and is used by:
--   1. ffmpeg worker (writes HLS manifest + segments + poster after transcode)
--   2. retention cron in plan 22-10 (deletes expired objects per retention_expires_at)
-- Both must supply the org_id prefix when writing/deleting; the storage layer itself
-- does not enforce it for service_role, so those code paths carry the contract.
