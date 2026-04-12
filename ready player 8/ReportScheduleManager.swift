import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreSpotlight)
import CoreSpotlight
import MobileCoreServices
#endif
#if canImport(AppIntents)
import AppIntents
#endif

// MARK: - ========== ReportScheduleManager.swift ==========
// Phase 19: iOS schedule management + iOS-specific features.
// D-50k: Full schedule management parity with web.
// D-55: All operations via web API (/api/reports/schedule).
// D-50u: Card-based list with swipe actions.
// D-70: Siri Shortcuts via AppIntents.
// D-74: CoreSpotlight indexing.
// D-76: CarPlay health summary + AirPlay presentation mode stubs.

// MARK: - Schedule Data Models

struct ReportSchedule: Codable, Identifiable {
    let id: String
    var name: String
    var frequency: ScheduleFrequency
    var dayOfWeek: Int?         // 1=Sun, 7=Sat
    var dayOfMonth: Int?        // 1-28
    var timeOfDay: String       // "HH:mm" in user's timezone
    var recipients: [String]    // team member IDs
    var sections: [String]      // section keys included
    var isPaused: Bool
    var nextRunAt: String?      // ISO 8601 date
    var lastDeliveryAt: String? // ISO 8601 date
    var lastDeliveryStatus: String? // "success" | "failed"
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, frequency
        case dayOfWeek = "day_of_week"
        case dayOfMonth = "day_of_month"
        case timeOfDay = "time_of_day"
        case recipients, sections
        case isPaused = "is_paused"
        case nextRunAt = "next_run_at"
        case lastDeliveryAt = "last_delivery_at"
        case lastDeliveryStatus = "last_delivery_status"
        case createdAt = "created_at"
    }
}

enum ScheduleFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case biweekly
    case monthly

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Biweekly"
        case .monthly: return "Monthly"
        }
    }
}

// MARK: - Schedule Create/Update Payload

struct SchedulePayload: Codable {
    var name: String
    var frequency: String
    var dayOfWeek: Int?
    var dayOfMonth: Int?
    var timeOfDay: String
    var recipients: [String]
    var sections: [String]

    enum CodingKeys: String, CodingKey {
        case name, frequency
        case dayOfWeek = "day_of_week"
        case dayOfMonth = "day_of_month"
        case timeOfDay = "time_of_day"
        case recipients, sections
    }
}

// MARK: - ReportScheduleListView (D-50u)

struct ReportScheduleListView: View {
    @State private var schedules: [ReportSchedule] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateSheet = false
    @State private var editingSchedule: ReportSchedule?

    private let supabase = SupabaseService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            scheduleHeader

