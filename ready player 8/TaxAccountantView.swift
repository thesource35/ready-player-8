import Foundation
import SwiftUI

// MARK: - ========== Tax Accountant Tab ==========

struct TaxExpense: Identifiable, Codable {
    var id = UUID()
    let date: String
    let description: String
    let amount: Double
    let category: TaxCategory
    let projectRef: String
    var receiptAttached: Bool
    var deductible: Bool
}

enum TaxCategory: String, CaseIterable, Codable {
    case materials = "Materials"
    case labor = "Labor"
    case equipment = "Equipment Rental"
    case fuel = "Fuel & Mileage"
    case insurance = "Insurance"
    case permits = "Permits & Fees"
    case tools = "Tools & Supplies"
    case office = "Office & Admin"
    case meals = "Meals & Travel"
    case subcontractors = "Subcontractors"
    case depreciation = "Depreciation"
    case professional = "Professional Services"

    var icon: String {
        switch self {
        case .materials: return "\u{1F9F1}"; case .labor: return "\u{1F477}"; case .equipment: return "\u{1F3D7}"
        case .fuel: return "\u{26FD}"; case .insurance: return "\u{1F6E1}"; case .permits: return "\u{1F4C4}"
        case .tools: return "\u{1F527}"; case .office: return "\u{1F4BC}"; case .meals: return "\u{1F37D}"
        case .subcontractors: return "\u{1F91D}"; case .depreciation: return "\u{1F4C9}"; case .professional: return "\u{1F4B3}"
        }
    }

    var color: Color {
        switch self {
        case .materials: return Theme.gold; case .labor: return Theme.cyan; case .equipment: return Theme.accent
        case .fuel: return Theme.green; case .insurance: return Theme.purple; case .permits: return Theme.red
        case .tools: return Color.orange; case .office: return Theme.muted; case .meals: return Theme.cyan
        case .subcontractors: return Theme.gold; case .depreciation: return Theme.purple; case .professional: return Theme.accent
        }
    }
}

struct TaxCPA: Identifiable {
    let id = UUID()
    let name: String
    let firm: String
    let specialty: String
    let hourlyRate: String
    let rating: Double
    let location: String
    let certifications: [String]
    let available: Bool
    let initials: String
}

struct SubcontractorPayment: Identifiable, Codable {
    var id = UUID()
    let name: String
    let ein: String
    let totalPaid: Double
    let needs1099: Bool
    let form1099Filed: Bool
}

private let mockCPAs: [TaxCPA] = [
    TaxCPA(name: "Robert Steinberg", firm: "Steinberg & Associates", specialty: "Construction & Real Estate", hourlyRate: "$275/hr", rating: 4.9, location: "Houston, TX", certifications: ["CPA", "CCA (Certified Construction Auditor)"], available: true, initials: "RS"),
    TaxCPA(name: "Linda Tran", firm: "BuildTax Advisory", specialty: "Contractor Tax Planning", hourlyRate: "$225/hr", rating: 4.8, location: "Los Angeles, CA", certifications: ["CPA", "EA (Enrolled Agent)"], available: true, initials: "LT"),
    TaxCPA(name: "Michael O'Donnell", firm: "O'Donnell Tax Group", specialty: "Small Business Construction", hourlyRate: "$195/hr", rating: 4.7, location: "Chicago, IL", certifications: ["CPA", "QuickBooks ProAdvisor"], available: false, initials: "MO"),
    TaxCPA(name: "Anita Sharma", firm: "Sharma & Partners", specialty: "Multi-State Contractor Tax", hourlyRate: "$250/hr", rating: 4.9, location: "New York, NY", certifications: ["CPA", "MST (Master of Tax)"], available: true, initials: "AS"),
]

// MARK: - Tax Accountant Main View

struct TaxAccountantView: View {
    @State private var activeSubTab: TaxSubTab = .expenses
    @State private var expenses: [TaxExpense] = []
    @State private var subPayments: [SubcontractorPayment] = []
    @State private var showAddExpense = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let supabase = SupabaseService.shared

    enum TaxSubTab: String, CaseIterable {
        case expenses = "Expenses"
        case deductions = "Deductions"
        case quarterly = "Quarterly"
        case sub1099 = "1099s"
        case cpas = "CPAs"
        case calendar = "Calendar"
    }

