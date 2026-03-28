import SwiftUI

// MARK: - ========== Smart Build Hub ==========

struct SmartBuildHubView: View {
    @State private var activeTab = 0
    private let tabs = ["Concrete AI", "BIM Center", "Net Zero", "Modular DCC", "Auto Home"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) { Text("\u{1F3D7}").font(.system(size: 18)); Text("SMART BUILD").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.purple) }
                        Text("Intelligent Construction Hub").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("Smart concrete, BIM, net zero, modular, and automated home building").font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.purple)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(tabs.indices, id: \.self) { i in
                            Button { withAnimation { activeTab = i } } label: {
                                Text(tabs[i].uppercased()).font(.system(size: 8, weight: .bold)).tracking(1)
                                    .foregroundColor(activeTab == i ? .black : Theme.muted)
                                    .padding(.horizontal, 12).padding(.vertical, 9)
                                    .background(activeTab == i ? Theme.purple : Theme.surface)
                            }.buttonStyle(.plain)
                        }
                    }.cornerRadius(8)
                }

                switch activeTab {
                case 0: concreteAI
                case 1: bimCenter
                case 2: netZero
                case 3: modularDCC
                default: autoHome
                }
            }.padding(16)
        }.background(Theme.bg)
    }

    // MARK: Smart Concrete Testing
    private var concreteAI: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SMART CONCRETE TESTING AI").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            Text("IoT sensors embedded in pours with AI-predicted strength curves").font(.system(size: 9)).foregroundColor(Theme.muted)
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("12").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("ACTIVE POURS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("48").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("SENSORS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("99.1%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.gold); Text("AI ACCURACY").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
            }
            let pours: [(id: String, location: String, mix: String, temp: String, strength: String, target: String, age: String, status: String)] = [
                ("P-041", "L3 Slab Pour A", "4000 PSI", "72\u{00B0}F", "3,240 PSI", "4,000 PSI", "5 days", "CURING"),
                ("P-040", "L2 Columns C1-C8", "5000 PSI", "68\u{00B0}F", "4,890 PSI", "5,000 PSI", "12 days", "97.8%"),
                ("P-039", "Foundation Wall N", "4000 PSI", "65\u{00B0}F", "4,120 PSI", "4,000 PSI", "21 days", "PASSED"),
                ("P-038", "Mat Slab Section 2", "5000 PSI", "70\u{00B0}F", "5,250 PSI", "5,000 PSI", "28 days", "PASSED"),
            ]
            ForEach(pours, id: \.id) { p in
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text("\(p.id) \u{2014} \(p.location)").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text(p.status).font(.system(size: 8, weight: .black)).foregroundColor(p.status == "PASSED" ? Theme.green : p.status == "CURING" ? Theme.gold : Theme.cyan) }
                    HStack(spacing: 12) {
                        Text("Mix: \(p.mix)").font(.system(size: 8)).foregroundColor(Theme.muted)
                        Text("Temp: \(p.temp)").font(.system(size: 8)).foregroundColor(Theme.muted)
                        Text("Age: \(p.age)").font(.system(size: 8)).foregroundColor(Theme.cyan)
                    }
                    HStack(spacing: 4) {
                        Text("Strength:").font(.system(size: 8)).foregroundColor(Theme.muted)
                        Text(p.strength).font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.accent)
                        Text("/ \(p.target)").font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
            Text("AI PREDICTION: Pour P-041 will reach 4,000 PSI target in 2.3 days based on temperature and maturity curve analysis.").font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.purple).padding(10).background(Theme.purple.opacity(0.06)).cornerRadius(8)
        }.padding(14).background(Theme.surface).cornerRadius(12).premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }

    // MARK: BIM & 3D Modeling
    private var bimCenter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BIM & 3D MODELING CENTER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("LOD 400").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.gold); Text("MODEL LEVEL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("2.4M").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.cyan); Text("ELEMENTS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("0").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.green); Text("CLASHES").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
            }
            let models: [(String, String, String, String, String)] = [
                ("Architectural", "Revit 2026", "LOD 400", "482K elements", "CURRENT"),
                ("Structural", "Tekla Structures", "LOD 350", "218K elements", "CURRENT"),
                ("MEP", "Revit MEP", "LOD 400", "1.2M elements", "CURRENT"),
                ("Civil/Site", "Civil 3D", "LOD 300", "94K elements", "UPDATING"),
                ("Landscape", "Lumion", "LOD 200", "45K elements", "CURRENT"),
                ("Federated Model", "Navisworks", "Combined", "2.4M elements", "SYNCED"),
            ]
            ForEach(models, id: \.0) { m in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) { Text(m.0).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Text("\(m.1) \u{2022} \(m.2)").font(.system(size: 8)).foregroundColor(Theme.muted) }
                    Spacer()
                    Text(m.3).font(.system(size: 8, weight: .semibold)).foregroundColor(Theme.cyan)
                    Text(m.4).font(.system(size: 7, weight: .black)).foregroundColor(m.4 == "CURRENT" || m.4 == "SYNCED" ? Theme.green : Theme.gold)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }
        }.padding(14).background(Theme.surface).cornerRadius(12)
    }

    // MARK: Net Zero Design
    private var netZero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NET ZERO BUILDING DESIGN").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("-42%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("CARBON").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("EUI 22").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.cyan); Text("kBtu/SF/yr").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("NET ZERO").font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.gold); Text("TARGET").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
            }
            let lowCarbon: [(material: String, carbon: String, alternative: String, savings: String)] = [
                ("Low-carbon concrete (LC3)", "40% less CO2", "Replaces OPC", "1,200 tons saved"),
                ("Cross-laminated timber (CLT)", "Carbon negative", "Replaces steel frame", "2,800 tons stored"),
                ("Recycled steel (EAF)", "75% less energy", "Replaces BOF steel", "890 tons saved"),
                ("Hempcrete insulation", "Carbon sequestering", "Replaces foam board", "45 tons stored"),
                ("Geopolymer concrete", "80% less CO2", "Replaces Portland", "640 tons saved"),
                ("Bio-based composites", "Net negative carbon", "Replaces FRP", "120 tons stored"),
            ]
            ForEach(lowCarbon, id: \.material) { m in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) { Text(m.material).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Text("\(m.carbon) \u{2022} \(m.alternative)").font(.system(size: 8)).foregroundColor(Theme.muted) }
                    Spacer()
                    Text(m.savings).font(.system(size: 8, weight: .heavy)).foregroundColor(Theme.green)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }
        }.padding(14).background(Theme.surface).cornerRadius(12).premiumGlow(cornerRadius: 12, color: Theme.green)
    }

    // MARK: Modular & Digital Component
    private var modularDCC: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MODULAR & DIGITAL COMPONENT CONSTRUCTION").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
            Text("Off-site fabrication with digital twin integration and automated assembly sequencing").font(.system(size: 9)).foregroundColor(Theme.muted)
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("86%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("PREFAB RATE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("214").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("COMPONENTS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("47%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("TIME SAVED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
            }
            let components: [(name: String, type: String, factory: String, status: String, sequence: Int)] = [
                ("Bathroom Pod Type A (x24)", "Volumetric", "ModularCraft TX", "DELIVERED", 1),
                ("Exterior Wall Panel N1-N12", "2D Panel", "PanelWorks FL", "FABRICATING", 2),
                ("MEP Rack Assembly L3-L5", "Pre-assembled", "PrefabTech GA", "IN TRANSIT", 3),
                ("Stair Module S1-S4", "Volumetric", "StairPro OH", "DESIGN COMPLETE", 4),
                ("Roof Cassette R1-R8", "2D Panel", "RoofTech CA", "ENGINEERING", 5),
            ]
            ForEach(components, id: \.name) { c in
                HStack(spacing: 8) {
                    Text("#\(c.sequence)").font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.accent).frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) { Text(c.name).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Text("\(c.type) \u{2022} \(c.factory)").font(.system(size: 8)).foregroundColor(Theme.muted) }
                    Spacer()
                    Text(c.status).font(.system(size: 7, weight: .black)).foregroundColor(c.status == "DELIVERED" ? Theme.green : c.status == "IN TRANSIT" ? Theme.cyan : Theme.gold)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }
        }.padding(14).background(Theme.surface).cornerRadius(12)
    }

    // MARK: Automated Home Building
    private var autoHome: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUTOMATED HOME BUILDING TECHNOLOGY").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            let technologies: [(name: String, description: String, speed: String, cost: String, status: String)] = [
                ("3D Concrete Printing", "Walls and foundations printed layer-by-layer", "600 SF/day", "$120/SF", "PRODUCTION"),
                ("Robotic Framing", "CNC-cut and robot-assembled wood frames", "1 floor/day", "$85/SF", "BETA"),
                ("Automated Bricklaying", "SAM-200 lays 500 bricks/hr", "2,000 SF/day", "$95/SF", "PRODUCTION"),
                ("Drone-Placed Roofing", "Autonomous shingle placement", "2,400 SF/day", "$8/SF", "PILOT"),
                ("AI-Optimized HVAC", "ML-designed ductwork and zoning", "Design: 2 hrs", "15% savings", "PRODUCTION"),
                ("Prefab Electrical Harness", "Factory-wired and tested", "Install: 4 hrs", "40% labor saved", "PRODUCTION"),
                ("Automated Tiling System", "Robotic precision tile placement", "200 SF/day", "$12/SF", "PILOT"),
                ("Self-Healing Concrete", "Bacteria-infused mix auto-repairs cracks", "Lifetime", "+8% material", "RESEARCH"),
            ]
            ForEach(technologies, id: \.name) { t in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.name).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                        Text(t.description).font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(t.speed).font(.system(size: 8, weight: .heavy)).foregroundColor(Theme.cyan)
                        Text(t.cost).font(.system(size: 8)).foregroundColor(Theme.accent)
                    }
                    Text(t.status).font(.system(size: 6, weight: .black)).foregroundColor(t.status == "PRODUCTION" ? Theme.green : t.status == "BETA" ? Theme.cyan : t.status == "PILOT" ? Theme.gold : Theme.purple).frame(width: 50)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }
        }.padding(14).background(Theme.surface).cornerRadius(12)
    }
}
