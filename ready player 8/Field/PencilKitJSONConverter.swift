// Phase 16 FIELD-03: PKDrawing ↔ LayerJSON converter.
//
// Per RESEARCH §5: PencilKit owns freehand strokes only. Arrows, rects,
// ellipses, and text labels live in a SwiftUI overlay layer above the
// PKCanvasView, then get merged into the same LayerJSON on save.
//
// Coordinates in LayerJSON are normalized 0..1 against the photo's
// intrinsic size. The converter accepts/returns PKDrawing in photo-
// space coordinates (0...photoSize.width × 0...photoSize.height).

import Foundation
import CoreGraphics
#if canImport(PencilKit) && !os(macOS)
import PencilKit
#endif

public enum PencilKitJSONConverter {

    #if canImport(PencilKit) && !os(macOS)

    /// Convert each PKStroke into a normalized AnnotationShape.Stroke.
    /// Default colour "#000000" + width 2.0 when PencilKit ink attrs
    /// cannot be mapped cleanly.
    public static func pkDrawingToStrokes(
        _ drawing: PKDrawing,
        photoSize: CGSize
    ) -> [AnnotationShape.Stroke] {
        guard photoSize.width > 0, photoSize.height > 0 else { return [] }
        var result: [AnnotationShape.Stroke] = []
        for stroke in drawing.strokes {
            var points: [[Double]] = []
            // PKStrokePath is sampled at parametric values.
            let path = stroke.path
            // Sample at integer indices — cheap, deterministic.
            for i in 0..<path.count {
                let pt = path[i].location
                let nx = min(max(Double(pt.x) / Double(photoSize.width),  0), 1)
                let ny = min(max(Double(pt.y) / Double(photoSize.height), 0), 1)
                points.append([nx, ny])
            }
            if points.count >= 1 {
                let colorHex = hexString(from: stroke.ink.color) ?? "#000000"
                result.append(.init(
                    points: points,
                    color: colorHex,
                    width: 2.0
                ))
            }
        }
        return result
    }

    /// Rebuild a PKDrawing from normalized AnnotationShape.Stroke values.
    public static func strokesToPKDrawing(
        _ strokes: [AnnotationShape.Stroke],
        photoSize: CGSize
    ) -> PKDrawing {
        var pkStrokes: [PKStroke] = []
        for s in strokes {
            var controls: [PKStrokePoint] = []
            for p in s.points where p.count == 2 {
                let x = CGFloat(p[0]) * photoSize.width
                let y = CGFloat(p[1]) * photoSize.height
                let sp = PKStrokePoint(
                    location: CGPoint(x: x, y: y),
                    timeOffset: 0,
                    size: CGSize(width: s.width, height: s.width),
                    opacity: 1,
                    force: 1,
                    azimuth: 0,
                    altitude: 0
                )
                controls.append(sp)
            }
            guard !controls.isEmpty else { continue }
            let path = PKStrokePath(controlPoints: controls, creationDate: Date())
            let ink = PKInk(.pen, color: uiColor(fromHex: s.color) ?? .black)
            pkStrokes.append(PKStroke(ink: ink, path: path))
        }
        return PKDrawing(strokes: pkStrokes)
    }

    /// Merge strokes with non-PencilKit overlay shapes into a single layer.
    public static func composeLayer(
        strokes: [AnnotationShape.Stroke],
        overlayShapes: [AnnotationShape]
    ) -> LayerJSON {
        var all: [AnnotationShape] = strokes.map { .stroke($0) }
        all.append(contentsOf: overlayShapes)
        return LayerJSON(schemaVersion: 1, shapes: all)
    }

    // MARK: - Colour helpers

    private static func hexString(from color: UIColor) -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let ri = Int(round(r * 255))
        let gi = Int(round(g * 255))
        let bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }

    private static func uiColor(fromHex hex: String) -> UIColor? {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = CGFloat((v >> 16) & 0xff) / 255.0
        let g = CGFloat((v >>  8) & 0xff) / 255.0
        let b = CGFloat( v        & 0xff) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }

    #endif
}
