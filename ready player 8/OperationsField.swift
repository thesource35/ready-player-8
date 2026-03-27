import Foundation
import SwiftUI

// MARK: - ========== OperationsField.swift ==========

// MARK: - Site Risk Score

struct SiteRiskScorePanel: View {
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let scores: [(site: String, score: Int, drivers: [String])] = [
        ("Riverside Lofts",    95, ["Status: DELAYED", "Crew HOLD", "Inspection DUE TODAY", "Weather: Rain"]),
        ("Site Gamma",         65, ["Status: AT RISK",  "Crew DELAYED", "Wind Advisory"]),
        ("Pine Ridge Ph.2",    55, ["Status: AT RISK",  "Inspection 1d OVERDUE", "Permit FLAGGED"]),
        ("Harbor Crossing",    10, ["Status: ON TRACK", "MEP Active"]),
        ("Eastside Civic Hub", 15, ["Status: ON TRACK", "Permit PENDING"]),
    ]

    private var portfolioScore: Int {
        scores.isEmpty ? 0 : scores.map(\.score).reduce(0, +) / scores.count
    }

    private func riskColor(_ score: Int) -> Color {
        if score >= 70 { return Theme.red }
        if score >= 40 { return Theme.gold }
        return Theme.green
    }

    private var roleNote: String {
        let hot = scores.first(where: { $0.score >= 70 })?.site ?? "none"
        switch role {
        case .superintendent: return "Highest risk site today: \(hot)"
        case .projectManager: return "Schedule impact likely at: \(hot)"
        case .executive:      return "Portfolio avg risk: \(portfolioScore)/100"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("SITE RISK SCORES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(riskColor(portfolioScore))
                Text("AVG \(portfolioScore)")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(riskColor(portfolioScore).opacity(0.9)))
                Spacer()
                Text(roleNote)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
            }
            VStack(spacing: 6) {
                ForEach(scores, id: \.site) { item in
                    RiskScoreRow(site: item.site, score: item.score, drivers: item.drivers, riskColor: riskColor(item.score))
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: riskColor(portfolioScore))
    }
}

struct RiskScoreRow: View {
    let site: String
    let score: Int
    let drivers: [String]
    let riskColor: Color
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(site)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                Spacer()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.surface)
                            .frame(height: 7)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(riskColor.opacity(0.85))
                            .frame(width: geo.size.width * CGFloat(score) / 100, height: 7)
                    }
                }
                .frame(width: 90, height: 7)
                Text("\(score)")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(riskColor)
                    .frame(width: 26, alignment: .trailing)
                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() } }) {
                    Text(expanded ? "▲" : "▼")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.muted)
                }
                .buttonStyle(.plain)
            }
            if expanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(drivers, id: \.self) { d in
                        Text("· \(d)")
                            .font(.system(size: 8, weight: .regular))
                            .foregroundColor(Theme.muted)
                    }
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(riskColor.opacity(score >= 70 ? 0.07 : 0.03))
        .cornerRadius(7)
    }
}

// MARK: - Daily Standup Report

