import Foundation
import SwiftUI

// MARK: - ========== OperationsCommercial.swift ==========

// MARK: - Submittal & Approval Log

enum SubmittalStatus: String, CaseIterable, Codable {
    case pending          = "PENDING"
    case approved         = "APPROVED"
    case reviseResubmit   = "REVISE & RESUBMIT"
    case rejected         = "REJECTED"
    var color: Color {
        switch self {
        case .pending:        return Theme.gold
        case .approved:       return Theme.green
        case .reviseResubmit: return Theme.cyan
        case .rejected:       return Theme.red
        }
    }
    var short: String {
        switch self {
        case .pending:        return "PEND"
        case .approved:       return "APPR"
        case .reviseResubmit: return "R&R"
        case .rejected:       return "REJ"
        }
    }
}

struct SubmittalItem: Identifiable, Codable {
    var id = UUID()
    var number: String
    var description: String
    var discipline: String
    var submittedDate: String
    var returnDate: String
    var revision: Int
    var status: SubmittalStatus
    var ball: String
}

struct SubmittalLogPanel: View {
    @State private var submittals: [SubmittalItem] = [
        SubmittalItem(number: "S-001", description: "Structural Steel Shop Drawings", discipline: "Structural", submittedDate: "03-01", returnDate: "03-15", revision: 1, status: .approved, ball: "Contractor"),
        SubmittalItem(number: "S-002", description: "Electrical Panel Schedules", discipline: "Electrical", submittedDate: "03-08", returnDate: "03-22", revision: 0, status: .pending, ball: "Architect"),
        SubmittalItem(number: "S-003", description: "HVAC Equipment Cuts", discipline: "Mechanical", submittedDate: "03-05", returnDate: "03-19", revision: 1, status: .reviseResubmit, ball: "Contractor"),
        SubmittalItem(number: "S-004", description: "Concrete Mix Design", discipline: "Civil", submittedDate: "02-20", returnDate: "03-06", revision: 2, status: .approved, ball: "Contractor"),
        SubmittalItem(number: "S-005", description: "Curtain Wall System", discipline: "Architectural", submittedDate: "03-12", returnDate: "03-26", revision: 0, status: .pending, ball: "Architect"),
        SubmittalItem(number: "S-006", description: "Fire Alarm Drawings", discipline: "Electrical", submittedDate: "03-03", returnDate: "03-17", revision: 0, status: .rejected, ball: "Contractor"),
    ]
    @State private var filterStatus: SubmittalStatus? = nil
    @State private var showAddForm = false
    @State private var newNum = ""
    @State private var newDesc = ""
    @State private var newDisc = ""
    @State private var newSub = ""
    @State private var newRet = ""

    private var filtered: [SubmittalItem] {
        submittals.filter { filterStatus == nil || $0.status == filterStatus }
    }
    private var pendingCount: Int { submittals.filter { $0.status == .pending }.count }
    private var approvedCount: Int { submittals.filter { $0.status == .approved }.count }
    private var actionCount: Int { submittals.filter { $0.status == .reviseResubmit || $0.status == .rejected }.count }

    private func addSubmittal() {
        guard !newNum.isEmpty, !newDesc.isEmpty else { return }
        submittals.append(SubmittalItem(number: newNum, description: newDesc, discipline: newDisc, submittedDate: newSub, returnDate: newRet, revision: 0, status: .pending, ball: "Architect"))
        newNum = ""; newDesc = ""; newDisc = ""; newSub = ""; newRet = ""
        showAddForm = false
    }

    private func exportLog() {
        let lines = submittals.map { "[\($0.status.short)] \($0.number) – \($0.description) | \($0.discipline) | Sub: \($0.submittedDate) | Return: \($0.returnDate) | Rev \($0.revision) | Ball: \($0.ball)" }
        copyTextToClipboard("SUBMITTAL LOG – \(submittals.count) items\n" + lines.joined(separator: "\n"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SUBMITTAL & APPROVAL LOG")
                        .font(.system(size: 11, weight: .black)).tracking(2)
                        .foregroundColor(Theme.accent)
                    Text("Pending \(pendingCount) · Approved \(approvedCount) · Action needed \(actionCount)")
                        .font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.muted)
                }
                Spacer()
                Button("EXPORT") { exportLog() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.accent).cornerRadius(5)
                Button(showAddForm ? "CANCEL" : "+ ADD") { showAddForm.toggle() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.cyan).cornerRadius(5)
            }

            HStack(spacing: 8) {
                Button("ALL") { filterStatus = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(filterStatus == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(filterStatus == nil ? Theme.accent : Theme.surface)
                    .cornerRadius(4)
                ForEach(SubmittalStatus.allCases, id: \.rawValue) { s in
                    Button(s.short) { filterStatus = (filterStatus == s) ? nil : s }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(filterStatus == s ? .black : Theme.muted)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(filterStatus == s ? s.color : Theme.surface)
                        .cornerRadius(4)
                }
            }

            if showAddForm {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Number (S-007)", text: $newNum)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 100)
                        TextField("Description", text: $newDesc)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Discipline", text: $newDisc)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 100)
                    }
                    HStack(spacing: 6) {
                        TextField("Submitted (MM-DD)", text: $newSub)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Expected Return (MM-DD)", text: $newRet)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        Button("ADD") { addSubmittal() }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Theme.green).cornerRadius(6)
                    }
                }
            }

            HStack(spacing: 6) {
                Text("NO.").frame(width: 50, alignment: .leading)
                Text("DESCRIPTION").frame(maxWidth: .infinity, alignment: .leading)
                Text("DISC.").frame(width: 80, alignment: .leading)
                Text("SUBMITTED").frame(width: 70, alignment: .center)
                Text("RETURN").frame(width: 65, alignment: .center)
                Text("REV").frame(width: 30, alignment: .center)
                Text("BALL").frame(width: 70, alignment: .center)
                Text("STATUS").frame(width: 55, alignment: .center)
            }
            .font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)

            ForEach(filtered) { item in
                HStack(spacing: 6) {
                    Text(item.number).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan)
                        .frame(width: 50, alignment: .leading)
                    Text(item.description).font(.system(size: 9)).foregroundColor(Theme.text).lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(item.discipline).font(.system(size: 8)).foregroundColor(Theme.muted)
                        .frame(width: 80, alignment: .leading)
                    Text(item.submittedDate).font(.system(size: 9)).foregroundColor(Theme.muted)
                        .frame(width: 70, alignment: .center)
                    Text(item.returnDate).font(.system(size: 9)).foregroundColor(Theme.gold)
                        .frame(width: 65, alignment: .center)
                    Text("R\(item.revision)").font(.system(size: 9, weight: .semibold)).foregroundColor(item.revision > 0 ? Theme.red : Theme.muted)
                        .frame(width: 30, alignment: .center)
                    Text(item.ball).font(.system(size: 8)).foregroundColor(item.ball == "Architect" ? Theme.cyan : Theme.green)
                        .frame(width: 70, alignment: .center)
                    Text(item.status.short)
                        .font(.system(size: 8, weight: .black)).foregroundColor(item.status.color)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(item.status.color.opacity(0.13)).cornerRadius(4)
                        .frame(width: 55, alignment: .center)
                }
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(Theme.surface.opacity(0.7)).cornerRadius(7)
            }
        }
        .padding(14).background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            submittals = loadJSON("ConstructOS.Ops.Submittals", default: submittals)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Project & Contract Account Management

