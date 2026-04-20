// Phase 29 LIVE-09 — Single suggestion card with severity-colored border.
//
// UI-SPEC §Color line 115-121 severity → border color mapping:
//   routine     → Theme.green
//   opportunity → Theme.gold
//   alert       → Theme.red
//
// UI-SPEC §Accessibility line 450 — color is ALWAYS paired with an SF Symbol
// shape for color-blind safety: routine=circle, opportunity=diamond,
// alert=triangle. Never color alone.
//
// Swipe-left dismiss (iOS): DragGesture threshold -80pt fires onDismiss.
// Dismiss animation is owned by the parent row (UI-SPEC §Motion line 359,
// 150ms fade+slide). Budget-marker rows render as a distinct inline banner
// (UI-SPEC LIVE-11 line 326) rather than a regular card.

import SwiftUI

struct LiveSuggestionCard: View {
    let suggestion: LiveSuggestion
    let onDismiss: () -> Void

    // MARK: - Severity → color (UI-SPEC §Color line 115-121)

    private var severityColor: Color {
        let sev = suggestion.actionHint?.severity ?? .routine
        switch sev {
        case .routine:     return Theme.green
        case .opportunity: return Theme.gold
        case .alert:       return Theme.red
        }
    }

    // MARK: - Severity → SF Symbol (UI-SPEC §Accessibility line 450 color-blind pair)

    private var severityIcon: String {
        let sev = suggestion.actionHint?.severity ?? .routine
        switch sev {
        case .routine:     return "circle"
        case .opportunity: return "diamond"
        case .alert:       return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        if suggestion.isBudgetMarker {
            budgetMarkerView
        } else {
            cardView
        }
    }

    // MARK: - Regular suggestion card

    private var cardView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: severityIcon)
                    .foregroundColor(severityColor)
                    .font(.system(size: 11))
                    .accessibilityHidden(true)
                Text(suggestion.suggestionText)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.text)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            if let verb = suggestion.actionHint?.verb, !verb.isEmpty {
                Text(verb.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.12))
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .frame(width: 280, alignment: .topLeading)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(severityColor, lineWidth: 1)
        )
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: severityColor)
        .gesture(
            DragGesture()
                .onEnded { value in
                    // UI-SPEC §Interaction line 313/350 — left-swipe dismiss.
                    if value.translation.width < -80 { onDismiss() }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Suggestion, \(severityLabel), \(suggestion.suggestionText). Swipe to dismiss."
        )
    }

    private var severityLabel: String {
        switch suggestion.actionHint?.severity ?? .routine {
        case .routine:     return "routine"
        case .opportunity: return "opportunity"
        case .alert:       return "alert"
        }
    }

    // MARK: - Budget-reached sentinel view (UI-SPEC LIVE-11 line 326)

    private var budgetMarkerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark")
                .foregroundColor(Theme.red)
                .accessibilityHidden(true)
            Text("Suggestion budget reached — resumes at 00:00 project-local time.")
                .font(.system(size: 12))
                .foregroundColor(Theme.red)
                .lineLimit(3)
        }
        .padding(12)
        .frame(width: 280, alignment: .topLeading)
        .background(Theme.red.opacity(0.15))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.red, lineWidth: 1))
        .cornerRadius(14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Suggestion budget reached for today, resumes at midnight.")
    }
}
