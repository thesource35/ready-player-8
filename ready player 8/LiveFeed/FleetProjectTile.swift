// Phase 29 D-07 — Single Fleet-view tile.
// Shows project name + 16:9 drone poster placeholder + top suggestion snippet row.
// UI-SPEC §Fleet view lines 261-272 (16:9 poster + 120 pt suggestion row).
// Wave 3 scaffold: real poster (Phase 22 signed URL) and latest suggestion lookup
// land in downstream consumption tasks.

import SwiftUI

struct FleetProjectTile: View {
    let project: ProjectSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            poster
            suggestionSnippet
        }
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    // 16:9 poster surface — drone-poster image loads here in a future plan (signed Phase 22
    // manifest URL resolved to poster.jpg). Wave 3 tile just tints the surface + shows name.
    private var poster: some View {
        ZStack {
            Rectangle().fill(Theme.surface)
            Text(project.name)
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.text)
                .padding(8)
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipped()
    }

    // 120pt fixed suggestion row — UI-SPEC line 272. 29-07 swaps in the real latest
    // LiveSuggestion with severity-colored border; Wave 3 shows neutral empty state.
    private var suggestionSnippet: some View {
        HStack {
            Text("No suggestions yet")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
                .lineLimit(2)
            Spacer()
        }
        .padding(12)
        .frame(height: 120, alignment: .topLeading)
    }
}
