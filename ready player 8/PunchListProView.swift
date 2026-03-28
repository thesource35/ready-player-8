import Combine
import SwiftUI
import PhotosUI

// MARK: - ========== Mobile Punch List Pro ==========

struct PunchItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var location: String
    var trade: String
    var priority: String  // "critical", "high", "medium", "low"
    var status: String    // "open", "in_progress", "resolved", "verified"
    var assignedTo: String
    var dueDate: String
    var notes: String
    var photoCount: Int
    var createdAt: Date
    var resolvedAt: Date?
}

@MainActor
final class PunchListStore: ObservableObject {
    static let shared = PunchListStore()
    @Published var items: [PunchItem] = []
    private let key = "ConstructOS.PunchPro.Items"

    init() { items = loadJSON(key, default: samplePunchItems) }

    func add(_ item: PunchItem) { items.insert(item, at: 0); save() }
    func update(_ item: PunchItem) { if let i = items.firstIndex(where: { $0.id == item.id }) { items[i] = item; save() } }
    func delete(_ item: PunchItem) { items.removeAll { $0.id == item.id }; save() }
    func save() { saveJSON(key, value: items) }

    var openCount: Int { items.filter { $0.status == "open" || $0.status == "in_progress" }.count }
    var resolvedCount: Int { items.filter { $0.status == "resolved" || $0.status == "verified" }.count }
    var criticalCount: Int { items.filter { $0.priority == "critical" && $0.status != "verified" }.count }
}

private let samplePunchItems: [PunchItem] = [
    PunchItem(title: "Fire-stopping gaps at grid B-7", location: "Level 3, Grid B-7", trade: "Fire Protection", priority: "critical", status: "open", assignedTo: "Apex Fire", dueDate: "Mar 28", notes: "Multiple penetrations unsealed", photoCount: 3, createdAt: Date()),
    PunchItem(title: "Drywall finish touch-up corridor", location: "Level 3 Corridor", trade: "Drywall", priority: "medium", status: "in_progress", assignedTo: "Delta Drywall", dueDate: "Mar 30", notes: "Visible joints at 3 locations", photoCount: 2, createdAt: Date()),
    PunchItem(title: "MEP label missing panel 2A", location: "Electrical Room B", trade: "Electrical", priority: "high", status: "open", assignedTo: "Prime Electric", dueDate: "Mar 29", notes: "Circuit directory and panel labels needed", photoCount: 1, createdAt: Date()),
    PunchItem(title: "Paint overspray on window frames", location: "Level 2, Units 201-204", trade: "Painting", priority: "low", status: "open", assignedTo: "ColorPro Paint", dueDate: "Apr 2", notes: "Clean glass and frames", photoCount: 4, createdAt: Date()),
    PunchItem(title: "HVAC diffuser alignment off", location: "Level 4, Open Office", trade: "HVAC", priority: "medium", status: "resolved", assignedTo: "Apex MEP", dueDate: "Mar 25", notes: "3 diffusers realigned", photoCount: 2, createdAt: Date().addingTimeInterval(-86400), resolvedAt: Date()),
    PunchItem(title: "Floor tile chip at entrance", location: "Main Lobby", trade: "Tile", priority: "high", status: "open", assignedTo: "ProTile Inc", dueDate: "Mar 27", notes: "Replace 2 tiles at main entry", photoCount: 1, createdAt: Date()),
]

struct PunchListProView: View {
    @ObservedObject var store = PunchListStore.shared
    @State private var filter: String = "all"
    @State private var searchText = ""
    @State private var showAdd = false
    @State private var sortBy = 0 // 0=priority, 1=date, 2=trade

    private var filtered: [PunchItem] {
        var list = store.items
        if filter != "all" { list = list.filter { $0.status == filter } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter { $0.title.lowercased().contains(q) || $0.location.lowercased().contains(q) || $0.trade.lowercased().contains(q) || $0.assignedTo.lowercased().contains(q) }
        }
        switch sortBy {
        case 1: list.sort { $0.dueDate < $1.dueDate }
        case 2: list.sort { $0.trade < $1.trade }
        default:
            let order = ["critical": 0, "high": 1, "medium": 2, "low": 3]
            list.sort { (order[$0.priority] ?? 4) < (order[$1.priority] ?? 4) }
        }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) { Text("\u{2705}").font(.system(size: 18)); Text("PUNCH LIST PRO").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.accent) }
                        Text("Mobile Construction Punch List").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                    }
                    Spacer()
                    Button { showAdd = true } label: {
                        Label("ADD ITEM", systemImage: "plus.circle.fill").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 12).padding(.vertical, 8).background(Theme.accent).cornerRadius(8)
                    }.buttonStyle(.plain)
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.accent)

                // Stats
                HStack(spacing: 8) {
                    VStack(spacing: 2) { Text("\(store.openCount)").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.red); Text("OPEN").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.red.opacity(0.06)).cornerRadius(8)
                    VStack(spacing: 2) { Text("\(store.criticalCount)").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.gold); Text("CRITICAL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
                    VStack(spacing: 2) { Text("\(store.resolvedCount)").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.green); Text("RESOLVED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                    VStack(spacing: 2) { Text("\(store.items.count)").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.cyan); Text("TOTAL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                }

                // Search + filter
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(Theme.muted)
                    TextField("Search items, locations, trades...", text: $searchText).font(.system(size: 12)).foregroundColor(Theme.text)
                }.padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(["all", "open", "in_progress", "resolved", "verified"], id: \.self) { f in
                            Button { filter = f } label: {
                                Text(f == "in_progress" ? "IN PROGRESS" : f.uppercased()).font(.system(size: 9, weight: .bold))
                                    .foregroundColor(filter == f ? .black : Theme.text)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(filter == f ? Theme.accent : Theme.surface).cornerRadius(6)
                            }.buttonStyle(.plain)
                        }
                    }
                }

                // Items
                ForEach(filtered) { item in
                    PunchItemCard(item: item) { updated in store.update(updated) }
                }
            }.padding(16)
        }.background(Theme.bg)
        .sheet(isPresented: $showAdd) {
            AddPunchItemSheet { item in store.add(item); showAdd = false }
        }
    }
}

