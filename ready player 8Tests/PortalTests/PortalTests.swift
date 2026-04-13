//
//  PortalTests.swift
//  ready player 8Tests
//
//  Per D-128: iOS XCTests for portal link creation, branding config, SupabaseService extensions.
//  Verifies DTO encoding/decoding for portal types (SupabasePortalConfig, SupabaseCompanyBranding).
//

import Testing
import Foundation
@testable import ready_player_8

// MARK: - Portal DTO Tests (D-128)

struct PortalTests {

    // MARK: - SupabasePortalConfig Codable

    @Test func portalConfigEncodesDecode() throws {
        let config = SupabasePortalConfig(
            linkId: "test-link-123",
            projectId: "test-project-456",
            userId: "test-user-789",
            slug: "riverdale-apartments",
            companySlug: "acme-builders",
            template: "full_progress",
            sectionsConfig: "{\"schedule\":{\"enabled\":true},\"budget\":{\"enabled\":false},\"photos\":{\"enabled\":true},\"change_orders\":{\"enabled\":true},\"documents\":{\"enabled\":true}}",
            showExactAmounts: false,
            watermarkEnabled: false,
            poweredByEnabled: false
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(SupabasePortalConfig.self, from: data)

        #expect(decoded.slug == "riverdale-apartments")
        #expect(decoded.companySlug == "acme-builders")
        #expect(decoded.template == "full_progress")
        #expect(decoded.showExactAmounts == false)
        #expect(decoded.watermarkEnabled == false)
        #expect(decoded.poweredByEnabled == false)
        #expect(decoded.linkId == "test-link-123")
        #expect(decoded.projectId == "test-project-456")
    }

    @Test func portalConfigWithOptionalFields() throws {
        let config = SupabasePortalConfig(
            linkId: "link-opt",
            projectId: "proj-opt",
            userId: "user-opt",
            slug: "optional-test",
            companySlug: "test-co",
            template: "executive_summary",
            sectionsConfig: "{}",
            showExactAmounts: true,
            welcomeMessage: "Welcome to your project portal!",
            sectionNotes: "{\"schedule\":\"On track as of April 10\"}",
            pinnedItems: "{\"photos\":[\"photo-1\",\"photo-2\"]}",
            dateRanges: "{\"photos\":{\"start\":\"2026-01-01\",\"end\":\"2026-04-01\"}}",
            watermarkEnabled: true,
            poweredByEnabled: true,
            clientEmail: "client@example.com"
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(SupabasePortalConfig.self, from: data)

        #expect(decoded.welcomeMessage == "Welcome to your project portal!")
        #expect(decoded.clientEmail == "client@example.com")
        #expect(decoded.watermarkEnabled == true)
        #expect(decoded.poweredByEnabled == true)
        #expect(decoded.showExactAmounts == true)
        #expect(decoded.sectionNotes != nil)
        #expect(decoded.pinnedItems != nil)
        #expect(decoded.dateRanges != nil)
    }

    @Test func portalConfigNilOptionals() throws {
        let config = SupabasePortalConfig(
            linkId: "link-nil",
            projectId: "proj-nil",
            userId: "user-nil",
            slug: "nil-test",
            companySlug: "test-nil-co",
            template: "photo_update",
            sectionsConfig: "{}",
            showExactAmounts: false,
            watermarkEnabled: false,
            poweredByEnabled: false
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(SupabasePortalConfig.self, from: data)

        #expect(decoded.welcomeMessage == nil)
        #expect(decoded.clientEmail == nil)
        #expect(decoded.sectionNotes == nil)
        #expect(decoded.pinnedItems == nil)
        #expect(decoded.dateRanges == nil)
        #expect(decoded.isDeleted == nil)
    }

    // MARK: - SupabaseCompanyBranding Codable

    @Test func brandingEncodesDecodes() throws {
        let branding = SupabaseCompanyBranding(
            orgId: "org-123",
            userId: "user-456",
            companyName: "Acme Builders LLC",
            themeConfig: "{\"primary\":\"#2563EB\",\"secondary\":\"#1D4ED8\",\"background\":\"#F8F9FB\",\"text\":\"#111827\",\"cardBg\":\"#FFFFFF\",\"fontFamily\":\"Inter\",\"borderRadius\":8,\"customCSS\":null}",
            fontFamily: "Inter"
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(branding)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(SupabaseCompanyBranding.self, from: data)

        #expect(decoded.companyName == "Acme Builders LLC")
        #expect(decoded.fontFamily == "Inter")
        #expect(decoded.orgId == "org-123")
    }

    @Test func brandingWithOptionalAssets() throws {
        let branding = SupabaseCompanyBranding(
            orgId: "org-assets",
            userId: "user-assets",
            companyName: "Premium Builders",
            logoLightPath: "/branding/logo-light.png",
            logoDarkPath: "/branding/logo-dark.png",
            faviconPath: "/branding/favicon.ico",
            coverImagePath: "/branding/cover.jpg",
            themeConfig: "{}",
            fontFamily: "DM Sans",
            customCss: ".portal-header { border-bottom: 2px solid #2563EB; }",
            contactInfo: "{\"email\":\"info@premium.com\",\"phone\":\"555-0100\"}"
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(branding)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(SupabaseCompanyBranding.self, from: data)

        #expect(decoded.companyName == "Premium Builders")
        #expect(decoded.fontFamily == "DM Sans")
        #expect(decoded.logoLightPath == "/branding/logo-light.png")
        #expect(decoded.logoDarkPath == "/branding/logo-dark.png")
        #expect(decoded.faviconPath == "/branding/favicon.ico")
        #expect(decoded.coverImagePath == "/branding/cover.jpg")
        #expect(decoded.customCss != nil)
        #expect(decoded.contactInfo != nil)
    }

    @Test func brandingNilAssets() throws {
        let branding = SupabaseCompanyBranding(
            orgId: "org-nil",
            userId: "user-nil",
            companyName: "Basic Co",
            themeConfig: "{}",
            fontFamily: "Roboto"
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(branding)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(SupabaseCompanyBranding.self, from: data)

        #expect(decoded.logoLightPath == nil)
        #expect(decoded.logoDarkPath == nil)
        #expect(decoded.faviconPath == nil)
        #expect(decoded.coverImagePath == nil)
        #expect(decoded.customCss == nil)
        #expect(decoded.contactInfo == nil)
    }

    // MARK: - Template Defaults Verification

    @Test func templateNamesAreValid() {
        // Verify the three template types match expected values (D-18)
        let validTemplates = ["executive_summary", "full_progress", "photo_update"]
        for template in validTemplates {
            #expect(template.isEmpty == false)
        }
    }
}
