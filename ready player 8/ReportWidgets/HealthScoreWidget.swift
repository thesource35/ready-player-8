import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - ========== HealthScoreWidget.swift ==========
// Phase 19: WidgetKit Home Screen widget showing portfolio health.
// D-67: WidgetKit widgets in small/medium/large sizes.
// NOTE: This file compiles in the main app target for shared types.
// TODO: Create a separate Widget Extension target in Xcode to actually display
//       these widgets on the Home Screen. The extension target needs:
//       1. File > New > Target > Widget Extension
//       2. Add this file and BudgetWidget.swift to the widget extension target
//       3. Share SupabaseProject model via a shared framework or App Group
//       4. Use App Group UserDefaults for data sharing between app and widget

// MARK: - Widget Data Models

/// Snapshot data for the health score widget timeline entry.
struct HealthScoreEntry: Identifiable {
    let id = UUID()
    let date: Date
    let healthScore: Int
    let healthLabel: String    // "On Track", "At Risk", "Critical"
    let healthColor: HealthColor
    let topProjects: [WidgetProjectSummary]
    let totalBudget: Double
    let totalBilled: Double

    enum HealthColor {
        case green, gold, red

        var color: Color {
            switch self {
            case .green: return Theme.green
            case .gold: return Theme.gold
            case .red: return Theme.red
            }
        }
    }
}

/// Minimal project info for widget display.
struct WidgetProjectSummary: Identifiable {
    let id: String
    let name: String
    let score: Int
    let healthColor: HealthScoreEntry.HealthColor
}

// MARK: - Timeline Provider (D-67)

#if canImport(WidgetKit)

struct HealthScoreTimelineProvider: TimelineProvider {
    typealias Entry = HealthScoreTimelineEntry

    func placeholder(in context: Context) -> HealthScoreTimelineEntry {
        HealthScoreTimelineEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (HealthScoreTimelineEntry) -> Void) {
        completion(loadCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthScoreTimelineEntry>) -> Void) {
        let entry = loadCurrentEntry()
        // Refresh every 30 minutes (D-67)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCurrentEntry() -> HealthScoreTimelineEntry {
        // Read cached project data from UserDefaults (App Group in widget extension)
        let projects: [SupabaseProject] = loadJSON("ConstructOS.Projects.DataRaw", default: [])
        guard !projects.isEmpty else {
            return HealthScoreTimelineEntry.placeholder
        }

        let scores = projects.compactMap { Int($0.score) }
        let avgScore = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count

        let topProjects = projects.prefix(3).map { proj in
            let s = Int(proj.score) ?? 0
            return WidgetProjectSummary(
                id: proj.id ?? UUID().uuidString,
                name: proj.name,
                score: s,
                healthColor: s >= 70 ? .green : (s >= 40 ? .gold : .red)
            )
        }

        let totalBudget = projects.compactMap { parseBudgetValue($0.budget) }.reduce(0, +)
        let billedRatio = Double(projects.compactMap { Int($0.score) }.filter { $0 > 0 }.count) / max(Double(projects.count), 1)

        return HealthScoreTimelineEntry(
            date: Date(),
            healthScore: avgScore,
            healthLabel: avgScore >= 70 ? "On Track" : (avgScore >= 40 ? "At Risk" : "Critical"),
            healthColor: avgScore >= 70 ? .green : (avgScore >= 40 ? .gold : .red),
            topProjects: Array(topProjects),
            totalBudget: totalBudget,
            billedPercent: billedRatio
        )
    }

    /// Parse budget string like "$1,250,000" to Double
    private func parseBudgetValue(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned)
    }
}

// MARK: - Timeline Entry

struct HealthScoreTimelineEntry: TimelineEntry {
    let date: Date
    let healthScore: Int
    let healthLabel: String
    let healthColor: HealthScoreEntry.HealthColor
    let topProjects: [WidgetProjectSummary]
    let totalBudget: Double
    let billedPercent: Double

    static let placeholder = HealthScoreTimelineEntry(
        date: Date(),
        healthScore: 78,
        healthLabel: "On Track",
        healthColor: .green,
        topProjects: [
            WidgetProjectSummary(id: "p1", name: "Tower Project", score: 85, healthColor: .green),
            WidgetProjectSummary(id: "p2", name: "Bridge Reno", score: 62, healthColor: .gold),
            WidgetProjectSummary(id: "p3", name: "Office Fit-Out", score: 41, healthColor: .red)
        ],
        totalBudget: 2_480_000,
        billedPercent: 0.65
    )
}