struct StandupReportPanel: View {
    @EnvironmentObject private var actionLog: RiskActionLogStore
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"
    @State private var reportText: String = ""
    @State private var copyStatus: String?
    @State private var generated = false

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private func generateReport() {
        let df = DateFormatter()
        df.dateFormat = "MM-dd"
        let today = df.string(from: Date())
        let full = DateFormatter()
        full.dateFormat = "EEEE, MMM d yyyy"
        let dateLabel = full.string(from: Date())

        let todayEntries  = actionLog.entries.filter { $0.hasPrefix("[\(today)") }
        let assigns       = todayEntries.filter { $0.lowercased().contains("assign")   }
        let notes         = todayEntries.filter { $0.lowercased().contains("note")     }
        let escalations   = actionLog.entries.filter { $0.lowercased().contains("escalate") }
        let safetyEntries = todayEntries.filter { $0.lowercased().contains("[safety]") }
        let schedEntries  = todayEntries.filter { $0.lowercased().contains("[schedule]") }

        var lines: [String] = []
        lines.append("DAILY STANDUP — \(role.display)")
        lines.append(dateLabel)
        lines.append(String(repeating: "-", count: 40))
        lines.append("")

        switch role {
        case .superintendent:
            lines.append("FIELD STATUS")
            lines.append("  Sites running: Harbor Crossing, Pine Ridge Ph.2, Eastside Civic Hub")
            lines.append("  On hold: Riverside Lofts (rain), Site Gamma (steel delay)")
            lines.append("")
            lines.append("SAFETY (\(safetyEntries.count) today)")
            safetyEntries.prefix(3).forEach { lines.append("  " + String($0.prefix(60))) }
            if safetyEntries.isEmpty { lines.append("  No safety entries today") }
            lines.append("")
            lines.append("SCHEDULE FLAGS (\(schedEntries.count) today)")
            schedEntries.prefix(3).forEach { lines.append("  " + String($0.prefix(60))) }
            if schedEntries.isEmpty { lines.append("  No schedule flags today") }
            lines.append("")
            lines.append("CREW: 61 workers — 22 active, 22 on hold due to weather")
            lines.append("WEATHER: Heavy rain today — concrete + steel ops suspended")

        case .projectManager:
            lines.append("SCHEDULE IMPACT")
            lines.append("  Riverside Lofts: DELAYED — rain delay, update baseline")
            lines.append("  Site Gamma: AT RISK — steel delivery pushed")
            lines.append("  Pine Ridge Ph.2: AT RISK — framing inspection 1d overdue")
            lines.append("")
            lines.append("ASSIGNS TODAY (\(assigns.count))")
            assigns.prefix(3).forEach { lines.append("  " + String($0.prefix(60))) }
            if assigns.isEmpty { lines.append("  No assignments today") }
            lines.append("")
            lines.append("ESCALATIONS (\(escalations.count) total)")
            escalations.prefix(3).forEach { lines.append("  " + String($0.prefix(60))) }
            if escalations.isEmpty { lines.append("  None" ) }
            lines.append("")
            lines.append("PERMITS: Foundation inspection DUE TODAY (Riverside) — PENDING")

        case .executive:
            lines.append("PORTFOLIO RISK SUMMARY")
            lines.append("  Avg risk score: 48/100")
            lines.append("  Critical sites: Riverside Lofts (95), Site Gamma (65), Pine Ridge (55)")
            lines.append("")
            lines.append("ESCALATIONS (\(escalations.count) open)")
            escalations.prefix(5).forEach { lines.append("  " + String($0.prefix(72))) }
            if escalations.isEmpty { lines.append("  None") }
            lines.append("")
            lines.append("WEATHER EXPOSURE: 2 sites on hold today (rain) — labor cost impact")
            lines.append("LABOR EXPOSURE: 61 workers, \(assigns.count) new assigns, \(notes.count) field notes")
        }

        lines.append("")
        lines.append("Generated by ConstructionOS · \(role.display) view")
        reportText = lines.joined(separator: "\n")
        withAnimation(.easeInOut(duration: 0.2)) { generated = true }
    }

