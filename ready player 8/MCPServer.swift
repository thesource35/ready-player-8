import Foundation
import SwiftUI
import Combine

// MARK: - ========== MCP Server (Model Context Protocol) ==========

/// Local MCP tool server that gives Angelic AI access to live app data.
/// Implements tool definitions and execution per the Anthropic tool_use spec.

@MainActor
final class MCPToolServer: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = MCPToolServer()

    // MARK: - Tool Definitions (sent to Claude in API call)

    var toolDefinitions: [[String: Any]] {
        [
            toolDef("get_projects", "Get all active construction projects with status, progress, budget, and team assignments", [:]),
            toolDef("get_contracts", "Get all contracts in the bid pipeline with stage, budget, bid due dates, and scores", [:]),
            toolDef("get_site_status", "Get live site status for all active jobsites including risk scores, weather holds, and crew deployment", [:]),
            toolDef("get_crew_deploy", "Get current crew deployment across all sites with headcount, trade, and status (ACTIVE/HOLD/DELAYED)", [:]),
            toolDef("get_inspections", "Get upcoming and overdue inspections with permit status and due dates", [:]),
            toolDef("get_weather", "Get weather forecast with construction risk flags (concrete pour holds, wind advisories, slip hazards)", [:]),
            toolDef("get_change_orders", "Get all change orders with status, amounts, and approval state", [:]),
            toolDef("get_safety_incidents", "Get recent safety incidents with type, severity, and corrective actions", [:]),
            toolDef("get_rfis", "Get open RFIs with priority, age, and assignment status", [:]),
            toolDef("get_rental_inventory", "Search construction equipment rentals by category or keyword", [
                "query": ["type": "string", "description": "Search term (e.g. 'excavator', 'concrete', 'crane')"],
                "category": ["type": "string", "description": "Category filter (e.g. 'Heavy Equipment', 'Hand & Power Tools')"]
            ]),
            toolDef("get_rental_rates", "Get market rental rates and pricing trends for equipment categories", [:]),
            toolDef("get_budget_summary", "Get budget health across all projects with spend vs. budget and burn rates", [:]),
            toolDef("get_subcontractor_scores", "Get subcontractor performance scorecards with ratings and payment status", [:]),
            toolDef("get_daily_costs", "Get daily cost tracking entries for all active sites", [:]),
            toolDef("get_material_deliveries", "Get material delivery status and tracking for all pending orders", [:]),
            toolDef("get_punch_list", "Get open punch list items across all sites with priority and status", [:]),
            toolDef("calculate_rental_cost", "Calculate total rental cost for equipment", [
                "equipment": ["type": "string", "description": "Equipment name"],
                "daily_rate": ["type": "number", "description": "Daily rental rate in dollars"],
                "days": ["type": "integer", "description": "Number of rental days"],
                "quantity": ["type": "integer", "description": "Number of units"]
            ]),
            // New MCP tools for all features
            toolDef("get_punch_list_status", "Get mobile punch list status with open, critical, and resolved counts", [:]),
            toolDef("estimate_roof", "Estimate roofing cost from satellite-measured area and material selection", [
                "area": ["type": "string", "description": "Roof area in square feet"],
                "material": ["type": "string", "description": "Roofing material (Asphalt Shingle, Metal Standing Seam, TPO, etc.)"]
            ]),
            toolDef("get_concrete_test_status", "Get smart concrete testing status with IoT sensor data and AI strength predictions", [:]),
            toolDef("get_bim_status", "Get BIM model status including LOD level, element counts, and clash detection", [:]),
            toolDef("get_net_zero_status", "Get net zero building design status with carbon tracking and low-carbon materials", [:]),
            toolDef("search_contractors", "Search the global contractor directory by trade and country", [
                "trade": ["type": "string", "description": "Contractor trade (e.g. 'electrical', 'concrete', 'roofing')"],
                "country": ["type": "string", "description": "Country filter (e.g. 'USA', 'Canada', 'Japan')"]
            ]),
            toolDef("get_wearable_safety", "Get wearable safety device status with biometrics and alerts for all workers", [:]),
            toolDef("get_robotics_fleet", "Get autonomous robotics fleet status with operating machines and productivity", [:]),
            toolDef("get_digital_twin_status", "Get digital twin sync status with IoT sensors, layers, and clash detection", [:]),
            toolDef("get_modular_status", "Get modular and digital component construction status with fabrication progress", [:]),
            // Advanced MCP tools for every remaining feature
            toolDef("get_timecards", "Get crew timecard data with hours, overtime, labor costs by site", [:]),
            toolDef("get_equipment_gps", "Get GPS locations and status for all tracked equipment assets", [:]),
            toolDef("get_permits", "Get all active and expiring permits across jobsites", [:]),
            toolDef("get_tax_summary", "Get tax expense summary with deductions, categories, and estimated savings", [:]),
            toolDef("get_electrical_contractors", "Get electrical and fiber contractor directory with certifications and availability", [:]),
            toolDef("get_fiber_projects", "Get fiber optic installation project status with splice counts and test results", [:]),
            toolDef("get_cash_flow", "Get cash flow forecast with AR/AP by month and net position", [:]),
            toolDef("get_invoices", "Get AIA G702/G703 pay application status with retainage tracking", [:]),
            toolDef("get_lien_waivers", "Get lien waiver status for all subcontractors with deadlines", [:]),
            toolDef("get_compliance_status", "Get compliance dashboard: toolbox talks, certified payroll, environmental", [:]),
            toolDef("get_client_portal", "Get client-facing project status with selections, warranty, and meeting data", [:]),
            toolDef("get_bid_analytics", "Get bid win/loss analytics with sector breakdown, pipeline value, and markup", [:]),
            toolDef("get_labor_productivity", "Get labor productivity metrics by trade with benchmarks and trends", [:]),
            toolDef("get_risk_ai_scores", "Get AI risk scores for all projects with factors and predictions", [:]),
            toolDef("get_fuel_log", "Get fuel purchase log with gallons, costs, and vehicle tracking", [:]),
            toolDef("get_training_certs", "Get workforce certification status with expiring and expired alerts", [:]),
            toolDef("get_crew_schedule", "Get weekly crew scheduling calendar with site assignments", [:]),
            toolDef("get_gantt_timeline", "Get project Gantt chart with milestones, critical path, and percent complete", [:]),
            toolDef("get_cost_codes", "Get CSI MasterFormat cost code breakdown with budget vs. actual", [:]),
            toolDef("calculate_material_takeoff", "Calculate material quantities from dimensions", [
                "material": ["type": "string", "description": "Material type (concrete, drywall, lumber, rebar, paint)"],
                "length": ["type": "string", "description": "Length in feet"],
                "width": ["type": "string", "description": "Width in feet"]
            ]),
            toolDef("get_3d_scan_status", "Get 3D laser scan status with point counts, accuracy, and BIM deviations", [:]),
            toolDef("get_carbon_tracker", "Get sustainability carbon footprint tracking with material savings", [:]),
            toolDef("get_5g_connectivity", "Get 5G and IoT site connectivity status with throughput and latency", [:]),
            toolDef("get_auto_home_tech", "Get automated home building technology status and production metrics", [:]),
            toolDef("get_geofence_zones", "Get geofence zone status with crew counts inside each jobsite boundary", [:]),
            toolDef("get_rental_favorites", "Get user's saved favorite rental equipment items", [:]),
            toolDef("get_price_alerts", "Get active price alert watchlist for rental equipment", [:]),
            toolDef("get_provider_accounts", "Get linked rental provider account status and spend data", [:]),
        ]
    }

    private func toolDef(_ name: String, _ description: String, _ properties: [String: [String: String]]) -> [String: Any] {
        var schema: [String: Any] = ["type": "object", "properties": properties]
        if !properties.isEmpty {
            schema["required"] = Array(properties.keys)
        }
        return [
            "name": name,
            "description": description,
            "input_schema": schema
        ]
    }

    // MARK: - Tool Execution

    func executeTool(name: String, input: [String: Any]) -> String {
        switch name {
        case "get_projects":
            return mockProjects.map { "\($0.name) | Client: \($0.client) | Status: \($0.status) | Progress: \($0.progress)% | Budget: \($0.budget) | Score: \($0.score)" }.joined(separator: "\n")

        case "get_contracts":
            return mockContracts.map { "\($0.title) | Client: \($0.client) | Stage: \($0.stage) | Budget: \($0.budget) | Bid Due: \($0.bidDue) | Score: \($0.score) | Bidders: \($0.bidders)" }.joined(separator: "\n")

        case "get_site_status":
            return """
            Riverside Lofts | DELAYED | Risk: 95 | Concrete crew on HOLD (rain)
            Site Gamma | AT RISK | Risk: 65 | Steel delivery delayed
            Pine Ridge Ph.2 | AT RISK | Risk: 55 | Framing inspection 1d overdue
            Harbor Crossing | ON TRACK | Risk: 10 | MEP active
            Eastside Civic Hub | ON TRACK | Risk: 15 | Permit pending
            """

        case "get_crew_deploy":
            return """
            Riverside Lofts | Concrete | 14 workers | HOLD
            Site Gamma | Steel | 8 workers | DELAYED
            Harbor Crossing | MEP | 22 workers | ACTIVE
            Pine Ridge Ph.2 | Framing | 11 workers | ACTIVE
            Eastside Civic Hub | Finishes | 6 workers | STANDBY
            Total: 61 workers across 5 sites
            """

        case "get_inspections":
            return """
            Riverside Lofts | Foundation Inspection | DUE TODAY | Permit: PENDING
            Site Gamma | Steel Frame Inspection | Due in 2d | Permit: APPROVED
            Harbor Crossing | MEP Rough-in | Due in 5d | Permit: APPROVED
            Pine Ridge Ph.2 | Framing Inspection | 1d OVERDUE | Permit: FLAGGED
            Eastside Civic Hub | Building Permit | Due in 9d | Permit: PENDING
            """

        case "get_weather":
            return """
            TODAY: Heavy Rain | High 54°F / Low 41°F | CONCRETE POUR HOLD | SLIP HAZARD
            TOMORROW: Partly Cloudy | High 61°F / Low 44°F | WIND ADVISORY
            DAY 3: Clear | High 68°F / Low 50°F | No risk flags
            """

        case "get_change_orders":
            return "CO-001 | Foundation depth increase | $42,000 | PENDING owner approval\nCO-002 | Added fire stops | $18,500 | APPROVED\nCO-003 | Revised MEP routing | $27,300 | PENDING"

        case "get_safety_incidents":
            return "INC-03-14 | Near Miss | Scaffold harness | Grid B-7 | Corrective action OPEN\nINC-03-10 | First Aid | Minor laceration | Site Gamma | CLOSED"

        case "get_rfis":
            return "RFI-001 | Structural steel connection detail | HIGH | 12 days open | Assigned: Engineering\nRFI-002 | MEP coordination conflict at grid C-4 | MED | 8 days open | PENDING\nRFI-003 | Exterior cladding attachment spec | LOW | 3 days open | OPEN"

        case "get_rental_inventory":
            let query = (input["query"] as? String ?? "").lowercased()
            let category = (input["category"] as? String ?? "").lowercased()
            let items = rentalInventory.filter { item in
                (query.isEmpty || item.name.lowercased().contains(query) || item.specs.lowercased().contains(query)) &&
                (category.isEmpty || item.category.rawValue.lowercased().contains(category))
            }.prefix(10)
            if items.isEmpty { return "No equipment found matching query." }
            return items.map { "\($0.name) | \($0.category.rawValue) | \($0.dailyRate)/day | \($0.weeklyRate)/week | \($0.provider.rawValue) | \($0.availability)" }.joined(separator: "\n")

        case "get_rental_rates":
            return """
            Excavators: avg $820/day (+5% trend, High demand)
            Dozers: avg $1,150/day (+3%, Medium demand)
            Boom Lifts: avg $340/day (-2%, Medium demand)
            Scissor Lifts: avg $145/day (+1%, High demand)
            Generators: avg $280/day (+8%, High demand)
            Cranes: avg $2,400/day (+4%, Low demand)
            Jackhammers: avg $72/day (flat, Medium demand)
            """

        case "get_budget_summary":
            return """
            Metro Tower Complex | Budget: $42.8M | Spent: $27.8M (65%) | On Track
            Harbor Industrial Park | Budget: $18.5M | Spent: $14.4M (78%) | Ahead
            Riverside Residential | Budget: $31.2M | Spent: $13.1M (42%) | On Track
            Portfolio Total: $92.5M budget, $55.3M spent (60%)
            """

        case "get_subcontractor_scores":
            return "Apex Concrete | Score: 92 | On-Time: 96% | Quality: 94% | Payment: CURRENT\nElite Steel | Score: 85 | On-Time: 88% | Quality: 90% | Payment: CURRENT\nPrime Electric | Score: 78 | On-Time: 82% | Quality: 85% | Payment: 30d OVERDUE"

        case "get_daily_costs":
            return "03-25: $48,200 (Labor: $31,400, Materials: $12,800, Equipment: $4,000)\n03-24: $52,100 (Labor: $33,600, Materials: $14,200, Equipment: $4,300)\n03-23: $44,800 (Labor: $29,100, Materials: $11,900, Equipment: $3,800)"

        case "get_material_deliveries":
            return """
            Structural Steel W8x31 | Nucor | PO-4411 | DELIVERED 03-15
            Concrete 4000 PSI | LaFarge | PO-4418 | ORDERED, due 03-18
            Electrical Conduit 3/4" EMT | Graybar | PO-4422 | DELAYED (ETA 03-20)
            Drywall 5/8" Type X | USG | PO-4430 | IN TRANSIT (ETA 4 hrs)
            """

        case "get_punch_list":
            return "Fire-stopping gaps at grid B-7 | HIGH | OPEN | Riverside Lofts\nDrywall finish touch-up L3 corridor | LOW | OPEN | Harbor Crossing\nMEP label missing at panel 2A | MED | IN PROGRESS | Pine Ridge"

        case "calculate_rental_cost":
            let rate = input["daily_rate"] as? Double ?? 0
            let days = input["days"] as? Int ?? 1
            let qty = input["quantity"] as? Int ?? 1
            let total = rate * Double(days) * Double(qty)
            let equipment = input["equipment"] as? String ?? "Equipment"
            return "\(equipment): $\(String(format: "%.0f", rate))/day x \(days) days x \(qty) units = $\(String(format: "%.0f", total)) total"

        // ========== NEW MCP TOOLS ==========

        case "get_punch_list_status":
            let store = PunchListStore.shared
            return "PUNCH LIST: \(store.openCount) open, \(store.criticalCount) critical, \(store.resolvedCount) resolved, \(store.items.count) total"

        case "estimate_roof":
            let area = Double(input["area"] as? String ?? "2400") ?? 2400
            let material = input["material"] as? String ?? "Asphalt Shingle"
            let rates: [String: Double] = ["Asphalt Shingle": 4.50, "Metal Standing Seam": 12.00, "TPO Membrane": 7.50, "Clay Tile": 15.00, "Slate": 22.00]
            let rate = rates[material] ?? 5.0
            let matCost = area * rate
            let labCost = area * rate * 0.6
            let total = matCost + labCost + (matCost * 0.12) + 550
            return "ROOF ESTIMATE: \(String(format: "%.0f", area)) SF \(material)\nMaterial: $\(String(format: "%.0f", matCost))\nLabor: $\(String(format: "%.0f", labCost))\nTotal: $\(String(format: "%.0f", total))"

        case "get_concrete_test_status":
            return "SMART CONCRETE: 12 active pours, 48 IoT sensors, 99.1% AI accuracy\nP-041 L3 Slab: 3,240/4,000 PSI (CURING, ETA 2.3 days)\nP-040 L2 Columns: 4,890/5,000 PSI (97.8%)\nP-039 Foundation: 4,120/4,000 PSI (PASSED)"

        case "get_bim_status":
            return "BIM CENTER: LOD 400, 2.4M elements, 0 clashes\n6 models: Architectural (Revit), Structural (Tekla), MEP (Revit MEP), Civil (Civil 3D), Landscape (Lumion), Federated (Navisworks)\nAll models CURRENT and SYNCED"

        case "get_net_zero_status":
            return "NET ZERO: -42% carbon vs baseline, EUI 22 kBtu/SF/yr\nLow-carbon concrete: 1,200 tons saved\nCLT: 2,800 tons stored\nSolar: 240 kW installed, EV: 12 L2 + 2 DC Fast\nLEED Gold target on track"

        case "search_contractors":
            let trade = (input["trade"] as? String ?? "").lowercased()
            let country = (input["country"] as? String ?? "").lowercased()
            let results = globalContractors.filter { c in
                (trade.isEmpty || c.trade.rawValue.lowercased().contains(trade)) &&
                (country.isEmpty || c.country.lowercased().contains(country))
            }.prefix(5)
            if results.isEmpty { return "No contractors found matching criteria" }
            return results.map { "\($0.company) | \($0.trade.rawValue) | \($0.location), \($0.country) | Rating: \($0.rating) | Revenue: \($0.revenue) | \($0.projectsCompleted) projects" }.joined(separator: "\n")

        case "get_wearable_safety":
            return "WEARABLE SAFETY: 5 connected, 1 ALERT (heat stress), 0 incidents\nCarlos Mendez: HR 108, Temp 99.4F, HEAT STRESS ALERT\nAll others: normal biometrics"

        case "get_robotics_fleet":
            return "ROBOTICS: 2 operating, 6 total fleet, 9,650 total hours\nTyBot R-3: rebar tying 1,400 ties/hr (OPERATING)\nSpot: 24/7 inspection patrol (PATROLLING)\nSAM-200: bricklaying (STANDBY)\nPrint3D-X: concrete 3D printing (CALIBRATING)"

        case "get_digital_twin_status":
            return "DIGITAL TWIN: 98.2% sync, 847 IoT sensors, 1.2s latency, 4 drone feeds\n7 layers active: Structural, MEP, Progress, Thermal, Drone, IoT, Earthwork\n3 clashes detected: 1 CRITICAL (HVAC vs beam), 1 MODERATE, 1 RESOLVED"

        case "get_modular_status":
            return "MODULAR: 86% prefab rate, 214 components, 47% time saved\nBathroom pods: DELIVERED\nWall panels: FABRICATING (45%)\nMEP racks: IN TRANSIT\nStair modules: DESIGN COMPLETE"

        case "get_timecards":
            return "TIMECARDS TODAY:\nMike Torres | Concrete | 6:00-2:30 | 8h + 0.5h OT | $383 | Riverside Lofts\nSarah Kim | Electrical | 7:00-5:30 | 8h + 2.5h OT | $646 | Harbor Crossing\nJames Wright | Framing | 6:30-3:00 | 8h | $336 | Pine Ridge Ph.2\nTOTAL: 27 hrs (3 OT) | $1,365 labor cost"

        case "get_equipment_gps":
            return "EQUIPMENT GPS:\nCAT 320 Excavator (EQ-001) | Riverside Lofts | ACTIVE | 2,340 hrs | Svc in 50 hrs\nJLG 600S Boom (EQ-014) | Harbor Crossing | ACTIVE | 890 hrs\nBobcat S770 (EQ-008) | Pine Ridge | SERVICE DUE | 1,560 hrs\nWacker Compactor (EQ-022) | Yard | IDLE | 420 hrs"

        case "get_permits":
            return "PERMITS:\nBP-2026-4821 | Building | City of Houston | Riverside Lofts | ACTIVE (exp 01/15/27)\nEP-2026-1193 | Electrical | Harris County | Harbor Crossing | ACTIVE (exp 08/01/26)\nGP-2026-0782 | Grading | City of Houston | Pine Ridge | EXPIRING (exp 06/01/26)"

        case "get_tax_summary":
            return "TAX SUMMARY:\n12 expense categories tracked\nTotal Expenses: $0 (add expenses in Tax tab)\nDeductible: $0\nEstimated Tax Savings (30%): $0\nKey Deductions: Section 179, Vehicle Mileage ($0.67/mi), Home Office, Equipment Depreciation\nQuarterly Estimates: Q1 $12,900, Q2 $15,600, Q3 $13,800, Q4 $12,900"

        case "get_electrical_contractors":
            return "ELECTRICAL & FIBER CONTRACTORS:\nMarcus Johnson | PowerGrid Electric | Master Electrician | $95/hr | 4.9 rating | Houston TX | AVAILABLE\nSarah Chen | FiberLink Solutions | BICSI RCDD | $110/hr | 4.8 | Bay Area | AVAILABLE\nPriya Patel | LightSpeed Fiber | BICSI TECH | $105/hr | 4.9 | NYC Metro | AVAILABLE\nDerek Torres | SunVolt Energy | NABCEP PV | $85/hr | 4.8 | Phoenix | AVAILABLE\n+ 4 more contractors"

        case "get_fiber_projects":
            return "FIBER PROJECTS:\nDowntown Office FTTH | AT&T Fiber | OS2 | 2,400 ft | 48 splices | OTDR Pass | 72%\nMetro Campus Backbone | Spectrum | OM4 | 8,200 ft | 192 splices | Pending | 45%\nIndustrial Park 5G | Verizon | OS2 | 14,800 ft | 384 splices | N/A | 15% (permitting)"

        case "get_cash_flow":
            return "CASH FLOW FORECAST:\nApr: AR $485K - AP $342K = +$143K\nMay: AR $520K - AP $398K = +$122K\nJun: AR $610K - AP $445K = +$165K\nJul: AR $475K - AP $380K = +$95K\nNet position: positive all quarters"

        case "get_invoices":
            return "AIA PAY APPLICATIONS:\n#07 | Riverside Lofts | Mar 2026 | $284,500 | Ret: $28,450 | SUBMITTED\n#06 | Riverside Lofts | Feb 2026 | $312,100 | Ret: $31,210 | APPROVED\n#04 | Harbor Crossing | Mar 2026 | $198,750 | Ret: $19,875 | DRAFT\n#12 | Pine Ridge Ph.2 | Mar 2026 | $156,200 | Ret: $15,620 | PAID\nTotal Billed: $952K | Retainage: $95K"

        case "get_lien_waivers":
            return "LIEN WAIVERS:\nApex Concrete | Conditional Progress | $48,200 | RECEIVED | Due Apr 1\nElite Steel | Conditional Progress | $32,100 | PENDING | Due Apr 1\nPrime Electric | Unconditional | $15,800 | RECEIVED\nQuick Plumbing | Conditional Final | $22,400 | REQUESTED | Due Apr 15"

        case "get_compliance_status":
            return "COMPLIANCE:\nToolbox Talks: 8 topics, 5 required (Fall Protection, Trenching, Electrical, Scaffold, Silica)\nCertified Payroll: Week 12 SUBMITTED (38 employees, $98,400)\nEnvironmental: SWPPP CURRENT, Dust monitoring CURRENT, Noise compliance DUE, EPA permit ACTIVE"

        case "get_client_portal":
            return "CLIENT PORTAL:\nProject Status: 3 projects visible to owners\nSelections: 5 items (3 PENDING, 2 APPROVED) - countertops, flooring, paint, fixtures, hardware\nWarranty: 6 items tracked (Roof 20yr, HVAC 10yr, Windows 10yr, Elevator 5yr)\nMeetings: 3 OAC meetings logged, 15 action items, 6 open"

        case "get_bid_analytics":
            return "BID ANALYTICS:\nWin Rate: 68% | Bids YTD: 47 | Pipeline: $142M | Avg Markup: 12.4%\nBy Sector: Commercial 72%, Healthcare 75%, Industrial 57%, Residential 78%, Infrastructure 40%"

        case "get_labor_productivity":
            return "LABOR PRODUCTIVITY:\nConcrete: 2.8 CY/hr (benchmark 2.5, +12%)\nFraming: 14.2 SF/hr (benchmark 12.0, +18%)\nElectrical: 3.1 dev/hr (benchmark 3.5, -11%)\nDrywall: 22.5 SF/hr (benchmark 20.0, +13%)\nPlumbing: 1.8 fix/hr (benchmark 2.0, -10%)"

        case "get_risk_ai_scores":
            return "AI RISK SCORES:\nRiverside Lofts: 92/100 HIGH RISK - weather delays, sub default risk, permit pending\nHarbor Crossing: 34/100 LOW RISK - on-time, strong subs\nPine Ridge Ph.2: 67/100 MODERATE - inspection backlog, labor shortage, material price volatility"

        case "get_fuel_log":
            return "FUEL LOG:\n03/25: F-350 #12 | 32.4 gal | $3.45/gal | $112 | Riverside Lofts\n03/24: Excavator EQ-001 | 45.0 gal | $3.89/gal | $175 | Riverside Lofts\n03/24: F-250 #08 | 28.1 gal | $3.42/gal | $96 | Harbor Crossing\nTotal: 143.5 gal | $479 (tax deductible)"

        case "get_training_certs":
            return "CERTIFICATIONS:\n8 total | 6 CURRENT | 1 EXPIRING | 1 EXPIRED\nEXPIRING: Sarah Kim - Master Electrician (exp 06/01/26)\nEXPIRED: Andre Williams - Forklift Operator (exp 11/01/25)\nAll OSHA cards current. NCCCO, BICSI, NABCEP active."

        case "get_crew_schedule":
            return "CREW SCHEDULE (This Week):\nAlpha (Concrete): RSL Mon-Wed, HBC Thu-Fri\nBravo (Steel): HBC Mon-Sat\nCharlie (Electrical): PRP Mon-Tue, RSL Wed-Thu, PRP Fri\nDelta (Framing): PRP Mon-Fri\nEcho (MEP): HBC Mon-Tue, ECH Wed-Thu, HBC Fri"

        case "get_gantt_timeline":
            return "GANTT TIMELINE (26 weeks):\n1. Site Prep (W1-3) 100% DONE\n2. Foundation (W4-7) 100% DONE\n3. Structural Steel (W8-13) 75% CRITICAL PATH\n4. Rough Plumbing (W10-13) 60%\n5. Electrical Rough-in (W11-15) 45%\n6. HVAC Ductwork (W12-15) 30%\n7. Exterior Envelope (W14-18) 10% CRITICAL\n8. Drywall (W16-19) 0%\n9. Finishes (W20-22) 0%\n10. Commissioning (W23-24) 0%"

        case "get_cost_codes":
            return "CSI COST CODES:\n03 00 00 Concrete: $312K / $485K budget (64%)\n05 00 00 Metals: $465K / $620K (75%)\n06 00 00 Wood: $95K / $180K (53%)\n09 00 00 Finishes: $48K / $340K (14%)\n22 00 00 Plumbing: $165K / $275K (60%)\n23 00 00 HVAC: $198K / $410K (48%)\n26 00 00 Electrical: $210K / $385K (55%)\n31 00 00 Earthwork: $118K / $125K (94%)"

        case "calculate_material_takeoff":
            let mat = (input["material"] as? String ?? "concrete").lowercased()
            let l = Double(input["length"] as? String ?? "0") ?? 0
            let w = Double(input["width"] as? String ?? "0") ?? 0
            let area = l * w
            switch mat {
            case "concrete": return "TAKEOFF: \(String(format: "%.0f", area)) SF slab at 4\" = \(String(format: "%.1f", area * 4/12/27)) CY (+10% waste = \(String(format: "%.1f", area * 4/12/27 * 1.1)) CY)"
            case "drywall": return "TAKEOFF: \(String(format: "%.0f", area)) SF = \(Int(ceil(area / 32))) sheets 4x8 (+10% = \(Int(ceil(area / 32 * 1.1))))"
            case "lumber": return "TAKEOFF: \(String(format: "%.0f", l)) LF wall = \(Int(ceil(l / 1.333))) studs @ 16\" OC"
            case "paint": return "TAKEOFF: \(String(format: "%.0f", area)) SF = \(String(format: "%.1f", area / 350)) gallons (1 coat @ 350 SF/gal)"
            default: return "TAKEOFF: \(String(format: "%.0f", area)) SF of \(mat)"
            }

        case "get_3d_scan_status":
            return "3D LASER SCANS:\n173M total points | 99.2% BIM match\nRiverside L3 | Leica RTC360 | 42M pts | +/-1.9mm | PROCESSED\nHarbor Ext | Faro Focus S350 | 68M pts | +/-1.0mm | PROCESSING\nPine Ridge Foundation | Trimble X7 | 28M pts | +/-2.4mm | COMPLETE\nDeviations: Column A-3 offset 12mm (FLAG), Slab L4 within tolerance (PASS)"

        case "get_carbon_tracker":
            return "CARBON TRACKER:\n847 tons CO2e total | -18% vs baseline | LEED Gold target\nLow-carbon concrete: -1,200 tons\nCLT structure: -2,800 tons stored\nRecycled steel: -890 tons\nSolar: 240 kW generating\nEV stations: 14 installed\nRainwater: 15,000 gal capacity"

        case "get_5g_connectivity":
            return "5G/IoT CONNECTIVITY:\nT-Mobile Private 5G: 1.2 Gbps / 8ms | 2 small cells ACTIVE\nWiFi 6E Mesh: 2.4 Gbps aggregate | L1-L5 coverage\nLoRaWAN: 847 IoT sensors connected\nStarlink: 150 Mbps backup (STANDBY)\nConnected: Excavator GPS, Tower crane anti-collision, Concrete pump flow, 3 drones RTK"

        case "get_auto_home_tech":
            return "AUTO HOME TECH:\n3D Concrete Printing: 600 SF/day, $120/SF (PRODUCTION)\nRobotic Framing: 1 floor/day, $85/SF (BETA)\nAutomated Bricklaying: 2,000 SF/day, $95/SF (PRODUCTION)\nDrone Roofing: 2,400 SF/day, $8/SF (PILOT)\nAI HVAC: 15% energy savings (PRODUCTION)\nSelf-Healing Concrete: lifetime auto-repair (RESEARCH)"

        case "get_geofence_zones":
            return "GEOFENCE ZONES:\nRiverside Lofts | 500 ft radius | ACTIVE | 14 crew inside\nHarbor Crossing | 400 ft radius | ACTIVE | 22 crew inside\nPine Ridge Ph.2 | 600 ft radius | ACTIVE | 11 crew inside\nEastside Civic | 350 ft radius | PAUSED | 0 crew"

        case "get_rental_favorites":
            let store = RentalDataStore.shared
            if store.favorites.isEmpty { return "No favorite equipment saved yet" }
            return "FAVORITES (\(store.favorites.count)):\n" + store.favorites.prefix(5).map { "\($0.itemName) | \($0.provider) | \($0.dailyRate)/day" }.joined(separator: "\n")

        case "get_price_alerts":
            let store = RentalDataStore.shared
            if store.priceAlerts.isEmpty { return "No price alerts set" }
            return "PRICE ALERTS (\(store.priceAlerts.count)):\n" + store.priceAlerts.prefix(5).map { "\($0.itemName) | Target: $\(String(format: "%.0f", $0.targetDailyRate))/day | \($0.triggered ? "TRIGGERED" : "WATCHING")" }.joined(separator: "\n")

        case "get_provider_accounts":
            let mgr = RentalProviderManager.shared
            if mgr.accounts.isEmpty { return "No provider accounts linked. Connect in Rentals > Providers." }
            return "LINKED ACCOUNTS (\(mgr.accounts.count)):\n" + mgr.accounts.values.map { "\($0.provider) | \($0.accountNumber) | \($0.tier) | Active: \($0.activeRentals) | Spent: \($0.totalSpent) | \($0.isVerified ? "VERIFIED" : "UNVERIFIED")" }.joined(separator: "\n")

        default:
            return "Unknown tool: \(name)"
        }
    }
}