enum AccountOwnerType: String, CaseIterable, Codable {
    case owner = "OWNER"
    case gc = "GC"
    case subcontractor = "SUB"

    var color: Color {
        switch self {
        case .owner: return Theme.cyan
        case .gc: return Theme.accent
        case .subcontractor: return Theme.gold
        }
    }
}

enum ContractAccountStatus: String, CaseIterable, Codable {
    case draft = "DRAFT"
    case active = "ACTIVE"
    case pendingInvoice = "PENDING INVOICE"
    case atRisk = "AT RISK"
    case closed = "CLOSED"

    var color: Color {
        switch self {
        case .draft: return Theme.cyan
        case .active: return Theme.green
        case .pendingInvoice: return Theme.gold
        case .atRisk: return Theme.red
        case .closed: return Theme.muted
        }
    }
}

struct ProjectAccountItem: Identifiable, Codable {
    var id = UUID()
    var code: String
    var projectName: String
    var ownerName: String
    var ownerType: AccountOwnerType
    var approvedBudget: Double
    var billedToDate: Double
    var retainagePct: Double
    var socialScore: Int

    var remaining: Double { approvedBudget - billedToDate }
}

struct ContractAccountItem: Identifiable, Codable {
    var id = UUID()
    var contractNo: String
    var projectCode: String
    var partner: String
    var contractValue: Double
    var invoicedToDate: Double
    var status: ContractAccountStatus
    var renewalDate: String
    var socialScore: Int
    var workEthicScore: Int
    var socialTrend7d: [Int]
    var workEthicTrend7d: [Int]

    var balance: Double { contractValue - invoicedToDate }
}

struct ProjectContractAccountPanel: View {
    @State private var projects: [ProjectAccountItem] = [
        ProjectAccountItem(code: "P-1024", projectName: "North Deck Expansion", ownerName: "Metro Transit", ownerType: .owner, approvedBudget: 2_800_000, billedToDate: 1_940_000, retainagePct: 5, socialScore: 88),
        ProjectAccountItem(code: "P-1188", projectName: "Medical Tower TI", ownerName: "Moss Development", ownerType: .gc, approvedBudget: 4_250_000, billedToDate: 2_680_000, retainagePct: 7.5, socialScore: 81),
        ProjectAccountItem(code: "P-1201", projectName: "East Utility Rehab", ownerName: "City Public Works", ownerType: .owner, approvedBudget: 1_900_000, billedToDate: 1_120_000, retainagePct: 10, socialScore: 74),
    ]

    @State private var contracts: [ContractAccountItem] = [
        ContractAccountItem(contractNo: "C-441", projectCode: "P-1024", partner: "Apex Electrical", contractValue: 540_000, invoicedToDate: 402_000, status: .active, renewalDate: "2026-12-31", socialScore: 86, workEthicScore: 91, socialTrend7d: [82, 83, 84, 85, 85, 86, 87], workEthicTrend7d: [88, 89, 89, 90, 90, 91, 91]),
        ContractAccountItem(contractNo: "C-457", projectCode: "P-1188", partner: "ProMech HVAC", contractValue: 780_000, invoicedToDate: 620_000, status: .pendingInvoice, renewalDate: "2026-09-30", socialScore: 79, workEthicScore: 84, socialTrend7d: [81, 81, 80, 80, 79, 79, 78], workEthicTrend7d: [85, 85, 84, 84, 84, 83, 83]),
        ContractAccountItem(contractNo: "C-463", projectCode: "P-1201", partner: "Ironclad Steel", contractValue: 420_000, invoicedToDate: 398_000, status: .atRisk, renewalDate: "2026-06-15", socialScore: 63, workEthicScore: 68, socialTrend7d: [69, 68, 67, 66, 65, 64, 63], workEthicTrend7d: [72, 71, 71, 70, 69, 68, 68]),
    ]

    @State private var contractFilter: ContractAccountStatus? = nil
    @State private var showProjectForm = false
    @State private var showContractForm = false
    @State private var showSocialDrivers = false
    @State private var selectedProjectDriverFilter: String? = nil
    @State private var selectedContractDriverFilter: String? = nil

    @State private var newProjectCode = ""
    @State private var newProjectName = ""
    @State private var newProjectOwner = ""
    @State private var newProjectBudget = ""
    @State private var newProjectRetainage = ""

    @State private var newContractNo = ""
    @State private var newContractProject = ""
    @State private var newContractPartner = ""
    @State private var newContractValue = ""
    @State private var newContractRenewal = ""

    private var totalBudget: Double { projects.map { $0.approvedBudget }.reduce(0, +) }
    private var totalBilled: Double { projects.map { $0.billedToDate }.reduce(0, +) }
    private var totalContractValue: Double { contracts.map { $0.contractValue }.reduce(0, +) }
    private var totalContractOpenBalance: Double { contracts.map { $0.balance }.reduce(0, +) }
    private var avgProjectSocialScore: Int {
        guard !projects.isEmpty else { return 0 }
        let total = projects.map { projectSocialScore($0) }.reduce(0, +)
        return Int((Double(total) / Double(projects.count)).rounded())
    }
    private var avgContractSocialScore: Int {
        guard !contracts.isEmpty else { return 0 }
        let total = contracts.map { contractSocialScore($0) }.reduce(0, +)
        return Int((Double(total) / Double(contracts.count)).rounded())
    }
    private var avgContractWorkEthicScore: Int {
        guard !contracts.isEmpty else { return 0 }
        let total = contracts.map { $0.workEthicScore }.reduce(0, +)
        return Int((Double(total) / Double(contracts.count)).rounded())
    }

    private var visibleProjects: [ProjectAccountItem] {
        projects.filter { project in
            guard let selectedProjectDriverFilter else { return true }
            return projectDrivers(project).contains(selectedProjectDriverFilter)
        }
    }

    private var visibleContracts: [ContractAccountItem] {
        contracts.filter { contract in
            let statusMatch = contractFilter == nil || contract.status == contractFilter
            let driverMatch: Bool
            if let selectedContractDriverFilter {
                driverMatch = contractDrivers(contract).contains(selectedContractDriverFilter)
            } else {
                driverMatch = true
            }
            return statusMatch && driverMatch
        }
    }

    private var projectDriverOptions: [String] {
        Array(Set(projects.flatMap { projectDrivers($0) })).sorted()
    }

    private var contractDriverOptions: [String] {
        Array(Set(contracts.flatMap { contractDrivers($0) })).sorted()
    }

