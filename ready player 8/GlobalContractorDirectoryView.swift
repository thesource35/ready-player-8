import SwiftUI

// MARK: - ========== Global Contractor Directory ==========

enum ContractorTrade: String, CaseIterable, Identifiable {
    case generalContractor = "General Contractor"
    case concrete = "Concrete"
    case steel = "Structural Steel"
    case electrical = "Electrical"
    case plumbing = "Plumbing"
    case hvac = "HVAC"
    case framing = "Framing"
    case roofing = "Roofing"
    case painting = "Painting"
    case flooring = "Flooring"
    case drywall = "Drywall"
    case masonry = "Masonry"
    case glazing = "Glazing"
    case fireProtection = "Fire Protection"
    case demolition = "Demolition"
    case excavation = "Excavation"
    case landscaping = "Landscaping"
    case paving = "Paving"
    case waterproofing = "Waterproofing"
    case insulation = "Insulation"
    case elevator = "Elevator"
    case solarPV = "Solar PV"
    case fiberOptic = "Fiber Optic"
    case crane = "Crane Services"
    case environmental = "Environmental"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .generalContractor: return "\u{1F3D7}"; case .concrete: return "\u{1F9F1}"; case .steel: return "\u{2699}\u{FE0F}"
        case .electrical: return "\u{26A1}"; case .plumbing: return "\u{1F6B0}"; case .hvac: return "\u{2744}\u{FE0F}"
        case .framing: return "\u{1FA9A}"; case .roofing: return "\u{1F3E0}"; case .painting: return "\u{1F3A8}"
        case .flooring: return "\u{1F4CF}"; case .drywall: return "\u{1F9F1}"; case .masonry: return "\u{1F9F1}"
        case .glazing: return "\u{1FA9F}"; case .fireProtection: return "\u{1F6A8}"; case .demolition: return "\u{1F4A5}"
        case .excavation: return "\u{1F69C}"; case .landscaping: return "\u{1F333}"; case .paving: return "\u{1F6E3}\u{FE0F}"
        case .waterproofing: return "\u{1F4A7}"; case .insulation: return "\u{1F321}\u{FE0F}"; case .elevator: return "\u{1F6D7}"
        case .solarPV: return "\u{2600}\u{FE0F}"; case .fiberOptic: return "\u{1F310}"; case .crane: return "\u{1F3D7}"
        case .environmental: return "\u{1F33F}"
        }
    }
}

struct DirectoryContractor: Identifiable {
    let id = UUID()
    let company: String
    let trade: ContractorTrade
    let location: String
    let country: String
    let rating: Double
    let projectsCompleted: Int
    let yearsInBusiness: Int
    let employees: String
    let revenue: String
    let certifications: [String]
    let specialties: [String]
    let verified: Bool
    var premiumListing: Bool = false  // $99/mo premium placement
    var featuredBadge: String? = nil  // "TOP RATED", "FAST RESPONSE", etc.
}

