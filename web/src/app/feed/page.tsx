"use client";
import Image from "next/image";
import Link from "next/link";
import { useState, useEffect } from "react";
import PremiumFeatureGate from "@/app/components/PremiumFeatureGate";
import FeatureAccessLink from "@/app/components/FeatureAccessLink";

const stories = [
  { name: "Marcus R.", initials: "MR", trade: "General", site: "Harborview", viewed: false },
  { name: "Sarah C.", initials: "SC", trade: "Fiber", site: "Campus", viewed: false },
  { name: "Carlos M.", initials: "CM", trade: "Concrete", site: "Central", viewed: true },
  { name: "Priya P.", initials: "PP", trade: "Electrical", site: "Data Center", viewed: true },
  { name: "Derek T.", initials: "DT", trade: "Solar", site: "SunVolt", viewed: false },
  { name: "Ashley W.", initials: "AW", trade: "Roofing", site: "Dallas", viewed: false },
  { name: "Jerome O.", initials: "JO", trade: "Crane", site: "Chicago", viewed: true },
];

const feedPosts = [
  { name: "Marcus Rivera", title: "Senior Ironworker", company: "PowerGrid Construction", initials: "MR", verified: true, content: "Just wrapped the structural steel on the Harborview Tower. 47 floors, 14 months, zero LTIs. Crew of 38 — every single one of you made this possible. 💪", tags: ["#SteelWork", "#SafetyFirst", "#ZeroIncidents"], likes: 247, comments: 42, shares: 18, time: "2h", type: "update", photos: 4, trade: "Steel", location: "Houston, TX" },
  { name: "Delta Build Group", title: "General Contractor · Licensed", company: "Delta Build", initials: "DB", verified: true, content: "🔔 SEEKING BIDS — 240-unit residential complex, Phoenix AZ. Packages open: MEP, framing, exterior envelope. Min bonding $2M. Prevailing wage applies.", tags: ["#OpenBid", "#PhoenixAZ", "#MEP"], likes: 67, comments: 31, shares: 15, time: "4h", type: "bid", photos: 0, trade: "General", location: "Phoenix, AZ" },
  { name: "Apex Concrete LLC", title: "Concrete Contractor", company: "Apex Concrete", initials: "AC", verified: true, content: "", tags: ["#Hiring", "#ConcreteCrew", "#MiamiJobs"], likes: 89, comments: 31, shares: 45, time: "4h", type: "hiring", photos: 0, trade: "Concrete", location: "Miami, FL", job: { title: "Concrete Finisher", pay: "$32-$38/hr", loc: "Miami, FL", urgent: true, type: "Full-time" } },
  { name: "Sarah Chen", title: "Lead Fiber Installer", company: "FiberLink Solutions", initials: "SC", verified: true, content: "OTDR test results looking clean on the downtown campus backbone. 68M points, all splices passing. This is what precision looks like.", tags: ["#FiberOptic", "#OTDR", "#DataCenter"], likes: 134, comments: 19, shares: 8, time: "5h", type: "update", photos: 3, trade: "Fiber", location: "San Francisco, CA" },
  { name: "TruBuild Electrical", title: "Electrical Contractor", company: "TruBuild", initials: "TE", verified: true, content: "NOW HIRING — Journeyman Electricians (4 positions) for a data center project in Austin, TX. 12-month contract, $42–$48/hr DOE. Per diem available. IBEW card preferred.", tags: ["#Hiring", "#Electrician", "#AustinTX"], likes: 112, comments: 58, shares: 24, time: "8h", type: "hiring", photos: 0, trade: "Electrical", location: "Austin, TX", job: { title: "Journeyman Electrician", pay: "$42-$48/hr", loc: "Austin, TX", urgent: false, type: "Contract 12mo" } },
  { name: "James Washington", title: "Ironworker Foreman", company: "Atlas Steel Works", initials: "JW", verified: true, content: "", tags: ["#ForSale", "#Equipment", "#Welding"], likes: 56, comments: 14, shares: 22, time: "8h", type: "selling", photos: 6, trade: "Steel", location: "Chicago, IL", equipment: { name: "Lincoln Ranger 330MPX Welder/Generator", price: "$4,200", condition: "Excellent — 420 hrs" } },
  { name: "Darnell Washington", title: "Concrete Foreman · 21 yrs", company: "Central District", initials: "DW", verified: true, content: "8,400 SF mat slab in 11 hours. Not a single cold joint. This is what trust looks like when your crew has been together 8 years. 🏆", tags: ["#ConcreteCrew", "#Foundation", "#SiteLife"], likes: 421, comments: 89, shares: 52, time: "12h", type: "update", photos: 6, trade: "Concrete", location: "Houston, TX" },
  { name: "Kim Nguyen", title: "Low Voltage Tech Lead", company: "SecureWire Systems", initials: "KN", verified: false, content: "Certified and ready for new projects. 7 years access control, CCTV, and structured cabling. BICSI TECH. Open to contracts in the PNW.", tags: ["#Available", "#LowVoltage", "#Seattle"], likes: 45, comments: 12, shares: 8, time: "1d", type: "available", photos: 0, trade: "Low Voltage", location: "Seattle, WA" },
  { name: "Derek Torres", title: "Solar Project Manager", company: "SunVolt Energy", initials: "DT", verified: false, content: "240kW commercial array going live this week. Battery storage + EV charging integrated. The future of jobsite power is here.", tags: ["#Solar", "#CleanEnergy", "#EV"], likes: 312, comments: 67, shares: 41, time: "1d", type: "project", photos: 8, trade: "Solar", location: "Phoenix, AZ" },
];

