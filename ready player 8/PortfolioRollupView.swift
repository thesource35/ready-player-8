import SwiftUI

// MARK: - ========== PortfolioRollupView.swift ==========
// Phase 19: Portfolio rollup view with KPI cards, project list, charts.
// D-36: Summary KPIs + project list + charts.
// D-41: Portfolio-level health score. D-42: Status filter.
// D-45: Pull-to-refresh. D-55: Web API fetch with offline fallback.
// D-68: Cache in UserDefaults for offline.

// MARK: - Rollup Data Models

struct PortfolioRollupData: Codable {
    let totalContractValue: Double?
    let totalBilled: Double?
    let totalRemaining: Double?
    let projectCount: Int?
    let healthScore: Double?
    let projects: [RollupProjectEntry]?
    let monthlySpend: [RollupMonthlySpend]?

    enum CodingKeys: String, CodingKey {
        case totalContractValue = "total_contract_value"
        case totalBilled = "total_billed"
        case totalRemaining = "total_remaining"
        case projectCount = "project_count"
        case healthScore = "health_score"
        case projects
        case monthlySpend = "monthly_spend"
    }
}

struct RollupProjectEntry: Codable, Identifiable {
    let id: String
    let name: String
    let client: String?
    let status: String?
    let healthScore: Double?
    let budget: String?
    let progress: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, client, status
        case healthScore = "health_score"
        case budget, progress
    }
}

struct RollupMonthlySpend: Codable, Identifiable {
    var id: String { month }
    let month: String
    let amount: Double
}

// MARK: - PortfolioRollupView

struct PortfolioRollupView: View {
    @State private var rollupData: PortfolioRollupData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var statusFilter = "All"

    private let supabase = SupabaseService.shared
    private let cacheKey = "ConstructOS.Reports.PortfolioRollupCache"
    private let statusFilters = ["All", "On Track", "At Risk", "Delayed", "Completed"]

    private var filteredProjects: [RollupProjectEntry] {
        let projects = rollupData?.projects ?? Self.demoProjects
        if statusFilter == "All" { return projects }
        return projects.filter { ($0.status ?? "") == statusFilter }
    }

    private var isDemo: Bool { rollupData == nil || rollupData?.projects == nil }

    // MARK: - Demo Data (D-66c)

    private static let demoProjects: [RollupProjectEntry] = [
        RollupProjectEntry(id: "demo-1", name: "Tower Project", client: "Sample Corp", status: "On Track", healthScore: 85, budget: "$1,250,000", progress: 72),
        RollupProjectEntry(id: "demo-2", name: "Bridge Renovation", client: "City Works", status: "At Risk", healthScore: 62, budget: "$890,000", progress: 45),
        RollupProjectEntry(id: "demo-3", name: "Office Fit-Out", client: "TechStart Inc", status: "Delayed", healthScore: 41, budget: "$340,000", progress: 30)
    ]

    private static let demoRollup = PortfolioRollupData(
        totalContractValue: 2_480_000, totalBilled: 1_340_000, totalRemaining: 1_140_000,
        projectCount: 3, healthScore: 63,
        projects: demoProjects,
        monthlySpend: [
            RollupMonthlySpend(month: "Jan", amount: 180_000),
            RollupMonthlySpend(month: "Feb", amount: 220_000),
            RollupMonthlySpend(month: "Mar", amount: 310_000),
            RollupMonthlySpend(month: "Apr", amount: 290_000)
        ]
    )

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if isDemo {
                    demoBanner
                }
                if isLoading {
                    rollupSkeleton
                } else if let err = errorMessage {
                    rollupError(err)
                } else {
                    portfolioContent
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .refreshable { await loadRollup() }
        .task { await loadRollup() }
    }

    // MARK: - Portfolio Content

    @ViewBuilder
    private var portfolioContent: some View {
        let data = rollupData ?? Self.demoRollup

        // D-41: Portfolio-level health score
        portfolioHealthHeader(data)

        // KPI stat cards
        kpiCards(data)

        // D-42: Status filter
        statusFilterPicker

        // D-43: Monthly spend trend chart
        if let monthly = data.monthlySpend, !monthly.isEmpty {
            let chartData = monthly.map { (month: $0.month, count: Int($0.amount / 1000)) }
            VStack(alignment: .leading, spacing: 8) {
                Text("MONTHLY SPEND TREND")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(Theme.accent)
                ActivityTrendChartView(data: chartData)
                    .frame(height: 200)
            }
        }

        // D-40: Project list with health badges
        projectList
    }

    // MARK: - Portfolio Health Header (D-41)

