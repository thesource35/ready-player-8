import Foundation
import SwiftUI

// MARK: - ========== OperationsCore.swift ==========

// MARK: - Operations Command Center

struct OpsPriorityAlert: Identifiable, Codable {
    var id = UUID()
    let title: String
    let detail: String
    let owner: String
    let severity: Int
    let due: String

    var severityLabel: String {
        if severity >= 3 { return "CRITICAL" }
        if severity == 2 { return "HIGH" }
        return "NORMAL"
    }

    var severityColor: Color {
        if severity >= 3 { return Theme.red }
        if severity == 2 { return Theme.gold }
        return Theme.cyan
    }
}

struct OpsActionQueueItem: Identifiable, Codable {
    var id = UUID()
    let action: String
    let team: String
    let eta: String
    let relatedRef: String
}

struct OperationsCommandCenterPanel: View {
    @State private var alerts: [OpsPriorityAlert] = [
        OpsPriorityAlert(title: "Delayed conduit shipment", detail: "PO-4422 pushed from 03-13 to 03-20. Electrical rough-in impacted.", owner: "Procurement", severity: 3, due: "Today 4PM"),
        OpsPriorityAlert(title: "Open recordable incident", detail: "Grid B-7 fall incident corrective action still open.", owner: "Safety", severity: 3, due: "Today 1PM"),
        OpsPriorityAlert(title: "Pending CO over $20k", detail: "CO-003 foundation depth increase pending owner approval.", owner: "PM", severity: 2, due: "Tomorrow 10AM"),
        OpsPriorityAlert(title: "Inspection prep", detail: "Fire-stopping punch list has 6 unresolved tags.", owner: "Superintendent", severity: 1, due: "Tomorrow 8AM"),
    ]

    @State private var queue: [OpsActionQueueItem] = [
        OpsActionQueueItem(action: "Call Graybar and lock revised delivery truck", team: "Procurement", eta: "45m", relatedRef: "PO-4422"),
        OpsActionQueueItem(action: "Submit CO-003 backup package with geotech memo", team: "PM", eta: "30m", relatedRef: "CO-003"),
        OpsActionQueueItem(action: "Close scaffold harness corrective action", team: "Safety", eta: "25m", relatedRef: "INC-03-14"),
        OpsActionQueueItem(action: "Notify drywall foreman of revised sequence", team: "Field Ops", eta: "15m", relatedRef: "SEQ-DELTA"),
    ]

    @State private var exportStatus: String? = nil

    private var criticalCount: Int { alerts.filter { $0.severity >= 3 }.count }
    private var highCount: Int { alerts.filter { $0.severity == 2 }.count }
    private var dueTodayCount: Int { alerts.filter { $0.due.lowercased().contains("today") }.count }

    private func completeAction(_ item: OpsActionQueueItem) {
        queue.removeAll { $0.id == item.id }
                                    saveJSON("ConstructOS.Ops.ActionQueue", value: queue)
    }

    private func exportDailyCommanderReport() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let header = "CONSTRUCTIONOS DAILY COMMANDER REPORT"
        let generated = "Generated: \(formatter.string(from: Date()))"
        let stats = "Critical: \(criticalCount) | High: \(highCount) | Due Today: \(dueTodayCount) | Queue: \(queue.count)"

        let alertLines = alerts.isEmpty
            ? ["No active priority alerts"]
            : alerts.map { "[\($0.severityLabel)] \($0.title) — \($0.detail) | Owner: \($0.owner) | Due: \($0.due)" }

        let queueLines = queue.isEmpty
            ? ["No open queue actions"]
            : queue.map { "- \($0.action) | Team: \($0.team) | ETA: \($0.eta) | Ref: \($0.relatedRef)" }

        let payload = [
            header,
            generated,
            stats,
            "",
            "PRIORITY ALERTS",
            alertLines.joined(separator: "\n"),
            "",
            "ACTION QUEUE",
            queueLines.joined(separator: "\n")
        ].joined(separator: "\n")

        copyTextToClipboard(payload)
        exportStatus = "Copied superintendent report"
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run { exportStatus = nil }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DashboardPanelHeading(
                    eyebrow: "COMMAND CENTER",
                    title: "Operations command center",
                    detail: "Priority alerts, queue actions, and due-now field work in one coordinated surface.",
                    accent: Theme.accent
                )
                Spacer()
                Button("EXPORT DAILY REPORT") { exportDailyCommanderReport() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.accent)
                    .cornerRadius(6)
            }

            HStack(spacing: 12) {
                DashboardStatPill(value: "\(criticalCount)", label: "CRITICAL", color: Theme.red)
                DashboardStatPill(value: "\(highCount)", label: "HIGH", color: Theme.gold)
                DashboardStatPill(value: "\(queue.count)", label: "OPEN ACTIONS", color: queue.isEmpty ? Theme.green : Theme.cyan)
            }

            Text("PRIORITY ALERTS")
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.gold)

            ForEach(alerts) { alert in
                HStack(alignment: .top, spacing: 10) {
                    Text(alert.severityLabel)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(alert.severityColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(alert.severityColor.opacity(0.12))
                        .cornerRadius(4)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(alert.title)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.text)
                        Text(alert.detail)
                            .font(.system(size: 9))
                            .foregroundColor(Theme.muted)
                            .lineLimit(2)
                        Text("Owner: \(alert.owner) · Due: \(alert.due)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.cyan)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(alert.severityColor.opacity(0.14), lineWidth: 1)
                )
                .cornerRadius(8)
            }

            Text("TODAY ACTION QUEUE")
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.cyan)

            ForEach(queue) { item in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.action)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.text)
                        Text("\(item.team) · ETA \(item.eta) · \(item.relatedRef)")
                            .font(.system(size: 8))
                            .foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Button("DONE") { completeAction(item) }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Theme.green)
                        .cornerRadius(5)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.cyan.opacity(0.12), lineWidth: 1)
                )
                .cornerRadius(8)
            }

            if let exportStatus {
                Text(exportStatus)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.green)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            alerts = loadJSON("ConstructOS.Ops.Alerts", default: alerts)
            queue = loadJSON("ConstructOS.Ops.ActionQueue", default: queue)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Change Order Tracker

