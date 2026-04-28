-- BASELINE: tables that pre-date the migrations directory.
--
-- 19 tables that were created on the prod Supabase project via the dashboard
-- SQL editor (or some pre-migrations bootstrap) and never captured as
-- migrations. The migrations folder otherwise can't bootstrap a fresh DB
-- because 001_updated_at_triggers.sql + later migrations reference these
-- tables as if they exist.
--
-- Captured 2026-04-28 from the prod schema dump
-- (`supabase db dump --linked --schema public`) AFTER applying the
-- multi-tenancy migrations 20260413001 + 20260428002..004 to prod.
--
-- These CREATE TABLE statements use IF NOT EXISTS so re-running on prod
-- (where they already exist) is a no-op. On staging (or any fresh DB),
-- they create the missing tables before subsequent migrations apply.
--
-- Filename uses 13 leading zeros so this migration applies BEFORE
-- 001_updated_at_triggers.sql (which alphabetically sorts as
-- "001_..." vs "00000000000_..." — 11 zeros sorts first).
--
-- Out of scope (deferred to a real "baseline-cleanup" phase):
--   - GRANT / ALTER OWNER statements (require superuser; service-role
--     and Supabase-managed roles handle access in practice)
--   - COMMENT ON statements (would require schema-owner privileges)
--   - Indexes on these tables (Phase-specific migrations add what's
--     needed; missing indexes can be added in a follow-up)
--   - RLS policies — added by 20260428002..004 multi-tenancy migrations

-- ============================================
-- cs_projects
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "client" "text" DEFAULT ''::"text" NOT NULL,
    "type" "text" DEFAULT 'General'::"text" NOT NULL,
    "status" "text" DEFAULT 'Active'::"text" NOT NULL,
    "progress" integer DEFAULT 0 NOT NULL,
    "budget" "text" DEFAULT '$0'::"text" NOT NULL,
    "score" "text" DEFAULT ''::"text" NOT NULL,
    "team" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "budget_numeric" double precision DEFAULT 0,
    "score_numeric" integer DEFAULT 0,
    "lat" numeric(9,6),
    "lng" numeric(9,6),
    "org_id" "uuid"
);

-- ============================================
-- cs_contracts
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_contracts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "client" "text" DEFAULT ''::"text" NOT NULL,
    "location" "text" DEFAULT ''::"text" NOT NULL,
    "sector" "text" DEFAULT ''::"text" NOT NULL,
    "stage" "text" DEFAULT 'Pursuit'::"text" NOT NULL,
    "package" "text" DEFAULT ''::"text" NOT NULL,
    "budget" "text" DEFAULT '$0'::"text" NOT NULL,
    "bid_due" "text" DEFAULT ''::"text" NOT NULL,
    "live_feed_status" "text" DEFAULT ''::"text" NOT NULL,
    "bidders" integer DEFAULT 0 NOT NULL,
    "score" integer DEFAULT 0 NOT NULL,
    "watch_count" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "budget_numeric" double precision DEFAULT 0,
    "org_id" "uuid"
);

-- ============================================
-- cs_market_data
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_market_data" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "city" "text" NOT NULL,
    "vacancy" double precision DEFAULT 0 NOT NULL,
    "new_biz" integer DEFAULT 0 NOT NULL,
    "closed" integer DEFAULT 0 NOT NULL,
    "trend" "text" DEFAULT 'flat'::"text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid"
);

-- ============================================
-- cs_ai_messages
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_ai_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "text" NOT NULL,
    "role" "text" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_change_orders
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_change_orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ref_number" "text" NOT NULL,
    "description" "text" NOT NULL,
    "amount" double precision DEFAULT 0 NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "project_ref" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "project_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_decision_journal
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_decision_journal" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "context" "text" DEFAULT ''::"text" NOT NULL,
    "thinking_mode" "text" DEFAULT 'Strategic'::"text" NOT NULL,
    "decision" "text" DEFAULT ''::"text" NOT NULL,
    "first_order" "text" DEFAULT ''::"text" NOT NULL,
    "second_order" "text" DEFAULT ''::"text" NOT NULL,
    "gates_passed" integer DEFAULT 0 NOT NULL,
    "outcome_status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "reviewed_at" timestamp with time zone,
    "user_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_feed_posts
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_feed_posts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "author_name" "text" NOT NULL,
    "author_title" "text" DEFAULT ''::"text" NOT NULL,
    "author_company" "text" DEFAULT ''::"text" NOT NULL,
    "content" "text" DEFAULT ''::"text" NOT NULL,
    "post_type" "text" DEFAULT 'update'::"text" NOT NULL,
    "tags" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "likes" integer DEFAULT 0 NOT NULL,
    "comments" integer DEFAULT 0 NOT NULL,
    "shares" integer DEFAULT 0 NOT NULL,
    "photo_count" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_leverage_snapshots
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_leverage_snapshots" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "total_score" double precision DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid"
);

-- ============================================
-- cs_ops_alerts
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_ops_alerts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "detail" "text" DEFAULT ''::"text" NOT NULL,
    "owner" "text" DEFAULT ''::"text" NOT NULL,
    "severity" integer DEFAULT 1 NOT NULL,
    "due" "text" DEFAULT ''::"text" NOT NULL,
    "resolved" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "project_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_psychology_sessions
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_psychology_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "score" double precision DEFAULT 0 NOT NULL,
    "profile_label" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid"
);

