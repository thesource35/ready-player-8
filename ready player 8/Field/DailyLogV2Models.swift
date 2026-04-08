import Foundation

// Phase 16 FIELD-04: V2 daily log DTOs.
//
// NOTE: a legacy `SupabaseDailyLog` struct lives in SupabaseService.swift
// with a flat shape (tempHigh/tempLow/workPerformed). That predates Phase 16
// and is still used by Operations panels. We add V2 models in this new file
// rather than edit the legacy struct to avoid regressions.
//
// Schema (supabase/migrations/*_cs_daily_logs.sql):
//   id uuid PK
//   project_id uuid FK cs_projects(id)
//   log_date date
//   template_snapshot_jsonb jsonb   (frozen at create — D-17)
//   content_jsonb jsonb             (editable fields)
//   weather_jsonb jsonb             (best-effort; may be {error})
//   created_by uuid                 (NOT text — verified ground truth)
//   UNIQUE(project_id, log_date)

struct SupabaseDailyLogV2: Codable, Identifiable, Sendable {
    var id: String?
    var projectId: String
    var logDate: String // YYYY-MM-DD
    var templateSnapshot: DailyLogResolvedTemplate?
    var content: DailyLogContentV2?
    var weather: DailyLogWeatherV2?
    var createdBy: String?

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case logDate = "log_date"
        case templateSnapshot = "template_snapshot_jsonb"
        case content = "content_jsonb"
        case weather = "weather_jsonb"
        case createdBy = "created_by"
    }
}

struct DailyLogContentV2: Codable, Sendable {
    var workPerformed: String?
    var delays: String?
    var visitors: String?
    var safetyNotes: String?
    var openRfis: Int?
    var openPunchItems: Int?

    enum CodingKeys: String, CodingKey {
        case workPerformed = "work_performed"
        case delays
        case visitors
        case safetyNotes = "safety_notes"
        case openRfis = "open_rfis"
        case openPunchItems = "open_punch_items"
    }
}

struct DailyLogWeatherV2: Codable, Sendable {
    var tempC: Double?
    var conditions: String?
    var fetchedAt: String?
    var error: String?
}

struct SupabaseProjectLogTemplate: Codable, Sendable {
    var projectId: String
    var layer: DailyLogProjectTemplateLayer?

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case layer = "template_layer"
    }
}
