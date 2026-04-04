import SwiftUI

// MARK: - ========== Compliance Tab ==========

struct ComplianceView: View {
    @State private var activeTab = 0
    private let tabs = ["Toolbox Talks", "Payroll", "Environmental"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("COMPLIANCE").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.red)
                        Text("Safety & Regulatory").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                    }
                    Spacer()
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.red)

                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button { withAnimation { activeTab = i } } label: { Text(tabs[i].uppercased()).font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(activeTab == i ? .black : Theme.muted).frame(maxWidth: .infinity).padding(.vertical, 9).background(activeTab == i ? Theme.red : Theme.surface) }.buttonStyle(.plain)
                    }
                }.cornerRadius(8)

                if activeTab == 0 { toolboxContent }
                else if activeTab == 1 { payrollContent }
                else { environmentalContent }
            }.padding(16)
        }.background(Theme.bg)
    }

    private var toolboxContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WEEKLY TOOLBOX TALKS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            let topics: [(String, String, String, Bool)] = [("Fall Protection - Harness Inspection","Fall Protection","15 min",true),("Trenching & Excavation Safety","Excavation","20 min",true),("Electrical Safety - Lockout/Tagout","Electrical","15 min",true),("Heat Illness Prevention","Weather","10 min",false),("Scaffold Safety","Fall Protection","15 min",true),("Silica Dust Exposure","Health","20 min",true),("Fire Prevention on Jobsite","Fire Safety","15 min",false),("PPE Inspection & Usage","General","10 min",true)]
            ForEach(topics, id: \.0) { t in
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkered").font(.system(size: 12)).foregroundColor(t.3 ? Theme.red : Theme.gold)
                    VStack(alignment: .leading, spacing: 2) { Text(t.0).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Text("\(t.1) \u{2022} \(t.2)").font(.system(size: 9)).foregroundColor(Theme.muted) }
                    Spacer()
                    if t.3 { Text("REQUIRED").font(.system(size: 7, weight: .black)).foregroundColor(Theme.red) }
                    Button { ToastManager.shared.show("Coming soon") } label: { Text("START").font(.system(size: 8, weight: .bold)).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 4).background(Theme.gold).cornerRadius(4) }.buttonStyle(.plain)
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    private var payrollContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CERTIFIED PAYROLL (WH-347)").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
            let weeks: [(String, Int, Double, String, String)] = [("Week 12 (Mar 17-23)",38,1520,"$98,400","SUBMITTED"),("Week 11 (Mar 10-16)",41,1640,"$106,200","APPROVED"),("Week 10 (Mar 3-9)",36,1440,"$93,600","APPROVED")]
            ForEach(weeks, id: \.0) { w in
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(w.0).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text(w.4).font(.system(size: 8, weight: .black)).foregroundColor(w.4 == "APPROVED" ? Theme.green : Theme.gold) }
                    HStack(spacing: 12) { Text("\(w.1) employees").font(.system(size: 9)).foregroundColor(Theme.muted); Text("\(String(format: "%.0f", w.2)) hrs").font(.system(size: 9)).foregroundColor(Theme.cyan); Text(w.3).font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.accent) }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    private var environmentalContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ENVIRONMENTAL COMPLIANCE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
            let items: [(String, String, String, String)] = [("SWPPP Plan","CURRENT","Mar 20","Apr 20"),("Dust Monitoring","CURRENT","Mar 24","Mar 31"),("Noise Compliance","DUE","Mar 10","Mar 25"),("Erosion Controls","CURRENT","Mar 22","Apr 5"),("Waste Disposal Log","CURRENT","Mar 25","Apr 1"),("EPA Stormwater Permit","ACTIVE","Jan 15","Jan 15/27")]
            ForEach(items, id: \.0) { item in
                HStack(spacing: 8) {
                    Circle().fill(item.1 == "DUE" ? Theme.gold : Theme.green).frame(width: 6, height: 6)
                    Text(item.0).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                    Spacer()
                    Text("Last: \(item.2)").font(.system(size: 8)).foregroundColor(Theme.muted)
                    Text("Next: \(item.3)").font(.system(size: 8, weight: .bold)).foregroundColor(item.1 == "DUE" ? Theme.gold : Theme.muted)
                    Text(item.1).font(.system(size: 7, weight: .black)).foregroundColor(item.1 == "DUE" ? Theme.gold : Theme.green)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }
        }
    }
}
