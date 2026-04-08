import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("field");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