    private var socialDriversPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SOCIAL SCORE DRIVERS")
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundColor(Theme.gold)

            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROJECT WATCH")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.muted)
                    ForEach(projects.sorted { projectSocialScore($0) < projectSocialScore($1) }.prefix(2)) { project in
                        Text("\(project.code) · \(projectSocialScore(project)) · \(projectDrivers(project).joined(separator: ", "))")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("CONTRACT WATCH")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.muted)
                    ForEach(contracts.sorted { contractSocialScore($0) < contractSocialScore($1) }.prefix(2)) { contract in
                        Text("\(contract.contractNo) · \(contractSocialScore(contract)) · \(contractDrivers(contract).joined(separator: ", "))")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                    }
                }
            }

            Text("DRILL-DOWN PROJECT DRIVERS")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Theme.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(projectDriverOptions, id: \.self) { driver in
                        Button(action: {
                            selectedProjectDriverFilter = (selectedProjectDriverFilter == driver) ? nil : driver
                        }) {
                            Text(driver)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(selectedProjectDriverFilter == driver ? .black : Theme.gold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedProjectDriverFilter == driver ? Theme.gold : Theme.gold.opacity(0.14))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("DRILL-DOWN CONTRACT DRIVERS")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Theme.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(contractDriverOptions, id: \.self) { driver in
                        Button(action: {
                            selectedContractDriverFilter = (selectedContractDriverFilter == driver) ? nil : driver
                        }) {
                            Text(driver)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(selectedContractDriverFilter == driver ? .black : Theme.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedContractDriverFilter == driver ? Theme.cyan : Theme.cyan.opacity(0.14))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(8)
        .background(Theme.surface.opacity(0.85))
        .cornerRadius(7)
    }

    private func fmt(_ value: Double) -> String {
        String(format: "$%,.0f", value)
    }

    private func socialColor(_ score: Int) -> Color {
        if score >= 85 { return Theme.green }
        if score >= 70 { return Theme.gold }
        return Theme.red
    }

    private func workEthicColor(_ score: Int) -> Color {
        if score >= 90 { return Theme.green }
        if score >= 78 { return Theme.cyan }
        if score >= 65 { return Theme.gold }
        return Theme.red
    }

    private func clampScore(_ value: Int) -> Int {
        max(30, min(99, value))
    }

    private func trendDelta(_ history: [Int]) -> Int {
        guard let first = history.first, let last = history.last else { return 0 }
        return last - first
    }

    private func trendSymbol(_ delta: Int) -> String {
        if delta > 0 { return "↑" }
        if delta < 0 { return "↓" }
        return "→"
    }

    private func trendColor(_ delta: Int) -> Color {
        if delta > 0 { return Theme.green }
        if delta < 0 { return Theme.red }
        return Theme.muted
    }

    private func daysUntil(_ isoDate: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: isoDate) else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let target = Calendar.current.startOfDay(for: date)
        return Calendar.current.dateComponents([.day], from: start, to: target).day
    }

    private func contractSocialScore(_ contract: ContractAccountItem) -> Int {
        let invoiceRatio = contract.contractValue > 0 ? (contract.invoicedToDate / contract.contractValue) : 0
        let progressRaw = Int((1 - abs(0.68 - invoiceRatio)) * 18)
        let progressScore = max(-12, min(18, progressRaw))

        let statusScore: Int
        switch contract.status {
        case .active: statusScore = 14
        case .pendingInvoice: statusScore = 6
        case .draft: statusScore = 0
        case .atRisk: statusScore = -14
        case .closed: statusScore = 8
        }

        let balanceRatio = contract.contractValue > 0 ? (contract.balance / contract.contractValue) : 0
        let balanceScore = max(-8, min(8, Int((0.35 - balanceRatio) * 20)))

        let renewalScore: Int
        if let days = daysUntil(contract.renewalDate) {
            if days < 30 { renewalScore = -8 }
            else if days < 90 { renewalScore = -3 }
            else if days > 180 { renewalScore = 4 }
            else { renewalScore = 1 }
        } else {
            renewalScore = 0
        }

        let seedScore = Int(Double(contract.socialScore - 70) * 0.4)
        let ethicInfluence = Int(Double(contract.workEthicScore - 75) * 0.3)
        let trendInfluence = max(-6, min(6, trendDelta(contract.socialTrend7d) + trendDelta(contract.workEthicTrend7d)))
        return clampScore(72 + progressScore + statusScore + balanceScore + renewalScore + seedScore + ethicInfluence + trendInfluence)
    }

    private func projectSocialScore(_ project: ProjectAccountItem) -> Int {
        let billingRatio = project.approvedBudget > 0 ? (project.billedToDate / project.approvedBudget) : 0
        let billingRaw = Int((1 - abs(0.72 - billingRatio)) * 22)
        let billingScore = max(-10, min(22, billingRaw))

        let retainageScore = max(-10, min(8, Int(8 - project.retainagePct)))

        let ownerScore: Int
        switch project.ownerType {
        case .owner: ownerScore = 3
        case .gc: ownerScore = 6
        case .subcontractor: ownerScore = 1
        }

        let linkedContracts = contracts.filter { $0.projectCode == project.code }
        let contractHealth: Int
        if linkedContracts.isEmpty {
            contractHealth = 0
        } else {
            let linkedAvg = Int((Double(linkedContracts.map { contractSocialScore($0) }.reduce(0, +)) / Double(linkedContracts.count)).rounded())
            contractHealth = max(-10, min(10, linkedAvg - 75))
        }

        let seedScore = Int(Double(project.socialScore - 70) * 0.35)
        return clampScore(70 + billingScore + retainageScore + ownerScore + contractHealth + seedScore)
    }

    private func projectDrivers(_ project: ProjectAccountItem) -> [String] {
        var drivers: [String] = []
        let billingRatio = project.approvedBudget > 0 ? (project.billedToDate / project.approvedBudget) : 0
        if billingRatio >= 0.65 && billingRatio <= 0.80 {
            drivers.append("Billing on target")
        } else if billingRatio < 0.50 {
            drivers.append("Low billing capture")
        } else {
            drivers.append("Billing drift")
        }

        if project.retainagePct >= 9 {
            drivers.append("High retainage")
        } else if project.retainagePct <= 5 {
            drivers.append("Low retainage")
        }

        let linked = contracts.filter { $0.projectCode == project.code }
        if !linked.isEmpty {
            let avgLinked = Int((Double(linked.map { contractSocialScore($0) }.reduce(0, +)) / Double(linked.count)).rounded())
            if avgLinked >= 82 { drivers.append("Strong contract health") }
            if avgLinked < 70 { drivers.append("Weak contract health") }
        }

        return drivers
    }

    private func contractDrivers(_ contract: ContractAccountItem) -> [String] {
        var drivers: [String] = []
        let invoiceRatio = contract.contractValue > 0 ? (contract.invoicedToDate / contract.contractValue) : 0
        if invoiceRatio >= 0.55 && invoiceRatio <= 0.85 {
            drivers.append("Invoice pace healthy")
        } else if invoiceRatio < 0.40 {
            drivers.append("Invoice lag")
        } else {
            drivers.append("Near ceiling")
        }

        switch contract.status {
        case .active: drivers.append("Active status")
        case .pendingInvoice: drivers.append("Pending invoice")
        case .atRisk: drivers.append("At-risk status")
        case .draft: drivers.append("Draft stage")
        case .closed: drivers.append("Closed contract")
        }

        if let days = daysUntil(contract.renewalDate) {
            if days < 45 { drivers.append("Renewal due soon") }
            if days > 180 { drivers.append("Renewal runway") }
        }

        return drivers
    }

    private func addProject() {
        guard !newProjectCode.isEmpty, !newProjectName.isEmpty, !newProjectOwner.isEmpty,
              let budget = Double(newProjectBudget) else { return }
        let retainage = Double(newProjectRetainage) ?? 5
        projects.append(ProjectAccountItem(
            code: newProjectCode,
            projectName: newProjectName,
            ownerName: newProjectOwner,
            ownerType: .owner,
            approvedBudget: budget,
            billedToDate: 0,
            retainagePct: retainage,
            socialScore: 72
        ))
        newProjectCode = ""
        newProjectName = ""
        newProjectOwner = ""
        newProjectBudget = ""
        newProjectRetainage = ""
        showProjectForm = false
    }

    private func addContract() {
        guard !newContractNo.isEmpty, !newContractProject.isEmpty, !newContractPartner.isEmpty,
              let value = Double(newContractValue) else { return }
        contracts.append(ContractAccountItem(
            contractNo: newContractNo,
            projectCode: newContractProject,
            partner: newContractPartner,
            contractValue: value,
            invoicedToDate: 0,
            status: .draft,
            renewalDate: newContractRenewal.isEmpty ? "TBD" : newContractRenewal,
            socialScore: 70,
            workEthicScore: 72,
            socialTrend7d: [66, 67, 68, 69, 69, 70, 70],
            workEthicTrend7d: [68, 69, 70, 71, 71, 72, 72]
        ))
        newContractNo = ""
        newContractProject = ""
        newContractPartner = ""
        newContractValue = ""
        newContractRenewal = ""
        showContractForm = false
    }

    private func exportAccountSnapshot() {
        let projectLines = projects.map {
            "[\($0.code)] \($0.projectName) | Owner: \($0.ownerName) | Budget: \(fmt($0.approvedBudget)) | Billed: \(fmt($0.billedToDate)) | Remaining: \(fmt($0.remaining)) | Social: \(projectSocialScore($0))"
        }
        let contractLines = contracts.map {
            "[\($0.contractNo)] \($0.partner) | Project: \($0.projectCode) | Value: \(fmt($0.contractValue)) | Invoiced: \(fmt($0.invoicedToDate)) | Balance: \(fmt($0.balance)) | Status: \($0.status.rawValue) | Social: \(contractSocialScore($0)) (Wk \(trendSymbol(trendDelta($0.socialTrend7d)))\(trendDelta($0.socialTrend7d))) | Work Ethic: \($0.workEthicScore) (Wk \(trendSymbol(trendDelta($0.workEthicTrend7d)))\(trendDelta($0.workEthicTrend7d)))"
        }

        let payload = [
            "PROJECT + CONTRACT ACCOUNT SNAPSHOT",
            "",
            "Project Budget: \(fmt(totalBudget)) | Project Billed: \(fmt(totalBilled))",
            "Contract Value: \(fmt(totalContractValue)) | Open Balance: \(fmt(totalContractOpenBalance))",
            "Project Social Score: \(avgProjectSocialScore) | Contract Social Score: \(avgContractSocialScore)",
            "Contract Work Ethic Score: \(avgContractWorkEthicScore)",
            "",
            "PROJECT ACCOUNTS",
            projectLines.joined(separator: "\n"),
            "",
            "CONTRACT ACCOUNTS",
            contractLines.joined(separator: "\n")
        ].joined(separator: "\n")

        copyTextToClipboard(payload)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROJECT & CONTRACT ACCOUNT MANAGEMENT")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundColor(Theme.accent)
                    Text("\(projects.count) projects | \(contracts.count) contracts")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Button("EXPORT") { exportAccountSnapshot() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.accent)
                    .cornerRadius(5)
                Button(showProjectForm ? "CANCEL PROJECT" : "+ PROJECT") { showProjectForm.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.cyan)
                    .cornerRadius(5)
                Button(showContractForm ? "CANCEL CONTRACT" : "+ CONTRACT") { showContractForm.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.green)
                    .cornerRadius(5)
                Button(showSocialDrivers ? "HIDE DRIVERS" : "SOCIAL DRIVERS") { showSocialDrivers.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.gold)
                    .cornerRadius(5)
            }

            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(fmt(totalBudget)).font(.system(size: 12, weight: .black)).foregroundColor(Theme.accent)
                    Text("PROJECT BUDGET").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text(fmt(totalBilled)).font(.system(size: 12, weight: .black)).foregroundColor(Theme.cyan)
                    Text("PROJECT BILLED").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text(fmt(totalContractValue)).font(.system(size: 12, weight: .black)).foregroundColor(Theme.gold)
                    Text("CONTRACT VALUE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text(fmt(totalContractOpenBalance)).font(.system(size: 12, weight: .black)).foregroundColor(Theme.green)
                    Text("OPEN BALANCE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(avgProjectSocialScore)/\(avgContractSocialScore)").font(.system(size: 12, weight: .black)).foregroundColor(Theme.gold)
                    Text("SOCIAL P/C").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
            }

            if showSocialDrivers {
                socialDriversPanel
            }

            if showProjectForm {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Code", text: $newProjectCode)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 80)
                        TextField("Project Name", text: $newProjectName)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Owner", text: $newProjectOwner)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                    }
                    HStack(spacing: 6) {
                        TextField("Budget", text: $newProjectBudget)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 100)
                        TextField("Retainage %", text: $newProjectRetainage)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 90)
                        Button("ADD PROJECT") { addProject() }
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.cyan)
                            .cornerRadius(6)
                    }
                }
            }

            if showContractForm {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Contract No", text: $newContractNo)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 100)
                        TextField("Project Code", text: $newContractProject)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 90)
                        TextField("Partner", text: $newContractPartner)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                    }
                    HStack(spacing: 6) {
                        TextField("Contract Value", text: $newContractValue)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 120)
                        TextField("Renewal (YYYY-MM-DD)", text: $newContractRenewal)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 150)
                        Button("ADD CONTRACT") { addContract() }
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.green)
                            .cornerRadius(6)
                    }
                }
            }

            HStack(spacing: 6) {
                Text("PROJECT ACCOUNTS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.gold)
                if let selectedProjectDriverFilterValue = selectedProjectDriverFilter {
                    Text(selectedProjectDriverFilterValue.uppercased())
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.gold)
                        .cornerRadius(5)
                    Button("CLEAR") { selectedProjectDriverFilter = nil }
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 6) {
                Text("CODE").frame(width: 65, alignment: .leading)
                Text("PROJECT").frame(maxWidth: .infinity, alignment: .leading)
                Text("OWNER").frame(width: 110, alignment: .leading)
                Text("SOC").frame(width: 44, alignment: .center)
                Text("BUDGET").frame(width: 90, alignment: .trailing)
                Text("BILLED").frame(width: 90, alignment: .trailing)
                Text("REMAIN").frame(width: 90, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(Theme.muted)

            ForEach(visibleProjects) { project in
                HStack(spacing: 6) {
                    Text(project.code)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.cyan)
                        .frame(width: 65, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(project.projectName).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text)
                        Text("Retainage \(String(format: "%.1f", project.retainagePct))%")
                            .font(.system(size: 8)).foregroundColor(Theme.muted)
                        if showSocialDrivers {
                            Text(projectDrivers(project).joined(separator: " · "))
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundColor(socialColor(projectSocialScore(project)))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(project.ownerName)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(project.ownerType.color)
                        .frame(width: 110, alignment: .leading)
                    Text("\(projectSocialScore(project))")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(socialColor(projectSocialScore(project)))
                        .cornerRadius(5)
                        .frame(width: 44, alignment: .center)
                    Text(fmt(project.approvedBudget)).font(.system(size: 9)).foregroundColor(Theme.accent)
                        .frame(width: 90, alignment: .trailing)
                    Text(fmt(project.billedToDate)).font(.system(size: 9)).foregroundColor(Theme.cyan)
                        .frame(width: 90, alignment: .trailing)
                    Text(fmt(project.remaining)).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.green)
                        .frame(width: 90, alignment: .trailing)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(7)
            }

            HStack(spacing: 6) {
                Text("CONTRACT ACCOUNTS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.cyan)
                if let selectedContractDriverFilterValue = selectedContractDriverFilter {
                    Text(selectedContractDriverFilterValue.uppercased())
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.cyan)
                        .cornerRadius(5)
                    Button("CLEAR") { selectedContractDriverFilter = nil }
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 8) {
                Button("ALL") { contractFilter = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(contractFilter == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(contractFilter == nil ? Theme.accent : Theme.surface)
                    .cornerRadius(4)
                ForEach(ContractAccountStatus.allCases, id: \.rawValue) { status in
                    Button(status.rawValue) {
                        contractFilter = (contractFilter == status) ? nil : status
                    }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(contractFilter == status ? .black : Theme.muted)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(contractFilter == status ? status.color : Theme.surface)
                    .cornerRadius(4)
                }
            }

            ForEach(visibleContracts) { contract in
                let socialDelta = trendDelta(contract.socialTrend7d)
                let ethicDelta = trendDelta(contract.workEthicTrend7d)
                HStack(spacing: 6) {
                    Text(contract.contractNo)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .frame(width: 60, alignment: .leading)
                    Text(contract.projectCode)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Theme.muted)
                        .frame(width: 70, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(contract.partner)
                            .font(.system(size: 9))
                            .foregroundColor(Theme.text)
                        HStack(spacing: 4) {
                            TrendSparkline(values: contract.socialTrend7d, color: Theme.accent)
                                .frame(width: 38, height: 12)
                            TrendSparkline(values: contract.workEthicTrend7d, color: Theme.green)
                                .frame(width: 38, height: 12)
                        }
                        if showSocialDrivers {
                            Text(contractDrivers(contract).joined(separator: " · "))
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundColor(socialColor(contractSocialScore(contract)))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(fmt(contract.contractValue))
                        .font(.system(size: 9))
                        .foregroundColor(Theme.accent)
                        .frame(width: 90, alignment: .trailing)
                    Text(fmt(contract.invoicedToDate))
                        .font(.system(size: 9))
                        .foregroundColor(Theme.cyan)
                        .frame(width: 90, alignment: .trailing)
                    Text(fmt(contract.balance))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(contract.balance > 0 ? Theme.green : Theme.muted)
                        .frame(width: 90, alignment: .trailing)
                    VStack(spacing: 1) {
                        Text(contract.status.rawValue)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(contract.status.color)
                        Text("SOC \(contractSocialScore(contract))")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(socialColor(contractSocialScore(contract)))
                        Text("Wk \(trendSymbol(socialDelta))\(socialDelta)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(trendColor(socialDelta))
                        Text("ETH \(contract.workEthicScore)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(workEthicColor(contract.workEthicScore))
                        Text("Wk \(trendSymbol(ethicDelta))\(ethicDelta)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(trendColor(ethicDelta))
                        Text(contract.renewalDate)
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(Theme.muted)
                    }
                    .frame(width: 110)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(7)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            projects = loadJSON("ConstructOS.Ops.ProjectAccounts", default: projects)
            contracts = loadJSON("ConstructOS.Ops.ContractAccounts", default: contracts)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Executive Portfolio View

struct PortfolioProjectMetric: Identifiable, Codable {
    var id = UUID()
    var projectCode: String
    var projectName: String
    var schedulePct: Double
    var budgetPct: Double
    var incidents30d: Int
    var openRFIs: Int
    var pendingHighDollarCOs: Int
    var deliveryDelays: Int
    var cashExposure: Double
}

struct ExecutivePortfolioPanel: View {
    @State private var metrics: [PortfolioProjectMetric] = [
        PortfolioProjectMetric(projectCode: "P-1024", projectName: "North Deck Expansion", schedulePct: 68, budgetPct: 62, incidents30d: 1, openRFIs: 4, pendingHighDollarCOs: 1, deliveryDelays: 1, cashExposure: 210_000),
        PortfolioProjectMetric(projectCode: "P-1188", projectName: "Medical Tower TI", schedulePct: 53, budgetPct: 59, incidents30d: 3, openRFIs: 9, pendingHighDollarCOs: 2, deliveryDelays: 2, cashExposure: 480_000),
        PortfolioProjectMetric(projectCode: "P-1201", projectName: "East Utility Rehab", schedulePct: 77, budgetPct: 73, incidents30d: 1, openRFIs: 2, pendingHighDollarCOs: 0, deliveryDelays: 0, cashExposure: 120_000),
        PortfolioProjectMetric(projectCode: "P-1216", projectName: "Airport Utility Relocation", schedulePct: 46, budgetPct: 51, incidents30d: 4, openRFIs: 11, pendingHighDollarCOs: 3, deliveryDelays: 3, cashExposure: 530_000),
    ]

    @State private var showOnlyHighRisk = false
    @State private var showWeightControls = false
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.Schedule") private var scheduleWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.Budget") private var budgetWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.Incidents") private var incidentWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.RFIs") private var rfiWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.HighCO") private var coWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.Delays") private var delayWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.Exposure") private var exposureWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Preset") private var activePreset: String = "Balanced"
    @AppStorage("ConstructOS.ExecutiveRisk.Preset.LastNamed") private var lastNamedPreset: String = "Balanced"

    private let presetTolerance: Double = 0.05

    private var visibleMetrics: [PortfolioProjectMetric] {
        metrics.filter { !showOnlyHighRisk || riskScore(for: $0) >= 70 }
    }

    private var totalExposure: Double { visibleMetrics.map { $0.cashExposure }.reduce(0, +) }
    private var avgRisk: Int {
        guard !visibleMetrics.isEmpty else { return 0 }
        let total = visibleMetrics.map { riskScore(for: $0) }.reduce(0, +)
        return total / visibleMetrics.count
    }
    private var delayedCount: Int { visibleMetrics.filter { $0.schedulePct < 60 }.count }
    private var budgetStressCount: Int { visibleMetrics.filter { $0.budgetPct > $0.schedulePct + 5 }.count }

    private func fmt(_ value: Double) -> String {
        String(format: "$%,.0f", value)
    }

    private func riskScore(for item: PortfolioProjectMetric) -> Int {
        let scheduleRisk = max(0, 70 - item.schedulePct) * 1.4 * scheduleWeight
        let budgetRisk = max(0, item.budgetPct - item.schedulePct) * 2.2 * budgetWeight
        let incidentRisk = min(Double(item.incidents30d) * 6 * incidentWeight, 24 * incidentWeight)
        let rfiRisk = min(Double(item.openRFIs) * 1.8 * rfiWeight, 18 * rfiWeight)
        let coRisk = min(Double(item.pendingHighDollarCOs) * 7 * coWeight, 21 * coWeight)
        let delayRisk = min(Double(item.deliveryDelays) * 5 * delayWeight, 15 * delayWeight)
        let exposureRisk = min((item.cashExposure / 80_000) * exposureWeight, 20 * exposureWeight)
        let raw = scheduleRisk + budgetRisk + incidentRisk + rfiRisk + coRisk + delayRisk + exposureRisk
        return Int(min(100, raw).rounded())
    }

    private func riskColor(for score: Int) -> Color {
        if score >= 75 { return Theme.red }
        if score >= 50 { return Theme.gold }
        return Theme.green
    }

    private func applyPreset(_ preset: String) {
        switch preset {
        case "Conservative":
            scheduleWeight = 1.2
            budgetWeight = 1.3
            incidentWeight = 1.4
            rfiWeight = 1.3
            coWeight = 1.5
            delayWeight = 1.4
            exposureWeight = 1.2
        case "Aggressive":
            scheduleWeight = 0.9
            budgetWeight = 1.0
            incidentWeight = 0.8
            rfiWeight = 0.8
            coWeight = 1.0
            delayWeight = 0.8
            exposureWeight = 0.9
        default:
            scheduleWeight = 1.0
            budgetWeight = 1.0
            incidentWeight = 1.0
            rfiWeight = 1.0
            coWeight = 1.0
            delayWeight = 1.0
            exposureWeight = 1.0
        }
        activePreset = preset
        if preset != "Custom" {
            lastNamedPreset = preset
        }
    }

    private func approximatelyEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) <= presetTolerance
    }

    private func resolvePresetFromWeights() -> String {
        if approximatelyEqual(scheduleWeight, 1.2) &&
            approximatelyEqual(budgetWeight, 1.3) &&
            approximatelyEqual(incidentWeight, 1.4) &&
            approximatelyEqual(rfiWeight, 1.3) &&
            approximatelyEqual(coWeight, 1.5) &&
            approximatelyEqual(delayWeight, 1.4) &&
            approximatelyEqual(exposureWeight, 1.2) {
            return "Conservative"
        }

        if approximatelyEqual(scheduleWeight, 0.9) &&
            approximatelyEqual(budgetWeight, 1.0) &&
            approximatelyEqual(incidentWeight, 0.8) &&
            approximatelyEqual(rfiWeight, 0.8) &&
            approximatelyEqual(coWeight, 1.0) &&
            approximatelyEqual(delayWeight, 0.8) &&
            approximatelyEqual(exposureWeight, 0.9) {
            return "Aggressive"
        }

        if approximatelyEqual(scheduleWeight, 1.0) &&
            approximatelyEqual(budgetWeight, 1.0) &&
            approximatelyEqual(incidentWeight, 1.0) &&
            approximatelyEqual(rfiWeight, 1.0) &&
            approximatelyEqual(coWeight, 1.0) &&
            approximatelyEqual(delayWeight, 1.0) &&
            approximatelyEqual(exposureWeight, 1.0) {
            return "Balanced"
        }

        return "Custom"
    }

    private func syncPresetLabelFromWeights() {
        let resolved = resolvePresetFromWeights()
        activePreset = resolved
        if resolved != "Custom" {
            lastNamedPreset = resolved
        }
    }

    private func resetWeights() {
        applyPreset("Balanced")
    }

    private func presetButton(_ label: String, color: Color) -> some View {
        Button(label) { applyPreset(label) }
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(activePreset == label ? .black : Theme.muted)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(activePreset == label ? color : Theme.surface)
            .cornerRadius(4)
    }

    private func weightRow(_ label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.muted)
                .frame(width: 72, alignment: .leading)
            Slider(value: value, in: 0.5...2.0, step: 0.1)
                .tint(Theme.accent)
                .onChange(of: value.wrappedValue) { _, _ in
                    syncPresetLabelFromWeights()
                }
            Text(String(format: "%.1fx", value.wrappedValue))
                .font(.system(size: 8, weight: .black))
                .foregroundColor(Theme.cyan)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private func exportPortfolioBrief() {
        let rows = visibleMetrics.map {
            "[\($0.projectCode)] \($0.projectName) | Sched \(Int($0.schedulePct))% | Budget \(Int($0.budgetPct))% | Risk \(riskScore(for: $0)) | Inc \($0.incidents30d) | RFI \($0.openRFIs) | CO \($0.pendingHighDollarCOs) | Delay \($0.deliveryDelays) | Exposure \(fmt($0.cashExposure))"
        }
        let payload = [
            "EXECUTIVE PORTFOLIO BRIEF",
            "Projects: \(visibleMetrics.count) | Avg Risk: \(avgRisk) | Delayed: \(delayedCount) | Budget Stress: \(budgetStressCount)",
            "Cash Exposure: \(fmt(totalExposure))",
            "",
            rows.joined(separator: "\n")
        ].joined(separator: "\n")
        copyTextToClipboard(payload)
    }

    private func progressBar(_ value: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface)
                Capsule().fill(color).frame(width: geo.size.width * CGFloat(max(0, min(value, 100))) / 100)
            }
        }
        .frame(height: 6)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DashboardPanelHeading(
                    eyebrow: "EXECUTIVE VIEW",
                    title: "Portfolio risk and cash exposure",
                    detail: "Signal blends schedule, budget, incidents, RFIs, change pressure, delivery delays, and exposure.",
                    accent: Theme.accent
                )
                Spacer()
                Button(showOnlyHighRisk ? "SHOW ALL" : "HIGH RISK ONLY") { showOnlyHighRisk.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.cyan)
                    .cornerRadius(5)
                Button(showWeightControls ? "HIDE WEIGHTS" : "TUNE WEIGHTS") { showWeightControls.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.gold)
                    .cornerRadius(5)
                Button("EXPORT BRIEF") { exportPortfolioBrief() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.accent)
                    .cornerRadius(5)
            }

            HStack(spacing: 14) {
                DashboardStatPill(value: "\(visibleMetrics.count)", label: "PROJECTS", color: Theme.accent)
                DashboardStatPill(value: "\(avgRisk)", label: "AVG RISK", color: avgRisk >= 70 ? Theme.red : (avgRisk >= 50 ? Theme.gold : Theme.green))
                DashboardStatPill(value: "\(delayedCount)", label: "DELAYED", color: delayedCount > 0 ? Theme.red : Theme.green)
                DashboardStatPill(value: fmt(totalExposure), label: "CASH EXPOSURE", color: Theme.gold)
            }

            if showWeightControls {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("PRESET")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.muted)
                        presetButton("Conservative", color: Theme.red)
                        presetButton("Balanced", color: Theme.accent)
                        presetButton("Aggressive", color: Theme.green)
                        Spacer()
                        Text(activePreset == "Custom" ? "CUSTOM · BASE \(lastNamedPreset.uppercased())" : activePreset.uppercased())
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(activePreset == "Custom" ? Theme.gold : Theme.cyan)
                    }
                    weightRow("Schedule", value: $scheduleWeight)
                    weightRow("Budget", value: $budgetWeight)
                    weightRow("Incidents", value: $incidentWeight)
                    weightRow("RFIs", value: $rfiWeight)
                    weightRow("High CO", value: $coWeight)
                    weightRow("Delays", value: $delayWeight)
                    weightRow("Exposure", value: $exposureWeight)
                    HStack {
                        if activePreset == "Custom" {
                            Button("REVERT TO \(lastNamedPreset.uppercased())") {
                                applyPreset(lastNamedPreset)
                            }
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.gold)
                            .cornerRadius(5)
                        }
                        Spacer()
                        Button("RESET DEFAULT WEIGHTS") { resetWeights() }
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.green)
                            .cornerRadius(5)
                    }
                }
                .padding(8)
                .background(Theme.surface.opacity(0.8))
                .cornerRadius(8)
            }

            Text("PROJECT HEATMAP")
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.gold)

            HStack(spacing: 6) {
                Text("CODE").frame(width: 60, alignment: .leading)
                Text("PROJECT").frame(maxWidth: .infinity, alignment: .leading)
                Text("SCHEDULE").frame(width: 110, alignment: .center)
                Text("BUDGET").frame(width: 110, alignment: .center)
                Text("RISK").frame(width: 45, alignment: .trailing)
                Text("EXPOSURE").frame(width: 95, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(Theme.muted)

            ForEach(visibleMetrics) { item in
                HStack(spacing: 6) {
                    Text(item.projectCode)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.cyan)
                        .frame(width: 60, alignment: .leading)
                    Text(item.projectName)
                        .font(.system(size: 9))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 2) {
                        Text("\(Int(item.schedulePct))%")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(item.schedulePct < 60 ? Theme.red : Theme.green)
                        progressBar(item.schedulePct, color: item.schedulePct < 60 ? Theme.red : Theme.green)
                    }
                    .frame(width: 110)

                    VStack(spacing: 2) {
                        Text("\(Int(item.budgetPct))%")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(item.budgetPct > item.schedulePct + 5 ? Theme.red : Theme.cyan)
                        progressBar(item.budgetPct, color: item.budgetPct > item.schedulePct + 5 ? Theme.red : Theme.cyan)
                    }
                    .frame(width: 110)

                    let score = riskScore(for: item)
                    Text("\(score)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(riskColor(for: score))
                        .frame(width: 45, alignment: .trailing)
                    Text(fmt(item.cashExposure))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .frame(width: 95, alignment: .trailing)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(8)
            }
        }
        .onAppear {
            syncPresetLabelFromWeights()
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            metrics = loadJSON("ConstructOS.Ops.PortfolioMetrics", default: metrics)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - RFI Tracker

struct RFIItem: Identifiable, Codable {
    let id: Int
    let subject: String
    let assignedTo: String
    let submittedDaysAgo: Int
    let priority: RFIPriority
    var status: RFIStatus = .open
}

enum RFIPriority: String, Codable {
    case high = "HIGH"
    case medium = "MED"
    case low = "LOW"
    var color: Color {
        switch self {
        case .high: return Theme.red
        case .medium: return Theme.accent
        case .low: return Theme.muted
        }
    }
}

enum RFIStatus: String, Codable {
    case open = "OPEN"
    case pending = "PENDING"
    case answered = "ANSWERED"
    var color: Color {
        switch self {
        case .open: return Theme.accent
        case .pending: return Color.orange
        case .answered: return Theme.green
        }
    }
}

struct RFITrackerPanel: View {
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"
    private var role: OpsRolePreset { OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent }
    @State private var expanded: Bool = false
    @State private var escalatedIDs: Set<Int> = []

    @State private var items: [RFIItem] = [
        RFIItem(id: 221, subject: "Structural beam spec — Grid C-4", assignedTo: "Thornfield Eng", submittedDaysAgo: 18, priority: .high),
        RFIItem(id: 218, subject: "Fire suppression riser relocation", assignedTo: "MEP Lead", submittedDaysAgo: 11, priority: .high),
        RFIItem(id: 215, subject: "Façade anchor bolt tolerance", assignedTo: "Architect", submittedDaysAgo: 7, priority: .medium),
        RFIItem(id: 209, subject: "Flooring transition detail — Level 3", assignedTo: "Interior Spec", submittedDaysAgo: 4, priority: .low),
        RFIItem(id: 204, subject: "Electrical panel clearance — Room 214", assignedTo: "MEP Lead", submittedDaysAgo: 14, priority: .medium, status: .pending),
        RFIItem(id: 199, subject: "Roof drain sizing confirmation", assignedTo: "Civil Eng", submittedDaysAgo: 21, priority: .high),
    ]

    private var overdueItems: [RFIItem] {
        items.filter { $0.submittedDaysAgo > 14 && $0.status != .answered }
    }

    private var visibleItems: [RFIItem] {
        switch role {
        case .superintendent:
            return items.filter { $0.priority == .high || $0.submittedDaysAgo > 10 }
        case .projectManager:
            return items
        case .executive:
            return overdueItems
        }
    }

    private var roleNote: String {
        switch role {
        case .superintendent: return "Field-blocking RFIs — high priority + aging."
        case .projectManager: return "Full open RFI queue — tap overdue rows to escalate."
        case .executive: return "Escalated & overdue RFIs. Avg response target: 7 days."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                DashboardPanelHeading(
                    eyebrow: "COORDINATION",
                    title: "RFI tracker",
                    detail: "Open questions, aging responses, and escalation pressure across design coordination.",
                    accent: Theme.text
                )
                Spacer()
                if !overdueItems.isEmpty {
                    Text("\(overdueItems.count) OVERDUE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.red)
                        .cornerRadius(4)
                }
                Text("\(items.filter { $0.status != .answered }.count) OPEN")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.accent)
                    .cornerRadius(4)
                Button(action: { withAnimation { expanded.toggle() } }) {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.muted)
                }
                .accessibilityLabel(expanded ? "Collapse section" : "Expand section")
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)

            HStack(spacing: 8) {
                DashboardStatPill(value: "\(items.filter { $0.status != .answered }.count)", label: "OPEN", color: Theme.accent)
                DashboardStatPill(value: "\(overdueItems.count)", label: "OVERDUE", color: overdueItems.isEmpty ? Theme.green : Theme.red)
                DashboardStatPill(value: role.display.uppercased(), label: "ROLE FILTER", color: Theme.cyan)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Text(roleNote)
                .font(.system(size: 10))
                .foregroundColor(Theme.muted)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

            Divider().background(Theme.border)

            if role == .executive && !expanded {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(overdueItems.count)")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(overdueItems.isEmpty ? Theme.green : Theme.red)
                        Text("OVERDUE RFIs")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.muted)
                            .tracking(1)
                    }
                    Divider().frame(height: 36).background(Theme.border)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(items.filter { $0.status != .answered }.count)")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(Theme.accent)
                        Text("TOTAL OPEN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.muted)
                            .tracking(1)
                    }
                    Spacer()
                    Button("VIEW ALL") { withAnimation { expanded = true } }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            } else {
                ForEach(visibleItems) { item in
                    RFIRow(
                        item: item,
                        isEscalated: escalatedIDs.contains(item.id),
                        showEscalate: role == .projectManager && item.submittedDaysAgo > 10,
                        onEscalate: { escalatedIDs.insert(item.id) }
                    )
                    Divider().background(Theme.border).padding(.leading, 14)
                }
            }
        }
        .background(Theme.panel)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(overdueItems.isEmpty ? Theme.border : Theme.red.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .onAppear {
            items = loadJSON("ConstructOS.Ops.RFIs", default: items)
        }
    }
}

