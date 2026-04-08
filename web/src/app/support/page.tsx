import { getPageMetadata } from "@/lib/seo";
export const metadata = getPageMetadata("support");
export default function SupportPage() {
  return (
    <div style={{ padding: 20, maxWidth: 800, margin: "0 auto" }}>
      <h1 style={{ fontSize: 28, fontWeight: 900, marginBottom: 8 }}>Support</h1>
      <p style={{ fontSize: 11, color: "var(--muted)", marginBottom: 24 }}>
        We are here to help. Enterprise customers get priority support with SLA-backed response times.
      </p>

      {[
        { title: "1. General Support", content: "Email support@constructionos.world for product questions, billing, or technical help. Include your company name and role for faster routing." },
        { title: "2. Enterprise Support", content: "For enterprise escalations, contact enterprise@constructionos.world with your account ID and a brief incident summary." },
        { title: "3. Security & Privacy", content: "Report security issues to security@constructionos.world. Privacy inquiries go to privacy@constructionos.world." },
        { title: "4. Response Targets", content: "Standard: within 1 business day. Enterprise: within 2 hours for critical incidents, 8 hours for high priority." },
      ].map((section) => (
        <div key={section.title} style={{ marginBottom: 20 }}>
          <h2 style={{ fontSize: 14, fontWeight: 800, color: "var(--accent)", marginBottom: 6 }}>{section.title}</h2>
          <p style={{ fontSize: 12, color: "var(--muted)", lineHeight: 1.7 }}>{section.content}</p>
        </div>
      ))}
    </div>
  );
}
