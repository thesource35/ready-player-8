import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("roofing");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