struct RFIRow: View {
    let item: RFIItem
    let isEscalated: Bool
    let showEscalate: Bool
    let onEscalate: () -> Void
    private var isOverdue: Bool { item.submittedDaysAgo > 14 && item.status != .answered }
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Rectangle()
                .fill(item.priority.color)
                .frame(width: 3, height: 44)
                .cornerRadius(2)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("RFI-\(item.id)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(Theme.muted)
                    Text(item.priority.rawValue)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(item.priority.color)
                        .cornerRadius(3)
                    Text(item.status.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(item.status.color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(item.status.color, lineWidth: 1))
                }
                Text(item.subject)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isOverdue ? Theme.red : Theme.text)
                    .lineLimit(1)
                Text(item.assignedTo)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.submittedDaysAgo)d")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(isOverdue ? Theme.red : Theme.muted)
                Text("AGO")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Theme.muted)
                    .tracking(1)
            }
            if showEscalate {
                Button(isEscalated ? "✓ ESC" : "ESCALATE") { onEscalate() }
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(isEscalated ? Theme.green : .white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(isEscalated ? Theme.green.opacity(0.15) : Theme.red)
                    .cornerRadius(5)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isOverdue ? Theme.red.opacity(0.05) : Color.clear)
    }
}

// MARK: - Budget Burn Rate