enum ChangeOrderStatus: String, CaseIterable, Codable {
    case pending  = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case void     = "VOID"

    var color: Color {
        switch self {
        case .pending:  return Theme.gold
        case .approved: return Theme.green
        case .rejected: return Theme.red
        case .void:     return Theme.muted
        }
    }
}

struct ChangeOrderItem: Identifiable, Codable {
    var id = UUID()
    var number: String
    var title: String
    var costImpact: Double
    var scheduleDays: Int
    var status: ChangeOrderStatus
    var submittedDate: String
    var decidedDate: String
    var description: String
}

struct ChangeOrderTrackerPanel: View {
    @State private var items: [ChangeOrderItem] = [
        ChangeOrderItem(number: "CO-001", title: "Structural Steel Upgrade", costImpact: 14_800, scheduleDays: 3, status: .approved, submittedDate: "03-01", decidedDate: "03-04", description: "Owner requested heavier gauge column steel per revised structural drawings."),
        ChangeOrderItem(number: "CO-002", title: "Electrical Panel Relocation", costImpact: 6_200, scheduleDays: 2, status: .pending, submittedDate: "03-09", decidedDate: "", description: "Relocate main service panel 12 ft to accommodate updated floor plan."),
        ChangeOrderItem(number: "CO-003", title: "Foundation Depth Increase", costImpact: 22_500, scheduleDays: 5, status: .pending, submittedDate: "03-11", decidedDate: "", description: "Geotech report requires additional 18\" bearing depth at grid lines B3-B7."),
        ChangeOrderItem(number: "CO-004", title: "Deleted Decorative Façade", costImpact: -8_400, scheduleDays: -1, status: .approved, submittedDate: "02-22", decidedDate: "02-25", description: "Owner deleted premium stone cladding in favor of standard EIFS."),
        ChangeOrderItem(number: "CO-005", title: "HVAC Scope Addition", costImpact: 11_300, scheduleDays: 4, status: .rejected, submittedDate: "03-05", decidedDate: "03-08", description: "Sub requested add to supply ventilation to server room — rejected, owner to self-perform."),
    ]
    @State private var filterStatus: ChangeOrderStatus? = nil
    @State private var showAdd = false
    @State private var newNumber = ""
    @State private var newTitle = ""
    @State private var newCost = ""
    @State private var newDays = ""
    @State private var newDesc = ""
    @State private var selectedStatus: ChangeOrderStatus = .pending
    @State private var exportStatus: String? = nil

    private var filtered: [ChangeOrderItem] {
        guard let f = filterStatus else { return items }
        return items.filter { $0.status == f }
    }

    private var approvedTotal: Double { items.filter { $0.status == .approved }.reduce(0) { $0 + $1.costImpact } }
    private var pendingCount: Int    { items.filter { $0.status == .pending  }.count }
    private var rejectedCount: Int   { items.filter { $0.status == .rejected }.count }

    private func addItem() {
        guard !newNumber.trimmingCharacters(in: .whitespaces).isEmpty,
              !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        let today = formatter.string(from: Date())
        let cost = Double(newCost) ?? 0
        let days = Int(newDays) ?? 0
        let item = ChangeOrderItem(number: newNumber.uppercased(), title: newTitle, costImpact: cost,
                                    scheduleDays: days, status: selectedStatus,
                                    submittedDate: today, decidedDate: selectedStatus == .pending ? "" : today,
                                    description: newDesc)
        items.insert(item, at: 0)
        saveJSON("ConstructOS.Ops.ChangeOrders", value: items)
        newNumber = ""; newTitle = ""; newCost = ""; newDays = ""; newDesc = ""
        selectedStatus = .pending
        showAdd = false
    }

