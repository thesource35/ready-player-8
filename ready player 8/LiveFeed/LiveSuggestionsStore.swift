// Phase 29 LIVE-09 / LIVE-11 — @MainActor store for per-project live suggestions.
//
// Reads cs_live_suggestions via the authenticated SupabaseService.shared client
// (T-29-RLS-CLIENT mitigation — never service_role; RLS enforces org_id scope).
// Dismiss PATCH fires against `/api/live-feed/suggestions/:id` (route lands in
// 29-10). Budget reads `/api/live-feed/budget` (also 29-10). Manual Analyze Now
// hits `/api/live-feed/analyze` (29-10). Until 29-10 ships, all three routes
// 404-tolerate: errors surface via AppError but budget/undo never blocks UI.
//
// Optimistic dismiss + 5s Undo window per UI-SPEC §Copywriting line 430.
// UI-SPEC §Color line 125-129 budget state thresholds (healthy/warning/reached).

import Foundation
import Combine
import SwiftUI

@MainActor
final class LiveSuggestionsStore: ObservableObject {

    // MARK: - Published state

    @Published private(set) var suggestions: [LiveSuggestion] = []
    @Published private(set) var loading: Bool = false
    @Published private(set) var error: AppError?
    @Published private(set) var budget: BudgetState? = nil
    @Published var undoPending: UndoPayload? = nil

    // MARK: - Nested types

    struct BudgetState: Equatable {
        let used: Int
        let remaining: Int
        let cap: Int
        let resetsAt: String?
        /// Healthy: < 80/96 used (UI-SPEC line 127)
        var isHealthy: Bool  { used < 80 }
        /// Warning: 80–95/96 used (UI-SPEC line 128)
        var isWarning: Bool  { used >= 80 && used < 96 }
        /// Reached: >= 96/96 used (UI-SPEC line 129)
        var isReached: Bool  { used >= 96 }
    }

    struct UndoPayload: Equatable {
        let suggestion: LiveSuggestion
        let dismissedAt: String
    }

    // MARK: - Config

    private let projectId: String

    init(projectId: String) { self.projectId = projectId }

    // MARK: - Derived

    /// Most-recent non-dismissed, non-budget-marker suggestion — TrafficUnifiedCard
    /// reads `latest?.actionHint?.structuredFields` for the on-site movement section.
    var latest: LiveSuggestion? {
        suggestions
            .filter { $0.dismissedAt == nil && !$0.isBudgetMarker }
            .sorted(by: { $0.generatedAt > $1.generatedAt })
            .first
    }

    /// True when the Edge Function wrote a `budget_reached_marker` sentinel row
    /// (UI-SPEC LIVE-11 line 326 — no silent skip).
    var budgetMarkerActive: Bool {
        suggestions.contains(where: { $0.isBudgetMarker && $0.dismissedAt == nil })
    }

    // MARK: - Network: suggestions list

    func refresh() async {
        guard !projectId.isEmpty else { return }
        loading = true
        defer { loading = false }

        do {
            let rows: [LiveSuggestion] = try await SupabaseService.shared.fetch(
                "cs_live_suggestions",
                query: [
                    "project_id":   "eq.\(projectId)",
                    "dismissed_at": "is.null"
                ],
                limit: 20,
                orderBy: "generated_at",
                ascending: false
            )
            suggestions = rows
            error = nil
        } catch let e as AppError {
            error = e
        } catch let e as SupabaseError {
            // Map SupabaseError → AppError so callers have a single surface.
            switch e {
            case .notConfigured:
                error = .supabaseNotConfigured
            case .httpError(let code, let body):
                error = .supabaseHTTP(statusCode: code, body: body)
            case .decodingError(let underlying):
                error = .decoding(underlying: underlying)
            case .encodingError(let underlying):
                error = .encoding(underlying: underlying)
            }
        } catch {
            self.error = AppError.unknown(error.localizedDescription)
        }
    }

    // MARK: - Network: budget (LIVE-11)

