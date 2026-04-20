// Phase 29 — Per-project Live Feed view (scaffold).
// This file owns the layout skeleton; named sections below are filled by:
//   29-06: DroneScrubberTimeline + ProjectDroneLibrarySheet + DroneUploadSheet
//   29-07: LiveSuggestionCardRow + TrafficUnifiedCard + BudgetBadge + AnalyzeNowButton + LastAnalyzedLabel
// UI-SPEC §Per-project Live Feed (iOS portrait) lines 236-255 drives the layout.

import SwiftUI

struct LiveFeedPerProjectView: View {
    let projectId: String

    var body: some View {
        if projectId.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 16) {
                videoPlayerPlaceholder          // Section 1 — 29-06
                scrubberPlaceholder             // Section 2 — 29-06
                suggestionsPlaceholder          // Section 3 — 29-07
                trafficPlaceholder              // Section 4 — 29-07
                HStack(spacing: 12) {           // Section 5 — 29-06
                    libraryButtonPlaceholder
                    uploadButtonPlaceholder
                }
            }
        }
    }

    // Empty-state copy from UI-SPEC §Copywriting Contract (no projects row).
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No Projects")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(Theme.text)
            Text("You don't have access to any projects yet. Contact your admin to be added.")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var videoPlayerPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Theme.surface)
            .frame(height: 220)
            .overlay(
                Text("Video player — 29-06")
                    .foregroundColor(Theme.muted)
                    .font(.system(size: 12))
            )
    }

    private var scrubberPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Theme.surface)
            .frame(height: 56)
            .overlay(
                Text("Scrubber — 29-06")
                    .foregroundColor(Theme.muted)
                    .font(.system(size: 12))
            )
    }

    private var suggestionsPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Theme.surface)
            .frame(height: 140)
            .overlay(
                Text("Suggestion cards — 29-07")
                    .foregroundColor(Theme.muted)
                    .font(.system(size: 12))
            )
    }

    private var trafficPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Theme.surface)
            .frame(height: 120)
            .overlay(
                Text("Traffic — 29-07")
                    .foregroundColor(Theme.muted)
                    .font(.system(size: 12))
            )
    }

    private var libraryButtonPlaceholder: some View {
        Text("Library")
            .font(.system(size: 11, weight: .heavy))
            .tracking(2)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.surface)
            .cornerRadius(10)
            .foregroundColor(Theme.muted)
    }

    private var uploadButtonPlaceholder: some View {
        Text("Upload Drone Clip")
            .font(.system(size: 11, weight: .heavy))
            .tracking(2)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.accent)
            .cornerRadius(10)
            .foregroundColor(.black)
    }
}