    private func exportLog() {
        let lines = items.map { "\($0.number) | \($0.title) | $\(String(format: "%.0f", $0.costImpact)) | \($0.scheduleDays)d sched | \($0.status.rawValue) | Sub: \($0.submittedDate)" }
        let payload = (["CHANGE ORDER LOG", "Approved Net: $\(String(format: "%.0f", approvedTotal))", ""] + lines).joined(separator: "\n")
        copyTextToClipboard(payload)
        exportStatus = "Copied \(items.count) change orders"
        Task { try? await Task.sleep(nanoseconds: 3_000_000_000); await MainActor.run { exportStatus = nil } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CHANGE ORDER TRACKER")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundColor(Theme.gold)
                    Text("\(items.count) orders · Net approved: \(approvedTotal >= 0 ? "+" : "")$\(String(format: "%.0f", approvedTotal))")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Button("+ ADD") { showAdd.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.gold).cornerRadius(5)
                Button("EXPORT") { exportLog() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.cyan)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.surface).cornerRadius(5)
            }

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("$\(String(format: "%.0f", approvedTotal))")
                        .font(.system(size: 14, weight: .black)).foregroundColor(approvedTotal >= 0 ? Theme.green : Theme.red)
                    Text("APPROVED NET").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(pendingCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.gold)
                    Text("PENDING").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(rejectedCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.red)
                    Text("REJECTED").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 6) {
                Button("ALL") { filterStatus = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(filterStatus == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(filterStatus == nil ? Theme.accent : Theme.surface).cornerRadius(4)
                ForEach(ChangeOrderStatus.allCases, id: \.self) { s in
                    Button(s.rawValue) { filterStatus = filterStatus == s ? nil : s }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(filterStatus == s ? .black : s.color)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(filterStatus == s ? s.color : Theme.surface).cornerRadius(4)
                }
            }

            if showAdd {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("CO-006", text: $newNumber)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 10)).frame(width: 72)
                        TextField("Title", text: $newTitle)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 10))
                    }
                    HStack(spacing: 8) {
                        TextField("Cost impact", text: $newCost)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 10))
                        TextField("Sched days", text: $newDays)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 10)).frame(width: 80)
                        Picker("", selection: $selectedStatus) {
                            ForEach(ChangeOrderStatus.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .frame(width: 100)
                    }
                    TextField("Description", text: $newDesc)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 10))
                    HStack(spacing: 8) {
                        Button("SAVE", action: addItem)
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Theme.green).cornerRadius(5)
                        Button("CANCEL") { showAdd = false }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                    }
                }
                .padding(8)
                .background(Theme.surface.opacity(0.6))
                .cornerRadius(8)
            }

            ForEach(filtered) { item in
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(item.number)
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(Theme.muted)
                            Text(item.title)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.text)
                        }
                        Text(item.description)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(Theme.muted)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            Text(item.costImpact >= 0 ? "+$\(String(format: "%.0f", item.costImpact))" : "-$\(String(format: "%.0f", abs(item.costImpact)))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(item.costImpact >= 0 ? Theme.red : Theme.green)
                            Text("\(item.scheduleDays >= 0 ? "+" : "")\(item.scheduleDays)d sched")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(item.scheduleDays > 0 ? Theme.red : item.scheduleDays < 0 ? Theme.green : Theme.muted)
                            Text("Sub: \(item.submittedDate)")
                                .font(.system(size: 9)).foregroundColor(Theme.muted)
                        }
                    }
                    Spacer()
                    Text(item.status.rawValue)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(item.status.color)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(item.status.color.opacity(0.12))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(8)
            }

            if let exportStatus {
                Text(exportStatus).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.green)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.gold)
        .onAppear {
            items = loadJSON("ConstructOS.Ops.ChangeOrders", default: items)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Safety Incident Log

enum IncidentType: String, CaseIterable, Codable {
    case nearMiss   = "NEAR MISS"
    case firstAid   = "FIRST AID"
    case recordable = "RECORDABLE"
    case lostTime   = "LOST TIME"

    var color: Color {
        switch self {
        case .nearMiss:   return Theme.gold
        case .firstAid:   return Theme.cyan
        case .recordable: return Color.orange
        case .lostTime:   return Theme.red
        }
    }
}

enum IncidentStatus: String, CaseIterable, Codable {
    case open   = "OPEN"
    case closed = "CLOSED"
}

struct SafetyIncident: Identifiable, Codable {
    var id = UUID()
    var date: String
    var type: IncidentType
    var location: String
    var description: String
    var crewMember: String
    var correctiveAction: String
    var status: IncidentStatus
}

struct SafetyIncidentPanel: View {
    @State private var incidents: [SafetyIncident] = [
        SafetyIncident(date: "03-10", type: .nearMiss, location: "Level 3 Deck", description: "Unsecured load nearly fell from hoist; stopped by netting.", crewMember: "R. Torres", correctiveAction: "Retrain all hoist operators. Load checklist enforced.", status: .closed),
        SafetyIncident(date: "03-12", type: .firstAid, location: "Staging Area", description: "Laceration to right hand from unguarded saw blade.", crewMember: "M. Jenkins", correctiveAction: "Guard replaced. PPE glove added to required kit.", status: .closed),
        SafetyIncident(date: "03-14", type: .recordable, location: "Grid B-7", description: "Fall from 4-ft scaffold — wrist fracture. No harness worn.", crewMember: "D. Alvarez", correctiveAction: "Harness audit underway. All leading edge work halted pending Safety Officer review.", status: .open),
    ]
    @State private var filterType: IncidentType? = nil
    @State private var filterStatus: IncidentStatus? = nil
    @State private var showAdd = false
    @State private var newDate = ""
    @State private var newLocation = ""
    @State private var newDesc = ""
    @State private var newCrew = ""
    @State private var newAction = ""
    @State private var newType: IncidentType = .nearMiss
    @State private var newStatus: IncidentStatus = .open

    private var filtered: [SafetyIncident] {
        incidents.filter {
            (filterType == nil || $0.type == filterType!) &&
            (filterStatus == nil || $0.status == filterStatus!)
        }
    }

    private var recordableCount: Int { incidents.filter { $0.type == .recordable || $0.type == .lostTime }.count }
    private var openCount: Int       { incidents.filter { $0.status == .open }.count }

    private func addIncident() {
        guard !newDesc.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let formatter = DateFormatter(); formatter.dateFormat = "MM-dd"
        let today = formatter.string(from: Date())
        let inc = SafetyIncident(date: newDate.isEmpty ? today : newDate, type: newType,
                                  location: newLocation, description: newDesc,
                                  crewMember: newCrew, correctiveAction: newAction, status: newStatus)
        incidents.insert(inc, at: 0)
        saveJSON("ConstructOS.Ops.SafetyIncidents", value: incidents)
        newDate = ""; newLocation = ""; newDesc = ""; newCrew = ""; newAction = ""
        newType = .nearMiss; newStatus = .open; showAdd = false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SAFETY INCIDENT LOG")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundColor(Theme.red)
                    Text("\(incidents.count) total · \(recordableCount) recordable · \(openCount) open")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Button("+ LOG") { showAdd.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.red).cornerRadius(5)
            }

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("\(incidents.count)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.text)
                    Text("TOTAL").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(recordableCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.red)
                    Text("RECORDABLE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(openCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(openCount > 0 ? Theme.gold : Theme.green)
                    Text("OPEN ITEMS").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 6) {
                Button("ALL TYPES") { filterType = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(filterType == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(filterType == nil ? Theme.accent : Theme.surface).cornerRadius(4)
                ForEach(IncidentType.allCases, id: \.self) { t in
                    Button(t.rawValue) { filterType = filterType == t ? nil : t }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(filterType == t ? .black : t.color)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(filterType == t ? t.color : Theme.surface).cornerRadius(4)
                }
                Button(filterStatus == .open ? "OPEN" : filterStatus == .closed ? "CLOSED" : "ALL STATUS") {
                    if filterStatus == nil { filterStatus = .open }
                    else if filterStatus == .open { filterStatus = .closed }
                    else { filterStatus = nil }
                }
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(filterStatus == nil ? Theme.muted : .black)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(filterStatus == nil ? Theme.surface : filterStatus == .open ? Theme.gold : Theme.green)
                .cornerRadius(4)
            }

            if showAdd {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("MM-DD", text: $newDate)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10)).frame(width: 60)
                        TextField("Location", text: $newLocation)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10))
                        TextField("Crew member", text: $newCrew)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10))
                    }
                    TextField("Incident description", text: $newDesc)
                        .textFieldStyle(.roundedBorder).font(.system(size: 10))
                    TextField("Corrective action", text: $newAction)
                        .textFieldStyle(.roundedBorder).font(.system(size: 10))
                    HStack(spacing: 8) {
                        Picker("Type", selection: $newType) {
                            ForEach(IncidentType.allCases, id: \.self) { Text($0.rawValue) }
                        }.frame(width: 120)
                        Picker("Status", selection: $newStatus) {
                            ForEach(IncidentStatus.allCases, id: \.self) { Text($0.rawValue) }
                        }.frame(width: 100)
                        Spacer()
                        Button("SAVE", action: addIncident)
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Theme.red).cornerRadius(5)
                        Button("CANCEL") { showAdd = false }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                    }
                }
                .padding(8)
                .background(Theme.surface.opacity(0.6))
                .cornerRadius(8)
            }

            ForEach(filtered) { inc in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(inc.date)
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(Theme.muted)
                        Text(inc.type.rawValue)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(inc.type.color)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(inc.type.color.opacity(0.12)).cornerRadius(4)
                        Text(inc.location)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.text)
                        Spacer()
                        Text(inc.status.rawValue)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(inc.status == .open ? Theme.gold : Theme.green)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(inc.status == .open ? Theme.gold.opacity(0.1) : Theme.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                    Text(inc.description)
                        .font(.system(size: 9)).foregroundColor(Theme.muted).lineLimit(2)
                    if !inc.crewMember.isEmpty {
                        Text("Crew: \(inc.crewMember)")
                            .font(.system(size: 8, weight: .semibold)).foregroundColor(Theme.cyan)
                    }
                    if !inc.correctiveAction.isEmpty {
                        Text("Action: \(inc.correctiveAction)")
                            .font(.system(size: 8)).foregroundColor(Theme.muted).lineLimit(2)
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.red)
        .onAppear {
            incidents = loadJSON("ConstructOS.Ops.SafetyIncidents", default: incidents)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Material Delivery Tracker

enum DeliveryStatus: String, CaseIterable, Codable {
    case ordered   = "ORDERED"
    case inTransit = "IN TRANSIT"
    case delivered = "DELIVERED"
    case delayed   = "DELAYED"

    var color: Color {
        switch self {
        case .ordered:   return Theme.cyan
        case .inTransit: return Theme.gold
        case .delivered: return Theme.green
        case .delayed:   return Theme.red
        }
    }
}

struct MaterialDelivery: Identifiable, Codable {
    var id = UUID()
    var material: String
    var quantity: String
    var supplier: String
    var po: String
    var expectedDate: String
    var actualDate: String
    var status: DeliveryStatus
    var notes: String
}

struct MaterialDeliveryPanel: View {
    @State private var deliveries: [MaterialDelivery] = [
        MaterialDelivery(material: "Structural Steel — W8x31 Beams", quantity: "48 pcs", supplier: "Nucor Steel", po: "PO-4411", expectedDate: "03-15", actualDate: "03-15", status: .delivered, notes: "All pieces tagged and staged at grid A-line."),
        MaterialDelivery(material: "Concrete — 4000 PSI Mix", quantity: "80 CY", supplier: "LaFarge Ready Mix", po: "PO-4418", expectedDate: "03-18", actualDate: "", status: .ordered, notes: "Pour scheduled 07:00. Pump truck confirmed."),
        MaterialDelivery(material: "Electrical Conduit — 3/4\" EMT", quantity: "600 ft", supplier: "Graybar Electric", po: "PO-4422", expectedDate: "03-13", actualDate: "", status: .delayed, notes: "Distributor backordered. ETA revised to 03-20."),
        MaterialDelivery(material: "Drywall — 5/8\" Type X", quantity: "2,400 sqft", supplier: "USG Corp", po: "PO-4430", expectedDate: "03-20", actualDate: "", status: .inTransit, notes: "Driver confirmed en route. ETA 4 hours."),
        MaterialDelivery(material: "Roofing Membrane — TPO 60mil", quantity: "12 squares", supplier: "Johns Manville", po: "PO-4435", expectedDate: "03-22", actualDate: "", status: .ordered, notes: ""),
    ]
    @State private var filterStatus: DeliveryStatus? = nil
    @State private var showAdd = false
    @State private var newMaterial = ""
    @State private var newQty = ""
    @State private var newSupplier = ""
    @State private var newPO = ""
    @State private var newExpected = ""
    @State private var newNotes = ""
    @State private var newDelivStatus: DeliveryStatus = .ordered
    @State private var exportStatus: String? = nil

    private var filtered: [MaterialDelivery] {
        guard let f = filterStatus else { return deliveries }
        return deliveries.filter { $0.status == f }
    }

    private var delayedCount: Int  { deliveries.filter { $0.status == .delayed   }.count }
    private var pendingCount: Int  { deliveries.filter { $0.status != .delivered }.count }
    private var deliveredCount: Int { deliveries.filter { $0.status == .delivered }.count }

    private func addDelivery() {
        guard !newMaterial.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let d = MaterialDelivery(material: newMaterial, quantity: newQty, supplier: newSupplier,
                                  po: newPO.isEmpty ? "PO-\(Int.random(in: 4000...9999))" : newPO,
                                  expectedDate: newExpected, actualDate: "",
                                  status: newDelivStatus, notes: newNotes)
        deliveries.insert(d, at: 0)
        saveJSON("ConstructOS.Ops.MaterialDeliveries", value: deliveries)
        newMaterial = ""; newQty = ""; newSupplier = ""; newPO = ""; newExpected = ""; newNotes = ""
        newDelivStatus = .ordered; showAdd = false
    }

    private func exportLog() {
        let lines = deliveries.map { "\($0.po) | \($0.material) | \($0.quantity) | \($0.supplier) | Expected: \($0.expectedDate) | \($0.status.rawValue)" }
        let payload = (["MATERIAL DELIVERY LOG", "Delivered: \(deliveredCount) | Pending: \(pendingCount) | Delayed: \(delayedCount)", ""] + lines).joined(separator: "\n")
        copyTextToClipboard(payload)
        exportStatus = "Copied \(deliveries.count) deliveries"
        Task { try? await Task.sleep(nanoseconds: 3_000_000_000); await MainActor.run { exportStatus = nil } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MATERIAL DELIVERY TRACKER")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundColor(Theme.cyan)
                    Text("\(deliveries.count) items · \(delayedCount) delayed · \(deliveredCount) delivered")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Button("+ ADD") { showAdd.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.cyan).cornerRadius(5)
                Button("EXPORT") { exportLog() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.gold)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.surface).cornerRadius(5)
            }

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("\(deliveredCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.green)
                    Text("DELIVERED").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(pendingCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.gold)
                    Text("PENDING").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(delayedCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(delayedCount > 0 ? Theme.red : Theme.muted)
                    Text("DELAYED").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 6) {
                Button("ALL") { filterStatus = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(filterStatus == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(filterStatus == nil ? Theme.accent : Theme.surface).cornerRadius(4)
                ForEach(DeliveryStatus.allCases, id: \.self) { s in
                    Button(s.rawValue) { filterStatus = filterStatus == s ? nil : s }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(filterStatus == s ? .black : s.color)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(filterStatus == s ? s.color : Theme.surface).cornerRadius(4)
                }
            }

            if showAdd {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("Material name", text: $newMaterial)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10))
                        TextField("Qty", text: $newQty)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10)).frame(width: 80)
                    }
                    HStack(spacing: 8) {
                        TextField("Supplier", text: $newSupplier)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10))
                        TextField("PO #", text: $newPO)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10)).frame(width: 80)
                        TextField("Expected MM-DD", text: $newExpected)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10)).frame(width: 110)
                    }
                    HStack(spacing: 8) {
                        TextField("Notes", text: $newNotes)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10))
                        Picker("", selection: $newDelivStatus) {
                            ForEach(DeliveryStatus.allCases, id: \.self) { Text($0.rawValue) }
                        }.frame(width: 110)
                    }
                    HStack(spacing: 8) {
                        Button("SAVE", action: addDelivery)
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Theme.cyan).cornerRadius(5)
                        Button("CANCEL") { showAdd = false }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                    }
                }
                .padding(8)
                .background(Theme.surface.opacity(0.6))
                .cornerRadius(8)
            }

            ForEach(filtered) { d in
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(d.po)
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundColor(Theme.muted)
                            Text(d.material)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.text)
                        }
                        HStack(spacing: 8) {
                            Text(d.quantity).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.cyan)
                            Text("·").foregroundColor(Theme.muted)
                            Text(d.supplier).font(.system(size: 9)).foregroundColor(Theme.muted)
                            if !d.expectedDate.isEmpty {
                                Text("· ETA \(d.expectedDate)").font(.system(size: 9)).foregroundColor(d.status == .delayed ? Theme.red : Theme.muted)
                            }
                        }
                        if !d.notes.isEmpty {
                            Text(d.notes).font(.system(size: 9)).foregroundColor(Theme.muted).lineLimit(2)
                        }
                    }
                    Spacer()
                    Text(d.status.rawValue)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(d.status.color)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(d.status.color.opacity(0.12)).cornerRadius(4)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(8)
            }

            if let exportStatus {
                Text(exportStatus).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.green)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan)
        .onAppear {
            deliveries = loadJSON("ConstructOS.Ops.MaterialDeliveries", default: deliveries)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Punch List Manager

enum PunchListStatus: String, CaseIterable, Codable {
    case open   = "OPEN"
    case closed = "CLOSED"
    var color: Color { self == .open ? Theme.gold : Theme.green }
}

struct PunchListItem: Identifiable, Codable {
    var id = UUID()
    var description: String
    var location: String
    var trade: String
    var dueDate: String
    var status: PunchListStatus
    var createdBy: String
}

struct PunchListPanel: View {
    @State private var items: [PunchListItem] = [
        PunchListItem(description: "Missing fire caulk at conduit penetrations", location: "Level 2 – Elec Room", trade: "Electrical", dueDate: "03-17", status: .open, createdBy: "Insp. Torres"),
        PunchListItem(description: "Exposed rebar at footing tie-in", location: "Grid C-4", trade: "Concrete", dueDate: "03-16", status: .open, createdBy: "PM Davis"),
        PunchListItem(description: "HVAC duct hanger spacing exceeds 8ft", location: "Corridor B1", trade: "Mechanical", dueDate: "03-18", status: .open, createdBy: "Insp. Torres"),
        PunchListItem(description: "Door hardware backset incorrect – Rm 204", location: "Level 2", trade: "Doors & Hardware", dueDate: "03-15", status: .closed, createdBy: "Super. Reyes"),
        PunchListItem(description: "Paint overspray on sprinkler heads", location: "Level 1 Lobby", trade: "Painting", dueDate: "03-19", status: .open, createdBy: "PM Davis"),
    ]
    @State private var filterStatus: PunchListStatus? = nil
    @State private var showAddForm = false
    @State private var newDesc = ""
    @State private var newLoc = ""
    @State private var newTrade = ""
    @State private var newDue = ""

    private var filtered: [PunchListItem] {
        items.filter { filterStatus == nil || $0.status == filterStatus }
    }
    private var openCount: Int { items.filter { $0.status == .open }.count }
    private var closedCount: Int { items.filter { $0.status == .closed }.count }

    private func addItem() {
        guard !newDesc.isEmpty, !newTrade.isEmpty else { return }
        items.append(PunchListItem(description: newDesc, location: newLoc, trade: newTrade, dueDate: newDue, status: .open, createdBy: "You"))
                        saveJSON("ConstructOS.Ops.PunchList", value: items)
        newDesc = ""; newLoc = ""; newTrade = ""; newDue = ""
        showAddForm = false
    }

    private func closeItem(_ item: PunchListItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].status = .closed
        }
    }

    private func exportPunchList() {
        let lines = items.map { "[\($0.status.rawValue)] \($0.description) | Loc: \($0.location) | Trade: \($0.trade) | Due: \($0.dueDate) | By: \($0.createdBy)" }
        copyTextToClipboard("PUNCH LIST EXPORT – \(items.count) items (Open: \(openCount))\n" + lines.joined(separator: "\n"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PUNCH LIST MANAGER")
                        .font(.system(size: 11, weight: .black)).tracking(2)
                        .foregroundColor(Theme.accent)
                    Text("Open \(openCount) · Closed \(closedCount)")
                        .font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.muted)
                }
                Spacer()
                Button("EXPORT") { exportPunchList() }
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
                ForEach(PunchListStatus.allCases, id: \.rawValue) { s in
                    Button(s.rawValue) { filterStatus = (filterStatus == s) ? nil : s }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(filterStatus == s ? .black : Theme.muted)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(filterStatus == s ? s.color : Theme.surface)
                        .cornerRadius(4)
                }
            }

            if showAddForm {
                VStack(spacing: 6) {
                    TextField("Description", text: $newDesc)
                        .textFieldStyle(.plain).font(.system(size: 10))
                        .padding(6).background(Theme.surface).cornerRadius(6)
                    HStack(spacing: 6) {
                        TextField("Location", text: $newLoc)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Trade", text: $newTrade)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Due (MM-DD)", text: $newDue)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 90)
                        Button("ADD") { addItem() }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Theme.green).cornerRadius(6)
                    }
                }
            }

            ForEach(filtered) { item in
                HStack(alignment: .top, spacing: 10) {
                    Text(item.status.rawValue)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(item.status.color)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(item.status.color.opacity(0.13))
                        .cornerRadius(4)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.description)
                            .font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text)
                        Text("\(item.location) · \(item.trade) · Due \(item.dueDate) · \(item.createdBy)")
                            .font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    if item.status == .open {
                        Button("CLOSE") { closeItem(item) }
                            .font(.system(size: 8, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Theme.green).cornerRadius(4)
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7)).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            items = loadJSON("ConstructOS.Ops.PunchList", default: items)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Subcontractor Scorecard

