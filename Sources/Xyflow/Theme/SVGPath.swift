#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

/// Reads the path data of an SVG `<path>` (`M10,20 C40,20 60,80 90,80`, with the commands
/// `M L H V C S Q T A Z`, absolute and relative) into a `CGPath`.
public enum SVGPath {
    public static func cgPath(from data: String) -> CGPath {
        let path = CGMutablePath()
        var parser = Parser(Array(data.unicodeScalars))
        parser.parse(into: path)
        return path
    }

    private struct Parser {
        private let scalars: [Unicode.Scalar]
        private var index = 0

        private var current = CGPoint.zero
        private var subpathStart = CGPoint.zero
        private var lastCubicControl: CGPoint?
        private var lastQuadControl: CGPoint?

        init(_ scalars: [Unicode.Scalar]) {
            self.scalars = scalars
        }

        // MARK: Scanning

        private func isSeparator(_ scalar: Unicode.Scalar) -> Bool {
            switch scalar {
            case " ", ",", "\n", "\t", "\r":
                return true
            default:
                return false
            }
        }

        private mutating func skipSeparators() {
            while index < scalars.count, isSeparator(scalars[index]) {
                index += 1
            }
        }

        private func isCommand(_ scalar: Unicode.Scalar) -> Bool {
            "MmLlHhVvCcSsQqTtAaZz".unicodeScalars.contains(scalar)
        }

        private mutating func readNumber() -> Double? {
            skipSeparators()
            let start = index
            guard index < scalars.count else { return nil }

            if scalars[index] == "+" || scalars[index] == "-" { index += 1 }

            var digits = 0
            while index < scalars.count, isDigit(scalars[index]) {
                index += 1
                digits += 1
            }

            if index < scalars.count, scalars[index] == "." {
                index += 1
                while index < scalars.count, isDigit(scalars[index]) {
                    index += 1
                    digits += 1
                }
            }

            guard digits > 0 else {
                index = start
                return nil
            }

            if index < scalars.count, scalars[index] == "e" || scalars[index] == "E" {
                var probe = index + 1
                if probe < scalars.count, scalars[probe] == "+" || scalars[probe] == "-" { probe += 1 }
                if probe < scalars.count, isDigit(scalars[probe]) {
                    while probe < scalars.count, isDigit(scalars[probe]) { probe += 1 }
                    index = probe
                }
            }

            var text = ""
            text.unicodeScalars.append(contentsOf: scalars[start..<index])
            return Double(text)
        }

        private func isDigit(_ scalar: Unicode.Scalar) -> Bool {
            scalar.value >= 48 && scalar.value <= 57
        }

        /// The flags of an arc are a single `0` or `1`, which may stick to what follows.
        private mutating func readFlag() -> Bool? {
            skipSeparators()
            guard index < scalars.count else { return nil }
            if scalars[index] == "0" {
                index += 1
                return false
            }
            if scalars[index] == "1" {
                index += 1
                return true
            }
            return nil
        }

        private mutating func hasNumber() -> Bool {
            skipSeparators()
            guard index < scalars.count else { return false }
            let scalar = scalars[index]
            return isDigit(scalar) || scalar == "-" || scalar == "+" || scalar == "."
        }

        // MARK: Parsing

        mutating func parse(into path: CGMutablePath) {
            var command: Unicode.Scalar?

            while true {
                skipSeparators()
                guard index < scalars.count else { break }

                let scalar = scalars[index]
                if isCommand(scalar) {
                    command = scalar
                    index += 1
                    if scalar == "Z" || scalar == "z" {
                        path.closeSubpath()
                        current = subpathStart
                        lastCubicControl = nil
                        lastQuadControl = nil
                        continue
                    }
                } else if command == nil {
                    break
                } else if command == "M" {
                    // the numbers that follow a moveto are linetos
                    command = "L"
                } else if command == "m" {
                    command = "l"
                }

                guard let command else { break }
                if !execute(command, path: path) { break }
            }
        }

