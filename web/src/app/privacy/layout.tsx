import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("privacy");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
