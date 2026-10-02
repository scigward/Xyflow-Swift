#if canImport(UIKit)
import XCTest
import XYSystem
@testable import Xyflow

final class SwiftFlowTests: XCTestCase {
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

    /// Lets the main run loop go on until the condition is met.
    @discardableResult
    private func wait(timeout: TimeInterval = 3, until condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while !condition() && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }

        return condition()
    }

    private func makeFlow(fitView: Bool? = nil) -> SwiftFlow {
        let nodes = [
            Node(id: "a", position: XYPosition(x: 0, y: 0), data: ["label": "Alpha"], sourcePosition: .right, targetPosition: .left),
            Node(id: "b", position: XYPosition(x: 300, y: 100), data: ["label": "Beta"], sourcePosition: .right, targetPosition: .left)
        ]
        let edges = [Edge(id: "e", source: "a", target: "b", label: "SEQUEL")]

        let flow = SwiftFlow(nodes: nodes, edges: edges, fitView: fitView)
        flow.frame = window.bounds
        window.addSubview(flow)
        flow.layoutIfNeeded()
        return flow
    }

    func testNodesAreMeasured() {
        let flow = makeFlow()

        XCTAssertTrue(wait { flow.store.nodesInitialized.get() })

        let measured = flow.store.nodes.get().first?.measured
        XCTAssertEqual(measured?.width, 150, "the border is part of the 150 points")
        XCTAssertGreaterThan(measured?.height ?? 0, 20)
    }

    func testHandlesAreFoundWhenTheNodeIsMeasured() {
        let flow = makeFlow()
        XCTAssertTrue(wait { flow.store.nodesInitialized.get() })

        let bounds = flow.store.nodeLookup.get().get("a")?.internals.handleBounds
        XCTAssertEqual(bounds?.source?.count, 1)
        XCTAssertEqual(bounds?.target?.count, 1)
        XCTAssertEqual(bounds?.source?.first?.position, .right)
        XCTAssertEqual(bounds?.target?.first?.position, .left)
    }

    func testEdgesAreLaidOutOnceHandlesAreKnown() {
        let flow = makeFlow()

        XCTAssertTrue(wait { flow.store.visibleEdges.get().count == 1 })

        let position = flow.store.visibleEdges.get().first?.position
        XCTAssertEqual(position?.sourcePosition, .right)
        XCTAssertEqual(position?.targetPosition, .left)
        XCTAssertLessThan(position?.sourceX ?? 0, position?.targetX ?? 0)
    }

    func testFitViewIsDoneAfterTheNodesAreMeasured() {
        let flow = makeFlow(fitView: true)

        XCTAssertTrue(wait { flow.store.viewport.get().zoom != 1 })

        let viewport = flow.store.viewport.get()
        XCTAssertGreaterThan(viewport.zoom, 0)

        // the nodes are inside of the flow
        for node in flow.store.nodes.get() {
            let screenX = node.position.x * viewport.zoom + viewport.x
            let screenY = node.position.y * viewport.zoom + viewport.y
            XCTAssertGreaterThanOrEqual(screenX, 0)
            XCTAssertGreaterThanOrEqual(screenY, 0)
            XCTAssertLessThanOrEqual(screenX, 600)
            XCTAssertLessThanOrEqual(screenY, 400)
        }
    }

    func testTheFlowBecomesInitialized() {
        let flow = makeFlow()
        var initialized = false
        flow.oninit = { initialized = true }

        XCTAssertTrue(wait { initialized })
        XCTAssertTrue(flow.store.initialized.get())
    }

    func testCustomNodeTypes() {
        final class CustomNode: UIView, FlowNodeComponent {
            let label = UILabel()
            func update(props: NodeProps) { label.text = props.data["label"] as? String }
            func preferredSize(width: Double?, height: Double?) -> CGSize? { CGSize(width: 90, height: 30) }
        }

        let flow = SwiftFlow(nodes: [Node(id: "x", position: XYPosition(x: 10, y: 10), data: ["label": "custom"], type: "custom")])
        flow.nodeTypes = ["custom": { CustomNode() }]
        flow.frame = window.bounds
        window.addSubview(flow)
        flow.layoutIfNeeded()

        XCTAssertTrue(wait { flow.store.nodesInitialized.get() })

        let measured = flow.store.nodes.get().first?.measured
        XCTAssertEqual(measured?.width, 90)
        XCTAssertEqual(measured?.height, 30)
    }

    func testClickOnANodeIsReported() {
        let flow = makeFlow()
        XCTAssertTrue(wait { flow.store.nodesInitialized.get() })

        var clicked: String?
        flow.onNodeClick = { clicked = $0.node.id }

        let wrapper = flow.nodeRenderer.wrapper(for: "b")
        XCTAssertNotNil(wrapper)

        flow.dispatchClick(FlowPointerEvent(clientX: 0, clientY: 0, target: wrapper))

        XCTAssertEqual(clicked, "b")
    }

    func testClickOnThePaneReportsAndUnselects() {
        let flow = makeFlow()
        flow.store.addSelectedNodes(["a"])

        var paneClicks = 0
        flow.onPaneClick = { _ in paneClicks += 1 }

        flow.dispatchClick(FlowPointerEvent(clientX: 1, clientY: 1, target: flow.paneView))

        XCTAssertEqual(paneClicks, 1)
        XCTAssertEqual(flow.store.nodes.get().first?.selected, false)
    }

    func testColorModeChangesTheStyleOfTheFlow() {
        let flow = makeFlow()

        XCTAssertEqual(flow.rootScope().value(of: "--xy-edge-stroke-default"), "#b1b1b7")

        flow.colorMode = .dark

        XCTAssertEqual(flow.colorModeClass, .dark)
        XCTAssertEqual(flow.rootScope().value(of: "--xy-edge-stroke-default"), "#3e3e3e")
    }

    func testStyleVariablesAreAvailableToStyles() {
        let flow = makeFlow()
        flow.styleVariables = ["--custom": "#0059dc"]

        let scope = FlowStyleScope(parent: flow.rootScope(), style: "--xy-edge-stroke: var(--custom)")
        XCTAssertEqual(scope.color(["--xy-edge-stroke"]), FlowCSS.parseColor("#0059dc"))
    }

    func testScreenAndFlowPositionsConvert() {
        let flow = makeFlow()
        let instance = flow.instance

        flow.store.viewport.set(Viewport(x: 50, y: 20, zoom: 2))

        let screen = instance.flowToScreenPosition(XYPosition(x: 10, y: 10))
        let back = instance.screenToFlowPosition(screen, snapToGrid: false)

        XCTAssertEqual(back.x, 10, accuracy: 1e-6)
        XCTAssertEqual(back.y, 10, accuracy: 1e-6)
    }

    func testRemovingNodesRemovesTheirViews() {
        let flow = makeFlow()
        XCTAssertTrue(wait { flow.store.nodesInitialized.get() })
        XCTAssertNotNil(flow.nodeRenderer.wrapper(for: "a"))

        flow.nodes.set(flow.nodes.get().filter { $0.id != "a" })

        XCTAssertNil(flow.nodeRenderer.wrapper(for: "a"))
        XCTAssertNotNil(flow.nodeRenderer.wrapper(for: "b"))
    }

    func testControlsAreLaidOut() {
        let flow = makeFlow()
        let controls = ControlsView(orientation: .horizontal)
        flow.add(controls)
        flow.layoutIfNeeded()

        XCTAssertTrue(controls.frame.width > 0)
        XCTAssertEqual(controls.frame.height, 26)
    }
}
#endif