struct SiteBudget: Identifiable {
    let id: Int
    let site: String
    let budgetM: Double
    let spentM: Double
    let percentComplete: Int
}

struct BudgetBurnPanel: View {
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let budgets: [SiteBudget] = [
        SiteBudget(id: 0, site: "Riverside Lofts",   budgetM: 12.4, spentM: 9.8,  percentComplete: 62),
        SiteBudget(id: 1, site: "Site Gamma",         budgetM: 8.1,  spentM: 5.3,  percentComplete: 55),
        SiteBudget(id: 2, site: "Harbor Crossing",    budgetM: 22.6, spentM: 11.2, percentComplete: 48),
        SiteBudget(id: 3, site: "Pine Ridge Ph.2",    budgetM: 6.8,  spentM: 4.1,  percentComplete: 58),
        SiteBudget(id: 4, site: "Eastside Civic Hub", budgetM: 4.2,  spentM: 1.3,  percentComplete: 29),
    ]

    private var totalBudget: Double { budgets.map(\.budgetM).reduce(0, +) }
    private var totalSpent:  Double { budgets.map(\.spentM).reduce(0, +) }
    private var overBudgetSites: [SiteBudget] { budgets.filter { burnRatio($0) > 1.10 } }

    private func burnRatio(_ s: SiteBudget) -> Double {
        guard s.percentComplete > 0 else { return 0 }
        let spentPct = s.spentM / s.budgetM
        let schedPct = Double(s.percentComplete) / 100.0
        return spentPct / schedPct
    }