enum SubPaymentStatus: String, CaseIterable, Codable {
    case current  = "CURRENT"
    case pending  = "PENDING"
    case overdue  = "OVERDUE"
    var color: Color { self == .current ? Theme.green : self == .pending ? Theme.gold : Theme.red }
}

struct SubcontractorRecord: Identifiable, Codable {
    var id = UUID()
    var name: String
    var trade: String
    var scheduleScore: Int
    var qualityScore: Int
    var safetyScore: Int
    var paymentStatus: SubPaymentStatus
    var overallGrade: String {
        let avg = (scheduleScore + qualityScore + safetyScore) / 3
        switch avg {
        case 90...: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        default: return "D"
        }
    }
    var gradeColor: Color {
        switch overallGrade {
        case "A": return Theme.green
        case "B": return Theme.cyan
        case "C": return Theme.gold
        default: return Theme.red
        }
    }
}

struct SubcontractorScorecardPanel: View {
    @State private var subs: [SubcontractorRecord] = [
        SubcontractorRecord(name: "Apex Electrical", trade: "Electrical", scheduleScore: 88, qualityScore: 91, safetyScore: 95, paymentStatus: .current),
        SubcontractorRecord(name: "Ironclad Steel", trade: "Structural Steel", scheduleScore: 72, qualityScore: 84, safetyScore: 80, paymentStatus: .pending),
        SubcontractorRecord(name: "ProMech HVAC", trade: "Mechanical", scheduleScore: 65, qualityScore: 77, safetyScore: 88, paymentStatus: .current),
        SubcontractorRecord(name: "Precision Concrete", trade: "Concrete", scheduleScore: 93, qualityScore: 90, safetyScore: 92, paymentStatus: .current),
        SubcontractorRecord(name: "SkyHigh Crane Co.", trade: "Crane & Rigging", scheduleScore: 80, qualityScore: 85, safetyScore: 70, paymentStatus: .overdue),
    ]
    @State private var sortByGrade = true

