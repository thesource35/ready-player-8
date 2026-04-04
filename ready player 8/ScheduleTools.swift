import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


// MARK: - ========== Project Timeline / Gantt Chart ==========

struct GanttTask: Identifiable {
    let id = UUID()
    let name: String
    let trade: String
    let startWeek: Int
    let durationWeeks: Int
    let percentComplete: Int
    let isCritical: Bool
    let dependencies: [String]
}

struct GanttChartView: View {
    private let tasks: [GanttTask] = [
        GanttTask(name: "Site Prep & Grading", trade: "Earthwork", startWeek: 1, durationWeeks: 3, percentComplete: 100, isCritical: true, dependencies: []),
        GanttTask(name: "Foundation", trade: "Concrete", startWeek: 4, durationWeeks: 4, percentComplete: 100, isCritical: true, dependencies: ["Site Prep"]),
        GanttTask(name: "Structural Steel", trade: "Steel", startWeek: 8, durationWeeks: 6, percentComplete: 75, isCritical: true, dependencies: ["Foundation"]),
        GanttTask(name: "Rough Plumbing", trade: "Plumbing", startWeek: 10, durationWeeks: 4, percentComplete: 60, isCritical: false, dependencies: ["Foundation"]),
        GanttTask(name: "Electrical Rough-in", trade: "Electrical", startWeek: 11, durationWeeks: 5, percentComplete: 45, isCritical: false, dependencies: ["Foundation"]),
        GanttTask(name: "HVAC Ductwork", trade: "HVAC", startWeek: 12, durationWeeks: 4, percentComplete: 30, isCritical: false, dependencies: ["Structural Steel"]),
        GanttTask(name: "Exterior Envelope", trade: "Exterior", startWeek: 14, durationWeeks: 5, percentComplete: 10, isCritical: true, dependencies: ["Structural Steel"]),
        GanttTask(name: "Drywall & Framing", trade: "Framing", startWeek: 16, durationWeeks: 4, percentComplete: 0, isCritical: true, dependencies: ["Rough Plumbing", "Electrical"]),
        GanttTask(name: "Finishes", trade: "Finishing", startWeek: 20, durationWeeks: 3, percentComplete: 0, isCritical: true, dependencies: ["Drywall"]),
        GanttTask(name: "Commissioning", trade: "General", startWeek: 23, durationWeeks: 2, percentComplete: 0, isCritical: true, dependencies: ["Finishes"]),
    ]
    private let totalWeeks = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROJECT TIMELINE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
            Text("Critical path highlighted \u{2022} 26-week schedule").font(.system(size: 9)).foregroundColor(Theme.muted)

            // Week headers
            HStack(spacing: 0) {
                Text("TASK").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted).frame(width: 100, alignment: .leading)
                ForEach(1...totalWeeks, id: \.self) { w in
                    if w % 4 == 1 {
                        Text("W\(w)").font(.system(size: 6, weight: .bold)).foregroundColor(Theme.muted).frame(maxWidth: .infinity)
                    }
                }
            }

            ForEach(tasks) { task in
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(task.name).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                        Text(task.trade).font(.system(size: 6)).foregroundColor(Theme.muted)
                    }.frame(width: 100, alignment: .leading)

                    GeometryReader { geo in
                        let barWidth = geo.size.width
                        let startX = barWidth * CGFloat(task.startWeek - 1) / CGFloat(totalWeeks)
                        let width = barWidth * CGFloat(task.durationWeeks) / CGFloat(totalWeeks)
                        let fillWidth = width * CGFloat(task.percentComplete) / 100

                        ZStack(alignment: .leading) {
                            // Background bar
                            RoundedRectangle(cornerRadius: 3)
                                .fill(task.isCritical ? Theme.red.opacity(0.15) : Theme.surface)
                                .frame(width: width, height: 14)
                                .offset(x: startX)

                            // Progress fill
                            if task.percentComplete > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(task.percentComplete == 100 ? Theme.green : task.isCritical ? Theme.red.opacity(0.6) : Theme.cyan.opacity(0.6))
                                    .frame(width: fillWidth, height: 14)
                                    .offset(x: startX)
                            }

                            // Percent label
                            Text("\(task.percentComplete)%")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: startX + 3, y: 0)
                        }
                    }.frame(height: 16)
                }
            }

            HStack(spacing: 12) {
                HStack(spacing: 4) { RoundedRectangle(cornerRadius: 2).fill(Theme.red.opacity(0.6)).frame(width: 12, height: 6); Text("Critical Path").font(.system(size: 7)).foregroundColor(Theme.muted) }
                HStack(spacing: 4) { RoundedRectangle(cornerRadius: 2).fill(Theme.cyan.opacity(0.6)).frame(width: 12, height: 6); Text("Non-Critical").font(.system(size: 7)).foregroundColor(Theme.muted) }
                HStack(spacing: 4) { RoundedRectangle(cornerRadius: 2).fill(Theme.green).frame(width: 12, height: 6); Text("Complete").font(.system(size: 7)).foregroundColor(Theme.muted) }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12).premiumGlow(cornerRadius: 12, color: Theme.accent)
    }
}

// MARK: - ========== CSI MasterFormat Cost Codes ==========

struct CostCodeEntry: Identifiable {
    let id = UUID()
    let code: String
    let division: String
    let description: String
    let budgeted: Double
    let actual: Double
    let committed: Double
}

