// Phase 16 FIELD-03: Swift mirror of the v1 annotation layer_json schema.
//
// Must stay in lockstep with web/src/lib/field/annotations/schema.ts.
// All coordinates normalized 0..1 against the photo's intrinsic size.
//
// Forward-compat rule (T-16-FWDCOMPAT): AnnotationShape.init(from:) returns nil
// (via a wrapping optional decoder) for unknown discriminants, and the
// LayerJSON decoder silently drops those entries.

import Foundation

public struct LayerJSON: Codable, Equatable {
    public var schemaVersion: Int
    public var shapes: [AnnotationShape]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case shapes
    }

    public init(schemaVersion: Int = 1, shapes: [AnnotationShape] = []) {
        self.schemaVersion = schemaVersion
        self.shapes = shapes
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = (try? c.decode(Int.self, forKey: .schemaVersion)) ?? 1

        // Decode shapes as an array of optional ShapeOrUnknown; drop unknowns.
        var unkeyed = try c.nestedUnkeyedContainer(forKey: .shapes)
        var out: [AnnotationShape] = []
        while !unkeyed.isAtEnd {
            if let wrap = try? unkeyed.decode(ShapeOrUnknown.self) {
                if let s = wrap.shape { out.append(s) }
            } else {
                // Skip malformed element to keep parsing resilient.
                _ = try? unkeyed.decode(AnyCodable.self)
            }
        }
        self.shapes = out
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(shapes, forKey: .shapes)
    }
}

public enum AnnotationShape: Codable, Equatable {
    case stroke(Stroke)
    case arrow(Arrow)
    case rect(Rect)
    case ellipse(Ellipse)
    case text(Text)

    public struct Stroke: Codable, Equatable {
        public var points: [[Double]] // each [x, y] normalized 0..1
        public var color: String
        public var width: Double

        public init(points: [[Double]], color: String, width: Double) {
            self.points = points
            self.color = color
            self.width = width
        }
    }

    public struct Arrow: Codable, Equatable {
        public var from: [Double] // [x, y]
        public var to: [Double]
        public var color: String
        public var width: Double
    }

    public struct Rect: Codable, Equatable {
        public var x: Double
        public var y: Double
        public var w: Double
        public var h: Double
        public var color: String
        public var width: Double
    }

    public struct Ellipse: Codable, Equatable {
        public var cx: Double
        public var cy: Double
        public var rx: Double
        public var ry: Double
        public var color: String
        public var width: Double
    }

    public struct Text: Codable, Equatable {
        public var x: Double
        public var y: Double
        public var text: String
        public var color: String
        public var size: Double
    }

    enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: TypeKey.self)
        let type = try c.decode(String.self, forKey: .type)
        let single = try decoder.singleValueContainer()
        switch type {
        case "stroke":  self = .stroke(try single.decode(Stroke.self))
        case "arrow":   self = .arrow(try single.decode(Arrow.self))
        case "rect":    self = .rect(try single.decode(Rect.self))
        case "ellipse": self = .ellipse(try single.decode(Ellipse.self))
        case "text":    self = .text(try single.decode(Text.self))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: c,
                debugDescription: "unknown shape type \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: DynamicKey.self)
        switch self {
        case .stroke(let s):
            try c.encode("stroke", forKey: .init(stringValue: "type")!)
            try c.encode(s.points, forKey: .init(stringValue: "points")!)
            try c.encode(s.color, forKey: .init(stringValue: "color")!)
            try c.encode(s.width, forKey: .init(stringValue: "width")!)
        case .arrow(let a):
            try c.encode("arrow", forKey: .init(stringValue: "type")!)
            try c.encode(a.from, forKey: .init(stringValue: "from")!)
            try c.encode(a.to, forKey: .init(stringValue: "to")!)
            try c.encode(a.color, forKey: .init(stringValue: "color")!)
            try c.encode(a.width, forKey: .init(stringValue: "width")!)
        case .rect(let r):
            try c.encode("rect", forKey: .init(stringValue: "type")!)
            try c.encode(r.x, forKey: .init(stringValue: "x")!)
            try c.encode(r.y, forKey: .init(stringValue: "y")!)
            try c.encode(r.w, forKey: .init(stringValue: "w")!)
            try c.encode(r.h, forKey: .init(stringValue: "h")!)
            try c.encode(r.color, forKey: .init(stringValue: "color")!)
            try c.encode(r.width, forKey: .init(stringValue: "width")!)
        case .ellipse(let e):
            try c.encode("ellipse", forKey: .init(stringValue: "type")!)
            try c.encode(e.cx, forKey: .init(stringValue: "cx")!)
            try c.encode(e.cy, forKey: .init(stringValue: "cy")!)
            try c.encode(e.rx, forKey: .init(stringValue: "rx")!)
            try c.encode(e.ry, forKey: .init(stringValue: "ry")!)
            try c.encode(e.color, forKey: .init(stringValue: "color")!)
            try c.encode(e.width, forKey: .init(stringValue: "width")!)
        case .text(let t):
            try c.encode("text", forKey: .init(stringValue: "type")!)
            try c.encode(t.x, forKey: .init(stringValue: "x")!)
            try c.encode(t.y, forKey: .init(stringValue: "y")!)
            try c.encode(t.text, forKey: .init(stringValue: "text")!)
            try c.encode(t.color, forKey: .init(stringValue: "color")!)
            try c.encode(t.size, forKey: .init(stringValue: "size")!)
        }
    }
}

/// Private wrapper that returns nil shape when decoding fails (unknown type).
struct ShapeOrUnknown: Decodable {
    let shape: AnnotationShape?
    init(from decoder: Decoder) throws {
        self.shape = try? AnnotationShape(from: decoder)
    }
}

/// Dynamic coding key used for heterogeneous shape encoding.
struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

/// Trivial "any json" decoder used only to skip malformed entries.
struct AnyCodable: Codable {
    init(from decoder: Decoder) throws { _ = try decoder.singleValueContainer() }
    func encode(to encoder: Encoder) throws {}
}
