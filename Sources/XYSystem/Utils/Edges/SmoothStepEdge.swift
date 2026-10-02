import Foundation

public struct GetSmoothStepPathParams {
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
    public var borderRadius: Double
    public var centerX: Double?
    public var centerY: Double?
    public var offset: Double

    public init(
        sourceX: Double,
        sourceY: Double,
        sourcePosition: Position = .bottom,
        targetX: Double,
        targetY: Double,
        targetPosition: Position = .top,
        borderRadius: Double = 5,
        centerX: Double? = nil,
        centerY: Double? = nil,
        offset: Double = 20
    ) {
        self.sourceX = sourceX
        self.sourceY = sourceY
        self.sourcePosition = sourcePosition
        self.targetX = targetX
        self.targetY = targetY
        self.targetPosition = targetPosition
        self.borderRadius = borderRadius
        self.centerX = centerX
        self.centerY = centerY
        self.offset = offset
    }
}

private enum Axis {
    case x
    case y

    var opposite: Axis {
        self == .x ? .y : .x
    }
}

private extension XYPosition {
    subscript(axis: Axis) -> Double {
        get { axis == .x ? x : y }
        set {
            if axis == .x { x = newValue } else { y = newValue }
        }
    }
}

private let handleDirections: [Position: XYPosition] = [
    .left: XYPosition(x: -1, y: 0),
    .right: XYPosition(x: 1, y: 0),
    .top: XYPosition(x: 0, y: -1),
    .bottom: XYPosition(x: 0, y: 1)
]

private func getDirection(source: XYPosition, sourcePosition: Position = .bottom, target: XYPosition) -> XYPosition {
    if sourcePosition == .left || sourcePosition == .right {
        return source.x < target.x ? XYPosition(x: 1, y: 0) : XYPosition(x: -1, y: 0)
    }
    return source.y < target.y ? XYPosition(x: 0, y: 1) : XYPosition(x: 0, y: -1)
}

private func distance(_ a: XYPosition, _ b: XYPosition) -> Double {
    (pow(b.x - a.x, 2) + pow(b.y - a.y, 2)).squareRoot()
}

/// With this function we try to mimic an orthogonal edge routing behaviour. It's not as good as a
/// real orthogonal edge routing, but it's faster and good enough as a default for step and smooth
/// step edges.
private func getPoints(
    source: XYPosition,
    sourcePosition: Position = .bottom,
    target: XYPosition,
    targetPosition: Position = .top,
    center: (x: Double?, y: Double?),
    offset: Double
) -> (points: [XYPosition], centerX: Double, centerY: Double, offsetX: Double, offsetY: Double) {
    let sourceDir = handleDirections[sourcePosition]!
    let targetDir = handleDirections[targetPosition]!
    let sourceGapped = XYPosition(x: source.x + sourceDir.x * offset, y: source.y + sourceDir.y * offset)
    let targetGapped = XYPosition(x: target.x + targetDir.x * offset, y: target.y + targetDir.y * offset)
    let dir = getDirection(source: sourceGapped, sourcePosition: sourcePosition, target: targetGapped)
    let dirAccessor: Axis = dir.x != 0 ? .x : .y
    let currDir = dir[dirAccessor]

    var points: [XYPosition] = []
    var centerX: Double
    var centerY: Double
    var sourceGapOffset = XYPosition(x: 0, y: 0)
    var targetGapOffset = XYPosition(x: 0, y: 0)

    let defaultCenter = getEdgeCenter(
        sourceX: source.x, sourceY: source.y, targetX: target.x, targetY: target.y)

    // opposite handle positions, default case
    if sourceDir[dirAccessor] * targetDir[dirAccessor] == -1 {
        centerX = center.x ?? defaultCenter.centerX
        centerY = center.y ?? defaultCenter.centerY
        //    --->
        //    |
        // >---
        let verticalSplit = [
            XYPosition(x: centerX, y: sourceGapped.y),
            XYPosition(x: centerX, y: targetGapped.y)
        ]
        //    |
        //  ---
        //  |
        let horizontalSplit = [
            XYPosition(x: sourceGapped.x, y: centerY),
            XYPosition(x: targetGapped.x, y: centerY)
        ]

        if sourceDir[dirAccessor] == currDir {
            points = dirAccessor == .x ? verticalSplit : horizontalSplit
        } else {
            points = dirAccessor == .x ? horizontalSplit : verticalSplit
        }
    } else {
        // sourceTarget means we take x from source and y from target, targetSource is the opposite
        let sourceTarget = [XYPosition(x: sourceGapped.x, y: targetGapped.y)]
        let targetSource = [XYPosition(x: targetGapped.x, y: sourceGapped.y)]
        // this handles edges with same handle positions
        if dirAccessor == .x {
            points = sourceDir.x == currDir ? targetSource : sourceTarget
        } else {
            points = sourceDir.y == currDir ? sourceTarget : targetSource
        }

        if sourcePosition == targetPosition {
            let diff = abs(source[dirAccessor] - target[dirAccessor])

            // if an edge goes from right to right for example (sourcePosition === targetPosition) and
            // the distance between source.x and target.x is less than the offset, the added point and
            // the gapped source/target will overlap. This leads to a weird edge path. To avoid this we
            // add a gapOffset to the source/target
            if diff <= offset {
                let gapOffset = jsMin(offset - 1, offset - diff)
                if sourceDir[dirAccessor] == currDir {
                    sourceGapOffset[dirAccessor] = (sourceGapped[dirAccessor] > source[dirAccessor] ? -1 : 1) * gapOffset
                } else {
                    targetGapOffset[dirAccessor] = (targetGapped[dirAccessor] > target[dirAccessor] ? -1 : 1) * gapOffset
                }
            }
        }

        // these are conditions for handling mixed handle positions like Right -> Bottom for example
        if sourcePosition != targetPosition {
            let dirAccessorOpposite = dirAccessor.opposite
            let isSameDir = sourceDir[dirAccessor] == targetDir[dirAccessorOpposite]
            let sourceGtTargetOppo = sourceGapped[dirAccessorOpposite] > targetGapped[dirAccessorOpposite]
            let sourceLtTargetOppo = sourceGapped[dirAccessorOpposite] < targetGapped[dirAccessorOpposite]
            let flipSourceTarget =
                (sourceDir[dirAccessor] == 1 && ((!isSameDir && sourceGtTargetOppo) || (isSameDir && sourceLtTargetOppo)))
                || (sourceDir[dirAccessor] != 1 && ((!isSameDir && sourceLtTargetOppo) || (isSameDir && sourceGtTargetOppo)))

            if flipSourceTarget {
                points = dirAccessor == .x ? sourceTarget : targetSource
            }
        }

        let sourceGapPoint = XYPosition(x: sourceGapped.x + sourceGapOffset.x, y: sourceGapped.y + sourceGapOffset.y)
        let targetGapPoint = XYPosition(x: targetGapped.x + targetGapOffset.x, y: targetGapped.y + targetGapOffset.y)
        let maxXDistance = jsMax(abs(sourceGapPoint.x - points[0].x), abs(targetGapPoint.x - points[0].x))
        let maxYDistance = jsMax(abs(sourceGapPoint.y - points[0].y), abs(targetGapPoint.y - points[0].y))

        // we want to place the label on the longest segment of the edge
        if maxXDistance >= maxYDistance {
            centerX = (sourceGapPoint.x + targetGapPoint.x) / 2
            centerY = points[0].y
        } else {
            centerX = points[0].x
            centerY = (sourceGapPoint.y + targetGapPoint.y) / 2
        }
    }

    let pathPoints =
        [source, XYPosition(x: sourceGapped.x + sourceGapOffset.x, y: sourceGapped.y + sourceGapOffset.y)]
        + points
        + [XYPosition(x: targetGapped.x + targetGapOffset.x, y: targetGapped.y + targetGapOffset.y), target]

    return (pathPoints, centerX, centerY, defaultCenter.offsetX, defaultCenter.offsetY)
}

