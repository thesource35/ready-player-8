// Shared fallback/mock data used by both API routes and page components.
// Single source of truth — update here when demo data changes.

import type { Project, Contract, FeedPost, PunchItem } from "@/lib/supabase/types";

export const MOCK_PROJECTS: Partial<Project>[] = [
  { id: "1", name: "Riverside Lofts", client: "Metro Development", type: "Mixed-Use", status: "On Track", progress: 72, budget: "$4.2M", score: 88, team: "Mike Torres", start_date: "Jan 2026", end_date: "Nov 2026" },
  { id: "2", name: "Harbor Crossing", client: "Harbor Industries", type: "Commercial", status: "Ahead", progress: 45, budget: "$8.1M", score: 92, team: "Sarah Kim", start_date: "Mar 2026", end_date: "Feb 2027" },
  { id: "3", name: "Pine Ridge Ph.2", client: "Urban Living", type: "Residential", status: "Delayed", progress: 28, budget: "$2.8M", score: 61, team: "James Wright", start_date: "Feb 2026", end_date: "Sep 2026" },
  { id: "4", name: "Skyline Tower", client: "Apex Corp", type: "High-Rise", status: "On Track", progress: 15, budget: "$22.5M", score: 85, team: "David Chen", start_date: "Apr 2026", end_date: "Dec 2027" },
  { id: "5", name: "Metro Station Retrofit", client: "City of Houston", type: "Infrastructure", status: "At Risk", progress: 55, budget: "$6.3M", score: 54, team: "Ana Rodriguez", start_date: "Nov 2025", end_date: "Aug 2026" },
];

export const MOCK_CONTRACTS: Partial<Contract>[] = [
  { id: "1", title: "Houston Medical Complex", client: "Texas Health Partners", sector: "Healthcare", stage: "Open For Bid", budget: "$18.2M", score: 94, watch_count: 23, location: "Houston, TX", bid_due: "Apr 15, 2026" },
  { id: "2", title: "DFW Airport Terminal C", client: "DFW Airport Authority", sector: "Aviation", stage: "Prequalifying Teams", budget: "$45.0M", score: 88, watch_count: 41, location: "Dallas, TX", bid_due: "May 1, 2026" },
  { id: "3", title: "Baytown Refinery Expansion", client: "ExxonMobil", sector: "Industrial", stage: "Open For Bid", budget: "$12.5M", score: 82, watch_count: 15, location: "Baytown, TX", bid_due: "Apr 22, 2026" },
  { id: "4", title: "Memorial Park Pavilion", client: "City of Houston", sector: "Municipal", stage: "Awarded", budget: "$3.8M", score: 91, watch_count: 8, location: "Houston, TX", bid_due: "N/A" },
  { id: "5", title: "Galleria Office Tower", client: "Hines REIT", sector: "Commercial", stage: "Negotiation", budget: "$28.5M", score: 79, watch_count: 19, location: "Houston, TX", bid_due: "Apr 30, 2026" },
];

export const MOCK_FEED_POSTS: Partial<FeedPost>[] = [
  { id: "1", author_name: "Marcus Rivera", author_title: "Senior Ironworker", author_company: "PowerGrid Construction", content: "Just wrapped structural steel on the Harborview Tower. 47 floors, 14 months, zero LTIs.", post_type: "update", likes: 247, comments: 42, shares: 18, photo_count: 4 },
  { id: "2", author_name: "Sarah Chen", author_title: "Lead Fiber Installer", author_company: "FiberLink Solutions", content: "OTDR test results looking clean on the downtown campus backbone.", post_type: "update", likes: 134, comments: 19, shares: 8, photo_count: 3 },
  { id: "3", author_name: "Darnell Washington", author_title: "Concrete Foreman", author_company: "Central District", content: "8,400 SF mat slab in 11 hours. Not a single cold joint.", post_type: "update", likes: 421, comments: 89, shares: 52, photo_count: 6 },
  { id: "4", author_name: "Derek Torres", author_title: "Solar PM", author_company: "SunVolt Energy", content: "240kW commercial array going live this week.", post_type: "project", likes: 312, comments: 67, shares: 41, photo_count: 8 },
];

export const MOCK_PUNCH_ITEMS: Partial<PunchItem>[] = [
  { id: "1", description: "Touch-up paint at stairwell B-2", location: "Building A, Level 2", trade: "Painting", priority: "HIGH", status: "OPEN", assignee: "Carlos M.", due_date: "Apr 2", photo_count: 3 },
  { id: "2", description: "HVAC diffuser not aligned in room 204", location: "Building A, Level 2", trade: "HVAC", priority: "MEDIUM", status: "IN PROGRESS", assignee: "HVAC Team", due_date: "Apr 3", photo_count: 2 },
  { id: "3", description: "Caulk gap at window frame unit 405", location: "Building B, Level 4", trade: "Exterior", priority: "CRITICAL", status: "OPEN", assignee: "Exterior Crew", due_date: "Mar 31", photo_count: 4 },
  { id: "4", description: "Fire caulking incomplete at shaft 3", location: "Building B, Level 3", trade: "Fire/Life Safety", priority: "CRITICAL", status: "IN PROGRESS", assignee: "FireSafe", due_date: "Apr 1", photo_count: 2 },
  { id: "5", description: "Floor tile grout color mismatch", location: "Building A, Level 1", trade: "Tile", priority: "MEDIUM", status: "COMPLETE", assignee: "Tile Sub", due_date: "Mar 28", photo_count: 5 },
];
