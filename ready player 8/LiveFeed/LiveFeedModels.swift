// Phase 29 — LiveSuggestion model + severity enum + AppStorage key constants.
// Source of truth for cs_live_suggestions wire shape (29-01 schema / D-17) and for the
// ConstructOS.LiveFeed.* AppStorage namespace (per CLAUDE.md + UI-SPEC §AppStorage Contract).
// Downstream plans (29-06, 29-07) read from this file; changes to field names require
// coordinated edits to web/src/lib/live-feed/types.ts and the Edge Function.

import Foundation

// MARK: - Severity (UI-SPEC locks exactly 3 values — routine / opportunity / alert)
enum LiveSuggestionSeverity: String, Codable, CaseIterable, Equatable {
    case routine, opportunity, alert
}

// MARK: - Structured action-hint fields
// UI-SPEC §Color lines 115-121 + RESEARCH §Open Questions — structured enum for downstream
// traffic-card rendering and severity-based border colors. Every field is optional because
// the Anthropic response may omit fields it can't observe in the frame.
struct LiveSuggestionActionHint: Codable, Equatable {
    let verb: String?
    let severity: LiveSuggestionSeverity
    let structuredFields: StructuredFields?

    struct StructuredFields: Codable, Equatable {
        let equipmentActiveCount: Int?
        let peopleVisibleCount: Int?
        let perimeterActivity: String?      // "clear" | "vehicle_approach" | "unidentified_activity"
        let deliveriesInProgress: Int?
        let weatherVisible: String?         // "clear" | "overcast" | "rain" | "dust" | "unknown"

        enum CodingKeys: String, CodingKey {
            case equipmentActiveCount = "equipment_active_count"
            case peopleVisibleCount = "people_visible_count"
            case perimeterActivity = "perimeter_activity"
            case deliveriesInProgress = "deliveries_in_progress"
            case weatherVisible = "weather_visible"
        }
    }

    enum CodingKeys: String, CodingKey {
        case verb, severity
        case structuredFields = "structured_fields"
    }
}

// MARK: - cs_live_suggestions row (D-17 columns, snake_case keys)
struct LiveSuggestion: Identifiable, Codable, Equatable {
    let id: String
    let projectId: String
    let orgId: String
    let generatedAt: String         // ISO 8601
    let sourceAssetId: String
    let model: String
    let suggestionText: String
    let actionHint: LiveSuggestionActionHint?
    let dismissedAt: String?
    let dismissedBy: String?

    enum CodingKeys: String, CodingKey {
        case id, model
        case projectId = "project_id"
        case orgId = "org_id"
        case generatedAt = "generated_at"
        case sourceAssetId = "source_asset_id"
        case suggestionText = "suggestion_text"
        case actionHint = "action_hint"
        case dismissedAt = "dismissed_at"
        case dismissedBy = "dismissed_by"
    }

    /// True when model == 'budget_reached_marker' (UI-SPEC LIVE-11 line 326).
    /// The Edge Function writes this sentinel row rather than silently skipping when
    /// the 96/day cap is hit; UI surfaces the state from the row itself.
    var isBudgetMarker: Bool { model == "budget_reached_marker" }
}

// MARK: - AppStorage keys (ConstructOS.LiveFeed.* namespace per CLAUDE.md)
// Per-project scoped keys are formatted at call site so callers can read/write with a
// stable key function rather than string-interpolating ad hoc.
enum LiveFeedStorageKey {
    static let lastSelectedProjectId = "ConstructOS.LiveFeed.LastSelectedProjectId"
    static let lastFleetSelection    = "ConstructOS.LiveFeed.LastFleetSelection"
    static let suggestionModel       = "ConstructOS.LiveFeed.SuggestionModel"

    /// Per-project key for "Last analyzed N min ago" timestamp display.
    static func lastAnalyzedAt(projectId: String) -> String {
        "ConstructOS.LiveFeed.LastAnalyzedAt.\(projectId)"
    }

    /// Per-project key for D-20 30s scrubber-touched guard (client-only).
    static func lastScrubTimestamp(projectId: String) -> String {
        "ConstructOS.LiveFeed.LastScrubTimestamp.\(projectId)"
    }
}
