// DocumentVersionsView.swift — Phase 13 Document Management
// Sheet that lists every version in a document chain (newest first), lets the
// user preview any version, and upload a new version that becomes current.

import SwiftUI

struct DocumentVersionsView: View {
    let chainId: String
    let entityType: DocumentEntityType
    let entityId: String
    let orgId: String

    @State private var versions: [SupabaseDocument] = []
    @State private var error: AppError?
    @State private var loading = true
    @State private var showingPicker = false
    @State private var uploading = false
    @State private var selectedDoc: SupabaseDocument?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if loading {
                ProgressView("Loading versions…")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let error {
                VStack(spacing: 12) {
                    Text(error.errorDescription ?? "Error")
                        .foregroundColor(Theme.red)
                        .multilineTextAlignment(.center)
                    Button("Retry") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if versions.isEmpty {
                Text("No versions found.")
                    .foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sortedVersions) { v in
                            versionRow(v)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .navigationTitle("Version History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingPicker = true
                } label: {
                    Label("New Version", systemImage: "plus")
                }
                .disabled(uploading)
            }
        }
        .task { await load() }
        .sheet(isPresented: $showingPicker) {
            DocumentPickerHelper(
                onPicked: { url in
                    showingPicker = false
                    Task { await uploadNewVersion(url) }
                },
                onCancel: { showingPicker = false }
            )
        }
        .sheet(item: $selectedDoc) { doc in
            NavigationStack { DocumentPreviewView(document: doc) }
        }
    }

    private var sortedVersions: [SupabaseDocument] {
        versions.sorted { $0.versionNumber > $1.versionNumber }
    }

    private func versionRow(_ v: SupabaseDocument) -> some View {
        Button {
            selectedDoc = v
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("v\(v.versionNumber)\(v.isCurrent ? "  (current)" : "")")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Theme.text)
                    Text(v.filename)
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                }
                Spacer()
                Text(String(v.createdAt.prefix(10)))
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }
            .padding(12)
            .background(v.isCurrent ? Theme.accent.opacity(0.25) : Theme.panel)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            versions = try await DocumentSyncManager.shared.listVersions(chainId: chainId)
            error = nil
        } catch let e as AppError {
            error = e
        } catch {
            self.error = .network(underlying: error)
        }
    }

    private func uploadNewVersion(_ url: URL) async {
        uploading = true
        defer { uploading = false }
        do {
            _ = try await DocumentSyncManager.shared.createNewVersion(
                chainId: chainId,
                fileURL: url,
                orgId: orgId
            )
            await load()
            // Refresh the parent list so the new "current" surfaces in the row.
            await DocumentSyncManager.shared.loadAttachments(
                entityType: entityType,
                entityId: entityId
            )
        } catch let e as AppError {
            error = e
        } catch {
            self.error = .network(underlying: error)
        }
    }
}