let globalContractors: [DirectoryContractor] = [
    DirectoryContractor(company: "Turner Construction", trade: .generalContractor, location: "New York, NY", country: "USA", rating: 4.9, projectsCompleted: 12000, yearsInBusiness: 122, employees: "10,000+", revenue: "$16B", certifications: ["ENR Top 400", "LEED AP"], specialties: ["Commercial", "Healthcare", "Data Centers"], verified: true),
    DirectoryContractor(company: "Skanska USA", trade: .generalContractor, location: "New York, NY", country: "Sweden/USA", rating: 4.8, projectsCompleted: 8500, yearsInBusiness: 137, employees: "28,000+", revenue: "$18B", certifications: ["ENR Top 400", "ISO 14001"], specialties: ["Infrastructure", "Green Building", "PPP"], verified: true),
    DirectoryContractor(company: "PCL Construction", trade: .generalContractor, location: "Edmonton, AB", country: "Canada", rating: 4.8, projectsCompleted: 6200, yearsInBusiness: 118, employees: "6,500+", revenue: "$9B CAD", certifications: ["ENR Top 400", "COR"], specialties: ["Industrial", "Heavy Civil", "Data Centers"], verified: true),
    DirectoryContractor(company: "Baker Concrete", trade: .concrete, location: "Monroe, OH", country: "USA", rating: 4.9, projectsCompleted: 4800, yearsInBusiness: 55, employees: "8,000+", revenue: "$2.1B", certifications: ["ACI Certified", "OSHA VPP"], specialties: ["High-rise", "Post-tension", "Tilt-up"], verified: true),
    DirectoryContractor(company: "Nucor Skyline", trade: .steel, location: "Charlotte, NC", country: "USA", rating: 4.7, projectsCompleted: 3200, yearsInBusiness: 78, employees: "3,500+", revenue: "$1.8B", certifications: ["AISC Certified", "AWS D1.1"], specialties: ["Structural", "Piling", "Bridge"], verified: true),
    DirectoryContractor(company: "Rosendin Electric", trade: .electrical, location: "San Jose, CA", country: "USA", rating: 4.8, projectsCompleted: 5600, yearsInBusiness: 105, employees: "7,500+", revenue: "$2.4B", certifications: ["NECA", "IBEW Partner"], specialties: ["Data Centers", "Solar", "EV Infrastructure"], verified: true),
    DirectoryContractor(company: "EMCOR Group", trade: .hvac, location: "Norwalk, CT", country: "USA", rating: 4.7, projectsCompleted: 9200, yearsInBusiness: 112, employees: "35,000+", revenue: "$12.6B", certifications: ["SMACNA", "ASHRAE"], specialties: ["MEP", "Building Automation", "Energy"], verified: true),
    DirectoryContractor(company: "Tecta America", trade: .roofing, location: "Rosemont, IL", country: "USA", rating: 4.6, projectsCompleted: 18000, yearsInBusiness: 24, employees: "4,500+", revenue: "$1.2B", certifications: ["NRCA", "GAF Master Elite"], specialties: ["Commercial Roofing", "Waterproofing", "Solar"], verified: true),
    DirectoryContractor(company: "Bouygues Construction", trade: .generalContractor, location: "Paris", country: "France", rating: 4.7, projectsCompleted: 15000, yearsInBusiness: 72, employees: "58,000+", revenue: "\u{20AC}13.5B", certifications: ["ISO 9001", "ISO 14001"], specialties: ["Infrastructure", "Real Estate", "Energy"], verified: true),
    DirectoryContractor(company: "Obayashi Corporation", trade: .generalContractor, location: "Tokyo", country: "Japan", rating: 4.8, projectsCompleted: 22000, yearsInBusiness: 132, employees: "15,000+", revenue: "\u{00A5}2.1T", certifications: ["ISO 9001", "OHSAS 18001"], specialties: ["Super High-Rise", "Tunnels", "Nuclear"], verified: true),
    DirectoryContractor(company: "Balfour Beatty", trade: .generalContractor, location: "London", country: "UK", rating: 4.6, projectsCompleted: 11000, yearsInBusiness: 115, employees: "26,000+", revenue: "\u{00A3}8.9B", certifications: ["ISO 45001", "BREEAM"], specialties: ["Infrastructure", "Defense", "Education"], verified: true),
    DirectoryContractor(company: "Samsung C&T", trade: .generalContractor, location: "Seoul", country: "South Korea", rating: 4.8, projectsCompleted: 8900, yearsInBusiness: 86, employees: "12,000+", revenue: "\u{20A9}38T", certifications: ["ISO 9001"], specialties: ["Super-Tall", "Petrochemical", "Smart City"], verified: true),
]

struct GlobalContractorDirectoryView: View {
    @State private var searchText = ""
    @State private var selectedTrade: ContractorTrade? = nil
    @State private var selectedCountry: String? = nil
    @State private var sortBy = 0

    private var countries: [String] { Array(Set(globalContractors.map(\.country))).sorted() }

