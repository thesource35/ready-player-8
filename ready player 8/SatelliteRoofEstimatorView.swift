import SwiftUI

// MARK: - ========== Satellite Roofing Estimator ==========

struct RoofEstimate: Identifiable, Codable {
    var id = UUID()
    let address: String
    let roofArea: Double      // sq ft
    let pitch: String
    let roofType: String
    let material: String
    let layers: Int
    let condition: String
    let estimatedCost: Double
    let laborCost: Double
    let materialCost: Double
    let wastePercent: Double
    let dumpsterCost: Double
    let permitCost: Double
    let totalCost: Double
    let createdAt: Date
}

struct SatelliteRoofEstimatorView: View {
    @State private var address = ""
    @State private var roofArea = ""
    @State private var pitch = "4/12"
    @State private var roofType = "Gable"
    @State private var material = "Asphalt Shingle"
    @State private var layers = 1
    @State private var condition = "Fair"
    @State private var estimate: RoofEstimate?
    @State private var savedEstimates: [RoofEstimate] = []
    @State private var isCalculating = false

    private let pitches = ["2/12", "3/12", "4/12", "5/12", "6/12", "7/12", "8/12", "10/12", "12/12"]
    private let roofTypes = ["Gable", "Hip", "Flat", "Mansard", "Gambrel", "Shed", "Butterfly"]
    private let materials = ["Asphalt Shingle", "Metal Standing Seam", "TPO Membrane", "EPDM Rubber", "Clay Tile", "Slate", "Wood Shake", "Composite", "Green Roof"]
    private let conditions = ["New Construction", "Good", "Fair", "Poor", "Storm Damage"]

    private let materialRates: [String: Double] = [
        "Asphalt Shingle": 4.50, "Metal Standing Seam": 12.00, "TPO Membrane": 7.50,
        "EPDM Rubber": 6.00, "Clay Tile": 15.00, "Slate": 22.00,
        "Wood Shake": 10.00, "Composite": 8.50, "Green Roof": 25.00
    ]