        private mutating func execute(_ command: Unicode.Scalar, path: CGMutablePath) -> Bool {
            let relative = command.value >= 97
            let offsetX = relative ? current.x : 0
            let offsetY = relative ? current.y : 0

            switch command {
            case "M", "m":
                guard let x = readNumber(), let y = readNumber() else { return false }
                current = CGPoint(x: offsetX + x, y: offsetY + y)
                subpathStart = current
                path.move(to: current)
                lastCubicControl = nil
                lastQuadControl = nil
            case "L", "l":
                guard let x = readNumber(), let y = readNumber() else { return false }
                current = CGPoint(x: offsetX + x, y: offsetY + y)
                path.addLine(to: current)
                lastCubicControl = nil
                lastQuadControl = nil
            case "H", "h":
                guard let x = readNumber() else { return false }
                current = CGPoint(x: offsetX + x, y: current.y)
                path.addLine(to: current)
                lastCubicControl = nil
                lastQuadControl = nil
            case "V", "v":
                guard let y = readNumber() else { return false }
                current = CGPoint(x: current.x, y: offsetY + y)
                path.addLine(to: current)
                lastCubicControl = nil
                lastQuadControl = nil
            case "C", "c":
                guard let x1 = readNumber(), let y1 = readNumber(),
                      let x2 = readNumber(), let y2 = readNumber(),
                      let x = readNumber(), let y = readNumber() else { return false }
                let control1 = CGPoint(x: offsetX + x1, y: offsetY + y1)
                let control2 = CGPoint(x: offsetX + x2, y: offsetY + y2)
                current = CGPoint(x: offsetX + x, y: offsetY + y)
                path.addCurve(to: current, control1: control1, control2: control2)
                lastCubicControl = control2
                lastQuadControl = nil
            case "S", "s":
                guard let x2 = readNumber(), let y2 = readNumber(),
                      let x = readNumber(), let y = readNumber() else { return false }
                let control1 = lastCubicControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                let control2 = CGPoint(x: offsetX + x2, y: offsetY + y2)
                current = CGPoint(x: offsetX + x, y: offsetY + y)
                path.addCurve(to: current, control1: control1, control2: control2)
                lastCubicControl = control2
                lastQuadControl = nil
            case "Q", "q":
                guard let x1 = readNumber(), let y1 = readNumber(),
                      let x = readNumber(), let y = readNumber() else { return false }
                let control = CGPoint(x: offsetX + x1, y: offsetY + y1)
                current = CGPoint(x: offsetX + x, y: offsetY + y)
                path.addQuadCurve(to: current, control: control)
                lastQuadControl = control
                lastCubicControl = nil
            case "T", "t":
                guard let x = readNumber(), let y = readNumber() else { return false }
                let control = lastQuadControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                current = CGPoint(x: offsetX + x, y: offsetY + y)
                path.addQuadCurve(to: current, control: control)
                lastQuadControl = control
                lastCubicControl = nil
            case "A", "a":
                guard let rx = readNumber(), let ry = readNumber(), let rotation = readNumber(),
                      let largeArc = readFlag(), let sweep = readFlag(),
                      let x = readNumber(), let y = readNumber() else { return false }
                let end = CGPoint(x: offsetX + x, y: offsetY + y)
                addArc(to: path, from: current, to: end, rx: rx, ry: ry, rotation: rotation,
                       largeArc: largeArc, sweep: sweep)
                current = end
                lastCubicControl = nil
                lastQuadControl = nil
            default:
                return false
            }

            return true
        }

        // MARK: Arcs

        /// An elliptical arc as cubic curves: the endpoint form of an SVG arc is turned into its center
        /// form (SVG 1.1, implementation notes F.6.5) and cut into pieces of at most a quarter turn.
        private func addArc(
            to path: CGMutablePath,
            from start: CGPoint,
            to end: CGPoint,
            rx radiusX: Double,
            ry radiusY: Double,
            rotation: Double,
            largeArc: Bool,
            sweep: Bool
        ) {
            var rx = abs(radiusX)
            var ry = abs(radiusY)

            if start == end { return }
            if rx == 0 || ry == 0 {
                path.addLine(to: end)
                return
            }

            let phi = rotation * Double.pi / 180
            let cosPhi = cos(phi)
            let sinPhi = sin(phi)

            let dx = (Double(start.x) - Double(end.x)) / 2
            let dy = (Double(start.y) - Double(end.y)) / 2
            let x1p = cosPhi * dx + sinPhi * dy
            let y1p = -sinPhi * dx + cosPhi * dy

            // radii that are too small are scaled up
            let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
            if lambda > 1 {
                let scale = lambda.squareRoot()
                rx *= scale
                ry *= scale
            }

            let numerator = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
            let denominator = rx * rx * y1p * y1p + ry * ry * x1p * x1p
            var coefficient = denominator == 0 ? 0 : (max(0, numerator / denominator)).squareRoot()
            if largeArc == sweep { coefficient = -coefficient }

            let cxp = coefficient * (rx * y1p / ry)
            let cyp = coefficient * -(ry * x1p / rx)

            let cx = cosPhi * cxp - sinPhi * cyp + (Double(start.x) + Double(end.x)) / 2
            let cy = sinPhi * cxp + cosPhi * cyp + (Double(start.y) + Double(end.y)) / 2

            func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
                let dot = ux * vx + uy * vy
                let length = (ux * ux + uy * uy).squareRoot() * (vx * vx + vy * vy).squareRoot()
                var value = acos(max(-1, min(1, dot / length)))
                if ux * vy - uy * vx < 0 { value = -value }
                return value
            }

            let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
            var delta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)

            if !sweep && delta > 0 { delta -= 2 * Double.pi }
            if sweep && delta < 0 { delta += 2 * Double.pi }

            let segments = max(1, Int((abs(delta) / (Double.pi / 2)).rounded(.up)))
            let step = delta / Double(segments)
            let alpha = 4.0 / 3.0 * tan(step / 4)

            var angleStart = theta1
            for _ in 0..<segments {
                let angleEnd = angleStart + step

                let cosStart = cos(angleStart), sinStart = sin(angleStart)
                let cosEnd = cos(angleEnd), sinEnd = sin(angleEnd)

                // points of the unit circle, with the tangents at them
                let p1x = cosStart - alpha * sinStart
                let p1y = sinStart + alpha * cosStart
                let p2x = cosEnd + alpha * sinEnd
                let p2y = sinEnd - alpha * cosEnd

                func transform(_ x: Double, _ y: Double) -> CGPoint {
                    let scaledX = x * rx
                    let scaledY = y * ry
                    return CGPoint(
                        x: cosPhi * scaledX - sinPhi * scaledY + cx,
                        y: sinPhi * scaledX + cosPhi * scaledY + cy)
                }

                path.addCurve(
                    to: transform(cosEnd, sinEnd),
                    control1: transform(p1x, p1y),
                    control2: transform(p2x, p2y))

                angleStart = angleEnd
            }
        }
    }
}
#endif
