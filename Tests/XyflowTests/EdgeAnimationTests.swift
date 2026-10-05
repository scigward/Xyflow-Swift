#if canImport(UIKit)
import UIKit
import XCTest
import XYSystem
@testable import Xyflow

final class EdgeAnimationTests: XCTestCase {
    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window = nil
        super.tearDown()
    }

    private func wait(until condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(3)
        while !condition() && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        return condition()
    }

    private func dashLayers(in layer: CALayer) -> [CAShapeLayer] {
        var result: [CAShapeLayer] = []
        if let shape = layer as? CAShapeLayer, shape.lineDashPattern != nil {
            result.append(shape)
        }
        for child in layer.sublayers ?? [] {
            result.append(contentsOf: dashLayers(in: child))
        }
        return result
    }

    private func makeFlow() -> SwiftFlow {
        let flow = SwiftFlow(nodes: [
            Node(id: "a", position: .zero, data: ["label": "Current"],
                 sourcePosition: .right, targetPosition: .left),
            Node(id: "b", position: XYPosition(x: 200, y: 100), data: ["label": "Related"],
                 sourcePosition: .right, targetPosition: .left),
            Node(id: "c", position: XYPosition(x: 400, y: 0), data: ["label": "Other"],
                 sourcePosition: .right, targetPosition: .left)
        ], edges: [
            Edge(id: "accent", source: "a", target: "b", animated: true,
                 style: "--xy-edge-stroke: #ff00ff"),
            Edge(id: "gray", source: "b", target: "c", animated: true)
        ])
        flow.colorMode = .dark
        flow.onlyRenderVisibleElements = true
        flow.nodesDraggable = false
        flow.elementsSelectable = false
        flow.frame = window.bounds
        window.addSubview(flow)
        flow.layoutIfNeeded()
        XCTAssertTrue(wait { self.dashLayers(in: flow.nodeRenderer.layer).count == 2 })
        // Commit the animations before tests cancel them; otherwise an uncommitted animation
        // need not deliver its stop delegate callback.
        CATransaction.flush()
        RunLoop.current.run(until: Date().addingTimeInterval(0.03))
        return flow
    }

    func testUnchangedGrayAndAccentEdgesRestoreLostAnimationsOnReconcile() {
        let flow = makeFlow()
        let paths = dashLayers(in: flow.nodeRenderer.layer)
        XCTAssertEqual(paths.count, 2)
        paths.forEach { $0.removeAnimation(forKey: "dashdraw") }

        // Identical edge objects, positions and styles take the EdgeSignature fast path.
        // This must not skip restoration of their independent presentation animations.
        flow.edgeRenderer.reconcile()
        for path in paths {
            XCTAssertNotNil(path.animation(forKey: "dashdraw"))
        }
    }

    func testIdleVisibleEdgeRecoversWithoutGeometryOrViewportUpdates() {
        let flow = makeFlow()
        let paths = dashLayers(in: flow.nodeRenderer.layer)
        paths.forEach { $0.removeAnimation(forKey: "dashdraw") }

        // Only Core Animation's stop callback runs; no reconcile, zoom or prop update is needed.
        CATransaction.flush()
        XCTAssertTrue(wait { paths.allSatisfy { $0.animation(forKey: "dashdraw") != nil } })
    }

    func testCulledCachedEdgesResumeWhenZoomMakesThemVisibleAgain() {
        let flow = makeFlow()
        let original = dashLayers(in: flow.nodeRenderer.layer)
        flow.store.viewport.set(Viewport(x: -2000, y: -2000, zoom: 1))
        XCTAssertTrue(wait { self.dashLayers(in: flow.nodeRenderer.layer).isEmpty })
        original.forEach { $0.removeAnimation(forKey: "dashdraw") }

        flow.store.viewport.set(Viewport(x: 0, y: 0, zoom: 1))
        XCTAssertTrue(wait { self.dashLayers(in: flow.nodeRenderer.layer).count == 2 })
        let restored = dashLayers(in: flow.nodeRenderer.layer)
        for originalPath in original {
            XCTAssertTrue(restored.contains { $0 === originalPath }, "cached edges should still be reused")
            XCTAssertNotNil(originalPath.animation(forKey: "dashdraw"))
        }
    }

    func testRemovedEdgeDoesNotRestartWhileDetachedAndResumesOnRemount() {
        let flow = makeFlow()
        let paths = dashLayers(in: flow.nodeRenderer.layer)
        flow.removeFromSuperview()
        paths.forEach { $0.removeAnimation(forKey: "dashdraw") }
        CATransaction.flush()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        XCTAssertTrue(paths.allSatisfy { $0.animation(forKey: "dashdraw") == nil })

        window.addSubview(flow)
        flow.layoutIfNeeded()
        XCTAssertTrue(wait { paths.allSatisfy { $0.animation(forKey: "dashdraw") != nil } })
    }

    func testExplicitlyDisablingAnimationDoesNotRestartIt() {
        let flow = makeFlow()
        flow.edges.set(flow.edges.get().map { edge in
            let copy = edge.copy()
            copy.animated = false
            // Keep a dashed stroke so this tests animation state, not removal of the pattern.
            copy.style = (copy.style ?? "") + "; stroke-dasharray: 5"
            return copy
        })
        let paths = dashLayers(in: flow.nodeRenderer.layer)
        XCTAssertEqual(paths.count, 2)
        CATransaction.flush()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        flow.edgeRenderer.reconcile()
        XCTAssertTrue(paths.allSatisfy { $0.animation(forKey: "dashdraw") == nil })
    }

    func testDashAnimationKeepsWebTimingAndHealthyAnimationsAreNotRestarted() throws {
        let flow = makeFlow()
        for path in dashLayers(in: flow.nodeRenderer.layer) {
            let original = try XCTUnwrap(path.animation(forKey: "dashdraw") as? CABasicAnimation)
            XCTAssertEqual(original.duration, 0.5)
            XCTAssertEqual(original.repeatCount, Float.infinity)
            XCTAssertEqual(original.fromValue as? Int, 10)
            XCTAssertEqual(original.toValue as? Int, 0)
            // An unset range reads back as nil on current SDKs, so nil and 0 both mean no preference.
            XCTAssertEqual(original.preferredFrameRateRange.preferred ?? 0, 0, "no artificial 30fps cap")
            // A nonzero start time distinguishes keeping the running animation from recreating it.
            // A running animation is read-only, so it is changed on a copy.
            let shifted = try XCTUnwrap(original.copy() as? CABasicAnimation)
            shifted.beginTime = path.convertTime(CACurrentMediaTime(), from: nil) - 0.125
            path.add(shifted, forKey: "dashdraw")
            for _ in 0..<20 { flow.edgeRenderer.reconcile() }
            let retained = try XCTUnwrap(path.animation(forKey: "dashdraw"))
            XCTAssertEqual(retained.beginTime, shifted.beginTime)
        }
    }
}
#endif
