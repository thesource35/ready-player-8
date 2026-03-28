import Foundation
import SwiftUI
import Combine

// MARK: - ========== MCP Server (Model Context Protocol) ==========

/// Local MCP tool server that gives Angelic AI access to live app data.
/// Implements tool definitions and execution per the Anthropic tool_use spec.

@MainActor
final class MCPToolServer: ObservableObject {
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

        default:
            return "Unknown tool: \(name)"
        }
    }
}
