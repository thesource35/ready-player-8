import SwiftUI

// Phase 16 FIELD-04: SwiftUI surface for the V2 daily log.
//
// Mirrors the web /field/logs/[date] editor. Uses DailyLogTemplateResolver
// to produce the same resolved template as the TS resolver for identical
// inputs. Kept in a new file under Field/ rather than jammed into the
// 35K-line OperationsCore.swift monolith — CLAUDE.md's "fix bugs in place"
// rule is about not breaking apart existing monoliths, not about forcing
// new feature code into them.

struct DailyLogV2View: View {
    let projectId: String
    let logDate: String // YYYY-MM-DD
    let role: OpsRolePreset

    @State private var resolved: DailyLogResolvedTemplate?
    @State private var content: [String: String] = [:]
    @State private var weatherError: String?
    @State private var loadError: String?
    @State private var saving = false
    @State private var savedAt: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Daily Log — \(logDate)")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Theme.text)

                if let err = loadError {
                    Text(err).foregroundColor(Theme.red)
                }

                if let warn = weatherError {
                    HStack {
                        Image(systemName: "cloud.slash")
                        Text("Weather unavailable: \(warn)")
                    }
                    .padding(8)
                    .background(Theme.gold.opacity(0.15))
                    .cornerRadius(8)
                    .foregroundColor(Theme.gold)
                }

                if let r = resolved {
                    ForEach(r.sections) { section in
                        sectionCard(section)
                    }
                }

                Button(action: save) {
                    Text(saving ? "Saving…" : "Save Log")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent)
                        .cornerRadius(10)
                }
                .disabled(saving || resolved == nil)

                if let at = savedAt {
                    Text("Saved at \(at.formatted(date: .omitted, time: .standard))")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
        .task { await load() }
    }

    @ViewBuilder
    private func sectionCard(_ s: DailyLogTemplateSection) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(s.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.text)
                if s.visibility == .required {
                    Text("*").foregroundColor(Theme.red)
                }
            }
            TextField("", text: Binding(
                get: { content[s.id] ?? "" },
                set: { content[s.id] = $0 }
            ), axis: .vertical)
            .lineLimit(2...5)
            .padding(8)
            .background(Theme.panel)
            .cornerRadius(8)
            .foregroundColor(Theme.text)
        }
        .padding(12)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func load() async {
        do {
            let layer = try? await SupabaseService.shared.fetchProjectLogTemplate(projectId: projectId)
            let existing = try? await SupabaseService.shared.fetchDailyLogV2(projectId: projectId, logDate: logDate)
            if let existing, let snap = existing.templateSnapshot {
                resolved = snap
                if let w = existing.weather, let e = w.error { weatherError = e }
            } else {
                resolved = DailyLogTemplateResolver.resolve(projectLayer: layer, role: role)
            }
        } catch {
            loadError = "Load failed: \(error.localizedDescription)"
        }
    }

    private func save() {
        guard let r = resolved else { return }
        saving = true
        Task {
            defer { saving = false }
            let contentV2 = DailyLogContentV2(
                workPerformed: content["work_performed"],
                delays: content["delays"],
                visitors: content["visitors"],
                safetyNotes: content["safety_notes"],
                openRfis: nil,
                openPunchItems: nil
            )
            let log = SupabaseDailyLogV2(
                id: nil,
                projectId: projectId,
                logDate: logDate,
                templateSnapshot: r,
                content: contentV2,
                weather: weatherError.map { DailyLogWeatherV2(tempC: nil, conditions: nil, fetchedAt: nil, error: $0) },
                createdBy: nil
            )
            do {
                try await SupabaseService.shared.insertDailyLogV2(log)
                savedAt = Date()
            } catch {
                loadError = "Save failed: \(error.localizedDescription)"
            }
        }
    }
}