    private func calculateEstimate() {
        guard let area = Double(roofArea.replacingOccurrences(of: ",", with: "")), area > 0 else { return }
        isCalculating = true

        let pitchMultiplier: Double = {
            let rise = Double(pitch.split(separator: "/").first ?? "4") ?? 4
            return 1.0 + (rise - 2) * 0.03
        }()

        let actualArea = area * pitchMultiplier
        let matRate = materialRates[material] ?? 5.0
        let matCost = actualArea * matRate
        let laborRate = matRate * 0.6
        let labCost = actualArea * laborRate
        let waste = actualArea * matRate * 0.12
        let tearOff = layers > 1 ? actualArea * 1.50 : 0
        let dumpster = layers > 1 ? 650.0 : 450.0
        let permit = area > 2000 ? 350.0 : 200.0
        let total = matCost + labCost + waste + tearOff + dumpster + permit

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            estimate = RoofEstimate(address: address, roofArea: area, pitch: pitch, roofType: roofType, material: material, layers: layers, condition: condition, estimatedCost: matCost + labCost, laborCost: labCost, materialCost: matCost, wastePercent: 12, dumpsterCost: dumpster, permitCost: permit, totalCost: total, createdAt: Date())
            isCalculating = false
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) { Text("\u{1F3E0}").font(.system(size: 18)); Text("SATELLITE ROOFING").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.gold) }
                        Text("AI Roof Estimator").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("Satellite-measured area with material and labor pricing").font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.gold)

                // Input form
                VStack(alignment: .leading, spacing: 10) {
                    Text("ROOF DETAILS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
                    TextField("Property address", text: $address).font(.system(size: 12)).padding(10).background(Theme.panel).cornerRadius(8)
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 3) { Text("AREA (SF)").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); TextField("2,400", text: $roofArea).font(.system(size: 12)).padding(8).background(Theme.panel).cornerRadius(6) }
                        VStack(alignment: .leading, spacing: 3) { Text("PITCH").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 4) { ForEach(pitches, id: \.self) { p in Button { pitch = p } label: { Text(p).font(.system(size: 9, weight: .bold)).foregroundColor(pitch == p ? .black : Theme.text).padding(.horizontal, 6).padding(.vertical, 4).background(pitch == p ? Theme.gold : Theme.panel).cornerRadius(4) }.buttonStyle(.plain) } } }
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) { Text("ROOF TYPE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 4) { ForEach(roofTypes, id: \.self) { t in Button { roofType = t } label: { Text(t).font(.system(size: 9, weight: .bold)).foregroundColor(roofType == t ? .black : Theme.text).padding(.horizontal, 8).padding(.vertical, 4).background(roofType == t ? Theme.cyan : Theme.panel).cornerRadius(4) }.buttonStyle(.plain) } } }
                    }
                    VStack(alignment: .leading, spacing: 3) { Text("MATERIAL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 4) { ForEach(materials, id: \.self) { m in Button { material = m } label: { Text(m).font(.system(size: 8, weight: .bold)).foregroundColor(material == m ? .black : Theme.text).padding(.horizontal, 8).padding(.vertical, 4).background(material == m ? Theme.accent : Theme.panel).cornerRadius(4) }.buttonStyle(.plain) } } }
                    }
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) { Text("LAYERS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted); Stepper("\(layers)", value: $layers, in: 1...3).font(.system(size: 11, weight: .bold)) }
                        VStack(alignment: .leading, spacing: 3) { Text("CONDITION").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 4) { ForEach(conditions, id: \.self) { c in Button { condition = c } label: { Text(c).font(.system(size: 8, weight: .bold)).foregroundColor(condition == c ? .black : Theme.text).padding(.horizontal, 6).padding(.vertical, 4).background(condition == c ? Theme.green : Theme.panel).cornerRadius(4) }.buttonStyle(.plain) } } }
                        }
                    }

                    Button { calculateEstimate() } label: {
                        Group {
                            if isCalculating { HStack { ProgressView().tint(.black); Text("CALCULATING...") } }
                            else { Text("GENERATE ESTIMATE") }
                        }.font(.system(size: 13, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 14).background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing)).cornerRadius(10)
                    }.buttonStyle(.plain).disabled(roofArea.isEmpty)
                }.padding(14).background(Theme.surface).cornerRadius(12)

                // Estimate result
                if let est = estimate {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ESTIMATE RESULT").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
                        HStack(spacing: 8) {
                            VStack(spacing: 2) { Text("$\(String(format: "%.0f", est.totalCost))").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.accent); Text("TOTAL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                            VStack(spacing: 2) { Text("$\(String(format: "%.0f", est.materialCost))").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("MATERIAL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                            VStack(spacing: 2) { Text("$\(String(format: "%.0f", est.laborCost))").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("LABOR").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text("Material (\(est.material))").font(.system(size: 9)).foregroundColor(Theme.muted); Spacer(); Text("$\(String(format: "%.0f", est.materialCost))").font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.text) }
                            HStack { Text("Labor").font(.system(size: 9)).foregroundColor(Theme.muted); Spacer(); Text("$\(String(format: "%.0f", est.laborCost))").font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.text) }
                            HStack { Text("Waste (\(String(format: "%.0f", est.wastePercent))%)").font(.system(size: 9)).foregroundColor(Theme.muted); Spacer(); Text("$\(String(format: "%.0f", est.materialCost * est.wastePercent / 100))").font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.text) }
                            HStack { Text("Dumpster").font(.system(size: 9)).foregroundColor(Theme.muted); Spacer(); Text("$\(String(format: "%.0f", est.dumpsterCost))").font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.text) }
                            HStack { Text("Permit").font(.system(size: 9)).foregroundColor(Theme.muted); Spacer(); Text("$\(String(format: "%.0f", est.permitCost))").font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.text) }
                            Divider().background(Theme.border)
                            HStack { Text("TOTAL ESTIMATE").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text("$\(String(format: "%.0f", est.totalCost))").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.accent) }
                            Text("\(String(format: "%.0f", est.roofArea)) SF \u{2022} \(est.pitch) pitch \u{2022} \(est.roofType) \u{2022} \(est.layers) layer\(est.layers > 1 ? "s" : "")").font(.system(size: 8)).foregroundColor(Theme.muted)
                        }
                    }.padding(14).background(Theme.surface).cornerRadius(12).premiumGlow(cornerRadius: 12, color: Theme.green)
                }
            }.padding(16)
        }.background(Theme.bg)
        .onAppear { savedEstimates = loadJSON("ConstructOS.Roofing.Estimates", default: [RoofEstimate]()) }
    }
}
