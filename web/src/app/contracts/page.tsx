"use client";
import Link from "next/link";
import { useState, useEffect } from "react";
import PremiumFeatureGate from "@/app/components/PremiumFeatureGate";

const fallbackContracts = [
  { title: "Houston Medical Complex", client: "Texas Health Partners", sector: "Healthcare", stage: "Open For Bid", value: "$18.2M", score: 94, watchCount: 23, location: "Houston, TX", deadline: "Apr 15, 2026" },
  { title: "DFW Airport Terminal C", client: "DFW Airport Authority", sector: "Aviation", stage: "Prequalifying Teams", value: "$45.0M", score: 88, watchCount: 41, location: "Dallas, TX", deadline: "May 1, 2026" },
  { title: "Baytown Refinery Expansion", client: "ExxonMobil", sector: "Industrial", stage: "Open For Bid", value: "$12.5M", score: 82, watchCount: 15, location: "Baytown, TX", deadline: "Apr 22, 2026" },
  { title: "Memorial Park Pavilion", client: "City of Houston", sector: "Municipal", stage: "Awarded", value: "$3.8M", score: 91, watchCount: 8, location: "Houston, TX", deadline: "N/A" },
  { title: "Galleria Office Tower", client: "Hines REIT", sector: "Commercial", stage: "Negotiation", value: "$28.5M", score: 79, watchCount: 19, location: "Houston, TX", deadline: "Apr 30, 2026" },
  { title: "Port of Houston Warehouse", client: "Port Authority", sector: "Industrial", stage: "Pursuit", value: "$9.2M", score: 71, watchCount: 12, location: "Houston, TX", deadline: "Jun 1, 2026" },
  { title: "River Oaks Residences", client: "Toll Brothers", sector: "Residential", stage: "Lost", value: "$6.4M", score: 65, watchCount: 5, location: "Houston, TX", deadline: "N/A" },
];

interface Contract {
  title: string;
  client: string;
  sector: string;
  stage: string;
  value: string;
  score: number;
  watchCount: number;
  location: string;
  deadline: string;
}

