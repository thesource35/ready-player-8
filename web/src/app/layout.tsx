import type { Metadata } from "next";
import "./globals.css";
import { Analytics } from "@vercel/analytics/react";
import AngelicAssistant from "./components/AngelicAssistant";
import MobileNav from "./components/MobileNav";

export const metadata: Metadata = {
  title: "ConstructionOS — The Construction Command Center",
  description: "32 tabs, 56 AI tools, equipment rentals, social network, and financial infrastructure for 142,000+ construction professionals.",
  keywords: "construction management, project management, construction software, AI construction, equipment rental, construction network, punch list, daily log, RFI, submittal, change order, AIA pay app, lien waiver, OSHA, safety compliance",
  openGraph: {
    title: "ConstructionOS — The Operating System for Construction",
    description: "Every tool a construction professional needs. From bid to closeout. 32 tabs, 56 AI tools, social network, equipment rentals.",
    url: "https://constructionos.world",
    siteName: "ConstructionOS",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "ConstructionOS — The Construction Command Center",
    description: "32 tabs, 56 AI tools, equipment rentals, social network for 142K+ construction professionals.",
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const navGroups = [
    { label: "CORE", links: [
      { href: "/projects", label: "Projects" }, { href: "/contracts", label: "Contracts" },
      { href: "/market", label: "Market" }, { href: "/maps", label: "Maps" },
      { href: "/feed", label: "Network" },
    ]},
    { label: "INTEL", links: [
      { href: "/ops", label: "Ops" }, { href: "/hub", label: "Hub" },
      { href: "/security", label: "Security" }, { href: "/pricing", label: "Pricing" },
      { href: "/ai", label: "Angelic AI" },
    ]},
    { label: "FIELD", links: [
      { href: "/field", label: "Field Ops" }, { href: "/finance", label: "Finance" },
      { href: "/compliance", label: "Compliance" }, { href: "/clients", label: "Clients" },
      { href: "/analytics", label: "Analytics" },
    ]},
    { label: "PLAN", links: [
      { href: "/schedule", label: "Schedule" }, { href: "/training", label: "Training" },
      { href: "/scanner", label: "Scanner" },
    ]},
    { label: "TRADE", links: [
      { href: "/electrical", label: "Electrical" }, { href: "/tax", label: "Tax" },
    ]},
    { label: "BUILD", links: [
      { href: "/punch", label: "Punch List" }, { href: "/roofing", label: "Roofing" },
      { href: "/smart-build", label: "Smart Build" }, { href: "/contractors", label: "Directory" },
      { href: "/tech", label: "Tech 2026" },
    ]},
    { label: "WEALTH", links: [
      { href: "/wealth", label: "Wealth" }, { href: "/cos-network", label: "COS Net" },
      { href: "/rentals", label: "Rentals" },
    ]},
    { label: "EMPIRE", links: [
      { href: "/empire", label: "Empire" },
      { href: "/settings", label: "Settings" },
    ]},
  ];

  return (
    <html lang="en" className="dark">
      <head>
        <link rel="manifest" href="/manifest.json" />
        <meta name="theme-color" content="#F29E3D" />
        <link rel="apple-touch-icon" href="/logo.png" />
      </head>
      <body className="min-h-screen">
        <nav className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 py-3" style={{ background: 'rgba(8,14,18,0.95)', backdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(51,84,94,0.2)' }}>
          <a href="/" className="flex items-center gap-2 shrink-0">
            <img src="/logo-sm.png" alt="ConstructionOS" className="w-8 h-8 rounded-lg" />
            <span className="text-base font-black tracking-wide text-[#F0F8F8]">CONSTRUCT<span className="text-[#F29E3D]">OS</span></span>
          </a>
          <div className="hidden lg:flex items-center gap-1 overflow-x-auto mx-4" style={{ scrollbarWidth: 'none' }}>
            {navGroups.map(g => (
              <div key={g.label} className="flex items-center gap-1">
                <span className="text-[7px] font-black tracking-widest px-1" style={{ color: 'rgba(158,189,194,0.3)' }}>{g.label}</span>
                {g.links.map(l => (
                  <a key={l.href} href={l.href} className="text-[11px] font-semibold px-2 py-1 rounded hover:bg-[#162832] whitespace-nowrap" style={{ color: '#9EBDC2' }}>{l.label}</a>
                ))}
                <span className="mx-1" style={{ color: 'rgba(51,84,94,0.3)' }}>|</span>
              </div>
            ))}
          </div>
          <div className="hidden lg:flex items-center gap-3 shrink-0">
            <a href="/login" className="text-sm font-bold text-[#F29E3D]">Sign In</a>
            <a href="/login" className="px-4 py-2 rounded-lg text-sm font-bold text-black" style={{ background: 'linear-gradient(90deg, #F29E3D, #FCC757)' }}>Get Started</a>
          </div>
          <MobileNav />
        </nav>
        <main className="pt-14">{children}</main>
        <AngelicAssistant />
        <Analytics />
        <footer className="text-center py-10" style={{ borderTop: '1px solid rgba(51,84,94,0.1)' }}>
          <div className="flex justify-center gap-6 mb-4 flex-wrap">
            <a href="/projects" className="text-xs text-[#9EBDC2]">Projects</a>
            <a href="/ai" className="text-xs text-[#9EBDC2]">Angelic AI</a>
            <a href="/rentals" className="text-xs text-[#9EBDC2]">Rentals</a>
            <a href="/pricing" className="text-xs text-[#9EBDC2]">Pricing</a>
            <a href="/terms" className="text-xs text-[#9EBDC2]">Terms</a>
            <a href="/privacy" className="text-xs text-[#9EBDC2]">Privacy</a>
            <a href="https://github.com/thesource35/ready-player-8" className="text-xs text-[#9EBDC2]">GitHub</a>
          </div>
          <p className="text-xs" style={{ color: 'rgba(158,189,194,0.4)' }}>ConstructionOS © 2026 Donovan Fagan · Built for the builders</p>
        </footer>
      </body>
    </html>
  );
}
