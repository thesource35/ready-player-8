// DocumentAttachmentsView.swift — Phase 13 Document Management
// Reusable section that lists current attachments for an entity (project, RFI,
// submittal, change order), allows the user to attach a new file, preview an
// existing one, and jump into version history.
//
// Wired to DocumentSyncManager.shared which already handles local-then-remote
// sync, retries, and AppError surfacing.

import SwiftUI

struct DocumentAttachmentsView: View {
    let entityType: DocumentEntityType
    let entityId: String
    let orgId: String

    @ObservedObject private var sync = DocumentSyncManager.shared

    @State private var showingPicker = false
    @State private var uploading = false
    @State private var localError: AppError?
    @State private var selectedDoc: SupabaseDocument?
    @State private var versionChainForHistory: String?

    private var entityKey: String { "\(entityType.rawValue):\(entityId)" }
    private var docs: [SupabaseDocument] { sync.documentsByEntity[entityKey] ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let err = localError ?? sync.lastError {
                errorBanner(err)
            }

            if docs.isEmpty {
                Text("No attachments yet.")
                    .foregroundColor(Theme.muted)
                    .padding(.vertical, 16)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(docs) { doc in
                        attachmentRow(doc)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
        .task {
            await sync.loadAttachments(entityType: entityType, entityId: entityId)
        }
        .sheet(isPresented: $showingPicker) {
            DocumentPickerHelper(
                onPicked: { url in
                    showingPicker = false
                    Task { await handleUpload(url) }
                },
                onCancel: { showingPicker = false }
            )
        }
        .sheet(item: $selectedDoc) { doc in
            NavigationStack {
                DocumentPreviewView(document: doc)
            }
        }
        .sheet(item: Binding<DocAttachIDWrap?>(
            get: { versionChainForHistory.map { DocAttachIDWrap(id: $0) } },
            set: { versionChainForHistory = $0?.id }
        )) { wrap in
            NavigationStack {
                DocumentVersionsView(
                    chainId: wrap.id,
                    entityType: entityType,
                    entityId: entityId,
                    orgId: orgId
                )
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Attachments")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Theme.text)
            Spacer()
            Button {
                showingPicker = true
            } label: {
                Label(uploading ? "Uploading…" : "Attach file", systemImage: "paperclip")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.accent)
                    .foregroundColor(.black)
                    .cornerRadius(10)
            }
            .disabled(uploading)
        }
    }

    private func errorBanner(_ err: AppError) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Theme.red)
            Text(err.errorDescription ?? "Error")
                .foregroundColor(Theme.red)
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Button("Retry") {
                localError = nil
                Task {
                    await sync.loadAttachments(entityType: entityType, entityId: entityId)
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Theme.accent)
        }
        .padding(10)
        .background(Theme.panel)
        .cornerRadius(10)
    }

    @ViewBuilder
    private func attachmentRow(_ doc: SupabaseDocument) -> some View {
        Button {
            selectedDoc = doc
        } label: {
            HStack(spacing: 12) {
                Image(systemName: doc.mimeType == "application/pdf" ? "doc.richtext" : "photo")
                    .foregroundColor(Theme.accent)
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.filename)
                        .foregroundColor(Theme.text)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Text("\(doc.mimeType) · \(formatBytes(doc.sizeBytes)) · v\(doc.versionNumber)")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Button {
                    versionChainForHistory = doc.versionChainId
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(Theme.accent)
                        .font(.system(size: 18))
                }
                .buttonStyle(.borderless)
            }
            .padding(12)
            .background(Theme.panel)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func handleUpload(_ url: URL) async {
        uploading = true
        localError = nil
        defer { uploading = false }
        let uploader = SupabaseService.shared.currentUserEmail ?? "unknown"
        do {
            _ = try await sync.uploadDocument(
                fileURL: url,
                entityType: entityType,
                entityId: entityId,
                orgId: orgId,
                uploadedBy: uploader
            )
            await sync.loadAttachments(entityType: entityType, entityId: entityId)
        } catch let e as AppError {
            localError = e
        } catch {
            localError = .network(underlying: error)
        }
    }

    private func formatBytes(_ b: Int64) -> String {
        if b < 1024 { return "\(b) B" }
        if b < 1024 * 1024 { return String(format: "%.1f KB", Double(b) / 1024) }
        return String(format: "%.1f MB", Double(b) / 1_048_576)
    }
}

private struct DocAttachIDWrap: Identifiable {
    let id: String
}
