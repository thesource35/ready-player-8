import Foundation
import SwiftUI

// MARK: - ========== Field Operations Tab ==========

struct DailyLogEntry: Identifiable, Codable {
    var id = UUID()
    let date: String; let weather: String; let tempHigh: Int; let tempLow: Int
    let manpower: Int; let workPerformed: String; let visitors: String
    let delays: String; let safetyNotes: String; let photoCount: Int; let createdBy: String
}

struct TimecardEntry: Identifiable, Codable {
    var id = UUID()
    let crewMember: String; let trade: String; let clockIn: String; let clockOut: String
    let hoursRegular: Double; let hoursOT: Double; let rate: Double; let site: String; let date: String
}

struct EquipmentAsset: Identifiable {
    let id = UUID()
    let name: String; let assetTag: String; let category: String; let site: String
    let hoursUsed: Int; let nextService: String; let status: String
}

struct PermitItem: Identifiable, Codable {
    var id = UUID()
    let permitNumber: String; let type: String; let jurisdiction: String
    let issuedDate: String; let expiresDate: String; let site: String; let status: String
    let contactName: String; let contactPhone: String
}

struct FieldOpsView: View {
    @State private var activeTab = 0
    @State private var dailyLogs: [DailyLogEntry] = []

    private let mockEquipment: [EquipmentAsset] = [
        EquipmentAsset(name: "CAT 320 Excavator", assetTag: "EQ-001", category: "Heavy", site: "Riverside Lofts", hoursUsed: 2340, nextService: "50 hrs", status: "ACTIVE"),
        EquipmentAsset(name: "JLG 600S Boom Lift", assetTag: "EQ-014", category: "Aerial", site: "Harbor Crossing", hoursUsed: 890, nextService: "110 hrs", status: "ACTIVE"),
        EquipmentAsset(name: "Bobcat S770", assetTag: "EQ-008", category: "Earthmoving", site: "Pine Ridge Ph.2", hoursUsed: 1560, nextService: "40 hrs", status: "SERVICE DUE"),
        EquipmentAsset(name: "Wacker Compactor", assetTag: "EQ-022", category: "Compaction", site: "Yard", hoursUsed: 420, nextService: "80 hrs", status: "IDLE"),
    ]
    private let mockTimecards: [TimecardEntry] = [
        TimecardEntry(crewMember: "Mike Torres", trade: "Concrete", clockIn: "6:00 AM", clockOut: "2:30 PM", hoursRegular: 8, hoursOT: 0.5, rate: 45, site: "Riverside Lofts", date: "03/25"),
        TimecardEntry(crewMember: "Sarah Kim", trade: "Electrical", clockIn: "7:00 AM", clockOut: "5:30 PM", hoursRegular: 8, hoursOT: 2.5, rate: 55, site: "Harbor Crossing", date: "03/25"),
        TimecardEntry(crewMember: "James Wright", trade: "Framing", clockIn: "6:30 AM", clockOut: "3:00 PM", hoursRegular: 8, hoursOT: 0, rate: 42, site: "Pine Ridge Ph.2", date: "03/25"),
    ]
    private let mockPermits: [PermitItem] = [
        PermitItem(permitNumber: "BP-2026-4821", type: "Building", jurisdiction: "City of Houston", issuedDate: "01/15/26", expiresDate: "01/15/27", site: "Riverside Lofts", status: "ACTIVE", contactName: "J. Martinez", contactPhone: "713-555-0142"),
        PermitItem(permitNumber: "EP-2026-1193", type: "Electrical", jurisdiction: "Harris County", issuedDate: "02/01/26", expiresDate: "08/01/26", site: "Harbor Crossing", status: "ACTIVE", contactName: "R. Chen", contactPhone: "713-555-0198"),
        PermitItem(permitNumber: "GP-2026-0782", type: "Grading", jurisdiction: "City of Houston", issuedDate: "12/01/25", expiresDate: "06/01/26", site: "Pine Ridge Ph.2", status: "EXPIRING", contactName: "A. Patel", contactPhone: "713-555-0231"),
    ]
    private let tabs = ["Daily Log", "Timecards", "Equipment", "Permits"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FIELD OPS").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.cyan)
                        Text("Field Operations Center").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("Daily logs, timecards, equipment tracking, and permits").font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.cyan)

                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button { withAnimation { activeTab = i } } label: {
                            Text(tabs[i].uppercased()).font(.system(size: 9, weight: .bold)).tracking(1)
                                .foregroundColor(activeTab == i ? .black : Theme.muted)
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                .background(activeTab == i ? Theme.cyan : Theme.surface)
                        }.buttonStyle(.plain)
                    }
                }.cornerRadius(8)

                if activeTab == 0 { dailyLogContent }
                else if activeTab == 1 { timecardsContent }
                else if activeTab == 2 { equipmentContent }
                else { permitsContent }
            }.padding(16)
        }.background(Theme.bg)
        .onAppear { dailyLogs = loadJSON("ConstructOS.Field.DailyLogs", default: [DailyLogEntry]()) }
    }

    private var dailyLogContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DAILY FIELD REPORTS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
            if dailyLogs.isEmpty {
                VStack(spacing: 8) { Text("No daily logs yet").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted) }
                    .frame(maxWidth: .infinity).padding(24).background(Theme.surface).cornerRadius(12)
            }
            ForEach(dailyLogs) { log in
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text(log.date).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text("\(log.manpower) crew").font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.cyan) }
                    Text(log.workPerformed).font(.system(size: 10)).foregroundColor(Theme.text).lineLimit(3)
                }.padding(12).background(Theme.surface).cornerRadius(10)
            }
        }
    }

    private var timecardsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CREW TIMECARDS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
            let totalHrs = mockTimecards.reduce(0.0) { $0 + $1.hoursRegular + $1.hoursOT }
            let totalCost = mockTimecards.reduce(0.0) { $0 + ($1.hoursRegular * $1.rate) + ($1.hoursOT * $1.rate * 1.5) }
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text(String(format: "%.1f", totalHrs)).font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("HOURS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("$\(String(format: "%.0f", totalCost))").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("LABOR COST").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.accent.opacity(0.06)).cornerRadius(8)
            }
            ForEach(mockTimecards) { tc in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) { Text(tc.crewMember).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Text("\(tc.trade) \u{2022} \(tc.site)").font(.system(size: 9)).foregroundColor(Theme.muted) }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) { Text("\(tc.clockIn) - \(tc.clockOut)").font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.text)
                        HStack(spacing: 4) { Text("\(String(format: "%.0f", tc.hoursRegular))h").font(.system(size: 8)).foregroundColor(Theme.green); if tc.hoursOT > 0 { Text("+\(String(format: "%.1f", tc.hoursOT))h OT").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold) } }
                    }
                    Text("$\(String(format: "%.0f", (tc.hoursRegular * tc.rate) + (tc.hoursOT * tc.rate * 1.5)))").font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.accent)
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    private var equipmentContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EQUIPMENT GPS TRACKER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            ForEach(mockEquipment) { eq in
                HStack(spacing: 10) {
                    Circle().fill(eq.status == "ACTIVE" ? Theme.green : eq.status == "IDLE" ? Theme.muted : Theme.gold).frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) { Text(eq.name).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Text(eq.assetTag).font(.system(size: 8, design: .monospaced)).foregroundColor(Theme.muted) }
                        Text("\(eq.site) \u{2022} \(eq.category) \u{2022} \(eq.hoursUsed) hrs").font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(eq.status).font(.system(size: 8, weight: .black)).foregroundColor(eq.status == "ACTIVE" ? Theme.green : eq.status == "IDLE" ? Theme.muted : Theme.gold)
                        Text("Svc in \(eq.nextService)").font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    private var permitsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PERMIT BOARD").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
            ForEach(mockPermits) { permit in
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text(permit.permitNumber).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(Theme.text); Spacer(); Text(permit.status).font(.system(size: 8, weight: .black)).foregroundColor(permit.status == "ACTIVE" ? Theme.green : Theme.gold) }
                    Text("\(permit.type) Permit \u{2022} \(permit.jurisdiction)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    HStack(spacing: 12) { Text("Issued: \(permit.issuedDate)").font(.system(size: 8)).foregroundColor(Theme.muted); Text("Expires: \(permit.expiresDate)").font(.system(size: 8, weight: .bold)).foregroundColor(permit.status == "EXPIRING" ? Theme.gold : Theme.muted) }
                    Text("\(permit.contactName) \u{2022} \(permit.contactPhone)").font(.system(size: 8)).foregroundColor(Theme.muted)
                }.padding(12).background(Theme.surface).cornerRadius(10)
            }
        }
    }
}