            if isLoading {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage {
                errorView(err)
            } else if schedules.isEmpty {
                emptyState
            } else {
                scheduleList
            }
        }
        .background(Theme.bg)
        .task { await fetchSchedules() }
        .sheet(isPresented: $showCreateSheet) {
            ScheduleEditSheet(schedule: nil) { await fetchSchedules() }
        }
        .sheet(item: $editingSchedule) { schedule in
            ScheduleEditSheet(schedule: schedule) { await fetchSchedules() }
        }
    }

    // MARK: - Header

    private var scheduleHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SCHEDULED REPORTS")
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(Theme.accent)
                Text("Automated report delivery")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            Button {
                showCreateSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.accent)
            }
            .accessibilityLabel("Create new schedule")
        }
        .padding(16)
    }

    // MARK: - Schedule List (D-50u: card-based with swipe actions)

    private var scheduleList: some View {
        List {
            ForEach(schedules) { schedule in
                scheduleCard(schedule)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    // D-50u: Swipe left to delete
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await deleteSchedule(schedule.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    // D-50u: Swipe right to pause/resume
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            Task { await togglePause(schedule) }
                        } label: {
                            Label(
                                schedule.isPaused ? "Resume" : "Pause",
                                systemImage: schedule.isPaused ? "play.fill" : "pause.fill"
                            )
                        }
                        .tint(Color(Theme.gold))
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await fetchSchedules() }
    }

    // MARK: - Schedule Card

    private func scheduleCard(_ schedule: ReportSchedule) -> some View {
        Button {
            editingSchedule = schedule
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(schedule.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.text)
                    Spacer()
                    // Status badge
                    Text(schedule.isPaused ? "PAUSED" : "ACTIVE")
                        .font(.system(size: 8, weight: .heavy))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (schedule.isPaused ? Theme.gold : Theme.green)
                                .opacity(0.15)
                        )
                        .foregroundColor(schedule.isPaused ? Theme.gold : Theme.green)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                HStack(spacing: 12) {
                    // Frequency
                    Label(schedule.frequency.displayName, systemImage: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.muted)

                    // D-50t: Next run time
                    if let nextRun = schedule.nextRunAt {
                        Label(formatRelativeDate(nextRun), systemImage: "calendar.badge.clock")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.cyan)
                    }
                }

                // Recipients count
                HStack(spacing: 12) {
                    Label("\(schedule.recipients.count) recipients", systemImage: "person.2")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.muted)

                    if let lastStatus = schedule.lastDeliveryStatus {
                        Label(
                            lastStatus == "success" ? "Delivered" : "Failed",
                            systemImage: lastStatus == "success" ? "checkmark.circle" : "exclamationmark.triangle"
                        )
                        .font(.system(size: 10))
                        .foregroundColor(lastStatus == "success" ? Theme.green : Theme.red)
                    }
                }

                // Action buttons (D-50g, D-50o)
                HStack(spacing: 8) {
                    // D-50g: Send Now
                    Button {
                        Task { await sendNow(schedule.id) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "paperplane.fill")
                            Text("Send Now")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.accent.opacity(0.15))
                        .foregroundColor(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    // D-50o: Send Test
                    Button {
                        Task { await sendTest(schedule.id) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope.badge")
                            Text("Send Test")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.surface)
                        .foregroundColor(Theme.muted)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.border.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.border.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(schedule.name), \(schedule.frequency.displayName), \(schedule.isPaused ? "paused" : "active")")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(Theme.muted)
            Text("No Scheduled Reports")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.text)
            Text("Set up automated report delivery to your team")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
            Button {
                showCreateSheet = true
            } label: {
                Text("Create Schedule")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.accent)
                    .foregroundColor(Theme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(Theme.red)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await fetchSchedules() } }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }

    // MARK: - API Methods (D-55: all via web API)

    private func fetchSchedules() async {
        isLoading = schedules.isEmpty
        errorMessage = nil
        do {
            let request = try supabase.makeReportRequest(path: "/api/reports/schedule")
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200...299).contains(status) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw AppError.supabaseHTTP(statusCode: status, body: body)
            }
            let decoded = try JSONDecoder().decode([ReportSchedule].self, from: data)
            await MainActor.run {
                schedules = decoded
                isLoading = false
                // D-74: Index schedules in CoreSpotlight
                indexSchedulesInSpotlight(decoded)
            }
        } catch {
            await MainActor.run {
                if schedules.isEmpty {
                    errorMessage = "Unable to load schedules: \(error.localizedDescription)"
                }
                isLoading = false
            }
        }
    }

    private func deleteSchedule(_ id: String) async {
        do {
            let request = try supabase.makeReportRequest(
                path: "/api/reports/schedule?id=\(id)",
                method: "DELETE"
            )
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200...299).contains(status) else { return }
            await MainActor.run {
                schedules.removeAll { $0.id == id }
            }
        } catch {
            // Silently handle -- schedule will remain in list
        }
    }

    // D-50f: Pause/resume toggle with immediate visual state change
    private func togglePause(_ schedule: ReportSchedule) async {
        // Optimistic update
        await MainActor.run {
            if let idx = schedules.firstIndex(where: { $0.id == schedule.id }) {
                schedules[idx].isPaused.toggle()
            }
        }

        do {
            let payload = ["is_paused": !schedule.isPaused]
            let body = try JSONSerialization.data(withJSONObject: payload)
            let request = try supabase.makeReportRequest(
                path: "/api/reports/schedule?id=\(schedule.id)",
                method: "PATCH",
                body: body
            )
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if !(200...299).contains(status) {
                // Revert on failure
                await MainActor.run {
                    if let idx = schedules.firstIndex(where: { $0.id == schedule.id }) {
                        schedules[idx].isPaused = schedule.isPaused
                    }
                }
            }
        } catch {
            // Revert on error
            await MainActor.run {
                if let idx = schedules.firstIndex(where: { $0.id == schedule.id }) {
                    schedules[idx].isPaused = schedule.isPaused
                }
            }
        }
    }

    // D-50g: Send Now
    private func sendNow(_ scheduleId: String) async {
        do {
            let payload = ["action": "send_now"]
            let body = try JSONSerialization.data(withJSONObject: payload)
            let request = try supabase.makeReportRequest(
                path: "/api/reports/schedule?id=\(scheduleId)",
                method: "POST",
                body: body
            )
            _ = try await URLSession.shared.data(for: request)
        } catch {
            // Error silently handled -- notification will confirm delivery
        }
    }

    // D-50o: Send Test
    private func sendTest(_ scheduleId: String) async {
        do {
            let payload = ["action": "send_test"]
            let body = try JSONSerialization.data(withJSONObject: payload)
            let request = try supabase.makeReportRequest(
                path: "/api/reports/schedule?id=\(scheduleId)",
                method: "POST",
                body: body
            )
            _ = try await URLSession.shared.data(for: request)
        } catch {
            // Error silently handled
        }
    }

    // MARK: - Helpers

    private func formatRelativeDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let d = formatter.date(from: isoString) else { return isoString }
            return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: Date())
        }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }

    // MARK: - D-74: CoreSpotlight Indexing

    private func indexSchedulesInSpotlight(_ schedules: [ReportSchedule]) {
        #if canImport(CoreSpotlight)
        let items = schedules.map { schedule -> CSSearchableItem in
            let attributes = CSSearchableItemAttributeSet(contentType: .content)
            attributes.title = "Report: \(schedule.name)"
            attributes.contentDescription = "\(schedule.frequency.displayName) scheduled report"
            attributes.keywords = ["report", "schedule", schedule.name, schedule.frequency.rawValue]
            return CSSearchableItem(
                uniqueIdentifier: "com.constructionos.schedule.\(schedule.id)",
                domainIdentifier: "com.constructionos.reports",
                attributeSet: attributes
            )
        }
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("[ReportScheduleManager] Spotlight indexing error: \(error.localizedDescription)")
            }
        }
        #endif
    }
}

