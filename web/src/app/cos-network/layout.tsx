import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("cos-network");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
