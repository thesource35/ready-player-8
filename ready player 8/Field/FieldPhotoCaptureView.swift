// FieldPhotoCaptureView.swift — Phase 16 gap fix
// ConstructionOS
//
// Simulator-compatible photo capture UI that wires the existing
// FieldLocationCapture + DocumentSyncManager + cs_documents pipeline together.
// Uses PhotosPicker (iOS 16+) so it works in the iOS Simulator where no
// physical camera is available. Camera UI on real devices can swap in
// UIImagePickerController later — the downstream pipeline is identical.

import PhotosUI
import SwiftUI
import UIKit

struct FieldPhotoCaptureView: View {

    // Persisted across launches so the tester doesn't re-enter IDs each time.
    @AppStorage("ConstructOS.Field.LastOrgID")     private var orgId: String = ""
    @AppStorage("ConstructOS.Field.LastProjectID") private var projectId: String = ""
    @AppStorage("ConstructOS.Field.LastUploader")  private var uploadedBy: String = "field-tester"

    @State private var selection: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var previewData: Data?
    @State private var status: String = ""
    @State private var isUploading = false
    @State private var uploadedDoc: SupabaseDocument?
    @State private var capturedGps: CapturedLocation?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    header

                    idFields

                    picker

                    if let img = previewImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .cornerRadius(10)
                    }

                    uploadButton

                    if !status.isEmpty {
                        Text(status)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.muted)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.surface)
                            .cornerRadius(8)
                    }

                    if let doc = uploadedDoc {
                        resultCard(doc)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Capture Field Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: selection) { _, newItem in
                Task { await loadSelection(newItem) }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FIELD · CAPTURE")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(Theme.cyan)
            Text("Pick a photo from the simulator library. The app attempts a fresh GPS fix, falls back to last-known, and records the result on the uploaded document.")
                .font(.system(size: 11))
                .foregroundColor(Theme.muted)
        }
    }

    private var idFields: some View {
        VStack(spacing: 8) {
            labeledField("Org ID (UUID)", text: $orgId)
            labeledField("Project ID (UUID)", text: $projectId)
            labeledField("Uploaded by", text: $uploadedBy)
        }
    }

    private func labeledField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.muted)
            TextField(label, text: text)
                .font(.system(size: 12))
                .padding(10)
                .background(Theme.surface)
                .cornerRadius(8)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }

    private var picker: some View {
        PhotosPicker(selection: $selection, matching: .images) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                Text(previewImage == nil ? "Pick Photo" : "Pick Another")
                    .font(.system(size: 12, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Theme.cyan.opacity(0.15))
            .foregroundColor(Theme.cyan)
            .cornerRadius(10)
        }
    }

    private var uploadButton: some View {
        Button {
            Task { await upload() }
        } label: {
            HStack {
                if isUploading { ProgressView().tint(.black) }
                Text(isUploading ? "Uploading…" : "Capture GPS & Upload")
                    .font(.system(size: 13, weight: .heavy))
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(canUpload ? Theme.accent : Theme.muted.opacity(0.3))
            .foregroundColor(.black)
            .cornerRadius(10)
        }
        .disabled(!canUpload || isUploading)
    }

    private var canUpload: Bool {
        previewData != nil && !orgId.isEmpty && !projectId.isEmpty
    }

    private func resultCard(_ doc: SupabaseDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("UPLOADED").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
            Text(doc.filename).font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text)
            HStack(spacing: 10) {
                Text("ID: \(doc.id.prefix(8))…").font(.system(size: 10)).foregroundColor(Theme.muted)
                if let badge = FieldPhotoUpload.gpsBadgeLabel(for: doc) {
                    Text(badge.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.gold.opacity(0.2))
                        .foregroundColor(Theme.gold)
                        .cornerRadius(4)
                } else if doc.gpsSource == GpsSource.fresh.rawValue {
                    Text("GPS").font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.green.opacity(0.2))
                        .foregroundColor(Theme.green)
                        .cornerRadius(4)
                }
            }
            if let lat = doc.gpsLat, let lng = doc.gpsLng {
                Text(String(format: "lat %.5f, lng %.5f", lat, lng))
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
            }
            // Phase 16 gap fix (test: iOS annotate): entry point to
            // PhotoAnnotateView. We already have the UIImage in previewImage
            // and the document id from the upload result, so the annotator
            // gets everything it needs inline.
            if let img = previewImage {
                NavigationLink {
                    PhotoAnnotateView(documentId: doc.id, orgId: orgId, photo: img)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil.tip.crop.circle")
                        Text("ANNOTATE")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.18))
                    .foregroundColor(Theme.accent)
                    .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(10)
    }

    // MARK: - Actions

    @MainActor
    private func loadSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                previewData = data
                previewImage = UIImage(data: data)
                status = "Photo loaded — ready to capture GPS and upload."
            }
        } catch {
            status = "Failed to load photo: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func upload() async {
        guard let data = previewData else { return }
        isUploading = true
        defer { isUploading = false }
        status = "Capturing GPS…"
        capturedGps = nil
        uploadedDoc = nil

        // 1. Attempt GPS capture — graceful on denial/timeout (sim).
        let capture = FieldLocationCapture(provider: CLLocationProvider())
        var gps: CapturedLocation?
        do {
            try await capture.ensurePermission()
            gps = try await capture.captureLocation()
        } catch {
            status = "GPS unavailable (\(error.localizedDescription)). Upload will proceed without location."
        }
        capturedGps = gps

        // 2. Write temp JPEG so DocumentSyncManager's fileURL path works unchanged.
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("field-\(UUID().uuidString).jpg")
        do {
            try data.write(to: tmp)
        } catch {
            status = "Failed to stage file: \(error.localizedDescription)"
            return
        }
        defer { try? FileManager.default.removeItem(at: tmp) }

        // 3. Upload via the existing pipeline (handles insert + attachment row).
        let sync = DocumentSyncManager.shared
        do {
            let doc = try await sync.uploadDocument(
                fileURL: tmp,
                entityType: .project,
                entityId: projectId,
                orgId: orgId,
                uploadedBy: uploadedBy
            )
            status = "Uploaded. Patching GPS metadata…"

            // 4. PATCH GPS fields onto the new row if we got a location.
            if let gps {
                let payload = GpsPatchPayload(
                    gpsLat: gps.lat,
                    gpsLng: gps.lng,
                    gpsAccuracyM: gps.accuracyM,
                    gpsSource: gps.source.rawValue,
                    capturedAt: ISO8601DateFormatter().string(from: gps.capturedAt)
                )
                try await SupabaseService.shared.update("cs_documents", id: doc.id, record: payload)
                var updated = doc
                FieldPhotoUpload.applyCapturedLocation(to: &updated, location: gps)
                uploadedDoc = updated
                status = "Done. GPS source: \(gps.source.rawValue)."
            } else {
                uploadedDoc = doc
                status = "Done. No GPS attached (permission denied or timeout)."
            }
        } catch {
            status = "Upload failed: \(error.localizedDescription)"
        }
    }
}

/// PATCH payload for cs_documents GPS columns. Matches snake_case encoder.
private struct GpsPatchPayload: Encodable {
    let gpsLat: Double
    let gpsLng: Double
    let gpsAccuracyM: Double
    let gpsSource: String
    let capturedAt: String
}
