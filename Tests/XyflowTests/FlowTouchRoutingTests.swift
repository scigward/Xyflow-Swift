#if canImport(UIKit)
import UIKit
import XCTest
import XYSystem
@testable import Xyflow

final class FlowTouchRoutingTests: XCTestCase {
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

    private func makeFlow() -> SwiftFlow {
        let flow = SwiftFlow(nodes: [Node(id: "anime", position: .zero, data: ["label": "Anime"])])
        flow.frame = window.bounds
        window.addSubview(flow)
        flow.layoutIfNeeded()
        return flow
    }

    func testNonDraggableNodeLeavesDescendantTouchesToCanvas() throws {
        let flow = makeFlow()
        flow.nodesDraggable = false
        let wrapper = try XCTUnwrap(flow.nodeRenderer.wrapper(for: "anime"))
        let content = try XCTUnwrap(wrapper.subviews.first)
        let router = FlowTouchRouter(flow: flow)

        XCTAssertFalse(wrapper.flowDragEnabled)
        XCTAssertNil(router.dragHost(for: content))

        // Canvas touches still pass the zoom filter, including touches that start over node content.
        let zoom = try XCTUnwrap(flow.zoomView.zoomBehavior)
        let first = ZoomTouch(identifier: 1, point: XYPosition(x: 30, y: 30))
        let second = ZoomTouch(identifier: 2, point: XYPosition(x: 90, y: 30))
        zoom.touchstarted(ZoomSourceEvent(type: "touchstart", target: content,
                                         touches: [first, second], changedTouches: [first, second]))
        let moved = ZoomTouch(identifier: 2, point: XYPosition(x: 150, y: 30))
        zoom.touchmoved(ZoomSourceEvent(type: "touchmove", target: content,
                                      touches: [first, moved], changedTouches: [moved]))
        XCTAssertEqual(flow.store.viewport.get().zoom, 2, accuracy: 0.001)
        zoom.touchended(ZoomSourceEvent(type: "touchend", target: content,
                                      changedTouches: [first, moved]))

        // Disabling drag does not disable an ordinary single-finger click.
        var clicked = false
        flow.onNodeClick = { _ in clicked = true }
        flow.dispatchClick(FlowPointerEvent(clientX: 30, clientY: 30, target: content))
        XCTAssertTrue(clicked)
    }

    func testDragHostFollowsGlobalAndPerNodeDraggableSettings() throws {
        let flow = makeFlow()
        let wrapper = try XCTUnwrap(flow.nodeRenderer.wrapper(for: "anime"))
        let router = FlowTouchRouter(flow: flow)
        XCTAssertNotNil(router.dragHost(for: wrapper))

        flow.nodesDraggable = false
        XCTAssertNil(router.dragHost(for: wrapper))

        let node = try XCTUnwrap(flow.nodes.get().first).copy()
        node.draggable = true
        flow.nodes.set([node])
        XCTAssertNotNil(router.dragHost(for: wrapper))

        let fixedNode = node.copy()
        fixedNode.draggable = false
        flow.nodes.set([fixedNode])
        XCTAssertNil(router.dragHost(for: wrapper))
    }

    private func makeLabeledFlow() -> SwiftFlow {
        let flow = SwiftFlow(nodes: [
            Node(id: "a", position: .zero, data: ["label": "Anime"]),
            Node(id: "b", position: XYPosition(x: 300, y: 100), data: ["label": "Sequel"])
        ], edges: [Edge(id: "relation", source: "a", target: "b", label: "SEQUEL")])
        flow.nodesDraggable = false
        flow.frame = window.bounds
        window.addSubview(flow)
        flow.layoutIfNeeded()
        let deadline = Date().addingTimeInterval(3)
        while !flow.nodeRenderer.subviews.contains(where: { $0 is EdgeLabelView }) && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        return flow
    }

    private func label(in flow: SwiftFlow) throws -> EdgeLabelView {
        try XCTUnwrap(flow.nodeRenderer.subviews.compactMap { $0 as? EdgeLabelView }.first)
    }

    /// A second finger must join the zoom regardless of which kind of view it lands on first.
    func testPinchAcrossLabelsAndNodesWorksInBothFingerArrivalOrders() throws {
        for order in 0..<3 {
            let flow = makeLabeledFlow()
            let label = try label(in: flow)
            let node = try XCTUnwrap(flow.nodeRenderer.wrapper(for: "a"))
            let firstTarget: UIView = order == 1 ? node : label
            let secondTarget: UIView = order == 0 ? node : label
            let zoom = try XCTUnwrap(flow.zoomView.zoomBehavior)
            let first = ZoomTouch(identifier: 1, point: XYPosition(x: 30, y: 30))
            let second = ZoomTouch(identifier: 2, point: XYPosition(x: 90, y: 30))
            zoom.touchstarted(ZoomSourceEvent(type: "touchstart", target: firstTarget,
                                             touches: [first], changedTouches: [first]))
            zoom.touchstarted(ZoomSourceEvent(type: "touchstart", target: secondTarget,
                                             touches: [first, second], changedTouches: [second]))
            let moved = ZoomTouch(identifier: 2, point: XYPosition(x: 150, y: 30))
            zoom.touchmoved(ZoomSourceEvent(type: "touchmove", target: secondTarget,
                                           touches: [first, moved], changedTouches: [moved]))
            XCTAssertEqual(flow.store.viewport.get().zoom, 2, accuracy: 0.001, "arrival order \(order)")
            zoom.touchended(ZoomSourceEvent(type: "touchend", target: secondTarget,
                                           changedTouches: [first, moved]))
        }
    }

    func testBuiltInLabelStillSelectsItsEdge() throws {
        let flow = makeLabeledFlow()
        let label = try label(in: flow)
        XCTAssertEqual(label.flowClasses, ["svelte-flow__edge-label"])
        XCTAssertTrue(label.isUserInteractionEnabled)
        flow.dispatchClick(FlowPointerEvent(clientX: 0, clientY: 0, target: label))
        XCTAssertEqual(flow.store.edges.get().first?.selected, true)
    }

    func testIntentionalNoPanClassStillBlocksTouchStarts() throws {
        let flow = makeLabeledFlow()
        let label = try label(in: flow)
        label.flowClasses.insert(FlowClass.noPan)
        let first = ZoomTouch(identifier: 1, point: XYPosition(x: 30, y: 30))
        let second = ZoomTouch(identifier: 2, point: XYPosition(x: 90, y: 30))
        let event = ZoomSourceEvent(type: "touchstart", target: label,
                                    touches: [first, second], changedTouches: [first, second])
        XCTAssertFalse(try XCTUnwrap(flow.zoomView.zoomBehavior).filter(event))
    }

    func testZoomOnPinchFalseStillBlocksMultiTouchOnLabels() throws {
        let flow = makeLabeledFlow()
        let label = try label(in: flow)
        flow.zoomOnPinch = false
        let first = ZoomTouch(identifier: 1, point: XYPosition(x: 30, y: 30))
        let second = ZoomTouch(identifier: 2, point: XYPosition(x: 90, y: 30))
        let event = ZoomSourceEvent(type: "touchstart", target: label,
                                    touches: [first, second], changedTouches: [first, second])
        XCTAssertFalse(try XCTUnwrap(flow.zoomView.zoomBehavior).filter(event))
        XCTAssertTrue(event.defaultPrevented)
    }
}
#endif
