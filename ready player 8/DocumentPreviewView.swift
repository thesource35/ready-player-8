// DocumentPreviewView.swift — Phase 13 Document Management
// In-app preview for PDFs (PDFKit) and images (AsyncImage). Loads a short-lived
// signed URL for the document's storage path on appear. Surfaces AppError
// inline with a Retry button.

import SwiftUI
import PDFKit

struct DocumentPreviewView: View {
    let document: SupabaseDocument

    @State private var signedURL: URL?
    @State private var error: AppError?

    var body: some View {
        Group {
            if let error {
                VStack(spacing: 12) {
                    Text("Preview failed")
                        .font(.headline)
                        .foregroundColor(Theme.red)
                    Text(error.errorDescription ?? "Unknown error")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button("Retry") {
                        Task { await load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if let signedURL {
                if document.mimeType == "application/pdf" {
                    PDFKitView(url: signedURL)
                        .edgesIgnoringSafeArea(.bottom)
                } else if document.mimeType.hasPrefix("image/") {
                    AsyncImage(url: signedURL) { img in
                        img.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Text("Unsupported preview type: \(document.mimeType)")
                        .foregroundColor(Theme.muted)
                }
            } else {
                ProgressView("Loading preview…")
                    .task { await load() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(document.filename)
        .background(Theme.bg)
    }

    private func load() async {
        do {
            let url = try await SupabaseService.shared.createSignedURL(
                bucket: "documents",
                path: document.storagePath
            )
            signedURL = url
            error = nil
        } catch let e as AppError {
            self.error = e
        } catch {
            self.error = .network(underlying: error)
        }
    }
}

/// SwiftUI bridge to PDFKit. Loads the PDF off the main thread to keep large
/// (>5MB) documents from blocking UI scroll.
struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.backgroundColor = .black
        Task.detached {
            let doc = PDFDocument(url: url)
            await MainActor.run { v.document = doc }
        }
        return v
    }

    func updateUIView(_ v: PDFView, context: Context) {}
}
