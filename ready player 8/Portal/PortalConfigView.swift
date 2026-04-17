import SwiftUI

// MARK: - ========== PortalConfigView.swift ==========

/// Section visibility configuration for a single portal link (D-28 through D-46).
/// Supports 5 section toggles, budget masking, template picker, expiry, slug, and more.
struct PortalConfigView: View {
    let config: SupabasePortalConfig

    // MARK: - Section Toggles
    @State private var scheduleEnabled = true
    @State private var budgetEnabled = false
    @State private var photosEnabled = true
    @State private var changeOrdersEnabled = true
    @State private var documentsEnabled = true

    // D-30: Budget data masked by default
    @State private var showExactAmounts = false

    // D-21: Show cameras toggle for portal viewers
    @State private var showCameras = false

    // Template picker (D-18)
    @State private var selectedTemplate = "full_progress"
    private let templates = ["executive_summary", "full_progress", "photo_update"]

    // Expiry picker (D-04)
    @State private var selectedExpiry = 30
    private let expiryOptions: [(label: String, days: Int)] = [
        ("7 days", 7),
        ("30 days", 30),
        ("90 days", 90),
        ("Never", 0),
    ]

    // Configuration fields
    @State private var slug: String = ""
    @State private var clientEmail: String = ""
    @State private var welcomeMessage: String = ""
    @State private var watermarkEnabled = false
    @State private var poweredByEnabled = false

    // State
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var errorMessage: String?

