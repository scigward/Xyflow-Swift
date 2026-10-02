#if canImport(CoreGraphics)
import XCTest
import CoreGraphics
@testable import Xyflow

final class SVGPathTests: XCTestCase {
    func testMoveAndLines() {
        let path = SVGPath.cgPath(from: "M10,20 L30,20 L30,50")

        XCTAssertEqual(path.boundingBox.minX, 10, accuracy: 1e-9)
        XCTAssertEqual(path.boundingBox.minY, 20, accuracy: 1e-9)
        XCTAssertEqual(path.boundingBox.maxX, 30, accuracy: 1e-9)
        XCTAssertEqual(path.boundingBox.maxY, 50, accuracy: 1e-9)
    }

    func testHorizontalAndVerticalLines() {
        let path = SVGPath.cgPath(from: "M0 0 H10 V5 h-4 v3")

        XCTAssertEqual(path.currentPoint.x, 6, accuracy: 1e-9)
        XCTAssertEqual(path.currentPoint.y, 8, accuracy: 1e-9)
    }

    func testRelativeCommands() {
        let path = SVGPath.cgPath(from: "m5 5 l10 0 l0 10")

        XCTAssertEqual(path.currentPoint.x, 15, accuracy: 1e-9)
        XCTAssertEqual(path.currentPoint.y, 15, accuracy: 1e-9)
    }

    func testNumbersWithoutSeparators() {
        let path = SVGPath.cgPath(from: "M10-20L-5.5.5")

        XCTAssertEqual(path.currentPoint.x, -5.5, accuracy: 1e-9)
        XCTAssertEqual(path.currentPoint.y, 0.5, accuracy: 1e-9)
    }

    func testCubicCurve() {
        let path = SVGPath.cgPath(from: "M10,20 C105,20 105,120 200,120")

        XCTAssertEqual(path.currentPoint.x, 200, accuracy: 1e-9)
        XCTAssertEqual(path.currentPoint.y, 120, accuracy: 1e-9)
    }

    func testSmoothCubicReflectsTheControlPoint() {
        let path = SVGPath.cgPath(from: "M0,0 C10,0 20,10 20,20 S30,40 40,40")

        XCTAssertEqual(path.currentPoint.x, 40, accuracy: 1e-9)
        XCTAssertEqual(path.currentPoint.y, 40, accuracy: 1e-9)
    }

    func testQuadraticCurves() {
        let path = SVGPath.cgPath(from: "M0,0 Q10,10 20,0 T40,0")

        XCTAssertEqual(path.currentPoint.x, 40, accuracy: 1e-9)
        XCTAssertEqual(path.currentPoint.y, 0, accuracy: 1e-9)
    }

    func testArcEndsWhereItIsToldTo() {
        let path = SVGPath.cgPath(from: "M10 10 A5 5 0 0 1 20 10")

        XCTAssertEqual(path.currentPoint.x, 20, accuracy: 1e-6)
        XCTAssertEqual(path.currentPoint.y, 10, accuracy: 1e-6)

        // a half circle of radius 5 over the points reaches 5 above or below them
        XCTAssertEqual(path.boundingBox.height, 5, accuracy: 0.2)
    }

    func testClosingGoesBackToTheStart() {
        let path = SVGPath.cgPath(from: "M1,1 L5,1 L5,5 Z")

        XCTAssertEqual(path.currentPoint.x, 1, accuracy: 1e-9)
        XCTAssertEqual(path.currentPoint.y, 1, accuracy: 1e-9)
    }

    func testGarbageEndsTheParsingButKeepsWhatWasRead() {
        let path = SVGPath.cgPath(from: "M0,0 L10,10 L")

        XCTAssertEqual(path.currentPoint.x, 10, accuracy: 1e-9)
    }

    func testEndsOfAStraightPath() {
        let ends = SVGPath.ends(of: SVGPath.cgPath(from: "M0,0 L10,0"))

        XCTAssertEqual(ends?.start, CGPoint(x: 0, y: 0))
        XCTAssertEqual(ends?.end, CGPoint(x: 10, y: 0))
        XCTAssertEqual(Double(ends?.startAngle ?? 1), 0, accuracy: 1e-9)
        XCTAssertEqual(Double(ends?.endAngle ?? 1), 0, accuracy: 1e-9)
    }

    func testEndsOfACurveFollowTheControlPoints() {
        // leaves the start going down and arrives going right
        let ends = SVGPath.ends(of: SVGPath.cgPath(from: "M0,0 C0,50 50,100 100,100"))

        XCTAssertEqual(Double(ends?.startAngle ?? 0), Double.pi / 2, accuracy: 1e-9)
        XCTAssertEqual(Double(ends?.endAngle ?? 1), 0, accuracy: 1e-9)
    }

    func testControlPointOnTheEndFallsBackToTheNextPoint() {
        // the first control point is on the start, the direction is then the one to the second
        let ends = SVGPath.ends(of: SVGPath.cgPath(from: "M0,0 C0,0 10,0 20,0"))

        XCTAssertEqual(Double(ends?.startAngle ?? 1), 0, accuracy: 1e-9)
    }

    func testEmptyPathHasNoEnds() {
        XCTAssertNil(SVGPath.ends(of: SVGPath.cgPath(from: "")))
    }
}
#endif
