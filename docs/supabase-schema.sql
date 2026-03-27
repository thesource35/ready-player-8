-- ConstructionOS Supabase Schema
-- Run this in your Supabase SQL Editor to create all tables
-- Then configure your Base URL and API Key in the Integration Hub

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- PROJECTS
-- ============================================================
CREATE TABLE IF NOT EXISTS cs_projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    client TEXT NOT NULL DEFAULT '',
    type TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'On Track',
    progress INTEGER NOT NULL DEFAULT 0,
    budget TEXT NOT NULL DEFAULT '$0',
    score TEXT NOT NULL DEFAULT '0',
    team TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CONTRACTS
-- ============================================================
CREATE TABLE IF NOT EXISTS cs_contracts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    client TEXT NOT NULL DEFAULT '',
    location TEXT NOT NULL DEFAULT '',
    sector TEXT NOT NULL DEFAULT '',
    stage TEXT NOT NULL DEFAULT 'Pursuit',
    package TEXT NOT NULL DEFAULT '',
    budget TEXT NOT NULL DEFAULT '$0',
    bid_due TEXT NOT NULL DEFAULT '',
    live_feed_status TEXT NOT NULL DEFAULT '',
    bidders INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    watch_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- MARKET DATA
-- ============================================================
CREATE TABLE IF NOT EXISTS cs_market_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT '',
    region TEXT NOT NULL DEFAULT '',
    market_score INTEGER NOT NULL DEFAULT 0,
    open_bids INTEGER NOT NULL DEFAULT 0,
    avg_project_size TEXT NOT NULL DEFAULT '',
    growth_trend TEXT NOT NULL DEFAULT '',
    top_sector TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- AI MESSAGES
-- ============================================================
CREATE TABLE IF NOT EXISTS cs_ai_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_messages_session ON cs_ai_messages(session_id);

-- ============================================================
-- DAILY LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS cs_daily_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date TEXT NOT NULL,
    weather TEXT NOT NULL DEFAULT '',
    temp_high INTEGER NOT NULL DEFAULT 0,
    temp_low INTEGER NOT NULL DEFAULT 0,
    manpower INTEGER NOT NULL DEFAULT 0,
    work_performed TEXT NOT NULL DEFAULT '',
    visitors TEXT NOT NULL DEFAULT '',
    delays TEXT NOT NULL DEFAULT '',
    safety_notes TEXT NOT NULL DEFAULT '',
    photo_count INTEGER NOT NULL DEFAULT 0,
    created_by TEXT NOT NULL DEFAULT '',
    site TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TIMECARDS
-- ============================================================
CREATE TABLE IF NOT EXISTS cs_timecards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crew_member TEXT NOT NULL,
    trade TEXT NOT NULL DEFAULT '',
    clock_in TEXT NOT NULL DEFAULT '',
    clock_out TEXT NOT NULL DEFAULT '',
    hours_regular DOUBLE PRECISION NOT NULL DEFAULT 0,
    hours_ot DOUBLE PRECISION NOT NULL DEFAULT 0,
    rate DOUBLE PRECISION NOT NULL DEFAULT 0,
    site TEXT NOT NULL DEFAULT '',
    date TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TAX EXPENSES
-- ============================================================
CREATE TABLE IF NOT EXISTS cs_tax_expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    category TEXT NOT NULL DEFAULT 'Materials',
    project_ref TEXT NOT NULL DEFAULT '',
    receipt_attached BOOLEAN NOT NULL DEFAULT FALSE,
    deductible BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- WEALTH TABLES
-- ============================================================
CREATE TABLE IF NOT EXISTS cs_wealth_opportunities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    wealth_signal DOUBLE PRECISION NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cs_decision_journal (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    context TEXT NOT NULL DEFAULT '',
    decision TEXT NOT NULL DEFAULT '',
    outcome TEXT NOT NULL DEFAULT '',
    score INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cs_psychology_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    score DOUBLE PRECISION NOT NULL DEFAULT 0,
    answers TEXT NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cs_leverage_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    total_score DOUBLE PRECISION NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cs_wealth_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL DEFAULT '',
    revenue DOUBLE PRECISION NOT NULL DEFAULT 0,
    expenses DOUBLE PRECISION NOT NULL DEFAULT 0,
    margin DOUBLE PRECISION NOT NULL DEFAULT 0,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
-- Enable RLS on all tables (configure policies per your auth setup)

ALTER TABLE cs_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_market_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_ai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_timecards ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_tax_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_wealth_opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_decision_journal ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_psychology_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_leverage_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_wealth_tracking ENABLE ROW LEVEL SECURITY;

-- Basic policy: authenticated users can do everything (customize per your needs)
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN SELECT unnest(ARRAY[
        'cs_projects', 'cs_contracts', 'cs_market_data', 'cs_ai_messages',
        'cs_daily_logs', 'cs_timecards', 'cs_tax_expenses',
        'cs_wealth_opportunities', 'cs_decision_journal',
        'cs_psychology_sessions', 'cs_leverage_snapshots', 'cs_wealth_tracking'
    ])
    LOOP
        EXECUTE format('CREATE POLICY IF NOT EXISTS %I_auth_policy ON %I FOR ALL TO authenticated USING (true) WITH CHECK (true)', tbl, tbl);
    END LOOP;
END $$;

-- ============================================================
-- SEED DATA (optional)
-- ============================================================
INSERT INTO cs_projects (name, client, type, status, progress, budget, score, team) VALUES
    ('Metro Tower Complex', 'Metro Development', 'Commercial', 'On Track', 65, '$42.8M', '92', 'Alpha'),
    ('Harbor Industrial Park', 'Harbor Industries', 'Industrial', 'Ahead', 78, '$18.5M', '88', 'Bravo'),
    ('Riverside Residential', 'Urban Living', 'Residential', 'On Track', 42, '$31.2M', '85', 'Charlie')
ON CONFLICT DO NOTHING;
