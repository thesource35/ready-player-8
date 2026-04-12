import SwiftUI

// MARK: - ========== ProjectReportView.swift ==========
// Phase 19: Single project report view with budget, schedule, safety, team, AI insights.
// D-55: Fetches from web API /api/reports/project/{id} with local fallback.
// D-75: VoiceOver semantic announcements.
// D-71: Landscape rotation support.

// MARK: - Report Data Models

struct ProjectReportData: Codable {
    let project: ProjectReportProject?
    let budget: ProjectReportBudget?
    let schedule: ProjectReportSchedule?
    let safety: ProjectReportSafety?
    let team: ProjectReportTeam?
    let insights: [String]?
    let generatedAt: String?

    enum CodingKeys: String, CodingKey {
        case project, budget, schedule, safety, team, insights
        case generatedAt = "generated_at"
    }
}

struct ProjectReportProject: Codable {
    let name: String?
    let client: String?
    let status: String?
    let healthScore: Double?
    let healthLabel: String?

    enum CodingKeys: String, CodingKey {
        case name, client, status
        case healthScore = "health_score"
        case healthLabel = "health_label"
    }
}

struct ProjectReportBudget: Codable {
    let contractValue: Double?
    let totalBilled: Double?
    let percentComplete: Double?
    let changeOrderNet: Double?
    let retainage: Double?

    enum CodingKeys: String, CodingKey {
        case contractValue = "contract_value"
        case totalBilled = "total_billed"
        case percentComplete = "percent_complete"
        case changeOrderNet = "change_order_net"
        case retainage
    }
}

struct ProjectReportSchedule: Codable {
    let milestones: [ReportMilestone]?
    let percentOnTrack: Double?

    enum CodingKeys: String, CodingKey {
        case milestones
        case percentOnTrack = "percent_on_track"
    }
}

struct ReportMilestone: Codable, Identifiable {
    var id: String { name }
    let name: String
    let percentComplete: Double

    enum CodingKeys: String, CodingKey {
        case name
        case percentComplete = "percent_complete"
    }
}

struct ProjectReportSafety: Codable {
    let totalIncidents: Int?
    let minor: Int?
    let moderate: Int?
    let serious: Int?
    let daysSinceLastIncident: Int?
    let monthlyData: [SafetyMonthData]?

    enum CodingKeys: String, CodingKey {
        case totalIncidents = "total_incidents"
        case minor, moderate, serious
        case daysSinceLastIncident = "days_since_last_incident"
        case monthlyData = "monthly_data"
    }
}

struct SafetyMonthData: Codable, Identifiable {
    var id: String { month }
    let month: String
    let count: Int
}

struct ProjectReportTeam: Codable {
    let memberCount: Int?
    let recentActivity: [TeamActivityEntry]?

    enum CodingKeys: String, CodingKey {
        case memberCount = "member_count"
        case recentActivity = "recent_activity"
    }
}

struct TeamActivityEntry: Codable, Identifiable {
    var id: String { "\(user)-\(action)-\(timestamp)" }
    let user: String
    let action: String
    let timestamp: String
}

// MARK: - ProjectReportView

struct ProjectReportView: View {
    let project: SupabaseProject
    let isDemo: Bool

    @State private var reportData: ProjectReportData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let supabase = SupabaseService.shared
    private let cacheKeyPrefix = "ConstructOS.Reports.ProjectCache."

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                reportHeader
                if isLoading {
                    reportSkeleton
                } else if let err = errorMessage {
                    sectionError(err)
                } else {
                    reportSections
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .refreshable { await loadReport() }
        .task { await loadReport() }
        .navigationTitle(project.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Report Header (D-10)

    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROJECT REPORT")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(3)
                        .foregroundColor(Theme.green)
                    Text(project.name)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Theme.text)
                    Text(project.client)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                healthBadgeLarge
            }

