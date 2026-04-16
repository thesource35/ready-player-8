// Phase 22 ffmpeg worker — Supabase service-role client.
// Bypasses RLS by design: the worker is a trusted server-side component that must
// read the raw upload blob and overwrite the row status. The worker is only reachable
// via X-Worker-Secret HMAC from the DB trigger (22-01) or the Fly.io internal network.

import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { config } from './config.js'

export const supabase: SupabaseClient = createClient(
  config.supabaseUrl,
  config.supabaseServiceRoleKey,
  {
    auth: { persistSession: false, autoRefreshToken: false },
  },
)
