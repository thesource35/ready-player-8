// Phase 29 LIVE-12 — horizontal 24h scrubber over drone clips.
//
// UI-SPEC §Color line 107 locks cyan for the active playhead; empty-state
// copy "No drone clips in the last 24 h." matches UI-SPEC line 331/392.
//
// Interaction (UI-SPEC LIVE-12):
//   tap segment → selectedAssetId updates + onScrub() fires
//   onScrub() is the D-20 hook: the parent stamps
//   `ConstructOS.LiveFeed.LastScrubTimestamp.{projectId}` so the 30s
//   auto-advance guard respects the user's scrubbing.

import SwiftUI

struct DroneScrubberTimeline: View {
    let clips: [VideoAsset]
    @Binding var selectedAssetId: String?
    /// Fires on user tap — parent updates LastScrubTimestamp for D-20 guard.
    let onScrub: () -> Void
    /// Fires when the empty-state CTA is tapped.
    let onUploadTap: () -> Void

    var body: some View {
        Group {
            if clips.isEmpty {
                empty
            } else {
                populated
            }
        }
    }

    // MARK: - Empty state

    private var empty: some View {
        HStack(spacing: 12) {
            Text("No drone clips in the last 24 h.")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
            Spacer()
            Button(action: onUploadTap) {
                Text("Upload Drone Clip")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.accent)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Upload Drone Clip")
        }
        .padding(12)
        .frame(height: 56)
        .background(Theme.surface)
        .cornerRadius(10)
    }

    // MARK: - Populated state

    private var populated: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(clips) { clip in
                    segment(for: clip)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 56)
        .background(Theme.surface)
        .cornerRadius(10)
    }

    private func segment(for clip: VideoAsset) -> some View {
        let isSelected = clip.id.uuidString == selectedAssetId
        return Button {
            selectedAssetId = clip.id.uuidString
            onScrub()
        } label: {
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Theme.cyan : Theme.muted.opacity(0.4))
                    .frame(width: 36, height: 28)
                Text(shortTime(from: clip.createdAt))
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(isSelected ? Theme.cyan : Theme.muted)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Drone clip, \(shortTime(from: clip.createdAt)). Tap to play.")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func shortTime(from date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: date)
    }
}
