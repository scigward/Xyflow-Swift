#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

/// Where a path starts and ends and which way it goes there, which is where markers are put.
public struct SVGPathEnds {
    public var start: CGPoint
    /// The direction of the path at its start, in radians.
    public var startAngle: CGFloat
    public var end: CGPoint
    /// The direction of the path at its end, in radians.
    public var endAngle: CGFloat
}

extension SVGPath {
    /// The ends of a path with the directions it has at them (the way `orient="auto"` reads them). A
    /// direction that a segment does not give, because its control point sits on the end, is taken
    /// from the next point that does.
    public static func ends(of path: CGPath) -> SVGPathEnds? {
        var segments: [[CGPoint]] = []
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero

        path.applyWithBlock { pointer in
            let element = pointer.pointee

            switch element.type {
            case .moveToPoint:
                current = element.points[0]
                subpathStart = current
            case .addLineToPoint:
                let end = element.points[0]
                segments.append([current, end])
                current = end
            case .addQuadCurveToPoint:
                let control = element.points[0]
                let end = element.points[1]
                segments.append([current, control, end])
                current = end
            case .addCurveToPoint:
                let control1 = element.points[0]
                let control2 = element.points[1]
                let end = element.points[2]
                segments.append([current, control1, control2, end])
                current = end
            case .closeSubpath:
                if current != subpathStart {
                    segments.append([current, subpathStart])
                }
                current = subpathStart
            @unknown default:
                break
            }
        }

        guard let first = segments.first, let last = segments.last else {
            return nil
        }

        func angle(from a: CGPoint, to b: CGPoint) -> CGFloat? {
            let dx = b.x - a.x
            let dy = b.y - a.y
            if dx == 0 && dy == 0 { return nil }
            return atan2(dy, dx)
        }

        // the direction at the start: the first point of the segment that is not on the start
        var startAngle: CGFloat = 0
        for point in first.dropFirst() {
            if let found = angle(from: first[0], to: point) {
                startAngle = found
                break
            }
        }

        // the direction at the end: the last point of the segment that is not on the end
        var endAngle: CGFloat = 0
        let endPoint = last[last.count - 1]
        for point in last.dropLast().reversed() {
            if let found = angle(from: point, to: endPoint) {
                endAngle = found
                break
            }
        }

        return SVGPathEnds(start: first[0], startAngle: startAngle, end: endPoint, endAngle: endAngle)
    }
}
#endif