    private var filtered: [DirectoryContractor] {
        var list = globalContractors
        if let trade = selectedTrade { list = list.filter { $0.trade == trade } }
        if let country = selectedCountry { list = list.filter { $0.country == country } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter { $0.company.lowercased().contains(q) || $0.location.lowercased().contains(q) || $0.trade.rawValue.lowercased().contains(q) || $0.specialties.joined().lowercased().contains(q) }
        }
        switch sortBy {
        case 1: list.sort { $0.projectsCompleted > $1.projectsCompleted }
        case 2: list.sort { $0.yearsInBusiness > $1.yearsInBusiness }
        default: list.sort { $0.rating > $1.rating }
        }
        return list
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) { Text("\u{1F4D6}").font(.system(size: 18)); Text("GLOBAL DIRECTORY").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.accent) }
                        Text("Contractor Database").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("\(globalContractors.count) contractors \u{2022} 25 trades \u{2022} \(countries.count) countries").font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(filtered.count)").font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.accent)
                        Text("RESULTS").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                    }
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.accent)

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(Theme.muted)
                    TextField("Search companies, trades, locations, specialties...", text: $searchText).font(.system(size: 12)).foregroundColor(Theme.text)
                }.padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)

                // Country filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        Button { selectedCountry = nil } label: { Text("ALL").font(.system(size: 8, weight: .bold)).foregroundColor(selectedCountry == nil ? .black : Theme.text).padding(.horizontal, 8).padding(.vertical, 4).background(selectedCountry == nil ? Theme.accent : Theme.surface).cornerRadius(4) }.buttonStyle(.plain)
                        ForEach(countries, id: \.self) { c in
                            Button { selectedCountry = selectedCountry == c ? nil : c } label: { Text(c).font(.system(size: 8, weight: .bold)).foregroundColor(selectedCountry == c ? .black : Theme.text).padding(.horizontal, 8).padding(.vertical, 4).background(selectedCountry == c ? Theme.cyan : Theme.surface).cornerRadius(4) }.buttonStyle(.plain)
                        }
                    }
                }

                // Trade filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        Button { selectedTrade = nil } label: { Text("ALL TRADES").font(.system(size: 8, weight: .bold)).foregroundColor(selectedTrade == nil ? .black : Theme.text).padding(.horizontal, 8).padding(.vertical, 4).background(selectedTrade == nil ? Theme.gold : Theme.surface).cornerRadius(4) }.buttonStyle(.plain)
                        ForEach(ContractorTrade.allCases) { trade in
                            Button { selectedTrade = selectedTrade == trade ? nil : trade } label: {
                                HStack(spacing: 2) { Text(trade.icon).font(.system(size: 8)); Text(trade.rawValue).font(.system(size: 7, weight: .bold)) }
                                    .foregroundColor(selectedTrade == trade ? .black : Theme.text)
                                    .padding(.horizontal, 6).padding(.vertical, 4)
                                    .background(selectedTrade == trade ? Theme.gold : Theme.surface).cornerRadius(4)
                            }.buttonStyle(.plain)
                        }
                    }
                }

                // Results
                ForEach(filtered) { contractor in
                    ContractorDirectoryCard(contractor: contractor)
                }
            }.padding(16)
        }.background(Theme.bg)
    }
}

struct ContractorDirectoryCard: View {
    let contractor: DirectoryContractor
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(contractor.trade.icon).font(.system(size: 20))
                    .frame(width: 36, height: 36).background(Theme.accent.opacity(0.1)).cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(contractor.company).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                        if contractor.verified { Image(systemName: "checkmark.seal.fill").font(.system(size: 9)).foregroundColor(Theme.green) }
                    }
                    Text("\(contractor.trade.rawValue) \u{2022} \(contractor.location) \u{2022} \(contractor.country)").font(.system(size: 9)).foregroundColor(Theme.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) { Text(String(format: "%.1f", contractor.rating)).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.gold); Image(systemName: "star.fill").font(.system(size: 8)).foregroundColor(Theme.gold) }
                    Text(contractor.revenue).font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.accent)
                }
            }

            if expanded {
                HStack(spacing: 12) {
                    VStack(spacing: 2) { Text("\(contractor.projectsCompleted)").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.cyan); Text("PROJECTS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }
                    VStack(spacing: 2) { Text("\(contractor.yearsInBusiness)").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.green); Text("YEARS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }
                    VStack(spacing: 2) { Text(contractor.employees).font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.accent); Text("STAFF").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }
                }
                Text("Certs: \(contractor.certifications.joined(separator: " \u{2022} "))").font(.system(size: 8)).foregroundColor(Theme.muted)
                Text("Specialties: \(contractor.specialties.joined(separator: ", "))").font(.system(size: 8)).foregroundColor(Theme.cyan)
                HStack(spacing: 6) {
                    Button { } label: { Text("CONTACT").font(.system(size: 9, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 6).background(Theme.accent).cornerRadius(6) }.buttonStyle(.plain)
                    Button { } label: { Text("REQUEST BID").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan).frame(maxWidth: .infinity).padding(.vertical, 6).background(Theme.cyan.opacity(0.12)).cornerRadius(6) }.buttonStyle(.plain)
                }
            }
            HStack { Spacer(); Button { withAnimation { expanded.toggle() } } label: { Text(expanded ? "LESS" : "MORE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.accent) }.buttonStyle(.plain) }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(contractor.verified ? Theme.green.opacity(0.2) : Theme.border.opacity(0.2), lineWidth: 0.8))
    }
}
