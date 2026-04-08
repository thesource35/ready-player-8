import XCTest
@testable import ready_player_8

#if canImport(PencilKit) && !os(macOS)
import PencilKit
#endif

/// Phase 16 FIELD-03 Wave 3: PencilKit ↔ LayerJSON round-trip + schema tests.
final class PencilKitJSONConverterTests: XCTestCase {

    // MARK: - Schema

    func test_decode_v1_fixture_keeps_known_shapes() throws {
        let json = Self.sampleJSON
        let data = Data(json.utf8)
        let layer = try JSONDecoder().decode(LayerJSON.self, from: data)
        XCTAssertEqual(layer.schemaVersion, 1)
        XCTAssertEqual(layer.shapes.count, 5)
        // Assert all normalized coordinates are in [0, 1].
        for shape in layer.shapes {
            for coord in Self.coords(of: shape) {
                XCTAssertGreaterThanOrEqual(coord, 0)
                XCTAssertLessThanOrEqual(coord, 1)
            }
        }
    }

    func test_decode_skips_unknown_shape_types() throws {
        let json = """
        {
          "schema_version": 1,
          "shapes": [
            {"type":"stroke","points":[[0.1,0.1],[0.2,0.2]],"color":"#FFF","width":2},
            {"type":"not_a_real_shape","mystery":"ignore me"},
            {"type":"rect","x":0.1,"y":0.1,"w":0.2,"h":0.2,"color":"#FFF","width":2}
          ]
        }
        """
        let layer = try JSONDecoder().decode(LayerJSON.self, from: Data(json.utf8))
        XCTAssertEqual(layer.shapes.count, 2, "unknown shape type must be dropped")
    }

    func test_encode_roundtrip_preserves_shape_count() throws {
        let layer = LayerJSON(
            schemaVersion: 1,
            shapes: [
                .stroke(.init(points: [[0.1, 0.1], [0.5, 0.5]], color: "#FF0000", width: 2)),
                .rect(.init(x: 0.1, y: 0.1, w: 0.2, h: 0.2, color: "#00FF00", width: 2)),
                .text(.init(x: 0.5, y: 0.5, text: "hi", color: "#FFFFFF", size: 24)),
            ]
        )
        let data = try JSONEncoder().encode(layer)
        let decoded = try JSONDecoder().decode(LayerJSON.self, from: data)
        XCTAssertEqual(decoded.shapes.count, 3)
    }

    // MARK: - PencilKit round-trip

    #if canImport(PencilKit) && !os(macOS)

    func test_pkDrawing_to_strokes_normalizes_into_unit_square() {
        let photoSize = CGSize(width: 1000, height: 500)
        let drawing = Self.makeDrawing(
            with: [
                [CGPoint(x: 100, y: 50), CGPoint(x: 500, y: 250), CGPoint(x: 900, y: 400)],
                [CGPoint(x: 0,   y: 0),  CGPoint(x: 1000, y: 500)],
                [CGPoint(x: 250, y: 125), CGPoint(x: 750, y: 375)],
            ]
        )
        let strokes = PencilKitJSONConverter.pkDrawingToStrokes(drawing, photoSize: photoSize)
        XCTAssertEqual(strokes.count, 3)
        for s in strokes {
            for p in s.points {
                XCTAssertEqual(p.count, 2)
                XCTAssertGreaterThanOrEqual(p[0], 0)
                XCTAssertLessThanOrEqual(p[0], 1)
                XCTAssertGreaterThanOrEqual(p[1], 0)
                XCTAssertLessThanOrEqual(p[1], 1)
            }
        }
    }

    func test_strokes_roundtrip_preserves_points_within_epsilon() {
        let photoSize = CGSize(width: 1000, height: 500)
        let original = Self.makeDrawing(
            with: [
                [CGPoint(x: 100, y: 50), CGPoint(x: 500, y: 250), CGPoint(x: 900, y: 400)],
            ]
        )
        let strokes = PencilKitJSONConverter.pkDrawingToStrokes(original, photoSize: photoSize)
        let rebuilt = PencilKitJSONConverter.strokesToPKDrawing(strokes, photoSize: photoSize)

        XCTAssertEqual(original.strokes.count, rebuilt.strokes.count)

        let reNormalized = PencilKitJSONConverter.pkDrawingToStrokes(rebuilt, photoSize: photoSize)
        XCTAssertEqual(reNormalized.count, strokes.count)
        for (a, b) in zip(strokes, reNormalized) {
            XCTAssertEqual(a.points.count, b.points.count)
            for (pa, pb) in zip(a.points, b.points) {
                XCTAssertEqual(pa[0], pb[0], accuracy: 0.01)
                XCTAssertEqual(pa[1], pb[1], accuracy: 0.01)
            }
        }
    }

    func test_composeLayer_merges_strokes_and_overlay_shapes() {
        let strokes: [AnnotationShape.Stroke] = [
            .init(points: [[0.1, 0.1], [0.2, 0.2]], color: "#FFF", width: 2),
        ]
        let overlay: [AnnotationShape] = [
            .arrow(.init(from: [0.1, 0.1], to: [0.9, 0.9], color: "#F00", width: 3)),
            .rect(.init(x: 0.2, y: 0.2, w: 0.3, h: 0.3, color: "#0F0", width: 2)),
        ]
        let layer = PencilKitJSONConverter.composeLayer(
            strokes: strokes, overlayShapes: overlay
        )
        XCTAssertEqual(layer.schemaVersion, 1)
        XCTAssertEqual(layer.shapes.count, 3)
        if case .stroke = layer.shapes[0] {} else { XCTFail("first shape must be stroke") }
    }

    // MARK: - Helpers

    private static func makeDrawing(with polylines: [[CGPoint]]) -> PKDrawing {
        var pkStrokes: [PKStroke] = []
        for poly in polylines {
            let controls = poly.map {
                PKStrokePoint(
                    location: $0,
                    timeOffset: 0,
                    size: CGSize(width: 2, height: 2),
                    opacity: 1,
                    force: 1,
                    azimuth: 0,
                    altitude: 0
                )
            }
            let path = PKStrokePath(controlPoints: controls, creationDate: Date())
            pkStrokes.append(PKStroke(ink: PKInk(.pen, color: .black), path: path))
        }
        return PKDrawing(strokes: pkStrokes)
    }

    #endif

    // MARK: - Fixture (inline — mirrors tests/fixtures/annotations/v1-sample.json)

    private static let sampleJSON = """
    {
      "schema_version": 1,
      "shapes": [
        {"type":"stroke","color":"#FF3B30","width":2,"points":[[0.12,0.18],[0.34,0.41],[0.58,0.63]]},
        {"type":"arrow","color":"#FFCC00","width":3,"from":[0.2,0.8],"to":[0.75,0.25]},
        {"type":"rect","color":"#34C759","width":2,"x":0.1,"y":0.1,"w":0.35,"h":0.2},
        {"type":"ellipse","color":"#5AC8FA","width":2,"cx":0.7,"cy":0.7,"rx":0.1,"ry":0.08},
        {"type":"text","color":"#FFFFFF","size":24,"x":0.3,"y":0.55,"text":"Crack in slab"}
      ]
    }
    """

    private static func coords(of shape: AnnotationShape) -> [Double] {
        switch shape {
        case .stroke(let s): return s.points.flatMap { $0 }
        case .arrow(let a):  return a.from + a.to
        case .rect(let r):   return [r.x, r.y]
        case .ellipse(let e): return [e.cx, e.cy]
        case .text(let t):   return [t.x, t.y]
        }
    }
}
