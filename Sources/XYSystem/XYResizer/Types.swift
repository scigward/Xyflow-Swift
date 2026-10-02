import Foundation

public struct ResizeParams: Equatable {
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
}

public struct ResizeParamsWithDirection: Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var direction: [Double]

    public init(x: Double, y: Double, width: Double, height: Double, direction: [Double]) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.direction = direction
    }
}

/// Used to determine the control line position of the NodeResizer.
public enum ControlLinePosition: String, Equatable {
    case top
    case bottom
    case left
    case right
}

/// Used to determine the control position of the NodeResizer.
public enum ControlPosition: String, Equatable {
    case top
    case bottom
    case left
    case right
    case topLeft = "top-left"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomRight = "bottom-right"

    public init(line: ControlLinePosition) {
        self = ControlPosition(rawValue: line.rawValue)!
    }
}

/// Used to determine the variant of the resize control.
public enum ResizeControlVariant: String, Equatable {
    case line
    case handle
}

/// The direction the user can resize the node.
public enum ResizeControlDirection: String, Equatable {
    case horizontal
    case vertical
}

public let xyResizerHandlePositions: [ControlPosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
public let xyResizerLinePositions: [ControlLinePosition] = [.top, .right, .bottom, .left]

public typealias ShouldResize = (D3DragEvent, ResizeParamsWithDirection) -> Bool
public typealias OnResizeStart = (D3DragEvent, ResizeParams) -> Void
public typealias OnResize = (D3DragEvent, ResizeParamsWithDirection) -> Void
public typealias OnResizeEnd = (D3DragEvent, ResizeParams) -> Void