-- ============================================
-- cs_punch_pro
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_punch_pro" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "description" "text" NOT NULL,
    "location" "text" DEFAULT ''::"text" NOT NULL,
    "trade" "text" DEFAULT ''::"text" NOT NULL,
    "priority" "text" DEFAULT 'medium'::"text" NOT NULL,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "assignee" "text" DEFAULT ''::"text" NOT NULL,
    "due_date" "text" DEFAULT ''::"text" NOT NULL,
    "photo_count" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "project_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_rental_leads
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_rental_leads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "full_name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "phone" "text" DEFAULT ''::"text" NOT NULL,
    "company" "text" DEFAULT ''::"text" NOT NULL,
    "equipment_type" "text" NOT NULL,
    "category" "text" DEFAULT ''::"text" NOT NULL,
    "project_name" "text" DEFAULT ''::"text" NOT NULL,
    "project_location" "text" DEFAULT ''::"text" NOT NULL,
    "rental_start" "text" DEFAULT ''::"text" NOT NULL,
    "rental_duration" "text" DEFAULT ''::"text" NOT NULL,
    "budget_range" "text" DEFAULT ''::"text" NOT NULL,
    "quantity" integer DEFAULT 1 NOT NULL,
    "delivery_needed" boolean DEFAULT true NOT NULL,
    "notes" "text" DEFAULT ''::"text" NOT NULL,
    "status" "text" DEFAULT 'new'::"text" NOT NULL,
    "assigned_provider" "text" DEFAULT ''::"text" NOT NULL,
    "provider_contacted" boolean DEFAULT false NOT NULL,
    "lead_value" double precision DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_rfis
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_rfis" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ref_number" "text" NOT NULL,
    "subject" "text" NOT NULL,
    "from_trade" "text" DEFAULT ''::"text" NOT NULL,
    "to_trade" "text" DEFAULT ''::"text" NOT NULL,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "priority" "text" DEFAULT 'normal'::"text" NOT NULL,
    "due_date" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "project_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_tax_expenses
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_tax_expenses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "date" "text" NOT NULL,
    "description" "text" NOT NULL,
    "amount" double precision DEFAULT 0 NOT NULL,
    "category" "text" DEFAULT ''::"text" NOT NULL,
    "project_ref" "text" DEFAULT ''::"text" NOT NULL,
    "receipt_attached" boolean DEFAULT false NOT NULL,
    "deductible" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "project_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_timecards
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_timecards" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "crew_member" "text" NOT NULL,
    "trade" "text" DEFAULT ''::"text" NOT NULL,
    "clock_in" "text" DEFAULT ''::"text" NOT NULL,
    "clock_out" "text" DEFAULT ''::"text" NOT NULL,
    "hours_regular" double precision DEFAULT 0 NOT NULL,
    "hours_ot" double precision DEFAULT 0 NOT NULL,
    "rate" double precision DEFAULT 0 NOT NULL,
    "site" "text" DEFAULT ''::"text" NOT NULL,
    "date" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "project_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_transactions
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "from_name" "text" NOT NULL,
    "to_name" "text" NOT NULL,
    "amount" double precision DEFAULT 0 NOT NULL,
    "type" "text" DEFAULT 'invoice'::"text" NOT NULL,
    "project_ref" "text" DEFAULT ''::"text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "fee" double precision DEFAULT 0 NOT NULL,
    "payment_method" "text" DEFAULT 'standard'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "project_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_wealth_opportunities
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_wealth_opportunities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "wealth_signal" integer DEFAULT 0 NOT NULL,
    "contract_id" "text",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

-- ============================================
-- cs_wealth_tracking
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_wealth_tracking" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "revenue" double precision DEFAULT 0 NOT NULL,
    "expenses" double precision DEFAULT 0 NOT NULL,
    "margin" double precision DEFAULT 0 NOT NULL,
    "notes" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid"
);

-- ============================================
-- cs_daily_logs
-- ============================================
CREATE TABLE IF NOT EXISTS "public"."cs_daily_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "date" "text" NOT NULL,
    "weather" "text" DEFAULT ''::"text" NOT NULL,
    "temp_high" integer DEFAULT 0 NOT NULL,
    "temp_low" integer DEFAULT 0 NOT NULL,
    "manpower" integer DEFAULT 0 NOT NULL,
    "work_performed" "text" DEFAULT ''::"text" NOT NULL,
    "visitors" "text" DEFAULT ''::"text" NOT NULL,
    "delays" "text" DEFAULT ''::"text" NOT NULL,
    "safety_notes" "text" DEFAULT ''::"text" NOT NULL,
    "photo_count" integer DEFAULT 0 NOT NULL,
    "created_by" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid",
    "project_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "org_id" "uuid",
    "log_date" "date",
    "template_snapshot_jsonb" "jsonb",
    "content_jsonb" "jsonb",
    "weather_jsonb" "jsonb",
    "updated_by" "uuid"
);

