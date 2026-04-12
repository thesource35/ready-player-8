import SwiftUI

// MARK: - ========== ReportAccessibility.swift ==========
// Phase 19: Comprehensive accessibility support for report views.
// D-75: VoiceOver semantic announcements with interpretation.
// D-26d / D-90: High contrast mode detection and chart pattern adjustment.
// D-88: Keyboard navigation helpers for chart data points.
// D-89: Tagged PDF accessibility notes.
// D-86: String Catalogs / LocalizedStringKey usage for i18n.

// MARK: - D-75: VoiceOver Semantic Announcement Modifier

/// View modifier that provides rich VoiceOver announcements with metric context.
/// Example: metric="Budget", value="92%", interpretation="at risk"
///   -> announces "Budget: 92% -- at risk"
struct ReportAccessibilityModifier: ViewModifier {
    let metric: String
    let value: String
    let interpretation: String

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(reportAccessibilityLabel))
            .accessibilityValue(Text(value))
            .accessibilityHint(Text(reportAccessibilityHint))
    }

    private var reportAccessibilityLabel: LocalizedStringKey {
        LocalizedStringKey("\(metric): \(value) -- \(interpretation)")
    }

    private var reportAccessibilityHint: LocalizedStringKey {
        LocalizedStringKey("Double tap to view \(metric.lowercased()) details")
    }
}

extension View {
    /// D-75: Attach semantic VoiceOver announcement to a report metric view.
    /// - Parameters:
    ///   - metric: The metric name (e.g., "Budget", "Schedule", "Health Score")
    ///   - value: The displayed value (e.g., "92%", "$1.2M", "78")
    ///   - interpretation: Human-readable status (e.g., "at risk", "on track", "critical")
    /// - Returns: Modified view with combined accessibility label and hint.
    func reportAccessibility(metric: String, value: String, interpretation: String) -> some View {
        self.modifier(ReportAccessibilityModifier(metric: metric, value: value, interpretation: interpretation))
    }
}

// MARK: - D-26d / D-90: High Contrast Mode Support

/// Helper to detect OS high contrast mode and provide accessible chart styling.
struct ReportHighContrastHelper {
    let isHighContrast: Bool

    // MARK: High Contrast Colors

    /// Adjusted chart colors with increased saturation for high contrast mode.
    var budgetSpentColor: Color {
        isHighContrast ? Color(red: 1.0, green: 0.4, blue: 0.0) : Theme.accent
    }

    var budgetRemainingColor: Color {
        isHighContrast ? Color(red: 0.0, green: 0.6, blue: 0.9) : Theme.cyan
    }

    var healthGreenColor: Color {
        isHighContrast ? Color(red: 0.0, green: 0.7, blue: 0.2) : Theme.green
    }

    var healthGoldColor: Color {
        isHighContrast ? Color(red: 0.9, green: 0.7, blue: 0.0) : Theme.gold
    }

    var healthRedColor: Color {
        isHighContrast ? Color(red: 0.9, green: 0.0, blue: 0.0) : Theme.red
    }

    var safetyLineColor: Color {
        isHighContrast ? Color(red: 0.8, green: 0.0, blue: 0.3) : Theme.red
    }

    var scheduleBarColor: Color {
        isHighContrast ? Color(red: 0.0, green: 0.5, blue: 0.9) : Theme.cyan
    }
}

// MARK: - D-26d: Chart Pattern Fills for Colorblind Users

/// Provides pattern-based chart styling for colorblind accessibility.
/// In high contrast mode, charts use patterns (hatching, dots) in addition to color
/// to distinguish categories.

/// Hatching pattern shape for "budget spent" category.
struct HatchPattern: Shape {
    let spacing: CGFloat
    let angle: Double

    init(spacing: CGFloat = 6, angle: Double = 45) {
        self.spacing = spacing
        self.angle = angle
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let diagonal = sqrt(rect.width * rect.width + rect.height * rect.height)
        let count = Int(diagonal / spacing)

        for i in 0...count {
            let offset = CGFloat(i) * spacing - diagonal / 2
            path.move(to: CGPoint(x: rect.midX + offset, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX + offset + rect.height, y: rect.maxY))
        }
        return path
    }
}

/// Dot pattern shape for "budget remaining" category.
struct DotPattern: Shape {
    let dotRadius: CGFloat
    let spacing: CGFloat

    init(dotRadius: CGFloat = 2, spacing: CGFloat = 8) {
        self.dotRadius = dotRadius
        self.spacing = spacing
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y = rect.minY + spacing / 2
        while y < rect.maxY {
            var x = rect.minX + spacing / 2
            while x < rect.maxX {
                path.addEllipse(in: CGRect(
                    x: x - dotRadius,
                    y: y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                ))
                x += spacing
            }
            y += spacing
        }
        return path
    }
}

