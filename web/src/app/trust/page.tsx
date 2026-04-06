"use client";
import { useState } from "react";
import PremiumFeatureGate from "@/app/components/PremiumFeatureGate";

const badges = [
  { level: "new", label: "New Member", icon: "👤", color: "#9EBDC2", minScore: 0 },
  { level: "active", label: "Active Builder", icon: "🔨", color: "#4AC4CC", minScore: 20 },
  { level: "trusted", label: "Trusted Pro", icon: "⭐", color: "#FCC757", minScore: 50 },
  { level: "elite", label: "Elite Contractor", icon: "🏆", color: "#F29E3D", minScore: 80 },
];

const trustBreakdown = [
  { category: "Profile Completeness", score: 18, max: 20, icon: "👤" },
  { category: "Credentials Submitted", score: 15, max: 20, icon: "📋" },
  { category: "Photo Proof Uploaded", score: 10, max: 15, icon: "📷" },
  { category: "Peer Endorsements", score: 12, max: 20, icon: "🤝" },
  { category: "Client Reviews", score: 14, max: 15, icon: "⭐" },
  { category: "Platform Activity", score: 8, max: 10, icon: "📊" },
];

const endorsements = [
  { name: "Marcus Rivera", trade: "General", skill: "Concrete Foundations", comment: "Best foundation crew in Houston. Zero callbacks." },
  { name: "Sarah Chen", trade: "Fiber", skill: "Project Management", comment: "Keeps the schedule tight. Great at coordinating." },
  { name: "Carlos Mendez", trade: "Concrete", skill: "Safety Leadership", comment: "Runs the safest sites I've worked on." },
];

const reviews = [
  { name: "Metro Development", role: "Owner", project: "Riverside Lofts", rating: 5, title: "Exceptional work", content: "Delivered ahead of schedule with zero safety incidents.", wouldHireAgain: true },
  { name: "Harbor Industries", role: "GC", project: "Harbor Crossing", rating: 4, title: "Solid performance", content: "Great quality work. Minor schedule adjustments needed.", wouldHireAgain: true },
  { name: "Urban Living", role: "Developer", project: "Pine Ridge Ph.2", rating: 5, title: "Best contractor we've worked with", content: "Communication is outstanding.", wouldHireAgain: true },
];

const totalScore = trustBreakdown.reduce((a, b) => a + b.score, 0);
const maxScore = trustBreakdown.reduce((a, b) => a + b.max, 0);
const currentBadge = badges.filter(b => totalScore >= b.minScore).pop()!;

export default function TrustPage() {
  return (
    <PremiumFeatureGate feature="trust-score">
      <TrustPageContent />
    </PremiumFeatureGate>
  );
}

function TrustPageContent() {
  const [activeTab, setActiveTab] = useState(0);
  const tabs = ["Trust Score", "Credentials", "Endorsements", "Reviews"];

  return (
    <div style={{ padding: 20, maxWidth: 900, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, textAlign: "center" }}>
        <div style={{ fontSize: 48, marginBottom: 8 }}>{currentBadge.icon}</div>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: currentBadge.color }}>{currentBadge.label.toUpperCase()}</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Trust & Reputation</h1>
        <div style={{ fontSize: 48, fontWeight: 900, color: currentBadge.color, margin: "12px 0 4px" }}>{totalScore}<span style={{ fontSize: 18, color: "var(--muted)" }}>/{maxScore}</span></div>
        <div style={{ width: 200, height: 8, borderRadius: 4, background: "var(--panel)", margin: "0 auto" }}>
          <div style={{ width: `${(totalScore / maxScore) * 100}%`, height: 8, borderRadius: 4, background: currentBadge.color }} />
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 8, marginBottom: 16 }}>
        {badges.map(b => (
          <div key={b.level} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, textAlign: "center", border: totalScore >= b.minScore ? `2px solid ${b.color}` : "1px solid var(--border)", opacity: totalScore >= b.minScore ? 1 : 0.5 }}>
            <div style={{ fontSize: 24 }}>{b.icon}</div>
            <div style={{ fontSize: 10, fontWeight: 800, color: b.color, marginTop: 4 }}>{b.label}</div>
            <div style={{ fontSize: 8, color: "var(--muted)" }}>{b.minScore}+ pts</div>
          </div>
        ))}
      </div>

      <div style={{ display: "flex", gap: 0, marginBottom: 16, borderRadius: 8, overflow: "hidden" }}>
        {tabs.map((t, i) => (
          <div key={t} onClick={() => setActiveTab(i)} style={{ flex: 1, textAlign: "center", padding: "9px 0", fontSize: 10, fontWeight: 800, background: activeTab === i ? "var(--accent)" : "var(--surface)", color: activeTab === i ? "var(--bg)" : "var(--muted)", cursor: "pointer" }}>{t.toUpperCase()}</div>
        ))}
      </div>

      {activeTab === 0 && trustBreakdown.map(t => (
        <div key={t.category} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
            <div style={{ display: "flex", gap: 8, alignItems: "center" }}><span style={{ fontSize: 18 }}>{t.icon}</span><span style={{ fontSize: 12, fontWeight: 800 }}>{t.category}</span></div>
            <span style={{ fontSize: 16, fontWeight: 900, color: t.score >= t.max * 0.8 ? "var(--green)" : "var(--gold)" }}>{t.score}/{t.max}</span>
          </div>
          <div style={{ background: "var(--panel)", borderRadius: 3, height: 4 }}><div style={{ background: t.score >= t.max * 0.8 ? "var(--green)" : "var(--gold)", borderRadius: 3, height: 4, width: `${(t.score / t.max) * 100}%` }} /></div>
        </div>
      ))}

      {activeTab === 2 && endorsements.map(e => (
        <div key={e.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8 }}>
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
            <span style={{ fontSize: 12, fontWeight: 800 }}>{e.name} <span style={{ fontSize: 9, color: "var(--muted)" }}>({e.trade})</span></span>
            <span style={{ fontSize: 9, fontWeight: 800, color: "var(--cyan)", background: "rgba(74,196,204,0.1)", padding: "3px 8px", borderRadius: 4 }}>{e.skill}</span>
          </div>
          <p style={{ fontSize: 11, fontStyle: "italic", color: "var(--text)", margin: 0 }}>&ldquo;{e.comment}&rdquo;</p>
        </div>
      ))}

      {activeTab === 3 && reviews.map(r => (
        <div key={r.project} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8 }}>
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
            <div><div style={{ fontSize: 13, fontWeight: 800 }}>{r.title}</div><div style={{ fontSize: 9, color: "var(--muted)" }}>{r.name} &bull; {r.role} &bull; {r.project}</div></div>
            <div style={{ display: "flex", gap: 1 }}>{[1,2,3,4,5].map(s => <span key={s} style={{ fontSize: 12, color: s <= r.rating ? "var(--gold)" : "var(--border)" }}>★</span>)}</div>
          </div>
          <p style={{ fontSize: 11, margin: "4px 0" }}>{r.content}</p>
          {r.wouldHireAgain && <span style={{ fontSize: 8, fontWeight: 900, color: "var(--green)", background: "rgba(105,210,148,0.1)", padding: "2px 6px", borderRadius: 3 }}>WOULD HIRE AGAIN</span>}
        </div>
      ))}
    </div>
  );
}