// MARK: - ScheduleEditSheet (Create/Edit)

struct ScheduleEditSheet: View {
    let schedule: ReportSchedule?
    let onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss

    // D-49: Frequency picker
    @State private var name: String = ""
    @State private var frequency: ScheduleFrequency = .weekly
    @State private var dayOfWeek: Int = 2 // Monday
    @State private var dayOfMonth: Int = 1
    @State private var selectedTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var recipients: Set<String> = []
    @State private var includedSections: Set<String> = Set(["budget", "schedule", "safety", "team", "activity"])
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let supabase = SupabaseService.shared

    private let allSections = [
        ("budget", "Budget & Financials"),
        ("schedule", "Schedule & Milestones"),
        ("safety", "Safety"),
        ("team", "Team & Activity"),
        ("activity", "Activity Trends"),
        ("insights", "AI Insights")
    ]

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            Form {
                // Name
                Section {
                    TextField("Schedule Name", text: $name)
                        .font(.system(size: 14))
                } header: {
                    Text("NAME")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(2)
                }

                // D-49: Frequency Picker
                Section {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(ScheduleFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    // Day picker based on frequency
                    if frequency == .weekly || frequency == .biweekly {
                        Picker("Day", selection: $dayOfWeek) {
                            ForEach(1...7, id: \.self) { day in
                                Text(dayNames[day - 1]).tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }

                    if frequency == .monthly {
                        Picker("Day of Month", selection: $dayOfMonth) {
                            ForEach(1...28, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }

                    // Time picker (wheel style per plan)
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .frame(height: 100)
                } header: {
                    Text("SCHEDULE")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(2)
                }

                // D-50e: Recipient selector
                Section {
                    Text("Team members from your organization")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.muted)
                    // Placeholder -- recipients would come from Phase 15 crew data
                    Text("\(recipients.count) selected")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.text)
                } header: {
                    Text("RECIPIENTS")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(2)
                }

                // D-50l: Section picker
                Section {
                    ForEach(allSections, id: \.0) { key, label in
                        Toggle(label, isOn: Binding(
                            get: { includedSections.contains(key) },
                            set: { isOn in
                                if isOn { includedSections.insert(key) }
                                else { includedSections.remove(key) }
                            }
                        ))
                        .font(.system(size: 12))
                        .tint(Theme.accent)
                    }
                } header: {
                    Text("SECTIONS")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(2)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle(schedule == nil ? "New Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await saveSchedule() }
                    }
                    .disabled(name.isEmpty || isSaving)
                    .foregroundColor(Theme.accent)
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let err = errorMessage { Text(err) }
            }
            .onAppear { populateFromExisting() }
        }
    }

    private func populateFromExisting() {
        guard let s = schedule else { return }
        name = s.name
        frequency = s.frequency
        dayOfWeek = s.dayOfWeek ?? 2
        dayOfMonth = s.dayOfMonth ?? 1
        recipients = Set(s.recipients)
        includedSections = Set(s.sections)
        // Parse time
        let parts = s.timeOfDay.split(separator: ":")
        if parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) {
            selectedTime = Calendar.current.date(from: DateComponents(hour: h, minute: m)) ?? Date()
        }
    }

    private func saveSchedule() async {
        isSaving = true
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeStr = timeFormatter.string(from: selectedTime)

        let payload = SchedulePayload(
            name: name,
            frequency: frequency.rawValue,
            dayOfWeek: (frequency == .weekly || frequency == .biweekly) ? dayOfWeek : nil,
            dayOfMonth: frequency == .monthly ? dayOfMonth : nil,
            timeOfDay: timeStr,
            recipients: Array(recipients),
            sections: Array(includedSections)
        )

        do {
            let body = try JSONEncoder().encode(payload)
            let method = schedule == nil ? "POST" : "PUT"
            let path = schedule == nil ? "/api/reports/schedule" : "/api/reports/schedule?id=\(schedule!.id)"
            let request = try supabase.makeReportRequest(path: path, method: method, body: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200...299).contains(status) else {
                let respBody = String(data: data, encoding: .utf8) ?? ""
                throw AppError.supabaseHTTP(statusCode: status, body: respBody)
            }
            await onSave()
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}

// MARK: - D-70: Siri Shortcuts via AppIntents

@available(iOS 16.0, *)
struct ShowReportIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Project Report"
    static var description = IntentDescription("Opens the ConstructionOS Reports tab to view project reports")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Deep link to Reports tab will be handled by the app's URL scheme or notification center
        NotificationCenter.default.post(name: .navigateToReports, object: nil)
        return .result()
    }
}

@available(iOS 16.0, *)
struct PortfolioHealthIntent: AppIntent {
    static var title: LocalizedStringResource = "Portfolio Health"
    static var description = IntentDescription("Shows the portfolio health summary in ConstructionOS")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .navigateToPortfolioRollup, object: nil)
        return .result()
    }
}

