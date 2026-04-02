export default function PrivacyPage() {
  return (
    <div style={{ padding: 20, maxWidth: 800, margin: "0 auto" }}>
      <h1 style={{ fontSize: 28, fontWeight: 900, marginBottom: 8 }}>Privacy Policy</h1>
      <p style={{ fontSize: 11, color: "var(--muted)", marginBottom: 24 }}>Last updated: March 31, 2026 &bull; Effective immediately</p>

      {[
        { title: "1. Information We Collect", content: "We collect information you provide directly (name, email, phone, company, license information), usage data (pages visited, features used, device information), and construction project data you input into the platform." },
        { title: "2. How We Use Your Information", content: "We use your information to provide and improve the Platform, process transactions, verify professional licenses, send notifications, provide AI-powered features, and comply with legal obligations." },
        { title: "3. Data Sharing", content: "We do not sell your personal information. We may share data with: service providers (Supabase, Anthropic AI, payment processors), verification services (state licensing boards), and as required by law." },
        { title: "4. Data Security", content: "We use industry-standard security measures including AES-256 encryption at rest and in transit, Keychain storage for sensitive credentials, biometric authentication, and two-factor authentication." },
        { title: "5. Data Retention", content: "We retain your data for as long as your account is active or as needed to provide services. You may request deletion of your data at any time by contacting privacy@constructionos.world." },
        { title: "6. Your Rights (CCPA/GDPR)", content: "You have the right to: access your personal data, correct inaccurate data, delete your data, port your data, opt out of data sales (we don't sell data), and withdraw consent at any time." },
        { title: "7. Cookies & Tracking", content: "We use essential cookies for authentication and session management. We use analytics to understand usage patterns. You can control cookies through your browser settings." },
        { title: "8. AI Data Usage", content: "Angelic AI processes your queries through Anthropic's Claude API. Conversations may be stored for service improvement. AI responses are not guaranteed to be accurate and should not replace professional advice." },
        { title: "9. Children's Privacy", content: "ConstructionOS is not intended for users under 18. We do not knowingly collect information from minors." },
        { title: "10. Changes to This Policy", content: "We may update this Privacy Policy periodically. We will notify you of material changes via email or in-app notification." },
        { title: "11. Contact", content: "For privacy inquiries: privacy@constructionos.world | Data Protection Officer: dpo@constructionos.world" },
      ].map(s => (
        <div key={s.title} style={{ marginBottom: 20 }}>
          <h2 style={{ fontSize: 14, fontWeight: 800, color: "var(--accent)", marginBottom: 6 }}>{s.title}</h2>
          <p style={{ fontSize: 12, color: "var(--muted)", lineHeight: 1.7 }}>{s.content}</p>
        </div>
      ))}
    </div>
  );
}
