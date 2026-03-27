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
}