const jobs = [
  { title: "Concrete Superintendent", company: "Trident Construction", trade: "Concrete", location: "Las Vegas, NV", pay: "$95–$115K/yr", start: "Apr 1", duration: "18 months", urgent: true, applicants: 7, reqs: ["ACI certified", "10+ yrs high-rise", "OSHA 30"] },
  { title: "Journeyman Electrician", company: "TruBuild Electrical", trade: "Electrical", location: "Austin, TX", pay: "$42–$48/hr", start: "Apr 1", duration: "12 months", urgent: false, applicants: 23, reqs: ["IBEW preferred", "Commercial exp", "Lift cert"] },
  { title: "Tower Crane Operator", company: "Skyline Lift Solutions", trade: "Crane", location: "New York, NY", pay: "$85–$105/hr", start: "Immediate", duration: "24 months", urgent: true, applicants: 3, reqs: ["NCCCO certified", "NYC DOB approved", "5+ yrs high-rise"] },
  { title: "Structural Steel Foreman", company: "Atlas Iron Works", trade: "Steel", location: "Houston, TX", pay: "$88–$102K/yr", start: "Apr 15", duration: "14 months", urgent: false, applicants: 11, reqs: ["AISC knowledge", "AWS D1.1", "15+ crew exp"] },
  { title: "HVAC Project Manager", company: "Apex MEP Solutions", trade: "HVAC", location: "Denver, CO", pay: "$110–$130K/yr", start: "May 1", duration: "Full-time", urgent: false, applicants: 5, reqs: ["PE or LEED AP", "BIM/Revit MEP", "PMP preferred"] },
  { title: "Plumbing Foreman", company: "Summit Mechanical", trade: "Plumbing", location: "Portland, OR", pay: "$75–$90K/yr", start: "Apr 1", duration: "10 months", urgent: true, applicants: 9, reqs: ["Master plumber lic.", "Commercial exp", "OSHA 30"] },
];

const marketListings = [
  { name: "Lincoln Ranger 330MPX Welder/Generator", price: "$4,200", condition: "Excellent", hours: "420 hrs", location: "Chicago, IL", seller: "James W.", type: "sell" },
  { name: "2022 Ford F-350 Flatbed (Roofing setup)", price: "$52,000", condition: "Good", hours: "48K miles", location: "Dallas, TX", seller: "Ashley W.", type: "sell" },
  { name: "Hilti TE 70-ATC Rotary Hammer", price: "$1,400", condition: "Like New", hours: "~200 hrs", location: "Houston, TX", seller: "Mike T.", type: "sell" },
  { name: "CAT 320 Excavator", price: "$2,800/mo", condition: "Excellent", hours: "2,340 hrs", location: "Houston, TX", seller: "Torres Construction", type: "rent" },
  { name: "JLG 600S Boom Lift", price: "$1,200/wk", condition: "Good", hours: "890 hrs", location: "Dallas, TX", seller: "EquipLease Pro", type: "rent" },
];

const dms = [
  { name: "Marcus Rivera", initials: "MR", title: "Superintendent", company: "PowerGrid", lastMsg: "Hey, you available for the steel package on Harborview Phase 2?", time: "30m ago", unread: 0 },
  { name: "Sarah Chen", initials: "SC", title: "Lead Fiber", company: "FiberLink", lastMsg: "Can you send me the specs for the fiber run in Building C?", time: "2h ago", unread: 1 },
  { name: "Carlos Mendez", initials: "CM", title: "Concrete Super", company: "Apex", lastMsg: "Pour scheduled for 7AM tomorrow. Pump truck confirmed.", time: "4h ago", unread: 0 },
  { name: "Priya Patel", initials: "PP", title: "Master Electrician", company: "LightSpeed", lastMsg: "Thanks for the referral — got the contract!", time: "1d ago", unread: 0 },
  { name: "Derek Torres", initials: "DT", title: "Solar PM", company: "SunVolt", lastMsg: "The inverter specs look good. Sending PO today.", time: "2d ago", unread: 0 },
];