    private func portfolioHealthHeader(_ data: PortfolioRollupData) -> some View {
        let score = data.healthScore ?? 63
        let color: Color = score >= 80 ? Theme.green : (score >= 60 ? Theme.gold : Theme.red)
        let label = score >= 80 ? "On Track" : (score >= 60 ? "At Risk" : "Critical")

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PORTFOLIO ROLLUP")
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(3)
                    .foregroundColor(Theme.green)
                Text("Portfolio Overview")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(Theme.text)
                Text("\(data.projectCount ?? filteredProjects.count) projects")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(spacing: 4) {
                Text("\(Int(score))%")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(color)
                Text(label.uppercased())
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(color)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
        .accessibilityLabel("Portfolio health: \(Int(score)) percent, \(label)")
    }

    // MARK: - KPI Cards (D-36)

    private func kpiCards(_ data: PortfolioRollupData) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            kpiCard("CONTRACT VALUE", formatCurrency(data.totalContractValue ?? 0), Theme.text)
            kpiCard("TOTAL BILLED", formatCurrency(data.totalBilled ?? 0), Theme.accent)
            kpiCard("REMAINING", formatCurrency(data.totalRemaining ?? 0), Theme.cyan)
            kpiCard("PROJECTS", "\(data.projectCount ?? filteredProjects.count)", Theme.green)
        }
    }

    private func kpiCard(_ label: String, _ value: String, _ color: Color) -> some View {
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

    // MARK: - Status Filter (D-42)

    private var statusFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(statusFilters, id: \.self) { filter in
                    Button(action: {
                        statusFilter = filter
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }) {
                        Text(filter.uppercased())
                            .font(.system(size: 8, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(statusFilter == filter ? Theme.bg : Theme.text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusFilter == filter ? Theme.accent : Theme.surface)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Project List (D-40)

    private var projectList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROJECTS")
                .font(.system(size: 12, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.cyan)

            if filteredProjects.isEmpty {
                Text("No projects match the selected filter.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
                    .padding(16)
            } else {
                ForEach(filteredProjects) { project in
                    projectRow(project)
                }
            }
        }
    }

    private func projectRow(_ project: RollupProjectEntry) -> some View {
        let score = project.healthScore ?? 0
        let color: Color = score >= 80 ? Theme.green : (score >= 60 ? Theme.gold : Theme.red)
        let label = score >= 80 ? "On Track" : (score >= 60 ? "At Risk" : "Critical")

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.text)
                if let client = project.client {
                    Text(client)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                }
            }
            Spacer()
            // Health badge
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .accessibilityLabel("\(project.name): health \(label), \(Int(score)) percent")
    }

    // MARK: - Demo Banner (D-66c)

    private var demoBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Theme.gold)
            Text("This is a demo report with sample data. Create a project to see your own data.")
                .font(.system(size: 11))
                .foregroundColor(Theme.gold)
        }
        .padding(12)
        .background(Theme.gold.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Skeleton Loading (D-58)

    private var rollupSkeleton: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.surface)
                        .frame(height: 72)
                }
            }
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .frame(height: 240)
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.surface)
                    .frame(height: 48)
            }
        }
    }

    // MARK: - Error View

    private func rollupError(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(Theme.red)
            Text("Report data could not be loaded. Check your connection and try again.")
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadRollup() }
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

    // MARK: - Data Loading (D-55)

    private func loadRollup() async {
        isLoading = rollupData == nil
        errorMessage = nil

        // Try web API first (D-55)
        if supabase.isWebAppConfigured {
            do {
                let request = try supabase.makeReportRequest(path: "/api/reports/rollup")
                let (data, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard (200...299).contains(statusCode) else {
                    throw AppError.supabaseHTTP(statusCode: statusCode, body: "Rollup API returned \(statusCode)")
                }
                // T-19-28: Validate JSON structure before rendering
                let decoded = try JSONDecoder().decode(PortfolioRollupData.self, from: data)
                await MainActor.run {
                    rollupData = decoded
                    isLoading = false
                    cacheRollup(data)
                }
                return
            } catch {
                CrashReporter.shared.reportError("Rollup API fetch failed: \(error.localizedDescription)")
            }
        }

        // Fallback: cached data or demo
        if let cached = loadCachedRollup() {
            await MainActor.run {
                rollupData = cached
                isLoading = false
            }
        } else {
            await MainActor.run {
                rollupData = Self.demoRollup
                isLoading = false
            }
        }
    }

    // MARK: - Cache (D-68)

    private func cacheRollup(_ data: Data) {
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private func loadCachedRollup() -> PortfolioRollupData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(PortfolioRollupData.self, from: data)
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}
