import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("tasks");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
