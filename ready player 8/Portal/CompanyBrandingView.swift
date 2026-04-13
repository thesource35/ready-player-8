import PhotosUI
import SwiftUI

// MARK: - ========== CompanyBrandingView.swift ==========

/// Company branding settings for portal customization (D-71).
/// Supports color pickers, font selector, logo upload, and "Powered by" toggle.
struct CompanyBrandingView: View {
    // MARK: - State

    @State private var companyName = ""
    @State private var primaryColor = Color(red: 0.22, green: 0.40, blue: 0.72) // Corporate Blue default
    @State private var backgroundColor = Color.white
    @State private var textColor = Color(red: 0.10, green: 0.12, blue: 0.14)
    @State private var fontFamily = "Inter"
    @State private var poweredByEnabled = false
    @State private var logoItem: PhotosPickerItem?
    @State private var logoImage: Image?
    @State private var logoData: Data?

    @State private var isSaving = false
    @State private var isLoading = false
    @State private var saveSuccess = false
    @State private var errorMessage: String?
    @State private var showResetAlert = false

    @AppStorage("ConstructOS.Portal.CompanyBranding") private var cachedBrandingJSON = ""

    private let supabase = SupabaseService.shared

    private let fontOptions = ["Inter", "Roboto", "Source Sans 3", "DM Sans"]

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                header
                companyNameSection
                colorSection
                fontSection
                logoSection
                poweredBySection
                actionButtons
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Company Branding")
        .alert("Reset Branding", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetBranding()
            }
        } message: {
            Text("This will reset all branding settings to defaults. This action cannot be undone.")
        }
        .onChange(of: logoItem) { _, newItem in
            Task { await loadLogoImage(newItem) }
        }
        .task { await loadBranding() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BRANDING")
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundStyle(Theme.muted)
            Text("Company Branding")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Theme.text)
            Text("Customize how your portals look to clients")
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
        }
    }

    // MARK: - Company Name

    private var companyNameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Company Name")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)
            TextField("Your Company Name", text: $companyName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14))
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Color Section

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Brand Colors")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)

            ColorPicker("Primary Color", selection: $primaryColor, supportsOpacity: false)
                .font(.system(size: 14))
                .foregroundStyle(Theme.text)

            ColorPicker("Background Color", selection: $backgroundColor, supportsOpacity: false)
                .font(.system(size: 14))
                .foregroundStyle(Theme.text)

            ColorPicker("Text Color", selection: $textColor, supportsOpacity: false)
                .font(.system(size: 14))
                .foregroundStyle(Theme.text)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Font Section (D-76)

    private var fontSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Font Family")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)

            Picker("Font", selection: $fontFamily) {
                ForEach(fontOptions, id: \.self) { font in
                    Text(font).tag(font)
                }
            }
            .pickerStyle(.segmented)

            // Preview
            Text("The quick brown fox jumps over the lazy dog")
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
                .padding(.top, 4)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Logo Section (D-75)

    private var logoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Company Logo")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)

            Text("PNG or SVG, max 2MB. Recommended 400x100px.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.muted)

            if let logoImage {
                logoImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 60)
                    .padding(8)
                    .background(Theme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            PhotosPicker(selection: $logoItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text(logoImage != nil ? "Change Logo" : "Select Logo")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Powered By Toggle (D-19)

    private var poweredBySection: some View {
        Toggle(isOn: $poweredByEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Show \"Powered by ConstructionOS\"")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.text)
                Text("Display ConstructionOS branding in portal footer")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
            }
        }
        .tint(Theme.accent)
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.red)
            }

            if saveSuccess {
                Text("Branding saved successfully!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.green)
            }

            // Save button
            Button {
                Task { await saveBranding() }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView().tint(.white)
                    }
                    Text(isSaving ? "Saving..." : "Save Branding")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isSaving)

            // Reset button
            Button {
                showResetAlert = true
            } label: {
                Text("Reset Branding")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Logo Loading

    private func loadLogoImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // Validate size (2MB max, D-75)
                guard data.count <= 2 * 1024 * 1024 else {
                    errorMessage = "Logo must be under 2MB"
                    return
                }
                logoData = data
                #if canImport(UIKit)
                if let uiImage = UIImage(data: data) {
                    logoImage = Image(uiImage: uiImage)
                }
                #endif
            }
        } catch {
            print("[CompanyBranding] Failed to load logo: \(error.localizedDescription)")
        }
    }

    // MARK: - Data Operations

    private func loadBranding() async {
        isLoading = true
        defer { isLoading = false }

        // Try local cache first
        if !cachedBrandingJSON.isEmpty,
           let data = cachedBrandingJSON.data(using: .utf8),
           let cached = try? JSONDecoder().decode(BrandingCache.self, from: data) {
            companyName = cached.companyName
            fontFamily = cached.fontFamily
            poweredByEnabled = cached.poweredByEnabled
            // Colors from hex
            if let p = Color(hex: cached.primaryHex) { primaryColor = p }
            if let b = Color(hex: cached.backgroundHex) { backgroundColor = b }
            if let t = Color(hex: cached.textHex) { textColor = t }
        }

        // Try remote
        guard supabase.isConfigured else { return }
        do {
            if let branding = try await supabase.fetchCompanyBranding(orgId: supabase.currentOrgId) {
                companyName = branding.companyName
                fontFamily = branding.fontFamily
                // Parse theme_config JSON for colors
                if let data = branding.themeConfig.data(using: .utf8),
                   let theme = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let hex = theme["primary"] as? String, let c = Color(hex: hex) { primaryColor = c }
                    if let hex = theme["background"] as? String, let c = Color(hex: hex) { backgroundColor = c }
                    if let hex = theme["text"] as? String, let c = Color(hex: hex) { textColor = c }
                }
            }
        } catch {
            print("[CompanyBranding] Remote load failed: \(error.localizedDescription)")
        }
    }

    private func saveBranding() async {
        isSaving = true
        errorMessage = nil
        saveSuccess = false

        // Build theme config JSON
        let themeConfig: [String: Any] = [
            "primary": primaryColor.hexString,
            "background": backgroundColor.hexString,
            "text": textColor.hexString,
            "fontFamily": fontFamily,
        ]

        guard let themeData = try? JSONSerialization.data(withJSONObject: themeConfig),
              let themeString = String(data: themeData, encoding: .utf8) else {
            errorMessage = "Failed to encode theme config"
            isSaving = false
            return
        }

        // Save to local cache
        let cache = BrandingCache(
            companyName: companyName,
            fontFamily: fontFamily,
            poweredByEnabled: poweredByEnabled,
            primaryHex: primaryColor.hexString,
            backgroundHex: backgroundColor.hexString,
            textHex: textColor.hexString
        )
        if let cacheData = try? JSONEncoder().encode(cache) {
            cachedBrandingJSON = String(data: cacheData, encoding: .utf8) ?? ""
        }

        // Save to Supabase
        guard supabase.isConfigured else {
            saveSuccess = true
            isSaving = false
            return
        }

        do {
            // Try to fetch existing branding first
            var branding = try await supabase.fetchCompanyBranding(orgId: supabase.currentOrgId)
            if branding != nil {
                branding?.companyName = companyName
                branding?.fontFamily = fontFamily
                branding?.themeConfig = themeString
                try await supabase.saveCompanyBranding(branding!)
            } else {
                let newBranding = SupabaseCompanyBranding(
                    orgId: supabase.currentOrgId,
                    userId: supabase.currentUserEmail ?? "unknown",
                    companyName: companyName,
                    themeConfig: themeString,
                    fontFamily: fontFamily
                )
                try await supabase.saveCompanyBranding(newBranding)
            }
            saveSuccess = true
            print("[CompanyBranding] Saved branding for org \(supabase.currentOrgId)")
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
            print("[CompanyBranding] Save failed: \(error.localizedDescription)")
        }

        isSaving = false
    }

    private func resetBranding() {
        companyName = ""
        primaryColor = Color(red: 0.22, green: 0.40, blue: 0.72)
        backgroundColor = .white
        textColor = Color(red: 0.10, green: 0.12, blue: 0.14)
        fontFamily = "Inter"
        poweredByEnabled = false
        logoImage = nil
        logoData = nil
        cachedBrandingJSON = ""
    }
}

// MARK: - Local Cache Model

private struct BrandingCache: Codable {
    let companyName: String
    let fontFamily: String
    let poweredByEnabled: Bool
    let primaryHex: String
    let backgroundHex: String
    let textHex: String
}

// MARK: - Color Hex Extension

extension Color {
    /// Initialize from hex string (e.g., "#3366B8" or "3366B8")
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }

    /// Convert to hex string for JSON storage
    var hexString: String {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        #else
        return "#3366B8" // Fallback for non-UIKit platforms
        #endif
    }
}
