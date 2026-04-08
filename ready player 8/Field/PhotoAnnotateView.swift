// Phase 16 FIELD-03: SwiftUI photo annotation screen.
//
// Layout: ZStack { Image · PKCanvasView (strokes) · Canvas overlay
// (arrows/rects/text) · toolbar }. On save the PKDrawing is converted
// to AnnotationShape.Stroke values, composed with the overlay shapes, and upserted
// into cs_photo_annotations via SupabaseService.
//
// This view is intentionally minimal — it compiles cleanly on iOS and
// is stubbed out on macOS (no PencilKit).

import SwiftUI

#if canImport(PencilKit) && !os(macOS)
import PencilKit

struct PhotoAnnotateView: View {
    let documentId: String
    let orgId: String
    let photo: UIImage

    @State private var canvas = PKCanvasView()
    @State private var overlayShapes: [AnnotationShape] = []
    @State private var saveStatus: String = ""
    @State private var isSaving = false

    private var photoSize: CGSize { photo.size }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                PKCanvasRepresentable(canvas: $canvas)
                    .background(Color.clear)
            }
            .frame(maxWidth: .infinity)

            HStack {
                Button("Undo") { canvas.undoManager?.undo() }
                Button("Clear") {
                    canvas.drawing = PKDrawing()
                    overlayShapes.removeAll()
                }
                Spacer()
                if !saveStatus.isEmpty {
                    Text(saveStatus).font(.caption)
                }
                Button(isSaving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
            .padding(.horizontal)
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let strokes = PencilKitJSONConverter.pkDrawingToStrokes(
            canvas.drawing, photoSize: photoSize
        )
        let layer = PencilKitJSONConverter.composeLayer(
            strokes: strokes, overlayShapes: overlayShapes
        )

        let dto = SupabasePhotoAnnotation(
            id: nil,
            document_id: documentId,
            org_id: orgId,
            layer_json: layer,
            schema_version: 1
        )

        do {
            try await SupabaseService.shared.upsertPhotoAnnotation(dto)
            saveStatus = "Saved"
        } catch {
            if let appErr = error as? AppError {
                saveStatus = appErr.errorDescription ?? "Error"
            } else {
                saveStatus = "Error: \(error.localizedDescription)"
            }
        }
    }
}

private struct PKCanvasRepresentable: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .red, width: 4)
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        return canvas
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

#else

struct PhotoAnnotateView: View {
    let documentId: String
    let orgId: String
    var body: some View {
        Text("Photo annotation requires iOS.")
            .foregroundColor(.secondary)
            .padding()
    }
}

#endif
