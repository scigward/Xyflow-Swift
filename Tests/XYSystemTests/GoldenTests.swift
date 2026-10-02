import XCTest
@testable import XYSystem

/// Expected values come from running the same inputs through @xyflow/system 0.0.59.
final class GoldenTests: XCTestCase {
    func testBezierPaths() {
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .top, targetX: 200, targetY: 120, targetPosition: .top))
            XCTAssertEqual(r.path, "M10,20 C10,-42.5 200,70 200,120")
            XCTAssertEqual(r.labelX, 105, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 27.8125, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 7.8125, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .top, targetX: 200, targetY: 120, targetPosition: .top, curvature: 0.5))
            XCTAssertEqual(r.path, "M10,20 C10,-105 200,70 200,120")
            XCTAssertEqual(r.labelX, 105, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 4.375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 15.625, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .top, targetX: 200, targetY: 120, targetPosition: .right))
            XCTAssertEqual(r.path, "M10,20 C10,-42.5 286.1503047005639,120 200,120")
            XCTAssertEqual(r.labelX, 137.30636426271144, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 46.5625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 127.30636426271144, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 26.5625, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .top, targetX: 200, targetY: 120, targetPosition: .right, curvature: 0.5))
            XCTAssertEqual(r.path, "M10,20 C10,-105 372.30060940112776,120 200,120")
            XCTAssertEqual(r.labelX, 169.6127285254229, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 23.125, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 159.6127285254229, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 3.125, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .bottom, targetX: 200, targetY: 120, targetPosition: .left))
            XCTAssertEqual(r.path, "M10,20 C10,70 105,120 200,120")
            XCTAssertEqual(r.labelX, 69.375, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 88.75, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 59.375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 68.75, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .bottom, targetX: 200, targetY: 120, targetPosition: .left, curvature: 0.5))
            XCTAssertEqual(r.path, "M10,20 C10,70 105,120 200,120")
            XCTAssertEqual(r.labelX, 69.375, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 88.75, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 59.375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 68.75, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .left, targetX: 200, targetY: 120, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M10,20 C-76.15030470056388,20 200,182.5 200,120")
            XCTAssertEqual(r.labelX, 72.69363573728855, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 93.4375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 62.693635737288545, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 73.4375, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .left, targetX: 200, targetY: 120, targetPosition: .bottom, curvature: 0.5))
            XCTAssertEqual(r.path, "M10,20 C-162.30060940112776,20 200,245 200,120")
            XCTAssertEqual(r.labelX, 40.38727147457709, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 116.875, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 30.38727147457709, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 96.875, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .right, targetX: 200, targetY: 120, targetPosition: .top))
            XCTAssertEqual(r.path, "M10,20 C105,20 200,70 200,120")
            XCTAssertEqual(r.labelX, 140.625, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 51.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 130.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 31.25, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .right, targetX: 200, targetY: 120, targetPosition: .top, curvature: 0.5))
            XCTAssertEqual(r.path, "M10,20 C105,20 200,70 200,120")
            XCTAssertEqual(r.labelX, 140.625, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 51.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 130.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 31.25, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .right, targetX: 200, targetY: 120, targetPosition: .right))
            XCTAssertEqual(r.path, "M10,20 C105,20 286.1503047005639,120 200,120")
            XCTAssertEqual(r.labelX, 172.93136426271144, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 70, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 162.93136426271144, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 10, sourceY: 20, sourcePosition: .right, targetX: 200, targetY: 120, targetPosition: .right, curvature: 0.5))
            XCTAssertEqual(r.path, "M10,20 C105,20 372.30060940112776,120 200,120")
            XCTAssertEqual(r.labelX, 205.2377285254229, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 70, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 195.2377285254229, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 0, sourceY: 0, sourcePosition: .top, targetX: 100, targetY: 0, targetPosition: .left))
            XCTAssertEqual(r.path, "M0,0 C0,0 50,0 100,0")
            XCTAssertEqual(r.labelX, 31.25, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 31.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 0, sourceY: 0, sourcePosition: .top, targetX: 100, targetY: 0, targetPosition: .left, curvature: 0.5))
            XCTAssertEqual(r.path, "M0,0 C0,0 50,0 100,0")
            XCTAssertEqual(r.labelX, 31.25, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 31.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 0, sourceY: 0, sourcePosition: .bottom, targetX: 100, targetY: 0, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M0,0 C0,0 100,0 100,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 0, sourceY: 0, sourcePosition: .bottom, targetX: 100, targetY: 0, targetPosition: .bottom, curvature: 0.5))
            XCTAssertEqual(r.path, "M0,0 C0,0 100,0 100,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 0, sourceY: 0, sourcePosition: .left, targetX: 100, targetY: 0, targetPosition: .top))
            XCTAssertEqual(r.path, "M0,0 C-62.5,0 100,0 100,0")
            XCTAssertEqual(r.labelX, 26.5625, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 26.5625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 0, sourceY: 0, sourcePosition: .left, targetX: 100, targetY: 0, targetPosition: .top, curvature: 0.5))
            XCTAssertEqual(r.path, "M0,0 C-125,0 100,0 100,0")
            XCTAssertEqual(r.labelX, 3.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 3.125, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 0, sourceY: 0, sourcePosition: .left, targetX: 100, targetY: 0, targetPosition: .right))
            XCTAssertEqual(r.path, "M0,0 C-62.5,0 162.5,0 100,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 0, sourceY: 0, sourcePosition: .left, targetX: 100, targetY: 0, targetPosition: .right, curvature: 0.5))
            XCTAssertEqual(r.path, "M0,0 C-125,0 225,0 100,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 0, sourceY: 0, sourcePosition: .right, targetX: 100, targetY: 0, targetPosition: .left))
            XCTAssertEqual(r.path, "M0,0 C50,0 50,0 100,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 0, sourceY: 0, sourcePosition: .right, targetX: 100, targetY: 0, targetPosition: .left, curvature: 0.5))
            XCTAssertEqual(r.path, "M0,0 C50,0 50,0 100,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 100, sourceY: 100, sourcePosition: .top, targetX: 0, targetY: 0, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M100,100 C100,50 0,50 0,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 100, sourceY: 100, sourcePosition: .top, targetX: 0, targetY: 0, targetPosition: .bottom, curvature: 0.5))
            XCTAssertEqual(r.path, "M100,100 C100,50 0,50 0,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 100, sourceY: 100, sourcePosition: .bottom, targetX: 0, targetY: 0, targetPosition: .top))
            XCTAssertEqual(r.path, "M100,100 C100,162.5 0,-62.5 0,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 100, sourceY: 100, sourcePosition: .bottom, targetX: 0, targetY: 0, targetPosition: .top, curvature: 0.5))
            XCTAssertEqual(r.path, "M100,100 C100,225 0,-125 0,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 100, sourceY: 100, sourcePosition: .bottom, targetX: 0, targetY: 0, targetPosition: .right))
            XCTAssertEqual(r.path, "M100,100 C100,162.5 50,0 0,0")
            XCTAssertEqual(r.labelX, 68.75, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 73.4375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 31.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 26.5625, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 100, sourceY: 100, sourcePosition: .bottom, targetX: 0, targetY: 0, targetPosition: .right, curvature: 0.5))
            XCTAssertEqual(r.path, "M100,100 C100,225 50,0 0,0")
            XCTAssertEqual(r.labelX, 68.75, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 96.875, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 31.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 3.125, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 100, sourceY: 100, sourcePosition: .left, targetX: 0, targetY: 0, targetPosition: .left))
            XCTAssertEqual(r.path, "M100,100 C50,100 -62.5,0 0,0")
            XCTAssertEqual(r.labelX, 7.8125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 92.1875, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 100, sourceY: 100, sourcePosition: .left, targetX: 0, targetY: 0, targetPosition: .left, curvature: 0.5))
            XCTAssertEqual(r.path, "M100,100 C50,100 -125,0 0,0")
            XCTAssertEqual(r.labelX, -15.625, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 115.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 100, sourceY: 100, sourcePosition: .right, targetX: 0, targetY: 0, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M100,100 C162.5,100 0,50 0,0")
            XCTAssertEqual(r.labelX, 73.4375, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 68.75, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 26.5625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 31.25, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 100, sourceY: 100, sourcePosition: .right, targetX: 0, targetY: 0, targetPosition: .bottom, curvature: 0.5))
            XCTAssertEqual(r.path, "M100,100 C225,100 0,50 0,0")
            XCTAssertEqual(r.labelX, 96.875, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 68.75, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 3.125, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 31.25, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .top, targetX: 120.75, targetY: -60, targetPosition: .top))
            XCTAssertEqual(r.path, "M-40.5,33.25 C-40.5,-13.375 120.75,-120.3537747369624 120.75,-60")
            XCTAssertEqual(r.labelX, 40.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -53.492040526360896, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 86.7420405263609, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .top, targetX: 120.75, targetY: -60, targetPosition: .top, curvature: 0.5))
            XCTAssertEqual(r.path, "M-40.5,33.25 C-40.5,-13.375 120.75,-180.7075494739248 120.75,-60")
            XCTAssertEqual(r.labelX, 40.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -76.12470605272179, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 109.37470605272179, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .top, targetX: 120.75, targetY: -60, targetPosition: .right))
            XCTAssertEqual(r.path, "M-40.5,33.25 C-40.5,-13.375 200.11515687000184,-60 120.75,-60")
            XCTAssertEqual(r.labelX, 69.8869338262507, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -30.859375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 110.3869338262507, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 64.109375, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .top, targetX: 120.75, targetY: -60, targetPosition: .right, curvature: 0.5))
            XCTAssertEqual(r.path, "M-40.5,33.25 C-40.5,-13.375 279.4803137400037,-60 120.75,-60")
            XCTAssertEqual(r.labelX, 99.64886765250138, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -30.859375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140.1488676525014, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 64.109375, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .bottom, targetX: 120.75, targetY: -60, targetPosition: .left))
            XCTAssertEqual(r.path, "M-40.5,33.25 C-40.5,93.6037747369624 40.125,-60 120.75,-60")
            XCTAssertEqual(r.labelX, 9.890625, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 9.257665526360896, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50.390625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 23.992334473639104, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .bottom, targetX: 120.75, targetY: -60, targetPosition: .left, curvature: 0.5))
            XCTAssertEqual(r.path, "M-40.5,33.25 C-40.5,153.9575494739248 40.125,-60 120.75,-60")
            XCTAssertEqual(r.labelX, 9.890625, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 31.89033105272179, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50.390625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 1.3596689472782089, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .left, targetX: 120.75, targetY: -60, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M-40.5,33.25 C-119.86515687000184,33.25 120.75,-13.375 120.75,-60")
            XCTAssertEqual(r.labelX, 10.36306617374931, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 4.109375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50.86306617374931, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 29.140625, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .left, targetX: 120.75, targetY: -60, targetPosition: .bottom, curvature: 0.5))
            XCTAssertEqual(r.path, "M-40.5,33.25 C-199.23031374000368,33.25 120.75,-13.375 120.75,-60")
            XCTAssertEqual(r.labelX, -19.39886765250138, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 4.109375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 21.10113234749862, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 29.140625, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .right, targetX: 120.75, targetY: -60, targetPosition: .top))
            XCTAssertEqual(r.path, "M-40.5,33.25 C40.125,33.25 120.75,-120.3537747369624 120.75,-60")
            XCTAssertEqual(r.labelX, 70.359375, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -36.007665526360896, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 110.859375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 69.2576655263609, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .right, targetX: 120.75, targetY: -60, targetPosition: .top, curvature: 0.5))
            XCTAssertEqual(r.path, "M-40.5,33.25 C40.125,33.25 120.75,-180.7075494739248 120.75,-60")
            XCTAssertEqual(r.labelX, 70.359375, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -58.64033105272179, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 110.859375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 91.89033105272179, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .right, targetX: 120.75, targetY: -60, targetPosition: .right))
            XCTAssertEqual(r.path, "M-40.5,33.25 C40.125,33.25 200.11515687000184,-60 120.75,-60")
            XCTAssertEqual(r.labelX, 100.1213088262507, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -13.375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140.6213088262507, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .right, targetX: 120.75, targetY: -60, targetPosition: .right, curvature: 0.5))
            XCTAssertEqual(r.path, "M-40.5,33.25 C40.125,33.25 279.4803137400037,-60 120.75,-60")
            XCTAssertEqual(r.labelX, 129.8832426525014, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -13.375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 170.3832426525014, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 5, sourceY: 5, sourcePosition: .top, targetX: 5, targetY: 80, targetPosition: .left))
            XCTAssertEqual(r.path, "M5,5 C5,-49.12658773652742 5,80 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 22.20252959880222, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 17.20252959880222, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 5, sourceY: 5, sourcePosition: .top, targetX: 5, targetY: 80, targetPosition: .left, curvature: 0.5))
            XCTAssertEqual(r.path, "M5,5 C5,-103.25317547305484 5,80 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 1.9050591976044373, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 3.0949408023955627, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 5, sourceY: 5, sourcePosition: .bottom, targetX: 5, targetY: 80, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M5,5 C5,42.5 5,134.12658773652743 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 76.85997040119778, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 71.85997040119778, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 5, sourceY: 5, sourcePosition: .bottom, targetX: 5, targetY: 80, targetPosition: .bottom, curvature: 0.5))
            XCTAssertEqual(r.path, "M5,5 C5,42.5 5,188.25317547305485 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 97.15744080239557, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 92.15744080239557, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 5, sourceY: 5, sourcePosition: .left, targetX: 5, targetY: 80, targetPosition: .top))
            XCTAssertEqual(r.path, "M5,5 C5,5 5,42.5 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 28.4375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 23.4375, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 5, sourceY: 5, sourcePosition: .left, targetX: 5, targetY: 80, targetPosition: .top, curvature: 0.5))
            XCTAssertEqual(r.path, "M5,5 C5,5 5,42.5 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 28.4375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 23.4375, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 5, sourceY: 5, sourcePosition: .left, targetX: 5, targetY: 80, targetPosition: .right))
            XCTAssertEqual(r.path, "M5,5 C5,5 5,80 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 5, sourceY: 5, sourcePosition: .left, targetX: 5, targetY: 80, targetPosition: .right, curvature: 0.5))
            XCTAssertEqual(r.path, "M5,5 C5,5 5,80 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 5, sourceY: 5, sourcePosition: .right, targetX: 5, targetY: 80, targetPosition: .left))
            XCTAssertEqual(r.path, "M5,5 C5,5 5,80 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 5, sourceY: 5, sourcePosition: .right, targetX: 5, targetY: 80, targetPosition: .left, curvature: 0.5))
            XCTAssertEqual(r.path, "M5,5 C5,5 5,80 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 300, sourceY: 10, sourcePosition: .top, targetX: 20, targetY: 10.5, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M300,10 C300,5.580582617584078 20,14.919417382415922 20,10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 300, sourceY: 10, sourcePosition: .top, targetX: 20, targetY: 10.5, targetPosition: .bottom, curvature: 0.5))
            XCTAssertEqual(r.path, "M300,10 C300,1.1611652351681556 20,19.338834764831844 20,10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 300, sourceY: 10, sourcePosition: .bottom, targetX: 20, targetY: 10.5, targetPosition: .top))
            XCTAssertEqual(r.path, "M300,10 C300,10.25 20,10.25 20,10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 300, sourceY: 10, sourcePosition: .bottom, targetX: 20, targetY: 10.5, targetPosition: .top, curvature: 0.5))
            XCTAssertEqual(r.path, "M300,10 C300,10.25 20,10.25 20,10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 300, sourceY: 10, sourcePosition: .bottom, targetX: 20, targetY: 10.5, targetPosition: .right))
            XCTAssertEqual(r.path, "M300,10 C300,10.25 160,10.5 20,10.5")
            XCTAssertEqual(r.labelX, 212.5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.34375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 87.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.34375, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 300, sourceY: 10, sourcePosition: .bottom, targetX: 20, targetY: 10.5, targetPosition: .right, curvature: 0.5))
            XCTAssertEqual(r.path, "M300,10 C300,10.25 160,10.5 20,10.5")
            XCTAssertEqual(r.labelX, 212.5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.34375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 87.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.34375, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 300, sourceY: 10, sourcePosition: .left, targetX: 20, targetY: 10.5, targetPosition: .left))
            XCTAssertEqual(r.path, "M300,10 C160,10 -84.58250331675944,10.5 20,10.5")
            XCTAssertEqual(r.labelX, 68.28156125621521, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 231.7184387437848, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 300, sourceY: 10, sourcePosition: .left, targetX: 20, targetY: 10.5, targetPosition: .left, curvature: 0.5))
            XCTAssertEqual(r.path, "M300,10 C160,10 -189.16500663351889,10.5 20,10.5")
            XCTAssertEqual(r.labelX, 29.063122512430425, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 270.9368774875696, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 300, sourceY: 10, sourcePosition: .right, targetX: 20, targetY: 10.5, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M300,10 C404.58250331675947,10 20,14.919417382415922 20,10.5")
            XCTAssertEqual(r.labelX, 199.21843874378482, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 11.90728151840597, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 100.78156125621518, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 1.90728151840597, accuracy: 1e-9)
        }
        do {
            let r = getBezierPath(GetBezierPathParams(sourceX: 300, sourceY: 10, sourcePosition: .right, targetX: 20, targetY: 10.5, targetPosition: .bottom, curvature: 0.5))
            XCTAssertEqual(r.path, "M300,10 C509.1650066335189,10 20,19.338834764831844 20,10.5")
            XCTAssertEqual(r.labelX, 238.43687748756957, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 13.564563036811942, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 61.563122512430425, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 3.5645630368119416, accuracy: 1e-9)
        }
    }

    func testSmoothStepPaths() {
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .top, targetX: 200, targetY: 120, targetPosition: .top))
            XCTAssertEqual(r.path, "M10 20L 10,5Q 10,0 15,0L 195,0Q 200,0 200,5L200 100L200 120")
            XCTAssertEqual(r.labelX, 105, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .top, targetX: 200, targetY: 120, targetPosition: .top, borderRadius: 0))
            XCTAssertEqual(r.path, "M10 20L 10,0Q 10,0 10,0L 200,0Q 200,0 200,0L200 100L200 120")
            XCTAssertEqual(r.labelX, 105, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .top, targetX: 200, targetY: 120, targetPosition: .top, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M10 20L 10,2Q 10,-10 22,-10L 188,-10Q 200,-10 200,2L200 90L200 120")
            XCTAssertEqual(r.labelX, 105, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -10, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .top, targetX: 200, targetY: 120, targetPosition: .right))
            XCTAssertEqual(r.path, "M10 20L 10,5Q 10,0 15,0L 215,0Q 220,0 220,5L 220,115Q 220,120 215,120L200 120")
            XCTAssertEqual(r.labelX, 115, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .top, targetX: 200, targetY: 120, targetPosition: .right, borderRadius: 0))
            XCTAssertEqual(r.path, "M10 20L 10,0Q 10,0 10,0L 220,0Q 220,0 220,0L 220,120Q 220,120 220,120L200 120")
            XCTAssertEqual(r.labelX, 115, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .top, targetX: 200, targetY: 120, targetPosition: .right, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M10 20L 10,2Q 10,-10 22,-10L 218,-10Q 230,-10 230,2L 230,108Q 230,120 218,120L200 120")
            XCTAssertEqual(r.labelX, 120, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -10, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .bottom, targetX: 200, targetY: 120, targetPosition: .left))
            XCTAssertEqual(r.path, "M10 20L10 40L 10,115Q 10,120 15,120L180 120L200 120")
            XCTAssertEqual(r.labelX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 120, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .bottom, targetX: 200, targetY: 120, targetPosition: .left, borderRadius: 0))
            XCTAssertEqual(r.path, "M10 20L10 40L 10,120Q 10,120 10,120L180 120L200 120")
            XCTAssertEqual(r.labelX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 120, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .bottom, targetX: 200, targetY: 120, targetPosition: .left, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M10 20L10 50L 10,108Q 10,120 22,120L170 120L200 120")
            XCTAssertEqual(r.labelX, 90, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 120, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .left, targetX: 200, targetY: 120, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M10 20L -5,20Q -10,20 -10,25L -10,135Q -10,140 -5,140L 195,140Q 200,140 200,135L200 120")
            XCTAssertEqual(r.labelX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .left, targetX: 200, targetY: 120, targetPosition: .bottom, borderRadius: 0))
            XCTAssertEqual(r.path, "M10 20L -10,20Q -10,20 -10,20L -10,140Q -10,140 -10,140L 200,140Q 200,140 200,140L200 120")
            XCTAssertEqual(r.labelX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .left, targetX: 200, targetY: 120, targetPosition: .bottom, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M10 20L -8,20Q -20,20 -20,32L -20,138Q -20,150 -8,150L 188,150Q 200,150 200,138L200 120")
            XCTAssertEqual(r.labelX, 90, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 150, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .right, targetX: 200, targetY: 120, targetPosition: .top))
            XCTAssertEqual(r.path, "M10 20L30 20L 195,20Q 200,20 200,25L200 100L200 120")
            XCTAssertEqual(r.labelX, 115, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .right, targetX: 200, targetY: 120, targetPosition: .top, borderRadius: 0))
            XCTAssertEqual(r.path, "M10 20L30 20L 200,20Q 200,20 200,20L200 100L200 120")
            XCTAssertEqual(r.labelX, 115, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .right, targetX: 200, targetY: 120, targetPosition: .top, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M10 20L40 20L 188,20Q 200,20 200,32L200 90L200 120")
            XCTAssertEqual(r.labelX, 120, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .right, targetX: 200, targetY: 120, targetPosition: .right))
            XCTAssertEqual(r.path, "M10 20L30 20L 215,20Q 220,20 220,25L 220,115Q 220,120 215,120L200 120")
            XCTAssertEqual(r.labelX, 125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .right, targetX: 200, targetY: 120, targetPosition: .right, borderRadius: 0))
            XCTAssertEqual(r.path, "M10 20L30 20L 220,20Q 220,20 220,20L 220,120Q 220,120 220,120L200 120")
            XCTAssertEqual(r.labelX, 125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 10, sourceY: 20, sourcePosition: .right, targetX: 200, targetY: 120, targetPosition: .right, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M10 20L40 20L 218,20Q 230,20 230,32L 230,108Q 230,120 218,120L200 120")
            XCTAssertEqual(r.labelX, 135, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .top, targetX: 100, targetY: 0, targetPosition: .left))
            XCTAssertEqual(r.path, "M0 0L 0,-15Q 0,-20 5,-20L 75,-20Q 80,-20 80,-15L 80,-5Q 80,0 85,0L100 0")
            XCTAssertEqual(r.labelX, 40, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .top, targetX: 100, targetY: 0, targetPosition: .left, borderRadius: 0))
            XCTAssertEqual(r.path, "M0 0L 0,-20Q 0,-20 0,-20L 80,-20Q 80,-20 80,-20L 80,0Q 80,0 80,0L100 0")
            XCTAssertEqual(r.labelX, 40, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .top, targetX: 100, targetY: 0, targetPosition: .left, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M0 0L 0,-18Q 0,-30 12,-30L 58,-30Q 70,-30 70,-18L 70,-12Q 70,0 82,0L100 0")
            XCTAssertEqual(r.labelX, 35, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -30, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .bottom, targetX: 100, targetY: 0, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M0 0L 0,15Q 0,20 5,20L 95,20Q 100,20 100,15L100 1L100 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .bottom, targetX: 100, targetY: 0, targetPosition: .bottom, borderRadius: 0))
            XCTAssertEqual(r.path, "M0 0L 0,20Q 0,20 0,20L 100,20Q 100,20 100,20L100 1L100 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .bottom, targetX: 100, targetY: 0, targetPosition: .bottom, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M0 0L 0,18Q 0,30 12,30L 88,30Q 100,30 100,18L100 1L100 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 30, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .left, targetX: 100, targetY: 0, targetPosition: .top))
            XCTAssertEqual(r.path, "M0 0L -15,0Q -20,0 -20,-5L -20,-15Q -20,-20 -15,-20L 95,-20Q 100,-20 100,-15L100 0")
            XCTAssertEqual(r.labelX, 40, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .left, targetX: 100, targetY: 0, targetPosition: .top, borderRadius: 0))
            XCTAssertEqual(r.path, "M0 0L -20,0Q -20,0 -20,0L -20,-20Q -20,-20 -20,-20L 100,-20Q 100,-20 100,-20L100 0")
            XCTAssertEqual(r.labelX, 40, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .left, targetX: 100, targetY: 0, targetPosition: .top, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M0 0L -18,0Q -30,0 -30,-12L -30,-18Q -30,-30 -18,-30L 88,-30Q 100,-30 100,-18L100 0")
            XCTAssertEqual(r.labelX, 35, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -30, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .left, targetX: 100, targetY: 0, targetPosition: .right))
            XCTAssertEqual(r.path, "M0 0L-20 0L-20 0L120 0L120 0L100 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .left, targetX: 100, targetY: 0, targetPosition: .right, borderRadius: 0))
            XCTAssertEqual(r.path, "M0 0L-20 0L-20 0L120 0L120 0L100 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .left, targetX: 100, targetY: 0, targetPosition: .right, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M0 0L-30 0L-30 0L130 0L130 0L100 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .right, targetX: 100, targetY: 0, targetPosition: .left))
            XCTAssertEqual(r.path, "M0 0L20 0L50 0L50 0L80 0L100 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .right, targetX: 100, targetY: 0, targetPosition: .left, borderRadius: 0))
            XCTAssertEqual(r.path, "M0 0L20 0L50 0L50 0L80 0L100 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 0, sourceY: 0, sourcePosition: .right, targetX: 100, targetY: 0, targetPosition: .left, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M0 0L30 0L50 0L50 0L70 0L100 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .top, targetX: 0, targetY: 0, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M100 100L100 80L 100,55Q 100,50 95,50L 5,50Q 0,50 0,45L0 20L0 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .top, targetX: 0, targetY: 0, targetPosition: .bottom, borderRadius: 0))
            XCTAssertEqual(r.path, "M100 100L100 80L 100,50Q 100,50 100,50L 0,50Q 0,50 0,50L0 20L0 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .top, targetX: 0, targetY: 0, targetPosition: .bottom, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M100 100L100 70L 100,60Q 100,50 90,50L 10,50Q 0,50 0,40L0 30L0 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .bottom, targetX: 0, targetY: 0, targetPosition: .top))
            XCTAssertEqual(r.path, "M100 100L 100,115Q 100,120 95,120L 55,120Q 50,120 50,115L 50,-15Q 50,-20 45,-20L 5,-20Q 0,-20 0,-15L0 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .bottom, targetX: 0, targetY: 0, targetPosition: .top, borderRadius: 0))
            XCTAssertEqual(r.path, "M100 100L 100,120Q 100,120 100,120L 50,120Q 50,120 50,120L 50,-20Q 50,-20 50,-20L 0,-20Q 0,-20 0,-20L0 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .bottom, targetX: 0, targetY: 0, targetPosition: .top, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M100 100L 100,118Q 100,130 88,130L 62,130Q 50,130 50,118L 50,-18Q 50,-30 38,-30L 12,-30Q 0,-30 0,-18L0 0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .bottom, targetX: 0, targetY: 0, targetPosition: .right))
            XCTAssertEqual(r.path, "M100 100L 100,115Q 100,120 95,120L 25,120Q 20,120 20,115L 20,5Q 20,0 15,0L0 0")
            XCTAssertEqual(r.labelX, 20, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 60, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .bottom, targetX: 0, targetY: 0, targetPosition: .right, borderRadius: 0))
            XCTAssertEqual(r.path, "M100 100L 100,120Q 100,120 100,120L 20,120Q 20,120 20,120L 20,0Q 20,0 20,0L0 0")
            XCTAssertEqual(r.labelX, 20, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 60, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .bottom, targetX: 0, targetY: 0, targetPosition: .right, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M100 100L 100,118Q 100,130 88,130L 42,130Q 30,130 30,118L 30,12Q 30,0 18,0L0 0")
            XCTAssertEqual(r.labelX, 30, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 65, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .left, targetX: 0, targetY: 0, targetPosition: .left))
            XCTAssertEqual(r.path, "M100 100L80 100L -15,100Q -20,100 -20,95L -20,5Q -20,0 -15,0L0 0")
            XCTAssertEqual(r.labelX, 30, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 100, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .left, targetX: 0, targetY: 0, targetPosition: .left, borderRadius: 0))
            XCTAssertEqual(r.path, "M100 100L80 100L -20,100Q -20,100 -20,100L -20,0Q -20,0 -20,0L0 0")
            XCTAssertEqual(r.labelX, 30, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 100, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .left, targetX: 0, targetY: 0, targetPosition: .left, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M100 100L70 100L -18,100Q -30,100 -30,88L -30,12Q -30,0 -18,0L0 0")
            XCTAssertEqual(r.labelX, 20, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 100, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .right, targetX: 0, targetY: 0, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M100 100L 115,100Q 120,100 120,95L 120,25Q 120,20 115,20L 5,20Q 0,20 0,15L0 0")
            XCTAssertEqual(r.labelX, 60, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .right, targetX: 0, targetY: 0, targetPosition: .bottom, borderRadius: 0))
            XCTAssertEqual(r.path, "M100 100L 120,100Q 120,100 120,100L 120,20Q 120,20 120,20L 0,20Q 0,20 0,20L0 0")
            XCTAssertEqual(r.labelX, 60, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 20, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 100, sourceY: 100, sourcePosition: .right, targetX: 0, targetY: 0, targetPosition: .bottom, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M100 100L 118,100Q 130,100 130,88L 130,42Q 130,30 118,30L 12,30Q 0,30 0,18L0 0")
            XCTAssertEqual(r.labelX, 65, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 30, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .top, targetX: 120.75, targetY: -60, targetPosition: .top))
            XCTAssertEqual(r.path, "M-40.5 33.25L-40.5 13.25L -40.5,-75Q -40.5,-80 -35.5,-80L 115.75,-80Q 120.75,-80 120.75,-75L120.75 -60")
            XCTAssertEqual(r.labelX, 40.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -80, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .top, targetX: 120.75, targetY: -60, targetPosition: .top, borderRadius: 0))
            XCTAssertEqual(r.path, "M-40.5 33.25L-40.5 13.25L -40.5,-80Q -40.5,-80 -40.5,-80L 120.75,-80Q 120.75,-80 120.75,-80L120.75 -60")
            XCTAssertEqual(r.labelX, 40.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -80, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .top, targetX: 120.75, targetY: -60, targetPosition: .top, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M-40.5 33.25L-40.5 3.25L -40.5,-78Q -40.5,-90 -28.5,-90L 108.75,-90Q 120.75,-90 120.75,-78L120.75 -60")
            XCTAssertEqual(r.labelX, 40.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -90, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .top, targetX: 120.75, targetY: -60, targetPosition: .right))
            XCTAssertEqual(r.path, "M-40.5 33.25L -40.5,18.25Q -40.5,13.25 -35.5,13.25L 135.75,13.25Q 140.75,13.25 140.75,8.25L 140.75,-55Q 140.75,-60 135.75,-60L120.75 -60")
            XCTAssertEqual(r.labelX, 50.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 13.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .top, targetX: 120.75, targetY: -60, targetPosition: .right, borderRadius: 0))
            XCTAssertEqual(r.path, "M-40.5 33.25L -40.5,13.25Q -40.5,13.25 -40.5,13.25L 140.75,13.25Q 140.75,13.25 140.75,13.25L 140.75,-60Q 140.75,-60 140.75,-60L120.75 -60")
            XCTAssertEqual(r.labelX, 50.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 13.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .top, targetX: 120.75, targetY: -60, targetPosition: .right, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M-40.5 33.25L -40.5,15.25Q -40.5,3.25 -28.5,3.25L 138.75,3.25Q 150.75,3.25 150.75,-8.75L 150.75,-48Q 150.75,-60 138.75,-60L120.75 -60")
            XCTAssertEqual(r.labelX, 55.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 3.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .bottom, targetX: 120.75, targetY: -60, targetPosition: .left))
            XCTAssertEqual(r.path, "M-40.5 33.25L -40.5,48.25Q -40.5,53.25 -35.5,53.25L 95.75,53.25Q 100.75,53.25 100.75,48.25L 100.75,-55Q 100.75,-60 105.75,-60L120.75 -60")
            XCTAssertEqual(r.labelX, 30.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 53.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .bottom, targetX: 120.75, targetY: -60, targetPosition: .left, borderRadius: 0))
            XCTAssertEqual(r.path, "M-40.5 33.25L -40.5,53.25Q -40.5,53.25 -40.5,53.25L 100.75,53.25Q 100.75,53.25 100.75,53.25L 100.75,-60Q 100.75,-60 100.75,-60L120.75 -60")
            XCTAssertEqual(r.labelX, 30.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 53.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .bottom, targetX: 120.75, targetY: -60, targetPosition: .left, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M-40.5 33.25L -40.5,51.25Q -40.5,63.25 -28.5,63.25L 78.75,63.25Q 90.75,63.25 90.75,51.25L 90.75,-48Q 90.75,-60 102.75,-60L120.75 -60")
            XCTAssertEqual(r.labelX, 25.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 63.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .left, targetX: 120.75, targetY: -60, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M-40.5 33.25L -55.5,33.25Q -60.5,33.25 -60.5,28.25L -60.5,-35Q -60.5,-40 -55.5,-40L 115.75,-40Q 120.75,-40 120.75,-45L120.75 -60")
            XCTAssertEqual(r.labelX, 30.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -40, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .left, targetX: 120.75, targetY: -60, targetPosition: .bottom, borderRadius: 0))
            XCTAssertEqual(r.path, "M-40.5 33.25L -60.5,33.25Q -60.5,33.25 -60.5,33.25L -60.5,-40Q -60.5,-40 -60.5,-40L 120.75,-40Q 120.75,-40 120.75,-40L120.75 -60")
            XCTAssertEqual(r.labelX, 30.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -40, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .left, targetX: 120.75, targetY: -60, targetPosition: .bottom, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M-40.5 33.25L -58.5,33.25Q -70.5,33.25 -70.5,21.25L -70.5,-18Q -70.5,-30 -58.5,-30L 108.75,-30Q 120.75,-30 120.75,-42L120.75 -60")
            XCTAssertEqual(r.labelX, 25.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -30, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .right, targetX: 120.75, targetY: -60, targetPosition: .top))
            XCTAssertEqual(r.path, "M-40.5 33.25L -25.5,33.25Q -20.5,33.25 -20.5,28.25L -20.5,-75Q -20.5,-80 -15.5,-80L 115.75,-80Q 120.75,-80 120.75,-75L120.75 -60")
            XCTAssertEqual(r.labelX, 50.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -80, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .right, targetX: 120.75, targetY: -60, targetPosition: .top, borderRadius: 0))
            XCTAssertEqual(r.path, "M-40.5 33.25L -20.5,33.25Q -20.5,33.25 -20.5,33.25L -20.5,-80Q -20.5,-80 -20.5,-80L 120.75,-80Q 120.75,-80 120.75,-80L120.75 -60")
            XCTAssertEqual(r.labelX, 50.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -80, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .right, targetX: 120.75, targetY: -60, targetPosition: .top, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M-40.5 33.25L -22.5,33.25Q -10.5,33.25 -10.5,21.25L -10.5,-78Q -10.5,-90 1.5,-90L 108.75,-90Q 120.75,-90 120.75,-78L120.75 -60")
            XCTAssertEqual(r.labelX, 55.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -90, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .right, targetX: 120.75, targetY: -60, targetPosition: .right))
            XCTAssertEqual(r.path, "M-40.5 33.25L-20.5 33.25L 135.75,33.25Q 140.75,33.25 140.75,28.25L 140.75,-55Q 140.75,-60 135.75,-60L120.75 -60")
            XCTAssertEqual(r.labelX, 60.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 33.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .right, targetX: 120.75, targetY: -60, targetPosition: .right, borderRadius: 0))
            XCTAssertEqual(r.path, "M-40.5 33.25L-20.5 33.25L 140.75,33.25Q 140.75,33.25 140.75,33.25L 140.75,-60Q 140.75,-60 140.75,-60L120.75 -60")
            XCTAssertEqual(r.labelX, 60.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 33.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: -40.5, sourceY: 33.25, sourcePosition: .right, targetX: 120.75, targetY: -60, targetPosition: .right, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M-40.5 33.25L-10.5 33.25L 138.75,33.25Q 150.75,33.25 150.75,21.25L 150.75,-48Q 150.75,-60 138.75,-60L120.75 -60")
            XCTAssertEqual(r.labelX, 70.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 33.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .top, targetX: 5, targetY: 80, targetPosition: .left))
            XCTAssertEqual(r.path, "M5 5L 5,-10Q 5,-15 0,-15L -10,-15Q -15,-15 -15,-10L -15,75Q -15,80 -10,80L5 80")
            XCTAssertEqual(r.labelX, -15, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 32.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .top, targetX: 5, targetY: 80, targetPosition: .left, borderRadius: 0))
            XCTAssertEqual(r.path, "M5 5L 5,-15Q 5,-15 5,-15L -15,-15Q -15,-15 -15,-15L -15,80Q -15,80 -15,80L5 80")
            XCTAssertEqual(r.labelX, -15, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 32.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .top, targetX: 5, targetY: 80, targetPosition: .left, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M5 5L 5,-13Q 5,-25 -7,-25L -13,-25Q -25,-25 -25,-13L -25,68Q -25,80 -13,80L5 80")
            XCTAssertEqual(r.labelX, -25, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 27.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .bottom, targetX: 5, targetY: 80, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M5 5L5 25L5 100L5 100L5 80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 62.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .bottom, targetX: 5, targetY: 80, targetPosition: .bottom, borderRadius: 0))
            XCTAssertEqual(r.path, "M5 5L5 25L5 100L5 100L5 80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 62.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .bottom, targetX: 5, targetY: 80, targetPosition: .bottom, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M5 5L5 35L5 110L5 110L5 80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 72.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .left, targetX: 5, targetY: 80, targetPosition: .top))
            XCTAssertEqual(r.path, "M5 5L -10,5Q -15,5 -15,10L -15,55Q -15,60 -10,60L 0,60Q 5,60 5,65L5 80")
            XCTAssertEqual(r.labelX, -15, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 32.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .left, targetX: 5, targetY: 80, targetPosition: .top, borderRadius: 0))
            XCTAssertEqual(r.path, "M5 5L -15,5Q -15,5 -15,5L -15,60Q -15,60 -15,60L 5,60Q 5,60 5,60L5 80")
            XCTAssertEqual(r.labelX, -15, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 32.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .left, targetX: 5, targetY: 80, targetPosition: .top, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M5 5L -13,5Q -25,5 -25,17L -25,38Q -25,50 -13,50L -7,50Q 5,50 5,62L5 80")
            XCTAssertEqual(r.labelX, -25, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 27.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .left, targetX: 5, targetY: 80, targetPosition: .right))
            XCTAssertEqual(r.path, "M5 5L -10,5Q -15,5 -15,10L -15,37.5Q -15,42.5 -10,42.5L 20,42.5Q 25,42.5 25,47.5L 25,75Q 25,80 20,80L5 80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .left, targetX: 5, targetY: 80, targetPosition: .right, borderRadius: 0))
            XCTAssertEqual(r.path, "M5 5L -15,5Q -15,5 -15,5L -15,42.5Q -15,42.5 -15,42.5L 25,42.5Q 25,42.5 25,42.5L 25,80Q 25,80 25,80L5 80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .left, targetX: 5, targetY: 80, targetPosition: .right, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M5 5L -13,5Q -25,5 -25,17L -25,30.5Q -25,42.5 -13,42.5L 23,42.5Q 35,42.5 35,54.5L 35,68Q 35,80 23,80L5 80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .right, targetX: 5, targetY: 80, targetPosition: .left))
            XCTAssertEqual(r.path, "M5 5L 20,5Q 25,5 25,10L 25,37.5Q 25,42.5 20,42.5L -10,42.5Q -15,42.5 -15,47.5L -15,75Q -15,80 -10,80L5 80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .right, targetX: 5, targetY: 80, targetPosition: .left, borderRadius: 0))
            XCTAssertEqual(r.path, "M5 5L 25,5Q 25,5 25,5L 25,42.5Q 25,42.5 25,42.5L -15,42.5Q -15,42.5 -15,42.5L -15,80Q -15,80 -15,80L5 80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 5, sourceY: 5, sourcePosition: .right, targetX: 5, targetY: 80, targetPosition: .left, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M5 5L 23,5Q 35,5 35,17L 35,30.5Q 35,42.5 23,42.5L -13,42.5Q -25,42.5 -25,54.5L -25,68Q -25,80 -13,80L5 80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .top, targetX: 20, targetY: 10.5, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M300 10L 300,-5Q 300,-10 295,-10L 165,-10Q 160,-10 160,-5L 160,25.5Q 160,30.5 155,30.5L 25,30.5Q 20,30.5 20,25.5L20 10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .top, targetX: 20, targetY: 10.5, targetPosition: .bottom, borderRadius: 0))
            XCTAssertEqual(r.path, "M300 10L 300,-10Q 300,-10 300,-10L 160,-10Q 160,-10 160,-10L 160,30.5Q 160,30.5 160,30.5L 20,30.5Q 20,30.5 20,30.5L20 10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .top, targetX: 20, targetY: 10.5, targetPosition: .bottom, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M300 10L 300,-8Q 300,-20 288,-20L 172,-20Q 160,-20 160,-8L 160,28.5Q 160,40.5 148,40.5L 32,40.5Q 20,40.5 20,28.5L20 10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .bottom, targetX: 20, targetY: 10.5, targetPosition: .top))
            XCTAssertEqual(r.path, "M300 10L 300,25Q 300,30 295,30L 165,30Q 160,30 160,25L 160,-4.5Q 160,-9.5 155,-9.5L 25,-9.5Q 20,-9.5 20,-4.5L20 10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .bottom, targetX: 20, targetY: 10.5, targetPosition: .top, borderRadius: 0))
            XCTAssertEqual(r.path, "M300 10L 300,30Q 300,30 300,30L 160,30Q 160,30 160,30L 160,-9.5Q 160,-9.5 160,-9.5L 20,-9.5Q 20,-9.5 20,-9.5L20 10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .bottom, targetX: 20, targetY: 10.5, targetPosition: .top, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M300 10L 300,28Q 300,40 288,40L 172,40Q 160,40 160,28L 160,-7.5Q 160,-19.5 148,-19.5L 32,-19.5Q 20,-19.5 20,-7.5L20 10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .bottom, targetX: 20, targetY: 10.5, targetPosition: .right))
            XCTAssertEqual(r.path, "M300 10L 300,25Q 300,30 295,30L 45,30Q 40,30 40,25L 40,15.5Q 40,10.5 35,10.5L20 10.5")
            XCTAssertEqual(r.labelX, 170, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 30, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .bottom, targetX: 20, targetY: 10.5, targetPosition: .right, borderRadius: 0))
            XCTAssertEqual(r.path, "M300 10L 300,30Q 300,30 300,30L 40,30Q 40,30 40,30L 40,10.5Q 40,10.5 40,10.5L20 10.5")
            XCTAssertEqual(r.labelX, 170, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 30, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .bottom, targetX: 20, targetY: 10.5, targetPosition: .right, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M300 10L 300,28Q 300,40 288,40L 62,40Q 50,40 50,28L 50,22.5Q 50,10.5 38,10.5L20 10.5")
            XCTAssertEqual(r.labelX, 175, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 40, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .left, targetX: 20, targetY: 10.5, targetPosition: .left))
            XCTAssertEqual(r.path, "M300 10L280 10L 0.25,10Q 0,10 0,10.25L 0,10.25Q 0,10.5 0.25,10.5L20 10.5")
            XCTAssertEqual(r.labelX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .left, targetX: 20, targetY: 10.5, targetPosition: .left, borderRadius: 0))
            XCTAssertEqual(r.path, "M300 10L280 10L 0,10Q 0,10 0,10L 0,10.5Q 0,10.5 0,10.5L20 10.5")
            XCTAssertEqual(r.labelX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .left, targetX: 20, targetY: 10.5, targetPosition: .left, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M300 10L270 10L -9.75,10Q -10,10 -10,10.25L -10,10.25Q -10,10.5 -9.75,10.5L20 10.5")
            XCTAssertEqual(r.labelX, 130, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .right, targetX: 20, targetY: 10.5, targetPosition: .bottom))
            XCTAssertEqual(r.path, "M300 10L 315,10Q 320,10 320,15L 320,25.5Q 320,30.5 315,30.5L 25,30.5Q 20,30.5 20,25.5L20 10.5")
            XCTAssertEqual(r.labelX, 170, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 30.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .right, targetX: 20, targetY: 10.5, targetPosition: .bottom, borderRadius: 0))
            XCTAssertEqual(r.path, "M300 10L 320,10Q 320,10 320,10L 320,30.5Q 320,30.5 320,30.5L 20,30.5Q 20,30.5 20,30.5L20 10.5")
            XCTAssertEqual(r.labelX, 170, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 30.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
        do {
            let r = getSmoothStepPath(GetSmoothStepPathParams(sourceX: 300, sourceY: 10, sourcePosition: .right, targetX: 20, targetY: 10.5, targetPosition: .bottom, borderRadius: 12, offset: 30))
            XCTAssertEqual(r.path, "M300 10L 318,10Q 330,10 330,22L 330,28.5Q 330,40.5 318,40.5L 32,40.5Q 20,40.5 20,28.5L20 10.5")
            XCTAssertEqual(r.labelX, 175, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 40.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
    }

    func testStraightPaths() {
        do {
            let r = getStraightPath(GetStraightPathParams(sourceX: 10, sourceY: 20, targetX: 200, targetY: 120))
            XCTAssertEqual(r.path, "M 10,20L 200,120")
            XCTAssertEqual(r.labelX, 105, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 70, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getStraightPath(GetStraightPathParams(sourceX: 0, sourceY: 0, targetX: 100, targetY: 0))
            XCTAssertEqual(r.path, "M 0,0L 100,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let r = getStraightPath(GetStraightPathParams(sourceX: 100, sourceY: 100, targetX: 0, targetY: 0))
            XCTAssertEqual(r.path, "M 100,100L 0,0")
            XCTAssertEqual(r.labelX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let r = getStraightPath(GetStraightPathParams(sourceX: -40.5, sourceY: 33.25, targetX: 120.75, targetY: -60))
            XCTAssertEqual(r.path, "M -40.5,33.25L 120.75,-60")
            XCTAssertEqual(r.labelX, 40.125, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, -13.375, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let r = getStraightPath(GetStraightPathParams(sourceX: 5, sourceY: 5, targetX: 5, targetY: 80))
            XCTAssertEqual(r.path, "M 5,5L 5,80")
            XCTAssertEqual(r.labelX, 5, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let r = getStraightPath(GetStraightPathParams(sourceX: 300, sourceY: 10, targetX: 20, targetY: 10.5))
            XCTAssertEqual(r.path, "M 300,10L 20,10.5")
            XCTAssertEqual(r.labelX, 160, accuracy: 1e-9)
            XCTAssertEqual(r.labelY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(r.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(r.offsetY, 0.25, accuracy: 1e-9)
        }
    }

    func testEdgeCenter() {
        do {
            let c = getEdgeCenter(sourceX: 10, sourceY: 20, targetX: 200, targetY: 120)
            XCTAssertEqual(c.centerX, 105, accuracy: 1e-9)
            XCTAssertEqual(c.centerY, 70, accuracy: 1e-9)
            XCTAssertEqual(c.offsetX, 95, accuracy: 1e-9)
            XCTAssertEqual(c.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let c = getEdgeCenter(sourceX: 0, sourceY: 0, targetX: 100, targetY: 0)
            XCTAssertEqual(c.centerX, 50, accuracy: 1e-9)
            XCTAssertEqual(c.centerY, 0, accuracy: 1e-9)
            XCTAssertEqual(c.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(c.offsetY, 0, accuracy: 1e-9)
        }
        do {
            let c = getEdgeCenter(sourceX: 100, sourceY: 100, targetX: 0, targetY: 0)
            XCTAssertEqual(c.centerX, 50, accuracy: 1e-9)
            XCTAssertEqual(c.centerY, 50, accuracy: 1e-9)
            XCTAssertEqual(c.offsetX, 50, accuracy: 1e-9)
            XCTAssertEqual(c.offsetY, 50, accuracy: 1e-9)
        }
        do {
            let c = getEdgeCenter(sourceX: -40.5, sourceY: 33.25, targetX: 120.75, targetY: -60)
            XCTAssertEqual(c.centerX, 40.125, accuracy: 1e-9)
            XCTAssertEqual(c.centerY, -13.375, accuracy: 1e-9)
            XCTAssertEqual(c.offsetX, 80.625, accuracy: 1e-9)
            XCTAssertEqual(c.offsetY, 46.625, accuracy: 1e-9)
        }
        do {
            let c = getEdgeCenter(sourceX: 5, sourceY: 5, targetX: 5, targetY: 80)
            XCTAssertEqual(c.centerX, 5, accuracy: 1e-9)
            XCTAssertEqual(c.centerY, 42.5, accuracy: 1e-9)
            XCTAssertEqual(c.offsetX, 0, accuracy: 1e-9)
            XCTAssertEqual(c.offsetY, 37.5, accuracy: 1e-9)
        }
        do {
            let c = getEdgeCenter(sourceX: 300, sourceY: 10, targetX: 20, targetY: 10.5)
            XCTAssertEqual(c.centerX, 160, accuracy: 1e-9)
            XCTAssertEqual(c.centerY, 10.25, accuracy: 1e-9)
            XCTAssertEqual(c.offsetX, 140, accuracy: 1e-9)
            XCTAssertEqual(c.offsetY, 0.25, accuracy: 1e-9)
        }
    }

    func testViewportForBounds() {
        do {
            let v = getViewportForBounds(Rect(x: 0, y: 0, width: 400, height: 300), width: 800, height: 600, minZoom: 0.5, maxZoom: 2, padding: 0.1)
            XCTAssertEqual(v.x, 36, accuracy: 1e-9)
            XCTAssertEqual(v.y, 27, accuracy: 1e-9)
            XCTAssertEqual(v.zoom, 1.82, accuracy: 1e-9)
        }
        do {
            let v = getViewportForBounds(Rect(x: -120, y: 40, width: 1000, height: 250.5), width: 640, height: 288, minZoom: 0, maxZoom: 1.2, padding: 0.1)
            XCTAssertEqual(v.x, 98.84, accuracy: 1e-9)
            XCTAssertEqual(v.y, 47.8245, accuracy: 1e-9)
            XCTAssertEqual(v.zoom, 0.582, accuracy: 1e-9)
        }
        do {
            let v = getViewportForBounds(Rect(x: 10, y: 10, width: 20, height: 20), width: 500, height: 500, minZoom: 0.5, maxZoom: 2, padding: 0.1)
            XCTAssertEqual(v.x, 210, accuracy: 1e-9)
            XCTAssertEqual(v.y, 210, accuracy: 1e-9)
            XCTAssertEqual(v.zoom, 2, accuracy: 1e-9)
        }
        do {
            let v = getViewportForBounds(Rect(x: 0, y: 0, width: 1000, height: 1000), width: 300, height: 200, minZoom: 0.1, maxZoom: 4, padding: 0.25)
            XCTAssertEqual(v.x, 70, accuracy: 1e-9)
            XCTAssertEqual(v.y, 20, accuracy: 1e-9)
            XCTAssertEqual(v.zoom, 0.16, accuracy: 1e-9)
        }
        do {
            let v = getViewportForBounds(Rect(x: 50, y: -30, width: 640, height: 480), width: 1024, height: 768, minZoom: 0.2, maxZoom: 3, padding: "20px")
            XCTAssertEqual(v.x, -49.16666666666663, accuracy: 1e-9)
            XCTAssertEqual(v.y, 65.5, accuracy: 1e-9)
            XCTAssertEqual(v.zoom, 1.5166666666666666, accuracy: 1e-9)
        }
        do {
            let v = getViewportForBounds(Rect(x: 50, y: -30, width: 640, height: 480), width: 1024, height: 768, minZoom: 0.2, maxZoom: 3, padding: "10%")
            XCTAssertEqual(v.x, 37.9375, accuracy: 1e-9)
            XCTAssertEqual(v.y, 114.9375, accuracy: 1e-9)
            XCTAssertEqual(v.zoom, 1.28125, accuracy: 1e-9)
        }
    }

    func testGeometryHelpers() {
        do {
            let bounds = getBoundsOfRects(Rect(x: 0, y: 0, width: 100, height: 50), Rect(x: 50, y: 25, width: 100, height: 50))
            XCTAssertEqual(bounds.x, 0, accuracy: 1e-9)
            XCTAssertEqual(bounds.y, 0, accuracy: 1e-9)
            XCTAssertEqual(bounds.width, 150, accuracy: 1e-9)
            XCTAssertEqual(bounds.height, 75, accuracy: 1e-9)
            XCTAssertEqual(getOverlappingArea(Rect(x: 0, y: 0, width: 100, height: 50), Rect(x: 50, y: 25, width: 100, height: 50)), 1250, accuracy: 1e-9)
        }
        do {
            let bounds = getBoundsOfRects(Rect(x: -10, y: -10, width: 5, height: 5), Rect(x: 30, y: 30, width: 5, height: 5))
            XCTAssertEqual(bounds.x, -10, accuracy: 1e-9)
            XCTAssertEqual(bounds.y, -10, accuracy: 1e-9)
            XCTAssertEqual(bounds.width, 45, accuracy: 1e-9)
            XCTAssertEqual(bounds.height, 45, accuracy: 1e-9)
            XCTAssertEqual(getOverlappingArea(Rect(x: -10, y: -10, width: 5, height: 5), Rect(x: 30, y: 30, width: 5, height: 5)), 0, accuracy: 1e-9)
        }
        do {
            let bounds = getBoundsOfRects(Rect(x: 1.5, y: 2.5, width: 10.25, height: 4), Rect(x: 4, y: 3, width: 2, height: 2))
            XCTAssertEqual(bounds.x, 1.5, accuracy: 1e-9)
            XCTAssertEqual(bounds.y, 2.5, accuracy: 1e-9)
            XCTAssertEqual(bounds.width, 10.25, accuracy: 1e-9)
            XCTAssertEqual(bounds.height, 4, accuracy: 1e-9)
            XCTAssertEqual(getOverlappingArea(Rect(x: 1.5, y: 2.5, width: 10.25, height: 4), Rect(x: 4, y: 3, width: 2, height: 2)), 4, accuracy: 1e-9)
        }
        do {
            let s = snapPosition(XYPosition(x: 13, y: 27), snapGrid: (10, 10))
            XCTAssertEqual(s.x, 10, accuracy: 1e-9)
            XCTAssertEqual(s.y, 30, accuracy: 1e-9)
        }
        do {
            let s = snapPosition(XYPosition(x: -4.5, y: 9.5), snapGrid: (5, 20))
            XCTAssertEqual(s.x, -5, accuracy: 1e-9)
            XCTAssertEqual(s.y, 0, accuracy: 1e-9)
        }
        do {
            let s = snapPosition(XYPosition(x: 100.49, y: 0.5), snapGrid: (1, 1))
            XCTAssertEqual(s.x, 100, accuracy: 1e-9)
            XCTAssertEqual(s.y, 1, accuracy: 1e-9)
        }
        do {
            let s = snapPosition(XYPosition(x: 2.5, y: -2.5), snapGrid: (5, 5))
            XCTAssertEqual(s.x, 5, accuracy: 1e-9)
            XCTAssertEqual(s.y, 0, accuracy: 1e-9)
        }
        do {
            let p = pointToRendererPoint(XYPosition(x: 100, y: 50), transform: Transform(10, 20, 2))
            XCTAssertEqual(p.x, 45, accuracy: 1e-9)
            XCTAssertEqual(p.y, 15, accuracy: 1e-9)
            let q = rendererPointToPoint(XYPosition(x: 100, y: 50), transform: Transform(10, 20, 2))
            XCTAssertEqual(q.x, 210, accuracy: 1e-9)
            XCTAssertEqual(q.y, 120, accuracy: 1e-9)
        }
        do {
            let p = pointToRendererPoint(XYPosition(x: 0, y: 0), transform: Transform(-30, 15, 0.5))
            XCTAssertEqual(p.x, 60, accuracy: 1e-9)
            XCTAssertEqual(p.y, -30, accuracy: 1e-9)
            let q = rendererPointToPoint(XYPosition(x: 0, y: 0), transform: Transform(-30, 15, 0.5))
            XCTAssertEqual(q.x, -30, accuracy: 1e-9)
            XCTAssertEqual(q.y, 15, accuracy: 1e-9)
        }
        do {
            let p = pointToRendererPoint(XYPosition(x: 333.3, y: -12.5), transform: Transform(0, 0, 1.2))
            XCTAssertEqual(p.x, 277.75, accuracy: 1e-9)
            XCTAssertEqual(p.y, -10.416666666666668, accuracy: 1e-9)
            let q = rendererPointToPoint(XYPosition(x: 333.3, y: -12.5), transform: Transform(0, 0, 1.2))
            XCTAssertEqual(q.x, 399.96, accuracy: 1e-9)
            XCTAssertEqual(q.y, -15, accuracy: 1e-9)
        }
        do {
            let m = calcAutoPan(XYPosition(x: 10, y: 10), bounds: Dimensions(width: 500, height: 400))
            XCTAssertEqual(m[0], 11.25, accuracy: 1e-9)
            XCTAssertEqual(m[1], 11.25, accuracy: 1e-9)
        }
        do {
            let m = calcAutoPan(XYPosition(x: 250, y: 200), bounds: Dimensions(width: 500, height: 400))
            XCTAssertEqual(m[0], 0, accuracy: 1e-9)
            XCTAssertEqual(m[1], 0, accuracy: 1e-9)
        }
        do {
            let m = calcAutoPan(XYPosition(x: 495, y: 395), bounds: Dimensions(width: 500, height: 400))
            XCTAssertEqual(m[0], -13.125, accuracy: 1e-9)
            XCTAssertEqual(m[1], -13.125, accuracy: 1e-9)
        }
        do {
            let m = calcAutoPan(XYPosition(x: -5, y: 420), bounds: Dimensions(width: 500, height: 400))
            XCTAssertEqual(m[0], 15, accuracy: 1e-9)
            XCTAssertEqual(m[1], -15, accuracy: 1e-9)
        }
    }

    func testNodeToolbarTransform() {
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .top, 10, .start).cssTransform, "translate(72px, 27px) translate(0%, -100%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .top, 10, .center).cssTransform, "translate(184.5px, 27px) translate(-50%, -100%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .top, 10, .end).cssTransform, "translate(297px, 27px) translate(-100%, -100%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .right, 10, .start).cssTransform, "translate(307px, 37px) translate(0%, 0%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .right, 10, .center).cssTransform, "translate(307px, 82px) translate(0%, -50%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .right, 10, .end).cssTransform, "translate(307px, 127px) translate(0%, -100%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .bottom, 10, .start).cssTransform, "translate(72px, 137px) translate(0%, 0%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .bottom, 10, .center).cssTransform, "translate(184.5px, 137px) translate(-50%, 0%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .bottom, 10, .end).cssTransform, "translate(297px, 137px) translate(-100%, 0%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .left, 10, .start).cssTransform, "translate(62px, 37px) translate(-100%, 0%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .left, 10, .center).cssTransform, "translate(62px, 82px) translate(-100%, -50%)")
        XCTAssertEqual(getNodeToolbarTransform(Rect(x: 40, y: 30, width: 150, height: 60), Viewport(x: 12, y: -8, zoom: 1.5), .left, 10, .end).cssTransform, "translate(62px, 127px) translate(-100%, -100%)")
    }

    func testMarkerIds() {
        XCTAssertEqual(getMarkerId(.marker(EdgeMarker(type: .arrow))), "type=arrow")
        XCTAssertEqual(getMarkerId(.marker(EdgeMarker(type: .arrow)), id: "flow"), "flow__type=arrow")
        XCTAssertEqual(getMarkerId(.marker(EdgeMarker(type: .arrowclosed, color: "#f00", width: 20, height: 10))), "color=#f00&height=10&type=arrowclosed&width=20")
        XCTAssertEqual(getMarkerId(.marker(EdgeMarker(type: .arrowclosed, color: "#f00", width: 20, height: 10)), id: "flow"), "flow__color=#f00&height=10&type=arrowclosed&width=20")
        XCTAssertEqual(getMarkerId(.marker(EdgeMarker(type: .arrowclosed, markerUnits: "userSpaceOnUse", orient: "auto", strokeWidth: 2))), "markerUnits=userSpaceOnUse&orient=auto&strokeWidth=2&type=arrowclosed")
        XCTAssertEqual(getMarkerId(.marker(EdgeMarker(type: .arrowclosed, markerUnits: "userSpaceOnUse", orient: "auto", strokeWidth: 2)), id: "flow"), "flow__markerUnits=userSpaceOnUse&orient=auto&strokeWidth=2&type=arrowclosed")
    }

    func testZoomInterpolationAndEasing() {
        do {
            let interpolator = interpolateZoom((0, 0, 400), (300, 120, 400))
            XCTAssertEqual(interpolator.duration, 1044.7188557899392, accuracy: 1e-9)
            do {
                let v = interpolator(0)
                XCTAssertEqual(v.ux, 4.1232648001943565e-14, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 1.6493059200777425e-14, accuracy: 1e-9)
                XCTAssertEqual(v.w, 399.99999999999994, accuracy: 1e-9)
            }
            do {
                let v = interpolator(0.25)
                XCTAssertEqual(v.ux, 65.6312674064929, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 26.25250696259716, accuracy: 1e-9)
                XCTAssertEqual(v.w, 481.01153281082867, accuracy: 1e-9)
            }
            do {
                let v = interpolator(0.5)
                XCTAssertEqual(v.ux, 150.00000000000006, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 60.00000000000003, accuracy: 1e-9)
                XCTAssertEqual(v.w, 514.1984052872976, accuracy: 1e-9)
            }
            do {
                let v = interpolator(0.9)
                XCTAssertEqual(v.ux, 276.6602519743481, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 110.66410078973924, accuracy: 1e-9)
                XCTAssertEqual(v.w, 435.8455206192296, accuracy: 1e-9)
            }
            do {
                let v = interpolator(1)
                XCTAssertEqual(v.ux, 300.00000000000006, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 120.00000000000003, accuracy: 1e-9)
                XCTAssertEqual(v.w, 400, accuracy: 1e-9)
            }
        }
        do {
            let interpolator = interpolateZoom((100, 50, 200), (-80, 400, 40))
            XCTAssertEqual(interpolator.duration, 3121.500541781628, accuracy: 1e-9)
            do {
                let v = interpolator(0)
                XCTAssertEqual(v.ux, 99.99999999999999, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 50.00000000000002, accuracy: 1e-9)
                XCTAssertEqual(v.w, 200, accuracy: 1e-9)
            }
            do {
                let v = interpolator(0.25)
                XCTAssertEqual(v.ux, 40.79159062716839, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 165.1274626693948, accuracy: 1e-9)
                XCTAssertEqual(v.w, 405.1388669926718, accuracy: 1e-9)
            }
            do {
                let v = interpolator(0.5)
                XCTAssertEqual(v.ux, -49.99999999999997, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 341.66666666666663, accuracy: 1e-9)
                XCTAssertEqual(v.w, 306.68478207363904, accuracy: 1e-9)
            }
            do {
                let v = interpolator(0.9)
                XCTAssertEqual(v.ux, -79.384213570963, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 398.8026374990947, accuracy: 1e-9)
                XCTAssertEqual(v.w, 61.99830660721893, accuracy: 1e-9)
            }
            do {
                let v = interpolator(1)
                XCTAssertEqual(v.ux, -79.99999999999994, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 399.9999999999999, accuracy: 1e-9)
                XCTAssertEqual(v.w, 40, accuracy: 1e-9)
            }
        }
        do {
            let interpolator = interpolateZoom((0, 0, 1), (0, 0, 8))
            XCTAssertEqual(interpolator.duration, 1470.3872152028205, accuracy: 1e-9)
            do {
                let v = interpolator(0)
                XCTAssertEqual(v.ux, 0, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 0, accuracy: 1e-9)
                XCTAssertEqual(v.w, 1, accuracy: 1e-9)
            }
            do {
                let v = interpolator(0.25)
                XCTAssertEqual(v.ux, 0, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 0, accuracy: 1e-9)
                XCTAssertEqual(v.w, 1.681792830507429, accuracy: 1e-9)
            }
            do {
                let v = interpolator(0.5)
                XCTAssertEqual(v.ux, 0, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 0, accuracy: 1e-9)
                XCTAssertEqual(v.w, 2.82842712474619, accuracy: 1e-9)
            }
            do {
                let v = interpolator(0.9)
                XCTAssertEqual(v.ux, 0, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 0, accuracy: 1e-9)
                XCTAssertEqual(v.w, 6.498019170849885, accuracy: 1e-9)
            }
            do {
                let v = interpolator(1)
                XCTAssertEqual(v.ux, 0, accuracy: 1e-9)
                XCTAssertEqual(v.uy, 0, accuracy: 1e-9)
                XCTAssertEqual(v.w, 7.999999999999998, accuracy: 1e-9)
            }
        }
        XCTAssertEqual(easeCubicInOut(0), 0, accuracy: 1e-12)
        XCTAssertEqual(easeCubicInOut(0.1), 0.004000000000000001, accuracy: 1e-12)
        XCTAssertEqual(easeCubicInOut(0.33), 0.14374800000000001, accuracy: 1e-12)
        XCTAssertEqual(easeCubicInOut(0.5), 0.5, accuracy: 1e-12)
        XCTAssertEqual(easeCubicInOut(0.75), 0.9375, accuracy: 1e-12)
        XCTAssertEqual(easeCubicInOut(1), 1, accuracy: 1e-12)
    }
}
