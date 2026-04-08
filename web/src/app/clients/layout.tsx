import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("clients");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
