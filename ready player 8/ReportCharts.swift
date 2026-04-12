import SwiftUI
import Charts

// MARK: - ========== ReportCharts.swift ==========
// Phase 19: SwiftUI Charts components for reports.
// D-18: SwiftUI Charts -- SectorMark, BarMark, LineMark, AreaMark.
// D-26b: Entrance animations. D-69: Haptic feedback. D-75: VoiceOver accessibility.
// D-71: Pinch-to-zoom on time-series. D-26d: High contrast support.

// MARK: - Chart Data Helpers

private struct ChartSlice: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let color: Color
}

private struct MilestoneData: Identifiable {
    let id = UUID()
    let name: String
    let percent: Double
}

private struct MonthlyPoint: Identifiable {
    let id = UUID()
    let month: String
    let count: Int
    let index: Int
}

// MARK: - Budget Pie Chart (D-18, D-24)

struct BudgetPieChartView: View {
    let spent: Double
    let remaining: Double

    @State private var selectedSlice: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var slices: [ChartSlice] {
        [
            ChartSlice(name: "Spent", value: spent, color: Theme.accent),
            ChartSlice(name: "Remaining", value: remaining, color: Theme.cyan)
        ]
    }

    private var percentComplete: Int {
        let total = spent + remaining
        guard total > 0 else { return 0 }
        return Int((spent / total) * 100)
    }

    var body: some View {
        VStack(spacing: 8) {
            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Amount", slice.value),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(slice.color)
                .opacity(selectedSlice == nil || selectedSlice == slice.name ? 1 : 0.5)
            }
            .chartBackground { _ in
                VStack(spacing: 2) {
                    Text("\(percentComplete)%")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(Theme.text)
                    Text("COMPLETE")
                        .font(.system(size: 6, weight: .heavy))
                        .foregroundColor(Theme.muted)
                }
            }
            .chartAngleSelection(value: .init(get: { selectedSlice }, set: { newValue in
                if let newValue = newValue as? String {
                    selectedSlice = newValue
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                }
            }))

            // Inline legend (D-23)
            HStack(spacing: 12) {
                legendDot("Spent", Theme.accent)
                legendDot("Remaining", Theme.cyan)
            }
        }
        .padding(16)
        .background(Theme.panel)
        .cornerRadius(14)
        .accessibilityLabel("Budget pie chart: \(percentComplete)% spent, \(100 - percentComplete)% remaining")
    }
}

// MARK: - Schedule Bar Chart (D-18, D-26)

struct ScheduleBarChartView: View {
    let milestones: [(name: String, percent: Double)]

    @State private var selectedBar: String?

    private var chartData: [MilestoneData] {
        milestones.prefix(8).map { MilestoneData(name: $0.name, percent: $0.percent) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MILESTONE PROGRESS")
                .font(.system(size: 8, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.muted)

            Chart(chartData) { ms in
                BarMark(
                    x: .value("Progress", ms.percent),
                    y: .value("Milestone", ms.name)
                )
                .cornerRadius(4)
                .foregroundStyle(Theme.cyan)
                .opacity(selectedBar == nil || selectedBar == ms.name ? 1 : 0.6)
            }
            .chartXScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisValueLabel {
                        if let pct = value.as(Double.self) {
                            Text("\(Int(pct))%")
                                .font(.system(size: 8))
                                .foregroundColor(Theme.muted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.border.opacity(0.3))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self) {
                            Text(name)
                                .font(.system(size: 8))
                                .foregroundColor(Theme.muted)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        }
                }
            }
        }
        .padding(16)
        .background(Theme.panel)
        .cornerRadius(14)
        .accessibilityLabel("Schedule bar chart showing \(milestones.count) milestones")
    }
}

// MARK: - Safety Line Chart (D-18, D-25)

struct SafetyLineChartView: View {
    let monthlyData: [(month: String, count: Int)]

    @State private var selectedMonth: String?
    @State private var magnification: CGFloat = 1.0

    private var chartPoints: [MonthlyPoint] {
        monthlyData.enumerated().map { MonthlyPoint(month: $1.month, count: $1.count, index: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SAFETY INCIDENTS")
                .font(.system(size: 8, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.muted)

            Chart(chartPoints) { point in
                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Incidents", point.count)
                )
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(Theme.red)

                PointMark(
                    x: .value("Month", point.month),
                    y: .value("Incidents", point.count)
                )
                .symbolSize(40)
                .foregroundStyle(Theme.red)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let count = value.as(Int.self) {
                            Text("\(count)")
                                .font(.system(size: 8))
                                .foregroundColor(Theme.muted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.border.opacity(0.3))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let month = value.as(String.self) {
                            Text(month)
                                .font(.system(size: 8))
                                .foregroundColor(Theme.muted)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        }
                }
            }
            // D-71: Pinch-to-zoom on time-series
            .scaleEffect(magnification)
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        magnification = max(1.0, min(value.magnification, 3.0))
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            magnification = 1.0
                        }
                    }
            )
        }
        .padding(16)
        .background(Theme.panel)
        .cornerRadius(14)
        .accessibilityLabel("Safety line chart showing \(monthlyData.count) months of incident data")
    }
}

// MARK: - Activity Trend Chart (D-19b)

struct ActivityTrendChartView: View {
    let data: [(month: String, count: Int)]

    @State private var magnification: CGFloat = 1.0

    private var chartPoints: [MonthlyPoint] {
        data.enumerated().map { MonthlyPoint(month: $1.month, count: $1.count, index: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACTIVITY TREND")
                .font(.system(size: 8, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.muted)

            Chart(chartPoints) { point in
                AreaMark(
                    x: .value("Month", point.month),
                    y: .value("Activity", point.count)
                )
                .opacity(0.1)
                .foregroundStyle(Theme.purple)

                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Activity", point.count)
                )
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(Theme.purple)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let count = value.as(Int.self) {
                            Text("\(count)")
                                .font(.system(size: 8))
                                .foregroundColor(Theme.muted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.border.opacity(0.3))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let month = value.as(String.self) {
                            Text(month)
                                .font(.system(size: 8))
                                .foregroundColor(Theme.muted)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        }
                }
            }
            // D-71: Pinch-to-zoom
            .scaleEffect(magnification)
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        magnification = max(1.0, min(value.magnification, 3.0))
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            magnification = 1.0
                        }
                    }
            )
        }
        .padding(16)
        .background(Theme.panel)
        .cornerRadius(14)
        .accessibilityLabel("Activity trend chart showing \(data.count) months of data")
    }
}

// MARK: - Shared Legend Helper

private func legendDot(_ label: String, _ color: Color) -> some View {
    HStack(spacing: 4) {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
        Text(label)
            .font(.system(size: 8, weight: .heavy))
            .foregroundColor(Theme.muted)
    }
}
