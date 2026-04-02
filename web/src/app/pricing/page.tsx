export default function PricingPage() {
  const tiers = [
    { name: "Field Worker", price: "$9.99", annual: "$99.99/yr", color: "#4AC4CC", desc: "For every trade on the jobsite", features: ["All 31 tabs","56 AI tools","Equipment rentals","Construction network","GPS timecards","Punch list","Cert tracker","Job alerts"], popular: false },
    { name: "Project Manager", price: "$24.99", annual: "$249.99/yr", color: "#FCC757", desc: "For supers, PMs, and estimators", features: ["Everything in Field Worker","Team management (25)","Client portal","Bid analytics","AIA invoicing","Gantt scheduling","CSI cost codes","PDF export"], popular: true },
    { name: "Company Owner", price: "$49.99", annual: "$499.99/yr", color: "#F29E3D", desc: "For GCs and sub owners", features: ["Everything in PM","Unlimited team","AI pricing engine","White-label portal","Priority support","Custom integrations","Market intel reports","Surety bonds"], popular: false },
  ];
  return (
    <div className="max-w-5xl mx-auto px-4 py-16">
      <div className="text-center mb-12">
        <h1 className="text-4xl font-black mb-3">Built for Every Hard Hat</h1>
        <p className="text-[#9EBDC2]">All features included. No lockouts. Unlimited users. Cancel anytime.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-5 mb-16">
        {tiers.map(t => (
          <div key={t.name} className="rounded-2xl p-7 relative" style={{ background: '#0F1C24', border: t.popular ? `2px solid ${t.color}` : '1px solid rgba(51,84,94,0.15)' }}>
            {t.popular && <div className="absolute -top-3 left-1/2 -translate-x-1/2 text-[10px] font-black px-4 py-1 rounded-full text-black" style={{ background: t.color }}>MOST POPULAR</div>}
            <h3 className="text-sm font-black tracking-widest uppercase mb-3" style={{ color: t.color }}>{t.name}</h3>
            <div className="text-4xl font-black text-[#F29E3D]">{t.price}</div>
            <div className="text-xs text-[#9EBDC2]">/month</div>
            <div className="text-xs text-[#69D294] mt-1">{t.annual} (save 17%)</div>
            <p className="text-xs text-[#9EBDC2] mt-3 mb-4">{t.desc}</p>
            <ul className="space-y-2 mb-6">
              {t.features.map(f => <li key={f} className="text-xs text-[#9EBDC2]"><span className="text-[#69D294] font-bold mr-1">✓</span> {f}</li>)}
            </ul>
            <a href="/checkout" className="block w-full py-3 rounded-xl text-sm font-bold text-black text-center" style={{ background: t.color }}>START FREE TRIAL</a>
          </div>
        ))}
      </div>

      {/* Payment Methods */}
      <div className="rounded-2xl p-8 text-center mb-8" style={{ background: 'rgba(105,210,148,0.06)', border: '1px solid rgba(105,210,148,0.15)' }}>
        <h2 className="text-2xl font-black mb-2">💳 Accepted Payment Methods</h2>
        <p className="text-sm text-[#9EBDC2] mb-5">Pay with your preferred method. Secure, instant processing.</p>
        <div className="flex flex-wrap gap-2 justify-center mb-4">
          {["💳 Visa", "💳 Mastercard", "💳 Amex", "🍎 Apple Pay", "G Google Pay", "🏦 Bank Transfer", "📱 PayPal", "🔄 ACH Direct"].map(m => (
            <span key={m} className="text-xs font-bold px-3 py-1.5 rounded-lg" style={{ background: 'rgba(105,210,148,0.1)', border: '1px solid rgba(105,210,148,0.2)', color: '#69D294' }}>{m}</span>
          ))}
        </div>
        <p className="text-xs text-[#69D294]">Powered by Square</p>
        <div className="flex justify-center gap-4 mt-3">
          {["🔒 PCI DSS", "🛡 3D Secure", "✅ SOC 2"].map(b => (
            <span key={b} className="text-[10px] text-[#9EBDC2]">{b}</span>
          ))}
        </div>
      </div>

      <p className="text-center text-xs text-[#9EBDC2] mb-8">All subscriptions include a 7-day free trial · Cancel anytime · Prices in USD · Annual billing saves 17%</p>

      {/* Compare */}
      <div className="mt-16">
        <h2 className="text-2xl font-black text-center mb-8">vs. The Competition</h2>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead><tr><th className="text-left py-3 text-xs text-[#9EBDC2]">Feature</th><th className="text-left py-3 text-xs text-[#9EBDC2]">ConstructionOS</th><th className="text-left py-3 text-xs text-[#9EBDC2]">Others</th></tr></thead>
            <tbody>
              {[["AI Assistant (56 tools)","✓","✗"],["Equipment Rental Marketplace","✓ 97 items","✗"],["Social Network","✓ Feed, DMs","✗"],["Verified Badges","✓ License-checked","✗"],["Financial Infrastructure","✓ Pay, Capital, Bonds","✗"],["Starting Price","$9.99/mo","$20,000+/yr"]].map(([f,us,them]) => (
                <tr key={f} style={{ borderBottom: '1px solid rgba(51,84,94,0.1)' }}>
                  <td className="py-3">{f}</td>
                  <td className="py-3 font-bold text-[#69D294]">{us}</td>
                  <td className="py-3 text-[#D94D48]">{them}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
