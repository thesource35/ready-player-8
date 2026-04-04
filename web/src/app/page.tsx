import Image from "next/image";
import Link from "next/link";
import AngelicFlowStrip from "./components/AngelicFlowStrip";
import FeatureAccessLink from "./components/FeatureAccessLink";

export default function Home() {
  const stats = [
    { num: "32", label: "Tabs" },
    { num: "56", label: "AI Tools" },
    { num: "97", label: "Rental Items" },
    { num: "6", label: "Providers" },
    { num: "142K+", label: "Professionals" },
    { num: "29K+", label: "Lines of Code" },
  ];

  const platformSections = [
    { group: "CORE", color: "#F29E3D", items: [
      { icon: "⌘", title: "Command Center", desc: "Real-time site risk scores, weather overlays, crew deployment, daily standup reports, inspection tracker.", href: "/" },
      { icon: "🏗", title: "Projects", desc: "Full project lifecycle management with real-time sync, scoring, status tracking, and CRUD operations.", href: "/projects" },
      { icon: "📋", title: "Contracts", desc: "Bid pipeline with 7-stage workflow, scoring algorithm, watcher counts, and deadline tracking.", href: "/contracts" },
      { icon: "📊", title: "Market Intelligence", desc: "8 metro markets with vacancy rates, permits, PSF data, bid opportunities, and trend insights.", href: "/market" },
      { icon: "🗺", title: "Live Maps", desc: "Satellite-backed site awareness with thermal/crew/weather overlays, delivery routes, and camera presets.", href: "/maps" },
      { icon: "👥", title: "Construction Network", desc: "Social feed, stories, DMs, job board, equipment marketplace, company pages, crew directory.", href: "/feed" },
    ]},
    { group: "INTEL", color: "#4AC4CC", items: [
      { icon: "⚙️", title: "12-Panel Ops Suite", desc: "Change orders, safety incidents, RFIs, submittals, priority alerts, action queue, commander reports.", href: "/ops" },
      { icon: "🔌", title: "Integration Hub", desc: "Supabase, Firebase, Outlook, QuickBooks, Microsoft 365, Procore, PlanGrid, DocuSign, webhooks.", href: "/hub" },
      { icon: "🔐", title: "Security & Access", desc: "Face ID, Touch ID, 2FA (authenticator/SMS/email), Keychain, AES-256, session management, audit log.", href: "/security" },
      { icon: "💲", title: "AI Pricing Engine", desc: "3 subscription tiers, competition comparison, ROI calculator.", href: "/pricing" },
      { icon: "🏗", title: "Angelic AI (56 Tools)", desc: "Claude-powered AI with 56 MCP tools, live data access, construction-specific knowledge.", href: "/ai" },
    ]},
    { group: "FIELD & FINANCE", color: "#69D294", items: [
      { icon: "📱", title: "Field Operations", desc: "Daily logs with weather, timecards with OT calc, equipment tracker, permit management.", href: "/field" },
      { icon: "💵", title: "Finance Hub", desc: "AIA G702/G703 pay apps, lien waiver manager (4 types), cash flow forecast.", href: "/finance" },
      { icon: "🛡", title: "Compliance", desc: "8 weekly toolbox talks, WH-347 certified payroll, SWPPP/environmental compliance tracker.", href: "/compliance" },
      { icon: "👤", title: "Client Portal", desc: "Owner dashboard with progress bars, material selections, warranty tracker, OAC meeting minutes.", href: "/clients" },
      { icon: "📈", title: "Analytics & AI Risk", desc: "Bid win/loss by sector, labor productivity benchmarks, ML-based project risk scoring.", href: "/analytics" },
    ]},
    { group: "PLANNING", color: "#8A8FCC", items: [
      { icon: "📅", title: "Schedule & Gantt", desc: "26-week Gantt chart with critical path, milestones, 3-week lookahead, trade sequencing.", href: "/schedule" },
      { icon: "🎓", title: "Training & Certs", desc: "OSHA 30, CPR/AED, confined space, PMP — course catalog with progress and cert tracking.", href: "/training" },
      { icon: "📷", title: "QR & Barcode Scanner", desc: "Crew badge sign-in, material PO verification, equipment tags, document scanning, inventory.", href: "/scanner" },
    ]},
    { group: "TRADE", color: "#FCC757", items: [
      { icon: "⚡", title: "Electrical & Fiber", desc: "6 trade categories, verified contractors with ratings, job leads, fiber FTTH projects.", href: "/electrical" },
      { icon: "💰", title: "Tax Accountant", desc: "12 IRS categories, deduction tracker, quarterly estimates, 1099 filing, CPA directory.", href: "/tax" },
    ]},
    { group: "BUILD", color: "#D94D48", items: [
      { icon: "✅", title: "Punch List Pro", desc: "Items with priority/trade/assignee, photo documentation, status workflow, location tracking.", href: "/punch" },
      { icon: "🏠", title: "Satellite Roofing", desc: "AI roof estimator with 9 materials, pitch calculator, full cost breakdown with labor/permits.", href: "/roofing" },
      { icon: "🧪", title: "Smart Build Hub", desc: "Concrete AI, BIM clash detection, net zero design, modular construction, auto home.", href: "/smart-build" },
      { icon: "📖", title: "Contractor Directory", desc: "12+ contractors, 25 trades, 6 countries, verified with ratings, revenue, specialties.", href: "/contractors" },
      { icon: "🤖", title: "Tech 2026", desc: "Digital twins, construction robotics, 3D scanning, sustainability, wearables, 5G/IoT, AI/ML.", href: "/tech" },
    ]},
    { group: "WEALTH & EMPIRE", color: "#FCC757", items: [
      { icon: "💎", title: "Wealth Intelligence", desc: "Money Lens, Psychology Decoder, Power Thinking, Leverage System, Opportunity Filter.", href: "/wealth" },
      { icon: "⭐", title: "Trust & Reputation", desc: "Credentials, peer endorsements, client reviews, photo proof — combined into a trust score.", href: "/trust" },
      { icon: "🛠", title: "Equipment Rentals", desc: "97 items, 20 categories, 6 providers (United Rentals, DOZR, etc.), AI recommender, bundles.", href: "/rentals" },
      { icon: "🏦", title: "Financial Empire", desc: "Pay (1.5% processing), Capital (invoice factoring), Insurance, Workforce, Supply Chain, Bonds, Intelligence.", href: "/empire" },
      { icon: "⚙️", title: "Settings & Profile", desc: "Role presets (Superintendent/PM/Executive), security toggles, subscription management, data export.", href: "/settings" },
    ]},
  ];

  const verificationTiers = [
    { tier: "Identity Verified", price: "FREE", icon: "✅", color: "#69D294", features: ["Email & phone verified", "Basic profile badge", "Access to public feed", "View job listings"] },
    { tier: "Licensed Professional", price: "$27.99/mo", icon: "🏆", color: "#FCC757", features: ["State license verification", "Gold verification badge", "Priority in search", "Bid on projects", "Post job listings"] },
    { tier: "Verified Company", price: "$49.99/mo", icon: "🏢", color: "#4AC4CC", features: ["Business license verified", "Company page + portfolio", "Unlimited job postings", "Equipment marketplace", "Analytics + API access"] },
  ];

  return (
    <div>
      {/* Hero */}
      <section className="text-center py-20 px-5 relative overflow-hidden" style={{ background: 'linear-gradient(180deg, #0F1C24 0%, #080E12 100%)' }}>
        <div className="relative z-10 max-w-4xl mx-auto">
          <div className="inline-block px-4 py-1.5 rounded-full text-xs font-bold tracking-wide mb-3" style={{ background: 'rgba(242,158,61,0.1)', border: '1px solid rgba(242,158,61,0.2)', color: '#F29E3D' }}>🚀 NOW ON THE APP STORE &amp; WEB</div>
          <div className="text-sm font-bold tracking-wide mb-5" style={{ color: '#4AC4CC' }}>Build this network</div>
          <div className="flex justify-center mb-5">
            <Image src="/logo.png" alt="ConstructionOS logo" width={96} height={96} className="rounded-2xl shadow-2xl" style={{ boxShadow: '0 0 60px rgba(242,158,61,0.3)' }} priority />
          </div>
          <h1 className="text-5xl md:text-7xl font-black tracking-wider mb-3">CONSTRUCT<span className="text-[#F29E3D]">OS</span></h1>
          <p className="text-lg md:text-xl text-[#9EBDC2] mb-2 max-w-2xl mx-auto">The operating system for the $13 trillion construction industry. Every tool a construction professional needs — from bid to closeout.</p>
          <div className="text-sm font-bold tracking-wide mb-8" style={{ color: '#4AC4CC' }}>Build this network</div>
          <div className="flex gap-6 justify-center mb-10 flex-wrap">
            {stats.map(s => (
              <div key={s.label} className="text-center">
                <div className="text-3xl md:text-4xl font-black text-[#F29E3D]">{s.num}</div>
                <div className="text-[10px] text-[#9EBDC2] tracking-widest uppercase">{s.label}</div>
              </div>
            ))}
          </div>
          <div className="flex gap-3 justify-center flex-wrap">
            <Link href="/login" className="px-8 py-4 rounded-xl text-base font-bold text-black" style={{ background: 'linear-gradient(90deg, #F29E3D, #FCC757)' }}>GET STARTED FREE</Link>
            <FeatureAccessLink feature="feed" paidHref="/feed" className="px-8 py-4 rounded-xl text-base font-bold text-[#4AC4CC] border-2 border-[#4AC4CC]">Join the Network</FeatureAccessLink>
            <a href="#features" className="px-8 py-4 rounded-xl text-base font-bold text-[#9EBDC2] border border-[#33545E]">See All Features</a>
          </div>
        </div>
      </section>

      <section className="max-w-6xl mx-auto px-5 py-8">
        <AngelicFlowStrip
          prompts={[
            "What plan fits a growing GC?",
            "Show me project risk examples",
            "How can Angelic help with rental quotes?",
          ]}
        />
      </section>

      {/* Network Preview */}
      <section className="max-w-6xl mx-auto px-5 py-16">
        <div className="text-center mb-10">
          <div className="text-xs font-black tracking-[0.3em] text-[#F29E3D] mb-2">THE CONSTRUCTION NETWORK</div>
          <h2 className="text-3xl md:text-4xl font-black mb-3">Instagram for Construction. <span className="text-[#4AC4CC]">Built for Builders.</span></h2>
          <p className="text-[#9EBDC2] max-w-xl mx-auto">Post project updates, hire crews, sell equipment, DM professionals, and build your company page — all in one network.</p>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-8">
          {[
            { icon: "📱", label: "Social Feed", desc: "Project updates & industry news", color: "#F29E3D" },
            { icon: "💼", label: "Job Board", desc: "Post & find construction jobs", color: "#69D294", href: "/jobs", feature: "jobs" },
            { icon: "🏗", label: "Equipment Market", desc: "Buy, sell & rent equipment", color: "#FCC757" },
            { icon: "💬", label: "Direct Messages", desc: "Encrypted professional messaging", color: "#4AC4CC" },
            { icon: "🏢", label: "Company Pages", desc: "Verified profiles + portfolios", color: "#8A8FCC" },
          ].map(f => (
            <FeatureAccessLink key={f.label} feature={f.feature ?? "feed"} paidHref={f.href ?? "/feed"} previewHref={f.feature === "jobs" ? "/jobs" : undefined} className="rounded-xl p-4 text-center block hover:-translate-y-1 transition-transform" style={{ background: '#0F1C24', border: `1px solid ${f.color}20` }}>
              <div className="text-2xl mb-2">{f.icon}</div>
              <div className="text-xs font-bold" style={{ color: f.color }}>{f.label}</div>
              <div className="text-[10px] text-[#9EBDC2] mt-1">{f.desc}</div>
            </FeatureAccessLink>
          ))}
        </div>
        <div className="text-center">
          <FeatureAccessLink feature="feed" paidHref="/feed" className="px-6 py-3 rounded-xl text-sm font-bold text-black inline-block" style={{ background: 'linear-gradient(90deg, #4AC4CC, #69D294)' }}>Explore the Network →</FeatureAccessLink>
        </div>
      </section>

      {/* Verification System */}
      <section className="py-16 px-5" style={{ background: '#0A1218' }}>
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-10">
            <div className="text-xs font-black tracking-[0.3em] text-[#FCC757] mb-2">TRUST &amp; SAFETY</div>
            <h2 className="text-3xl font-black mb-3">3-Tier Verification System</h2>
            <p className="text-[#9EBDC2]">License checking against state databases. Get verified to stand out.</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {verificationTiers.map(t => (
              <div key={t.tier} className="rounded-2xl p-6 text-center" style={{ background: '#0F1C24', border: `1px solid ${t.color}30` }}>
                <div className="text-4xl mb-3">{t.icon}</div>
                <h3 className="text-lg font-black mb-1" style={{ color: t.color }}>{t.tier}</h3>
                <div className="text-2xl font-black mb-4">{t.price}</div>
                {t.features.map(f => (
                  <div key={f} className="text-xs text-[#9EBDC2] py-1.5 border-t" style={{ borderColor: 'rgba(51,84,94,0.2)' }}>✓ {f}</div>
                ))}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* All Features by Group */}
      <section id="features" className="max-w-6xl mx-auto px-5 py-16" style={{ scrollMarginTop: 80 }}>
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-black mb-3">Every Feature. <span className="text-[#4AC4CC]">One Platform.</span></h2>
          <p className="text-[#9EBDC2]">32 tabs, 56 AI tools — from bid to closeout. Click any feature to explore.</p>
        </div>
        {platformSections.map(section => (
          <div key={section.group} className="mb-12">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-1 h-6 rounded-full" style={{ background: section.color }} />
              <h3 className="text-sm font-black tracking-[0.2em]" style={{ color: section.color }}>{section.group}</h3>
              <div className="flex-1 h-px" style={{ background: `${section.color}20` }} />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {section.items.map(f => (
                f.href === "/" ? (
                  <Link key={f.title} href={f.href} className="rounded-xl p-5 block transition-all hover:-translate-y-0.5 hover:shadow-lg" style={{ background: '#0F1C24', border: '1px solid rgba(74,196,204,0.06)' }}>
                    <div className="text-2xl mb-2">{f.icon}</div>
                    <h4 className="text-sm font-bold text-[#F29E3D] mb-1.5">{f.title}</h4>
                    <p className="text-xs text-[#9EBDC2] leading-relaxed">{f.desc}</p>
                  </Link>
                ) : (
                  <FeatureAccessLink key={f.title} feature={f.href.slice(1)} paidHref={f.href} className="rounded-xl p-5 block transition-all hover:-translate-y-0.5 hover:shadow-lg" style={{ background: '#0F1C24', border: '1px solid rgba(74,196,204,0.06)' }}>
                    <div className="text-2xl mb-2">{f.icon}</div>
                    <h4 className="text-sm font-bold text-[#F29E3D] mb-1.5">{f.title}</h4>
                    <p className="text-xs text-[#9EBDC2] leading-relaxed">{f.desc}</p>
                  </FeatureAccessLink>
                )
              ))}
            </div>
          </div>
        ))}
      </section>

      {/* Financial Empire */}
      <section className="max-w-5xl mx-auto px-5 py-16">
        <div className="text-center mb-10">
          <div className="text-xs font-black tracking-[0.3em] text-[#F29E3D] mb-2">FINANCIAL INFRASTRUCTURE</div>
          <h2 className="text-3xl font-black mb-3">The Financial Empire</h2>
          <p className="text-[#9EBDC2]">7 financial products built for construction. Think Stripe + Plaid + Gusto for builders.</p>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {[
            { icon: "💵", name: "Pay", desc: "1.5% processing", color: "#69D294" },
            { icon: "🏦", name: "Capital", desc: "Invoice factoring", color: "#F29E3D" },
            { icon: "🛡", name: "Insurance", desc: "GL, WC, Builder's Risk", color: "#4AC4CC" },
            { icon: "👥", name: "Workforce", desc: "Payroll & benefits", color: "#FCC757" },
            { icon: "📦", name: "Supply Chain", desc: "Vendor management", color: "#8A8FCC" },
            { icon: "📜", name: "Bonds", desc: "Bid, performance, payment", color: "#D94D48" },
            { icon: "📊", name: "Intelligence", desc: "Market data & analytics", color: "#4AC4CC" },
          ].map(p => (
            <FeatureAccessLink key={p.name} feature="empire" paidHref="/empire" className="rounded-xl p-4 text-center block hover:-translate-y-1 transition-transform" style={{ background: '#0F1C24', border: `1px solid ${p.color}20` }}>
              <div className="text-2xl mb-1">{p.icon}</div>
              <div className="text-xs font-bold" style={{ color: p.color }}>{p.name}</div>
              <div className="text-[9px] text-[#9EBDC2] mt-1">{p.desc}</div>
            </FeatureAccessLink>
          ))}
        </div>
        <div className="text-center">
          <FeatureAccessLink feature="empire" paidHref="/empire" className="px-6 py-3 rounded-xl text-sm font-bold text-black inline-block" style={{ background: 'linear-gradient(90deg, #F29E3D, #FCC757)' }}>Explore the Empire →</FeatureAccessLink>
        </div>
      </section>

      {/* Pricing Preview */}
      <section className="py-16 px-5" style={{ background: '#0A1218' }}>
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-10">
            <h2 className="text-3xl font-black mb-3">Simple Pricing. <span className="text-[#69D294]">Built for Every Role.</span></h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5 mb-8">
            {[
              { name: "Field Worker", price: "$9.99", desc: "Daily logs, timecards, safety, basic AI", color: "#69D294" },
              { name: "Project Manager", price: "$27.99", desc: "Full ops suite, scheduling, analytics, AI tools", color: "#F29E3D", featured: true },
              { name: "Company Owner", price: "$49.99", desc: "Financial empire, multi-project, API, custom branding", color: "#4AC4CC" },
            ].map(p => (
              <div key={p.name} className="rounded-2xl p-6 text-center" style={{ background: '#0F1C24', border: p.featured ? '2px solid #F29E3D' : '1px solid rgba(51,84,94,0.2)' }}>
                {p.featured && <div className="text-[9px] font-black text-[#F29E3D] mb-2">MOST POPULAR</div>}
                <h3 className="text-lg font-black mb-1">{p.name}</h3>
                <div className="text-3xl font-black mb-1" style={{ color: p.color }}>{p.price}<span className="text-sm text-[#9EBDC2]">/mo</span></div>
                <p className="text-xs text-[#9EBDC2] mb-4">{p.desc}</p>
                <Link href={p.featured ? "/checkout?plan=pm" : "/pricing"} className="block py-2.5 rounded-lg text-sm font-bold" style={{ background: p.featured ? 'linear-gradient(90deg, #F29E3D, #FCC757)' : '#162832', color: p.featured ? '#000' : '#9EBDC2' }}>
                  {p.featured ? 'Get Started' : 'View Plan'}
                </Link>
              </div>
            ))}
          </div>
          <p className="text-center text-xs text-[#9EBDC2]">Cancel anytime • No long-term contracts • <Link href="/pricing" className="text-[#F29E3D]">Full comparison →</Link></p>
        </div>
      </section>

      {/* Equipment Rentals Preview */}
      <section className="max-w-5xl mx-auto px-5 py-16">
        <div className="text-center mb-10">
          <div className="text-xs font-black tracking-[0.3em] text-[#4AC4CC] mb-2">EQUIPMENT MARKETPLACE</div>
          <h2 className="text-3xl font-black mb-3">97 Items. 6 Providers. <span className="text-[#FCC757]">AI Recommender.</span></h2>
          <p className="text-[#9EBDC2]">United Rentals, Sunbelt, DOZR, BigRentz, ToolSy, RentMyEquipment — all in one search.</p>
        </div>
        <div className="grid grid-cols-3 md:grid-cols-6 gap-3 mb-6">
          {["United Rentals", "Sunbelt", "DOZR", "BigRentz", "ToolSy", "RentMyEquip"].map(p => (
            <div key={p} className="rounded-lg p-3 text-center" style={{ background: '#0F1C24' }}>
              <div className="text-[10px] font-bold text-[#FCC757]">{p}</div>
            </div>
          ))}
        </div>
        <div className="text-center">
          <FeatureAccessLink feature="rentals" paidHref="/rentals" className="px-6 py-3 rounded-xl text-sm font-bold text-black inline-block" style={{ background: 'linear-gradient(90deg, #4AC4CC, #69D294)' }}>Browse Equipment →</FeatureAccessLink>
        </div>
      </section>

      {/* CTA */}
      <section className="text-center py-20 px-5" style={{ background: 'linear-gradient(180deg, #080E12, #0F1C24)' }}>
        <div className="flex justify-center mb-6">
          <Image src="/logo.png" alt="ConstructionOS logo" width={64} height={64} className="rounded-xl" style={{ boxShadow: '0 0 40px rgba(242,158,61,0.2)' }} />
        </div>
        <h2 className="text-3xl md:text-4xl font-black mb-4">Ready to Command Your Jobsite?</h2>
        <p className="text-[#9EBDC2] mb-8 max-w-lg mx-auto">Join 142,891 construction professionals using ConstructionOS to manage projects, crews, finances, and everything in between.</p>
        <div className="flex gap-3 justify-center flex-wrap">
          <Link href="/login" className="px-10 py-4 rounded-xl text-lg font-bold text-black" style={{ background: 'linear-gradient(90deg, #F29E3D, #FCC757)' }}>GET STARTED FREE</Link>
          <FeatureAccessLink feature="feed" paidHref="/feed" className="px-10 py-4 rounded-xl text-lg font-bold text-[#4AC4CC] border-2 border-[#4AC4CC]">Join the Network</FeatureAccessLink>
        </div>
        <div className="flex justify-center gap-8 mt-10">
          {[
            { label: "iOS App", status: "On the App Store" },
            { label: "Web App", status: "constructionos.world" },
            { label: "macOS", status: "Universal Binary" },
            { label: "visionOS", status: "Spatial Computing" },
          ].map(p => (
            <div key={p.label} className="text-center">
              <div className="text-xs font-black text-[#F29E3D]">{p.label}</div>
              <div className="text-[9px] text-[#9EBDC2]">{p.status}</div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