    private var totalExpenses: Double { expenses.reduce(0) { $0 + $1.amount } }
    private var totalDeductible: Double { expenses.filter { $0.deductible }.reduce(0) { $0 + $1.amount } }
    private var categoryTotals: [(category: TaxCategory, total: Double)] {
        TaxCategory.allCases.compactMap { cat in
            let total = expenses.filter { $0.category == cat }.reduce(0) { $0 + $1.amount }
            return total > 0 ? (cat, total) : nil
        }.sorted { $0.total > $1.total }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("\u{1F4B0}").font(.system(size: 18))
                            Text("TAX CENTER").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.green)
                        }
                        Text("Construction Tax Intelligence")
                            .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("Expense tracking, deductions, quarterly estimates, and 1099 management")
                            .font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        let savings = totalDeductible * 0.3
                        Text(savings >= 1000 ? "$\(String(format: "%.1f", savings / 1000))K" : "$\(String(format: "%.0f", savings))")
                            .font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.green)
                        Text("EST. SAVINGS").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                    }
                }
                .padding(16).background(Theme.surface).cornerRadius(14)
                .premiumGlow(cornerRadius: 14, color: Theme.green)

                // Sub-tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(TaxSubTab.allCases, id: \.self) { tab in
                            Button { withAnimation { activeSubTab = tab } } label: {
                                Text(tab.rawValue.uppercased())
                                    .font(.system(size: 9, weight: .bold)).tracking(1)
                                    .foregroundColor(activeSubTab == tab ? .black : Theme.muted)
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(activeSubTab == tab ? Theme.green : Theme.surface)
                            }.buttonStyle(.plain)
                        }
                    }.cornerRadius(8)
                }

                switch activeSubTab {
                case .expenses: expensesContent
                case .deductions: deductionsContent
                case .quarterly: quarterlyContent
                case .sub1099: sub1099Content
                case .cpas: cpasContent
                case .calendar: taxCalendarContent
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
        .task {
            expenses = loadJSON("ConstructOS.Tax.Expenses", default: [TaxExpense]())
            subPayments = loadJSON("ConstructOS.Tax.SubPayments", default: [SubcontractorPayment]())
            if supabase.isConfigured {
                isLoading = true
                do {
                    let remote: [SupabaseTaxExpense] = try await supabase.fetch("cs_tax_expenses")
                    if !remote.isEmpty {
                        expenses = remote.map {
                            TaxExpense(date: $0.date, description: $0.description, amount: $0.amount, category: TaxCategory(rawValue: $0.category) ?? .materials, projectRef: $0.projectRef, receiptAttached: $0.receiptAttached, deductible: $0.deductible)
                        }
                    }
                } catch { errorMessage = "Failed to sync expenses" }
                isLoading = false
            }
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseSheet { expense in
                // Save locally
                saveJSON("ConstructOS.Tax.Expenses", value: expenses)
                // Sync to Supabase
                if supabase.isConfigured {
                    let dto = SupabaseTaxExpense(date: expense.date, description: expense.description, amount: expense.amount, category: expense.category.rawValue, projectRef: expense.projectRef, receiptAttached: expense.receiptAttached, deductible: expense.deductible)
                    Task { await supabase.insertWithOfflineSupport("cs_tax_expenses", record: dto) }
                }
                expenses.insert(expense, at: 0)
                saveJSON("ConstructOS.Tax.Expenses", value: expenses)
                showAddExpense = false
            }
        }
    }

    // MARK: Expenses
    private var expensesContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("EXPENSE TRACKER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
                Spacer()
                Button { showAddExpense = true } label: {
                    Label("ADD EXPENSE", systemImage: "plus.circle.fill")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                        .padding(.horizontal, 12).padding(.vertical, 6).background(Theme.accent).cornerRadius(6)
                }.buttonStyle(.plain)
            }

            // Stats
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text(totalExpenses >= 1000 ? "$\(String(format: "%.1f", totalExpenses / 1000))K" : "$\(String(format: "%.0f", totalExpenses))")
                        .font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent)
                    Text("TOTAL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(8).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) {
                    Text(totalDeductible >= 1000 ? "$\(String(format: "%.1f", totalDeductible / 1000))K" : "$\(String(format: "%.0f", totalDeductible))")
                        .font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green)
                    Text("DEDUCTIBLE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(8).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) {
                    Text("\(expenses.count)").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan)
                    Text("ENTRIES").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(8).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
            }

            // Category breakdown
            if !categoryTotals.isEmpty {
                ForEach(categoryTotals, id: \.category) { item in
                    HStack(spacing: 8) {
                        Text(item.category.icon).font(.system(size: 14))
                        Text(item.category.rawValue).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text)
                        Spacer()
                        Text("$\(String(format: "%.0f", item.total))")
                            .font(.system(size: 11, weight: .heavy)).foregroundColor(item.category.color)
                    }
                    .padding(8).background(item.category.color.opacity(0.05)).cornerRadius(6)
                }
            }

            // Expense list
            ForEach(expenses.prefix(15)) { expense in
                HStack(spacing: 8) {
                    Text(expense.category.icon).font(.system(size: 12))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(expense.description).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                        Text("\(expense.date) \u{2022} \(expense.category.rawValue) \u{2022} \(expense.projectRef)")
                            .font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    if expense.deductible {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 9)).foregroundColor(Theme.green)
                    }
                    Text("$\(String(format: "%.0f", expense.amount))")
                        .font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.accent)
                }
                .padding(8).background(Theme.surface).cornerRadius(6)
            }
        }
    }

    // MARK: Deductions
    private var deductionsContent: some View {
        let deductions: [(name: String, desc: String, maxAmount: String, icon: String)] = [
            ("Section 179", "Deduct full purchase price of qualifying equipment in year purchased", "$1,160,000 limit", "\u{1F3D7}"),
            ("Vehicle Mileage", "IRS standard rate for business use of personal vehicle", "$0.67/mile (2024)", "\u{1F698}"),
            ("Home Office", "Dedicated workspace in your home used for business", "$5/sq ft (simplified)", "\u{1F3E0}"),
            ("Equipment Depreciation", "MACRS depreciation on construction equipment over 5-7 years", "Based on cost basis", "\u{1F4C9}"),
            ("Insurance Premiums", "Business insurance, workers comp, general liability", "100% deductible", "\u{1F6E1}"),
            ("Tools & Supplies", "Hand tools, power tools, safety equipment, consumables", "100% if < $2,500 each", "\u{1F527}"),
            ("Fuel & Maintenance", "Fuel, repairs, maintenance for business vehicles/equipment", "100% deductible", "\u{26FD}"),
            ("Contractor Licenses", "State license fees, continuing education, certifications", "100% deductible", "\u{1F4C4}"),
            ("Retirement Contributions", "SEP-IRA, Solo 401(k), SIMPLE IRA contributions", "Up to $66,000/yr", "\u{1F4B0}"),
            ("Health Insurance", "Self-employed health insurance deduction", "100% of premiums", "\u{2695}\u{FE0F}"),
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("TAX DEDUCTION FINDER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
            Text("Common construction tax deductions \u{2014} maximize your write-offs")
                .font(.system(size: 10)).foregroundColor(Theme.muted)

            ForEach(deductions, id: \.name) { d in
                HStack(alignment: .top, spacing: 10) {
                    Text(d.icon).font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(d.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                        Text(d.desc).font(.system(size: 10)).foregroundColor(Theme.muted)
                        Text(d.maxAmount).font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.green)
                    }
                }
                .padding(10).background(Theme.surface).cornerRadius(8)
            }

            // Write-off dashboard
            if !categoryTotals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR WRITE-OFF DASHBOARD").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
                    HStack(spacing: 8) {
                        VStack(spacing: 2) {
                            Text(totalDeductible >= 1000 ? "$\(String(format: "%.1f", totalDeductible/1000))K" : "$\(String(format: "%.0f", totalDeductible))")
                                .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.green)
                            Text("TOTAL DEDUCTIONS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                        }.frame(maxWidth: .infinity)
                        VStack(spacing: 2) {
                            Text("$\(String(format: "%.0f", totalDeductible * 0.30))")
                                .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.accent)
                            Text("EST. TAX SAVED (30%)").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                        }.frame(maxWidth: .infinity)
                    }
                    .padding(12).background(Theme.surface).cornerRadius(10)
                    .premiumGlow(cornerRadius: 10, color: Theme.green)
                }
            }
        }
    }

    // MARK: Quarterly
    private var quarterlyContent: some View {
        let quarters: [(name: String, due: String, income: Double, expenses: Double)] = [
            ("Q1 (Jan-Mar)", "Apr 15", 185000, 142000),
            ("Q2 (Apr-Jun)", "Jun 15", 210000, 158000),
            ("Q3 (Jul-Sep)", "Sep 15", 195000, 149000),
            ("Q4 (Oct-Dec)", "Jan 15", 178000, 135000),
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("QUARTERLY ESTIMATE CALCULATOR").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)

            ForEach(quarters, id: \.name) { q in
                let taxable = q.income - q.expenses
                let estimated = taxable * 0.30

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(q.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                        Spacer()
                        Text("DUE: \(q.due)").font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.gold)
                    }
                    HStack(spacing: 12) {
                        VStack(spacing: 1) { Text("INCOME").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text("$\(String(format: "%.0f", q.income/1000))K").font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.green) }
                        Text("\u{2212}").foregroundColor(Theme.muted)
                        VStack(spacing: 1) { Text("EXPENSES").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text("$\(String(format: "%.0f", q.expenses/1000))K").font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.red) }
                        Text("=").foregroundColor(Theme.muted)
                        VStack(spacing: 1) { Text("TAXABLE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text("$\(String(format: "%.0f", taxable/1000))K").font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.accent) }
                        Text("\u{2192}").foregroundColor(Theme.muted)
                        VStack(spacing: 1) { Text("EST. TAX").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Text("$\(String(format: "%.0f", estimated/1000))K").font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.purple) }
                    }
                }
                .padding(12).background(Theme.surface).cornerRadius(10)
            }
        }
    }

    // MARK: 1099s
    private var sub1099Content: some View {
        let mockSubs: [SubcontractorPayment] = [
            SubcontractorPayment(name: "Apex Concrete LLC", ein: "**-***4821", totalPaid: 48200, needs1099: true, form1099Filed: false),
            SubcontractorPayment(name: "Elite Steel Works", ein: "**-***7293", totalPaid: 32100, needs1099: true, form1099Filed: true),
            SubcontractorPayment(name: "Prime Electric Inc", ein: "**-***5180", totalPaid: 15800, needs1099: true, form1099Filed: false),
            SubcontractorPayment(name: "Quick Plumbing", ein: "**-***8834", totalPaid: 8400, needs1099: true, form1099Filed: false),
            SubcontractorPayment(name: "Joe's Drywall", ein: "**-***2917", totalPaid: 450, needs1099: false, form1099Filed: false),
        ]

        let total1099 = mockSubs.filter { $0.needs1099 }.reduce(0) { $0 + $1.totalPaid }
        let filedCount = mockSubs.filter { $0.form1099Filed }.count
        let needCount = mockSubs.filter { $0.needs1099 }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("1099 TRACKER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
                Spacer()
                Text("\(filedCount)/\(needCount) FILED").font(.system(size: 9, weight: .heavy))
                    .foregroundColor(filedCount == needCount ? Theme.green : Theme.gold)
            }
            Text("Subcontractors paid $600+ require 1099-NEC filing")
                .font(.system(size: 10)).foregroundColor(Theme.muted)

            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("$\(String(format: "%.1f", total1099/1000))K").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent)
                    Text("TOTAL 1099").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(8).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) {
                    Text("\(needCount)").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.gold)
                    Text("REQUIRED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(8).background(Theme.gold.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) {
                    Text("\(filedCount)").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green)
                    Text("FILED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(8).background(Theme.green.opacity(0.06)).cornerRadius(8)
            }

            ForEach(mockSubs) { sub in
                HStack(spacing: 8) {
                    Image(systemName: sub.form1099Filed ? "checkmark.circle.fill" : sub.needs1099 ? "exclamationmark.circle.fill" : "minus.circle")
                        .font(.system(size: 12)).foregroundColor(sub.form1099Filed ? Theme.green : sub.needs1099 ? Theme.gold : Theme.muted)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(sub.name).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                        Text("EIN: \(sub.ein) \u{2022} \(sub.needs1099 ? "1099 REQUIRED" : "Under $600")").font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text("$\(String(format: "%.0f", sub.totalPaid))").font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.accent)
                }
                .padding(8).background(Theme.surface).cornerRadius(6)
            }
        }
    }

    // MARK: CPAs
    private var cpasContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONSTRUCTION TAX PROFESSIONALS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)

            ForEach(mockCPAs) { cpa in
                HStack(spacing: 10) {
                    Circle().fill(LinearGradient(colors: [Theme.purple, Theme.green], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                        .overlay(Text(cpa.initials).font(.system(size: 12, weight: .heavy)).foregroundColor(.white))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(cpa.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                            if cpa.available { Circle().fill(Theme.green).frame(width: 5, height: 5) }
                        }
                        Text("\(cpa.firm) \u{2022} \(cpa.specialty)").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Text(cpa.certifications.joined(separator: " \u{2022} ")).font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(cpa.hourlyRate).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.accent)
                        HStack(spacing: 1) {
                            Text("\(String(format: "%.1f", cpa.rating))").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.gold)
                            Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(Theme.gold)
                        }
                    }
                }
                .padding(10).background(Theme.surface).cornerRadius(10)
            }
        }
    }

    // MARK: Tax Calendar
    private var taxCalendarContent: some View {
        let dates: [(date: String, event: String, urgency: String)] = [
            ("Jan 15", "Q4 estimated tax payment due", "high"),
            ("Jan 31", "W-2s and 1099-NEC due to recipients", "high"),
            ("Feb 28", "1099 filing deadline (paper)", "medium"),
            ("Mar 31", "1099 filing deadline (electronic)", "medium"),
            ("Apr 15", "Tax return due / Q1 estimated payment", "critical"),
            ("Jun 15", "Q2 estimated tax payment due", "high"),
            ("Sep 15", "Q3 estimated tax payment / Extended returns due", "high"),
            ("Oct 15", "Extended tax return deadline", "medium"),
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("TAX CALENDAR").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.red)
            Text("Key deadlines for construction businesses").font(.system(size: 10)).foregroundColor(Theme.muted)

            ForEach(dates, id: \.date) { item in
                HStack(spacing: 10) {
                    Text(item.date).font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(item.urgency == "critical" ? Theme.red : item.urgency == "high" ? Theme.gold : Theme.muted)
                        .frame(width: 55, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.event).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text)
                    }
                    Spacer()
                    Text(item.urgency.uppercased()).font(.system(size: 7, weight: .black))
                        .foregroundColor(.black).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(item.urgency == "critical" ? Theme.red : item.urgency == "high" ? Theme.gold : Theme.muted).cornerRadius(3)
                }
                .padding(8).background(item.urgency == "critical" ? Theme.red.opacity(0.06) : Theme.surface).cornerRadius(6)
            }
        }
    }
}