struct CostCodeView: View {
    private let codes: [CostCodeEntry] = [
        CostCodeEntry(code: "03 00 00", division: "Concrete", description: "All concrete work", budgeted: 485000, actual: 312000, committed: 142000),
        CostCodeEntry(code: "05 00 00", division: "Metals", description: "Structural & misc steel", budgeted: 620000, actual: 465000, committed: 98000),
        CostCodeEntry(code: "06 00 00", division: "Wood/Plastics", description: "Framing & blocking", budgeted: 180000, actual: 95000, committed: 72000),
        CostCodeEntry(code: "09 00 00", division: "Finishes", description: "Drywall, paint, flooring", budgeted: 340000, actual: 48000, committed: 195000),
        CostCodeEntry(code: "22 00 00", division: "Plumbing", description: "All plumbing systems", budgeted: 275000, actual: 165000, committed: 85000),
        CostCodeEntry(code: "23 00 00", division: "HVAC", description: "Mechanical systems", budgeted: 410000, actual: 198000, committed: 142000),
        CostCodeEntry(code: "26 00 00", division: "Electrical", description: "All electrical systems", budgeted: 385000, actual: 210000, committed: 118000),
        CostCodeEntry(code: "31 00 00", division: "Earthwork", description: "Grading & excavation", budgeted: 125000, actual: 118000, committed: 0),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CSI MASTERFORMAT COST CODES").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            let totalBudget = codes.reduce(0.0) { $0 + $1.budgeted }
            let totalActual = codes.reduce(0.0) { $0 + $1.actual }
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("$\(String(format: "%.1f", totalBudget/1000000))M").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("BUDGET").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("$\(String(format: "%.1f", totalActual/1000000))M").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("ACTUAL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("\(String(format: "%.0f", totalActual/totalBudget*100))%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("SPENT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.green.opacity(0.06)).cornerRadius(8)
            }
            ForEach(codes) { c in
                let pct = c.budgeted > 0 ? (c.actual + c.committed) / c.budgeted * 100 : 0
                HStack(spacing: 6) {
                    Text(c.code).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(Theme.gold).frame(width: 60, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.division).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2).fill(Theme.border.opacity(0.3)).frame(height: 4)
                                RoundedRectangle(cornerRadius: 2).fill(pct > 100 ? Theme.red : Theme.green).frame(width: geo.size.width * min(CGFloat(pct), 100) / 100, height: 4)
                            }
                        }.frame(height: 4)
                    }
                    Text("$\(String(format: "%.0f", c.actual/1000))K").font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.accent).frame(width: 50, alignment: .trailing)
                    Text("\(String(format: "%.0f", pct))%").font(.system(size: 8, weight: .bold)).foregroundColor(pct > 100 ? Theme.red : Theme.green).frame(width: 30)
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }
}

// MARK: - ========== Material Takeoff Calculator ==========

struct MaterialTakeoffView: View {
    @State private var length: String = ""
    @State private var width: String = ""
    @State private var height: String = ""
    @State private var thickness: String = "4"
    @State private var materialType = 0
    private let materials = ["Concrete (CY)", "Drywall (sheets)", "Lumber 2x4 (pcs)", "Rebar #4 (pcs)", "Paint (gal)"]

    private var result: String {
        let l = Double(length) ?? 0, w = Double(width) ?? 0, h = Double(height) ?? 0, t = Double(thickness) ?? 4
        guard l > 0, w > 0 else { return "Enter dimensions" }
        let area = l * w
        switch materialType {
        case 0: let cy = area * (t / 12) / 27; return "\(String(format: "%.1f", cy)) CY concrete (+ 10% waste = \(String(format: "%.1f", cy * 1.1)) CY)"
        case 1: let sheets = Int(ceil(area / 32)); return "\(sheets) sheets 4x8 drywall (+ 10% = \(Int(ceil(Double(sheets) * 1.1))))"
        case 2: let pcs = h > 0 ? Int(ceil(l / 1.333)) * Int(ceil(h / 8)) : Int(ceil(l / 1.333)); return "\(pcs) studs @ 16\" OC"
        case 3: let pcs = Int(ceil(l / 20)) * Int(ceil(w / 20)) * (h > 0 ? Int(h) : 1); return "\(pcs) pieces #4 rebar @ 12\" OC"
        case 4: let gal = area / 350; return "\(String(format: "%.1f", gal)) gallons (1 coat, 350 sf/gal)"
        default: return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MATERIAL TAKEOFF CALCULATOR").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(materials.indices, id: \.self) { i in
                        Button { materialType = i } label: {
                            Text(materials[i]).font(.system(size: 8, weight: .bold))
                                .foregroundColor(materialType == i ? .black : Theme.text)
                                .padding(.horizontal, 8).padding(.vertical, 5)
                                .background(materialType == i ? Theme.cyan : Theme.panel).cornerRadius(5)
                        }.buttonStyle(.plain)
                    }
                }
            }
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("LENGTH (ft)").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); TextField("0", text: $length).font(.system(size: 12)).padding(6).background(Theme.panel).cornerRadius(5) }
                VStack(spacing: 2) { Text("WIDTH (ft)").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); TextField("0", text: $width).font(.system(size: 12)).padding(6).background(Theme.panel).cornerRadius(5) }
                if materialType == 2 || materialType == 3 { VStack(spacing: 2) { Text("HEIGHT (ft)").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); TextField("0", text: $height).font(.system(size: 12)).padding(6).background(Theme.panel).cornerRadius(5) } }
                if materialType == 0 { VStack(spacing: 2) { Text("THICK (in)").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); TextField("4", text: $thickness).font(.system(size: 12)).padding(6).background(Theme.panel).cornerRadius(5) } }
            }
            Text(result).font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.accent).padding(10).frame(maxWidth: .infinity, alignment: .leading).background(Theme.accent.opacity(0.06)).cornerRadius(8)
        }
        .padding(14).background(Theme.surface).cornerRadius(12).premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }
}

// MARK: - ========== Fuel Log Tracker ==========

struct FuelEntry: Identifiable, Codable {
    var id = UUID()
    let date: String; let vehicle: String; let gallons: Double; let pricePerGal: Double; let odometer: Int; let site: String
    var total: Double { gallons * pricePerGal }
}

struct FuelLogView: View {
     private var entries: [FuelEntry] = loadJSON("ConstructOS.Fleet.FuelEntries", default: [FuelEntry]())
    @State private var showAdd = false

