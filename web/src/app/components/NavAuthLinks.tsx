"use client";

import Link from "next/link";
import { Suspense } from "react";
import { usePathname, useSearchParams } from "next/navigation";

function NavAuthLinksInner() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const query = searchParams.toString();
  const redirectTarget = `${pathname || "/"}${query ? `?${query}` : ""}`;
  const loginHref = `/login?redirect=${encodeURIComponent(redirectTarget)}`;

  return (
    <>
      <Link href={loginHref} className="text-sm font-bold text-[#F29E3D]">Sign In</Link>
      <Link href={loginHref} className="px-4 py-2 rounded-lg text-sm font-bold text-black" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)" }}>Get Started</Link>
    </>
  );
}

export default function NavAuthLinks() {
  return (
    <Suspense fallback={
      <>
        <Link href="/login" className="text-sm font-bold text-[#F29E3D]">Sign In</Link>
        <Link href="/login" className="px-4 py-2 rounded-lg text-sm font-bold text-black" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)" }}>Get Started</Link>
      </>
    }>
      <NavAuthLinksInner />
    </Suspense>
  );
}