// MARK: - Widget Views (D-67: small, medium, large)

/// Small widget: large health score number + color indicator + label
struct HealthScoreSmallView: View {
    let entry: HealthScoreTimelineEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("PORTFOLIO")
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundColor(.secondary)

            Text("\(entry.healthScore)")
                .font(.system(size: 48, weight: .heavy))
                .foregroundColor(entry.healthColor.color)

            Text(entry.healthLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(entry.healthColor.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(entry.healthColor.color.opacity(0.15))
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Portfolio health score: \(entry.healthScore), \(entry.healthLabel)")
    }
}

/// Medium widget: health score + top 3 projects with health badges
struct HealthScoreMediumView: View {
    let entry: HealthScoreTimelineEntry

    var body: some View {
        HStack(spacing: 12) {
            // Left: score
            VStack(spacing: 4) {
                Text("\(entry.healthScore)")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(entry.healthColor.color)
                Text(entry.healthLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(entry.healthColor.color)
            }
            .frame(width: 80)

            Divider()

            // Right: top projects
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.topProjects) { project in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(project.healthColor.color)
                            .frame(width: 8, height: 8)
                        Text(project.name)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                        Spacer()
                        Text("\(project.score)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(project.healthColor.color)
                    }
                }
            }
        }
        .padding(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Portfolio health: \(entry.healthScore). Top projects: \(entry.topProjects.map { "\($0.name) at \($0.score)" }.joined(separator: ", "))")
    }
}

/// Large widget: health score + project list + budget bar
struct HealthScoreLargeView: View {
    let entry: HealthScoreTimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PORTFOLIO HEALTH")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.secondary)
                    Text(entry.healthLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(entry.healthColor.color)
                }
                Spacer()
                Text("\(entry.healthScore)")
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundColor(entry.healthColor.color)
            }

            Divider()

            // Project list
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.topProjects) { project in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(project.healthColor.color)
                            .frame(width: 8, height: 8)
                        Text(project.name)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Spacer()
                        Text("\(project.score)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(project.healthColor.color)
                    }
                }
            }

            Spacer()

            // Budget bar
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget Progress")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * min(entry.billedPercent, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
                Text("\(Int(entry.billedPercent * 100))% billed")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Portfolio health: \(entry.healthScore), \(entry.healthLabel). Budget \(Int(entry.billedPercent * 100)) percent billed. \(entry.topProjects.count) projects shown.")
    }
}

// MARK: - Widget Configuration (D-67)

/// HealthScoreWidget provides .systemSmall, .systemMedium, .systemLarge families.
struct HealthScoreWidget: Widget {
    let kind: String = "com.constructionos.healthscore"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthScoreTimelineProvider()) { entry in
            HealthScoreWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Portfolio Health")
        .description("See your portfolio health score at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Routes to the correct size view based on widget family.
struct HealthScoreWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HealthScoreTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall:
            HealthScoreSmallView(entry: entry)
        case .systemMedium:
            HealthScoreMediumView(entry: entry)
        case .systemLarge:
            HealthScoreLargeView(entry: entry)
        default:
            HealthScoreSmallView(entry: entry)
        }
    }
}

#endif

// MARK: - D-72: watchOS Complication Placeholder
// TODO: watchOS complications require a separate watchOS app target.
// Approach: Use WidgetKit complications (ClockKit deprecated).
// - Create watchOS App target with WidgetKit extension
// - Implement AccessoryCircular: health score number in circular gauge
// - Implement AccessoryRectangular: health score + label + top project name
// - Implement AccessoryInline: "Health: 78 - On Track"
// - Share data via Watch Connectivity framework or App Group
// - Refresh via TimelineProvider with 15-minute intervals

// MARK: - D-73: Dynamic Island / Live Activity Placeholder
// TODO: Dynamic Island and Live Activities require ActivityKit.
// Approach for batch PDF export progress:
// - Define ActivityAttributes for ReportExportActivity
// - ContentState: exportProgress (Double 0-1), currentFile (String), totalFiles (Int)
// - Compact leading: document icon, compact trailing: progress %
// - Expanded: progress bar + file name + estimated time remaining
// - Lock screen: full progress bar with file list
// - Start activity when batch export begins, update progress, end on completion
// - Requires: import ActivityKit, iOS 16.1+
