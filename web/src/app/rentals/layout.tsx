import { getPageMetadata } from "@/lib/seo";

export const metadata = getPageMetadata("rentals");

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
