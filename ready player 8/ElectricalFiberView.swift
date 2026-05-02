import Foundation
import SwiftUI

// MARK: - ========== Electrician & Fiber Installation Tab ==========

// MARK: - Data Models

struct ElectricalContractor: Identifiable {
    let id = UUID()
    let name: String
    let company: String
    let trade: ElectricalTrade
    let licenseType: String
    let licenseNumber: String
    let licenseState: String
    let isVerified: Bool
    let rating: Double
    let reviewCount: Int
    let hourlyRate: String
    let yearsExperience: Int
    let serviceArea: String
    let certifications: [String]
    let specialties: [String]
    let available: Bool
    let responseTime: String
    let completedJobs: Int
    let insuranceVerified: Bool
    let bondAmount: String
    let initials: String
}

enum ElectricalTrade: String, CaseIterable {
    case electrician = "Electrician"
    case fiberInstaller = "Fiber Installer"
    case lowVoltage = "Low Voltage"
    case solarInstaller = "Solar Installer"
    case generatorTech = "Generator Tech"
    case fireAlarm = "Fire Alarm"

    var icon: String {
        switch self {
        case .electrician: return "\u{26A1}"
        case .fiberInstaller: return "\u{1F310}"
        case .lowVoltage: return "\u{1F50C}"
        case .solarInstaller: return "\u{2600}\u{FE0F}"
        case .generatorTech: return "\u{1F50B}"
        case .fireAlarm: return "\u{1F6A8}"
        }
    }

    var color: Color {
        switch self {
        case .electrician: return Theme.gold
        case .fiberInstaller: return Theme.cyan
        case .lowVoltage: return Theme.purple
        case .solarInstaller: return Color.orange
        case .generatorTech: return Theme.green
        case .fireAlarm: return Theme.red
        }
    }
}

struct ElectricalLead: Identifiable, Codable {
    var id = UUID()
    let title: String
    let tradeType: String
    let description: String
    let location: String
    let budget: String
    let urgency: String
    let postedBy: String
    let postedAt: Date
    var bidsReceived: Int
    var status: String
}

struct FiberProject: Identifiable {
    let id = UUID()
    let projectName: String
    let isp: String
    let fiberType: String
    let distance: String
    let spliceCount: Int
    let permitStatus: String
    let testResults: String
    let status: String
    let completionPercent: Int
}

