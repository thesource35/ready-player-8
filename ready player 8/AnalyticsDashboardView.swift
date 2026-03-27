import SwiftUI

// MARK: - ========== Analytics Dashboard Tab ==========

struct AnalyticsDashboardView: View {
    @State private var activeTab = 0
    private let tabs = ["Bids", "Labor", "Risk AI"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ANALYTICS").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.accent)
                        Text("Business Intelligence").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                    }
                    Spacer()
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.accent)

                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button { withAnimation { activeTab = i } } label: { Text(tabs[i].uppercased()).font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(activeTab == i ? .black : Theme.muted).frame(maxWidth: .infinity).padding(.vertical, 9).background(activeTab == i ? Theme.accent : Theme.surface) }.buttonStyle(.plain)
                    }
                }.cornerRadius(8)

                if activeTab == 0 { bidAnalytics }
                else if activeTab == 1 { laborProductivity }
                else { riskAI }
            }.padding(16)
        }.background(Theme.bg)
    }

    private var bidAnalytics: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BID WIN/LOSS ANALYTICS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("68%").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.green); Text("WIN RATE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("47").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.accent); Text("BIDS YTD").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("$142M").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.gold); Text("PIPELINE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("12.4%").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.cyan); Text("AVG MARKUP").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
            }
            let sectors: [(String, Int, Int, Int)] = [("Commercial",18,13,72),("Healthcare",8,6,75),("Industrial",7,4,57),("Residential",9,7,78),("Infrastructure",5,2,40)]
            ForEach(sectors, id: \.0) { s in
                HStack(spacing: 8) {
                    Text(s.0).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text).frame(width: 80, alignment: .leading)
                    GeometryReader { geo in ZStack(alignment: .leading) { RoundedRectangle(cornerRadius: 3).fill(Theme.border.opacity(0.3)).frame(height: 8); RoundedRectangle(cornerRadius: 3).fill(s.3 >= 70 ? Theme.green : s.3 >= 50 ? Theme.gold : Theme.red).frame(width: geo.size.width * CGFloat(s.3) / 100, height: 8) } }.frame(height: 8)
                    Text("\(s.3)%").font(.system(size: 10, weight: .heavy)).foregroundColor(s.3 >= 70 ? Theme.green : s.3 >= 50 ? Theme.gold : Theme.red).frame(width: 35)
                    Text("\(s.2)/\(s.1)").font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.muted).frame(width: 30)
                }
            }
        }
    }

    private var laborProductivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LABOR PRODUCTIVITY").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            let trades: [(String, Double, Double, String)] = [("Concrete (CY/hr)",2.8,2.5,"+12%"),("Framing (SF/hr)",14.2,12.0,"+18%"),("Electrical (dev/hr)",3.1,3.5,"-11%"),("Drywall (SF/hr)",22.5,20.0,"+13%"),("Plumbing (fix/hr)",1.8,2.0,"-10%"),("Painting (SF/hr)",45.0,40.0,"+13%")]
            ForEach(trades, id: \.0) { t in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) { Text(t.0).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Text("Benchmark: \(String(format: "%.1f", t.2))").font(.system(size: 8)).foregroundColor(Theme.muted) }
                    Spacer()
                    Text(String(format: "%.1f", t.1)).font(.system(size: 16, weight: .heavy)).foregroundColor(t.1 >= t.2 ? Theme.green : Theme.red)
                    Text(t.3).font(.system(size: 9, weight: .bold)).foregroundColor(t.3.hasPrefix("+") ? Theme.green : Theme.red)
                }.padding(8).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    private var riskAI: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI RISK SCORING").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.red)
            Text("ML-based project risk prediction using historical patterns").font(.system(size: 10)).foregroundColor(Theme.muted)
            let risks: [(String, Int, [String], String)] = [
                ("Riverside Lofts", 92, ["Weather delays (3x in 30d)", "Sub default risk", "Permit renewal pending"], "HIGH RISK - Schedule slip likely"),
                ("Harbor Crossing", 34, ["On-time deliveries", "Strong sub performance"], "LOW RISK - On track"),
                ("Pine Ridge Ph.2", 67, ["Inspection backlog", "Labor shortage trend", "Material price volatility"], "MODERATE - Monitor closely"),
            ]
            ForEach(risks, id: \.0) { r in
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text(r.0).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text("\(r.1)/100").font(.system(size: 14, weight: .heavy)).foregroundColor(r.1 >= 70 ? Theme.red : r.1 >= 40 ? Theme.gold : Theme.green) }
                    GeometryReader { geo in ZStack(alignment: .leading) { RoundedRectangle(cornerRadius: 3).fill(Theme.border.opacity(0.3)).frame(height: 6); RoundedRectangle(cornerRadius: 3).fill(r.1 >= 70 ? Theme.red : r.1 >= 40 ? Theme.gold : Theme.green).frame(width: geo.size.width * CGFloat(r.1) / 100, height: 6) } }.frame(height: 6)
                    ForEach(r.2, id: \.self) { f in HStack(spacing: 4) { Circle().fill(Theme.red.opacity(0.5)).frame(width: 4, height: 4); Text(f).font(.system(size: 9)).foregroundColor(Theme.muted) } }
                    Text(r.3).font(.system(size: 10, weight: .heavy)).foregroundColor(r.1 >= 70 ? Theme.red : r.1 >= 40 ? Theme.gold : Theme.green)
                }.padding(12).background(r.1 >= 70 ? Theme.red.opacity(0.04) : Theme.surface).cornerRadius(10)
            }
        }
    }
}