// MARK: Add Expense Sheet
struct AddExpenseSheet: View {
    let onSubmit: (TaxExpense) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var desc = ""; @State private var amount = ""; @State private var projectRef = ""
    @State private var category: TaxCategory = .materials; @State private var deductible = true

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("LOG EXPENSE").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.text)
                        TextField("Description", text: $desc).font(.system(size: 13)).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                        HStack(spacing: 8) {
                            TextField("Amount $", text: $amount).font(.system(size: 13)).frame(width: 100).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                            TextField("Project ref", text: $projectRef).font(.system(size: 13)).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 4)], spacing: 4) {
                            ForEach(TaxCategory.allCases, id: \.self) { cat in
                                Button { category = cat } label: {
                                    HStack(spacing: 3) { Text(cat.icon).font(.system(size: 9)); Text(cat.rawValue).font(.system(size: 8, weight: .bold)).lineLimit(1) }
                                        .foregroundColor(category == cat ? .black : Theme.text)
                                        .frame(maxWidth: .infinity).padding(.vertical, 6)
                                        .background(category == cat ? cat.color : Theme.surface).cornerRadius(5)
                                }.buttonStyle(.plain)
                            }
                        }
                        Toggle("Tax Deductible", isOn: $deductible).font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text)
                        Button {
                            guard !desc.isEmpty, let amt = Double(amount.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) else { return }
                            let df = DateFormatter(); df.dateFormat = "MM/dd"
                            onSubmit(TaxExpense(date: df.string(from: Date()), description: desc, amount: amt, category: category, projectRef: projectRef, receiptAttached: false, deductible: deductible))
                        } label: {
                            Text("LOG EXPENSE").font(.system(size: 13, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 14).background(Theme.green).cornerRadius(10)
                        }.buttonStyle(.plain)
                    }.padding(20)
                }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) } }
        }.preferredColorScheme(.dark)
    }
}