    private func copyReport() {
        copyTextToClipboard(reportText)
        copyStatus = "Copied to clipboard"
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run { copyStatus = nil }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("DAILY STANDUP")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.accent)
                Text(role.display)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.accent.opacity(0.9)))
                Spacer()
                if let status = copyStatus {
                    Text(status)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.green)
                }
                if generated {
                    Button(action: copyReport) {
                        Text("COPY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accent)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                Button(action: generateReport) {
                    Text(generated ? "REFRESH" : "GENERATE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(LinearGradient(gradient: Gradient(colors: [Theme.accent, Theme.gold]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            Text("Role-optimized report ready to paste into Slack, email, or field notes.")
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(Theme.muted)
            if generated && !reportText.isEmpty {
                ScrollView {
                    Text(reportText)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 220)
                .padding(10)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
        .onChange(of: rolePresetRaw) { _, _ in
            if generated { generateReport() }
        }
    }
}

// MARK: - Crew Deploy Board

struct CrewAssignment: Identifiable {
    let id: Int
    let site: String
    let trade: String
    let headcount: Int
    let status: String
    let statusColor: Color
}

struct CrewDeployBoard: View {
    @EnvironmentObject private var actionLog: RiskActionLogStore
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"
    @State private var loggedSite: String? = nil

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let crews: [CrewAssignment] = [
        CrewAssignment(id: 0, site: "Riverside Lofts",   trade: "Concrete",   headcount: 14, status: "HOLD",     statusColor: Theme.red),
        CrewAssignment(id: 1, site: "Site Gamma",         trade: "Steel",      headcount: 8,  status: "DELAYED",  statusColor: Theme.gold),
        CrewAssignment(id: 2, site: "Harbor Crossing",    trade: "MEP",        headcount: 22, status: "ACTIVE",   statusColor: Theme.green),
        CrewAssignment(id: 3, site: "Pine Ridge Ph.2",    trade: "Framing",    headcount: 11, status: "ACTIVE",   statusColor: Theme.green),
        CrewAssignment(id: 4, site: "Eastside Civic Hub", trade: "Finishes",   headcount: 6,  status: "STANDBY",  statusColor: Theme.cyan),
    ]

    private var totalCrew: Int { crews.reduce(0) { $0 + $1.headcount } }
    private var activeCount: Int { crews.filter { $0.status == "ACTIVE" }.count }
    private var holdCount: Int { crews.filter { $0.status == "HOLD" || $0.status == "DELAYED" }.count }

    private var roleSubtitle: String {
        switch role {
        case .superintendent: return "\(totalCrew) workers across \(crews.count) sites"
        case .projectManager: return "\(holdCount) crews delayed — schedule impact pending"
        case .executive:      return "Total labor exposure: \(totalCrew) workers"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("CREW DEPLOY")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.purple)
                HStack(spacing: 4) {
                    CrewStatBadge(label: "ACTIVE", count: activeCount,           color: Theme.green)
                    CrewStatBadge(label: "HOLD",   count: holdCount,             color: Theme.red)
                    CrewStatBadge(label: "TOTAL",  count: totalCrew,             color: Theme.purple)
                }
                Spacer()
            }
            Text(roleSubtitle)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.muted)
            if let site = loggedSite {
                Text("✓ Reassignment logged for \(site)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.green)
            }
            VStack(spacing: 6) {
                ForEach(crews) { crew in
                    CrewRowTile(crew: crew) {
                        actionLog.add("[reassign] \(crew.trade) crew reassigned from \(crew.site) — \(crew.headcount) workers")
                        loggedSite = crew.site
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            await MainActor.run { loggedSite = nil }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: Theme.purple)
    }
}

struct CrewStatBadge: View {
    let label: String
    let count: Int
    let color: Color
    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 7.5, weight: .heavy))
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.bg)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(color.opacity(0.85)))
        }
    }
}

struct CrewRowTile: View {
    let crew: CrewAssignment
    let onReassign: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(crew.statusColor.opacity(0.85))
                .frame(width: 7, height: 7)
            Text(crew.site)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(Theme.text)
                .lineLimit(1)
            Text(crew.trade)
                .font(.system(size: 8.5, weight: .regular))
                .foregroundColor(Theme.muted)
            Spacer()
            Text("\(crew.headcount) workers")
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.muted)
            Text(crew.status)
                .font(.system(size: 7.5, weight: .heavy))
                .foregroundColor(crew.statusColor)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(crew.statusColor.opacity(0.14))
                .cornerRadius(4)
            Button(action: onReassign) {
                Text("REASSIGN")
                    .font(.system(size: 7.5, weight: .heavy))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.purple.opacity(isHovering ? 1 : 0.75))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .onHover { isHovering = $0 }
        }
        .padding(.horizontal, 8)
        .frame(height: 30)
        .background(crew.statusColor.opacity(0.05))
        .cornerRadius(7)
    }
}

// MARK: - Inspection & Permit Tracker

