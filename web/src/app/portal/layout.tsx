import type { Metadata } from "next";
import { Inter } from "next/font/google";

// D-11: Portal pages never indexed by search engines
// D-63: Light mode only for portal
// Portal is standalone — no app navigation

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-inter",
});

export const metadata: Metadata = {
  robots: "noindex, nofollow",
};

export default function PortalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.variable}>
      <head>
        <meta name="robots" content="noindex, nofollow" />
      </head>
      <body
        style={{
          margin: 0,
          padding: 0,
          fontFamily: "var(--font-inter), system-ui, -apple-system, sans-serif",
          background: "#FFFFFF",
          color: "#1F2937",
          minHeight: "100vh",
        }}
      >
        {children}
      </body>
    </html>
  );
}
