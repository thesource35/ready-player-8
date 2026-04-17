import Link from "next/link";
import { createServerSupabase } from "@/lib/supabase/server";

export const metadata = { title: "Team Assignments — ConstructionOS" };

type AssignmentRow = {
  id: string;
  project_id: string;
  member_id: string;
  role_on_project: string | null;
  start_date: string | null;
  status: string;
  cs_team_members: { name: string | null } | null;
  cs_projects: { name: string | null } | null;
};

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

export default async function AssignmentsPage() {
  const supabase = await createServerSupabase();
  let rows: AssignmentRow[] = [];
  if (supabase) {
    const { data } = await supabase
      .from("cs_project_assignments")
      .select(
        "id, project_id, member_id, role_on_project, start_date, status, cs_team_members(name), cs_projects(name)"
      )
      .order("start_date", { ascending: false });
    rows = (data as unknown as AssignmentRow[] | null) ?? [];
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
          <Link href="/team/assignments" style={{ ...navLink, color: "var(--text)", fontWeight: 600 }}>
            Assignments
          </Link>
          <Link href="/team/certifications" style={navLink}>
            Certifications
          </Link>
          <Link href="/team" style={navLink}>
            Daily Crew
          </Link>
        </nav>
      </header>
      <section style={{ background: "var(--surface)", borderRadius: 14, padding: 16 }}>
        {rows.length ? (
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr>
                <th style={th}>Member</th>
                <th style={th}>Project</th>
                <th style={th}>Role on Project</th>
                <th style={th}>Start</th>
                <th style={th}>Status</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id} style={{ borderTop: "1px solid var(--border)" }}>
                  <td style={td}>{r.cs_team_members?.name ?? r.member_id}</td>
                  <td style={td}>{r.cs_projects?.name ?? r.project_id}</td>
                  <td style={td}>{r.role_on_project ?? "—"}</td>
                  <td style={td}>{r.start_date ?? "—"}</td>
                  <td style={td}>{r.status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p style={{ padding: 48, textAlign: "center", color: "var(--muted)" }}>
            No assignments yet. POST /api/team/assignments to create one.
          </p>
        )}
      </section>
    </main>
  );
}