const companies = [
  { name: "PowerGrid Construction", trade: "General Contractor", location: "Houston, TX", employees: "850+", projects: 24, revenue: "$420M", rating: 4.9, verified: true, desc: "Full-service GC specializing in commercial, healthcare, and data center construction.", specialties: ["Commercial TI", "Healthcare", "Data Centers", "Mixed-Use"], initials: "PG" },
  { name: "Apex Concrete LLC", trade: "Concrete Contractor", location: "Miami, FL", employees: "320+", projects: 12, revenue: "$85M", rating: 4.8, verified: true, desc: "Southeast's premier concrete contractor. Post-tension, tilt-up, and high-rise foundations.", specialties: ["Post-Tension", "Tilt-Up", "Mat Foundations", "Structural"], initials: "AC" },
  { name: "FiberLink Solutions", trade: "Fiber Optic Contractor", location: "San Francisco, CA", employees: "180+", projects: 8, revenue: "$42M", rating: 4.9, verified: true, desc: "Data center and enterprise fiber infrastructure. BICSI certified. Coast to coast.", specialties: ["Data Center", "Campus Fiber", "FTTH", "5G Small Cell"], initials: "FL" },
  { name: "Atlas Steel Works", trade: "Structural Steel", location: "Chicago, IL", employees: "220+", projects: 15, revenue: "$68M", rating: 4.7, verified: true, desc: "Structural steel fabrication and erection for high-rise and industrial projects.", specialties: ["High-Rise Steel", "Industrial", "Bridges", "Misc. Metals"], initials: "AS" },
];

const crew = [
  { name: "Jerome Okafor", trade: "Crane", role: "Tower Crane Operator", years: 18, location: "Chicago, IL", rating: 4.9, jobs: 94, health: 92, ethic: 96, available: true, badge: "NCCCO Certified", connections: 312, initials: "JO" },
  { name: "Sofia Mendez", trade: "Electrical", role: "Master Electrician", years: 14, location: "Dallas, TX", rating: 4.8, jobs: 127, health: 94, ethic: 92, available: true, badge: "IBEW L20", connections: 488, initials: "SM" },
  { name: "Kevin Park", trade: "Plumbing", role: "Plumbing Foreman", years: 11, location: "Seattle, WA", rating: 4.7, jobs: 83, health: 79, ethic: 84, available: false, badge: "Master Plumber", connections: 201, initials: "KP" },
  { name: "Asha Williams", trade: "Steel", role: "Structural Detailer", years: 9, location: "Atlanta, GA", rating: 4.9, jobs: 61, health: 87, ethic: 90, available: true, badge: "AWS Certified", connections: 274, initials: "AW" },
  { name: "Tomás Fuentes", trade: "Concrete", role: "Concrete Superintendent", years: 22, location: "Phoenix, AZ", rating: 5.0, jobs: 148, health: 91, ethic: 95, available: true, badge: "ACI Grade 1", connections: 390, initials: "TF" },
  { name: "DeShawn Morris", trade: "Roofing", role: "Roofing Foreman", years: 16, location: "Miami, FL", rating: 4.8, jobs: 109, health: 85, ethic: 88, available: true, badge: "NRCA Certified", connections: 258, initials: "DM" },
];

const feedFilters = ["all", "projects", "hiring", "available", "selling", "bids"];
const tabs = ["Feed", "Jobs", "Market", "DMs", "Companies"];

