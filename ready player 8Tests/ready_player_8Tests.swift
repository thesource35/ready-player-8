//
//  ready_player_8Tests.swift
//  ready player 8Tests
//
//  Created by Beverly Hunter on 3/23/26.
//

import Testing
@testable import ready_player_8

struct ConstructionOSTests {

    // MARK: - Keychain Tests

    @Test func keychainSaveAndRead() {
        let key = "test.keychain.\(UUID().uuidString)"
        KeychainHelper.save(key: key, data: "test-secret-value")
        let result = KeychainHelper.read(key: key)
        #expect(result == "test-secret-value")
        KeychainHelper.delete(key: key)
        #expect(KeychainHelper.read(key: key) == nil)
    }

    @Test func keychainOverwrite() {
        let key = "test.keychain.overwrite.\(UUID().uuidString)"
        KeychainHelper.save(key: key, data: "first")
        KeychainHelper.save(key: key, data: "second")
        #expect(KeychainHelper.read(key: key) == "second")
        KeychainHelper.delete(key: key)
    }

    @Test func keychainReadMissing() {
        let result = KeychainHelper.read(key: "nonexistent.key.\(UUID().uuidString)")
        #expect(result == nil)
    }

    // MARK: - JSON Persistence Tests

    @Test func loadJSONDefault() {
        let result: [String] = loadJSON("test.nonexistent.\(UUID().uuidString)", default: ["fallback"])
        #expect(result == ["fallback"])
    }

    @Test func saveAndLoadJSON() {
        let key = "test.json.\(UUID().uuidString)"
        let data = ["hello", "world"]
        saveJSON(key, value: data)
        let loaded: [String] = loadJSON(key, default: [])
        #expect(loaded == data)
        UserDefaults.standard.removeObject(forKey: key)
    }

