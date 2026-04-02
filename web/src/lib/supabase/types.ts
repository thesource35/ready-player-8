// TypeScript types matching iOS SupabaseService.swift DTOs exactly

export interface Project {
  id: string;
  name: string;
  client: string;
  type: string;
  status: string;
  progress: number;
  budget: string;
  score: string;
  team: string;
  created_at: string;
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