    /// Reads `GET /api/live-feed/budget?project_id=X` — route lands in 29-10.
    /// Until then, 404 / network-fail leaves `budget` nil and UI shows healthy visuals.
    func loadBudget() async {
        guard !projectId.isEmpty, !SupabaseService.shared.baseURL.isEmpty,
              let url = URL(string: "\(SupabaseService.shared.baseURL)/api/live-feed/budget?project_id=\(projectId)")
        else { return }

        var req = URLRequest(url: url)
        if let token = SupabaseService.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return }
            struct Env: Decodable {
                let used: Int; let remaining: Int; let cap: Int; let resetsAt: String?
                enum CodingKeys: String, CodingKey {
                    case used, remaining, cap
                    case resetsAt = "resets_at"
                }
            }
            if let env = try? JSONDecoder().decode(Env.self, from: data) {
                budget = BudgetState(used: env.used, remaining: env.remaining, cap: env.cap, resetsAt: env.resetsAt)
            }
        } catch {
            // Silent — budget info is non-critical; UI shows healthy visuals if nil.
        }
    }

    // MARK: - Dismiss + Undo (LIVE-09)

    /// Optimistic dismiss + 5s Undo window (UI-SPEC §Copywriting line 430).
    /// If the PATCH fails server-side (e.g. RLS rejects `dismissed_by != auth.uid()`),
    /// the Undo window still clears after 5s — the next `refresh()` re-syncs state.
    func dismiss(_ s: LiveSuggestion) {
        let now = ISO8601DateFormatter().string(from: Date())
        let dismissedBy = SupabaseService.shared.currentUserId ?? ""

        // Optimistic: mutate local list immediately.
        if let idx = suggestions.firstIndex(where: { $0.id == s.id }) {
            var updated = suggestions
            updated[idx] = withDismissed(s, at: now, by: dismissedBy)
            suggestions = updated
        }
        undoPending = UndoPayload(suggestion: s, dismissedAt: now)

        // Fire PATCH async (404-tolerant until 29-10 ships).
        Task { await sendPatch(id: s.id, dismissedAt: now) }

        // Auto-clear undo after 5s.
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if self?.undoPending?.suggestion.id == s.id { self?.undoPending = nil }
        }
    }

    /// Revert the most recent dismiss. Fires PATCH with null dismissed_at to
    /// clear it server-side (RLS UPDATE WITH CHECK from 29-01 still enforces
    /// `dismissed_by = auth.uid()` but we already set that on dismiss).
    func undo() {
        guard let payload = undoPending else { return }
        undoPending = nil
        if let idx = suggestions.firstIndex(where: { $0.id == payload.suggestion.id }) {
            suggestions[idx] = payload.suggestion
        }
        Task { await sendPatch(id: payload.suggestion.id, dismissedAt: nil) }
    }

    private func sendPatch(id: String, dismissedAt: String?) async {
        guard !SupabaseService.shared.baseURL.isEmpty,
              let url = URL(string: "\(SupabaseService.shared.baseURL)/api/live-feed/suggestions/\(id)")
        else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = SupabaseService.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = dismissedAt == nil
            ? ["dismissed_at": NSNull()]
            : ["dismissed_at": dismissedAt!]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: req)
    }

    // MARK: - Manual Analyze Now (LIVE-11 / D-22)

    /// Triggers `/api/live-feed/analyze` (29-10). Server-side 96/day cap is the
    /// authoritative gate — client-side disable via `budget.isReached` is UX only.
    func analyzeNow() async {
        guard !projectId.isEmpty, !SupabaseService.shared.baseURL.isEmpty,
              let url = URL(string: "\(SupabaseService.shared.baseURL)/api/live-feed/analyze?project_id=\(projectId)")
        else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        if let token = SupabaseService.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        _ = try? await URLSession.shared.data(for: req)

        // Stamp last-analyzed timestamp so LastAnalyzedLabel ticks from "just now".
        let ts = ISO8601DateFormatter().string(from: Date())
        UserDefaults.standard.set(ts, forKey: LiveFeedStorageKey.lastAnalyzedAt(projectId: projectId))

        // Refresh suggestion list + budget so UI reflects the new row and used-count.
        await refresh()
        await loadBudget()
    }

    // MARK: - Helpers

    /// Rebuild a suggestion with dismissed_at / dismissed_by set, preserving all other fields.
    /// (LiveSuggestion has immutable let properties so we construct a new value.)
    private func withDismissed(_ s: LiveSuggestion, at: String, by: String) -> LiveSuggestion {
        LiveSuggestion(
            id: s.id,
            projectId: s.projectId,
            orgId: s.orgId,
            generatedAt: s.generatedAt,
            sourceAssetId: s.sourceAssetId,
            model: s.model,
            suggestionText: s.suggestionText,
            actionHint: s.actionHint,
            dismissedAt: at,
            dismissedBy: by
        )
    }
}
