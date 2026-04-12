import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

// MARK: - ========== ShowReportIntent.swift ==========
// Phase 19: Siri Shortcuts for reports via AppIntents framework.
// D-70: "Show project report" and "Portfolio health" voice commands.
// Note: ShowReportIntent and PortfolioHealthIntent are defined in ReportScheduleManager.swift.
// This file adds parameterized variants and the AppShortcutsProvider registration.

#if canImport(AppIntents)

// MARK: - D-70: Parameterized Project Report Intent

/// Siri intent to show a specific project report by name.
/// Usage: "Hey Siri, show project report for Tower Project"
@available(iOS 16.0, *)
struct ShowProjectReportByNameIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Project Report"
    static var description = IntentDescription("Opens the ConstructionOS Reports tab to view a specific project report")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Project Name")
    var projectName: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Show report for \(\.$projectName)")
    }

    func perform() async throws -> some IntentResult {
        if let name = projectName, !name.isEmpty {
            // Post notification with project name for deep linking
            NotificationCenter.default.post(
                name: .navigateToProjectReport,
                object: nil,
                userInfo: ["projectName": name]
            )
        } else {
            // Navigate to Reports tab without specific project
            NotificationCenter.default.post(name: .navigateToReports, object: nil)
        }
        return .result()
    }
}

// MARK: - Notification Names for Deep Linking

extension Notification.Name {
    /// Navigate to a specific project report (userInfo contains "projectName")
    static let navigateToProjectReport = Notification.Name("com.constructionos.navigateToProjectReport")
}

// MARK: - D-70: AppShortcutsProvider Registration

/// Registers all report-related Siri Shortcuts with the system.
/// This makes intents discoverable in the Shortcuts app and via Siri.
@available(iOS 16.0, *)
struct ReportShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowProjectReportByNameIntent(),
            phrases: [
                "Show project report in \(.applicationName)",
                "Open project report in \(.applicationName)"
            ],
            shortTitle: "Show Project Report",
            systemImageName: "chart.bar.doc.horizontal"
        )
        AppShortcut(
            intent: PortfolioHealthIntent(),
            phrases: [
                "Portfolio health in \(.applicationName)",
                "Show portfolio health in \(.applicationName)",
                "How are my projects doing in \(.applicationName)"
            ],
            shortTitle: "Portfolio Health",
            systemImageName: "heart.text.square"
        )
    }
}

#endif

// MARK: - Suggested Invocation Phrases (D-70)
// "Show project report" -> ShowProjectReportByNameIntent
// "Portfolio health" -> PortfolioHealthIntent (from ReportScheduleManager.swift)
//
// Users can also create custom shortcuts in the Shortcuts app
// using the registered AppShortcuts above.