// 999.5 (d) Tier 3: bundle-gated.
#if DEBUG
private let mockElectricalContractors: [ElectricalContractor] = [
    ElectricalContractor(name: "Marcus Johnson", company: "PowerGrid Electric", trade: .electrician, licenseType: "Master Electrician", licenseNumber: "ME-48291", licenseState: "TX", isVerified: true, rating: 4.9, reviewCount: 147, hourlyRate: "$95/hr", yearsExperience: 22, serviceArea: "Houston Metro", certifications: ["Master Electrician", "OSHA 30", "NFPA 70E"], specialties: ["Commercial TI", "Industrial Controls", "Emergency Power"], available: true, responseTime: "< 2 hrs", completedJobs: 312, insuranceVerified: true, bondAmount: "$500K", initials: "MJ"),
    ElectricalContractor(name: "Sarah Chen", company: "FiberLink Solutions", trade: .fiberInstaller, licenseType: "BICSI RCDD", licenseNumber: "RCDD-19847", licenseState: "CA", isVerified: true, rating: 4.8, reviewCount: 93, hourlyRate: "$110/hr", yearsExperience: 15, serviceArea: "Bay Area", certifications: ["BICSI RCDD", "CFOT", "OSHA 10"], specialties: ["Data Center", "Campus Fiber", "FTTH", "OTDR Testing"], available: true, responseTime: "< 4 hrs", completedJobs: 198, insuranceVerified: true, bondAmount: "$1M", initials: "SC"),
    ElectricalContractor(name: "Andre Williams", company: "Volt Masters", trade: .electrician, licenseType: "Journeyman Electrician", licenseNumber: "JE-73920", licenseState: "FL", isVerified: true, rating: 4.7, reviewCount: 68, hourlyRate: "$72/hr", yearsExperience: 11, serviceArea: "Miami-Dade", certifications: ["Journeyman Electrician", "EPA 608", "OSHA 10"], specialties: ["Residential", "Multifamily", "Service Upgrades"], available: false, responseTime: "< 6 hrs", completedJobs: 156, insuranceVerified: true, bondAmount: "$250K", initials: "AW"),
    ElectricalContractor(name: "Priya Patel", company: "LightSpeed Fiber", trade: .fiberInstaller, licenseType: "BICSI TECH", licenseNumber: "BT-28461", licenseState: "NY", isVerified: true, rating: 4.9, reviewCount: 112, hourlyRate: "$105/hr", yearsExperience: 13, serviceArea: "NYC Metro", certifications: ["BICSI TECH", "CFOT", "CPCT"], specialties: ["MDU Fiber", "5G Small Cell", "Structured Cabling"], available: true, responseTime: "< 3 hrs", completedJobs: 241, insuranceVerified: true, bondAmount: "$750K", initials: "PP"),
    ElectricalContractor(name: "Derek Torres", company: "SunVolt Energy", trade: .solarInstaller, licenseType: "NABCEP Certified", licenseNumber: "NB-58392", licenseState: "AZ", isVerified: true, rating: 4.8, reviewCount: 76, hourlyRate: "$85/hr", yearsExperience: 9, serviceArea: "Phoenix Metro", certifications: ["NABCEP PV", "Master Electrician", "OSHA 30"], specialties: ["Commercial Solar", "Battery Storage", "EV Charging"], available: true, responseTime: "< 4 hrs", completedJobs: 134, insuranceVerified: true, bondAmount: "$500K", initials: "DT"),
    ElectricalContractor(name: "Kim Nguyen", company: "SecureWire Systems", trade: .lowVoltage, licenseType: "Low Voltage License", licenseNumber: "LV-41293", licenseState: "WA", isVerified: true, rating: 4.6, reviewCount: 54, hourlyRate: "$68/hr", yearsExperience: 8, serviceArea: "Seattle Metro", certifications: ["Low Voltage", "NICET Level II", "BICSI TECH"], specialties: ["Security Systems", "Access Control", "AV Install"], available: true, responseTime: "< 4 hrs", completedJobs: 89, insuranceVerified: true, bondAmount: "$200K", initials: "KN"),
    ElectricalContractor(name: "James O'Brien", company: "FireShield Electric", trade: .fireAlarm, licenseType: "NICET Level III", licenseNumber: "NI-29384", licenseState: "IL", isVerified: true, rating: 4.9, reviewCount: 88, hourlyRate: "$90/hr", yearsExperience: 18, serviceArea: "Chicago Metro", certifications: ["NICET III Fire Alarm", "Master Electrician", "OSHA 30"], specialties: ["Fire Alarm Design", "Mass Notification", "Inspection/Testing"], available: true, responseTime: "< 2 hrs", completedJobs: 267, insuranceVerified: true, bondAmount: "$1M", initials: "JO"),
    ElectricalContractor(name: "Carlos Reyes", company: "GenPower Services", trade: .generatorTech, licenseType: "Master Electrician", licenseNumber: "ME-67284", licenseState: "TX", isVerified: true, rating: 4.7, reviewCount: 41, hourlyRate: "$88/hr", yearsExperience: 14, serviceArea: "Dallas-Fort Worth", certifications: ["Generac Certified", "Kohler Authorized", "Master Electrician"], specialties: ["Standby Generators", "Transfer Switches", "Load Management"], available: true, responseTime: "< 3 hrs", completedJobs: 178, insuranceVerified: true, bondAmount: "$500K", initials: "CR"),
]
#else
private let mockElectricalContractors: [ElectricalContractor] = []
#endif

#if DEBUG
private let mockFiberProjects: [FiberProject] = [
    FiberProject(projectName: "Downtown Office FTTH", isp: "AT&T Fiber", fiberType: "Single-Mode OS2", distance: "2,400 ft", spliceCount: 48, permitStatus: "APPROVED", testResults: "OTDR Pass -0.3dB avg", status: "In Progress", completionPercent: 72),
    FiberProject(projectName: "Metro Campus Backbone", isp: "Spectrum Enterprise", fiberType: "Multi-Mode OM4", distance: "8,200 ft", spliceCount: 192, permitStatus: "APPROVED", testResults: "Pending", status: "Splicing", completionPercent: 45),
    FiberProject(projectName: "Industrial Park 5G", isp: "Verizon Business", fiberType: "Single-Mode OS2", distance: "14,800 ft", spliceCount: 384, permitStatus: "PENDING", testResults: "N/A", status: "Permitting", completionPercent: 15),
]
#else
private let mockFiberProjects: [FiberProject] = []
#endif

// MARK: - Electrician & Fiber Main View

struct ElectricalFiberView: View {
    @State private var activeSubTab: ElecSubTab = .directory
    @State private var searchQuery = ""
    @State private var selectedTrade: ElectricalTrade? = nil
    @State private var leads: [ElectricalLead] = loadJSON("ConstructOS.Electrical.Leads", default: [ElectricalLead]())
    @State private var showPostLead = false

