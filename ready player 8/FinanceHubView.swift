import SwiftUI

// MARK: - ========== Finance Hub Tab ==========

struct FinanceHubView: View {
    @State private var activeTab = 0
    private let tabs = ["Invoices", "Lien Waivers", "Cash Flow"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FINANCE HUB").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.green)
                        Text("Financial Command Center").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                    }
                    Spacer()
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.green)

                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button { withAnimation { activeTab = i } } label: {
                            Text(tabs[i].uppercased()).font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(activeTab == i ? .black : Theme.muted).frame(maxWidth: .infinity).padding(.vertical, 9).background(activeTab == i ? Theme.green : Theme.surface)
                        }.buttonStyle(.plain)
                    }
                }.cornerRadius(8)

                if activeTab == 0 { invoicesContent }
                else if activeTab == 1 { liensContent }
                else { cashFlowContent }
            }.padding(16)
        }.background(Theme.bg)
    }

    private var invoicesContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AIA G702/G703 PAY APPLICATIONS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("$952K").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("BILLED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("$95K").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.gold); Text("RETAINAGE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.gold.opacity(0.06)).cornerRadius(8)
            }
            let invoices: [(String, String, String, String, String)] = [("#07","Riverside Lofts","$284,500","$28,450","SUBMITTED"),("#06","Riverside Lofts","$312,100","$31,210","APPROVED"),("#04","Harbor Crossing","$198,750","$19,875","DRAFT"),("#12","Pine Ridge Ph.2","$156,200","$15,620","PAID")]
            ForEach(invoices, id: \.0) { inv in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) { Text("Pay App \(inv.0)").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Text(inv.1).font(.system(size: 9)).foregroundColor(Theme.muted) }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) { Text(inv.2).font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.accent); Text("Ret: \(inv.3)").font(.system(size: 8)).foregroundColor(Theme.gold) }
                    Text(inv.4).font(.system(size: 7, weight: .black)).foregroundColor(inv.4 == "PAID" ? Theme.green : inv.4 == "APPROVED" ? Theme.cyan : Theme.gold).padding(.horizontal, 6).padding(.vertical, 3).background((inv.4 == "PAID" ? Theme.green : Theme.gold).opacity(0.1)).cornerRadius(4)
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    private var liensContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LIEN WAIVER MANAGER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
            let waivers: [(String, String, String, String, String)] = [("Apex Concrete","Conditional Progress","$48,200","RECEIVED","Apr 1"),("Elite Steel","Conditional Progress","$32,100","PENDING","Apr 1"),("Prime Electric","Unconditional","$15,800","RECEIVED","N/A"),("Quick Plumbing","Conditional Final","$22,400","REQUESTED","Apr 15")]
            ForEach(waivers, id: \.0) { w in
                HStack(spacing: 8) {
                    Image(systemName: w.3 == "RECEIVED" ? "checkmark.circle.fill" : "clock.fill").font(.system(size: 12)).foregroundColor(w.3 == "RECEIVED" ? Theme.green : Theme.gold)
                    VStack(alignment: .leading, spacing: 2) { Text(w.0).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Text("\(w.1) \u{2022} \(w.2)").font(.system(size: 9)).foregroundColor(Theme.muted) }
                    Spacer()
                    if w.4 != "N/A" { Text("Due: \(w.4)").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold) }
                    Text(w.3).font(.system(size: 7, weight: .black)).foregroundColor(w.3 == "RECEIVED" ? Theme.green : Theme.gold)
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    private var cashFlowContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CASH FLOW FORECAST").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            let months: [(String, Double, Double)] = [("Apr",485000,342000),("May",520000,398000),("Jun",610000,445000),("Jul",475000,380000)]
            ForEach(months, id: \.0) { m in
                let net = m.1 - m.2
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(m.0).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text("+$\(String(format: "%.0f", net/1000))K").font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.green) }
                    HStack(spacing: 12) { Text("AR: $\(String(format: "%.0f", m.1/1000))K").font(.system(size: 9)).foregroundColor(Theme.green); Text("AP: $\(String(format: "%.0f", m.2/1000))K").font(.system(size: 9)).foregroundColor(Theme.red) }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }
}
