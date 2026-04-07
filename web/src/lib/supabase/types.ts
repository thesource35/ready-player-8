// TypeScript types matching iOS SupabaseService.swift DTOs exactly

export interface Project {
  id: string;
  name: string;
  client: string;
  type: string;
  status: string;
  progress: number;
  budget: string;
  score: number;
  team: string;
  start_date?: string;
  end_date?: string;
  created_at: string;
  user_id?: string;
}

export interface Contract {
  id: string;
  title: string;
  client: string;
  location: string;
  sector: string;
  stage: string;
  package: string;
  budget: string;
  bid_due: string;
  live_feed_status: string;
  bidders: number;
  score: number;
  watch_count: number;
  created_at: string;
  user_id?: string;
}

export interface MarketData {
  id: string;
  city: string;
  vacancy: number;
  new_biz: number;
  closed: number;
  trend: string;
  updated_at: string;
}

export interface AIMessage {
  id: string;
  session_id: string;
  role: string;
  content: string;
  created_at: string;
}

export interface WealthOpportunity {
  id: string;
  name: string;
  wealth_signal: number;
  contract_id: string | null;
  status: string;
  created_at: string;
}

export interface DecisionJournal {
  id: string;
  title: string;
  context: string;
  thinking_mode: string;
  decision: string;
  first_order: string;
  second_order: string;
  gates_passed: number;
  outcome_status: string;
  created_at: string;
  reviewed_at: string | null;
}

export interface PsychologySession {
  id: string;
  score: number;
  profile_label: string;
  created_at: string;
}

export interface LeverageSnapshot {
  id: string;
  total_score: number;
  created_at: string;
}

export interface WealthTracking {
  id: string;
  name: string;
  revenue: number;
  expenses: number;
  margin: number;
  notes: string;
  created_at: string;
}

export interface DailyLog {
  id: string;
  date: string;
  weather: string;
  temp_high: number;
  temp_low: number;
  manpower: number;
  work_performed: string;
  visitors: string;
  delays: string;
  safety_notes: string;
  photo_count: number;
  created_by: string;
  created_at: string;
}

export interface PunchItem {
  id: string;
  description: string;
  location: string;
  trade: string;
  priority: string;
  status: string;
  assignee: string;
  due_date: string;
  photo_count: number;
  created_at: string;
  user_id?: string;
}

export interface FeedPost {
  id: string;
  author_name: string;
  author_title: string;
  author_company: string;
  content: string;
  post_type: string;
  tags: string[];
  likes: number;
  comments: number;
  shares: number;
  photo_count: number;
  created_at: string;
  user_id?: string;
}

export interface UserProfile {
  id: string;
  email: string;
  full_name: string;
  company: string;
  trade: string;
  title: string;
  location: string;
  bio: string;
  verification_tier: string;
  subscription_tier: string;
  created_at: string;
}

export interface OpsAlert {
  id: string;
  title: string;
  message: string;
  severity: string;
  acknowledged: boolean;
  created_at: string;
  user_id?: string;
}

export interface Rfi {
  id: string;
  number: string;
  subject: string;
  status: string;
  priority: string;
  assigned_to: string;
  due_date: string;
  created_at: string;
  user_id?: string;
}

export interface ChangeOrder {
  id: string;
  number: string;
  description: string;
  amount: number;
  status: string;
  requested_by: string;
  created_at: string;
  user_id?: string;
}

export type Document = {
  id: string;
  org_id: string;
  version_chain_id: string;
  version_number: number;
  is_current: boolean;
  filename: string;
  mime_type: string;
  size_bytes: number;
  storage_path: string;
  uploaded_by: string;
  created_at: string;
};

export type DocumentAttachment = {
  document_id: string;
  entity_type: "project" | "rfi" | "submittal" | "change_order";
  entity_id: string;
  created_at: string;
};
