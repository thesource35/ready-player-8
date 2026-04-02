export default function TermsPage() {
  return (
    <div style={{ padding: 20, maxWidth: 800, margin: "0 auto" }}>
      <h1 style={{ fontSize: 28, fontWeight: 900, marginBottom: 8 }}>Terms and Conditions</h1>
      <p style={{ fontSize: 11, color: "var(--muted)", marginBottom: 24 }}>Last updated: March 31, 2026 &bull; Effective immediately</p>

      {[
        { title: "1. Acceptance of Terms", content: "By accessing or using ConstructionOS (\"the Platform\"), you agree to be bound by these Terms and Conditions. If you do not agree, do not use the Platform. ConstructionOS reserves the right to modify these terms at any time." },
        { title: "2. Platform Description", content: "ConstructionOS is a construction management platform providing project management, AI tools, equipment rentals, financial infrastructure, social networking, and related services for construction professionals." },
        { title: "3. User Accounts", content: "You must provide accurate information when creating an account. You are responsible for maintaining the confidentiality of your credentials and for all activities under your account. You must be at least 18 years old to use the Platform." },
        { title: "4. Subscription & Payments", content: "Paid features require a subscription processed through the Apple App Store or authorized payment processors. All payments are processed by Square. Subscriptions auto-renew unless cancelled 24 hours before the end of the current period." },
        { title: "5. Verification System", content: "Our 3-tier verification system (Identity, Licensed, Company) verifies credentials against state databases. Verification badges do not constitute an endorsement. Users are responsible for maintaining valid licenses." },
        { title: "6. Intellectual Property", content: "All content, features, and functionality of ConstructionOS are owned by the company and protected by intellectual property laws. Users retain ownership of their own data but grant ConstructionOS a license to use it for platform operations." },
        { title: "7. Limitation of Liability", content: "TO THE MAXIMUM EXTENT PERMITTED BY LAW, CONSTRUCTIONOS'S TOTAL LIABILITY SHALL NOT EXCEED $100 USD OR THE AMOUNT YOU PAID IN THE LAST 12 MONTHS, WHICHEVER IS LESS. WE ARE NOT LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES." },
        { title: "8. Mandatory Arbitration", content: "Any dispute arising from these Terms shall be resolved through binding arbitration under the American Arbitration Association rules. Arbitration shall take place in Houston, Texas. YOU WAIVE YOUR RIGHT TO A JURY TRIAL." },
        { title: "9. Class Action Waiver", content: "YOU AGREE TO RESOLVE DISPUTES ONLY ON AN INDIVIDUAL BASIS AND WAIVE ANY RIGHT TO PARTICIPATE IN A CLASS ACTION LAWSUIT OR CLASS-WIDE ARBITRATION." },
        { title: "10. Governing Law", content: "These Terms are governed by the laws of the State of Texas, without regard to conflict of law principles." },
        { title: "11. Contact", content: "For questions about these Terms, contact: legal@constructionos.world" },
      ].map(s => (
        <div key={s.title} style={{ marginBottom: 20 }}>
          <h2 style={{ fontSize: 14, fontWeight: 800, color: "var(--accent)", marginBottom: 6 }}>{s.title}</h2>
          <p style={{ fontSize: 12, color: "var(--muted)", lineHeight: 1.7 }}>{s.content}</p>
        </div>
      ))}
    </div>
  );
}
