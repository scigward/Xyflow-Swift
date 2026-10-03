#if canImport(UIKit)
import UIKit
import XCTest
import XYSystem
@testable import Xyflow

final class EdgeLayeringTests: XCTestCase {
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

    private func makeFlow() -> SwiftFlow {
        let flow = SwiftFlow(nodes: [
            Node(id: "a", position: XYPosition(x: 0, y: 0), data: ["label": "Alpha"],
                 sourcePosition: .right, targetPosition: .left),
            Node(id: "b", position: XYPosition(x: 300, y: 100), data: ["label": "Beta"],
                 sourcePosition: .right, targetPosition: .left)
        ], edges: [Edge(id: "e", source: "a", target: "b", animated: true, label: "SEQUEL")])
        flow.colorMode = .dark
        flow.frame = window.bounds
        window.addSubview(flow)
        flow.layoutIfNeeded()
        XCTAssertTrue(wait { flow.nodeRenderer.subviews.contains { $0 is EdgeLabelView } })
        return flow
    }

    private func label(in flow: SwiftFlow) throws -> EdgeLabelView {
        try XCTUnwrap(flow.nodeRenderer.subviews.compactMap { $0 as? EdgeLabelView }.first)
    }

    /// Edge wrapper layers have no UIView; the labels and node wrappers do.
    private func pathLayers(in flow: SwiftFlow) -> [CALayer] {
        let viewLayers = Set(flow.nodeRenderer.subviews.map { ObjectIdentifier($0.layer) })
        return (flow.nodeRenderer.layer.sublayers ?? []).filter {
            !viewLayers.contains(ObjectIdentifier($0))
        }
    }

    func testAnimatedPathsStayBehindOpaqueLabelsAndNodes() throws {
        let flow = makeFlow()
        let label = try label(in: flow)
        let path = try XCTUnwrap(pathLayers(in: flow).first)
        let layers = try XCTUnwrap(flow.nodeRenderer.layer.sublayers)

        XCTAssertTrue(label.superview === flow.nodeRenderer)
        XCTAssertTrue(path.superlayer === label.layer.superlayer)
        XCTAssertTrue(flow.edgeLabelRenderer.subviews.isEmpty, "the portal is only the styling context")
        XCTAssertEqual(label.backgroundColor, FlowCSS.parseColor("#141414")?.uiColor)
        let pathIndex = try XCTUnwrap(layers.firstIndex { $0 === path })
        let labelIndex = try XCTUnwrap(layers.firstIndex { $0 === label.layer })
        XCTAssertLessThan(pathIndex, labelIndex)
        for node in flow.nodeRenderer.subviews where node is NodeWrapperView {
            let nodeIndex = try XCTUnwrap(layers.firstIndex { $0 === node.layer })
            XCTAssertLessThan(labelIndex, nodeIndex)
        }
    }

    func testLabelsTrackEdgeZIndexAndRemainClickable() throws {
        let flow = makeFlow()
        let edge = try XCTUnwrap(flow.edges.get().first).copy()
        edge.zIndex = 6
        flow.edges.set([edge])
        let label = try label(in: flow)

        XCTAssertEqual(label.layer.zPosition, 6)
        XCTAssertEqual(pathLayers(in: flow).first?.zPosition, 6)
        flow.dispatchClick(FlowPointerEvent(clientX: 0, clientY: 0, target: label))
        XCTAssertEqual(flow.store.edges.get().first?.selected, true)
    }

    func testHitTestingFollowsTheLabelAndNodeStackingOrder() throws {
        let flow = makeFlow()
        let label = try label(in: flow)
        let node = try XCTUnwrap(flow.nodeRenderer.wrapper(for: "a"))
        // An elevated label may overlap another node even where its edge path does not cross it.
        label.frame = node.frame
        let point = CGPoint(x: node.frame.midX, y: node.frame.midY)
        label.layer.zPosition = 6
        let frontHit = flow.nodeRenderer.hitTest(point, with: nil)
        XCTAssertTrue(frontHit === label || frontHit?.isDescendant(of: label) == true)

        label.layer.zPosition = node.layer.zPosition
        let ordinaryHit = flow.nodeRenderer.hitTest(point, with: nil)
        XCTAssertTrue(ordinaryHit === node || ordinaryHit?.isDescendant(of: node) == true)
    }

    func testReconcileDoesNotDuplicateLabelsAndRemovingEdgesRemovesThem() throws {
        let flow = makeFlow()
        let original = try label(in: flow)
        for _ in 0..<20 {
            flow.nodeRenderer.reconcile()
            flow.edgeRenderer.reconcile()
        }

        let labels = flow.nodeRenderer.subviews.compactMap { $0 as? EdgeLabelView }
        XCTAssertEqual(labels.count, 1)
        XCTAssertTrue(labels.first === original)
        XCTAssertEqual(pathLayers(in: flow).count, 1)
        flow.edges.set([])
        XCTAssertFalse(flow.nodeRenderer.subviews.contains { $0 is EdgeLabelView })
        XCTAssertTrue(pathLayers(in: flow).isEmpty)
    }

    func testLabelStylesStillUseTheWebPortalAncestors() throws {
        let flow = makeFlow()
        flow.styleSheet = """
        .svelte-flow__edgelabel-renderer > .svelte-flow__edge-label { background-color: #123456 }
        """
        XCTAssertEqual(try label(in: flow).backgroundColor, FlowCSS.parseColor("#123456")?.uiColor)
    }
}
#endif
