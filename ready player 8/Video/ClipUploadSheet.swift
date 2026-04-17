// Phase 22-08: Clip upload sheet presented as .sheet.
//
// Offers PhotosPicker (Photos library) and fileImporter (Files app) for video selection.
// On selection: probes file via VideoUploadClient.probeFile, validates D-31 caps,
// surfaces errors inline. On upload tap: starts VideoUploadClient.upload with progress.
// On success: dismisses sheet and calls VideoSyncManager.upsertAsset.
//
// D-38: Name field pre-filled with filename stripped of extension.

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ClipUploadSheet: View {
    let projectId: String
    let orgId: String
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    // File selection
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showFilePicker: Bool = false
    @State private var selectedFileURL: URL?

    // Form
    @State private var clipName: String = ""
    @State private var errorMessage: String?

    // Upload state
    @State private var isUploading: Bool = false
    @State private var uploadProgress: Double = 0
    @State private var uploadClient: VideoUploadClient?

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Source selection buttons
                        if selectedFileURL == nil {
                            sourceSelectionView
                        } else {
                            uploadFormView
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Upload clip")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        uploadClient?.cancel()
                        dismiss()
                    }
                    .foregroundColor(Theme.muted)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.mpeg4Movie, UTType.quickTimeMovie, .movie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    handleFileSelected(url)
                }
            case .failure(let error):
                errorMessage = "File selection failed: \(error.localizedDescription)"
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let item = newValue else { return }
            Task {
                // Export photo library video to a temp file
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let tmp = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("mov")
                    try? data.write(to: tmp)
                    handleFileSelected(tmp)
                }
            }
        }
    }

    // MARK: - Source selection

    private var sourceSelectionView: some View {
        VStack(spacing: 16) {
            Text("Choose a video file from Photos or Files.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.muted)

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .videos,
                photoLibrary: .shared()
            ) {
                Label("Choose from Photos", systemImage: "photo.on.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .foregroundColor(Theme.bg)
                    .cornerRadius(10)
            }

            Button {
                showFilePicker = true
            } label: {
                Label("Choose from Files", systemImage: "folder")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.surface)
                    .foregroundColor(Theme.text)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
            }

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.red)
                    .padding(12)
                    .background(Theme.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Upload form (after file selected)

    private var uploadFormView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // File info
            if let url = selectedFileURL {
                HStack {
                    Image(systemName: "film")
                        .foregroundColor(Theme.accent)
                    Text(url.lastPathComponent)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                    Spacer()
                    Button("Change") {
                        selectedFileURL = nil
                        clipName = ""
                        errorMessage = nil
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.accent)
                }
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Name field (D-38: pre-filled with filename)
            VStack(alignment: .leading, spacing: 6) {
                Text("CLIP NAME")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                TextField("Clip name", text: $clipName)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.text)
                    .accentColor(Theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.surface)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))
            }

            // Error
            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.red)
                    .padding(12)
                    .background(Theme.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Progress bar during upload
            if isUploading {
                VStack(spacing: 8) {
                    ProgressView(value: uploadProgress)
                        .tint(Theme.gold)
                    Text("Uploading \u{00B7} \(Int(uploadProgress * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
            }

            // Upload button
            Button {
                Task { await startUpload() }
            } label: {
                Text(isUploading ? "Uploading\u{2026}" : "Upload clip")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isUploading ? Theme.muted.opacity(0.3) : Theme.accent)
                    .foregroundColor(Theme.bg)
                    .cornerRadius(10)
            }
            .disabled(isUploading)
        }
    }

    // MARK: - File handling

    private func handleFileSelected(_ url: URL) {
        errorMessage = nil
        selectedFileURL = url

        // D-38: Pre-fill name with filename stripped of extension
        let filename = url.deletingPathExtension().lastPathComponent
        clipName = filename

        // Probe + validate immediately
        Task {
            do {
                let probe = try await VideoUploadClient.probeFile(url)
                try VideoUploadClient.validate(probe)
            } catch let err as AppError {
                errorMessage = err.errorDescription
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Upload

    private func startUpload() async {
        guard let fileURL = selectedFileURL else { return }
        guard let projId = UUID(uuidString: projectId),
              let oId = UUID(uuidString: orgId) else {
            errorMessage = "Invalid project or org ID."
            return
        }

        guard let apiBase = UserDefaults.standard.string(forKey: "ConstructOS.Integrations.Backend.BaseURL"),
              let baseURL = URL(string: apiBase) else {
            errorMessage = "Supabase backend not configured."
            return
        }

        let sessionToken = await MainActor.run { SupabaseService.shared.accessToken ?? "" }

        isUploading = true
        errorMessage = nil

        let client = VideoUploadClient(
            progress: { fraction in
                Task { @MainActor in
                    self.uploadProgress = fraction
                }
            },
            onComplete: { result in
                Task { @MainActor in
                    self.isUploading = false
                    switch result {
                    case .success:
                        // Trigger a re-sync so the new asset appears
                        await VideoSyncManager.shared.syncProject(projId, service: SupabaseService.shared)
                        self.onComplete()
                        self.dismiss()
                    case .failure(let err):
                        self.errorMessage = err.errorDescription ?? "Upload failed."
                    }
                }
            }
        )
        self.uploadClient = client

        await client.upload(
            fileUrl: fileURL,
            projectId: projId,
            orgId: oId,
            name: clipName.isEmpty ? nil : clipName,
            sessionToken: sessionToken,
            apiBaseURL: baseURL
        )
    }
}