struct InspectionItem: Identifiable {
    let id: Int
    let site: String
    let type: String
    let dueDays: Int
    let permitStatus: PermitStatus
}

enum PermitStatus: String {
    case approved = "APPROVED"
    case pending  = "PENDING"
    case flagged  = "FLAGGED"

    var color: Color {
        switch self {
        case .approved: return Theme.green
        case .pending:  return Theme.gold
        case .flagged:  return Theme.red
        }
    }
}

struct InspectionPermitTracker: View {
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let items: [InspectionItem] = [
        InspectionItem(id: 0, site: "Riverside Lofts",   type: "Foundation Inspection", dueDays:  0, permitStatus: .pending),
        InspectionItem(id: 1, site: "Site Gamma",         type: "Steel Frame Inspection", dueDays:  2, permitStatus: .approved),
        InspectionItem(id: 2, site: "Harbor Crossing",    type: "MEP Rough-in",           dueDays:  5, permitStatus: .approved),
        InspectionItem(id: 3, site: "Pine Ridge Ph.2",    type: "Framing Inspection",     dueDays: -1, permitStatus: .flagged),
        InspectionItem(id: 4, site: "Eastside Civic Hub", type: "Building Permit",        dueDays:  9, permitStatus: .pending),
    ]

    private var overdueCount:  Int { items.filter { $0.dueDays <  0 }.count }
    private var dueTodayCount: Int { items.filter { $0.dueDays == 0 }.count }
    private var upcomingCount: Int { items.filter { $0.dueDays >  0 }.count }
    private var hasCritical:   Bool { overdueCount > 0 || dueTodayCount > 0 }

    private var roleNote: String {
        switch role {
        case .superintendent: return "Coordinate inspectors on site for due items"
        case .projectManager: return "Permit flags may delay critical path"
        case .executive:      return "\(overdueCount + dueTodayCount) inspections require immediate action"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("INSPECTIONS & PERMITS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(hasCritical ? Theme.red : Theme.gold)
                if overdueCount > 0 {
                    Text("\(overdueCount) OVERDUE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.red)
                        .cornerRadius(5)
                }
                if dueTodayCount > 0 {
                    Text("DUE TODAY")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.gold)
                        .cornerRadius(5)
                }
                Spacer()
            }
            Text(roleNote)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.muted)
            VStack(spacing: 6) {
                ForEach(items) { item in
                    InspectionRow(item: item)
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: hasCritical ? Theme.red : Theme.gold)
    }
}

struct InspectionRow: View {
    let item: InspectionItem

    private var dueLabel: String {
        if item.dueDays < 0  { return "\(abs(item.dueDays))d OVERDUE" }
        if item.dueDays == 0 { return "DUE TODAY" }
        return "DUE IN \(item.dueDays)d"
    }

    private var dueColor: Color {
        if item.dueDays <= 0 { return Theme.red }
        if item.dueDays <= 3 { return Theme.gold }
        return Theme.muted
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.site)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                Text(item.type)
                    .font(.system(size: 8.5, weight: .regular))
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
            }
            Spacer()
            Text(dueLabel)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(dueColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(dueColor.opacity(0.12))
                .cornerRadius(4)
            Text(item.permitStatus.rawValue)
                .font(.system(size: 7.5, weight: .heavy))
                .foregroundColor(item.permitStatus.color)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(item.permitStatus.color.opacity(0.14))
                .cornerRadius(4)
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background(item.dueDays <= 0 ? Theme.red.opacity(0.06) : Theme.surface.opacity(0.5))
        .cornerRadius(7)
    }
}

// MARK: - Weather Risk Overlay

struct WeatherDay: Identifiable {
    let id: Int
    let label: String
    let icon: String
    let tempHigh: Int
    let tempLow: Int
    let condition: String
    let riskFlags: [WeatherRiskFlag]
}

struct WeatherRiskFlag: Identifiable {
    let id: Int
    let label: String
    let color: Color
}