            // D-16b: generation timestamp
            if let genAt = reportData?.generatedAt {
                Text("Generated \(genAt)")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
            } else {
                Text("Generated \(formattedDate())")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    private var healthBadgeLarge: some View {
        let score = reportData?.project?.healthScore ?? (Double(project.score) ?? 0)
        let color: Color = score >= 80 ? Theme.green : (score >= 60 ? Theme.gold : Theme.red)
        let label = score >= 80 ? "On Track" : (score >= 60 ? "At Risk" : "Critical")
        return VStack(spacing: 4) {
            Text("\(Int(score))%")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(color)
            Text(label.uppercased())
                .font(.system(size: 8, weight: .heavy))
                .tracking(1)
                .foregroundColor(color)
        }
        .accessibilityLabel("Health score: \(Int(score)) percent, \(label)")
    }

    // MARK: - Report Sections

    @ViewBuilder
    private var reportSections: some View {
        budgetSection
        scheduleSection
        safetySection
        teamSection
        insightsSection
    }

    // MARK: - Budget Section

    private var budgetSection: some View {
        let budget = reportData?.budget
        let spent = budget?.totalBilled ?? 0
        let total = budget?.contractValue ?? 0
        let pct = budget?.percentComplete ?? (total > 0 ? (spent / total) * 100 : 0)
        let budgetColor: Color = pct >= 90 ? Theme.red : (pct >= 75 ? Theme.gold : Theme.green)

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading("BUDGET & FINANCIALS", color: Theme.accent)

            // Stat cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statCard("CONTRACT", formatCurrency(total), Theme.text)
                statCard("BILLED", formatCurrency(spent), Theme.accent)
                statCard("REMAINING", formatCurrency(max(0, total - spent)), Theme.cyan)
                statCard("COMPLETE", "\(Int(pct))%", budgetColor)
            }
            .accessibilityLabel("Budget: \(Int(pct))% spent\(pct >= 90 ? " -- at risk" : "")")

            if budget?.changeOrderNet != nil || budget?.retainage != nil {
                HStack(spacing: 8) {
                    if let co = budget?.changeOrderNet {
                        miniStat("CHANGE ORDERS", formatCurrency(co))
                    }
                    if let ret = budget?.retainage {
                        miniStat("RETAINAGE", formatCurrency(ret))
                    }
                }
            }

            // Budget pie chart placeholder -- rendered by ReportCharts
            if total > 0 {
                BudgetPieChartView(spent: spent, remaining: max(0, total - spent))
                    .frame(height: chartHeight)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        let schedule = reportData?.schedule
        let milestones = schedule?.milestones ?? []

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading("SCHEDULE & MILESTONES", color: Theme.cyan)

            if milestones.isEmpty {
                noneRecorded
            } else {
                // Milestone progress bars (D-12)
                ForEach(milestones.prefix(8)) { ms in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(ms.name)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.text)
                            Spacer()
                            Text("\(Int(ms.percentComplete))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.muted)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.border.opacity(0.3))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(ms.percentComplete >= 80 ? Theme.green : (ms.percentComplete >= 50 ? Theme.gold : Theme.red))
                                    .frame(width: geo.size.width * CGFloat(min(ms.percentComplete, 100)) / 100, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .accessibilityLabel("\(ms.name): \(Int(ms.percentComplete))% complete")
                }

                // Schedule bar chart
                let chartData = milestones.prefix(8).map { (name: $0.name, percent: $0.percentComplete) }
                ScheduleBarChartView(milestones: chartData)
                    .frame(height: chartHeight)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    // MARK: - Safety Section (D-16)

    private var safetySection: some View {
        let safety = reportData?.safety

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading("SAFETY", color: Theme.red)

            if let safety = safety, (safety.totalIncidents ?? 0) > 0 {
                // Severity badges
                HStack(spacing: 8) {
                    severityBadge("Minor", safety.minor ?? 0, Theme.gold)
                    severityBadge("Moderate", safety.moderate ?? 0, Theme.accent)
                    severityBadge("Serious", safety.serious ?? 0, Theme.red)
                }
                .accessibilityLabel("Safety: \(safety.totalIncidents ?? 0) total incidents, \(safety.serious ?? 0) serious")

                // Days since last
                if let days = safety.daysSinceLastIncident, days >= 0 {
                    HStack(spacing: 4) {
                        Text("Days since last incident:")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.muted)
                        Text("\(days)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(days > 30 ? Theme.green : Theme.gold)
                    }
                }

                // Safety line chart
                if let monthly = safety.monthlyData, !monthly.isEmpty {
                    let chartData = monthly.map { (month: $0.month, count: $0.count) }
                    SafetyLineChartView(monthlyData: chartData)
                        .frame(height: chartHeight)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(Theme.green)
                    Text("No safety incidents recorded")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.green)
                }
                .accessibilityLabel("Safety: no incidents recorded")
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    // MARK: - Team Section (D-14)

    private var teamSection: some View {
        let team = reportData?.team

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading("TEAM & ACTIVITY", color: Theme.purple)

            HStack {
                Text("Members")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
                Spacer()
                Text("\(team?.memberCount ?? Int(project.team) ?? 0)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.text)
            }

            if let activities = team?.recentActivity, !activities.isEmpty {
                ForEach(activities.prefix(5)) { activity in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.purple.opacity(0.3))
                            .frame(width: 6, height: 6)
                        Text("\(activity.user) \(activity.action)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                        Spacer()
                        Text(activity.timestamp)
                            .font(.system(size: 9))
                            .foregroundColor(Theme.muted)
                    }
                }
            } else {
                noneRecorded
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    // MARK: - AI Insights Section (D-16d)

    private var insightsSection: some View {
        let insights = reportData?.insights ?? []

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading("KEY INSIGHTS", color: Theme.accent)

            if insights.isEmpty {
                Text("Add more project data to unlock AI-powered insights.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
            } else {
                ForEach(Array(insights.enumerated()), id: \.offset) { _, insight in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.gold)
                        Text(insight)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.text)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    // MARK: - Skeleton Loading (D-58)

    private var reportSkeleton: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.surface)
                        .frame(height: 72)
                }
            }
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .frame(height: 200)
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.surface)
                    .frame(height: 48)
            }
        }
    }

    // MARK: - Shared Sub-Views

    private func sectionHeading(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy))
            .tracking(2)
            .foregroundColor(color)
    }