export default function ContractsPage() {
  const [search, setSearch] = useState("");
  const [activeFilter, setActiveFilter] = useState("All");
  const [allContracts, setAllContracts] = useState<Contract[]>(fallbackContracts);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const stageFilters = ["All", "Pursuit", "Prequalifying Teams", "Open For Bid", "Negotiation", "Awarded", "Lost"];

  const mapContract = (c: Record<string, unknown>): Contract => ({
    title: (c.title as string) || "",
    client: (c.client as string) || "",
    sector: (c.sector as string) || "",
    stage: (c.stage as string) || "",
    value: (c.value as string) || (c.budget as string) || "",
    score: (c.score as number) || 0,
    watchCount: (c.watchCount as number) || (c.watch_count as number) || 0,
    location: (c.location as string) || "",
    deadline: (c.deadline as string) || (c.bid_due as string) || "N/A",
  });

  useEffect(() => {
    setIsLoading(true);
    fetch("/api/contracts?page=0")
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((result: Record<string, unknown> | Record<string, unknown>[]) => {
        if (Array.isArray(result)) {
          if (result.length > 0) setAllContracts(result.map(mapContract));
          setHasMore(false);
        } else {
          const items = result.data as Record<string, unknown>[] | undefined;
          if (Array.isArray(items) && items.length > 0) setAllContracts(items.map(mapContract));
          setHasMore((result.hasMore as boolean) || false);
        }
        setIsLoading(false);
      })
      .catch(() => { setError("Failed to load contracts"); setIsLoading(false); });
  }, []);

  const loadMore = async () => {
    setLoadingMore(true);
    try {
      const nextPage = page + 1;
      const res = await fetch(`/api/contracts?page=${nextPage}`);
      const result = await res.json();
      if (Array.isArray(result)) {
        setAllContracts(prev => [...prev, ...result.map(mapContract)]);
        setHasMore(false);
      } else {
        const items = result.data as Record<string, unknown>[] | undefined;
        setAllContracts(prev => [...prev, ...(items || []).map(mapContract)]);
        setHasMore(result.hasMore || false);
      }
      setPage(nextPage);
    } catch (e) {
      console.error("[contracts] load more failed:", e);
      setError("Couldn't load more contracts. Try again.");
    } finally {
      setLoadingMore(false);
    }
  };

  const contracts = allContracts.filter(c => {
    const matchesSearch = !search || c.title.toLowerCase().includes(search.toLowerCase()) || c.client.toLowerCase().includes(search.toLowerCase()) || c.sector.toLowerCase().includes(search.toLowerCase());
    const matchesFilter = activeFilter === "All" || c.stage === activeFilter;
    return matchesSearch && matchesFilter;
  });
  const activeBids = contracts.filter(c => c.stage === "Open For Bid" || c.stage === "Prequalifying Teams").length;
  const totalWatchers = contracts.reduce((a, b) => a + b.watchCount, 0);
  const avgScore = Math.round(contracts.reduce((a, b) => a + b.score, 0) / contracts.length);

  const stageColor = (s: string) => {
    if (s === "Awarded") return "var(--green)";
    if (s === "Open For Bid") return "var(--gold)";
    if (s === "Prequalifying Teams") return "var(--cyan)";
    if (s === "Negotiation") return "var(--accent)";
    if (s === "Lost") return "var(--red)";
    return "var(--muted)";
  };

  return (
    <PremiumFeatureGate feature="contracts">
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(252,199,87,0.08)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 4, color: "var(--gold)" }}>CONTRACTS</div>
            <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Bid Pipeline</h1>
            <p style={{ fontSize: 12, color: "var(--muted)" }}>Track, score, and manage all bid opportunities</p>
          </div>
          <Link href="/login?redirect=%2Fcontracts" style={{ background: "var(--gold)", color: "var(--bg)", border: "none", borderRadius: 8, padding: "8px 16px", fontWeight: 700, fontSize: 12, cursor: "pointer", textDecoration: "none", display: "inline-block" }}>+ Add Contract</Link>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 16 }}>
        {[
          { val: contracts.length.toString(), label: "TOTAL BIDS", color: "var(--gold)" },
          { val: activeBids.toString(), label: "ACTIVE BIDS", color: "var(--cyan)" },
          { val: totalWatchers.toString(), label: "WATCHERS", color: "var(--accent)" },
          { val: avgScore.toString(), label: "AVG SCORE", color: "var(--green)" },
        ].map(s => (
          <div key={s.label} style={{ textAlign: "center", padding: 14, background: "var(--surface)", borderRadius: 10 }}>
            <div style={{ fontSize: 24, fontWeight: 900, color: s.color }}>{s.val}</div>
            <div style={{ fontSize: 8, fontWeight: 800, letterSpacing: 2, color: "var(--muted)", marginTop: 4 }}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* Search */}
      <input aria-label="Search contracts" placeholder="Search contracts, clients, sectors..." value={search} onChange={e => setSearch(e.target.value)} style={{ width: "100%", marginBottom: 12 }} />

      {isLoading && <div style={{ textAlign: "center", padding: 40, color: "var(--muted)" }}>Loading contracts...</div>}
      {error && <div role="alert" style={{ textAlign: "center", padding: 16, color: "var(--red)", background: "rgba(217,77,72,0.1)", borderRadius: 10, marginBottom: 12 }}>{error}</div>}

      {/* Stage Filter Pills */}
      <div style={{ display: "flex", gap: 6, marginBottom: 16, flexWrap: "wrap" }}>
        {stageFilters.map(f => (
          <span key={f} onClick={() => setActiveFilter(f)} style={{ fontSize: 10, fontWeight: 700, padding: "5px 12px", borderRadius: 6, background: activeFilter === f ? "var(--gold)" : "var(--surface)", color: activeFilter === f ? "var(--bg)" : "var(--muted)", border: activeFilter === f ? "none" : "1px solid rgba(51,84,94,0.3)", cursor: "pointer" }}>{f}</span>
        ))}
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {contracts.map(c => (
          <div key={c.title} style={{ background: "var(--surface)", borderRadius: 12, padding: 16, border: "1px solid rgba(74,196,204,0.06)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <h3 style={{ fontSize: 14, fontWeight: 800, margin: 0 }}>{c.title}</h3>
                <p style={{ fontSize: 11, color: "var(--muted)", margin: "2px 0 0" }}>{c.client} &bull; {c.sector} &bull; {c.location}</p>
              </div>
              <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
                <span style={{ fontSize: 16, fontWeight: 900, color: "var(--gold)" }}>{c.value}</span>
                <span style={{ fontSize: 14, fontWeight: 900, color: "var(--cyan)" }}>{c.score}</span>
                <span style={{ fontSize: 8, fontWeight: 900, color: stageColor(c.stage), background: `${stageColor(c.stage)}15`, padding: "3px 8px", borderRadius: 4 }}>{c.stage.toUpperCase()}</span>
              </div>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8, fontSize: 10, color: "var(--muted)" }}>
              <span>{c.watchCount} watchers</span>
              {c.deadline !== "N/A" && <span>Deadline: <b style={{ color: "var(--gold)" }}>{c.deadline}</b></span>}
            </div>
          </div>
        ))}
      </div>

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
    </div>
    </PremiumFeatureGate>
  );
}
