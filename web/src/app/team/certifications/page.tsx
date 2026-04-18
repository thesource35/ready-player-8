import Link from "next/link";
import { createServerSupabase } from "@/lib/supabase/server";
import { getUrgencyInfo } from "@/lib/certifications/urgency";
import { CertHighlightScroller } from "./CertHighlightScroller";

export const metadata = { title: "Team Certifications — ConstructionOS" };

function timeAgo(isoDate: string): string {
  const diff = Date.now() - new Date(isoDate).getTime();
  const hours = Math.floor(diff / (1000 * 60 * 60));
  if (hours < 1) return "< 1h ago";
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

type CertRow = {
  id: string;
  member_id: string;
  name: string;
  issuer: string | null;
  number: string | null;
  issued_date: string | null;
  expires_at: string | null;
  document_id: string | null;
  status: string;
  cs_team_members: { name: string | null } | null;
};

type PageProps = { searchParams: Promise<{ highlight?: string }> };

const navLink: React.CSSProperties = { color: "var(--muted)", textDecoration: "none", fontSize: 14 };

export default async function CertificationsPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const highlightId =
    params.highlight && /^[0-9a-f-]{36}$/i.test(params.highlight) ? params.highlight : null;

  const supabase = await createServerSupabase();
  let rows: CertRow[] = [];
  if (supabase) {
    const { data } = await supabase
      .from("cs_certifications")
      .select(
        "id, member_id, name, issuer, number, issued_date, expires_at, document_id, status, cs_team_members(name)"
      )
      .order("expires_at", { ascending: true, nullsFirst: false });
    rows = (data as unknown as CertRow[] | null) ?? [];
  }

  // D-38: Admin-only cert scan status badge
  let lastScanInfo: { lastScanAt: string | null; alertCount: number } = { lastScanAt: null, alertCount: 0 };
  let isAdmin = false;
  if (supabase) {
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { count: ownedProjects } = await supabase
        .from("cs_projects")
        .select("id", { count: "exact", head: true })
        .eq("created_by", user.id);
      isAdmin = (ownedProjects ?? 0) > 0;
    }

    if (isAdmin) {
      const { data: lastEvent } = await supabase
        .from("cs_activity_events")
        .select("created_at")
        .eq("entity_type", "certifications")
        .order("created_at", { ascending: false })
        .limit(1)
        .single();

      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
      const { count: recentAlerts } = await supabase
        .from("cs_activity_events")
        .select("id", { count: "exact", head: true })
        .eq("entity_type", "certifications")
        .gte("created_at", oneDayAgo);

      lastScanInfo = {
        lastScanAt: lastEvent?.created_at ?? null,
        alertCount: recentAlerts ?? 0,
      };
    }
  }

  return (
    <main style={{ padding: 32, maxWidth: 1200, margin: "0 auto" }}>
      <style>{`@keyframes certPulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }`}</style>

      <header
        style={{
          display: "flex",
          alignItems: "baseline",
          justifyContent: "space-between",
          marginBottom: 24,
        }}
      >
        <h1 style={{ fontSize: 28, fontWeight: 800, letterSpacing: 4, color: "var(--text)" }}>TEAM</h1>
        <nav style={{ display: "flex", gap: 16 }}>
          <Link href="/team" style={navLink}>
            Members
          </Link>
          <Link href="/team/assignments" style={navLink}>
            Assignments
          </Link>
          <Link href="/team/certifications" style={{ ...navLink, color: "var(--text)", fontWeight: 600 }}>
            Certifications
          </Link>
          <Link href="/team" style={navLink}>
            Daily Crew
          </Link>
        </nav>
      </header>

      {/* Summary banner — D-19 */}
      {(() => {
        const expiring30 = rows.filter((c) => {
          const info = getUrgencyInfo(c.expires_at);
          return info.level === "warning" || info.level === "urgent";
        }).length;
        const expired = rows.filter((c) => getUrgencyInfo(c.expires_at).level === "expired").length;
        if (expiring30 === 0 && expired === 0) return null;
        return (
          <div
            role="alert"
            style={{
              background: "var(--surface)",
              border: "1px solid var(--gold)",
              borderRadius: 10,
              padding: "12px 16px",
              marginBottom: 16,
              display: "flex",
              gap: 16,
              alignItems: "center",
              fontSize: 13,
              fontWeight: 600,
              color: "var(--text)",
            }}
          >
            {expiring30 > 0 && <span>{expiring30} expiring within 30 days</span>}
            {expiring30 > 0 && expired > 0 && <span style={{ color: "var(--muted)" }}>·</span>}
            {expired > 0 && <span style={{ color: "var(--red)" }}>{expired} expired</span>}
          </div>
        );
      })()}

      {/* D-38: Admin-only cert scan status badge */}
      {isAdmin && lastScanInfo.lastScanAt && (
        <div
          aria-label={`Last cert scan: ${timeAgo(lastScanInfo.lastScanAt)}, ${lastScanInfo.alertCount} alerts sent`}
          style={{
            display: "inline-flex",
            alignItems: "center",
            gap: 8,
            background: "var(--panel)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            padding: "6px 12px",
            fontSize: 12,
            color: "var(--muted)",
            marginBottom: 16,
          }}
        >
          <span style={{ width: 8, height: 8, borderRadius: "50%", background: "var(--green)", display: "inline-block" }} />
          Last cert scan: {timeAgo(lastScanInfo.lastScanAt)} &middot; {lastScanInfo.alertCount} alerts sent
        </div>
      )}

      <CertHighlightScroller certId={highlightId} />

      {rows.length ? (
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))",
            gap: 16,
          }}
        >
          {rows.map((c) => {
            const urgency = getUrgencyInfo(c.expires_at);
            const isHighlighted = c.id === highlightId;
            const shouldPulse = urgency.level === "urgent" || urgency.level === "expired";

            return (
              <article
                key={c.id}
                id={`cert-${c.id}`}
                style={{
                  background: isHighlighted ? "var(--panel)" : "var(--surface)",
                  borderRadius: 14,
                  padding: 16,
                  border: isHighlighted
                    ? "2px solid var(--accent)"
                    : "1px solid var(--border)",
                  scrollMarginTop: 80,
                }}
              >
                <h2 style={{ fontSize: 16, fontWeight: 800, color: "var(--text)", marginBottom: 4 }}>
                  {c.name}
                </h2>
                <p style={{ fontSize: 12, color: "var(--muted)", marginBottom: 12 }}>
                  {c.issuer ?? "\u2014"}
                </p>
                <p style={{ fontSize: 13, color: "var(--text)", marginBottom: 4 }}>
                  <strong>Member:</strong> {c.cs_team_members?.name ?? c.member_id}
                </p>
                <p style={{ fontSize: 12, color: "var(--muted)", marginBottom: 12 }}>
                  Issued {c.issued_date ?? "\u2014"}
                </p>
                <p
                  style={{
                    fontSize: 20,
                    fontWeight: 800,
                    letterSpacing: 1,
                    color: urgency.color,
                  }}
                >
                  EXPIRES {c.expires_at ?? "\u2014"}
                </p>
                <p style={{ fontSize: 11, color: "var(--muted)", marginTop: 8 }}>
                  Status: {c.status}
                  {c.document_id ? " \u00b7 Doc attached" : ""}
                </p>

                {/* Urgency badge — D-18 */}
                <span
                  style={{
                    display: "inline-block",
                    marginTop: 8,
                    padding: "3px 10px",
                    borderRadius: 6,
                    fontSize: 11,
                    fontWeight: 700,
                    color: "#fff",
                    background: urgency.color,
                    animation: shouldPulse ? "certPulse 1.5s ease-in-out infinite" : "none",
                  }}
                >
                  {urgency.label}
                </span>

                {/* Update Cert CTA — D-20 */}
                <div style={{ marginTop: 10 }}>
                  <Link
                    href={`/team/certifications/${c.id}/edit`}
                    style={{
                      fontSize: 12,
                      fontWeight: 600,
                      color: "var(--accent)",
                      border: "1px solid var(--accent)",
                      borderRadius: 8,
                      padding: "4px 12px",
                      textDecoration: "none",
                    }}
                  >
                    Update Cert
                  </Link>
                </div>
              </article>
            );
          })}
        </div>
      ) : (
        <section style={{ background: "var(--surface)", borderRadius: 14, padding: 48, textAlign: "center" }}>
          <p style={{ color: "var(--muted)" }}>
            No certifications on file. POST /api/team/certifications to add one.
          </p>
        </section>
      )}
    </main>
  );
}

