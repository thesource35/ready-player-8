"use client"
import { useEffect, useState } from "react"
import { certUrgency } from "@/lib/certifications/urgency"

type CertSummary = { safe: number; warning: number; urgent: number; expired: number; total: number }

export function CertComplianceWidget() {
  const [summary, setSummary] = useState<CertSummary | null>(null)

  useEffect(() => {
    let cancelled = false
    fetch("/api/team/certifications")
      .then(r => r.ok ? r.json() : { data: [] })
      .then(({ data }) => {
        if (cancelled) return
        const rows = (data ?? []) as { expires_at: string | null }[]
        const s: CertSummary = { safe: 0, warning: 0, urgent: 0, expired: 0, total: rows.length }
        for (const r of rows) {
          s[certUrgency(r.expires_at)]++
        }
        setSummary(s)
      })
      .catch(() => {})
    return () => { cancelled = true }
  }, [])

  if (!summary || summary.total === 0) return null
  const renewalRate = Math.round((summary.safe / summary.total) * 100)

  return (
    <div style={{
      background: "var(--surface)", borderRadius: 14, padding: 20,
      border: "1px solid var(--border)",
    }}>
      <h3 style={{ fontSize: 14, fontWeight: 800, letterSpacing: 2, color: "var(--text)", marginBottom: 12 }}>
        CERT COMPLIANCE
      </h3>
      <div style={{ display: "flex", gap: 16, flexWrap: "wrap" }}>
        <div style={{ textAlign: "center" }}>
          <span style={{ fontSize: 28, fontWeight: 800, color: "var(--green)" }}>{summary.safe}</span>
          <p style={{ fontSize: 11, color: "var(--muted)" }}>Valid</p>
        </div>
        <div style={{ textAlign: "center" }}>
          <span style={{ fontSize: 28, fontWeight: 800, color: "var(--gold)" }}>{summary.warning}</span>
          <p style={{ fontSize: 11, color: "var(--muted)" }}>Expiring Soon</p>
        </div>
        <div style={{ textAlign: "center" }}>
          <span style={{ fontSize: 28, fontWeight: 800, color: "var(--red)" }}>{summary.urgent + summary.expired}</span>
          <p style={{ fontSize: 11, color: "var(--muted)" }}>Urgent/Expired</p>
        </div>
      </div>
      <p style={{ fontSize: 12, color: "var(--muted)", marginTop: 12 }}>
        Renewal rate: {renewalRate}% current
      </p>
    </div>
  )
}