    private var sorted: [SubcontractorRecord] {
        sortByGrade
            ? subs.sorted { $0.overallGrade < $1.overallGrade }
            : subs.sorted { $0.name < $1.name }
    }

    private func scoreBar(_ score: Int, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface)
                Capsule().fill(color).frame(width: geo.size.width * CGFloat(score) / 100)
            }
        }
        .frame(height: 5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SUBCONTRACTOR SCORECARD")
                        .font(.system(size: 11, weight: .black)).tracking(2)
                        .foregroundColor(Theme.accent)
                    Text("\(subs.count) subs tracked · \(subs.filter { $0.paymentStatus == .overdue }.count) payment overdue")
                        .font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.muted)
                }
                Spacer()
                Button(sortByGrade ? "SORT: GRADE" : "SORT: NAME") { sortByGrade.toggle() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.cyan).cornerRadius(5)
            }

            HStack(spacing: 6) {
                Text("SUB / TRADE").frame(width: 160, alignment: .leading)
                Text("SCHED").frame(width: 60, alignment: .center)
                Text("QUAL").frame(width: 60, alignment: .center)
                Text("SAFETY").frame(width: 60, alignment: .center)
                Text("PAY").frame(width: 70, alignment: .center)
                Text("GRD").frame(width: 30, alignment: .center)
            }
            .font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)

            ForEach(sorted) { sub in
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(sub.name).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text)
                        Text(sub.trade).font(.system(size: 8)).foregroundColor(Theme.muted)
                    }.frame(width: 160, alignment: .leading)

                    VStack(spacing: 2) {
                        Text("\(sub.scheduleScore)").font(.system(size: 9, weight: .semibold)).foregroundColor(sub.scheduleScore >= 80 ? Theme.green : Theme.gold)
                        scoreBar(sub.scheduleScore, color: sub.scheduleScore >= 80 ? Theme.green : Theme.gold)
                    }.frame(width: 60)

                    VStack(spacing: 2) {
                        Text("\(sub.qualityScore)").font(.system(size: 9, weight: .semibold)).foregroundColor(sub.qualityScore >= 80 ? Theme.green : Theme.gold)
                        scoreBar(sub.qualityScore, color: sub.qualityScore >= 80 ? Theme.green : Theme.gold)
                    }.frame(width: 60)

                    VStack(spacing: 2) {
                        Text("\(sub.safetyScore)").font(.system(size: 9, weight: .semibold)).foregroundColor(sub.safetyScore >= 80 ? Theme.green : Theme.red)
                        scoreBar(sub.safetyScore, color: sub.safetyScore >= 80 ? Theme.green : Theme.red)
                    }.frame(width: 60)

                    Text(sub.paymentStatus.rawValue)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(sub.paymentStatus.color)
                        .frame(width: 70)

                    Text(sub.overallGrade)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(sub.gradeColor)
                        .frame(width: 30)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7)).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            subs = loadJSON("ConstructOS.Ops.Subcontractors", default: subs)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Daily Cost Tracker

