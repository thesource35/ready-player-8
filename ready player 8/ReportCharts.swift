import SwiftUI
import Charts

// MARK: - ========== ReportCharts.swift ==========
// Phase 19: SwiftUI Charts components for reports.
// Stub implementations -- Task 2 will add full chart rendering.

// MARK: - Budget Pie Chart (D-18)

struct BudgetPieChartView: View {
    let spent: Double
    let remaining: Double

    var body: some View {
        // Placeholder -- full SectorMark chart in Task 2
        Text("Budget chart loading...")
            .font(.system(size: 12))
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.panel)
            .cornerRadius(14)
    }
}

// MARK: - Schedule Bar Chart (D-18)

struct ScheduleBarChartView: View {
    let milestones: [(name: String, percent: Double)]

    var body: some View {
        // Placeholder -- full BarMark chart in Task 2
        Text("Schedule chart loading...")
            .font(.system(size: 12))
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.panel)
            .cornerRadius(14)
    }
}

// MARK: - Safety Line Chart (D-18)

struct SafetyLineChartView: View {
    let monthlyData: [(month: String, count: Int)]

    var body: some View {
        // Placeholder -- full LineMark + PointMark chart in Task 2
        Text("Safety chart loading...")
            .font(.system(size: 12))
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.panel)
            .cornerRadius(14)
    }
}

// MARK: - Activity Trend Chart (D-19b)

struct ActivityTrendChartView: View {
    let data: [(month: String, count: Int)]

    var body: some View {
        // Placeholder -- full AreaMark + LineMark chart in Task 2
        Text("Activity chart loading...")
            .font(.system(size: 12))
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.panel)
            .cornerRadius(14)
    }
}