    enum ElecSubTab: String, CaseIterable {
        case directory = "Directory"
        case leads = "Leads"
        case fiber = "Fiber"
        case emergency = "Emergency"
        case verify = "Verify"
    }

    private var filteredContractors: [ElectricalContractor] {
        var list = mockElectricalContractors
        if let trade = selectedTrade { list = list.filter { $0.trade == trade } }
        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            list = list.filter { $0.name.lowercased().contains(q) || $0.company.lowercased().contains(q) || $0.specialties.joined().lowercased().contains(q) || $0.serviceArea.lowercased().contains(q) }
        }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("\u{26A1}").font(.system(size: 18))
                            Text("ELECTRICAL & FIBER").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.gold)
                        }
                        Text("Contractor Network")
                            .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("Licensed electricians, fiber installers, and trade specialists")
                            .font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(mockElectricalContractors.filter { $0.available }.count)").font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.green)
                        Text("AVAILABLE").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                    }
                }
                .padding(16).background(Theme.surface).cornerRadius(14)
                .premiumGlow(cornerRadius: 14, color: Theme.gold)

                // Sub-tabs
                HStack(spacing: 0) {
                    ForEach(ElecSubTab.allCases, id: \.self) { tab in
                        Button { withAnimation { activeSubTab = tab } } label: {
                            Text(tab.rawValue.uppercased())
                                .font(.system(size: 9, weight: .bold)).tracking(1)
                                .foregroundColor(activeSubTab == tab ? .black : Theme.muted)
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                .background(activeSubTab == tab ? Theme.gold : Theme.surface)
                        }.buttonStyle(.plain)
                    }
                }.cornerRadius(8)

                switch activeSubTab {
                case .directory: directoryContent
                case .leads: leadsContent
                case .fiber: fiberContent
                case .emergency: emergencyContent
                case .verify: verifyContent
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
        .onAppear { leads = loadJSON("ConstructOS.Electrical.Leads", default: [ElectricalLead]()) }
        .sheet(isPresented: $showPostLead) { PostLeadSheet { lead in leads.insert(lead, at: 0); saveJSON("ConstructOS.Electrical.Leads", value: leads); showPostLead = false } }
    }

    // MARK: Directory
    private var directoryContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(Theme.muted)
                TextField("Search electricians, fiber, specialties...", text: $searchQuery)
                    .font(.system(size: 12)).foregroundColor(Theme.text)
            }
            .padding(10).background(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Button { selectedTrade = nil } label: {
                        Text("ALL").font(.system(size: 9, weight: .bold))
                            .foregroundColor(selectedTrade == nil ? .black : Theme.text)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(selectedTrade == nil ? Theme.gold : Theme.surface).cornerRadius(6)
                    }.buttonStyle(.plain)
                    ForEach(ElectricalTrade.allCases, id: \.rawValue) { trade in
                        Button { selectedTrade = selectedTrade == trade ? nil : trade } label: {
                            HStack(spacing: 3) {
                                Text(trade.icon).font(.system(size: 10))
                                Text(trade.rawValue).font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(selectedTrade == trade ? .black : trade.color)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(selectedTrade == trade ? trade.color : trade.color.opacity(0.12)).cornerRadius(6)
                        }.buttonStyle(.plain)
                    }
                }
            }

            ForEach(filteredContractors) { contractor in
                ContractorCard(contractor: contractor)
            }
        }
    }

    // MARK: Leads
    private var leadsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ACTIVE LEADS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
                Spacer()
                Button { showPostLead = true } label: {
                    Label("POST JOB", systemImage: "plus.circle.fill")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Theme.accent).cornerRadius(6)
                }.buttonStyle(.plain)
            }

            if leads.isEmpty {
                VStack(spacing: 8) {
                    Text("\u{1F4CB}").font(.system(size: 36))
                    Text("No active leads").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted)
                    Text("Post a job to receive bids from verified contractors").font(.system(size: 11)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(24).background(Theme.surface).cornerRadius(12)
            } else {
                ForEach(leads) { lead in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(lead.title).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                            Spacer()
                            Text(lead.urgency.uppercased()).font(.system(size: 8, weight: .black))
                                .foregroundColor(lead.urgency == "urgent" ? Theme.red : Theme.gold)
                        }
                        Text(lead.description).font(.system(size: 10)).foregroundColor(Theme.muted).lineLimit(2)
                        HStack(spacing: 10) {
                            Label(lead.location, systemImage: "mappin").font(.system(size: 9)).foregroundColor(Theme.muted)
                            Label(lead.budget, systemImage: "dollarsign.circle").font(.system(size: 9)).foregroundColor(Theme.accent)
                            Spacer()
                            Text("\(lead.bidsReceived) bids").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan)
                        }
                    }
                    .padding(12).background(Theme.surface).cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.3), lineWidth: 0.8))
                }
            }
        }
    }

    // MARK: Fiber Projects
    private var fiberContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FIBER PROJECTS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)

            ForEach(mockFiberProjects) { project in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(project.projectName).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                        Spacer()
                        Text("\(project.completionPercent)%").font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.cyan)
                    }
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Theme.border.opacity(0.3)).frame(height: 5)
                            RoundedRectangle(cornerRadius: 3).fill(Theme.cyan)
                                .frame(width: geo.size.width * CGFloat(project.completionPercent) / 100, height: 5)
                        }
                    }.frame(height: 5)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 1) { Text("ISP").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text(project.isp).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text) }
                        VStack(alignment: .leading, spacing: 1) { Text("FIBER").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text(project.fiberType).font(.system(size: 9)).foregroundColor(Theme.text) }
                        VStack(alignment: .leading, spacing: 1) { Text("DISTANCE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text(project.distance).font(.system(size: 9)).foregroundColor(Theme.text) }
                        VStack(alignment: .leading, spacing: 1) { Text("SPLICES").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text("\(project.spliceCount)").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.accent) }
                    }

                    HStack(spacing: 8) {
                        Label(project.permitStatus, systemImage: "doc.badge.gearshape").font(.system(size: 8, weight: .bold))
                            .foregroundColor(project.permitStatus == "APPROVED" ? Theme.green : Theme.gold)
                        if project.testResults != "N/A" && project.testResults != "Pending" {
                            Label(project.testResults, systemImage: "checkmark.seal").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.green)
                        }
                        Spacer()
                        Text(project.status.uppercased()).font(.system(size: 8, weight: .black))
                            .foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 3)
                            .background(project.completionPercent > 50 ? Theme.green : Theme.gold).cornerRadius(4)
                    }
                }
                .padding(12).background(Theme.surface).cornerRadius(10)
                .premiumGlow(cornerRadius: 10, color: Theme.cyan)
            }
        }
    }

    // MARK: Emergency
    private var emergencyContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\u{1F6A8} EMERGENCY DISPATCH").font(.system(size: 12, weight: .black)).tracking(1).foregroundColor(Theme.red)
                Spacer()
            }
            Text("Request urgent electrical or fiber service. Available contractors with fastest response times shown first.")
                .font(.system(size: 10)).foregroundColor(Theme.muted)

            ForEach(mockElectricalContractors.filter { $0.available }.sorted { $0.responseTime < $1.responseTime }) { contractor in
                HStack(spacing: 10) {
                    Circle().fill(Theme.green).frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contractor.name).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                        Text("\(contractor.trade.rawValue) \u{2022} \(contractor.company)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(contractor.responseTime).font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.green)
                        Text(contractor.hourlyRate).font(.system(size: 9)).foregroundColor(Theme.accent)
                    }
                    Button { ToastManager.shared.show("Coming soon") } label: {
                        Text("DISPATCH").font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 6).background(Theme.red).cornerRadius(6)
                    }.buttonStyle(.plain)
                }
                .padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    // MARK: Verify
    private var verifyContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LICENSE VERIFICATION").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
            Text("Verify contractor licenses, insurance, and bonding before hiring")
                .font(.system(size: 10)).foregroundColor(Theme.muted)

            ForEach(mockElectricalContractors) { contractor in
                HStack(spacing: 10) {
                    Image(systemName: contractor.isVerified ? "checkmark.shield.fill" : "shield.slash")
                        .font(.system(size: 16)).foregroundColor(contractor.isVerified ? Theme.green : Theme.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contractor.name).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                        Text("\(contractor.licenseType) \u{2022} \(contractor.licenseNumber) \u{2022} \(contractor.licenseState)")
                            .font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Circle().fill(contractor.insuranceVerified ? Theme.green : Theme.red).frame(width: 5, height: 5)
                            Text("INSURED").font(.system(size: 7, weight: .bold)).foregroundColor(contractor.insuranceVerified ? Theme.green : Theme.red)
                        }
                        Text("Bond: \(contractor.bondAmount)").font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                }
                .padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }
}