struct DailyCostEntry: Identifiable, Codable {
    var id = UUID()
    var trade: String
    var laborHours: Double
    var laborRate: Double
    var equipmentCost: Double
    var materialCost: Double
    var dateLabel: String
    var totalCost: Double { (laborHours * laborRate) + equipmentCost + materialCost }
}

struct DailyCostTrackerPanel: View {
    @State private var entries: [DailyCostEntry] = [
        DailyCostEntry(trade: "Electrical", laborHours: 48, laborRate: 85, equipmentCost: 0, materialCost: 1240, dateLabel: "Today"),
        DailyCostEntry(trade: "Concrete", laborHours: 64, laborRate: 72, equipmentCost: 2200, materialCost: 4800, dateLabel: "Today"),
        DailyCostEntry(trade: "Mechanical", laborHours: 32, laborRate: 90, equipmentCost: 0, materialCost: 620, dateLabel: "Today"),
        DailyCostEntry(trade: "Crane & Rigging", laborHours: 16, laborRate: 110, equipmentCost: 3200, materialCost: 0, dateLabel: "Today"),
        DailyCostEntry(trade: "Supervision", laborHours: 24, laborRate: 95, equipmentCost: 0, materialCost: 0, dateLabel: "Today"),
    ]
    @State private var dailyBudgetBaseline: Double = 48000
    @State private var showAddForm = false
    @State private var newTrade = ""
    @State private var newHours = ""
    @State private var newRate  = ""
    @State private var newEquip = ""
    @State private var newMat   = ""

