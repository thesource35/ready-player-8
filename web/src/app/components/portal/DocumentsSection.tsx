import SectionWrapper from "./SectionWrapper";

// D-31: List only user-selected documents
// Each doc: name, type icon, size, upload date, download link

type DocumentsSectionProps = {
  documents: Record<string, unknown>[];
  sectionNote?: string;
};

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function getDocIcon(type: string): string {
  const t = (type ?? "").toLowerCase();
  if (t.includes("pdf")) return "\uD83D\uDCC4";
  if (t.includes("image") || t.includes("png") || t.includes("jpg")) return "\uD83D\uDDBC\uFE0F";
  if (t.includes("spreadsheet") || t.includes("xls") || t.includes("csv")) return "\uD83D\uDCCA";
  if (t.includes("doc") || t.includes("word")) return "\uD83D\uDCC3";
  return "\uD83D\uDCC1";
}

export default function DocumentsSection({
  documents,
  sectionNote,
}: DocumentsSectionProps) {
  return (
    <SectionWrapper
      id="documents"
      title="Documents"
      itemCount={documents.length}
      sectionNote={sectionNote}
    >
      <div>
        {documents.map((doc, i) => (
          <div
            key={(doc.id as string) ?? i}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 12,
              padding: "12px 0",
              borderBottom:
                i < documents.length - 1 ? "1px solid #F1F3F5" : "none",
            }}
          >
            {/* Type icon */}
            <span style={{ fontSize: 20, flexShrink: 0 }}>
              {getDocIcon((doc.file_type as string) ?? (doc.content_type as string) ?? "")}
            </span>

            {/* Name and metadata */}
            <div style={{ flex: 1, minWidth: 0 }}>
              <div
                style={{
                  fontSize: 14,
                  fontWeight: 500,
                  color: "var(--portal-text, #374151)",
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                  whiteSpace: "nowrap",
                }}
              >
                {(doc.name as string) ??
                  (doc.file_name as string) ??
                  "Document"}
              </div>
              <div
                style={{
                  fontSize: 12,
                  color: "#9CA3AF",
                  display: "flex",
                  gap: 12,
                  marginTop: 2,
                }}
              >
                {doc.file_size && (
                  <span>
                    {formatFileSize(doc.file_size as number)}
                  </span>
                )}
                {doc.created_at && (
                  <span>
                    {new Date(doc.created_at as string).toLocaleDateString(
                      "en-US",
                      { month: "short", day: "numeric", year: "numeric" }
                    )}
                  </span>
                )}
              </div>
            </div>

            {/* Download link */}
            {(doc.file_path || doc.download_url) && (
              <a
                href={(doc.download_url as string) ?? (doc.file_path as string)}
                target="_blank"
                rel="noopener noreferrer"
                style={{
                  fontSize: 12,
                  fontWeight: 500,
                  color: "var(--portal-primary, #2563EB)",
                  textDecoration: "none",
                  padding: "6px 12px",
                  borderRadius: 6,
                  border: "1px solid var(--portal-primary, #2563EB)",
                  whiteSpace: "nowrap",
                  transition: "background 200ms ease-in-out",
                }}
              >
                Download
              </a>
            )}
          </div>
        ))}

        {documents.length === 0 && (
          <p
            style={{
              fontSize: 13,
              color: "#9CA3AF",
              textAlign: "center",
              padding: 16,
            }}
          >
            No documents available.
          </p>
        )}
      </div>
    </SectionWrapper>
  );
}
