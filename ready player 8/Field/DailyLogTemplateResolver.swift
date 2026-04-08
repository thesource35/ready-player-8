import Foundation

// Phase 16 FIELD-04: Swift mirror of web/src/lib/field/templateResolver.ts.
//
// Composition rules match the TypeScript resolver exactly so iOS and web
// produce identical resolved templates for the same inputs (D-14/D-17).

enum DailyLogSectionVisibility: String, Codable {
    case required
    case optional
    case hidden
}

struct DailyLogTemplateSection: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var kind: String
    var visibility: DailyLogSectionVisibility
}

struct DailyLogTemplate: Codable, Equatable {
    var version: String
    var sections: [DailyLogTemplateSection]
}

struct DailyLogProjectTemplateLayer: Codable, Equatable {
    var addedSections: [DailyLogTemplateSection]?
    var hiddenSectionIds: [String]?
    var requiredSectionIds: [String]?
    var copyOverrides: [String: String]?
}

struct DailyLogResolvedTemplate: Codable, Equatable {
    var version: String
    var sections: [DailyLogTemplateSection]
    var resolvedFor: String
}

enum DailyLogTemplateResolver {
    static let baseTemplateV1 = DailyLogTemplate(
        version: "v1",
        sections: [
            .init(id: "weather", label: "Weather", kind: "weather", visibility: .required),
            .init(id: "crew_on_site", label: "Crew On Site", kind: "crew_on_site", visibility: .required),
            .init(id: "open_rfis", label: "Open RFIs", kind: "open_rfis", visibility: .optional),
            .init(id: "open_punch_items", label: "Open Punch Items", kind: "open_punch_items", visibility: .optional),
            .init(id: "yesterday_carryover", label: "Yesterday's Carryover", kind: "yesterday_carryover", visibility: .optional),
            .init(id: "work_performed", label: "Work Performed", kind: "work_performed", visibility: .required),
            .init(id: "delays", label: "Delays", kind: "delays", visibility: .optional),
            .init(id: "visitors", label: "Visitors", kind: "visitors", visibility: .optional),
            .init(id: "safety_notes", label: "Safety Notes", kind: "safety_notes", visibility: .required)
        ]
    )

    // Default role filters mirror TS. OpsRolePreset reused from ThemeAndModels.
    private static func roleFilter(for role: OpsRolePreset) -> [String: DailyLogSectionVisibility] {
        switch role {
        case .executive:
            return ["crew_on_site": .hidden, "visitors": .hidden]
        case .superintendent, .projectManager:
            return [:]
        }
    }

    static func resolve(
        base: DailyLogTemplate = baseTemplateV1,
        projectLayer: DailyLogProjectTemplateLayer?,
        role: OpsRolePreset
    ) -> DailyLogResolvedTemplate {
        let hidden = Set(projectLayer?.hiddenSectionIds ?? [])
        let required = Set(projectLayer?.requiredSectionIds ?? [])
        let overrides = projectLayer?.copyOverrides ?? [:]

        var sections: [DailyLogTemplateSection] = base.sections
            .filter { !hidden.contains($0.id) }
            .map { s in
                var copy = s
                if required.contains(s.id) { copy.visibility = .required }
                if let label = overrides[s.id] { copy.label = label }
                return copy
            }

        if let added = projectLayer?.addedSections, !added.isEmpty {
            for section in added {
                sections.removeAll { $0.id == section.id }
                sections.append(section)
            }
        }

        let filter = roleFilter(for: role)
        sections = sections.compactMap { s in
            if let override = filter[s.id] {
                if override == .hidden { return nil }
                var copy = s
                copy.visibility = override
                return copy
            }
            return s
        }

        return DailyLogResolvedTemplate(
            version: base.version,
            sections: sections,
            resolvedFor: role.rawValue
        )
    }
}