    private func burnLabel(_ s: SiteBudget) -> String {
        let r = burnRatio(s)
        if r > 1.10 { return "OVER PACE" }
        if r < 0.85 { return "UNDER" }
        return "ON PACE"
    }

    private func burnColor(_ s: SiteBudget) -> Color {
        let r = burnRatio(s)
        if r > 1.10 { return Theme.red }
        if r < 0.85 { return Theme.cyan }
        return Theme.green
    }

    private var portfolioLabel: String {
        let pct = totalBudget > 0 ? Int((totalSpent / totalBudget) * 100) : 0
        return "$\(String(format: "%.1f", totalSpent))M of $\(String(format: "%.1f", totalBudget))M (\(pct)%)"
    }

    private var roleNote: String {
        switch role {
        case .superintendent: return "Labor & material burn on your sites"
        case .projectManager: return overBudgetSites.isEmpty ? "All sites on budget trajectory" : "\(overBudgetSites.count) site(s) burning over pace"
        case .executive:      return "Portfolio: \(portfolioLabel)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("BUDGET BURN")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(overBudgetSites.isEmpty ? Theme.green : Theme.red)
                if !overBudgetSites.isEmpty {
                    Text("\(overBudgetSites.count) OVER PACE")
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
            VStack(spacing: 7) {
                ForEach(budgets) { site in
                    BudgetBurnRow(
                        site:      site,
                        burnLabel: burnLabel(site),
                        burnColor: burnColor(site),
                        showSpend: role != .superintendent
                    )
                }
            }
            Divider().background(Theme.border)
            HStack {
                Text("PORTFOLIO TOTAL")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(Theme.muted)
                Spacer()
                Text(portfolioLabel)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.text)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: overBudgetSites.isEmpty ? Theme.green : Theme.red)
    }
}

struct BudgetBurnRow: View {
    let site: SiteBudget
    let burnLabel: String
    let burnColor: Color
    let showSpend: Bool

