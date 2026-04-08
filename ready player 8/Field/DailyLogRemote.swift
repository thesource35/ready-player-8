import Foundation

// Phase 16 FIELD-04: Remote I/O for daily log V2 (kept out of the monolithic
// SupabaseService.swift so the legacy SupabaseDailyLog struct at line 996
// is untouched).
//
// Uses SupabaseService's existing generic fetch/insert API.

extension SupabaseService {
    /// Fetch a single daily log V2 for (project_id, log_date). Nil if absent.
    func fetchDailyLogV2(projectId: String, logDate: String) async throws -> SupabaseDailyLogV2? {
        let rows: [SupabaseDailyLogV2] = try await fetch(
            "cs_daily_logs",
            query: [
                "project_id": "eq.\(projectId)",
                "log_date": "eq.\(logDate)",
                "select": "*"
            ],
            limit: 1
        )
        return rows.first
    }

    /// Insert a new daily log V2. Maps unique violation (23505 / HTTP 409)
    /// to a user-facing validation error.
    func insertDailyLogV2(_ log: SupabaseDailyLogV2) async throws {
        do {
            try await insert("cs_daily_logs", record: log)
        } catch let error as SupabaseError {
            if case .httpError(let status, let body) = error,
               status == 409 || body.contains("23505") {
                throw AppError.validationFailed(
                    field: "log_date",
                    reason: "A log already exists for this date"
                )
            }
            throw error
        }
    }

    /// Fetch a project's template layer customization. Nil if none set.
    func fetchProjectLogTemplate(projectId: String) async throws -> DailyLogProjectTemplateLayer? {
        struct Row: Codable { var template_layer: DailyLogProjectTemplateLayer? }
        let rows: [Row] = try await fetch(
            "cs_projects",
            query: ["id": "eq.\(projectId)", "select": "template_layer"],
            limit: 1
        )
        return rows.first?.template_layer ?? nil
    }
}
