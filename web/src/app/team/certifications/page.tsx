import Link from "next/link";
import { createServerSupabase } from "@/lib/supabase/server";

export const metadata = { title: "Team Certifications — ConstructionOS" };

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

const navLink: React.CSSProperties = { color: "var(--muted)", textDecoration: "none", fontSize: 14 };

// D-06 / UI-SPEC "license card": expires_at is visually prominent. Color-code by proximity.
function expiryColor(expires: string | null): string {
  if (!expires) return "var(--muted)";
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const exp = new Date(expires);
  const diffDays = (exp.getTime() - today.getTime()) / (1000 * 60 * 60 * 24);
  if (diffDays < 0) return "var(--red)";
  if (diffDays < 30) return "var(--gold)";
  return "var(--text)";
}

export default async function CertificationsPage() {
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

  return (
    <main style={{ padding: 32, maxWidth: 1200, margin: "0 auto" }}>
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
        </nav>
      </header>

      {rows.length ? (
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))",
            gap: 16,
          }}
        >
          {rows.map((c) => (
            <article
              key={c.id}
              style={{
                background: "var(--surface)",
                borderRadius: 14,
                padding: 16,
                border: "1px solid var(--border)",
              }}
            >
              <h2 style={{ fontSize: 16, fontWeight: 800, color: "var(--text)", marginBottom: 4 }}>
                {c.name}
              </h2>
              <p style={{ fontSize: 12, color: "var(--muted)", marginBottom: 12 }}>
                {c.issuer ?? "—"}
              </p>
              <p style={{ fontSize: 13, color: "var(--text)", marginBottom: 4 }}>
                <strong>Member:</strong> {c.cs_team_members?.name ?? c.member_id}
              </p>
              <p style={{ fontSize: 12, color: "var(--muted)", marginBottom: 12 }}>
                Issued {c.issued_date ?? "—"}
              </p>
              <p
                style={{
                  fontSize: 20,
                  fontWeight: 800,
                  letterSpacing: 1,
                  color: expiryColor(c.expires_at),
                }}
              >
                EXPIRES {c.expires_at ?? "—"}
              </p>
              <p style={{ fontSize: 11, color: "var(--muted)", marginTop: 8 }}>
                Status: {c.status}
                {c.document_id ? " · Doc attached" : ""}
              </p>
            </article>
          ))}
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
