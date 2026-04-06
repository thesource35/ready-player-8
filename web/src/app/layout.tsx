import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { Suspense } from "react";
import "./globals.css";
import { Analytics } from "@vercel/analytics/react";
import AngelicAssistant from "./components/AngelicAssistant";
import MobileNav from "./components/MobileNav";
import FeatureAccessLink from "./components/FeatureAccessLink";
import ExternalLink from "./components/ExternalLink";
import { githubRepoUrl } from "@/lib/links/externalLinks";

export const metadata: Metadata = {
  title: "ConstructionOS — The Construction Command Center",
  description: "32 tabs, 56 AI tools, equipment rentals, social network, and financial infrastructure for construction professionals.",
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
    description: "32 tabs, 56 AI tools, equipment rentals, social network for construction professionals.",
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <head>
        <link rel="manifest" href="/manifest.json" />
        <meta name="theme-color" content="#F29E3D" />
        <link rel="apple-touch-icon" href="/logo.png" />
      </head>
      <body className="min-h-screen">
        <nav className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 py-3" style={{ background: 'rgba(8,14,18,0.95)', backdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(51,84,94,0.2)' }}>
          <Link href="/" className="flex items-center gap-2 shrink-0">
            <Image src="/logo-sm.png" alt="ConstructionOS" width={32} height={32} className="rounded-lg" />
            <span className="text-base font-black tracking-wide text-[#F0F8F8]">CONSTRUCT<span className="text-[#F29E3D]">OS</span></span>
          </Link>
          <MobileNav />
        </nav>
        <main className="pt-14">{children}</main>
        <Suspense fallback={null}><AngelicAssistant /></Suspense>
        <Analytics />
        <footer className="text-center py-10" style={{ borderTop: '1px solid rgba(51,84,94,0.1)' }}>
          <div className="flex justify-center gap-6 mb-4 flex-wrap">
            <FeatureAccessLink feature="projects" paidHref="/projects" className="text-xs text-[#9EBDC2]">Projects</FeatureAccessLink>
            <FeatureAccessLink feature="ai" paidHref="/ai" className="text-xs text-[#9EBDC2]">Angelic AI</FeatureAccessLink>
            <FeatureAccessLink feature="jobs" paidHref="/jobs" previewHref="/jobs" className="text-xs text-[#9EBDC2]">Jobs</FeatureAccessLink>
            <FeatureAccessLink feature="rentals" paidHref="/rentals" className="text-xs text-[#9EBDC2]">Rentals</FeatureAccessLink>
            <Link href="/pricing" className="text-xs text-[#9EBDC2]">Pricing</Link>
            <Link href="/support" className="text-xs text-[#9EBDC2]">Support</Link>
            <Link href="/terms" className="text-xs text-[#9EBDC2]">Terms</Link>
            <Link href="/privacy" className="text-xs text-[#9EBDC2]">Privacy</Link>
            <ExternalLink href={githubRepoUrl} className="text-xs text-[#9EBDC2]">GitHub</ExternalLink>
          </div>
          <p className="text-xs" style={{ color: 'rgba(158,189,194,0.4)' }}>ConstructionOS © {new Date().getFullYear()} Donovan Fagan · Built for the builders</p>
        </footer>
      </body>
    </html>
  );
}
