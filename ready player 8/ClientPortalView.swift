import SwiftUI

// MARK: - ========== Client Portal Tab ==========

struct ClientPortalView: View {
    @State private var activeTab = 0
    private let tabs = ["Dashboard", "Selections", "Warranty", "Meetings"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CLIENT PORTAL").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.purple)
                        Text("Owner & Stakeholder Hub").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                    }
                    Spacer()
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.purple)

                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button { withAnimation { activeTab = i } } label: { Text(tabs[i].uppercased()).font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(activeTab == i ? .black : Theme.muted).frame(maxWidth: .infinity).padding(.vertical, 9).background(activeTab == i ? Theme.purple : Theme.surface) }.buttonStyle(.plain)
                    }
                }.cornerRadius(8)

                if activeTab == 0 { ownerDashboard }
                else if activeTab == 1 { selectionsBoard }
                else if activeTab == 2 { warrantyTracker }
                else { meetingMinutes }
            }.padding(16)
        }.background(Theme.bg)
    }

    private var ownerDashboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROJECT STATUS FOR OWNERS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
            ForEach(mockProjects) { p in
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text(p.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text(p.status).font(.system(size: 8, weight: .black)).foregroundColor(p.status == "On Track" ? Theme.green : Theme.gold) }
                    GeometryReader { geo in ZStack(alignment: .leading) { RoundedRectangle(cornerRadius: 3).fill(Theme.border.opacity(0.3)).frame(height: 6); RoundedRectangle(cornerRadius: 3).fill(Theme.accent).frame(width: geo.size.width * CGFloat(p.progress) / 100, height: 6) } }.frame(height: 6)
                    HStack { Text("\(p.progress)% complete").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.accent); Spacer(); Text("Budget: \(p.budget)").font(.system(size: 9)).foregroundColor(Theme.muted) }
                }.padding(12).background(Theme.surface).cornerRadius(10)
            }
        }
    }

    private var selectionsBoard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MATERIAL & FINISH SELECTIONS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            let selections: [(String, String, String, String)] = [("Kitchen Countertops","Quartz vs Granite vs Marble","PENDING","Apr 5"),("Flooring - Common Areas","LVP vs Tile vs Polished Concrete","APPROVED","N/A"),("Exterior Paint","SW 7015 vs BM HC-172","PENDING","Apr 10"),("Light Fixtures - Lobby","Modern LED vs Industrial Pendant","APPROVED","N/A"),("Cabinet Hardware","Brushed Nickel vs Matte Black","PENDING","Apr 8")]
            ForEach(selections, id: \.0) { sel in
                HStack(spacing: 8) {
                    Image(systemName: sel.2 == "APPROVED" ? "checkmark.circle.fill" : "questionmark.circle").font(.system(size: 14)).foregroundColor(sel.2 == "APPROVED" ? Theme.green : Theme.gold)
                    VStack(alignment: .leading, spacing: 2) { Text(sel.0).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Text(sel.1).font(.system(size: 9)).foregroundColor(Theme.muted) }
                    Spacer()
                    if sel.3 != "N/A" { Text("Due: \(sel.3)").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold) }
                    Text(sel.2).font(.system(size: 7, weight: .black)).foregroundColor(sel.2 == "APPROVED" ? Theme.green : Theme.gold)
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    private var warrantyTracker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WARRANTY TRACKER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            let warranties: [(String, String, String, Int)] = [("Roof Membrane (TPO)","Johns Manville","Jun 2026 - Jun 2046",20),("HVAC System","Carrier","May 2026 - May 2036",10),("Windows & Glazing","Pella","Apr 2026 - Apr 2036",10),("Elevator System","Otis","Jul 2026 - Jul 2031",5),("Waterproofing","Tremco","Mar 2026 - Mar 2041",15),("Fire Suppression","Viking Group","Jun 2026 - Jun 2031",5)]
            ForEach(warranties, id: \.0) { w in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) { Text(w.0).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Text("\(w.1) \u{2022} \(w.2)").font(.system(size: 9)).foregroundColor(Theme.muted) }
                    Spacer()
                    Text("\(w.3) YR").font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.cyan)
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    private var meetingMinutes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OAC MEETING MINUTES").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
            let meetings: [(String, Int, Int, Int)] = [("Mar 24, 2026",8,5,3),("Mar 17, 2026",7,4,2),("Mar 10, 2026",9,6,1)]
            ForEach(meetings, id: \.0) { m in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) { Text("OAC Meeting \u{2014} \(m.0)").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Text("\(m.1) attendees").font(.system(size: 9)).foregroundColor(Theme.muted) }
                    Spacer()
                    VStack(spacing: 1) { Text("\(m.2)").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.accent); Text("ACTIONS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }
                    VStack(spacing: 1) { Text("\(m.3)").font(.system(size: 14, weight: .heavy)).foregroundColor(m.3 > 0 ? Theme.gold : Theme.green); Text("OPEN").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }
}
