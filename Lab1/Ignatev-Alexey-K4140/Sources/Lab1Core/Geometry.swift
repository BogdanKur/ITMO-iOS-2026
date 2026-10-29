import Foundation
public struct Point: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public mutating func move(byX dx: Double, byY dy: Double) {
        x += dx
        y += dy
    }

    public var distanceToOrigin: Double {
        hypot(x, y)
    }
}

public struct Rectangle: Equatable, Sendable {
    public var origin: Point
    public private(set) var width: Double
    public private(set) var height: Double
    public init(origin: Point, width: Double, height: Double) {
        self.origin = origin
        self.width = width.isFinite && width > 0 ? width : 1
        self.height = height.isFinite && height > 0 ? height : 1
    }

    public var area: Double {
        width * height
    }

    public var perimeter: Double {
        2 * (width + height)
    }

    public var center: Point {
        Point(x: origin.x + width / 2, y: origin.y + height / 2)
    }

    // Invalid factors leave the rectangle unchanged, preserving positive finite dimensions.
    public mutating func scale(by factor: Double) {
        let w = width * factor, h = height * factor
        guard factor.isFinite, factor > 0, w.isFinite, h.isFinite, w > 0, h > 0 else {
            return
        }
        width = w
        height = h
    }

    public func contains(_ point: Point) -> Bool {
        point.x >= origin.x && point.x <= origin.x + width &&
            point.y >= origin.y && point.y <= origin.y + height
    }
}