    private let mockEntries: [FuelEntry] = [
        FuelEntry(date: "03/25", vehicle: "F-350 #12", gallons: 32.4, pricePerGal: 3.45, odometer: 48291, site: "Riverside Lofts"),
        FuelEntry(date: "03/24", vehicle: "Excavator EQ-001", gallons: 45.0, pricePerGal: 3.89, odometer: 0, site: "Riverside Lofts"),
        FuelEntry(date: "03/24", vehicle: "F-250 #08", gallons: 28.1, pricePerGal: 3.42, odometer: 62104, site: "Harbor Crossing"),
        FuelEntry(date: "03/23", vehicle: "Loader EQ-003", gallons: 38.0, pricePerGal: 3.89, odometer: 0, site: "Pine Ridge Ph.2"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FUEL LOG").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Color.orange)
            let totalGal = (entries.isEmpty ? mockEntries : entries).reduce(0.0) { $0 + $1.gallons }
            let totalCost = (entries.isEmpty ? mockEntries : entries).reduce(0.0) { $0 + $1.total }
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text(String(format: "%.0f", totalGal)).font(.system(size: 18, weight: .heavy)).foregroundColor(Color.orange); Text("GALLONS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Color.orange.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("$\(String(format: "%.0f", totalCost))").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("TOTAL COST").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.accent.opacity(0.06)).cornerRadius(8)
            }
            ForEach(entries.isEmpty ? mockEntries : entries) { e in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) { Text(e.vehicle).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Text("\(e.date) \u{2022} \(e.site)").font(.system(size: 8)).foregroundColor(Theme.muted) }
                    Spacer()
                    Text("\(String(format: "%.1f", e.gallons)) gal").font(.system(size: 9)).foregroundColor(Theme.muted)
                    Text("$\(String(format: "%.2f", e.pricePerGal))/gal").font(.system(size: 8)).foregroundColor(Theme.muted)
                    Text("$\(String(format: "%.0f", e.total))").font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.accent)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .onAppear { entries = loadJSON("ConstructOS.Fuel.Entries", default: [FuelEntry]()) }
    }
}

// MARK: - ========== Training & Certification Tracker ==========

struct CrewCertification: Identifiable {
    let id = UUID()
    let crewMember: String; let certification: String; let issuer: String
    let issueDate: String; let expiryDate: String; let status: String
    let initials: String
}

struct TrainingCertView: View {
    private let certs: [CrewCertification] = [
        CrewCertification(crewMember: "Mike Torres", certification: "OSHA 30-Hour", issuer: "OSHA", issueDate: "01/15/25", expiryDate: "01/15/30", status: "CURRENT", initials: "MT"),
        CrewCertification(crewMember: "Sarah Kim", certification: "Master Electrician", issuer: "State of TX", issueDate: "06/01/24", expiryDate: "06/01/26", status: "EXPIRING", initials: "SK"),
        CrewCertification(crewMember: "James Wright", certification: "NCCCO Crane Operator", issuer: "NCCCO", issueDate: "03/15/24", expiryDate: "03/15/29", status: "CURRENT", initials: "JW"),
        CrewCertification(crewMember: "Carlos Mendez", certification: "CPR/First Aid", issuer: "Red Cross", issueDate: "09/01/24", expiryDate: "09/01/26", status: "CURRENT", initials: "CM"),
        CrewCertification(crewMember: "Andre Williams", certification: "Forklift Operator", issuer: "OSHA", issueDate: "11/01/22", expiryDate: "11/01/25", status: "EXPIRED", initials: "AW"),
        CrewCertification(crewMember: "Priya Patel", certification: "BICSI RCDD", issuer: "BICSI", issueDate: "04/01/23", expiryDate: "04/01/26", status: "CURRENT", initials: "PP"),
        CrewCertification(crewMember: "Derek Torres", certification: "NABCEP PV Installer", issuer: "NABCEP", issueDate: "08/15/24", expiryDate: "08/15/27", status: "CURRENT", initials: "DT"),
        CrewCertification(crewMember: "Kim Nguyen", certification: "OSHA 10-Hour", issuer: "OSHA", issueDate: "01/01/24", expiryDate: "N/A", status: "CURRENT", initials: "KN"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TRAINING & CERTS").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.gold)
                        Text("Workforce Certifications").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                    }
                    Spacer()
                    let expired = certs.filter { $0.status == "EXPIRED" }.count
                    let expiring = certs.filter { $0.status == "EXPIRING" }.count
                    if expired > 0 { Text("\(expired) EXPIRED").font(.system(size: 9, weight: .black)).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 3).background(Theme.red).cornerRadius(4) }
                    if expiring > 0 { Text("\(expiring) EXPIRING").font(.system(size: 9, weight: .black)).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 3).background(Theme.gold).cornerRadius(4) }
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.gold)

                HStack(spacing: 8) {
                    VStack(spacing: 2) { Text("\(certs.count)").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.accent); Text("TOTAL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                    VStack(spacing: 2) { Text("\(certs.filter { $0.status == "CURRENT" }.count)").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.green); Text("CURRENT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.green.opacity(0.06)).cornerRadius(8)
                    VStack(spacing: 2) { Text("\(certs.filter { $0.status == "EXPIRED" || $0.status == "EXPIRING" }.count)").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.red); Text("ACTION").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.red.opacity(0.06)).cornerRadius(8)
                }

                ForEach(certs) { cert in
                    HStack(spacing: 10) {
                        Circle().fill(cert.status == "CURRENT" ? Theme.green : cert.status == "EXPIRING" ? Theme.gold : Theme.red)
                            .frame(width: 32, height: 32)
                            .overlay(Text(cert.initials).font(.system(size: 10, weight: .heavy)).foregroundColor(.white))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cert.crewMember).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                            Text(cert.certification).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.cyan)
                            Text("\(cert.issuer) \u{2022} \(cert.issueDate) to \(cert.expiryDate)").font(.system(size: 8)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        Text(cert.status).font(.system(size: 8, weight: .black))
                            .foregroundColor(cert.status == "CURRENT" ? Theme.green : cert.status == "EXPIRING" ? Theme.gold : Theme.red)
                    }.padding(10).background(Theme.surface).cornerRadius(8)
                }
            }.padding(16)
        }.background(Theme.bg)
    }
}

