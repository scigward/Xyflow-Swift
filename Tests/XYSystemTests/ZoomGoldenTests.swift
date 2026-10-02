import XCTest
@testable import XYSystem

/// Calls and wheel events with random values: the transforms are the ones d3-zoom ends up with.
final class ZoomGoldenTests: XCTestCase {
    private typealias Object = [String: Any]

    private func number(_ value: Any?) -> Double {
        if let number = value as? NSNumber { return number.doubleValue }
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        XCTFail("not a number: \(String(describing: value))")
        return .nan
    }

    private func numbers(_ value: Any?) -> [Double] {
        ((value as? [Any]) ?? []).map { number($0) }
    }

    private func point(_ value: Any?) -> XYPosition? {
        guard let values = value as? [Any], values.count == 2 else { return nil }
        return XYPosition(x: number(values[0]), y: number(values[1]))
    }

    /// The scale is not limited in some of the scenarios and grows to huge numbers, where the last digits of `pow`
    /// of the two platforms differ: the numbers have to agree to nine digits.
    private func assertClose(_ actual: Double, _ expected: Double, _ label: String, line: UInt = #line) {
        let allowed = 1e-9 * max(1, abs(expected))
        XCTAssertEqual(actual, expected, accuracy: allowed, label, line: line)
    }

    func testTransformsAreTheOnesOfD3Zoom() throws {
        let data = Data(zoomGoldenJSON.utf8)
        let scenarios = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [Object])
        XCTAssertGreaterThan(scenarios.count, 20)

        var checked = 0

        for (index, scenario) in scenarios.enumerated() {
            let width = number(scenario["W"])
            let height = number(scenario["H"])
            let behavior = D3ZoomBehavior(extent: { CoordinateExtent(0, 0, width, height) })

            let scale = numbers(scenario["scaleExtent"])
            behavior.setScaleExtent((scale[0], scale[1]))

            if let pairs = scenario["translateExtent"] as? [[Any]] {
                let min = numbers(pairs[0])
                let max = numbers(pairs[1])
                behavior.setTranslateExtent(CoordinateExtent(min[0], min[1], max[0], max[1]))
            }

            for (opIndex, op) in (scenario["ops"] as! [Object]).enumerated() {
                let kind = op["op"] as! String
                let at = point(op["p"])
                let label = "\(kind) \(opIndex) of scenario \(index)"

                switch kind {
                case "scaleBy":
                    behavior.scaleBy(number(op["k"]), point: at)
                case "scaleTo":
                    behavior.scaleTo(number(op["k"]), point: at)
                case "translateBy":
                    behavior.translateBy(number(op["x"]), number(op["y"]))
                case "translateTo":
                    behavior.translateTo(number(op["x"]), number(op["y"]), point: at)
                case "transform":
                    behavior.applyTransform(
                        ZoomTransform.identity.translate(number(op["x"]), number(op["y"])).scale(number(op["k"])),
                        point: at)
                case "wheel":
                    let x = number(op["x"])
                    let y = number(op["y"])
                    behavior.wheeled(ZoomSourceEvent(
                        type: "wheel",
                        ctrlKey: (op["ctrlKey"] as? NSNumber)?.boolValue ?? (op["ctrlKey"] as? Bool) ?? false,
                        clientX: x,
                        clientY: y,
                        point: XYPosition(x: x, y: y),
                        deltaX: number(op["deltaX"]),
                        deltaY: number(op["deltaY"]),
                        deltaMode: Int(number(op["deltaMode"]))))
                default:
                    XCTFail("unknown operation \(kind)")
                }

                let expected = op["result"] as! Object
                assertClose(behavior.transform.k, number(expected["k"]), "k of \(label)")
                assertClose(behavior.transform.x, number(expected["x"]), "x of \(label)")
                assertClose(behavior.transform.y, number(expected["y"]), "y of \(label)")
                checked += 1
            }
        }

        XCTAssertGreaterThan(checked, 400)
    }
}