export default function FeedPage() {
  const [activeTab, setActiveTab] = useState(0);
  const [feedFilter, setFeedFilter] = useState("all");
  const [posts, setPosts] = useState(feedPosts);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);

  const mapPost = (p: Record<string, unknown>) => ({
    name: (p.name as string) || (p.author_name as string) || "",
    title: (p.title as string) || (p.author_title as string) || "",
    company: (p.company as string) || (p.author_company as string) || "",
    initials: (p.initials as string) || ((p.author_name as string) || "").split(" ").map((w: string) => w[0]).join("").slice(0, 2).toUpperCase(),
    verified: (p.verified as boolean) ?? true,
    content: (p.content as string) || "",
    tags: (p.tags as string[]) || [],
    likes: (p.likes as number) || 0,
    comments: (p.comments as number) || 0,
    shares: (p.shares as number) || 0,
    time: (p.time as string) || (p.created_at as string) || "",
    type: (p.type as string) || (p.post_type as string) || "update",
    photos: (p.photos as number) || (p.photo_count as number) || 0,
    trade: (p.trade as string) || "General",
    location: (p.location as string) || "",
  });

  useEffect(() => {
    setIsLoading(true);
    fetch("/api/feed?page=0")
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((result: Record<string, unknown> | Record<string, unknown>[]) => {
        if (Array.isArray(result)) {
          if (result.length > 0) setPosts(result.map(mapPost));
          setHasMore(false);
        } else {
          const items = result.data as Record<string, unknown>[] | undefined;
          if (Array.isArray(items) && items.length > 0) setPosts(items.map(mapPost));
          setHasMore((result.hasMore as boolean) || false);
        }
        setIsLoading(false);
      })
      .catch(() => { setError("Failed to load feed"); setIsLoading(false); });
  }, []);

  const loadMore = async () => {
    setLoadingMore(true);
    try {
      const nextPage = page + 1;
      const res = await fetch(`/api/feed?page=${nextPage}`);
      const result = await res.json();
      if (Array.isArray(result)) {
        setPosts(prev => [...prev, ...result.map(mapPost)]);
        setHasMore(false);
      } else {
        const items = result.data as Record<string, unknown>[] | undefined;
        setPosts(prev => [...prev, ...(items || []).map(mapPost)]);
        setHasMore(result.hasMore || false);
      }
      setPage(nextPage);
    } catch (e) {
      console.error("[feed] load more failed:", e);
      setError("Couldn't load more posts. Try again.");
    } finally {
      setLoadingMore(false);
    }
  };

  const filteredPosts = feedFilter === "all" ? posts : posts.filter(p =>
    feedFilter === "hiring" ? p.type === "hiring" :
    feedFilter === "selling" ? p.type === "selling" :
    feedFilter === "available" ? p.type === "available" :
    feedFilter === "projects" ? p.type === "project" :
    feedFilter === "bids" ? p.type === "bid" : true
  );

  const typeColor = (t: string) => t === "hiring" ? "#69D294" : t === "selling" ? "#FCC757" : t === "bid" ? "#4AC4CC" : t === "available" ? "#8A8FCC" : t === "project" ? "#F29E3D" : "";

  return (
    <PremiumFeatureGate feature="feed">
    <div className="max-w-3xl mx-auto px-4 py-6">
      {/* Header */}
      <div className="flex items-center gap-3 mb-4 p-4 rounded-2xl" style={{ background: "#0F1C24", border: "1px solid rgba(74,196,204,0.08)" }}>
        <Image src="/logo-sm.png" alt="COS" width={40} height={40} className="rounded-xl" />
        <div className="flex-1">
          <div className="text-xs font-black tracking-[0.2em] text-[#F29E3D]">CONSTRUCTIONOS NETWORK</div>
          <div className="text-xs text-[#9EBDC2]">Instagram for construction — Growing network of professionals</div>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-2 h-2 rounded-full bg-[#69D294]" />
          <span className="text-[10px] font-bold text-[#69D294]">8,420 online</span>
        </div>
      </div>

      {/* Tabs */}
      {isLoading && <div style={{ textAlign: "center", padding: 40, color: "var(--muted)" }}>Loading network...</div>}
      {error && <div role="alert" style={{ textAlign: "center", padding: 16, color: "var(--red)", background: "rgba(217,77,72,0.1)", borderRadius: 10, marginBottom: 12 }}>{error}</div>}

      <div className="flex mb-4 rounded-lg overflow-hidden" style={{ background: "#0F1C24" }} role="tablist" aria-label="Network tabs">
        {tabs.map((t, i) => (
          <button key={t} onClick={() => setActiveTab(i)} role="tab" aria-selected={activeTab === i} aria-label={`${t} tab`} className="flex-1 py-2.5 text-[10px] font-bold tracking-wider relative" style={{ background: activeTab === i ? "rgba(242,158,61,0.08)" : "transparent", color: activeTab === i ? "#F29E3D" : "#9EBDC2" }}>
            {t.toUpperCase()}
            {t === "DMs" && dms.some(d => d.unread > 0) && <span className="absolute top-1.5 right-1/4 w-1.5 h-1.5 rounded-full bg-[#D94D48]" />}
          </button>
        ))}
      </div>

      {/* Feed Tab */}
      {activeTab === 0 && (
        <>
          {/* Stories */}
          <div className="flex gap-3 overflow-x-auto pb-3 mb-4" style={{ scrollbarWidth: "none" }}>
            <div className="flex-shrink-0 text-center w-16">
              <div className="w-14 h-14 rounded-full flex items-center justify-center text-xl" style={{ background: "#0F1C24", border: "2px dashed rgba(242,158,61,0.3)" }}>+</div>
              <div className="text-[8px] font-bold text-[#9EBDC2] mt-1">Your Story</div>
            </div>
            {stories.map(s => (
              <div key={s.name} className="flex-shrink-0 text-center w-16 cursor-pointer">
                <div className="w-14 h-14 rounded-full flex items-center justify-center" style={{ background: s.viewed ? "rgba(158,189,194,0.3)" : "linear-gradient(135deg, #F29E3D, #FCC757, #4AC4CC)", padding: "2.5px" }}>
                  <div className="w-full h-full rounded-full flex items-center justify-center text-xs font-black" style={{ background: "#080E12", color: s.viewed ? "#9EBDC2" : "#F0F8F8" }}>{s.initials}</div>
                </div>
                <div className="text-[8px] font-bold mt-1">{s.name}</div>
                <div className="text-[7px] text-[#9EBDC2]">{s.site}</div>
              </div>
            ))}
          </div>

          {/* Compose */}
          <div className="rounded-xl p-3 mb-4 flex gap-3 items-center" style={{ background: "#0F1C24" }}>
            <div className="w-9 h-9 rounded-full flex items-center justify-center text-[10px] font-black text-black shrink-0" style={{ background: "linear-gradient(135deg, #F29E3D, #FCC757)" }}>YOU</div>
            <div className="flex-1 py-2 px-3 rounded-lg text-xs text-[#9EBDC2]" style={{ background: "#162832" }}>Share a project update, job post, or equipment listing...</div>
            <FeatureAccessLink feature="jobs" paidHref="/jobs#post-job" previewHref="/jobs#post-job" className="px-3 py-1.5 rounded-lg text-[10px] font-bold text-black" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)", textDecoration: "none" }}>POST</FeatureAccessLink>
          </div>

          {/* Feed Filters */}
          <div className="flex gap-1.5 mb-4 overflow-x-auto" style={{ scrollbarWidth: "none" }}>
            {feedFilters.map(f => (
              <button key={f} onClick={() => setFeedFilter(f)} className="text-[9px] font-bold px-3 py-1.5 rounded-md whitespace-nowrap" style={{ background: feedFilter === f ? "#F29E3D" : "#0F1C24", color: feedFilter === f ? "#080E12" : "#9EBDC2" }}>{f === "all" ? "ALL" : f.toUpperCase()}</button>
            ))}
          </div>

          {/* Posts */}
          {filteredPosts.map((p, i) => (
            <div key={i} className="rounded-2xl p-4 mb-3" style={{ background: "#0F1C24", border: "1px solid rgba(74,196,204,0.06)" }}>
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs font-black text-black shrink-0" style={{ background: "linear-gradient(135deg, #F29E3D, #FCC757)" }}>{p.initials}</div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1">
                    <span className="text-sm font-bold truncate">{p.name}</span>
                    {p.verified && <span className="text-[#4AC4CC] shrink-0">✓</span>}
                  </div>
                  <div className="text-[10px] text-[#9EBDC2] truncate">{p.title} at {p.company} · {p.location} · {p.time}</div>
                </div>
                {p.type !== "update" && <span className="text-[9px] font-black px-2 py-1 rounded shrink-0" style={{ background: typeColor(p.type), color: "#000" }}>{p.type.toUpperCase()}</span>}
              </div>

              {p.content && <p className="text-[13px] leading-relaxed mb-3">{p.content}</p>}

              {p.job && (
                <div className="rounded-xl p-3 mb-3" style={{ background: "rgba(105,210,148,0.06)", border: "1px solid rgba(105,210,148,0.1)" }}>
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <div className="text-sm font-bold">{p.job.title}</div>
                      <div className="text-xs text-[#9EBDC2]">{p.job.type} · {p.job.loc}</div>
                    </div>
                    {p.job.urgent && <span className="text-[8px] font-black text-[#D94D48] bg-[rgba(217,77,72,0.1)] px-2 py-0.5 rounded">URGENT</span>}
                  </div>
                  <div className="text-base font-black text-[#69D294] mb-2">{p.job.pay}</div>
                  <FeatureAccessLink feature="jobs" paidHref="/jobs" previewHref="/jobs" className="block w-full py-2 rounded-lg text-xs font-bold text-black text-center" style={{ background: "#69D294", textDecoration: "none" }}>OPEN LIVE JOB</FeatureAccessLink>
                </div>
              )}

              {p.equipment && (
                <div className="rounded-xl p-3 mb-3" style={{ background: "rgba(252,199,87,0.06)", border: "1px solid rgba(252,199,87,0.1)" }}>
                  <div className="flex justify-between items-center">
                    <div><div className="text-sm font-bold">{p.equipment.name}</div><div className="text-xs text-[#9EBDC2]">{p.equipment.condition}</div></div>
                    <div className="text-lg font-black text-[#F29E3D]">{p.equipment.price}</div>
                  </div>
                </div>
              )}

              {p.tags.length > 0 && <div className="flex gap-1.5 flex-wrap mb-3">{p.tags.map(t => <span key={t} className="text-[10px] font-bold text-[#F29E3D]">{t}</span>)}</div>}
              {p.photos > 0 && <div className="rounded-xl h-44 flex items-center justify-center mb-3 overflow-hidden" style={{ background: "#162832" }}><span className="text-[#9EBDC2] text-sm">📷 {p.photos} photos</span></div>}

              <div className="flex border-t pt-2" style={{ borderColor: "rgba(51,84,94,0.2)" }}>
                {[["❤️", p.likes], ["💬", p.comments], ["↗️", p.shares]].map(([icon, count]) => (
                  <button key={String(icon)} className="flex-1 flex items-center justify-center gap-1.5 py-1.5 text-xs text-[#9EBDC2] hover:text-[#F0F8F8] transition">{icon} <span className="font-bold">{count}</span></button>
                ))}
              </div>
            </div>
          ))}

          {hasMore && (
            <div style={{ textAlign: "center", padding: "20px 0" }}>
              <button
                onClick={loadMore}
                disabled={loadingMore}
                style={{
                  background: "var(--accent, #FCC757)",
                  color: "#0A1A2A",
                  border: "none",
                  borderRadius: 8,
                  padding: "10px 28px",
                  fontSize: 14,
                  fontWeight: 700,
                  cursor: loadingMore ? "wait" : "pointer",
                  opacity: loadingMore ? 0.6 : 1,
                }}
              >
                {loadingMore ? "Loading..." : "Load More"}
              </button>
            </div>
          )}
        </>
      )}

      {/* Jobs Tab */}
      {activeTab === 1 && (
        <>
          <div className="rounded-xl p-4 mb-4 flex flex-col md:flex-row md:items-center md:justify-between gap-3" style={{ background: "rgba(105,210,148,0.06)", border: "1px solid rgba(105,210,148,0.12)" }}>
            <div>
              <div className="text-[10px] font-black tracking-[0.2em] text-[#69D294] mb-1">LIVE JOBS FLOW</div>
              <div className="text-sm font-bold">The real jobs board now lives on its own live route.</div>
              <div className="text-[11px] text-[#9EBDC2] mt-1">Open the dedicated board to post roles into the database and keep the hiring feed moving.</div>
            </div>
            <div className="flex gap-2">
              <FeatureAccessLink feature="jobs" paidHref="/jobs" previewHref="/jobs" className="px-3 py-2 rounded-lg text-[10px] font-bold text-black text-center" style={{ background: "#69D294", textDecoration: "none" }}>OPEN JOBS BOARD</FeatureAccessLink>
              <FeatureAccessLink feature="jobs" paidHref="/jobs#post-job" previewHref="/jobs#post-job" className="px-3 py-2 rounded-lg text-[10px] font-bold text-[#F29E3D] border border-[#F29E3D] text-center" style={{ textDecoration: "none" }}>POST A JOB</FeatureAccessLink>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-2 mb-4">
            <div className="text-center p-3 rounded-lg" style={{ background: "#0F1C24" }}><div className="text-lg font-black text-[#F29E3D]">{jobs.length}</div><div className="text-[7px] font-bold text-[#9EBDC2]">OPEN JOBS</div></div>
            <div className="text-center p-3 rounded-lg" style={{ background: "#0F1C24" }}><div className="text-lg font-black text-[#D94D48]">{jobs.filter(j => j.urgent).length}</div><div className="text-[7px] font-bold text-[#9EBDC2]">URGENT</div></div>
            <div className="text-center p-3 rounded-lg" style={{ background: "#0F1C24" }}><div className="text-lg font-black text-[#69D294]">{jobs.reduce((a, b) => a + b.applicants, 0)}</div><div className="text-[7px] font-bold text-[#9EBDC2]">APPLICANTS</div></div>
          </div>
          {jobs.map(j => (
            <div key={j.title} className="rounded-xl p-4 mb-3" style={{ background: "#0F1C24", border: "1px solid rgba(74,196,204,0.06)" }}>
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h3 className="text-sm font-bold">{j.title}</h3>
                  <p className="text-[10px] text-[#9EBDC2]">{j.company} · {j.location}</p>
                </div>
                <div className="text-right">
                  <div className="text-sm font-black text-[#69D294]">{j.pay}</div>
                  {j.urgent && <span className="text-[8px] font-black text-[#D94D48]">URGENT</span>}
                </div>
              </div>
              <div className="flex gap-2 mb-2 text-[9px] text-[#9EBDC2]">
                <span className="px-2 py-0.5 rounded" style={{ background: "rgba(74,196,204,0.08)", color: "#4AC4CC" }}>{j.trade}</span>
                <span>Start: {j.start}</span><span>{j.duration}</span><span>{j.applicants} applicants</span>
              </div>
              <div className="flex gap-1 flex-wrap mb-3">{j.reqs.map(r => <span key={r} className="text-[8px] px-2 py-0.5 rounded" style={{ background: "rgba(105,210,148,0.08)", color: "#69D294" }}>{r}</span>)}</div>
              <FeatureAccessLink feature="jobs" paidHref="/jobs" previewHref="/jobs" className="block w-full py-2 rounded-lg text-xs font-bold text-black text-center" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)", textDecoration: "none" }}>OPEN LIVE JOB</FeatureAccessLink>
            </div>
          ))}
        </>
      )}

      {/* Market Tab */}
      {activeTab === 2 && (
        <>
          <div className="flex gap-2 mb-4">
            <span className="text-[10px] font-bold px-3 py-1.5 rounded-md text-black" style={{ background: "#FCC757" }}>ALL</span>
            <span className="text-[10px] font-bold px-3 py-1.5 rounded-md text-[#9EBDC2]" style={{ background: "#0F1C24" }}>FOR SALE</span>
            <span className="text-[10px] font-bold px-3 py-1.5 rounded-md text-[#9EBDC2]" style={{ background: "#0F1C24" }}>FOR RENT</span>
          </div>
          {marketListings.map(m => (
            <div key={m.name} className="rounded-xl p-4 mb-3" style={{ background: "#0F1C24", border: "1px solid rgba(252,199,87,0.08)" }}>
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h3 className="text-sm font-bold">{m.name}</h3>
                  <p className="text-[10px] text-[#9EBDC2]">{m.condition} · {m.hours} · {m.location}</p>
                </div>
                <div className="text-right">
                  <div className="text-lg font-black text-[#F29E3D]">{m.price}</div>
                  <span className="text-[8px] font-black" style={{ color: m.type === "sell" ? "#FCC757" : "#4AC4CC" }}>{m.type === "sell" ? "FOR SALE" : "FOR RENT"}</span>
                </div>
              </div>
              <div className="flex gap-2 text-[10px] text-[#9EBDC2]"><span>Seller: {m.seller}</span></div>
              <Link href="/login?redirect=%2Ffeed" className="block w-full mt-3 py-2 rounded-lg text-xs font-bold text-black text-center" style={{ background: m.type === "sell" ? "#FCC757" : "#4AC4CC" }}>{m.type === "sell" ? "CONTACT SELLER" : "REQUEST RENTAL"}</Link>
            </div>
          ))}
        </>
      )}

      {/* DMs Tab */}
      {activeTab === 3 && (
        <>
          <div className="rounded-xl p-3 mb-4 flex items-center gap-2" style={{ background: "#162832" }}>
            <span className="text-[#9EBDC2] text-xs">🔍</span>
            <span className="text-xs text-[#9EBDC2]">Search conversations...</span>
          </div>
          {dms.map(d => (
            <div key={d.name} className="rounded-xl p-3 mb-2 flex items-center gap-3 cursor-pointer hover:bg-[#162832] transition" style={{ background: "#0F1C24" }}>
              <div className="relative shrink-0">
                <div className="w-11 h-11 rounded-full flex items-center justify-center text-xs font-black text-black" style={{ background: "linear-gradient(135deg, #F29E3D, #FCC757)" }}>{d.initials}</div>
                {d.unread > 0 && <div className="absolute -top-0.5 -right-0.5 w-4 h-4 rounded-full bg-[#D94D48] flex items-center justify-center text-[8px] font-black text-white">{d.unread}</div>}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex justify-between items-center">
                  <span className="text-sm font-bold">{d.name}</span>
                  <span className="text-[9px] text-[#9EBDC2]">{d.time}</span>
                </div>
                <div className="text-[10px] text-[#9EBDC2]">{d.title} at {d.company}</div>
                <p className="text-[11px] text-[#9EBDC2] truncate mt-0.5" style={{ fontWeight: d.unread > 0 ? 700 : 400, color: d.unread > 0 ? "#F0F8F8" : undefined }}>{d.lastMsg}</p>
              </div>
            </div>
          ))}
        </>
      )}

      {/* Companies Tab */}
      {activeTab === 4 && (
        <>
          <h2 className="text-[10px] font-black tracking-[0.15em] text-[#F29E3D] mb-3">VERIFIED COMPANY PAGES</h2>
          {companies.map(c => (
            <div key={c.name} className="rounded-xl p-4 mb-3" style={{ background: "#0F1C24", border: "1px solid rgba(74,196,204,0.06)" }}>
              <div className="flex items-start gap-3 mb-3">
                <div className="w-12 h-12 rounded-xl flex items-center justify-center text-sm font-black text-black shrink-0" style={{ background: "linear-gradient(135deg, #F29E3D, #FCC757)" }}>{c.initials}</div>
                <div className="flex-1">
                  <div className="flex items-center gap-1.5">
                    <span className="text-sm font-bold">{c.name}</span>
                    {c.verified && <span className="text-[#4AC4CC] text-xs">✓</span>}
                  </div>
                  <div className="text-[10px] text-[#9EBDC2]">{c.trade} · {c.location}</div>
                </div>
                <div className="text-sm font-black text-[#FCC757]">★ {c.rating}</div>
              </div>
              <p className="text-[11px] text-[#9EBDC2] mb-3">{c.desc}</p>
              <div className="grid grid-cols-3 gap-2 mb-3">
                <div className="text-center p-2 rounded-lg" style={{ background: "#162832" }}>
                  <div className="text-xs font-black text-[#F29E3D]">{c.revenue}</div>
                  <div className="text-[7px] text-[#9EBDC2]">REVENUE</div>
                </div>
                <div className="text-center p-2 rounded-lg" style={{ background: "#162832" }}>
                  <div className="text-xs font-black text-[#4AC4CC]">{c.employees}</div>
                  <div className="text-[7px] text-[#9EBDC2]">EMPLOYEES</div>
                </div>
                <div className="text-center p-2 rounded-lg" style={{ background: "#162832" }}>
                  <div className="text-xs font-black text-[#69D294]">{c.projects}</div>
                  <div className="text-[7px] text-[#9EBDC2]">PROJECTS</div>
                </div>
              </div>
              <div className="flex gap-1 flex-wrap">{c.specialties.map(s => <span key={s} className="text-[8px] font-bold px-2 py-0.5 rounded" style={{ background: "rgba(74,196,204,0.08)", color: "#4AC4CC" }}>{s}</span>)}</div>
            </div>
          ))}

          {/* Crew Directory */}
          <h2 className="text-[10px] font-black tracking-[0.15em] text-[#4AC4CC] mb-3 mt-6">CREW DIRECTORY</h2>
          {crew.map(c => (
            <div key={c.name} className="rounded-xl p-3 mb-2 flex items-center gap-3" style={{ background: "#0F1C24" }}>
              <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs font-black text-black shrink-0" style={{ background: "linear-gradient(135deg, #4AC4CC, #69D294)" }}>{c.initials}</div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="text-sm font-bold">{c.name}</span>
                  <span className="text-[8px] font-bold px-1.5 py-0.5 rounded" style={{ background: c.available ? "rgba(105,210,148,0.1)" : "rgba(217,77,72,0.1)", color: c.available ? "#69D294" : "#D94D48" }}>{c.available ? "AVAILABLE" : "BUSY"}</span>
                </div>
                <div className="text-[10px] text-[#9EBDC2]">{c.role} · {c.location} · {c.years} yrs</div>
                <div className="flex gap-2 text-[9px] mt-0.5">
                  <span className="text-[#FCC757]">★ {c.rating}</span>
                  <span className="text-[#9EBDC2]">{c.jobs} jobs</span>
                  <span className="text-[#4AC4CC]">{c.badge}</span>
                  <span className="text-[#9EBDC2]">{c.connections} connections</span>
                </div>
              </div>
              <Link href="/login?redirect=%2Ffeed" className="px-3 py-1.5 rounded-lg text-[9px] font-bold text-black shrink-0 text-center" style={{ background: "#4AC4CC", textDecoration: "none" }}>FOLLOW</Link>
            </div>
          ))}
        </>
      )}
    </div>
    </PremiumFeatureGate>
  );
}
