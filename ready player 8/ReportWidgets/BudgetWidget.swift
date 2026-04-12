import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - ========== BudgetWidget.swift ==========
// Phase 19: WidgetKit Home Screen widget showing budget status KPIs.
// D-67: Budget status widget with contract value, billed %, change orders.
// NOTE: Requires Widget Extension target (see HealthScoreWidget.swift TODO).

// MARK: - Budget Widget Data

struct BudgetWidgetData: Identifiable {
    let id = UUID()
    let totalContractValue: Double
    let totalBilled: Double
    let percentBilled: Double
    let changeOrderImpact: Double
    let remaining: Double
}

#if canImport(WidgetKit)

// MARK: - Timeline Provider (D-67)

struct BudgetTimelineProvider: TimelineProvider {
    typealias Entry = BudgetTimelineEntry

    func placeholder(in context: Context) -> BudgetTimelineEntry {
        BudgetTimelineEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetTimelineEntry) -> Void) {
        completion(loadCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetTimelineEntry>) -> Void) {
        let entry = loadCurrentEntry()
        // Refresh every 30 minutes (D-67)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCurrentEntry() -> BudgetTimelineEntry {
        let projects: [SupabaseProject] = loadJSON("ConstructOS.Projects.DataRaw", default: [])
        guard !projects.isEmpty else {
            return BudgetTimelineEntry.placeholder
        }

        let budgets = projects.compactMap { parseBudgetValue($0.budget) }
        let totalContract = budgets.reduce(0, +)
        // Estimate billed from progress
        let avgProgress = Double(projects.map(\.progress).reduce(0, +)) / max(Double(projects.count), 1)
        let totalBilled = totalContract * (avgProgress / 100.0)
        let percentBilled = totalContract > 0 ? (totalBilled / totalContract) * 100 : 0

        return BudgetTimelineEntry(
            date: Date(),
            totalContractValue: totalContract,
            totalBilled: totalBilled,
            percentBilled: percentBilled,
            changeOrderImpact: 0, // Would come from real data
            remaining: totalContract - totalBilled
        )
    }

    private func parseBudgetValue(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned)
    }
}

// MARK: - Timeline Entry

struct BudgetTimelineEntry: TimelineEntry {
    let date: Date
    let totalContractValue: Double
    let totalBilled: Double
    let percentBilled: Double
    let changeOrderImpact: Double
    let remaining: Double

    static let placeholder = BudgetTimelineEntry(
        date: Date(),
        totalContractValue: 2_480_000,
        totalBilled: 1_612_000,
        percentBilled: 65,
        changeOrderImpact: 45_000,
        remaining: 868_000
    )
}

// MARK: - Widget Views (D-67)

/// Small: total contract value + % billed
struct BudgetSmallView: View {
    let entry: BudgetTimelineEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("BUDGET")
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundColor(.secondary)

            Text(formatCurrency(entry.totalContractValue))
                .font(.system(size: 20, weight: .heavy))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: min(entry.percentBilled / 100, 1.0))
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(entry.percentBilled))%")
                    .font(.system(size: 14, weight: .bold))
            }
            .frame(width: 44, height: 44)

            Text("billed")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Budget: \(formatCurrency(entry.totalContractValue)) total, \(Int(entry.percentBilled)) percent billed")
    }
}

/// Medium: contract value + billed + remaining + change order impact
struct BudgetMediumView: View {
    let entry: BudgetTimelineEntry

    var body: some View {
        HStack(spacing: 12) {
            // Left: progress ring
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: min(entry.percentBilled / 100, 1.0))
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(entry.percentBilled))%")
                            .font(.system(size: 16, weight: .heavy))
                        Text("billed")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 56, height: 56)
            }

            Divider()

            // Right: KPI grid
            VStack(alignment: .leading, spacing: 6) {
                budgetKPI(label: "Contract", value: formatCurrency(entry.totalContractValue), color: .primary)
                budgetKPI(label: "Billed", value: formatCurrency(entry.totalBilled), color: Theme.green)
                budgetKPI(label: "Remaining", value: formatCurrency(entry.remaining), color: Theme.cyan)
                if entry.changeOrderImpact != 0 {
                    budgetKPI(label: "Change Orders", value: formatCurrency(entry.changeOrderImpact), color: Theme.gold)
                }
            }
        }
        .padding(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Budget overview: \(formatCurrency(entry.totalContractValue)) contract, \(formatCurrency(entry.totalBilled)) billed, \(formatCurrency(entry.remaining)) remaining")
    }

    private func budgetKPI(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Widget Configuration (D-67)

struct BudgetWidget: Widget {
    let kind: String = "com.constructionos.budget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetTimelineProvider()) { entry in
            BudgetWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget Status")
        .description("Track your portfolio budget at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BudgetWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BudgetTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall:
            BudgetSmallView(entry: entry)
        case .systemMedium:
            BudgetMediumView(entry: entry)
        default:
            BudgetSmallView(entry: entry)
        }
    }
}

#endif

// MARK: - Helpers

/// Format a Double as a compact currency string (e.g., "$1.2M", "$340K").
func formatCurrency(_ value: Double) -> String {
    if value >= 1_000_000 {
        return String(format: "$%.1fM", value / 1_000_000)
    } else if value >= 1_000 {
        return String(format: "$%.0fK", value / 1_000)
    } else {
        return String(format: "$%.0f", value)
    }
}