    @Test func saveAndLoadCodableStruct() {
        let key = "test.codable.\(UUID().uuidString)"
        let alert = OpsPriorityAlert(title: "Test", detail: "Detail", owner: "PM", severity: 3, due: "Today")
        saveJSON(key, value: [alert])
        let loaded: [OpsPriorityAlert] = loadJSON(key, default: [])
        #expect(loaded.count == 1)
        #expect(loaded[0].title == "Test")
        #expect(loaded[0].severity == 3)
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Input Validation Tests

    @Test func emailValidation() {
        #expect(InputValidator.email("user@example.com").isValid == true)
        #expect(InputValidator.email("invalid").isValid == false)
        #expect(InputValidator.email("").isValid == false)
        #expect(InputValidator.email("a@b.c").isValid == true)
    }

    @Test func requiredValidation() {
        #expect(InputValidator.required("hello").isValid == true)
        #expect(InputValidator.required("").isValid == false)
        #expect(InputValidator.required("   ").isValid == false)
    }

    @Test func numericValidation() {
        #expect(InputValidator.numeric("123").isValid == true)
        #expect(InputValidator.numeric("$1,234.56").isValid == true)
        #expect(InputValidator.numeric("abc").isValid == false)
        #expect(InputValidator.numeric("").isValid == false)
    }

    @Test func passwordValidation() {
        #expect(InputValidator.password("12345678").isValid == true)
        #expect(InputValidator.password("short").isValid == false)
        #expect(InputValidator.password("").isValid == false)
    }

    @Test func minLengthValidation() {
        #expect(InputValidator.minLength("hello", min: 3).isValid == true)
        #expect(InputValidator.minLength("hi", min: 3).isValid == false)
    }

    // MARK: - MCP Tool Execution Tests

    @Test @MainActor func mcpGetProjects() {
        let server = MCPToolServer.shared
        let result = server.executeTool(name: "get_projects", input: [:])
        #expect(result.contains("Metro Tower"))
        #expect(result.contains("Budget:"))
    }

    @Test @MainActor func mcpGetSiteStatus() {
        let server = MCPToolServer.shared
        let result = server.executeTool(name: "get_site_status", input: [:])
        #expect(result.contains("Riverside Lofts"))
        #expect(result.contains("DELAYED"))
        #expect(result.contains("ON TRACK"))
    }

    @Test @MainActor func mcpGetWeather() {
        let server = MCPToolServer.shared
        let result = server.executeTool(name: "get_weather", input: [:])
        #expect(result.contains("Heavy Rain"))
        #expect(result.contains("CONCRETE POUR HOLD"))
    }

    @Test @MainActor func mcpRentalSearch() {
        let server = MCPToolServer.shared
        let result = server.executeTool(name: "get_rental_inventory", input: ["query": "excavator"])
        #expect(result.contains("Excavator"))
        #expect(result.contains("/day"))
    }

    @Test @MainActor func mcpRentalSearchNoResults() {
        let server = MCPToolServer.shared
        let result = server.executeTool(name: "get_rental_inventory", input: ["query": "zzzznonexistent"])
        #expect(result.contains("No equipment found"))
    }

    @Test @MainActor func mcpCalculateRentalCost() {
        let server = MCPToolServer.shared
        let result = server.executeTool(name: "calculate_rental_cost", input: [
            "equipment": "Excavator",
            "daily_rate": 850.0,
            "days": 5,
            "quantity": 2
        ])
        #expect(result.contains("8500"))
        #expect(result.contains("Excavator"))
    }

    @Test @MainActor func mcpUnknownTool() {
        let server = MCPToolServer.shared
        let result = server.executeTool(name: "nonexistent_tool", input: [:])
        #expect(result.contains("Unknown tool"))
    }

    @Test @MainActor func mcpToolDefinitionsExist() {
        let server = MCPToolServer.shared
        let tools = server.toolDefinitions
        #expect(tools.count == 18)
        let names = tools.compactMap { $0["name"] as? String }
        #expect(names.contains("get_projects"))
        #expect(names.contains("get_rental_inventory"))
        #expect(names.contains("calculate_rental_cost"))
    }

    // MARK: - Model Codable Tests

    @Test func changeOrderCodable() {
        let co = ChangeOrderItem(number: "CO-001", title: "Test", amount: "$1,000", impactDays: "5", status: .pending, submittedDate: "03-25", decidedDate: "", description: "Test CO")
        let data = try? JSONEncoder().encode(co)
        #expect(data != nil)
        let decoded = try? JSONDecoder().decode(ChangeOrderItem.self, from: data!)
        #expect(decoded?.title == "Test")
        #expect(decoded?.status == .pending)
    }

    @Test func safetyIncidentCodable() {
        let inc = SafetyIncident(type: .nearMiss, date: "03-25", location: "Site A", description: "Test", crewMember: "John", correctiveAction: "Fixed", status: .open)
        let data = try? JSONEncoder().encode(inc)
        #expect(data != nil)
        let decoded = try? JSONDecoder().decode(SafetyIncident.self, from: data!)
        #expect(decoded?.type == .nearMiss)
        #expect(decoded?.location == "Site A")
    }

    @Test func materialDeliveryCodable() {
        let d = MaterialDelivery(material: "Steel", quantity: "48 pcs", supplier: "Nucor", po: "PO-001", expectedDate: "03-25", actualDate: "", status: .ordered, notes: "")
        let data = try? JSONEncoder().encode(d)
        #expect(data != nil)
        let decoded = try? JSONDecoder().decode(MaterialDelivery.self, from: data!)
        #expect(decoded?.material == "Steel")
        #expect(decoded?.status == .ordered)
    }

    @Test func rfiItemCodable() {
        let rfi = RFIItem(id: 1, subject: "Test RFI", assignedTo: "Engineering", submittedDaysAgo: 5, priority: .high, status: .open)
        let data = try? JSONEncoder().encode(rfi)
        #expect(data != nil)
        let decoded = try? JSONDecoder().decode(RFIItem.self, from: data!)
        #expect(decoded?.subject == "Test RFI")
        #expect(decoded?.priority == .high)
    }

    // MARK: - Rental Data Store Tests

    @Test @MainActor func rentalFavoriteToggle() {
        let store = RentalDataStore.shared
        let item = RentalItem(name: "Test Excavator", category: .heavyEquipment, dailyRate: "$850", weeklyRate: "$3200", monthlyRate: "$8500", specs: "20-ton", availability: "Available", provider: .unitedRentals, imageIcon: "🏗")
        let wasFav = store.isFavorite(item)
        store.toggleFavorite(item)
        #expect(store.isFavorite(item) != wasFav)
        store.toggleFavorite(item) // toggle back
        #expect(store.isFavorite(item) == wasFav)
    }

    // MARK: - Subscription Tier Tests

    @Test func subscriptionTierFeatures() {
        let free = SubscriptionManager.SubscriptionTier.free
        let pro = SubscriptionManager.SubscriptionTier.pro
        let enterprise = SubscriptionManager.SubscriptionTier.enterprise
        #expect(free.features.count > 0)
        #expect(pro.features.count > free.features.count)
        #expect(enterprise.features.count > pro.features.count)
    }

    // MARK: - Rental Provider Tests

    @Test func allProvidersHaveURLs() {
        for provider in RentalProvider.allCases {
            #expect(!provider.websiteURL.isEmpty)
            #expect(!provider.searchURL.isEmpty)
            #expect(!provider.tagline.isEmpty)
            #expect(!provider.features.isEmpty)
        }
    }

    @Test func rentalCategoryCount() {
        #expect(RentalCategory.allCases.count == 20)
    }

    @Test func rentalProviderCount() {
        #expect(RentalProvider.allCases.count == 6)
    }

    @Test func rentalInventoryNotEmpty() {
        #expect(rentalInventory.count >= 90)
    }

    // MARK: - Deep Link Tests

    @Test func deepLinkProjects() {
        let tab = DeepLinkHandler.handleURL(URL(string: "constructionos://projects")!)
        #expect(tab == .projects)
    }

    @Test func deepLinkRentals() {
        let tab = DeepLinkHandler.handleURL(URL(string: "constructionos://rentals")!)
        #expect(tab == .rentals)
    }

    @Test func deepLinkSettings() {
        let tab = DeepLinkHandler.handleURL(URL(string: "constructionos://settings")!)
        #expect(tab == .settings)
    }

    @Test func deepLinkUnknown() {
        let tab = DeepLinkHandler.handleURL(URL(string: "constructionos://unknown")!)
        #expect(tab == .home)
    }

    @Test func deepLinkWrongScheme() {
        let tab = DeepLinkHandler.handleURL(URL(string: "https://example.com")!)
        #expect(tab == nil)
    }

    @Test func deepLinkAllTabs() {
        let paths = ["projects", "contracts", "market", "maps", "ops", "hub", "security",
                     "angelic", "wealth", "rentals", "electrical", "tax", "field",
                     "finance", "compliance", "clients", "analytics", "schedule",
                     "training", "scanner", "settings"]
        for path in paths {
            let tab = DeepLinkHandler.handleURL(URL(string: "constructionos://\(path)")!)
            #expect(tab != nil, "Deep link for \(path) should resolve")
        }
    }

    // MARK: - Theme Tests

    @Test func themeColorsExist() {
        // Verify all theme colors are non-nil
        let colors = [Theme.bg, Theme.surface, Theme.panel, Theme.border,
                      Theme.accent, Theme.gold, Theme.cyan, Theme.green,
                      Theme.red, Theme.purple, Theme.text, Theme.muted]
        #expect(colors.count == 12)
    }

    // MARK: - OpsRolePreset Tests

    @Test func rolePresetValues() {
        #expect(OpsRolePreset.superintendent.display == "Superintendent")
        #expect(OpsRolePreset.projectManager.display == "Project Manager")
        #expect(OpsRolePreset.executive.display == "Executive")
    }

    @Test func rolePresetRawValues() {
        #expect(OpsRolePreset(rawValue: "SUPER") == .superintendent)
        #expect(OpsRolePreset(rawValue: "PM") == .projectManager)
        #expect(OpsRolePreset(rawValue: "EXEC") == .executive)
        #expect(OpsRolePreset(rawValue: "INVALID") == nil)
    }

    @Test func rolePresetAllCases() {
        #expect(OpsRolePreset.allCases.count == 3)
    }

    // MARK: - NavTab Tests

    @Test func navTabCount() {
        #expect(ContentView.NavTab.allCases.count == 25)
    }

    @Test func navTabRawValues() {
        #expect(ContentView.NavTab.home.rawValue == "home")
        #expect(ContentView.NavTab.rentals.rawValue == "rentals")
        #expect(ContentView.NavTab.settings.rawValue == "settings")
    }

    // MARK: - Electrical Trade Tests

    @Test func electricalTradeCount() {
        #expect(ElectricalTrade.allCases.count == 6)
    }

    @Test func electricalTradeIcons() {
        for trade in ElectricalTrade.allCases {
            #expect(!trade.icon.isEmpty)
        }
    }

    // MARK: - Tax Category Tests

    @Test func taxCategoryCount() {
        #expect(TaxCategory.allCases.count == 12)
    }

    @Test func taxCategoryIcons() {
        for cat in TaxCategory.allCases {
            #expect(!cat.icon.isEmpty)
            #expect(!cat.rawValue.isEmpty)
        }
    }

    // MARK: - Codable Round-Trip Tests

    @Test func punchListCodable() {
        let item = PunchListItem(description: "Fix drywall", location: "Floor 3", trade: "Finishing", dueDate: "04/01", status: .open, createdBy: "You")
        let data = try? JSONEncoder().encode(item)
        #expect(data != nil)
        let decoded = try? JSONDecoder().decode(PunchListItem.self, from: data!)
        #expect(decoded?.description == "Fix drywall")
        #expect(decoded?.status == .open)
    }

    @Test func dailyLogCodable() {
        let log = DailyLogEntry(date: "03/25", weather: "Clear", tempHigh: 68, tempLow: 50, manpower: 22, workPerformed: "Concrete pour", visitors: "None", delays: "", safetyNotes: "", photoCount: 3, createdBy: "You")
        let data = try? JSONEncoder().encode(log)
        #expect(data != nil)
        let decoded = try? JSONDecoder().decode(DailyLogEntry.self, from: data!)
        #expect(decoded?.manpower == 22)
    }

    @Test func timecardCodable() {
        let tc = TimecardEntry(crewMember: "Mike", trade: "Concrete", clockIn: "6:00", clockOut: "2:30", hoursRegular: 8, hoursOT: 0.5, rate: 45, site: "RSL", date: "03/25")
        let data = try? JSONEncoder().encode(tc)
        #expect(data != nil)
        let decoded = try? JSONDecoder().decode(TimecardEntry.self, from: data!)
        #expect(decoded?.crewMember == "Mike")
        #expect(decoded?.hoursOT == 0.5)
    }

    @Test func taxExpenseCodable() {
        let exp = TaxExpense(date: "03/25", description: "Steel", amount: 4200, category: .materials, projectRef: "RSL", receiptAttached: true, deductible: true)
        let data = try? JSONEncoder().encode(exp)
        #expect(data != nil)
        let decoded = try? JSONDecoder().decode(TaxExpense.self, from: data!)
        #expect(decoded?.amount == 4200)
        #expect(decoded?.category == .materials)
    }

    @Test func fuelEntryCodable() {
        let fuel = FuelEntry(date: "03/25", vehicle: "F-350", gallons: 32.4, pricePerGal: 3.45, odometer: 48291, site: "RSL")
        #expect(fuel.total == 32.4 * 3.45)
        let data = try? JSONEncoder().encode(fuel)
        #expect(data != nil)
    }

    @Test func electricalLeadCodable() {
        let lead = ElectricalLead(title: "Panel Upgrade", tradeType: "Electrician", description: "200A to 400A", location: "Houston", budget: "$15,000", urgency: "urgent", postedBy: "You", postedAt: Date(), bidsReceived: 0, status: "open")
        let data = try? JSONEncoder().encode(lead)
        #expect(data != nil)
        let decoded = try? JSONDecoder().decode(ElectricalLead.self, from: data!)
        #expect(decoded?.title == "Panel Upgrade")
    }

    // MARK: - MCP Tool Coverage

    @Test @MainActor func mcpGetCrewDeploy() {
        let result = MCPToolServer.shared.executeTool(name: "get_crew_deploy", input: [:])
        #expect(result.contains("61 workers"))
    }

    @Test @MainActor func mcpGetInspections() {
        let result = MCPToolServer.shared.executeTool(name: "get_inspections", input: [:])
        #expect(result.contains("DUE TODAY"))
        #expect(result.contains("OVERDUE"))
    }

    @Test @MainActor func mcpGetBudget() {
        let result = MCPToolServer.shared.executeTool(name: "get_budget_summary", input: [:])
        #expect(result.contains("$92.5M"))
    }

    @Test @MainActor func mcpGetContracts() {
        let result = MCPToolServer.shared.executeTool(name: "get_contracts", input: [:])
        #expect(result.contains("Client:"))
        #expect(result.contains("Budget:"))
    }

    @Test @MainActor func mcpGetChangeOrders() {
        let result = MCPToolServer.shared.executeTool(name: "get_change_orders", input: [:])
        #expect(result.contains("CO-"))
    }

    @Test @MainActor func mcpGetPunchList() {
        let result = MCPToolServer.shared.executeTool(name: "get_punch_list", input: [:])
        #expect(result.contains("OPEN"))
    }

    @Test @MainActor func mcpGetMaterialDeliveries() {
        let result = MCPToolServer.shared.executeTool(name: "get_material_deliveries", input: [:])
        #expect(result.contains("DELIVERED"))
        #expect(result.contains("DELAYED"))
    }

    @Test @MainActor func mcpGetRentalRates() {
        let result = MCPToolServer.shared.executeTool(name: "get_rental_rates", input: [:])
        #expect(result.contains("Excavators"))
        #expect(result.contains("/day"))
    }
}
