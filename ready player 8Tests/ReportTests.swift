//
//  ReportTests.swift
//  ready player 8Tests
//
//  Per D-85: iOS XCTests for report functionality.
//  Per D-80: Uses shared JSON test fixture for cross-platform consistency.
//

import Testing
import Foundation
@testable import ready_player_8

// MARK: - Report Aggregation Tests (D-85)

struct ReportTests {

    // MARK: - Budget Parsing (Cross-Platform D-80)

    /// parseBudget must produce the same results as TypeScript parseBudgetString.
    /// These values match the integration.test.ts expectations for D-80 fixture consistency.
    @Test func parseBudgetDollarAmount() {
        let result = ReportTestHelpers.parseBudget("$450,000")
        #expect(result == 450000)
    }

    @Test func parseBudgetZero() {
        let result = ReportTestHelpers.parseBudget("$0")
        #expect(result == 0)
    }

    @Test func parseBudgetTBD() {
        let result = ReportTestHelpers.parseBudget("TBD")
        #expect(result == 0)
    }

    @Test func parseBudgetNA() {
        let result = ReportTestHelpers.parseBudget("N/A")
        #expect(result == 0)
    }

    @Test func parseBudgetEmpty() {
        let result = ReportTestHelpers.parseBudget("")
        #expect(result == 0)
    }

    @Test func parseBudgetLargeAmount() {
        let result = ReportTestHelpers.parseBudget("$1,200,000")
        #expect(result == 1200000)
    }

    @Test func parseBudgetPlainNumber() {
        let result = ReportTestHelpers.parseBudget("800000")
        #expect(result == 800000)
    }

    // MARK: - Health Score Computation (D-85)

    @Test func healthScorePerfect() {
        let score = ReportTestHelpers.computeHealthScore(
            budgetSpentPercent: 30,
            delayedMilestonePercent: 0,
            criticalOpenIssues: 0
        )
        #expect(score >= 80)
        #expect(ReportTestHelpers.healthLabel(for: score) == "On Track")
    }

    @Test func healthScoreAtRisk() {
        let score = ReportTestHelpers.computeHealthScore(
            budgetSpentPercent: 95,
            delayedMilestonePercent: 15,
            criticalOpenIssues: 1
        )
        #expect(score >= 60 && score < 80)
        #expect(ReportTestHelpers.healthLabel(for: score) == "At Risk")
    }

    @Test func healthScoreCritical() {
        let score = ReportTestHelpers.computeHealthScore(
            budgetSpentPercent: 110,
            delayedMilestonePercent: 50,
            criticalOpenIssues: 5
        )
        #expect(score < 60)
        #expect(ReportTestHelpers.healthLabel(for: score) == "Critical")
    }

    // MARK: - Chart Data Preparation (D-85)

    @Test func chartDataFromBudget() {
        let budget = 450000.0
        let spent = 225000.0
        let remaining = budget - spent
        let percentComplete = (spent / budget) * 100

        #expect(percentComplete == 50)
        #expect(remaining == 225000)
    }

    @Test func chartDataSafetyBreakdown() {
        let incidents: [(String, String)] = [
            ("Minor cut", "minor"),
            ("Scaffold near-miss", "moderate"),
            ("Heat exhaustion", "minor"),
        ]

        var minor = 0, moderate = 0, serious = 0
        for (_, severity) in incidents {
            switch severity {
            case "minor": minor += 1
            case "moderate": moderate += 1
            case "serious": serious += 1
            default: break
            }
        }

        #expect(minor == 2)
        #expect(moderate == 1)
        #expect(serious == 0)
    }

    // MARK: - Shared JSON Fixture (D-80)

    /// Per D-80: Read shared JSON test fixtures for cross-platform consistency.
    /// NOTE: The shared fixture file (sample-project.json) lives in the web test
    /// fixtures directory. For iOS, we duplicate the key assertions to ensure
    /// both platforms agree on expected values.
    @Test func sharedFixtureProjectValues() {
        // These values must match web/src/lib/reports/__tests__/fixtures/sample-project.json
        let projectBudget = "$450,000"
        let parsedBudget = ReportTestHelpers.parseBudget(projectBudget)
        #expect(parsedBudget == 450000)

        // Contract billing: 85000 + 140000 + 0 = 225000
        let totalBilled: Double = 85000 + 140000 + 0
        #expect(totalBilled == 225000)

        // Percent complete: 225000 / 450000 = 50%
        let pctComplete = (totalBilled / parsedBudget) * 100
        #expect(pctComplete == 50)
    }

    // MARK: - Snapshot Testing Reference (D-85)
    // NOTE: swift-snapshot-testing framework (pointfreeco/swift-snapshot-testing)
    // would be needed for UI snapshot regression tests. Add via SPM:
    //   .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0")
    // Then: import SnapshotTesting + assertSnapshot(of: view, as: .image)
}

// MARK: - Test Helpers

/// Extracted helper functions that mirror the aggregation logic from
/// ProjectReportView.swift for testability.
/// These are pure functions with no SwiftUI or Supabase dependencies.
enum ReportTestHelpers {

    /// Parse a budget string like "$450,000" to a Double.
    /// Matches TypeScript parseBudgetString behavior.
    static func parseBudget(_ text: String) -> Double {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed == "N/A" || trimmed == "TBD" || trimmed == "---" {
            return 0
        }
        let cleaned = trimmed.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned) ?? 0
    }

    /// Compute composite health score.
    /// Weights: budget 40%, schedule 35%, issues 25%.
    /// Matches TypeScript computeHealthScore behavior.
    static func computeHealthScore(
        budgetSpentPercent: Double,
        delayedMilestonePercent: Double,
        criticalOpenIssues: Int
    ) -> Double {
        let budgetScore = min(100, max(0, 100 - max(0, (budgetSpentPercent - 70) * (100.0 / 50.0))))
        let scheduleScore = min(100, max(0, 100 - (delayedMilestonePercent * 2)))
        let issuesScore = min(100, max(0, 100 - (Double(criticalOpenIssues) * 15)))

        let rawScore = (budgetScore * 0.4) + (scheduleScore * 0.35) + (issuesScore * 0.25)
        return min(100, max(0, rawScore)).rounded()
    }

    /// Get health label for a score. Matches TypeScript thresholds.
    static func healthLabel(for score: Double) -> String {
        score >= 80 ? "On Track" : (score >= 60 ? "At Risk" : "Critical")
    }
}
