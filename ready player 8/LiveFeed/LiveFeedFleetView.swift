// Phase 29 LIVE-03 / D-07 — Fleet-view grid (iOS).
// 2 columns on iPhone portrait, 3 on iPad portrait via sizeClass detection.
// UI-SPEC §Fleet view (iOS portrait) lines 274-276.

import SwiftUI

struct LiveFeedFleetView: View {
    let projects: [ProjectSummary]
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        let cols = (sizeClass == .regular) ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 24), count: cols)
    }

    var body: some View {
        if projects.isEmpty {
            empty
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(projects) { p in
                        FleetProjectTile(project: p)
                    }
                }
            }
        }
    }

    // Empty-state copy from UI-SPEC §Copywriting Contract (Fleet-view no-projects row).
    private var empty: some View {
        VStack(spacing: 12) {
            Text("No Active Projects")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(Theme.text)
            Text("Join or create a project to see it here.")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
