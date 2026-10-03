#if canImport(UIKit)
import UIKit
import XCTest
import XYSystem
@testable import Xyflow

final class RendererPerformanceTests: XCTestCase {
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
        let flow = SwiftFlow(nodes: [
            Node(id: "a", position: .zero, data: ["label": "Alpha"],
                 sourcePosition: .right, targetPosition: .left),
            Node(id: "b", position: XYPosition(x: 200, y: 0), data: ["label": "Beta"],
                 sourcePosition: .right, targetPosition: .left),
            Node(id: "c", position: XYPosition(x: 400, y: 0), data: ["label": "Gamma"],
                 sourcePosition: .right, targetPosition: .left)
        ], edges: [
            Edge(id: "first", source: "a", target: "b", type: "straight", animated: true, label: "FIRST"),
            Edge(id: "second", source: "a", target: "b", type: "straight", animated: true, label: "SECOND"),
            Edge(id: "third", source: "a", target: "b", type: "straight", animated: true, label: "THIRD")
        ])
        flow.nodesDraggable = false
        flow.elementsSelectable = false
        flow.frame = window.bounds
        window.addSubview(flow)
        flow.layoutIfNeeded()
        let deadline = Date().addingTimeInterval(3)
        while flow.store.visibleEdges.get().count != 3 && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertEqual(flow.store.visibleEdges.get().count, 3)
        return flow
    }

    private func nodeOrder(_ flow: SwiftFlow) -> [String] {
        flow.nodeRenderer.subviews.compactMap { ($0 as? NodeWrapperView)?.nodeId }
    }

    private func frontEdge(_ flow: SwiftFlow) throws -> String? {
        let source = try XCTUnwrap(flow.nodeRenderer.wrapper(for: "a"))
        let target = try XCTUnwrap(flow.nodeRenderer.wrapper(for: "b"))
        let midpoint = CGPoint(x: (source.frame.maxX + target.frame.minX) / 2, y: source.frame.midY)
        let client = flow.edgeRenderer.convert(midpoint, to: nil)
        return flow.edgeRenderer.edge(at: FlowPointerEvent(
            clientX: Double(client.x), clientY: Double(client.y), target: flow.edgeRenderer))?.id
    }

    func testEqualZPreservesSourceOrderForNodesAndReverseOrderForEdgeHits() throws {
        let flow = makeFlow()
        for _ in 0..<20 {
            flow.nodeRenderer.reconcile()
            flow.edgeRenderer.reconcile()
        }
        XCTAssertEqual(nodeOrder(flow), ["a", "b", "c"])
        XCTAssertEqual(try frontEdge(flow), "third")

        flow.nodes.set(Array(flow.nodes.get().reversed()))
        flow.edges.set(Array(flow.edges.get().reversed()))
        XCTAssertEqual(nodeOrder(flow), ["c", "b", "a"])
        XCTAssertEqual(try frontEdge(flow), "first")
    }

    func testMixedZAndInPlaceChangesUseTheSameStableStackingRules() throws {
        let flow = makeFlow()
        // No identity-based z cache: even the existing internal objects may change their z.
        flow.store.nodeLookup.get().get("a")?.internals.z = 8
        flow.store.nodeLookup.get().get("b")?.internals.z = 2
        flow.store.nodeLookup.get().get("c")?.internals.z = 2
        flow.nodeRenderer.reconcile()
        XCTAssertEqual(nodeOrder(flow), ["b", "c", "a"])

        let edges = flow.edges.get()
        edges[0].zIndex = 4
        edges[1].zIndex = 9
        edges[2].zIndex = 4
        flow.edges.set(edges)
        XCTAssertEqual(try frontEdge(flow), "second")
        edges[2].zIndex = 9
        flow.edges.set(edges)
        XCTAssertEqual(try frontEdge(flow), "third", "last source edge wins equal-z ties")
    }

    func testLabelAttachmentKeepsPathsBelowLabelsAndLabelsBelowNodes() throws {
        let flow = makeFlow()
        let labels = flow.nodeRenderer.subviews.compactMap { $0 as? EdgeLabelView }
        XCTAssertEqual(labels.map { $0.textLabel.text ?? "" }, ["FIRST", "SECOND", "THIRD"])
        let layers = try XCTUnwrap(flow.nodeRenderer.layer.sublayers)
        let nodeLayers = flow.nodeRenderer.subviews.compactMap { ($0 as? NodeWrapperView)?.layer }
        let labelLayers = labels.map { $0.layer }
        let viewLayers = Set(flow.nodeRenderer.subviews.map { ObjectIdentifier($0.layer) })
        let pathLayers = layers.filter { !viewLayers.contains(ObjectIdentifier($0)) }
        for label in labelLayers {
            let labelIndex = try XCTUnwrap(layers.firstIndex { $0 === label })
            for path in pathLayers {
                XCTAssertLessThan(try XCTUnwrap(layers.firstIndex { $0 === path }), labelIndex)
            }
            for node in nodeLayers {
                XCTAssertLessThan(labelIndex, try XCTUnwrap(layers.firstIndex { $0 === node }))
            }
        }
        flow.edges.set([])
        XCTAssertFalse(flow.nodeRenderer.subviews.contains { $0 is EdgeLabelView })
        XCTAssertEqual(nodeOrder(flow), ["a", "b", "c"])
    }
}
#endif
