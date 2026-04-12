import SwiftUI

// MARK: - ========== ReportsView.swift ==========
// Phase 19: Reports tab with segmented control for Project Report / Portfolio Rollup.
// iPhone: single-column stacked cards (D-09). iPad: NavigationSplitView (D-09).

struct ReportsView: View {
    @State private var selectedTab: Int = 0
    @State private var projects: [SupabaseProject] = loadJSON("ConstructOS.Projects.DataRaw", default: [SupabaseProject]())
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedProjectId: String?

    private let supabase = SupabaseService.shared

    // MARK: - Demo data for D-66c
    private static let demoProjects: [SupabaseProject] = [
        SupabaseProject(id: "demo-1", name: "Demo Tower Project", client: "Sample Corp", type: "Commercial", status: "On Track", progress: 72, budget: "$1,250,000", score: "85", team: "8"),
        SupabaseProject(id: "demo-2", name: "Demo Bridge Renovation", client: "City Works", type: "Infrastructure", status: "At Risk", progress: 45, budget: "$890,000", score: "62", team: "5"),
        SupabaseProject(id: "demo-3", name: "Demo Office Fit-Out", client: "TechStart Inc", type: "Commercial", status: "Delayed", progress: 30, budget: "$340,000", score: "41", team: "3")
    ]

    private var displayProjects: [SupabaseProject] {
        let list = supabase.isConfigured ? projects : []
        if list.isEmpty { return Self.demoProjects }
        return list
    }

    private var isDemo: Bool {
        let list = supabase.isConfigured ? projects : []
        return list.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // D-44: segmented control
            segmentedControl
            // Content
            if isLoading {
                skeletonLoading
            } else if let err = errorMessage {
                reportErrorView(err)
            } else {
                reportContent
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .refreshable { await loadProjects() }
        .task { await loadProjects() }
    }

    // MARK: - Segmented Control (D-44)

    private var segmentedControl: some View {
        Picker("Report Type", selection: $selectedTab) {
            Text("Project Report").tag(0)
            Text("Portfolio Rollup").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onChange(of: selectedTab) { _, _ in
            // D-69: haptic on tab switch
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
    }

    // MARK: - Report Content

    @ViewBuilder
    private var reportContent: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // D-09: iPad NavigationSplitView
            iPadSplitView
        } else {
            // D-09: iPhone single-column
            iPhoneView
        }
        #else
        // macOS: use split view
        iPadSplitView
        #endif
    }

    // MARK: - iPhone Layout (D-09)

    private var iPhoneView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if isDemo {
                    demoBanner
                }
                if selectedTab == 0 {
                    projectListView
                } else {
                    PortfolioRollupView()
                }
            }
            .padding(16)
        }
    }

    // MARK: - iPad Layout (D-09)

    private var iPadSplitView: some View {
        NavigationSplitView {
            // Sidebar: project list
            List(displayProjects, selection: $selectedProjectId) { project in
                projectSidebarRow(project)
                    .tag(project.id)
                    .listRowBackground(
                        selectedProjectId == project.id
                            ? Theme.accent.opacity(0.15)
                            : Color.clear
                    )
            }
            .listStyle(.sidebar)
            .navigationTitle("Reports")
            .frame(minWidth: 280)
        } detail: {
            if selectedTab == 1 {
                PortfolioRollupView()
            } else if let projectId = selectedProjectId,
                      let project = displayProjects.first(where: { $0.id == projectId }) {
                ProjectReportView(project: project, isDemo: isDemo)
            } else {
                reportPlaceholder
            }
        }
    }

    // MARK: - Project List

    private var projectListView: some View {
        ForEach(displayProjects) { project in
            NavigationLink(destination: ProjectReportView(project: project, isDemo: isDemo)) {
                projectCard(project)
            }
            .buttonStyle(.plain)
        }
    }

    private func projectCard(_ project: SupabaseProject) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.text)
                Text(project.client)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            healthBadge(score: Double(project.score) ?? 0)
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    private func projectSidebarRow(_ project: SupabaseProject) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.text)
                Text(project.client)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            healthBadge(score: Double(project.score) ?? 0)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Health Badge

    func healthBadge(score: Double) -> some View {
        let color: Color = score >= 80 ? Theme.green : (score >= 60 ? Theme.gold : Theme.red)
        let label = score >= 80 ? "On Track" : (score >= 60 ? "At Risk" : "Critical")
        return HStack(spacing: 4) {
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
        .accessibilityLabel("Health: \(label), score \(Int(score))%")
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

    private var skeletonLoading: some View {
        ScrollView {
            VStack(spacing: 12) {
                // KPI skeleton
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.surface)
                            .frame(height: 72)
                    }
                }
                // Chart skeleton
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
                    .frame(height: 240)
                // List skeleton
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.surface)
                        .frame(height: 48)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Error View

    private func reportErrorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(Theme.red)
            Text("Report data could not be loaded. Check your connection and try again.")
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadProjects() }
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

    // MARK: - Placeholder

    private var reportPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(Theme.muted.opacity(0.5))
            Text("Select a project to view its report")
                .font(.system(size: 14))
                .foregroundColor(Theme.muted)
        }
    }

    // MARK: - Data Loading

    private func loadProjects() async {
        guard supabase.isConfigured else { return }
        isLoading = projects.isEmpty
        errorMessage = nil
        do {
            let remote: [SupabaseProject] = try await supabase.fetch("cs_projects")
            await MainActor.run {
                projects = remote
                isLoading = false
                saveJSON("ConstructOS.Projects.DataRaw", value: projects)
            }
        } catch {
            await MainActor.run {
                isLoading = false
                if projects.isEmpty {
                    errorMessage = error.localizedDescription
                }
                CrashReporter.shared.reportError("Reports loadProjects failed: \(error.localizedDescription)")
            }
        }
    }
}
