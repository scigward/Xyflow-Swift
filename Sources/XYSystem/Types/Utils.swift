import Foundation

/// While `PanelPosition` places a view in the corners of a container, `Position` is less
/// precise and used primarily in relation to edges and handles.
public enum Position: String, Equatable, Hashable {
    case left
    case top
    case right
    case bottom
}

public let oppositePosition: [Position: Position] = [
    .left: .right,
    .right: .left,
    .top: .bottom,
    .bottom: .top
]

/// A point in a coordinate system.
public struct XYPosition: Equatable, Hashable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = XYPosition(x: 0, y: 0)
}

public struct XYZPosition: Equatable, Hashable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct Dimensions: Equatable, Hashable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct Rect: Equatable, Hashable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public static let zero = Rect(x: 0, y: 0, width: 0, height: 0)
}

public struct Box: Equatable, Hashable {
    public var x: Double
    public var y: Double
    public var x2: Double
    public var y2: Double

    public init(x: Double, y: Double, x2: Double, y2: Double) {
        self.x = x
        self.y = y
        self.x2 = x2
        self.y2 = y2
    }
}

/// The translation and scale of the viewport as the zoom behaviour keeps it: `[x, y, scale]`.
public struct Transform: Equatable, Hashable {
    public var x: Double
    public var y: Double
    public var scale: Double

    public init(_ x: Double, _ y: Double, _ scale: Double) {
        self.x = x
        self.y = y
        self.scale = scale
    }

    public static let identity = Transform(0, 0, 1)

    public subscript(index: Int) -> Double {
        switch index {
        case 0: return x
        case 1: return y
        default: return scale
        }
    }
}

/// Two points in a coordinate system: the top left and the bottom right corner. It is used for
/// the bounds of nodes in the flow and for the bounds of the viewport.
public struct CoordinateExtent: Equatable, Hashable {
    public var minX: Double
    public var minY: Double
    public var maxX: Double
    public var maxY: Double

    public init(_ minX: Double, _ minY: Double, _ maxX: Double, _ maxY: Double) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }

    public init(topLeft: XYPosition, bottomRight: XYPosition) {
        self.init(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y)
    }

    /// `[[-∞, -∞], [+∞, +∞]]`, the unbounded extent props usually default to.
    public static let infinite = CoordinateExtent(
        -Double.infinity, -Double.infinity, Double.infinity, Double.infinity)
}

/// `-0` and `+0` are the same value for everything in this module, and `Double.minimum`/`maximum`
/// order them. These helpers keep the behaviour of `Math.min` and `Math.max`.
@inline(__always)
func jsMin(_ a: Double, _ b: Double) -> Double {
    if a.isNaN || b.isNaN { return .nan }
    return a < b ? a : (b < a ? b : (a.sign == .minus ? a : b))
}

@inline(__always)
func jsMax(_ a: Double, _ b: Double) -> Double {
    if a.isNaN || b.isNaN { return .nan }
    return a > b ? a : (b > a ? b : (a.sign == .plus ? a : b))
}

/// `Math.round`: halves go up, also for negative numbers (`-2.5` rounds to `-2`).
@inline(__always)
func jsRound(_ value: Double) -> Double {
    if !value.isFinite { return value }
    let floor = value.rounded(.down)
    return value - floor >= 0.5 ? floor + 1 : floor
}