    private var spentPct: Double {
        site.budgetM > 0 ? min(site.spentM / site.budgetM, 1.0) : 0
    }
    private var schedPct: Double { Double(site.percentComplete) / 100.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(site.site)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                Spacer()
                if showSpend {
                    Text("$\(String(format: "%.1f", site.spentM))M / $\(String(format: "%.1f", site.budgetM))M")
                        .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                        .foregroundColor(Theme.muted)
                }
                Text(burnLabel)
                    .font(.system(size: 7.5, weight: .heavy))
                    .foregroundColor(burnColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(burnColor.opacity(0.14))
                    .cornerRadius(4)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surface)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.muted.opacity(0.25))
                        .frame(width: geo.size.width * schedPct, height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(burnColor.opacity(0.80))
                        .frame(width: geo.size.width * spentPct, height: 5)
                        .padding(.vertical, 1.5)
                    Rectangle()
                        .fill(Theme.muted.opacity(0.6))
                        .frame(width: 1.5, height: 12)
                        .offset(x: geo.size.width * schedPct - 0.75)
                }
            }
            .frame(height: 8)
            HStack {
                Text("Spent \(Int(spentPct * 100))%")
                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(burnColor.opacity(0.9))
                Text("Schedule \(site.percentComplete)%")
                    .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                    .foregroundColor(Theme.muted)
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(burnColor == Theme.red ? Theme.red.opacity(0.06) : Theme.surface.opacity(0.4))
        .cornerRadius(7)
    }
}
