-- ConstructionOS License Verification System
-- Run in Supabase SQL Editor

-- Verification requests submitted by users
create table cs_verification_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  tier text not null default 'licensed',  -- 'identity', 'licensed', 'company'
  status text not null default 'pending',  -- 'pending', 'reviewing', 'approved', 'denied'

  -- Personal info
  full_name text not null,
  email text not null,
  phone text not null default '',

  -- Trade & License
  trade text not null,
  license_type text not null default '',
  license_number text not null default '',
  license_state text not null default '',
  license_expiry text not null default '',
  osha_level text not null default '',

  -- Company info (for company tier)
  company_name text not null default '',
  ein text not null default '',
  years_in_business int not null default 0,

  -- Insurance & Bonding (for company tier)
  insurance_carrier text not null default '',
  insurance_policy_number text not null default '',
  gl_coverage_amount text not null default '',
  wc_coverage_amount text not null default '',
  bonding_company text not null default '',
  bonding_capacity text not null default '',

  -- Verification evidence
  license_photo_url text,
  insurance_cert_url text,
  id_photo_url text,

  -- Admin fields
  reviewer_notes text not null default '',
  denial_reason text not null default '',
  verified_at timestamptz,
  submitted_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Verified badges (active verifications)
create table cs_verified_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) unique,
  tier text not null default 'identity',
  badge_label text not null default 'VERIFIED',
  trade text not null default '',
  license_number text not null default '',
  license_state text not null default '',
  license_verified boolean not null default false,
  insurance_verified boolean not null default false,
  bonding_verified boolean not null default false,
  company_name text not null default '',
  expires_at timestamptz,
  granted_at timestamptz default now()
);

-- Verification audit log
create table cs_verification_log (
  id uuid primary key default gen_random_uuid(),
  request_id uuid references cs_verification_requests(id),
  action text not null,  -- 'submitted', 'reviewing', 'approved', 'denied', 'revoked', 'expired'
  actor text not null default 'system',
  details text not null default '',
  created_at timestamptz default now()
);

-- Trade license requirements reference
create table cs_trade_requirements (
  id uuid primary key default gen_random_uuid(),
  trade text not null unique,
  requires_state_license boolean not null default true,
  license_types text[] not null default '{}',
  accepted_certifications text[] not null default '{}',
  verify_with text not null default 'State Licensing Board',
  states_covered int not null default 50,
  avg_processing_days int not null default 3
);

-- Seed trade requirements
insert into cs_trade_requirements (trade, requires_state_license, license_types, accepted_certifications, verify_with, states_covered, avg_processing_days) values
  ('Electrician', true, '{"Journeyman Electrician","Master Electrician"}', '{"OSHA 30","NFPA 70E"}', 'State Licensing Board', 50, 3),
  ('Plumber', true, '{"Journeyman Plumber","Master Plumber"}', '{"OSHA 30","Medical Gas"}', 'State Licensing Board', 48, 3),
  ('HVAC', true, '{"HVAC License","EPA 608 Universal"}', '{"NATE","R-410A"}', 'EPA / State Board', 45, 4),
  ('General Contractor', true, '{"General Contractor License","Building Contractor"}', '{"PMP","LEED AP"}', 'State Contractor Board', 50, 5),
  ('Crane Operator', true, '{"NCCCO Certification"}', '{"OSHA 30","Signal Person"}', 'NCCCO Database', 50, 2),
  ('Welder', true, '{"AWS D1.1 Certified","CWI"}', '{"OSHA 10","Structural Steel"}', 'AWS Certification', 50, 3),
  ('Roofing Contractor', true, '{"Roofing Contractor License"}', '{"NRCA Certified","OSHA 30"}', 'State Contractor Board', 42, 4),
  ('Structural Engineer', true, '{"PE License"}', '{"SE Exam","FE Exam"}', 'State PE Board', 50, 7),
  ('Architect', true, '{"Architecture License"}', '{"ARE","NCARB"}', 'State Architecture Board', 50, 7),
  ('Fire Protection', true, '{"Fire Protection License"}', '{"NICET Level III","OSHA 30"}', 'State Fire Marshal', 50, 4),
  ('Concrete', false, '{"ACI Certification"}', '{"ACI Grade 1","Flatwork Finisher"}', 'ACI Certification', 50, 2),
  ('Steel/Ironwork', false, '{"AWS Certification"}', '{"AISC","Rigging Cert"}', 'AWS / AISC', 50, 3),
  ('Solar Installer', true, '{"Solar Contractor License"}', '{"NABCEP PV","OSHA 10"}', 'State Contractor Board', 35, 4),
  ('Low Voltage', true, '{"Low Voltage License"}', '{"BICSI TECH","NICET"}', 'State Licensing Board', 40, 3),
  ('Demolition', true, '{"Demolition Contractor License"}', '{"OSHA 30","Lead/Asbestos"}', 'State Contractor Board', 38, 5)
on conflict (trade) do nothing;

-- RLS policies
alter table cs_verification_requests enable row level security;
alter table cs_verified_badges enable row level security;
alter table cs_verification_log enable row level security;
alter table cs_trade_requirements enable row level security;

-- Users can read their own verification requests
create policy "Users read own requests" on cs_verification_requests
  for select using (auth.uid() = user_id);

-- Users can insert their own verification requests
create policy "Users create own requests" on cs_verification_requests
  for insert with check (auth.uid() = user_id);

-- Users can read their own badges
create policy "Users read own badge" on cs_verified_badges
  for select using (auth.uid() = user_id);

-- Anyone can read trade requirements
create policy "Public read trade requirements" on cs_trade_requirements
  for select using (true);

-- Verification log readable by request owner
create policy "Users read own logs" on cs_verification_log
  for select using (
    request_id in (select id from cs_verification_requests where user_id = auth.uid())
  );