// MARK: - ========== Crew Scheduling Calendar ==========

struct CrewScheduleView: View {
    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let crews: [(name: String, trade: String, assignments: [String])] = [
        ("Alpha Crew", "Concrete", ["RSL", "RSL", "RSL", "HBC", "HBC", ""]),
        ("Bravo Crew", "Steel", ["HBC", "HBC", "HBC", "HBC", "HBC", "HBC"]),
        ("Charlie Crew", "Electrical", ["PRP", "PRP", "RSL", "RSL", "PRP", ""]),
        ("Delta Crew", "Framing", ["PRP", "PRP", "PRP", "PRP", "PRP", ""]),
        ("Echo Crew", "MEP", ["HBC", "HBC", "ECH", "ECH", "HBC", ""]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CREW SCHEDULE \u{2014} THIS WEEK").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)

            HStack(spacing: 0) {
                Text("CREW").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted).frame(width: 80, alignment: .leading)
                ForEach(days, id: \.self) { d in
                    Text(d.uppercased()).font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted).frame(maxWidth: .infinity)
                }
            }

            ForEach(crews, id: \.name) { crew in
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(crew.name).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.text)
                        Text(crew.trade).font(.system(size: 7)).foregroundColor(Theme.muted)
                    }.frame(width: 80, alignment: .leading)

                    ForEach(crew.assignments.indices, id: \.self) { i in
                        let site = crew.assignments[i]
                        Text(site).font(.system(size: 7, weight: .bold))
                            .foregroundColor(site.isEmpty ? Theme.muted : .white)
                            .frame(maxWidth: .infinity).frame(height: 22)
                            .background(site.isEmpty ? Theme.panel : siteColor(site))
                            .cornerRadius(3)
                    }
                }
            }

            HStack(spacing: 8) {
                ForEach([("RSL", "Riverside"), ("HBC", "Harbor"), ("PRP", "Pine Ridge"), ("ECH", "Eastside")], id: \.0) { code, name in
                    HStack(spacing: 3) { Circle().fill(siteColor(code)).frame(width: 6, height: 6); Text("\(code)=\(name)").font(.system(size: 7)).foregroundColor(Theme.muted) }
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }

    private func siteColor(_ code: String) -> Color {
        switch code {
        case "RSL": return Theme.red.opacity(0.7)
        case "HBC": return Theme.cyan.opacity(0.7)
        case "PRP": return Theme.gold.opacity(0.7)
        case "ECH": return Theme.green.opacity(0.7)
        default: return Theme.panel
        }
    }
}

// MARK: - ========== Scanner / QR Tools Tab ==========

#if os(iOS)
import AVFoundation
#endif