struct WeatherRiskPanel: View {
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let forecast: [WeatherDay] = [
        WeatherDay(id: 0, label: "TODAY",  icon: "🌧", tempHigh: 54, tempLow: 41,
                   condition: "Heavy Rain",
                   riskFlags: [
                       WeatherRiskFlag(id: 0, label: "CONCRETE POUR HOLD", color: Theme.red),
                       WeatherRiskFlag(id: 1, label: "SLIP HAZARD",        color: Theme.gold),
                   ]),
        WeatherDay(id: 1, label: "TMR",    icon: "⛅️", tempHigh: 61, tempLow: 44,
                   condition: "Partly Cloudy",
                   riskFlags: [
                       WeatherRiskFlag(id: 2, label: "WIND ADVISORY",      color: Theme.gold),
                   ]),
        WeatherDay(id: 2, label: "Day 3",  icon: "☀️", tempHigh: 68, tempLow: 50,
                   condition: "Clear",
                   riskFlags: []),
    ]

    private var hasFieldWarning: Bool {
        forecast.first?.riskFlags.contains { $0.color == Theme.red } == true
    }

    private var roleNote: String {
        switch role {
        case .superintendent: return "Concrete + steel ops suspended today"
        case .projectManager: return "Rain delay — update schedule baseline"
        case .executive:      return "Weather delay risk on 2 sites today"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                DashboardPanelHeading(
                    eyebrow: "WEATHER",
                    title: "Weather risk overlay",
                    detail: "Forecast-driven field risk and role-specific impact for the next work window.",
                    accent: Theme.cyan
                )
                if hasFieldWarning {
                    Text("⚠ FIELD WARNING")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.red)
                        .cornerRadius(5)
                }
                Spacer()
            }

            Text(roleNote)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.muted)

            HStack(spacing: 8) {
                ForEach(forecast) { day in
                    WeatherDayCard(day: day)
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: hasFieldWarning ? Theme.red : Theme.cyan)
    }
}

struct WeatherDayCard: View {
    let day: WeatherDay

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(day.label)
                    .font(.system(size: 8.5, weight: .heavy))
                    .foregroundColor(Theme.muted)
                Spacer()
                Text(day.icon)
                    .font(.system(size: 14))
            }
            Text(day.condition)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.text)
            Text("\(day.tempHigh)° / \(day.tempLow)°")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(Theme.muted)
            if day.riskFlags.isEmpty {
                Text("No risk flags")
                    .font(.system(size: 7.5, weight: .regular))
                    .foregroundColor(Theme.green.opacity(0.8))
            } else {
                ForEach(day.riskFlags) { flag in
                    Text(flag.label)
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(flag.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(day.riskFlags.isEmpty ? Theme.surface.opacity(0.6) : day.riskFlags.first!.color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(day.riskFlags.isEmpty ? Theme.border.opacity(0.3) : day.riskFlags.first!.color.opacity(0.4), lineWidth: 0.9)
        )
        .cornerRadius(9)
    }
}

// MARK: - Site Status Dashboard

enum SiteStatusLevel: String {
    case onTrack = "ON TRACK"
    case atRisk  = "AT RISK"
    case delayed = "DELAYED"

    var color: Color {
        switch self {
        case .onTrack: return Theme.green
        case .atRisk:  return Theme.gold
        case .delayed: return Theme.red
        }
    }
    var dot: String {
        switch self {
        case .onTrack: return "●"
        case .atRisk:  return "◆"
        case .delayed: return "▲"
        }
    }
}

struct SiteEntry: Identifiable {
    let id: Int
    let name: String
    let status: SiteStatusLevel
    let trade: String
    let owner: String
}

struct SiteStatusDashboard: View {
    @EnvironmentObject private var actionLog: RiskActionLogStore
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let sites: [SiteEntry] = [
        SiteEntry(id: 0, name: "Riverside Lofts",   status: .delayed,  trade: "Concrete",  owner: "Apex Dev"),
        SiteEntry(id: 1, name: "Site Gamma",         status: .atRisk,   trade: "Steel",     owner: "Henderson LLC"),
        SiteEntry(id: 2, name: "Harbor Crossing",    status: .onTrack,  trade: "MEP",       owner: "Sun Capital"),
        SiteEntry(id: 3, name: "Pine Ridge Ph.2",    status: .atRisk,   trade: "Framing",   owner: "Miller Group"),
        SiteEntry(id: 4, name: "Eastside Civic Hub", status: .onTrack,  trade: "Finishes",  owner: "City of West"),
    ]

    private var delayedCount: Int { sites.filter { $0.status == .delayed }.count }
    private var atRiskCount:  Int { sites.filter { $0.status == .atRisk  }.count }
    private var onTrackCount: Int { sites.filter { $0.status == .onTrack }.count }

    private var roleSubtitle: String {
        switch role {
        case .superintendent: return "Field coordination view"
        case .projectManager: return "Schedule impact view"
        case .executive:      return "Escalation exposure"
        }
    }

    private func recentAction(for site: SiteEntry) -> String {
        let key = site.name.lowercased().components(separatedBy: " ").first ?? ""
        let hit = actionLog.entries.first { $0.lowercased().contains(key) }
        return hit.map { String($0.prefix(44)) } ?? "No actions logged"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                DashboardPanelHeading(
                    eyebrow: "SITE STATUS",
                    title: "Live site operating picture",
                    detail: "Current trade posture, owner context, and recent actions across active jobs.",
                    accent: Theme.green
                )
                Spacer()
                Text(roleSubtitle)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.muted)
            }

            HStack(spacing: 8) {
                DashboardStatPill(value: "\(onTrackCount)", label: "ON TRACK", color: Theme.green)
                DashboardStatPill(value: "\(atRiskCount)", label: "AT RISK", color: Theme.gold)
                DashboardStatPill(value: "\(delayedCount)", label: "DELAYED", color: Theme.red)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(sites) { site in
                    SiteStatusTile(
                        name:         site.name,
                        status:       site.status,
                        trade:        site.trade,
                        owner:        site.owner,
                        role:         role,
                        recentAction: recentAction(for: site)
                    )
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: Theme.green)
    }
}

