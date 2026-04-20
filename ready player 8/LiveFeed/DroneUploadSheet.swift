// Phase 29 LIVE-01 — iOS drone upload sheet.
//
// Uses .fileImporter (UI-SPEC §LIVE-01 line 285 iOS branch) +
// VideoUploadClient.upload(..., sourceType: .drone) — the widened signature
// 29-02 added to the single Phase 22 upload path (no parallel drone client).
//
// Error copy per UI-SPEC §Copywriting line 426-429:
//   upload failed — network unreachable / exceeds 2 GB / unsupported codec.
// AppError.errorDescription already phrases these per CLAUDE.md; we surface
// it verbatim as the inline message, so no new copy lives in this view.

import SwiftUI
import UniformTypeIdentifiers

struct DroneUploadSheet: View {
    let projectId: String
    let orgId: String
    let sessionToken: String
    let apiBaseURL: URL
    @Binding var isPresented: Bool
    /// Called with the new cs_video_assets.id on successful upload.
    let onUploadComplete: (String) -> Void

    @State private var showPicker: Bool = false
    @State private var uploadProgress: Double = 0
    @State private var uploadInFlight: Bool = false
    @State private var errorMessage: String?
    @State private var client: VideoUploadClient?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer()
                Text(stateHeading)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Theme.text)

                if uploadInFlight {
                    ProgressView(value: uploadProgress)
                        .tint(Theme.accent)
                        .padding(.horizontal, 32)
                    Text("\(Int(uploadProgress * 100))%")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.muted)
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Retry") { showPicker = true }
                        .foregroundColor(Theme.accent)
                } else {
                    Button(action: { showPicker = true }) {
                        Text("Choose File")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(2)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Theme.accent)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    Text("MP4 or MOV, up to 2 GB / 60 min")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
            }
            .navigationTitle("Upload Drone Clip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(Theme.accent)
                }
            }
            .fileImporter(
                isPresented: $showPicker,
                allowedContentTypes: [.movie, .video, .mpeg4Movie, .quickTimeMovie],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task { await startUpload(fileUrl: url) }
                    }
                case .failure(let err):
                    errorMessage = "Couldn't open file — \(err.localizedDescription)"
                }
            }
        }
        // T-29-06-03 mitigation: cancel any in-flight upload if the sheet
        // is torn down while bytes are still in transit. Prevents callback
        // leaks and the associated memory build-up.
        .onDisappear { client?.cancel() }
    }

    private var stateHeading: String {
        if uploadInFlight { return "Uploading…" }
        if errorMessage != nil { return "Upload failed" }
        return "Select a drone clip"
    }

    private func startUpload(fileUrl: URL) async {
        uploadInFlight = true
        errorMessage = nil
        uploadProgress = 0

        let c = VideoUploadClient(
            progress: { p in
                Task { @MainActor in uploadProgress = p }
            },
            onComplete: { result in
                Task { @MainActor in
                    uploadInFlight = false
                    switch result {
                    case .success(let assetId):
                        onUploadComplete(assetId)
                        isPresented = false
                    case .failure(let err):
                        errorMessage = err.errorDescription ?? "Upload failed."
                    }
                }
            }
        )
        self.client = c

        // LIVE-01 / D-11: drone discriminator flows to cs_video_assets.source_type='drone'
        // via the 29-02 widened /api/video/vod/upload-url route.
        guard let pId = UUID(uuidString: projectId),
              let oId = UUID(uuidString: orgId) else {
            errorMessage = "Invalid project or org id."
            uploadInFlight = false
            return
        }

        // Security-scoped resources from .fileImporter must be bracketed so
        // we can read the file during upload even after the picker dismisses.
        let accessing = fileUrl.startAccessingSecurityScopedResource()
        defer { if accessing { fileUrl.stopAccessingSecurityScopedResource() } }

        await c.upload(
            fileUrl: fileUrl,
            projectId: pId,
            orgId: oId,
            name: fileUrl.lastPathComponent,
            sessionToken: sessionToken,
            apiBaseURL: apiBaseURL,
            sourceType: .drone
        )
    }
}