struct ScannerToolsView: View {
    @State private var activeTab = 0
    @State private var scannedCode: String?
    @State private var lookupResult: String?
    private let tabs = ["QR Scanner", "Blueprint", "Time-lapse", "Markup"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SCANNER & TOOLS").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.accent)
                        Text("Field Documentation").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                    }
                    Spacer()
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.accent)

                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button { withAnimation { activeTab = i } } label: {
                            Text(tabs[i].uppercased()).font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(activeTab == i ? .black : Theme.muted).frame(maxWidth: .infinity).padding(.vertical, 9).background(activeTab == i ? Theme.accent : Theme.surface)
                        }.buttonStyle(.plain)
                    }
                }.cornerRadius(8)

                if activeTab == 0 { qrScannerContent }
                else if activeTab == 1 { blueprintContent }
                else if activeTab == 2 { timelapseContent }
                else { markupContent }
            }.padding(16)
        }.background(Theme.bg)
    }

    private var qrScannerContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QR / BARCODE SCANNER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            RoundedRectangle(cornerRadius: 12).fill(Theme.panel).frame(height: 200)
                .overlay(VStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder").font(.system(size: 48)).foregroundColor(Theme.cyan.opacity(0.5))
                    Text("Point camera at equipment QR code").font(.system(size: 11)).foregroundColor(Theme.muted)
                    Text("Scans asset tags, material pallets, and permit stickers").font(.system(size: 9)).foregroundColor(Theme.muted)
                })

            if let code = scannedCode {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCANNED").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.green)
                    Text(code).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(Theme.text)
                    if let result = lookupResult { Text(result).font(.system(size: 10)).foregroundColor(Theme.muted) }
                }.padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
            }

            // Demo scan buttons
            HStack(spacing: 8) {
                Button { scannedCode = "EQ-001"; lookupResult = "CAT 320 Excavator \u{2022} Riverside Lofts \u{2022} 2,340 hrs" } label: {
                    Text("DEMO: Equipment").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan).padding(.horizontal, 10).padding(.vertical, 6).background(Theme.cyan.opacity(0.12)).cornerRadius(6)
                }.buttonStyle(.plain)
                Button { scannedCode = "PO-4422"; lookupResult = "Electrical Conduit 3/4\" EMT \u{2022} Graybar \u{2022} DELAYED" } label: {
                    Text("DEMO: Material").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.gold).padding(.horizontal, 10).padding(.vertical, 6).background(Theme.gold.opacity(0.12)).cornerRadius(6)
                }.buttonStyle(.plain)
                Button { scannedCode = "BP-2026-4821"; lookupResult = "Building Permit \u{2022} City of Houston \u{2022} ACTIVE exp 01/15/27" } label: {
                    Text("DEMO: Permit").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.green).padding(.horizontal, 10).padding(.vertical, 6).background(Theme.green.opacity(0.12)).cornerRadius(6)
                }.buttonStyle(.plain)
            }
        }
    }

    private var blueprintContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BLUEPRINT VIEWER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
            let plans: [(String, String, String, String)] = [("A-101","Floor Plan - Level 1","Architecture","Rev 4"),("A-102","Floor Plan - Level 2","Architecture","Rev 3"),("S-201","Foundation Plan","Structural","Rev 2"),("M-301","HVAC Layout - Level 1","Mechanical","Rev 5"),("E-401","Power Plan - Level 1","Electrical","Rev 3"),("P-501","Plumbing Riser Diagram","Plumbing","Rev 2")]
            ForEach(plans, id: \.0) { p in
                HStack(spacing: 8) {
                    Text(p.0).font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundColor(Theme.purple).frame(width: 40)
                    VStack(alignment: .leading, spacing: 1) { Text(p.1).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Text(p.2).font(.system(size: 8)).foregroundColor(Theme.muted) }
                    Spacer()
                    Text(p.3).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.cyan)
                    Button { ToastManager.shared.show("Coming soon") } label: { Text("VIEW").font(.system(size: 8, weight: .bold)).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 4).background(Theme.purple).cornerRadius(4) }.buttonStyle(.plain)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }
        }
    }

    private var timelapseContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TIME-LAPSE CAMERA").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
            Text("Scheduled site photo capture for progress documentation").font(.system(size: 9)).foregroundColor(Theme.muted)
            let cameras: [(String, String, String, Int)] = [("CAM-01","Riverside Lofts - North","Every 30 min",2847),("CAM-02","Harbor Crossing - East","Every 1 hr",1204),("CAM-03","Pine Ridge - Aerial","Every 15 min",5692)]
            ForEach(cameras, id: \.0) { c in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).fill(Theme.panel).frame(width: 48, height: 36)
                        .overlay(Image(systemName: "camera.fill").font(.system(size: 14)).foregroundColor(Theme.green.opacity(0.5)))
                    VStack(alignment: .leading, spacing: 2) { Text(c.1).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Text("\(c.0) \u{2022} \(c.2)").font(.system(size: 8)).foregroundColor(Theme.muted) }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) { Text("\(c.3)").font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.green); Text("PHOTOS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }
                }.padding(8).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    private var markupContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHOTO MARKUP").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.red)
            Text("Annotate site photos with arrows, circles, and text for deficiency tagging").font(.system(size: 9)).foregroundColor(Theme.muted)
            RoundedRectangle(cornerRadius: 12).fill(Theme.panel).frame(height: 180)
                .overlay(VStack(spacing: 8) {
                    Image(systemName: "pencil.and.outline").font(.system(size: 36)).foregroundColor(Theme.red.opacity(0.5))
                    Text("Tap to select a photo for markup").font(.system(size: 11)).foregroundColor(Theme.muted)
                })
            HStack(spacing: 8) {
                ForEach(["Arrow", "Circle", "Rectangle", "Text", "Measure"], id: \.self) { tool in
                    Button { ToastManager.shared.show("Coming soon") } label: {
                        Text(tool).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text)
                            .padding(.horizontal, 10).padding(.vertical, 6).background(Theme.surface).cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 0.8))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - ========== Schedule Hub (Gantt + Crew + Takeoff) ==========

struct ScheduleHubView: View {
    @State private var activeTab = 0
    private let tabs = ["Timeline", "Crew Calendar", "Cost Codes", "Takeoff", "Fuel Log", "Geofence", "Estimate", "Maintenance", "Prequal", "Reference"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SCHEDULE & PLANNING").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.accent)
                        Text("Project Planning Hub").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                    }
                    Spacer()
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.accent)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(tabs.indices, id: \.self) { i in
                            Button { withAnimation { activeTab = i } } label: {
                                Text(tabs[i].uppercased()).font(.system(size: 9, weight: .bold)).tracking(1)
                                    .foregroundColor(activeTab == i ? .black : Theme.muted)
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(activeTab == i ? Theme.accent : Theme.surface)
                            }.buttonStyle(.plain)
                        }
                    }.cornerRadius(8)
                }

                if activeTab == 0 { GanttChartView() }
                else if activeTab == 1 { CrewScheduleView() }
                else if activeTab == 2 { CostCodeView() }
                else if activeTab == 3 { MaterialTakeoffView() }
                else if activeTab == 4 { FuelLogView() }
                else if activeTab == 5 { geofenceContent }
                else if activeTab == 6 { EstimatingView() }
                else if activeTab == 7 { MaintenanceScheduleView() }
                else if activeTab == 8 { SubPrequalView() }
                else { ReferenceLibraryView() }
            }.padding(16)
        }.background(Theme.bg)
    }

    private var geofenceContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GEOFENCE ZONES").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
            Text("Auto clock-in/out when crew GPS enters or exits jobsite boundaries").font(.system(size: 9)).foregroundColor(Theme.muted)
            let zones: [(String, String, String, Int)] = [
                ("Riverside Lofts", "500 ft radius", "ACTIVE", 14),
                ("Harbor Crossing", "400 ft radius", "ACTIVE", 22),
                ("Pine Ridge Ph.2", "600 ft radius", "ACTIVE", 11),
                ("Eastside Civic Hub", "350 ft radius", "PAUSED", 0),
            ]
            ForEach(zones, id: \.0) { z in
                HStack(spacing: 8) {
                    Circle().fill(z.2 == "ACTIVE" ? Theme.green : Theme.muted).frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) { Text(z.0).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Text("\(z.1) \u{2022} \(z.3) crew inside").font(.system(size: 9)).foregroundColor(Theme.muted) }
                    Spacer()
                    Text(z.2).font(.system(size: 8, weight: .black)).foregroundColor(z.2 == "ACTIVE" ? Theme.green : Theme.muted)
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }
}