/// Returns a pattern-aware color for a chart category.
/// In high contrast mode, returns a view with pattern overlay for colorblind distinction.
/// - Parameter category: The chart data category (e.g., "spent", "remaining", "on_track")
/// - Returns: A Color appropriate for the current accessibility context.
func chartPatternColor(for category: String, isHighContrast: Bool) -> Color {
    let helper = ReportHighContrastHelper(isHighContrast: isHighContrast)
    switch category.lowercased() {
    case "spent", "billed", "budget_spent":
        return helper.budgetSpentColor
    case "remaining", "budget_remaining":
        return helper.budgetRemainingColor
    case "on_track", "green", "healthy":
        return helper.healthGreenColor
    case "at_risk", "gold", "warning":
        return helper.healthGoldColor
    case "critical", "red", "delayed":
        return helper.healthRedColor
    case "safety", "incidents":
        return helper.safetyLineColor
    case "schedule", "milestones":
        return helper.scheduleBarColor
    default:
        return isHighContrast ? .primary : Theme.muted
    }
}

/// View modifier that overlays a pattern on a chart segment for high contrast mode.
struct ChartPatternOverlay: ViewModifier {
    let category: String
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    func body(content: Content) -> some View {
        if differentiateWithoutColor {
            content.overlay {
                patternForCategory(category)
                    .opacity(0.3)
            }
        } else {
            content
        }
    }

    @ViewBuilder
    private func patternForCategory(_ category: String) -> some View {
        switch category.lowercased() {
        case "spent", "billed", "budget_spent":
            HatchPattern(spacing: 6, angle: 45)
                .stroke(Color.primary, lineWidth: 1)
        case "remaining", "budget_remaining":
            DotPattern(dotRadius: 2, spacing: 8)
                .fill(Color.primary)
        case "on_track", "green", "healthy":
            HatchPattern(spacing: 8, angle: 0)
                .stroke(Color.primary, lineWidth: 1)
        case "at_risk", "gold", "warning":
            HatchPattern(spacing: 4, angle: 90)
                .stroke(Color.primary, lineWidth: 1)
        case "critical", "red", "delayed":
            DotPattern(dotRadius: 3, spacing: 6)
                .fill(Color.primary)
        default:
            EmptyView()
        }
    }
}

extension View {
    /// D-26d: Apply pattern overlay for colorblind-accessible chart rendering.
    func chartPattern(for category: String) -> some View {
        self.modifier(ChartPatternOverlay(category: category))
    }
}

// MARK: - D-88: Keyboard Navigation Helpers

/// View modifier for keyboard-navigable chart data points.
/// Adds focus management so keyboard users can tab through data points.
struct ChartDataPointFocusModifier: ViewModifier {
    let dataPointLabel: String
    let dataPointValue: String
    let index: Int
    let total: Int

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(dataPointAccessibilityLabel))
            .accessibilityValue(Text(dataPointValue))
            .accessibilityHint(Text(navigationHint))
            .accessibilityAddTraits(.isButton)
            .accessibilityRespondsToUserInteraction(true)
    }

    private var dataPointAccessibilityLabel: LocalizedStringKey {
        LocalizedStringKey("Data point \(index + 1) of \(total): \(dataPointLabel)")
    }

    private var navigationHint: LocalizedStringKey {
        if index < total - 1 {
            return LocalizedStringKey("Swipe right for next data point")
        } else {
            return LocalizedStringKey("Last data point. Swipe left to go back")
        }
    }
}

extension View {
    /// D-88: Make a chart data point keyboard/VoiceOver navigable.
    func chartDataPointFocus(label: String, value: String, index: Int, total: Int) -> some View {
        self.modifier(ChartDataPointFocusModifier(
            dataPointLabel: label,
            dataPointValue: value,
            index: index,
            total: total
        ))
    }
}

// MARK: - D-89: Tagged PDF Accessibility Helpers

/// Helpers for generating accessible PDF content from report views.
/// Tagged PDFs (PDF/UA compliance) require alt text on images and proper structure.
struct ReportPDFAccessibility {
    /// Generate alt text for a chart image embedded in a PDF.
    /// - Parameters:
    ///   - chartType: The type of chart (e.g., "pie", "bar", "line")
    ///   - title: The chart title
    ///   - dataDescription: A human-readable summary of the data shown
    /// - Returns: Alt text string suitable for PDF image tagging.
    static func chartAltText(chartType: String, title: String, dataDescription: String) -> String {
        "\(title) (\(chartType) chart): \(dataDescription)"
    }

    /// Generate alt text for a budget pie chart.
    static func budgetPieAltText(spent: Double, remaining: Double) -> String {
        let total = spent + remaining
        let pct = total > 0 ? Int((spent / total) * 100) : 0
        return chartAltText(
            chartType: "pie",
            title: "Budget Overview",
            dataDescription: "\(pct)% spent (\(formatAccessibleCurrency(spent))) of \(formatAccessibleCurrency(total)) total, \(formatAccessibleCurrency(remaining)) remaining"
        )
    }

    /// Generate alt text for a schedule bar chart.
    static func scheduleBarAltText(milestones: [(name: String, percent: Int)]) -> String {
        let desc = milestones.map { "\($0.name): \($0.percent)% complete" }.joined(separator: "; ")
        return chartAltText(
            chartType: "bar",
            title: "Schedule Progress",
            dataDescription: "\(milestones.count) milestones shown. \(desc)"
        )
    }

