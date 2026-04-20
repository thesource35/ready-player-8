// Phase 29 LIVE-09 — Horizontal swipable suggestion row (iOS portrait).
//
// UI-SPEC §Per-project iOS portrait line 247 — below the scrubber, above the
// Traffic card. Planner density: 280pt cards with 12pt gap (both fit the 4px
// spacing grid; picked per UI-SPEC Open Question 1).
//
// Empty state (UI-SPEC §Copywriting line 418-419):
//   Heading: "Analysis Pending"
//   Body:    "The first AI suggestion will appear here within 15 minutes,
//            or tap Analyze Now."
//
// Undo toast (UI-SPEC §Copywriting line 431):
//   "Suggestion dismissed. [Undo]" — inline below the row, 5s auto-clear
//   owned by LiveSuggestionsStore.

import SwiftUI

struct LiveSuggestionCardRow: View {
    @ObservedObject var store: LiveSuggestionsStore

    private var activeSuggestions: [LiveSuggestion] {
        store.suggestions.filter { $0.dismissedAt == nil }
    }

    var body: some View {
        if activeSuggestions.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activeSuggestions) { s in
                            LiveSuggestionCard(suggestion: s, onDismiss: {
                                store.dismiss(s)
                            })
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                    }
                    .padding(.horizontal, 4)
                }
                // UI-SPEC §Motion line 359 — 150ms fade + slide on dismiss.
                .animation(.easeInOut(duration: 0.15), value: store.suggestions.map(\.dismissedAt))

                if let undo = store.undoPending {
                    HStack {
                        Text("Suggestion dismissed.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.text)
                        Spacer()
                        Button(action: { store.undo() }) {
                            Text("Undo")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(2)
                                .foregroundColor(Theme.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Undo dismiss")
                    }
                    .padding(12)
                    .background(Theme.surface)
                    .cornerRadius(10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id(undo.suggestion.id)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: store.undoPending?.suggestion.id)
        }
    }

    // MARK: - Empty state (UI-SPEC §Copywriting line 418-419)

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Analysis Pending")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.text)
            Text("The first AI suggestion will appear here within 15 minutes, or tap Analyze Now.")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(14)
    }
}