struct PunchItemCard: View {
    let item: PunchItem
    let onUpdate: (PunchItem) -> Void
    @State private var expanded = false

    private var priorityColor: Color {
        switch item.priority { case "critical": return Theme.red; case "high": return Theme.gold; case "medium": return Theme.cyan; default: return Theme.muted }
    }
    private var statusColor: Color {
        switch item.status { case "open": return Theme.red; case "in_progress": return Theme.gold; case "resolved": return Theme.green; default: return Theme.cyan }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle().fill(priorityColor).frame(width: 8, height: 8)
                Text(item.title).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text).lineLimit(expanded ? nil : 1)
                Spacer()
                Text(item.priority.uppercased()).font(.system(size: 7, weight: .black)).foregroundColor(priorityColor)
            }
            HStack(spacing: 8) {
                Label(item.location, systemImage: "mappin").font(.system(size: 8)).foregroundColor(Theme.muted)
                Label(item.trade, systemImage: "wrench").font(.system(size: 8)).foregroundColor(Theme.cyan)
                Spacer()
                Text(item.status.replacingOccurrences(of: "_", with: " ").uppercased()).font(.system(size: 7, weight: .black))
                    .foregroundColor(.black).padding(.horizontal, 6).padding(.vertical, 2).background(statusColor).cornerRadius(3)
            }
            if expanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assigned: \(item.assignedTo)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    Text("Due: \(item.dueDate)").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.gold)
                    if !item.notes.isEmpty { Text(item.notes).font(.system(size: 9)).foregroundColor(Theme.muted) }
                    if item.photoCount > 0 { Label("\(item.photoCount) photos", systemImage: "camera").font(.system(size: 9)).foregroundColor(Theme.cyan) }
                    HStack(spacing: 6) {
                        if item.status == "open" {
                            Button { var u = item; u.status = "in_progress"; onUpdate(u) } label: { Text("START").font(.system(size: 8, weight: .bold)).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 4).background(Theme.gold).cornerRadius(4) }.buttonStyle(.plain)
                        }
                        if item.status == "in_progress" {
                            Button { var u = item; u.status = "resolved"; u.resolvedAt = Date(); onUpdate(u) } label: { Text("RESOLVE").font(.system(size: 8, weight: .bold)).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 4).background(Theme.green).cornerRadius(4) }.buttonStyle(.plain)
                        }
                        if item.status == "resolved" {
                            Button { var u = item; u.status = "verified"; onUpdate(u) } label: { Text("VERIFY").font(.system(size: 8, weight: .bold)).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 4).background(Theme.cyan).cornerRadius(4) }.buttonStyle(.plain)
                        }
                    }
                }
            }
            HStack { Spacer(); Button { withAnimation { expanded.toggle() } } label: { Text(expanded ? "LESS" : "MORE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.accent) }.buttonStyle(.plain) }
        }
        .padding(12).background(item.priority == "critical" && item.status == "open" ? Theme.red.opacity(0.04) : Theme.surface).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(priorityColor.opacity(0.3), lineWidth: 0.8))
    }
}

struct AddPunchItemSheet: View {
    let onSubmit: (PunchItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""; @State private var location = ""; @State private var trade = ""
    @State private var priority = "medium"; @State private var assignedTo = ""; @State private var dueDate = ""; @State private var notes = ""

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NEW PUNCH ITEM").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.text)
                        TextField("Title", text: $title).font(.system(size: 13)).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                        HStack(spacing: 8) {
                            TextField("Location", text: $location).font(.system(size: 13)).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                            TextField("Trade", text: $trade).font(.system(size: 13)).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                        }
                        HStack(spacing: 8) {
                            TextField("Assigned to", text: $assignedTo).font(.system(size: 13)).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                            TextField("Due date", text: $dueDate).font(.system(size: 13)).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                        }
                        HStack(spacing: 6) {
                            ForEach(["critical", "high", "medium", "low"], id: \.self) { p in
                                Button { priority = p } label: {
                                    Text(p.uppercased()).font(.system(size: 9, weight: .bold))
                                        .foregroundColor(priority == p ? .black : Theme.text)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(priority == p ? (p == "critical" ? Theme.red : p == "high" ? Theme.gold : p == "medium" ? Theme.cyan : Theme.muted) : Theme.surface).cornerRadius(6)
                                }.buttonStyle(.plain)
                            }
                        }
                        TextField("Notes", text: $notes).font(.system(size: 13)).padding(10).background(Theme.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)).cornerRadius(8)
                        Button {
                            guard !title.isEmpty else { return }
                            onSubmit(PunchItem(title: title, location: location, trade: trade, priority: priority, status: "open", assignedTo: assignedTo, dueDate: dueDate, notes: notes, photoCount: 0, createdAt: Date()))
                        } label: {
                            Text("CREATE PUNCH ITEM").font(.system(size: 13, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 14).background(Theme.accent).cornerRadius(10)
                        }.buttonStyle(.plain)
                    }.padding(20)
                }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) } }
        }.preferredColorScheme(.dark)
    }
}