    /// Generate alt text for a safety line chart.
    static func safetyLineAltText(monthlyData: [(month: String, count: Int)]) -> String {
        let total = monthlyData.map(\.count).reduce(0, +)
        let desc = monthlyData.map { "\($0.month): \($0.count)" }.joined(separator: ", ")
        return chartAltText(
            chartType: "line",
            title: "Safety Incidents Over Time",
            dataDescription: "\(total) total incidents across \(monthlyData.count) months. Monthly: \(desc)"
        )
    }

    /// Format currency for screen reader pronunciation.
    private static func formatAccessibleCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

// MARK: - D-86: String Catalogs / i18n Support

/// Localized string keys for all report-related user-visible text.
/// These use LocalizedStringKey so Xcode automatically extracts them
/// into String Catalogs (Localizable.xcstrings) for translation.
///
/// Usage in views:
///   Text(ReportStrings.portfolioHealth)
///   Text(ReportStrings.budgetOverview)
///
/// Note: Xcode auto-generates Localizable.xcstrings when String Catalogs
/// are enabled. Add String Catalog file via:
///   File > New > File > String Catalog (Localizable.xcstrings)
struct ReportStrings {
    // MARK: Section Titles
    static let portfolioHealth: LocalizedStringKey = "Portfolio Health"
    static let projectReport: LocalizedStringKey = "Project Report"
    static let portfolioRollup: LocalizedStringKey = "Portfolio Rollup"
    static let budgetOverview: LocalizedStringKey = "Budget Overview"
    static let scheduleProgress: LocalizedStringKey = "Schedule Progress"
    static let safetyIncidents: LocalizedStringKey = "Safety Incidents"
    static let teamActivity: LocalizedStringKey = "Team & Activity"
    static let aiInsights: LocalizedStringKey = "AI Insights"

    // MARK: Status Labels
    static let onTrack: LocalizedStringKey = "On Track"
    static let atRisk: LocalizedStringKey = "At Risk"
    static let critical: LocalizedStringKey = "Critical"
    static let delayed: LocalizedStringKey = "Delayed"
    static let completed: LocalizedStringKey = "Completed"

    // MARK: KPI Labels
    static let contractValue: LocalizedStringKey = "Contract Value"
    static let totalBilled: LocalizedStringKey = "Total Billed"
    static let percentComplete: LocalizedStringKey = "% Complete"
    static let changeOrders: LocalizedStringKey = "Change Orders"
    static let retainage: LocalizedStringKey = "Retainage"
    static let healthScore: LocalizedStringKey = "Health Score"
    static let activeProjects: LocalizedStringKey = "Active Projects"
    static let totalTeamMembers: LocalizedStringKey = "Team Members"

    // MARK: Actions
    static let exportPDF: LocalizedStringKey = "Export PDF"
    static let exportCSV: LocalizedStringKey = "Export CSV"
    static let shareReport: LocalizedStringKey = "Share Report"
    static let refreshData: LocalizedStringKey = "Refresh Data"
    static let filterProjects: LocalizedStringKey = "Filter Projects"

    // MARK: Accessibility Labels
    static let chartBudgetPie: LocalizedStringKey = "Budget pie chart showing spent versus remaining"
    static let chartScheduleBar: LocalizedStringKey = "Schedule bar chart showing milestone progress"
    static let chartSafetyLine: LocalizedStringKey = "Safety line chart showing incidents over time"
    static let chartActivityTrend: LocalizedStringKey = "Activity trend chart showing project activity"

    // MARK: Empty States
    static let noData: LocalizedStringKey = "No data available"
    static let noProjects: LocalizedStringKey = "No projects found"
    static let noReports: LocalizedStringKey = "No reports generated yet"
    static let demoDataNotice: LocalizedStringKey = "Showing demo data. Connect to Supabase for live data."

    // MARK: Time / Date
    static let generatedAt: LocalizedStringKey = "Generated at"
    static let lastUpdated: LocalizedStringKey = "Last Updated"
    static let reportDate: LocalizedStringKey = "Report Date"
}

// MARK: - High Contrast Environment Reader

/// View modifier that reads the high contrast environment setting and provides
/// a ReportHighContrastHelper to child views.
struct HighContrastReportModifier: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.colorSchemeContrast) private var contrast

    var isHighContrast: Bool {
        differentiateWithoutColor || contrast == .increased
    }

    func body(content: Content) -> some View {
        content
            .environment(\.reportHighContrast, isHighContrast)
    }
}

/// Custom environment key for passing high contrast state through the view hierarchy.
private struct ReportHighContrastKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var reportHighContrast: Bool {
        get { self[ReportHighContrastKey.self] }
        set { self[ReportHighContrastKey.self] = newValue }
    }
}

extension View {
    /// Apply high contrast detection to the report view hierarchy.
    func reportHighContrastAware() -> some View {
        self.modifier(HighContrastReportModifier())
    }
}
