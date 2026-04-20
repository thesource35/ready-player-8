// Phase 29 D-09 — older drone clips (> 24h old), up to Phase 22's 30d retention.
//
// UI-SPEC §Component Inventory iOS line 185 + empty-state copy "No Older Clips"
// (UI-SPEC line 389).
//
// Selecting a row writes the tapped asset's id to `selectedAssetId` and
// dismisses the sheet — the parent's video player swaps over.

import SwiftUI

struct ProjectDroneLibrarySheet: View {
    let clips: [VideoAsset]
    @Binding var isPresented: Bool
    @Binding var selectedAssetId: String?

    var body: some View {
        NavigationView {
            Group {
                if clips.isEmpty {
                    emptyState
                } else {
                    clipList
                }
            }
            .navigationTitle("Drone Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No Older Clips")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(Theme.text)
            Text("Clips older than 24 hours appear here for up to 30 days.")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - List

    private var clipList: some View {
        List(clips) { clip in
            Button {
                selectedAssetId = clip.id.uuidString
                isPresented = false
            } label: {
                row(for: clip)
            }
        }
    }

    private func row(for clip: VideoAsset) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateOnly(from: clip.createdAt))
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.text)
                if let name = clip.name, !name.isEmpty {
                    Text(name)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                } else {
                    Text(timeOnly(from: clip.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.muted)
                }
            }
            Spacer()
            Image(systemName: "play.fill")
                .foregroundColor(Theme.accent)
        }
    }

    // MARK: - Formatting

    private func dateOnly(from date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    private func timeOnly(from date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: date)
    }
}
