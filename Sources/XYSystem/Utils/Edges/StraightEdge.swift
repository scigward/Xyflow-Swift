import Foundation

public struct GetStraightPathParams {
    /// The `x` position of the source handle.
    public var sourceX: Double
    /// The `y` position of the source handle.
    public var sourceY: Double
    /// The `x` position of the target handle.
    public var targetX: Double
    /// The `y` position of the target handle.
    public var targetY: Double

    public init(sourceX: Double, sourceY: Double, targetX: Double, targetY: Double) {
        self.sourceX = sourceX
        self.sourceY = sourceY
        self.targetX = targetX
        self.targetY = targetY
    }
}

/// Calculates the straight line path between two points.
/// - Returns: A path string you can use in an SVG, the `labelX` and `labelY` position (center of
///   path) and `offsetX`, `offsetY` between source handle and label.
public func getStraightPath(_ params: GetStraightPathParams) -> EdgePathResult {
    let center = getEdgeCenter(
        sourceX: params.sourceX,
        sourceY: params.sourceY,
        targetX: params.targetX,
        targetY: params.targetY)

    let path = "M \(formatNumber(params.sourceX)),\(formatNumber(params.sourceY))"
        + "L \(formatNumber(params.targetX)),\(formatNumber(params.targetY))"

    return EdgePathResult(
        path: path,
        labelX: center.centerX,
        labelY: center.centerY,
        offsetX: center.offsetX,
        offsetY: center.offsetY)
}
