import { AttachmentList } from "@/components/documents/AttachmentList";
import DailyCrewSection from "./DailyCrewSection";
import CamerasSection from "./cameras/CamerasSection";

export default async function ProjectDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  // TODO: Resolve orgId from session + project row; canManage from user_orgs role lookup.
  // For now, use empty orgId (CamerasSection handles gracefully) and default canManage=true.
  const orgId = "";
  const canManage = true;

  return (
    <main style={{ maxWidth: 1100, margin: "0 auto", padding: 20 }}>
      <h1 style={{ fontSize: 28, fontWeight: 800 }}>Project {id}</h1>
      <div style={{ marginTop: 20 }}>
        <AttachmentList entityType="project" entityId={id} />
      </div>
      <DailyCrewSection projectId={id} />
      <CamerasSection projectId={id} orgId={orgId} canManage={canManage} />
    </main>
  );
}
