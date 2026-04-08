// HEICConverter.swift — Phase 13 Document Management
// Converts HEIC image bytes to JPEG via ImageIO. Used by DocumentSyncManager
// before upload (D-12: iOS auto-converts HEIC to JPEG so non-Apple recipients
// can read photos).

import Foundation
import ImageIO
import UniformTypeIdentifiers

enum HEICConverter {
    /// Decode HEIC bytes and re-encode as JPEG.
    /// - Parameters:
    ///   - heicData: Raw HEIC file bytes (e.g. from PHPickerViewController).
    ///   - quality: Lossy compression quality (0.0 ... 1.0). Default 0.85.
    /// - Returns: JPEG-encoded `Data` ready to upload.
    /// - Throws: `AppError.validationFailed` if the source bytes can't be
    ///   decoded as an image, or if JPEG encoding fails.
    static func heicToJpeg(_ heicData: Data, quality: CGFloat = 0.85) throws -> Data {
        guard let src = CGImageSourceCreateWithData(heicData as CFData, nil) else {
            throw AppError.validationFailed(field: "image", reason: "Invalid HEIC source")
        }
        guard CGImageSourceGetCount(src) > 0 else {
            throw AppError.validationFailed(field: "image", reason: "HEIC source contains no images")
        }
        let outData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            outData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw AppError.validationFailed(field: "image", reason: "JPEG destination creation failed")
        }
        let opts: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImageFromSource(dest, src, 0, opts as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw AppError.validationFailed(field: "image", reason: "JPEG finalize failed")
        }
        return outData as Data
    }
}
