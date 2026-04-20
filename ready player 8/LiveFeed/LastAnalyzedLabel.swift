// Phase 29 LIVE-11 / D-22 — "LAST ANALYZED N MIN AGO" ticking label.
//
// UI-SPEC §Copywriting line 424 — format rules:
//   < 60s        → "JUST NOW"
//   1-59 minutes → "{N} MIN AGO"
//   >= 60 min    → "{N} H AGO"
// (The copy contract uses lowercase; we uppercase here to match the tracking-2
// label typography scale per UI-SPEC §Typography line 70-71.)
//
// UI-SPEC §Motion line 363 — ticks every 30s via Timer.publish. On cold start
// with no stored timestamp, the label hides itself (UI-SPEC never-analyzed
// state) rather than rendering "— min ago".
//
// Reads LiveFeedStorageKey.lastAnalyzedAt(projectId:) — written by the Edge
// Function callback OR by LiveSuggestionsStore.analyzeNow() after a manual trigger.

import SwiftUI
import Combine

struct LastAnalyzedLabel: View {
    let projectId: String
    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        let text = phrase
        HStack(spacing: 4) {
            if !text.isEmpty {
                Text("LAST ANALYZED")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                Text(text)
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(Theme.cyan)
            }
        }
        .onReceive(timer) { self.now = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text.isEmpty ? "" : "Last analyzed \(text.lowercased())")
    }

    // MARK: - Phrase formatter (UI-SPEC §Copywriting line 424)

    private var phrase: String {
        let key = LiveFeedStorageKey.lastAnalyzedAt(projectId: projectId)
        guard let raw = UserDefaults.standard.string(forKey: key),
              !raw.isEmpty,
              let date = ISO8601DateFormatter().date(from: raw) else {
            return ""
        }
        let diff = Int(now.timeIntervalSince(date))
        if diff < 60   { return "JUST NOW" }
        if diff < 3600 { return "\(diff / 60) MIN AGO" }
        return "\(diff / 3600) H AGO"
    }
}
