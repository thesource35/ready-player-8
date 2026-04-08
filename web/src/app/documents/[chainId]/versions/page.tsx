import { VersionHistory } from "@/components/documents/VersionHistory";

export default async function VersionsPage({
  params,
  searchParams,
}: {
  params: Promise<{ chainId: string }>;
  searchParams: Promise<{ entity_type?: string; entity_id?: string }>;
}) {
  const { chainId } = await params;
  const sp = await searchParams;
  const entityType = (sp.entity_type ?? "project") as
    | "project"
    | "rfi"
    | "submittal"
    | "change_order";
  const entityId = sp.entity_id ?? "";
  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: 20 }}>
      <h1>Document Versions</h1>
      <VersionHistory
        chainId={chainId}
        entityType={entityType}
        entityId={entityId}
      />
    </main>
  );
}