// MARK: - ========== Multi-Language Support ==========

enum AppLanguage: String, CaseIterable {
    case english = "English"
    case spanish = "Espa\u{00F1}ol"

    var code: String {
        switch self {
        case .english: return "en"
        case .spanish: return "es"
        }
    }
}

struct LocalizedStrings {
    static func get(_ key: String, language: AppLanguage = .english) -> String {
        let strings: [String: [String: String]] = [
            "command": ["en": "COMMAND", "es": "COMANDO"],
            "projects": ["en": "PROJECTS", "es": "PROYECTOS"],
            "contracts": ["en": "CONTRACTS", "es": "CONTRATOS"],
            "safety": ["en": "SAFETY", "es": "SEGURIDAD"],
            "crew": ["en": "CREW", "es": "EQUIPO"],
            "weather": ["en": "WEATHER", "es": "CLIMA"],
            "equipment": ["en": "EQUIPMENT", "es": "EQUIPO"],
            "schedule": ["en": "SCHEDULE", "es": "HORARIO"],
            "daily_log": ["en": "DAILY LOG", "es": "REGISTRO DIARIO"],
            "clock_in": ["en": "CLOCK IN", "es": "ENTRADA"],
            "clock_out": ["en": "CLOCK OUT", "es": "SALIDA"],
            "on_track": ["en": "ON TRACK", "es": "EN CAMINO"],
            "delayed": ["en": "DELAYED", "es": "RETRASADO"],
            "at_risk": ["en": "AT RISK", "es": "EN RIESGO"],
            "approved": ["en": "APPROVED", "es": "APROBADO"],
            "pending": ["en": "PENDING", "es": "PENDIENTE"],
            "urgent": ["en": "URGENT", "es": "URGENTE"],
            "search": ["en": "Search", "es": "Buscar"],
            "settings": ["en": "SETTINGS", "es": "CONFIGURACI\u{00D3}N"],
            "sign_out": ["en": "Sign Out", "es": "Cerrar Sesi\u{00F3}n"],
            "available": ["en": "Available", "es": "Disponible"],
            "total": ["en": "TOTAL", "es": "TOTAL"],
            "active": ["en": "ACTIVE", "es": "ACTIVO"],
            "completed": ["en": "COMPLETED", "es": "COMPLETADO"],
            "submit": ["en": "SUBMIT", "es": "ENVIAR"],
            "cancel": ["en": "Cancel", "es": "Cancelar"],
        ]
        return strings[key]?[language.code] ?? key
    }
}



// MARK: - ========== Estimating / Bid Builder ==========

struct EstimateLineItem: Identifiable, Codable {
    var id = UUID()
    let costCode: String
    let description: String
    let quantity: Double
    let unit: String
    let unitCost: Double
    var markup: Double = 15
    var total: Double { quantity * unitCost }
    var withMarkup: Double { total * (1 + markup / 100) }
}

struct EstimatingView: View {
    @State private var items: [EstimateLineItem] = [
        EstimateLineItem(costCode: "03 30 00", description: "Cast-in-Place Concrete", quantity: 240, unit: "CY", unitCost: 185),
        EstimateLineItem(costCode: "05 12 00", description: "Structural Steel Framing", quantity: 48, unit: "TON", unitCost: 3200),
        EstimateLineItem(costCode: "06 11 00", description: "Wood Framing", quantity: 12400, unit: "BF", unitCost: 1.85),
        EstimateLineItem(costCode: "09 29 00", description: "Gypsum Board", quantity: 18500, unit: "SF", unitCost: 2.40),
        EstimateLineItem(costCode: "22 11 00", description: "Plumbing Piping", quantity: 1, unit: "LS", unitCost: 142000),
        EstimateLineItem(costCode: "26 05 00", description: "Electrical Wiring", quantity: 1, unit: "LS", unitCost: 198000),
    ]
    @State private var projectName = "New Project Estimate"
    @State private var globalMarkup = 15.0

    private var subtotal: Double { items.reduce(0) { $0 + $1.total } }
    private var totalWithMarkup: Double { items.reduce(0) { $0 + $1.withMarkup } }
    private var profit: Double { totalWithMarkup - subtotal }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BID ESTIMATOR").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
                Spacer()
                Text("$\(String(format: "%.0f", totalWithMarkup/1000))K BID TOTAL")
                    .font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.accent)
            }

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("$\(String(format: "%.0f", subtotal/1000))K").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.cyan); Text("COST").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("$\(String(format: "%.0f", profit/1000))K").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.green); Text("PROFIT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("\(String(format: "%.1f", profit/subtotal*100))%").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.gold); Text("MARGIN").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.gold.opacity(0.06)).cornerRadius(8)
            }

            ForEach(items) { item in
                HStack(spacing: 6) {
                    Text(item.costCode).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundColor(Theme.gold).frame(width: 55, alignment: .leading)
                    Text(item.description).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                    Spacer()
                    Text("\(String(format: "%.0f", item.quantity)) \(item.unit)").font(.system(size: 8)).foregroundColor(Theme.muted)
                    Text("$\(String(format: "%.0f", item.total/1000))K").font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.accent)
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12).premiumGlow(cornerRadius: 12, color: Theme.gold)
    }
}

// MARK: - ========== Equipment Maintenance Scheduler ==========

struct MaintenanceItem: Identifiable {
    let id = UUID()
    let equipment: String; let task: String; let interval: String
    let lastDone: String; let nextDue: String; let hoursRemaining: Int; let status: String
}

