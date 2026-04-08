import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("login");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
