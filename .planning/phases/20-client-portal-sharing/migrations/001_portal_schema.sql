-- ============================================================
-- Phase 20: Client Portal & Sharing -- Schema Migration
-- ============================================================

-- 1. Extend cs_report_shared_links with link_type (D-97)
ALTER TABLE cs_report_shared_links
  ADD COLUMN IF NOT EXISTS link_type text NOT NULL DEFAULT 'report'
    CHECK (link_type IN ('report', 'portal'));

-- 2. Portal configuration per link (D-97)
CREATE TABLE IF NOT EXISTS cs_portal_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  link_id uuid NOT NULL REFERENCES cs_report_shared_links(id) ON DELETE CASCADE,
  project_id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id uuid,
  slug text NOT NULL,
  company_slug text NOT NULL,
  template text NOT NULL DEFAULT 'full_progress'
    CHECK (template IN ('executive_summary', 'full_progress', 'photo_update')),
  sections_config jsonb NOT NULL DEFAULT '{}'::jsonb,
  show_exact_amounts boolean NOT NULL DEFAULT false,
  welcome_message text,
  section_notes jsonb DEFAULT '{}'::jsonb,
  pinned_items jsonb DEFAULT '{}'::jsonb,
  date_ranges jsonb DEFAULT '{}'::jsonb,
  watermark_enabled boolean NOT NULL DEFAULT false,
  powered_by_enabled boolean NOT NULL DEFAULT false,
  client_email text,
  is_deleted boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(company_slug, slug)
);

-- 3. Company branding (D-73)
CREATE TABLE IF NOT EXISTS cs_company_branding (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_name text NOT NULL DEFAULT '',
  logo_light_path text,
  logo_dark_path text,
  favicon_path text,
  cover_image_path text,
  theme_config jsonb NOT NULL DEFAULT '{}'::jsonb,
  font_family text NOT NULL DEFAULT 'Inter',
  custom_css text,
  contact_info jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(org_id)
);

-- 4. Portal analytics (D-21, D-43, D-102)
CREATE TABLE IF NOT EXISTS cs_portal_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  portal_config_id uuid NOT NULL REFERENCES cs_portal_config(id) ON DELETE CASCADE,
  link_id uuid NOT NULL,
  section_viewed text,
  time_spent_ms int,
  scroll_depth_pct int,
  ip_hash text,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 5. Portal audit log -- INSERT ONLY (D-114)
CREATE TABLE IF NOT EXISTS cs_portal_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  action text NOT NULL,
  portal_config_id uuid,
  link_id uuid,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 6. Indexes
CREATE INDEX IF NOT EXISTS idx_portal_config_link_id ON cs_portal_config(link_id);
CREATE INDEX IF NOT EXISTS idx_portal_config_slug ON cs_portal_config(company_slug, slug);
CREATE INDEX IF NOT EXISTS idx_portal_config_project ON cs_portal_config(project_id);
CREATE INDEX IF NOT EXISTS idx_portal_config_user ON cs_portal_config(user_id);
CREATE INDEX IF NOT EXISTS idx_portal_analytics_config ON cs_portal_analytics(portal_config_id, created_at);
CREATE INDEX IF NOT EXISTS idx_portal_analytics_link ON cs_portal_analytics(link_id, created_at);
CREATE INDEX IF NOT EXISTS idx_portal_audit_created ON cs_portal_audit_log(created_at);
CREATE INDEX IF NOT EXISTS idx_company_branding_org ON cs_company_branding(org_id);
CREATE INDEX IF NOT EXISTS idx_shared_links_type ON cs_report_shared_links(link_type);

-- 7. RLS Policies

-- cs_portal_config: owner/org can read/write, service role for public
ALTER TABLE cs_portal_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "portal_config_select_own" ON cs_portal_config
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "portal_config_insert_own" ON cs_portal_config
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "portal_config_update_own" ON cs_portal_config
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "portal_config_delete_own" ON cs_portal_config
  FOR DELETE USING (auth.uid() = user_id);

-- cs_company_branding: admin/manager only (D-74)
ALTER TABLE cs_company_branding ENABLE ROW LEVEL SECURITY;

CREATE POLICY "branding_select_org" ON cs_company_branding
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "branding_insert_org" ON cs_company_branding
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "branding_update_org" ON cs_company_branding
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- cs_portal_analytics: insert allowed for all (view logging), select for owner
ALTER TABLE cs_portal_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "analytics_insert_any" ON cs_portal_analytics
  FOR INSERT WITH CHECK (true);

CREATE POLICY "analytics_select_own" ON cs_portal_analytics
  FOR SELECT USING (
    portal_config_id IN (
      SELECT id FROM cs_portal_config WHERE user_id = auth.uid()
    )
  );

-- cs_portal_audit_log: INSERT only, no UPDATE/DELETE (D-114 immutable)
ALTER TABLE cs_portal_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_insert_any" ON cs_portal_audit_log
  FOR INSERT WITH CHECK (true);

CREATE POLICY "audit_select_own" ON cs_portal_audit_log
  FOR SELECT USING (user_id = auth.uid());

-- 8. Supabase Storage bucket for branding assets (D-100)
-- NOTE: Bucket creation must be done via Supabase dashboard or supabase CLI:
-- supabase storage create branding --public=false
-- RLS on storage.objects for 'branding' bucket should restrict uploads to authenticated users

-- 9. Updated_at trigger for portal tables
CREATE OR REPLACE FUNCTION update_portal_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_portal_config_updated_at
  BEFORE UPDATE ON cs_portal_config
  FOR EACH ROW EXECUTE FUNCTION update_portal_updated_at();

CREATE TRIGGER trg_company_branding_updated_at
  BEFORE UPDATE ON cs_company_branding
  FOR EACH ROW EXECUTE FUNCTION update_portal_updated_at();
