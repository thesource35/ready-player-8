import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("smart-build");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
