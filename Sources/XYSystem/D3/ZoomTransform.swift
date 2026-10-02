import Foundation

/// The transform a zoom behavior keeps: a translation and a scale. A point `p` of the content is
/// at `p * k + (x, y)` of the view.
public struct ZoomTransform: Equatable {
    public var k: Double
    public var x: Double
    public var y: Double

    public init(k: Double, x: Double, y: Double) {
        self.k = k
        self.x = x
        self.y = y
    }

    public static let identity = ZoomTransform(k: 1, x: 0, y: 0)

    public func scale(_ factor: Double) -> ZoomTransform {
        factor == 1 ? self : ZoomTransform(k: k * factor, x: x, y: y)
    }

    public func translate(_ dx: Double, _ dy: Double) -> ZoomTransform {
        dx == 0 && dy == 0 ? self : ZoomTransform(k: k, x: x + k * dx, y: y + k * dy)
    }

    public func apply(_ point: XYPosition) -> XYPosition {
        XYPosition(x: point.x * k + x, y: point.y * k + y)
    }

    public func applyX(_ value: Double) -> Double {
        value * k + x
    }

    public func applyY(_ value: Double) -> Double {
        value * k + y
    }

    public func invert(_ location: XYPosition) -> XYPosition {
        XYPosition(x: (location.x - x) / k, y: (location.y - y) / k)
    }

    public func invertX(_ value: Double) -> Double {
        (value - x) / k
    }

    public func invertY(_ value: Double) -> Double {
        (value - y) / k
    }
}
