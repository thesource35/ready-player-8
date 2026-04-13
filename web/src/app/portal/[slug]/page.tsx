import { notFound } from "next/navigation";

// The slug alone (without project) is not a valid portal URL.
// e.g., /portal/acme-builders without a project slug -> 404
export default function PortalSlugPage() {
  notFound();
}