// MARK: Contractor Card
struct ContractorCard: View {
    let contractor: ElectricalContractor
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle().fill(LinearGradient(colors: [contractor.trade.color, Theme.gold], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(Text(contractor.initials).font(.system(size: 12, weight: .heavy)).foregroundColor(.white))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(contractor.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                        if contractor.isVerified { Image(systemName: "checkmark.seal.fill").font(.system(size: 9)).foregroundColor(Theme.green) }
                        if contractor.available { Circle().fill(Theme.green).frame(width: 5, height: 5) }
                    }
                    Text("\(contractor.company) \u{2022} \(contractor.trade.rawValue)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    Text(contractor.certifications.joined(separator: " \u{2022} ")).font(.system(size: 8)).foregroundColor(Theme.muted).lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(contractor.hourlyRate).font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.accent)
                    HStack(spacing: 2) {
                        Text("\(String(format: "%.1f", contractor.rating))").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.gold)
                        Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(Theme.gold)
                        Text("(\(contractor.reviewCount))").font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                }
            }

            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 16) {
                        VStack(spacing: 2) { Text("\(contractor.yearsExperience)").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.accent); Text("YEARS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }
                        VStack(spacing: 2) { Text("\(contractor.completedJobs)").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.green); Text("JOBS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }
                        VStack(spacing: 2) { Text(contractor.responseTime).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.cyan); Text("RESPONSE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }
                        VStack(spacing: 2) { Text(contractor.bondAmount).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.gold); Text("BOND").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }
                    }
                    Text("SPECIALTIES: \(contractor.specialties.joined(separator: ", "))").font(.system(size: 9)).foregroundColor(Theme.muted)
                    Text("SERVICE AREA: \(contractor.serviceArea)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    Text("LICENSE: \(contractor.licenseType) #\(contractor.licenseNumber) (\(contractor.licenseState))").font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.muted)

                    HStack(spacing: 6) {
                        Button { ToastManager.shared.show("Coming soon") } label: { Text("REQUEST QUOTE").font(.system(size: 9, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 7).background(Theme.accent).cornerRadius(6) }.buttonStyle(.plain)
                        Button { ToastManager.shared.show("Coming soon") } label: { Text("VIEW PROFILE").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan).frame(maxWidth: .infinity).padding(.vertical, 7).background(Theme.cyan.opacity(0.12)).cornerRadius(6) }.buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack {
                Text(contractor.trade.icon).font(.system(size: 10))
                Text(contractor.serviceArea).font(.system(size: 9)).foregroundColor(Theme.muted)
                Spacer()
                Button { withAnimation { expanded.toggle() } } label: {
                    Text(expanded ? "LESS" : "MORE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.accent)
                }.buttonStyle(.plain)
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(contractor.available ? Theme.green.opacity(0.2) : Theme.border.opacity(0.3), lineWidth: 0.8))
    }
}

// MARK: Post Lead Sheet
struct PostLeadSheet: View {
    let onSubmit: (ElectricalLead) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""; @State private var tradeType = "Electrician"
    @State private var desc = ""; @State private var location = ""
    @State private var budget = ""; @State private var urgency = "normal"

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("POST A JOB LEAD").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.text)
                        TextField("Job title", text: $title).font(.system(size: 13)).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                        TextEditor(text: $desc).font(.system(size: 12)).foregroundColor(Theme.text).scrollContentBackground(.hidden).background(Theme.surface).frame(height: 80).padding(6).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                        HStack(spacing: 8) {
                            TextField("Location", text: $location).font(.system(size: 13)).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                            TextField("Budget", text: $budget).font(.system(size: 13)).frame(width: 100).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                        }
                        HStack(spacing: 6) {
                            ForEach(["normal", "urgent", "emergency"], id: \.self) { u in
                                Button { urgency = u } label: {
                                    Text(u.uppercased()).font(.system(size: 9, weight: .bold))
                                        .foregroundColor(urgency == u ? .black : Theme.text)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(urgency == u ? (u == "emergency" ? Theme.red : u == "urgent" ? Theme.gold : Theme.accent) : Theme.surface).cornerRadius(6)
                                }.buttonStyle(.plain)
                            }
                        }
                        Button {
                            guard !title.isEmpty else { return }
                            onSubmit(ElectricalLead(title: title, tradeType: tradeType, description: desc, location: location, budget: budget, urgency: urgency, postedBy: "You", postedAt: Date(), bidsReceived: 0, status: "open"))
                        } label: {
                            Text("POST LEAD").font(.system(size: 13, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 14).background(Theme.accent).cornerRadius(10)
                        }.buttonStyle(.plain)
                    }.padding(20)
                }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) } }
        }.preferredColorScheme(.dark)
    }
}
