import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("contractors");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
