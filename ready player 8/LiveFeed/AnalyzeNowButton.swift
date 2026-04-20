// Phase 29 LIVE-11 / D-22 — Analyze Now button with budget-gated disabled state.
//
// UI-SPEC §Copywriting line 422 — disabled-state tooltip copy (verbatim):
//   "Suggestion budget reached for today — resumes at 00:00 project-local time."
//
// Client-side disable via `store.budget?.isReached` is UX-only — server-side
// 96/day cap in the 29-10 route is the authoritative gate (T-29-07-02
// mitigation). The button fires `store.analyzeNow()` which handles the POST +
// downstream refresh + budget reload + LastAnalyzedAt stamp.

import SwiftUI

struct AnalyzeNowButton: View {
    @ObservedObject var store: LiveSuggestionsStore
    @State private var inFlight: Bool = false

    private var disabled: Bool {
        (store.budget?.isReached ?? false) || inFlight
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if inFlight {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.black)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .accessibilityHidden(true)
                }
                Text("ANALYZE NOW")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(disabled ? Theme.surface : Theme.accent)
            .foregroundColor(disabled ? Theme.muted : .black)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityHint(
            disabled
                ? "Suggestion budget reached for today — resumes at 00:00 project-local time."
                : "Request a fresh AI analysis now."
        )
    }

    private func onTap() {
        guard !disabled else { return }
        inFlight = true
        Task { @MainActor in
            await store.analyzeNow()
            inFlight = false
        }
    }
}
