import Foundation

/// What `getBezierPath`, `getStraightPath`, `getSmoothStepPath` and `getSimpleBezierPath` return:
/// the path to draw and where a label of the edge goes.
public struct EdgePathResult: Equatable {
    /// The path to use in an SVG `<path>` element.
    public var path: String
    /// The `x` position you can use to render a label for this edge.
    public var labelX: Double
    /// The `y` position you can use to render a label for this edge.
    public var labelY: Double
    /// The absolute difference between the source `x` position and the `x` position of the
    /// middle of this path.
    public var offsetX: Double
    /// The absolute difference between the source `y` position and the `y` position of the
    /// middle of this path.
    public var offsetY: Double

    public init(path: String, labelX: Double, labelY: Double, offsetX: Double, offsetY: Double) {
        self.path = path
        self.labelX = labelX
        self.labelY = labelY
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
}

public struct GetBezierPathParams {
    /// The `x` position of the source handle.
    public var sourceX: Double
    /// The `y` position of the source handle.
    public var sourceY: Double
    /// The position of the source handle.
    public var sourcePosition: Position
    /// The `x` position of the target handle.
    public var targetX: Double
    /// The `y` position of the target handle.
    public var targetY: Double
    /// The position of the target handle.
    public var targetPosition: Position
    /// The curvature of the bezier edge.
    public var curvature: Double

    public init(
        sourceX: Double,
        sourceY: Double,
        sourcePosition: Position = .bottom,
        targetX: Double,
        targetY: Double,
        targetPosition: Position = .top,
        curvature: Double = 0.25
    ) {
        self.sourceX = sourceX
        self.sourceY = sourceY
        self.sourcePosition = sourcePosition
        self.targetX = targetX
        self.targetY = targetY
        self.targetPosition = targetPosition
        self.curvature = curvature
    }
}

public struct GetControlWithCurvatureParams {
    public var pos: Position
    public var x1: Double
    public var y1: Double
    public var x2: Double
    public var y2: Double
    public var c: Double

    public init(pos: Position, x1: Double, y1: Double, x2: Double, y2: Double, c: Double) {
        self.pos = pos
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.c = c
    }
}

public func getBezierEdgeCenter(
    sourceX: Double,
    sourceY: Double,
    targetX: Double,
    targetY: Double,
    sourceControlX: Double,
    sourceControlY: Double,
    targetControlX: Double,
    targetControlY: Double
) -> (centerX: Double, centerY: Double, offsetX: Double, offsetY: Double) {
    // cubic bezier t=0.5 mid point, not the actual mid point, but easy to calculate
    // https://stackoverflow.com/questions/67516101/how-to-find-distance-mid-point-of-bezier-curve
    let centerX = sourceX * 0.125 + sourceControlX * 0.375 + targetControlX * 0.375 + targetX * 0.125
    let centerY = sourceY * 0.125 + sourceControlY * 0.375 + targetControlY * 0.375 + targetY * 0.125
    let offsetX = abs(centerX - sourceX)
    let offsetY = abs(centerY - sourceY)

    return (centerX, centerY, offsetX, offsetY)
}

func calculateControlOffset(_ distance: Double, _ curvature: Double) -> Double {
    if distance >= 0 {
        return 0.5 * distance
    }

    return curvature * 25 * (-distance).squareRoot()
}

public func getControlWithCurvature(_ params: GetControlWithCurvatureParams) -> (Double, Double) {
    let pos = params.pos
    let x1 = params.x1
    let y1 = params.y1
    let x2 = params.x2
    let y2 = params.y2
    let c = params.c

    switch pos {
    case .left:
        return (x1 - calculateControlOffset(x1 - x2, c), y1)
    case .right:
        return (x1 + calculateControlOffset(x2 - x1, c), y1)
    case .top:
        return (x1, y1 - calculateControlOffset(y1 - y2, c))
    case .bottom:
        return (x1, y1 + calculateControlOffset(y2 - y1, c))
    }
}

/// Everything you need to render a bezier edge between two nodes.
/// - Returns: A path string you can use in an SVG, the `labelX` and `labelY` position (center of
///   path) and `offsetX`, `offsetY` between source handle and label.
public func getBezierPath(_ params: GetBezierPathParams) -> EdgePathResult {
    let (sourceControlX, sourceControlY) = getControlWithCurvature(GetControlWithCurvatureParams(
        pos: params.sourcePosition,
        x1: params.sourceX,
        y1: params.sourceY,
        x2: params.targetX,
        y2: params.targetY,
        c: params.curvature))
    let (targetControlX, targetControlY) = getControlWithCurvature(GetControlWithCurvatureParams(
        pos: params.targetPosition,
        x1: params.targetX,
        y1: params.targetY,
        x2: params.sourceX,
        y2: params.sourceY,
        c: params.curvature))
    let center = getBezierEdgeCenter(
        sourceX: params.sourceX,
        sourceY: params.sourceY,
        targetX: params.targetX,
        targetY: params.targetY,
        sourceControlX: sourceControlX,
        sourceControlY: sourceControlY,
        targetControlX: targetControlX,
        targetControlY: targetControlY)

    let start = "M\(formatNumber(params.sourceX)),\(formatNumber(params.sourceY))"
    let controls = "C\(formatNumber(sourceControlX)),\(formatNumber(sourceControlY)) \(formatNumber(targetControlX)),\(formatNumber(targetControlY))"
    let end = "\(formatNumber(params.targetX)),\(formatNumber(params.targetY))"

    return EdgePathResult(
        path: "\(start) \(controls) \(end)",
        labelX: center.centerX,
        labelY: center.centerY,
        offsetX: center.offsetX,
        offsetY: center.offsetY)
}