    private let supabase = SupabaseService.shared

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                sectionHeader
                templateSection
                sectionToggles
                settingsSection
                saveButton
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Portal Settings")
        .task { await loadConfig() }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PORTAL CONFIGURATION")
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundStyle(Theme.muted)
            Text(config.slug)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Theme.text)
        }
    }

    // MARK: - Template Picker (D-18)

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Template")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)

            Picker("Template", selection: $selectedTemplate) {
                Text("Executive Summary").tag("executive_summary")
                Text("Full Progress").tag("full_progress")
                Text("Photo Update").tag("photo_update")
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTemplate) { _, newTemplate in
                applyTemplateDefaults(newTemplate)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Section Toggles (D-28 through D-46)

    private var sectionToggles: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visible Sections")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)

            Text("Health score badge is always visible at top (D-29)")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)

            sectionToggle(
                icon: "calendar",
                title: "Schedule",
                subtitle: "Gantt chart and milestone checklist",
                isOn: $scheduleEnabled
            )

            VStack(spacing: 8) {
                sectionToggle(
                    icon: "dollarsign.circle",
                    title: "Budget",
                    subtitle: "Financial overview and status bars",
                    isOn: $budgetEnabled
                )

                // D-30: Additional toggle for exact amounts when budget is enabled
                if budgetEnabled {
                    HStack {
                        Spacer().frame(width: 36)
                        Toggle(isOn: $showExactAmounts) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show exact amounts")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.text)
                                Text("Display dollar values instead of percentages")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                        .tint(Theme.accent)
                    }
                    .padding(.horizontal, 14)
                    .transition(.opacity)
                }
            }

            sectionToggle(
                icon: "camera",
                title: "Photos",
                subtitle: "Progress photo timeline",
                isOn: $photosEnabled
            )

            sectionToggle(
                icon: "doc.text",
                title: "Change Orders",
                subtitle: "Scope and status updates",
                isOn: $changeOrdersEnabled
            )

            sectionToggle(
                icon: "folder",
                title: "Documents",
                subtitle: "Shared project documents",
                isOn: $documentsEnabled
            )

            sectionToggle(
                icon: "video",
                title: "Show cameras",
                subtitle: "Portal viewers can watch live streams (head-only) and any clips you've flagged as shareable.",
                isOn: $showCameras
            )
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sectionToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.text)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .tint(Theme.accent)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)

            // Expiry picker (D-04)
            VStack(alignment: .leading, spacing: 6) {
                Text("Link Expiry")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.text)
                Picker("Expiry", selection: $selectedExpiry) {
                    ForEach(expiryOptions, id: \.days) { option in
                        Text(option.label).tag(option.days)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Custom slug (D-24)
            VStack(alignment: .leading, spacing: 6) {
                Text("Custom Slug")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.text)
                TextField("e.g., riverdale-project", text: $slug)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            // Client email (D-09)
            VStack(alignment: .leading, spacing: 6) {
                Text("Client Email (optional)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.text)
                TextField("client@example.com", text: $clientEmail)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            // Welcome message (D-70)
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome Message")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.text)
                TextEditor(text: $welcomeMessage)
                    .frame(minHeight: 80)
                    .font(.system(size: 14))
                    .scrollContentBackground(.hidden)
                    .background(Theme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.border, lineWidth: 1)
                    )
            }

            // Watermark toggle (D-57)
            Toggle(isOn: $watermarkEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Watermark Photos")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.text)
                    Text("Add company watermark to portal photos")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
            }
            .tint(Theme.accent)

            // Powered by toggle (D-19)
            Toggle(isOn: $poweredByEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show \"Powered by ConstructionOS\"")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.text)
                    Text("Display branding in portal footer")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
            }
            .tint(Theme.accent)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: 8) {
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.red)
            }

            if saveSuccess {
                Text("Settings saved successfully!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.green)
            }

            Button {
                Task { await saveConfig() }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSaving ? "Saving..." : "Save Settings")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isSaving)
        }
    }

    // MARK: - Template Defaults (D-18, D-33)

    private func applyTemplateDefaults(_ template: String) {
        switch template {
        case "executive_summary":
            scheduleEnabled = true
            budgetEnabled = false // D-33: budget always defaults hidden
            photosEnabled = false
            changeOrdersEnabled = true
            documentsEnabled = false
        case "photo_update":
            scheduleEnabled = false
            budgetEnabled = false
            photosEnabled = true
            changeOrdersEnabled = false
            documentsEnabled = false
        default: // full_progress
            scheduleEnabled = true
            budgetEnabled = false
            photosEnabled = true
            changeOrdersEnabled = true
            documentsEnabled = true
        }
    }

    // MARK: - Data Operations

    private func loadConfig() async {
        // Populate fields from existing config
        selectedTemplate = config.template
        slug = config.slug
        clientEmail = config.clientEmail ?? ""
        welcomeMessage = config.welcomeMessage ?? ""
        watermarkEnabled = config.watermarkEnabled
        poweredByEnabled = config.poweredByEnabled
        showExactAmounts = config.showExactAmounts
        showCameras = config.showCameras

        // Parse sections_config JSON to set toggles
        if let data = config.sectionsConfig.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            scheduleEnabled = (json["schedule"] as? [String: Any])?["enabled"] as? Bool ?? true
            budgetEnabled = (json["budget"] as? [String: Any])?["enabled"] as? Bool ?? false
            photosEnabled = (json["photos"] as? [String: Any])?["enabled"] as? Bool ?? true
            changeOrdersEnabled = (json["change_orders"] as? [String: Any])?["enabled"] as? Bool ?? true
            documentsEnabled = (json["documents"] as? [String: Any])?["enabled"] as? Bool ?? true
        }
    }

    private func saveConfig() async {
        isSaving = true
        errorMessage = nil
        saveSuccess = false

        // Build sections_config JSON
        let sections: [String: Any] = [
            "schedule": ["enabled": scheduleEnabled],
            "budget": ["enabled": budgetEnabled],
            "photos": ["enabled": photosEnabled],
            "change_orders": ["enabled": changeOrdersEnabled],
            "documents": ["enabled": documentsEnabled],
        ]

        guard let sectionsData = try? JSONSerialization.data(withJSONObject: sections),
              let sectionsString = String(data: sectionsData, encoding: .utf8) else {
            errorMessage = "Failed to encode sections config"
            isSaving = false
            return
        }

        var updated = config
        updated.template = selectedTemplate
        updated.sectionsConfig = sectionsString
        updated.showExactAmounts = showExactAmounts
        updated.showCameras = showCameras
        updated.slug = slug
        updated.clientEmail = clientEmail.isEmpty ? nil : clientEmail
        updated.welcomeMessage = welcomeMessage.isEmpty ? nil : welcomeMessage
        updated.watermarkEnabled = watermarkEnabled
        updated.poweredByEnabled = poweredByEnabled

        do {
            guard let configId = config.id else {
                errorMessage = "Missing portal config ID"
                isSaving = false
                return
            }
            try await supabase.update("cs_portal_config", id: configId, record: updated)
            saveSuccess = true
            print("[PortalConfig] Saved config for \(config.slug)")
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
            print("[PortalConfig] Save failed: \(error.localizedDescription)")
        }

        isSaving = false
    }
}