struct MaintenanceScheduleView: View {
    private let items: [MaintenanceItem] = [
        MaintenanceItem(equipment: "CAT 320 Excavator", task: "Engine Oil & Filter", interval: "Every 500 hrs", lastDone: "Mar 10", nextDue: "50 hrs", hoursRemaining: 50, status: "DUE SOON"),
        MaintenanceItem(equipment: "CAT 320 Excavator", task: "Hydraulic Filter", interval: "Every 1000 hrs", lastDone: "Jan 15", nextDue: "160 hrs", hoursRemaining: 160, status: "OK"),
        MaintenanceItem(equipment: "JLG 600S Boom Lift", task: "Annual Inspection", interval: "Yearly", lastDone: "Aug 22", nextDue: "Aug 2026", hoursRemaining: 999, status: "OK"),
        MaintenanceItem(equipment: "Bobcat S770", task: "Engine Oil & Filter", interval: "Every 250 hrs", lastDone: "Mar 1", nextDue: "10 hrs", hoursRemaining: 10, status: "OVERDUE"),
        MaintenanceItem(equipment: "Bobcat S770", task: "Drive Belt", interval: "Every 1500 hrs", lastDone: "Nov 20", nextDue: "440 hrs", hoursRemaining: 440, status: "OK"),
        MaintenanceItem(equipment: "Wacker Compactor", task: "Air Filter", interval: "Every 100 hrs", lastDone: "Mar 18", nextDue: "80 hrs", hoursRemaining: 80, status: "OK"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MAINTENANCE SCHEDULE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
                Spacer()
                let overdue = items.filter { $0.status == "OVERDUE" }.count
                let dueSoon = items.filter { $0.status == "DUE SOON" }.count
                if overdue > 0 { Text("\(overdue) OVERDUE").font(.system(size: 8, weight: .black)).foregroundColor(.black).padding(.horizontal, 6).padding(.vertical, 2).background(Theme.red).cornerRadius(3) }
                if dueSoon > 0 { Text("\(dueSoon) DUE SOON").font(.system(size: 8, weight: .black)).foregroundColor(.black).padding(.horizontal, 6).padding(.vertical, 2).background(Theme.gold).cornerRadius(3) }
            }
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Circle().fill(item.status == "OVERDUE" ? Theme.red : item.status == "DUE SOON" ? Theme.gold : Theme.green).frame(width: 6, height: 6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.equipment).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                        Text("\(item.task) \u{2022} \(item.interval)").font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text(item.nextDue).font(.system(size: 9, weight: .heavy)).foregroundColor(item.status == "OVERDUE" ? Theme.red : item.status == "DUE SOON" ? Theme.gold : Theme.muted)
                    Text(item.status).font(.system(size: 7, weight: .black)).foregroundColor(item.status == "OVERDUE" ? Theme.red : item.status == "DUE SOON" ? Theme.gold : Theme.green)
                }.padding(8).background(item.status == "OVERDUE" ? Theme.red.opacity(0.04) : Theme.surface).cornerRadius(6)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }
}

// MARK: - ========== Subcontractor Prequalification ==========