private func getBend(_ a: XYPosition, _ b: XYPosition, _ c: XYPosition, _ size: Double) -> String {
    let bendSize = jsMin(jsMin(distance(a, b) / 2, distance(b, c) / 2), size)
    let x = b.x
    let y = b.y

    // no bend
    if (a.x == x && x == c.x) || (a.y == y && y == c.y) {
        return "L\(formatNumber(x)) \(formatNumber(y))"
    }

    // first segment is horizontal
    if a.y == y {
        let xDir: Double = a.x < c.x ? -1 : 1
        let yDir: Double = a.y < c.y ? 1 : -1
        return "L \(formatNumber(x + bendSize * xDir)),\(formatNumber(y))"
            + "Q \(formatNumber(x)),\(formatNumber(y)) \(formatNumber(x)),\(formatNumber(y + bendSize * yDir))"
    }

    let xDir: Double = a.x < c.x ? 1 : -1
    let yDir: Double = a.y < c.y ? -1 : 1
    return "L \(formatNumber(x)),\(formatNumber(y + bendSize * yDir))"
        + "Q \(formatNumber(x)),\(formatNumber(y)) \(formatNumber(x + bendSize * xDir)),\(formatNumber(y))"
}

/// Everything you need to render a stepped path between two nodes. The `borderRadius` can be used
/// to choose how rounded the corners of those steps are.
/// - Returns: A path string you can use in an SVG, the `labelX` and `labelY` position (center of
///   path) and `offsetX`, `offsetY` between source handle and label.
public func getSmoothStepPath(_ params: GetSmoothStepPathParams) -> EdgePathResult {
    let result = getPoints(
        source: XYPosition(x: params.sourceX, y: params.sourceY),
        sourcePosition: params.sourcePosition,
        target: XYPosition(x: params.targetX, y: params.targetY),
        targetPosition: params.targetPosition,
        center: (x: params.centerX, y: params.centerY),
        offset: params.offset)
    let points = result.points

    var path = ""
    for (index, point) in points.enumerated() {
        if index > 0 && index < points.count - 1 {
            path += getBend(points[index - 1], point, points[index + 1], params.borderRadius)
        } else {
            path += "\(index == 0 ? "M" : "L")\(formatNumber(point.x)) \(formatNumber(point.y))"
        }
    }

    return EdgePathResult(
        path: path,
        labelX: result.centerX,
        labelY: result.centerY,
        offsetX: result.offsetX,
        offsetY: result.offsetY)
}
