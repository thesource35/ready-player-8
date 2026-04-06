import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("tax");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
