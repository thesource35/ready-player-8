// Phase 22-08: 2-step Add Camera wizard presented as .sheet.
//
// Step 1: Name (required 1-128 chars) + Location label (optional 0-256) + Audio toggle.
//   - Audio toggle ON shows red jurisdiction warning stripe (D-35) and requires
//     confirmation modal with exact UI-SPEC copy.
// Step 2: Displays RTMP URL + Stream key in monospace with Copy buttons.
//   - Stream key shown once then dropped (D-23).
//   - Copy button: default="Copy", active="Copied" (reverts after 2s).
//
// Calls POST /api/video/mux/create-live-input on Continue.
// On Finish: dismisses sheet, calls VideoSyncManager.upsertSource().

import SwiftUI

struct AddCameraWizard: View {
    let projectId: String
    let orgId: String
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var wizardStep: Int = 1

    // Step 1 fields
    @State private var name: String = ""
    @State private var locationLabel: String = ""
    @State private var audioEnabled: Bool = false
    @State private var showAudioConfirmation: Bool = false
    @State private var audioConfirmed: Bool = false

    // Step 1 loading + error
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Step 2 credentials (shown once)
    @State private var rtmpUrl: String = ""
    @State private var streamKey: String = ""
    @State private var createdSource: VideoSource?

    // Copy button states
    @State private var rtmpCopied: Bool = false
    @State private var keyCopied: Bool = false

