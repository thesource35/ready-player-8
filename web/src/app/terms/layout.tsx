import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("terms");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
