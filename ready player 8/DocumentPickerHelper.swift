// DocumentPickerHelper.swift — Phase 13 Document Management
// Thin UIKit bridge that lets SwiftUI present UIDocumentPickerViewController
// and receive a single picked file URL (copied into the app sandbox).

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerHelper: UIViewControllerRepresentable {
    let onPicked: (URL) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .png, .jpeg, .heic, .webP]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coord {
        Coord(onPicked: onPicked, onCancel: onCancel)
    }

    final class Coord: NSObject, UIDocumentPickerDelegate {
        let onPicked: (URL) -> Void
        let onCancel: () -> Void
        init(onPicked: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPicked = onPicked
            self.onCancel = onCancel
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { onPicked(url) }
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}
