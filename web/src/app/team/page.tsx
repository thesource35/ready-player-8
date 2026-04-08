import Link from "next/link";
import { createServerSupabase } from "@/lib/supabase/server";
import type { TeamMember } from "@/lib/supabase/types";

export const metadata = { title: "Team — ConstructionOS" };

const th: React.CSSProperties = {
  textAlign: "left",
  fontSize: 12,
  fontWeight: 600,
  letterSpacing: 2,
  color: "var(--muted)",
  padding: 8,
  textTransform: "uppercase",
};
const td: React.CSSProperties = { padding: 8, fontSize: 14, color: "var(--text)" };
const navLink: React.CSSProperties = { color: "var(--muted)", textDecoration: "none", fontSize: 14 };

export default async function TeamPage() {
  const supabase = await createServerSupabase();
  let members: TeamMember[] = [];
  if (supabase) {
    const { data } = await supabase
      .from("cs_team_members")
      .select("id, kind, user_id, name, role, trade, email, phone, company, notes, created_at, updated_at")
      .order("name");
    members = (data as TeamMember[] | null) ?? [];
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
          <Link href="/team" style={{ ...navLink, color: "var(--text)", fontWeight: 600 }}>
            Members
          </Link>
          <Link href="/team/assignments" style={navLink}>
            Assignments
          </Link>
          <Link href="/team/certifications" style={navLink}>
            Certifications
          </Link>
        </nav>
      </header>
      <section style={{ background: "var(--surface)", borderRadius: 14, padding: 16 }}>
        {members.length ? (
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr>
                <th style={th}>Name</th>
                <th style={th}>Kind</th>
                <th style={th}>Role</th>
                <th style={th}>Trade</th>
                <th style={th}>Company</th>
              </tr>
            </thead>
            <tbody>
              {members.map((m) => (
                <tr key={m.id} style={{ borderTop: "1px solid var(--border)" }}>
                  <td style={td}>{m.name}</td>
                  <td style={td}>{m.kind}</td>
                  <td style={td}>{m.role ?? "—"}</td>
                  <td style={td}>{m.trade ?? "—"}</td>
                  <td style={td}>{m.company ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p style={{ padding: 48, textAlign: "center", color: "var(--muted)" }}>
            No team members yet. Add one via POST /api/team.
          </p>
        )}
      </section>
    </main>
  );
}
