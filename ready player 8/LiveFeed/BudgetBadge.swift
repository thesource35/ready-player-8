// Phase 29 LIVE-11 / D-22 — Budget badge with 3 states.
//
// UI-SPEC §Color line 125-129 — three states on `store.budget`:
//   Healthy (< 80/96):  surface bg, muted text, surface border (invisible)
//   Warning (80-95/96): surface bg, gold text,  1px gold border
//   Reached (>= 96/96): red @ 15% opacity bg, red text, 1px red border
//
// UI-SPEC §Copywriting line 423 — "96 / 96 today" text format.
// UI-SPEC §Accessibility line 447 — VoiceOver reads state qualifier.
//
// When `store.budget` is nil (first load or 29-10 route not yet shipped),
// the badge renders in the healthy visual state as a graceful fallback.

import SwiftUI

struct BudgetBadge: View {
    @ObservedObject var store: LiveSuggestionsStore

    var body: some View {
        HStack(spacing: 4) {
            Text("\(used) / \(cap)")
                .font(.system(size: 9, weight: .heavy))
                .tracking(2)
            Text("today")
                .font(.system(size: 9, weight: .heavy))
                .tracking(2)
                .opacity(0.6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(bg)
        .foregroundColor(fg)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(border, lineWidth: 1)
        )
        .cornerRadius(8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Suggestion budget, \(used) of \(cap) used today, \(stateLabel)."
        )
        // UI-SPEC §Motion line 363 — 300ms ease-out color interpolation.
        .animation(.easeOut(duration: 0.3), value: stateLabel)
    }

    // MARK: - Derived values

    private var used: Int { store.budget?.used ?? 0 }
    private var cap: Int  { store.budget?.cap  ?? 96 }

    private var stateLabel: String {
        guard let b = store.budget else { return "healthy" }
        if b.isReached { return "reached" }
        if b.isWarning { return "warning" }
        return "healthy"
    }

    // MARK: - Color derivations (UI-SPEC §Color line 125-129)

    private var bg: Color {
        guard let b = store.budget else { return Theme.surface }
        if b.isReached { return Theme.red.opacity(0.15) }
        return Theme.surface
    }

    private var fg: Color {
        guard let b = store.budget else { return Theme.muted }
        if b.isReached { return Theme.red }
        if b.isWarning { return Theme.gold }
        return Theme.muted
    }

    private var border: Color {
        guard let b = store.budget else { return Theme.surface }
        if b.isReached { return Theme.red }
        if b.isWarning { return Theme.gold }
        return Theme.surface
    }
}
