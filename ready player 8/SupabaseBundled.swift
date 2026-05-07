import Foundation

// MARK: - Bundled Supabase configuration (production defaults)
//
// 2026-05-07: every end-user iPhone needs to talk to the SAME Supabase
// project (constructionos / nzdbphddnrfybwecvsvq). These values are baked
// into the app at build time so users never see the "Configure Backend"
// sheet on first launch -- they just sign up / sign in with email + password.
//
// SECURITY NOTE: the anon key is PUBLIC by design. It identifies the app
// to Supabase but grants no privileges beyond what RLS policies allow for
// the `anon` and `authenticated` roles. Per-user data isolation comes from
// each user's auth session (their JWT), not from this key. RLS audit
// (Phase 21+22+29 + multi-tenancy migrations 20260413001/20260428002..006)
// confirms 47/48 cs_* tables have explicit policies enforcing
// user_id = auth.uid() OR org_id IN user's orgs.
//
// The service-role key (which DOES bypass RLS) is NEVER bundled. It lives
// only in Edge Function secrets on Supabase's servers (notifications-fanout,
// cert-expiry-scan, etc.).
//
// To rotate this anon key: dashboard -> Project Settings -> API ->
// "Reset anon key" (this also invalidates all client sessions; rare op).

enum SupabaseBundled {
    /// Production Supabase project URL (apex). Never includes path or trailing slash.
    static let baseURL = "https://nzdbphddnrfybwecvsvq.supabase.co"

    /// Production anon (public) JWT. Safe to embed -- per security note above.
    /// Decoded payload: {iss:supabase, ref:nzdbphddnrfybwecvsvq, role:anon,
    /// iat:1775070633, exp:2090646633} -- expires year 2036.
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56ZGJwaGRkbnJmeWJ3ZWN2c3ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUwNzA2MzMsImV4cCI6MjA5MDY0NjYzM30.Z2ojly1dvq--BjEt56-QC-Xh3KJ3fhAsuhkwysn5aDI"
}