struct SiteStatBadge: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 7.5, weight: .heavy))
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.bg)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(color.opacity(0.85)))
        }
    }
}

struct SiteStatusTile: View {
    let name: String
    let status: SiteStatusLevel
    let trade: String
    let owner: String
    let role: OpsRolePreset
    let recentAction: String

    private var roleDetailLine: String {
        switch role {
        case .superintendent: return trade
        case .projectManager: return "Owner: \(owner)"
        case .executive:      return owner
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Text(status.dot)
                    .font(.system(size: 9))
                    .foregroundColor(status.color)
                Text(status.rawValue)
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(status.color)
                Spacer()
            }
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.text)
                .lineLimit(1)
            Text(roleDetailLine)
                .font(.system(size: 8.5, weight: .regular))
                .foregroundColor(Theme.muted)
                .lineLimit(1)
            Text(recentAction)
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundColor(Theme.muted.opacity(0.75))
                .lineLimit(2)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(status.color.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(status.color.opacity(0.35), lineWidth: 0.9)
        )
        .cornerRadius(10)
    }
}

struct LogFilterChip: View {
    let title: String
    let selected: Bool
    let color: Color
    let action: () -> Void
    @State private var isHovering = false

    private var chipParts: (label: String, count: String?) {
        let pieces = title.split(separator: " ")
        guard pieces.count >= 2, let last = pieces.last, Int(last) != nil else {
            return (title, nil)
        }
        let label = pieces.dropLast().joined(separator: " ")
        return (label, String(last))
    }

    private var fillColor: Color {
        if selected {
            return color
        }
        return isHovering ? color.opacity(0.24) : color.opacity(0.14)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(chipParts.label)
                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)

                if let count = chipParts.count {
                    Text(count)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(selected ? Color.black.opacity(0.18) : color.opacity(0.16))
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(selected ? .black : color.opacity(isHovering ? 1 : 0.95))
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .frame(height: 24)
            .background(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(selected ? 0 : (isHovering ? 0.45 : 0.28)), lineWidth: 0.8)
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
