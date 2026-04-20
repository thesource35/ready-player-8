// Phase 29 LIVE-10 / D-18 — Unified Traffic card.
//
// UI-SPEC §Component Inventory line 170 + §Interaction line 317-320:
//   Top section: ROAD TRAFFIC (flow-color dot + Light/Moderate/Heavy label).
//     v1 renders a static "Light" placeholder; Phase 21 tile summary wiring is a
//     follow-up — planner's discretion per plan context.
//   Bottom section: ON-SITE MOVEMENT parsed from
//     `store.latest?.actionHint?.structuredFields` (equipment_active_count,
//     people_visible_count, deliveries_in_progress).
//   Empty copy (UI-SPEC line 320): "No data — waiting for next analysis".
//
// Reads `store.latest` — which already filters out dismissed + budget-marker
// rows — so this card surfaces the freshest ACTIONABLE on-site snapshot.

import SwiftUI

struct TrafficUnifiedCard: View {
    @ObservedObject var store: LiveSuggestionsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            roadSection
            Divider().background(Theme.border)
            onSiteSection
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.cyan)
    }

    // MARK: - Road traffic section

    private var roadSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ROAD TRAFFIC")
                .font(.system(size: 9, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.muted)
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.green)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text("Light")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Theme.text)
                Spacer(minLength: 8)
                Text("No data — waiting for next analysis")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    // MARK: - On-site movement section (reads action_hint.structured_fields)

    private var onSiteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ON-SITE MOVEMENT")
                .font(.system(size: 9, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.muted)
            if let fields = store.latest?.actionHint?.structuredFields {
                HStack(spacing: 16) {
                    stat(label: "Equipment", value: fields.equipmentActiveCount)
                    stat(label: "People",    value: fields.peopleVisibleCount)
                    stat(label: "Deliveries", value: fields.deliveriesInProgress)
                }
            } else {
                Text("No data — waiting for next analysis")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
            }
        }
    }

    // MARK: - Stat cell

    private func stat(label: String, value: Int?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value.map(String.init) ?? "—")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(Theme.text)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.muted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value.map(String.init) ?? "no data")")
    }
}
