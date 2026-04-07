import { AttachmentList } from "@/components/documents/AttachmentList";

export default async function RfiDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return (
    <main style={{ maxWidth: 1100, margin: "0 auto", padding: 20 }}>
      <h1 style={{ fontSize: 28, fontWeight: 800 }}>RFI {id}</h1>
      <div style={{ marginTop: 20 }}>
        <AttachmentList entityType="rfi" entityId={id} />
      </div>
    </main>
  );
}