    private func statCard(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Theme.accent.opacity(0.06))
        .cornerRadius(10)
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.text)
            Text(label)
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Theme.panel)
        .cornerRadius(8)
    }

    private func severityBadge(_ label: String, _ count: Int, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            Text(label.uppercased())
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(4)
    }

    private var noneRecorded: some View {
        Text("None recorded")
            .font(.system(size: 12))
            .foregroundColor(Theme.muted)
    }

    private func sectionError(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(Theme.red)
            Text("Report data could not be loaded. Check your connection and try again.")
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadReport() }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Theme.bg)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Theme.accent)
            .cornerRadius(8)
        }
        .padding(32)
    }

    // MARK: - Chart Height (D-71: landscape support)

    private var chartHeight: CGFloat {
        #if os(iOS)
        let isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        return isLandscape ? 300 : 200
        #else
        return 200
        #endif
    }

    // MARK: - Data Loading (D-55)

    private func loadReport() async {
        isLoading = reportData == nil
        errorMessage = nil

        // Try web API first (D-55)
        if supabase.isWebAppConfigured, let projectId = project.id {
            do {
                let request = try supabase.makeReportRequest(path: "/api/reports/project/\(projectId)")
                let (data, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard (200...299).contains(statusCode) else {
                    throw AppError.supabaseHTTP(statusCode: statusCode, body: "Report API returned \(statusCode)")
                }
                // T-19-28: Validate JSON structure before rendering
                let decoded = try JSONDecoder().decode(ProjectReportData.self, from: data)
                await MainActor.run {
                    reportData = decoded
                    isLoading = false
                    cacheReport(data)
                }
                return
            } catch {
                CrashReporter.shared.reportError("Report API fetch failed: \(error.localizedDescription)")
                // Fall through to local fallback
            }
        }

        // Fallback: local aggregation from cached data or demo (D-55)
        if let cached = loadCachedReport() {
            await MainActor.run {
                reportData = cached
                isLoading = false
            }
        } else if isDemo {
            await MainActor.run {
                reportData = buildDemoReport()
                isLoading = false
            }
        } else {
            await MainActor.run {
                reportData = buildLocalReport()
                isLoading = false
            }
        }
    }

    // MARK: - Cache (D-68)

    private func cacheReport(_ data: Data) {
        if let projectId = project.id {
            UserDefaults.standard.set(data, forKey: cacheKeyPrefix + projectId)
        }
    }

    private func loadCachedReport() -> ProjectReportData? {
        guard let projectId = project.id,
              let data = UserDefaults.standard.data(forKey: cacheKeyPrefix + projectId) else { return nil }
        return try? JSONDecoder().decode(ProjectReportData.self, from: data)
    }

    // MARK: - Local Fallback Reports

    private func buildLocalReport() -> ProjectReportData {
        let budget = parseBudget(project.budget)
        return ProjectReportData(
            project: ProjectReportProject(
                name: project.name, client: project.client,
                status: project.status,
                healthScore: Double(project.score) ?? 0,
                healthLabel: healthLabel(for: Double(project.score) ?? 0)
            ),
            budget: ProjectReportBudget(
                contractValue: budget,
                totalBilled: budget * Double(project.progress) / 100,
                percentComplete: Double(project.progress),
                changeOrderNet: nil, retainage: nil
            ),
            schedule: ProjectReportSchedule(milestones: [], percentOnTrack: nil),
            safety: ProjectReportSafety(totalIncidents: 0, minor: 0, moderate: 0, serious: 0, daysSinceLastIncident: -1, monthlyData: nil),
            team: ProjectReportTeam(memberCount: Int(project.team), recentActivity: nil),
            insights: nil,
            generatedAt: formattedDate()
        )
    }

    private func buildDemoReport() -> ProjectReportData {
        let budget = parseBudget(project.budget)
        let spent = budget * 0.72
        return ProjectReportData(
            project: ProjectReportProject(
                name: project.name, client: project.client,
                status: project.status,
                healthScore: Double(project.score) ?? 85,
                healthLabel: healthLabel(for: Double(project.score) ?? 85)
            ),
            budget: ProjectReportBudget(
                contractValue: budget, totalBilled: spent,
                percentComplete: 72, changeOrderNet: 45000, retainage: 62500
            ),
            schedule: ProjectReportSchedule(
                milestones: [
                    ReportMilestone(name: "Foundation", percentComplete: 100),
                    ReportMilestone(name: "Framing", percentComplete: 85),
                    ReportMilestone(name: "Electrical", percentComplete: 60),
                    ReportMilestone(name: "Plumbing", percentComplete: 55),
                    ReportMilestone(name: "Finishing", percentComplete: 20)
                ],
                percentOnTrack: 80
            ),
            safety: ProjectReportSafety(
                totalIncidents: 3, minor: 2, moderate: 1, serious: 0,
                daysSinceLastIncident: 14,
                monthlyData: [
                    SafetyMonthData(month: "Jan", count: 1),
                    SafetyMonthData(month: "Feb", count: 0),
                    SafetyMonthData(month: "Mar", count: 2),
                    SafetyMonthData(month: "Apr", count: 0)
                ]
            ),
            team: ProjectReportTeam(
                memberCount: 8,
                recentActivity: [
                    TeamActivityEntry(user: "John D.", action: "updated schedule", timestamp: "2h ago"),
                    TeamActivityEntry(user: "Sarah M.", action: "submitted RFI", timestamp: "4h ago"),
                    TeamActivityEntry(user: "Mike R.", action: "closed punch item", timestamp: "1d ago")
                ]
            ),
            insights: [
                "Budget utilization at 72% aligns well with 72% schedule completion.",
                "Safety incident rate trending down over the last quarter.",
                "Consider increasing crew size for the finishing phase to meet deadline."
            ],
            generatedAt: formattedDate()
        )
    }

    // MARK: - Helpers

    private func parseBudget(_ text: String) -> Double {
        let cleaned = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned) ?? 0
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }

    private func healthLabel(for score: Double) -> String {
        score >= 80 ? "On Track" : (score >= 60 ? "At Risk" : "Critical")
    }

    private func formattedDate() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM dd, yyyy 'at' HH:mm"
        return fmt.string(from: Date())
    }
}

// MARK: - SupabaseService Report Helper

extension SupabaseService {
    /// Build a URLRequest for a report API endpoint.
    /// Uses the same web app base URL and auth token as calendar API.
    func makeReportRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard isWebAppConfigured else {
            throw AppError.supabaseNotConfigured
        }
        guard let url = URL(string: "\(webAppBaseURL)\(path)") else {
            throw AppError.validationFailed(field: "URL", reason: "Invalid report API path: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        // CSRF: match the pattern from makeWebAPIRequest
        request.setValue(webAppBaseURL, forHTTPHeaderField: "Origin")
        request.setValue("1", forHTTPHeaderField: "X-CSRF-Token")
        return request
    }
}
