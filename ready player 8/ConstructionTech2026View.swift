import SwiftUI

// MARK: - ========== Construction Tech 2026 ==========

struct ConstructionTech2026View: View {
    @State private var activeTab = 0
    private let tabs = ["Digital Twin", "Robotics", "3D Scan", "Sustainability", "Wearables", "Modular", "5G/IoT"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("\u{1F916}").font(.system(size: 18))
                            Text("TECH 2026").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.purple)
                        }
                        Text("Construction Technology Hub").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("AI, robotics, digital twins, sustainability, and smart site technology").font(.system(size: 11)).foregroundColor(Theme.muted)
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
                case 0: digitalTwinView
                case 1: roboticsView
                case 2: laserScanView
                case 3: sustainabilityView
                case 4: wearablesView
                case 5: modularView
                default: connectivityView
                }
            }.padding(16)
        }.background(Theme.bg)
    }

    // MARK: - Digital Twin

    private var digitalTwinView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REAL-TIME DIGITAL TWIN").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            Text("Live 3D model synced with jobsite sensors, drones, and BIM data").font(.system(size: 9)).foregroundColor(Theme.muted)

            // Twin status dashboard
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("98.2%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("SYNC RATE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("847").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("IoT SENSORS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("1.2s").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("LATENCY").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("4").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.purple); Text("DRONE FEEDS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.purple.opacity(0.06)).cornerRadius(8)
            }

            // Twin layers
            let layers: [(String, String, String, Bool)] = [
                ("Structural Model", "IFC/BIM synchronized", "LIVE", true),
                ("MEP Coordination", "Clash detection active", "LIVE", true),
                ("Progress Overlay", "AI-verified vs. schedule", "LIVE", true),
                ("Thermal Layer", "IR camera feed", "ACTIVE", true),
                ("Drone Photogrammetry", "Last capture: 2h ago", "SYNCED", true),
                ("IoT Sensor Mesh", "Concrete cure, vibration, temp", "847 nodes", true),
                ("Earthwork Volume", "Cut/fill vs. design grade", "SYNCED", false),
            ]
            ForEach(layers, id: \.0) { layer in
                HStack(spacing: 8) {
                    Circle().fill(layer.3 ? Theme.green : Theme.gold).frame(width: 6, height: 6)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(layer.0).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                        Text(layer.1).font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text(layer.2).font(.system(size: 8, weight: .black)).foregroundColor(layer.3 ? Theme.green : Theme.gold)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }

            // AI clash detection
            VStack(alignment: .leading, spacing: 6) {
                Text("AI CLASH DETECTION").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.red)
                let clashes: [(String, String, String)] = [
                    ("HVAC duct vs. structural beam", "Grid C-4, Level 3", "CRITICAL"),
                    ("Plumbing riser vs. conduit run", "Core B, Levels 2-4", "MODERATE"),
                    ("Fire sprinkler vs. cable tray", "Grid A-7, Level 2", "RESOLVED"),
                ]
                ForEach(clashes, id: \.0) { clash in
                    HStack(spacing: 6) {
                        Circle().fill(clash.2 == "CRITICAL" ? Theme.red : clash.2 == "RESOLVED" ? Theme.green : Theme.gold).frame(width: 5, height: 5)
                        Text(clash.0).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text)
                        Spacer()
                        Text(clash.1).font(.system(size: 8)).foregroundColor(Theme.muted)
                        Text(clash.2).font(.system(size: 7, weight: .black)).foregroundColor(clash.2 == "CRITICAL" ? Theme.red : clash.2 == "RESOLVED" ? Theme.green : Theme.gold)
                    }
                }
            }.padding(10).background(Theme.red.opacity(0.04)).cornerRadius(8)
        }
        .padding(14).background(Theme.surface).cornerRadius(12).premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }

    // MARK: - Robotics

    private var roboticsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ROBOTICS & AUTONOMOUS EQUIPMENT").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)

            let robots: [(name: String, type: String, status: String, productivity: String, site: String, hours: Int)] = [
                ("TyBot R-3", "Rebar Tying Robot", "OPERATING", "1,400 ties/hr", "Riverside Lofts", 2840),
                ("SAM-200", "Bricklaying Robot", "STANDBY", "500 bricks/hr", "Pine Ridge Ph.2", 1200),
                ("Hilti Jaibot", "MEP Drill Robot", "OPERATING", "120 holes/hr", "Harbor Crossing", 890),
                ("Dusty Robotics", "Layout Robot", "COMPLETE", "10,000 SF/hr", "Eastside Civic", 340),
                ("Spot (Boston Dynamics)", "Inspection Robot", "PATROLLING", "24/7 coverage", "All Sites", 4200),
                ("Print3D-X", "Concrete 3D Printer", "CALIBRATING", "12 CY/hr", "Innovation Lab", 180),
            ]

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("\(robots.filter { $0.status == "OPERATING" }.count)").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("OPERATING").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("\(robots.count)").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("FLEET").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("\(robots.reduce(0) { $0 + $1.hours })").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("TOTAL HRS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
            }

            ForEach(robots, id: \.name) { robot in
                HStack(spacing: 10) {
                    Circle().fill(robot.status == "OPERATING" ? Theme.green : robot.status == "PATROLLING" ? Theme.cyan : robot.status == "STANDBY" ? Theme.gold : Theme.muted).frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(robot.name).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                        Text("\(robot.type) \u{2022} \(robot.site)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(robot.productivity).font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.accent)
                        Text(robot.status).font(.system(size: 7, weight: .black)).foregroundColor(robot.status == "OPERATING" ? Theme.green : robot.status == "PATROLLING" ? Theme.cyan : Theme.gold)
                    }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }

    // MARK: - 3D Laser Scan

    private var laserScanView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("3D LASER SCANNING & REALITY CAPTURE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)

            let scans: [(site: String, scanner: String, points: String, accuracy: String, date: String, status: String)] = [
                ("Riverside Lofts L3", "Leica RTC360", "42M points", "\u{00B1}1.9mm", "Mar 25", "PROCESSED"),
                ("Harbor Crossing Ext", "Faro Focus S350", "68M points", "\u{00B1}1.0mm", "Mar 24", "PROCESSING"),
                ("Pine Ridge Foundation", "Trimble X7", "28M points", "\u{00B1}2.4mm", "Mar 22", "COMPLETE"),
                ("Eastside MEP Coord", "Leica BLK360", "35M points", "\u{00B1}4.0mm", "Mar 20", "REGISTERED"),
            ]

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("173M").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.gold); Text("TOTAL POINTS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("\(scans.count)").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("SCANS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("99.2%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("BIM MATCH").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
            }

            ForEach(scans, id: \.site) { scan in
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(scan.site).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text(scan.status).font(.system(size: 7, weight: .black)).foregroundColor(scan.status == "COMPLETE" || scan.status == "REGISTERED" ? Theme.green : Theme.gold) }
                    HStack(spacing: 12) {
                        Text(scan.scanner).font(.system(size: 8)).foregroundColor(Theme.muted)
                        Text(scan.points).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.cyan)
                        Text("Accuracy: \(scan.accuracy)").font(.system(size: 8)).foregroundColor(Theme.green)
                        Text(scan.date).font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("SCAN-TO-BIM DEVIATIONS").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.red)
                let deviations: [(String, String, String)] = [
                    ("Column grid A-3 offset", "12mm from design", "FLAG"),
                    ("Slab elevation L4", "Within tolerance", "PASS"),
                    ("MEP penetration B-7", "8mm shift detected", "REVIEW"),
                ]
                ForEach(deviations, id: \.0) { d in
                    HStack(spacing: 6) {
                        Image(systemName: d.2 == "PASS" ? "checkmark.circle.fill" : d.2 == "FLAG" ? "exclamationmark.triangle.fill" : "eye.fill")
                            .font(.system(size: 9)).foregroundColor(d.2 == "PASS" ? Theme.green : d.2 == "FLAG" ? Theme.red : Theme.gold)
                        Text(d.0).font(.system(size: 9)).foregroundColor(Theme.text)
                        Spacer()
                        Text(d.1).font(.system(size: 8)).foregroundColor(Theme.muted)
                        Text(d.2).font(.system(size: 7, weight: .black)).foregroundColor(d.2 == "PASS" ? Theme.green : d.2 == "FLAG" ? Theme.red : Theme.gold)
                    }
                }
            }.padding(10).background(Theme.surface).cornerRadius(8)
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }

    // MARK: - Sustainability

    private var sustainabilityView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SUSTAINABILITY & CARBON TRACKER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("847").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("TONS CO2e").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("-18%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("vs BASELINE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("LEED").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.gold); Text("GOLD TARGET").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
            }

            let materials: [(material: String, carbon: String, recycled: String, status: String)] = [
                ("Concrete (low-carbon)", "42 kg CO2e/CY", "35% SCM", "SPECIFIED"),
                ("Steel (EAF recycled)", "0.8 t CO2e/t", "92% recycled", "IN USE"),
                ("Mass Timber (CLT)", "Carbon negative", "FSC certified", "SPECIFIED"),
                ("Recycled Aggregate", "0.5 kg CO2e/CY", "100% recycled", "IN USE"),
                ("Low-VOC Coatings", "Minimal off-gas", "GreenGuard Gold", "APPROVED"),
            ]
            ForEach(materials, id: \.material) { m in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) { Text(m.material).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Text("\(m.carbon) \u{2022} \(m.recycled)").font(.system(size: 8)).foregroundColor(Theme.muted) }
                    Spacer()
                    Text(m.status).font(.system(size: 7, weight: .black)).foregroundColor(Theme.green)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }

            let energy: [(String, String, String)] = [
                ("Solar array (rooftop)", "240 kW installed", "GENERATING"),
                ("EV charging stations", "12 Level 2 + 2 DC Fast", "OPERATIONAL"),
                ("Rainwater harvesting", "15,000 gal capacity", "ACTIVE"),
                ("Smart HVAC controls", "AI-optimized scheduling", "LEARNING"),
            ]
            VStack(alignment: .leading, spacing: 6) {
                Text("ENERGY & WATER SYSTEMS").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.cyan)
                ForEach(energy, id: \.0) { e in
                    HStack(spacing: 6) {
                        Circle().fill(Theme.green).frame(width: 5, height: 5)
                        Text(e.0).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text)
                        Spacer()
                        Text(e.1).font(.system(size: 8)).foregroundColor(Theme.muted)
                        Text(e.2).font(.system(size: 7, weight: .black)).foregroundColor(Theme.green)
                    }
                }
            }.padding(10).background(Theme.surface).cornerRadius(8)
        }
        .padding(14).background(Theme.surface).cornerRadius(12).premiumGlow(cornerRadius: 12, color: Theme.green)
    }

    // MARK: - Wearables

    private var wearablesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WEARABLE SAFETY TECHNOLOGY").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.red)

            let devices: [(worker: String, device: String, heartRate: Int, temp: Double, fatigue: String, location: String, alert: String?)] = [
                ("Mike Torres", "Smart Hardhat + Vest", 82, 98.2, "LOW", "Grid A-4, L3", nil),
                ("Sarah Kim", "Smart Watch + Gas Monitor", 94, 98.8, "MODERATE", "Electrical Room B", nil),
                ("James Wright", "Smart Hardhat", 76, 97.9, "LOW", "Grid C-2, L1", nil),
                ("Carlos Mendez", "Smart Vest + Proximity", 108, 99.4, "HIGH", "Crane Zone", "HEAT STRESS"),
                ("Andre Williams", "Smart Hardhat + Fall Det", 88, 98.5, "LOW", "Scaffold L4", nil),
            ]

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("\(devices.count)").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("CONNECTED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("\(devices.filter { $0.alert != nil }.count)").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.red); Text("ALERTS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.red.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("0").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("INCIDENTS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
            }

            ForEach(devices, id: \.worker) { d in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(d.worker).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                        Spacer()
                        if let alert = d.alert {
                            Text(alert).font(.system(size: 7, weight: .black)).foregroundColor(.black)
                                .padding(.horizontal, 6).padding(.vertical, 2).background(Theme.red).cornerRadius(3)
                        }
                    }
                    HStack(spacing: 12) {
                        HStack(spacing: 3) { Image(systemName: "heart.fill").font(.system(size: 8)).foregroundColor(d.heartRate > 100 ? Theme.red : Theme.green); Text("\(d.heartRate) BPM").font(.system(size: 8, weight: .bold)).foregroundColor(d.heartRate > 100 ? Theme.red : Theme.text) }
                        HStack(spacing: 3) { Image(systemName: "thermometer").font(.system(size: 8)).foregroundColor(d.temp > 99 ? Theme.gold : Theme.text); Text("\(String(format: "%.1f", d.temp))\u{00B0}F").font(.system(size: 8)).foregroundColor(Theme.text) }
                        Text("Fatigue: \(d.fatigue)").font(.system(size: 8, weight: .bold)).foregroundColor(d.fatigue == "HIGH" ? Theme.red : d.fatigue == "MODERATE" ? Theme.gold : Theme.green)
                        Spacer()
                        Text(d.location).font(.system(size: 7)).foregroundColor(Theme.muted)
                    }
                }.padding(10).background(d.alert != nil ? Theme.red.opacity(0.04) : Theme.surface).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }

    // MARK: - Modular

    private var modularView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MODULAR & PREFAB CONSTRUCTION").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)

            let modules: [(name: String, factory: String, size: String, weight: String, ship: String, status: String, complete: Int)] = [
                ("Bathroom Pod A1-A12", "ModularCraft TX", "8x10x9 ft", "4,200 lb", "Mar 28", "IN TRANSIT", 100),
                ("MEP Rack Assembly L3", "PrefabTech GA", "4x12x10 ft", "2,800 lb", "Apr 2", "FABRICATING", 72),
                ("Exterior Wall Panel N1-N8", "PanelWorks FL", "10x30 ft", "6,500 lb", "Apr 8", "FABRICATING", 45),
                ("Headwall Units ICU", "MedModular CA", "6x8x9 ft", "3,100 lb", "Apr 15", "DESIGN", 20),
            ]

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("\(modules.count)").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.gold); Text("MODULES").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("32%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("WASTE REDUCED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("40%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("TIME SAVED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
            }

            ForEach(modules, id: \.name) { mod in
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text(mod.name).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text("\(mod.complete)%").font(.system(size: 12, weight: .heavy)).foregroundColor(mod.complete == 100 ? Theme.green : Theme.accent) }
                    GeometryReader { geo in ZStack(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(Theme.border.opacity(0.3)).frame(height: 4); RoundedRectangle(cornerRadius: 2).fill(mod.complete == 100 ? Theme.green : Theme.accent).frame(width: geo.size.width * CGFloat(mod.complete) / 100, height: 4) } }.frame(height: 4)
                    HStack(spacing: 10) {
                        Text(mod.factory).font(.system(size: 8)).foregroundColor(Theme.muted)
                        Text(mod.size).font(.system(size: 8)).foregroundColor(Theme.cyan)
                        Text(mod.weight).font(.system(size: 8)).foregroundColor(Theme.muted)
                        Spacer()
                        Text("Ship: \(mod.ship)").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold)
                        Text(mod.status).font(.system(size: 7, weight: .black)).foregroundColor(mod.status == "IN TRANSIT" ? Theme.cyan : mod.status == "FABRICATING" ? Theme.gold : Theme.muted)
                    }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }

    // MARK: - 5G / IoT Connectivity

    private var connectivityView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("5G & IoT SITE CONNECTIVITY").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("5G").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("NETWORK").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("1.2 Gbps").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.green); Text("THROUGHPUT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("8ms").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("LATENCY").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
            }

            let nodes: [(name: String, type: String, status: String, data: String)] = [
                ("5G Small Cell - Tower N", "T-Mobile Private 5G", "ACTIVE", "1.2 Gbps / 8ms"),
                ("5G Small Cell - Yard", "T-Mobile Private 5G", "ACTIVE", "980 Mbps / 12ms"),
                ("WiFi 6E Mesh - L1-L5", "Cisco Meraki", "ACTIVE", "2.4 Gbps aggregate"),
                ("LoRaWAN Gateway", "IoT Sensor Network", "ACTIVE", "847 sensors connected"),
                ("Starlink Terminal", "Backup Satellite", "STANDBY", "150 Mbps / 40ms"),
                ("CBRS Private LTE", "On-site coverage", "ACTIVE", "450 Mbps / 15ms"),
            ]

            ForEach(nodes, id: \.name) { node in
                HStack(spacing: 8) {
                    Circle().fill(node.status == "ACTIVE" ? Theme.green : Theme.gold).frame(width: 6, height: 6)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(node.name).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                        Text(node.type).font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text(node.data).font(.system(size: 8, weight: .semibold)).foregroundColor(Theme.cyan)
                    Text(node.status).font(.system(size: 7, weight: .black)).foregroundColor(node.status == "ACTIVE" ? Theme.green : Theme.gold)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CONNECTED EQUIPMENT").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.purple)
                let equipment: [(String, String, String)] = [
                    ("Excavator CAT 320", "GPS + Telematics", "Real-time grade control"),
                    ("Tower Crane #1", "Anti-collision + Load", "Wind speed monitoring"),
                    ("Concrete Pump", "Flow rate + PSI", "Volume tracking"),
                    ("3 Drones (DJI M350)", "RTK + LiDAR", "Autonomous flight paths"),
                ]
                ForEach(equipment, id: \.0) { eq in
                    HStack(spacing: 6) {
                        Image(systemName: "wifi").font(.system(size: 8)).foregroundColor(Theme.cyan)
                        Text(eq.0).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text)
                        Spacer()
                        Text(eq.1).font(.system(size: 8)).foregroundColor(Theme.muted)
                        Text(eq.2).font(.system(size: 7)).foregroundColor(Theme.cyan)
                    }
                }
            }.padding(10).background(Theme.surface).cornerRadius(8)
        }
        .padding(14).background(Theme.surface).cornerRadius(12).premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }
}
