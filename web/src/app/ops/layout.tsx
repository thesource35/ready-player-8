import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("ops");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