    private var totalToday: Double { entries.map { $0.totalCost }.reduce(0, +) }
    private var laborTotal: Double { entries.map { $0.laborHours * $0.laborRate }.reduce(0, +) }
    private var equipTotal: Double { entries.map { $0.equipmentCost }.reduce(0, +) }
    private var matTotal: Double   { entries.map { $0.materialCost }.reduce(0, +) }
    private var variance: Double   { totalToday - dailyBudgetBaseline }
    private var varianceColor: Color { variance <= 0 ? Theme.green : Theme.red }

    private func addEntry() {
        guard !newTrade.isEmpty, let h = Double(newHours), let r = Double(newRate) else { return }
        let e = Double(newEquip) ?? 0; let m = Double(newMat) ?? 0
        entries.append(DailyCostEntry(trade: newTrade, laborHours: h, laborRate: r, equipmentCost: e, materialCost: m, dateLabel: "Today"))
        newTrade = ""; newHours = ""; newRate = ""; newEquip = ""; newMat = ""
        showAddForm = false
    }

    private func fmt(_ v: Double) -> String { String(format: "$%,.0f", v) }

    private func exportReport() {
        let lines = entries.map { "  \($0.trade): Labor \(fmt($0.laborHours * $0.laborRate)) + Equip \(fmt($0.equipmentCost)) + Mat \(fmt($0.materialCost)) = \(fmt($0.totalCost))" }
        let payload = "DAILY COST REPORT – \(Date())\nTotal: \(fmt(totalToday)) | Budget: \(fmt(dailyBudgetBaseline)) | Variance: \(variance >= 0 ? "+" : "")\(fmt(variance))\n\n" + lines.joined(separator: "\n")
        copyTextToClipboard(payload)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAILY COST TRACKER")
                        .font(.system(size: 11, weight: .black)).tracking(2)
                        .foregroundColor(Theme.accent)
                    Text("Today's burn vs. \(fmt(dailyBudgetBaseline)) baseline")
                        .font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.muted)
                }
                Spacer()
                Button("EXPORT") { exportReport() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.accent).cornerRadius(5)
                Button(showAddForm ? "CANCEL" : "+ ENTRY") { showAddForm.toggle() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.cyan).cornerRadius(5)
            }

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(fmt(totalToday))
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(totalToday <= dailyBudgetBaseline ? Theme.green : Theme.red)
                    Text("TODAY TOTAL").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text(fmt(laborTotal)).font(.system(size: 11, weight: .black)).foregroundColor(Theme.cyan)
                    Text("LABOR").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                VStack(spacing: 2) {
                    Text(fmt(equipTotal)).font(.system(size: 11, weight: .black)).foregroundColor(Theme.gold)
                    Text("EQUIPMENT").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                VStack(spacing: 2) {
                    Text(fmt(matTotal)).font(.system(size: 11, weight: .black)).foregroundColor(Theme.purple)
                    Text("MATERIALS").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(variance >= 0 ? "+" : "")\(fmt(variance))")
                        .font(.system(size: 11, weight: .black)).foregroundColor(varianceColor)
                    Text("VARIANCE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
            }

            if showAddForm {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Trade", text: $newTrade)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Hours", text: $newHours)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 70)
                        TextField("Rate/hr", text: $newRate)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 70)
                        TextField("Equipment $", text: $newEquip)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 90)
                        TextField("Materials $", text: $newMat)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 90)
                        Button("ADD") { addEntry() }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Theme.green).cornerRadius(6)
                    }
                }
            }

            HStack(spacing: 6) {
                Text("TRADE").frame(width: 130, alignment: .leading)
                Text("HOURS").frame(width: 55, alignment: .trailing)
                Text("LABOR").frame(width: 80, alignment: .trailing)
                Text("EQUIP").frame(width: 80, alignment: .trailing)
                Text("MAT").frame(width: 80, alignment: .trailing)
                Text("TOTAL").frame(width: 80, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)

            ForEach(entries) { entry in
                HStack(spacing: 6) {
                    Text(entry.trade).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text)
                        .frame(width: 130, alignment: .leading)
                    Text(String(format: "%.1f", entry.laborHours)).font(.system(size: 9)).foregroundColor(Theme.muted)
                        .frame(width: 55, alignment: .trailing)
                    Text(fmt(entry.laborHours * entry.laborRate)).font(.system(size: 9)).foregroundColor(Theme.cyan)
                        .frame(width: 80, alignment: .trailing)
                    Text(fmt(entry.equipmentCost)).font(.system(size: 9)).foregroundColor(Theme.gold)
                        .frame(width: 80, alignment: .trailing)
                    Text(fmt(entry.materialCost)).font(.system(size: 9)).foregroundColor(Theme.purple)
                        .frame(width: 80, alignment: .trailing)
                    Text(fmt(entry.totalCost)).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(Theme.surface.opacity(0.7)).cornerRadius(7)
            }
        }
        .padding(14).background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            entries = loadJSON("ConstructOS.Ops.DailyCosts", default: entries)
        }
        .padding(.horizontal, 16)
    }
}