// Notification names for deep linking from Siri
extension Notification.Name {
    static let navigateToReports = Notification.Name("com.constructionos.navigateToReports")
    static let navigateToPortfolioRollup = Notification.Name("com.constructionos.navigateToPortfolioRollup")
}

// MARK: - D-76: CarPlay Health Summary Stub

/// CarPlay health summary: color-coded health badge + project count.
/// Accessible from CarPlay scene in ready_player_8App.swift.
struct CarPlayReportHealthSummary {
    let projectCount: Int
    let healthScore: Double
    let healthLabel: String // "On Track", "At Risk", "Critical"

    var healthColor: String {
        if healthScore >= 80 { return "green" }
        if healthScore >= 60 { return "gold" }
        return "red"
    }

    /// Formatted summary for CarPlay display
    var summary: String {
        "\(projectCount) projects \u{2022} \(healthLabel)"
    }
}

// MARK: - D-76: AirPlay Presentation Mode Stub

/// Chart-only view for external displays via AirPlay.
/// Renders charts at full-screen size without navigation chrome.
struct AirPlayPresentationView: View {
    let report: ProjectReportData

    var body: some View {
        VStack(spacing: 20) {
            Text("PORTFOLIO OVERVIEW")
                .font(.system(size: 24, weight: .heavy))
                .tracking(4)
                .foregroundColor(.white)

            if let budget = report.budget {
                BudgetPieChartView(
                    spent: budget.totalBilled ?? 0,
                    remaining: (budget.contractValue ?? 0) - (budget.totalBilled ?? 0)
                )
                .frame(height: 300)
            }

            if let schedule = report.schedule, let milestones = schedule.milestones {
                ScheduleBarChartView(
                    milestones: milestones.map { (name: $0.name, percent: $0.percentComplete) }
                )
                .frame(height: 300)
            }
        }
        .padding(40)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Placeholder Notes for Separate Targets

// TODO: D-67 WidgetKit — Requires a separate Widget Extension target in Xcode.
//   - Small widget: health score circle + project count
//   - Medium widget: health score + top 3 project statuses
//   - Large widget: mini portfolio rollup with budget bars
//   - Add via File > New > Target > Widget Extension

// TODO: D-72 Apple Watch — Requires a separate WatchKit App target in Xcode.
//   - Complication: portfolio health score + project count
//   - Watch app: scrollable project health list
//   - Add via File > New > Target > Watch App

// TODO: D-73 Dynamic Island / Live Activity — Requires ActivityKit integration.
//   - Live Activity for batch PDF export progress
//   - Shows: progress bar, estimated time remaining, current project name
//   - Requires Info.plist: NSSupportsLiveActivities = YES
//   - Add ActivityAttributes struct + ActivityConfiguration