struct SubPrequalView: View {
    private let subs: [(name: String, trade: String, emr: Double, bondLimit: String, yearsInBiz: Int, financialRating: String, references: Int, score: Int)] = [
        ("Apex Concrete LLC", "Concrete", 0.82, "$2M", 18, "A", 12, 94),
        ("Elite Steel Works", "Steel", 0.95, "$5M", 22, "A+", 18, 91),
        ("Prime Electric Inc", "Electrical", 1.12, "$1M", 11, "B+", 8, 78),
        ("Quick Plumbing", "Plumbing", 0.88, "$500K", 8, "B", 6, 72),
        ("Delta Drywall", "Drywall", 1.35, "$750K", 5, "B-", 4, 58),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SUBCONTRACTOR PREQUALIFICATION").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
            Text("EMR, bonding, financial strength, and reference scoring").font(.system(size: 9)).foregroundColor(Theme.muted)
            ForEach(subs, id: \.name) { sub in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(sub.name).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                        Text(sub.trade).font(.system(size: 8)).foregroundColor(Theme.muted)
                        Spacer()
                        Text("\(sub.score)/100").font(.system(size: 13, weight: .heavy)).foregroundColor(sub.score >= 80 ? Theme.green : sub.score >= 60 ? Theme.gold : Theme.red)
                    }
                    HStack(spacing: 12) {
                        VStack(spacing: 1) { Text("EMR").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text(String(format: "%.2f", sub.emr)).font(.system(size: 10, weight: .heavy)).foregroundColor(sub.emr <= 1.0 ? Theme.green : Theme.red) }
                        VStack(spacing: 1) { Text("BOND").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text(sub.bondLimit).font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.cyan) }
                        VStack(spacing: 1) { Text("YEARS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text("\(sub.yearsInBiz)").font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.accent) }
                        VStack(spacing: 1) { Text("FINANCIAL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text(sub.financialRating).font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.gold) }
                        VStack(spacing: 1) { Text("REFS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text("\(sub.references)").font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.purple) }
                    }
                    // Score bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(Theme.border.opacity(0.3)).frame(height: 4)
                            RoundedRectangle(cornerRadius: 2).fill(sub.score >= 80 ? Theme.green : sub.score >= 60 ? Theme.gold : Theme.red)
                                .frame(width: geo.size.width * CGFloat(sub.score) / 100, height: 4)
                        }
                    }.frame(height: 4)
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }
}

// MARK: - ========== Construction Reference Library ==========

struct ReferenceLibraryView: View {
    @State private var activeRef = 0
    private let refs = ["Concrete Mixes", "Steel Weights", "Soil Types", "OSHA Violations", "Wage Rates"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONSTRUCTION REFERENCE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(refs.indices, id: \.self) { i in
                        Button { activeRef = i } label: {
                            Text(refs[i]).font(.system(size: 8, weight: .bold))
                                .foregroundColor(activeRef == i ? .black : Theme.text)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(activeRef == i ? Theme.cyan : Theme.panel).cornerRadius(5)
                        }.buttonStyle(.plain)
                    }
                }
            }

            if activeRef == 0 { concreteMixes }
            else if activeRef == 1 { steelWeights }
            else if activeRef == 2 { soilTypes }
            else if activeRef == 3 { oshaViolations }
            else { wageRates }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }

    private var concreteMixes: some View {
        let mixes: [(String, String, String, String, String)] = [
            ("3000 PSI", "General slabs, footings", "4\" slump", "5-7% air", "Type I/II"),
            ("4000 PSI", "Structural, foundations", "4\" slump", "5-7% air", "Type I/II"),
            ("5000 PSI", "Columns, high-load", "4\" slump", "5-7% air", "Type I"),
            ("6000 PSI", "Post-tension, precast", "6\" slump", "3-5% air", "Type III"),
            ("SCC Mix", "Self-consolidating", "24\"+ spread", "2-4% air", "Type I + fly ash"),
        ]
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(mixes, id: \.0) { m in
                HStack(spacing: 8) {
                    Text(m.0).font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.accent).frame(width: 60, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(m.1).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text)
                        Text("Slump: \(m.2) \u{2022} Air: \(m.3) \u{2022} Cement: \(m.4)").font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                }.padding(6).background(Theme.panel).cornerRadius(5)
            }
        }
    }

    private var steelWeights: some View {
        let shapes: [(String, String, String)] = [
            ("W8x31", "Wide Flange", "31 lb/ft"), ("W10x49", "Wide Flange", "49 lb/ft"),
            ("W12x65", "Wide Flange", "65 lb/ft"), ("W14x90", "Wide Flange", "90 lb/ft"),
            ("HSS 6x6x1/4", "Tube Steel", "19.02 lb/ft"), ("HSS 8x8x3/8", "Tube Steel", "37.69 lb/ft"),
            ("L4x4x1/4", "Angle", "6.6 lb/ft"), ("L6x6x3/8", "Angle", "14.9 lb/ft"),
            ("#4 Rebar", "Reinforcing", "0.668 lb/ft"), ("#5 Rebar", "Reinforcing", "1.043 lb/ft"),
        ]
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(shapes, id: \.0) { s in
                HStack {
                    Text(s.0).font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundColor(Theme.cyan).frame(width: 90, alignment: .leading)
                    Text(s.1).font(.system(size: 9)).foregroundColor(Theme.muted)
                    Spacer()
                    Text(s.2).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.accent)
                }
            }
        }
    }

    private var soilTypes: some View {
        let soils: [(String, String, String, String)] = [
            ("GW", "Well-graded gravel", "600+ psf", "Excellent"),
            ("GP", "Poorly-graded gravel", "500 psf", "Good"),
            ("SW", "Well-graded sand", "400 psf", "Good"),
            ("SP", "Poorly-graded sand", "300 psf", "Fair"),
            ("CL", "Lean clay", "200 psf", "Fair"),
            ("CH", "Fat clay", "150 psf", "Poor"),
            ("OH", "Organic clay", "100 psf", "Very Poor"),
            ("PT", "Peat", "N/A", "Unsuitable"),
        ]
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(soils, id: \.0) { s in
                HStack(spacing: 8) {
                    Text(s.0).font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundColor(Theme.gold).frame(width: 25)
                    Text(s.1).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text).frame(width: 110, alignment: .leading)
                    Text(s.2).font(.system(size: 9)).foregroundColor(Theme.cyan)
                    Spacer()
                    Text(s.3).font(.system(size: 8, weight: .bold)).foregroundColor(s.3 == "Excellent" || s.3 == "Good" ? Theme.green : s.3 == "Fair" ? Theme.gold : Theme.red)
                }
            }
        }
    }

    private var oshaViolations: some View {
        let violations: [(String, String, String)] = [
            ("1926.501", "Fall Protection", "$15,625 per violation"),
            ("1926.451", "Scaffolding", "$15,625 per violation"),
            ("1926.1053", "Ladders", "$15,625 per violation"),
            ("1926.503", "Fall Protection Training", "$15,625 per violation"),
            ("1910.1200", "Hazard Communication", "$15,625 per violation"),
            ("1926.20", "Safety Programs", "$15,625 per violation"),
            ("1926.100", "Head Protection", "$15,625 per violation"),
            ("1926.502", "Fall Protection Systems", "$15,625 per violation"),
        ]
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(violations, id: \.0) { v in
                HStack(spacing: 8) {
                    Text(v.0).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(Theme.red).frame(width: 70, alignment: .leading)
                    Text(v.1).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text)
                    Spacer()
                    Text(v.2).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold)
                }
            }
        }
    }

    private var wageRates: some View {
        let rates: [(String, String, String, String)] = [
            ("Electrician", "TX - Harris County", "$42.50/hr", "$63.75 OT"),
            ("Plumber", "TX - Harris County", "$40.25/hr", "$60.38 OT"),
            ("Ironworker", "TX - Harris County", "$38.90/hr", "$58.35 OT"),
            ("Carpenter", "TX - Harris County", "$35.75/hr", "$53.63 OT"),
            ("Laborer", "TX - Harris County", "$28.50/hr", "$42.75 OT"),
            ("Cement Mason", "TX - Harris County", "$32.00/hr", "$48.00 OT"),
            ("Operating Engineer", "TX - Harris County", "$44.00/hr", "$66.00 OT"),
            ("Painter", "TX - Harris County", "$30.25/hr", "$45.38 OT"),
        ]
        return VStack(alignment: .leading, spacing: 6) {
            Text("DAVIS-BACON PREVAILING WAGES").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
            ForEach(rates, id: \.0) { r in
                HStack(spacing: 8) {
                    Text(r.0).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text).frame(width: 90, alignment: .leading)
                    Text(r.1).font(.system(size: 8)).foregroundColor(Theme.muted)
                    Spacer()
                    Text(r.2).font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.green)
                    Text(r.3).font(.system(size: 8)).foregroundColor(Theme.gold)
                }
            }
        }
    }
}