    private var nameValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && name.count <= 128 }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if wizardStep == 1 {
                            step1View
                        } else {
                            step2View
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(wizardStep == 1 ? "Add camera" : "Camera credentials")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.muted)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Enable audio capture?", isPresented: $showAudioConfirmation) {
            Button("Cancel", role: .cancel) {
                audioEnabled = false
            }
            Button("Enable audio") {
                audioConfirmed = true
            }
        } message: {
            Text("Recording audio may require two-party consent in your state or country. Only turn this on if everyone who may be recorded has given consent.")
        }
    }

    // MARK: - Step 1

    private var step1View: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Audio jurisdiction warning stripe (D-35)
            if audioEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.red)
                    Text("Recording audio may require consent from everyone on site. Confirm you have consent before enabling, or leave audio off.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.red)
                }
                .padding(12)
                .background(Theme.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Name field
            VStack(alignment: .leading, spacing: 6) {
                Text("NAME")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                TextField("Camera name", text: $name)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.text)
                    .accentColor(Theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.surface)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))
                if name.count > 128 {
                    Text("Name must be 128 characters or fewer")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.red)
                }
            }

            // Location label field
            VStack(alignment: .leading, spacing: 6) {
                Text("LOCATION LABEL")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                TextField("Optional — e.g. NW corner, Level 3", text: $locationLabel)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.text)
                    .accentColor(Theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.surface)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))
            }

            // Audio toggle (D-35)
            Toggle(isOn: Binding(
                get: { audioEnabled },
                set: { newValue in
                    if newValue && !audioConfirmed {
                        showAudioConfirmation = true
                    } else if !newValue {
                        audioEnabled = false
                        audioConfirmed = false
                    }
                }
            )) {
                Text("Capture audio")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.text)
            }
            .tint(Theme.accent)

            // Error message
            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.red)
                    .padding(12)
                    .background(Theme.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Continue button
            Button {
                Task { await createLiveInput() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(Theme.bg)
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "" : "Continue")
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(nameValid && !isLoading ? Theme.accent : Theme.muted.opacity(0.3))
                .foregroundColor(Theme.bg)
                .cornerRadius(10)
            }
            .disabled(!nameValid || isLoading)
        }
    }

    // MARK: - Step 2

    private var step2View: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your camera is registered. Copy the credentials below into your encoder or camera settings.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.muted)

            // RTMP URL
            credentialField(
                label: "RTMP ingest URL",
                value: rtmpUrl,
                helper: "Paste this into your camera or encoder's streaming settings.",
                copied: rtmpCopied,
                onCopy: {
                    copyToClipboard(rtmpUrl)
                    rtmpCopied = true
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        rtmpCopied = false
                    }
                }
            )

            // Stream key
            credentialField(
                label: "Stream key",
                value: streamKey,
                helper: "Keep this secret \u{2014} it works like a password. You can copy it now, but it won't be shown again.",
                copied: keyCopied,
                onCopy: {
                    copyToClipboard(streamKey)
                    keyCopied = true
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        keyCopied = false
                    }
                }
            )

            // Finish button
            Button {
                // Optimistically add the source to sync manager
                if let src = createdSource {
                    VideoSyncManager.shared.upsertSource(src)
                }
                onComplete()
                dismiss()
            } label: {
                Text("Finish")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .foregroundColor(Theme.bg)
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Credential field helper

    private func credentialField(
        label: String,
        value: String,
        helper: String,
        copied: Bool,
        onCopy: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(Theme.muted)

            HStack {
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Theme.text)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onCopy) {
                    Text(copied ? "Copied" : "Copy")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(copied ? Theme.green : Theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(helper)
                .font(.system(size: 11))
                .foregroundColor(Theme.muted)
        }
    }

    // MARK: - API call

    private func createLiveInput() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let apiBase = UserDefaults.standard.string(forKey: "ConstructOS.Integrations.Backend.BaseURL"),
              let baseURL = URL(string: apiBase) else {
            errorMessage = "Supabase backend not configured. Set up your integration in Command \u{2192} Integrations."
            return
        }

        let sessionToken = await MainActor.run { SupabaseService.shared.accessToken ?? "" }

        let url = baseURL.appendingPathComponent("/api/video/mux/create-live-input")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "project_id": projectId,
            "org_id": orgId,
            "name": name.trimmingCharacters(in: .whitespaces),
            "location_label": locationLabel.trimmingCharacters(in: .whitespaces),
            "audio_enabled": audioEnabled
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                errorMessage = "Couldn't reach Mux to create the camera. Check your connection and try again \u{2014} nothing has been saved."
                return
            }

            if http.statusCode == 403 {
                let bodyStr = String(data: data, encoding: .utf8) ?? ""
                if bodyStr.contains("camera_limit_reached") {
                    errorMessage = "Camera limit reached (20). Archive an unused camera or contact support to raise the cap."
                } else {
                    errorMessage = "Permission denied. You may not have the required role to add cameras."
                }
                return
            }

            if http.statusCode >= 500 {
                errorMessage = "Couldn't reach Mux to create the camera. Check your connection and try again \u{2014} nothing has been saved."
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                errorMessage = "Couldn't create the camera (HTTP \(http.statusCode)). Please try again."
                return
            }

            // Decode the response
            struct CreateLiveInputResponse: Decodable {
                let source_id: String
                let rtmp_url: String
                let stream_key: String
                let playback_id: String
            }

            let resp = try JSONDecoder().decode(CreateLiveInputResponse.self, from: data)

            self.rtmpUrl = resp.rtmp_url
            self.streamKey = resp.stream_key

            // Build a local VideoSource for optimistic UI
            if let srcId = UUID(uuidString: resp.source_id),
               let projId = UUID(uuidString: projectId),
               let oId = UUID(uuidString: orgId) {
                self.createdSource = VideoSource(
                    id: srcId,
                    orgId: oId,
                    projectId: projId,
                    kind: .fixedCamera,
                    name: name.trimmingCharacters(in: .whitespaces),
                    locationLabel: locationLabel.isEmpty ? nil : locationLabel,
                    muxLiveInputId: nil,
                    muxPlaybackId: resp.playback_id,
                    audioEnabled: audioEnabled,
                    status: .idle,
                    lastActiveAt: nil,
                    createdAt: Date(),
                    createdBy: UUID()
                )
            }

            wizardStep = 2
        } catch {
            errorMessage = "Couldn't reach Mux to create the camera. Check your connection and try again \u{2014} nothing has been saved."
        }
    }

    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
