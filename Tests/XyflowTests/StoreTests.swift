#if canImport(UIKit)
import UIKit
import XCTest
import XYSystem
@testable import Xyflow

final class ReactiveStoreTests: XCTestCase {
    func testSubscribeIsCalledRightAwayAndOnChange() {
        let store = Writable<Int>(1)
        var seen: [Int] = []

        let stop = store.subscribe { seen.append($0) }
        store.set(2)
        store.set(2)
        store.set(3)
        stop()
        store.set(4)

        XCTAssertEqual(seen, [1, 2, 3])
    }

    func testUpdateUsesTheCurrentValue() {
        let store = Writable<[String]>([])

        store.update { $0 + ["a"] }
        store.update { $0 + ["b"] }

        XCTAssertEqual(store.get(), ["a", "b"])
    }

    func testStoresOfObjectsAlwaysNotify() {
        let node = Node(id: "a", position: XYPosition(x: 0, y: 0))
        let store = Writable<[Node]>([node])
        var calls = 0

        store.subscribeAny { calls += 1 }
        store.set(store.get())

        XCTAssertEqual(calls, 2)
    }

    func testSetOverrideTakesTheValueInsteadOfTheStore() {
        let store = Writable<Int>(0)
        var received: Int?

        store.setOverride = { received = $0 }
        store.set(5)

        XCTAssertEqual(received, 5)
        XCTAssertEqual(store.get(), 0)

        store.rawSet(7)
        XCTAssertEqual(store.get(), 7)
    }

    func testValuesSetWhileNotifyingAreToldInOrder() {
        let store = Writable<Int>(0)
        var seen: [Int] = []

        store.subscribe { value in
            seen.append(value)
            if value == 1 { store.set(2) }
        }
        store.subscribe { value in seen.append(value * 10) }

        store.set(1)

        XCTAssertEqual(seen, [0, 0, 1, 10, 2, 20])
    }

    func testDerivedFollowsItsDependencies() {
        let a = Writable<Int>(1)
        let b = Writable<Int>(10)
        let sum = Derived<Int>([a, b]) { a.get() + b.get() }
        var seen: [Int] = []

        let stop = sum.subscribe { seen.append($0) }
        a.set(2)
        b.set(20)
        stop()

        XCTAssertEqual(seen, [11, 12, 22])
        XCTAssertEqual(sum.get(), 22)
    }

    func testDerivedOnlyNotifiesWhenItsValueChanged() {
        let source = Writable<Int>(1)
        let sign = Derived<Bool>([source]) { source.get() > 0 }
        var calls = 0

        sign.subscribeAny { calls += 1 }
        source.set(2)
        source.set(3)
        source.set(-1)

        // once for the subscription, once for the sign that changed
        XCTAssertEqual(calls, 2)
    }

    func testQuietDependenciesOnlyNotifyWhenTheValueIsAnotherOne() {
        let nodes = [
            Node(id: "a", position: XYPosition(x: 0, y: 0)),
            Node(id: "b", position: XYPosition(x: 5, y: 5))
        ]
        let source = Writable<[Node]>(nodes)
        let viewport = Writable<Int>(0)
        let shown = Derived<[Node]>([source], quiet: [viewport], isEqual: sameObjects) {
            viewport.get() < 10 ? source.get() : [source.get()[0]]
        }
        var calls = 0
        shown.subscribeAny { calls += 1 }

        // the same nodes after the viewport moved
        viewport.set(1)
        viewport.set(2)
        XCTAssertEqual(calls, 1)

        // another set of nodes
        viewport.set(11)
        XCTAssertEqual(calls, 2)
        XCTAssertEqual(shown.get().map { $0.id }, ["a"])

        // the loud dependencies tell even when the objects are the same
        source.set(source.get())
        XCTAssertEqual(calls, 3)
    }

    func testSameObjectsComparesIdentityAndOrder() {
        let a = Node(id: "a", position: XYPosition(x: 0, y: 0))
        let b = Node(id: "a", position: XYPosition(x: 0, y: 0))

        XCTAssertTrue(sameObjects([a, b], [a, b]))
        XCTAssertFalse(sameObjects([a, b], [b, a]))
        XCTAssertFalse(sameObjects([a], [b]))
        XCTAssertFalse(sameObjects([a], [a, b]))
    }
}

final class KeyEventTests: XCTestCase {
    func testNamedKeysKeepTheirNames() {
        let shift = FlowKeyEvent(usage: 225, name: nil, modifiers: [.shift])

        XCTAssertEqual(shift?.key, "Shift")
        XCTAssertEqual(shift?.code, "ShiftLeft")
    }

    func testLettersAndDigitsAreKnownByTheirUsage() {
        XCTAssertEqual(FlowKeyEvent(usage: 4, name: nil, modifiers: [])?.key, "a")
        XCTAssertEqual(FlowKeyEvent(usage: 4, name: nil, modifiers: [])?.code, "KeyA")
        XCTAssertEqual(FlowKeyEvent(usage: 29, name: nil, modifiers: [])?.key, "z")
        XCTAssertEqual(FlowKeyEvent(usage: 4, name: nil, modifiers: [.shift])?.key, "A")

        XCTAssertEqual(FlowKeyEvent(usage: 30, name: nil, modifiers: [])?.key, "1")
        XCTAssertEqual(FlowKeyEvent(usage: 38, name: nil, modifiers: [])?.key, "9")
        XCTAssertEqual(FlowKeyEvent(usage: 39, name: nil, modifiers: [])?.key, "0")
        XCTAssertEqual(FlowKeyEvent(usage: 39, name: nil, modifiers: [])?.code, "Digit0")
    }

    func testOtherKeysUseTheNameOfTheKeyboard() {
        XCTAssertEqual(FlowKeyEvent(usage: 100, name: "\\", modifiers: [])?.key, "\\")
        XCTAssertNil(FlowKeyEvent(usage: 100, name: nil, modifiers: []))
        XCTAssertNil(FlowKeyEvent(usage: 100, name: "", modifiers: []))
    }
}

final class FlowStoreTests: XCTestCase {
    private func makeStore() -> SwiftFlowStore {
        SwiftFlowStore(
            nodes: [
                Node(id: "a", position: XYPosition(x: 0, y: 0), measured: Measured(width: 100, height: 40)),
                Node(id: "b", position: XYPosition(x: 200, y: 100), measured: Measured(width: 100, height: 40))
            ],
            edges: [Edge(id: "e", source: "a", target: "b")])
    }

    func testNodesAreAdopted() {
        let store = makeStore()

        XCTAssertEqual(store.nodeLookup.get().keys, ["a", "b"])
        XCTAssertEqual(store.edgeLookup.get().keys, ["e"])
        XCTAssertEqual(store.nodeLookup.get().get("b")?.internals.positionAbsolute.x, 200)
    }

    func testSelectingANodeUnselectsTheOthers() {
        let store = makeStore()

        store.addSelectedNodes(["a"])
        XCTAssertEqual(store.nodes.get().map { $0.selected }, [true, false])

        store.addSelectedNodes(["b"])
        XCTAssertEqual(store.nodes.get().map { $0.selected }, [false, true])
    }

    func testMultiSelectionKeepsTheOthers() {
        let store = makeStore()

        store.addSelectedNodes(["a"])
        store.multiselectionKeyPressed.set(true)
        store.addSelectedNodes(["b"])

        XCTAssertEqual(store.nodes.get().map { $0.selected }, [true, true])
    }

    func testUnselectAll() {
        let store = makeStore()
        store.addSelectedNodes(["a"])
        store.addSelectedEdges(["e"])

        store.unselectNodesAndEdges()

        XCTAssertEqual(store.nodes.get().compactMap { $0.selected }.filter { $0 }.count, 0)
        XCTAssertEqual(store.edges.get().first?.selected, false)
    }

    func testVisibleNodesAreOnlyToldWhenTheSetChanged() {
        let store = makeStore()
        // a node without measured handles is always rendered, so it can be measured
        for node in store.nodeLookup.get().values {
            node.internals.handleBounds = NodeHandleBounds(source: [], target: [])
        }
        store.onlyRenderVisibleElements.set(true)
        store.width.set(500)
        store.height.set(500)

        var calls = 0
        store.visibleNodes.subscribeAny { calls += 1 }
        XCTAssertEqual(store.visibleNodes.get().count, 2)

        // moved, and the same nodes are in view
        store.viewport.set(Viewport(x: -10, y: -10, zoom: 1))
        store.viewport.set(Viewport(x: -20, y: -10, zoom: 1))
        XCTAssertEqual(calls, 1)

        // moved so far that none is in view
        store.viewport.set(Viewport(x: -5000, y: 0, zoom: 1))
        XCTAssertEqual(calls, 2)
        XCTAssertEqual(store.visibleNodes.get().count, 0)

        // and back
        store.viewport.set(Viewport(x: 0, y: 0, zoom: 1))
        XCTAssertEqual(calls, 3)
        XCTAssertEqual(store.visibleNodes.get().count, 2)

        // a node that changed is told, even though it is the same object
        store.nodes.update { $0 }
        XCTAssertEqual(calls, 4)
    }

    func testTheConnectionIsOnlyToldOfTheViewportWhileOneIsMade() {
        let store = makeStore()
        var calls = 0
        store.connection.subscribeAny { calls += 1 }

        store.viewport.set(Viewport(x: 10, y: 10, zoom: 1))
        store.viewport.set(Viewport(x: 20, y: 10, zoom: 1))

        XCTAssertEqual(calls, 1)
    }

    func testVisibleEdgesNeedBothNodes() {
        let store = makeStore()

        XCTAssertEqual(store.visibleEdges.get().count, 0, "the nodes have no handles yet")
    }

    func testAddEdge() {
        let store = makeStore()

        store.addEdge(.connection(Connection(source: "b", target: "a", sourceHandle: nil, targetHandle: nil)))

        XCTAssertEqual(store.edges.get().count, 2)
        XCTAssertEqual(store.connectionLookup.get().get("b-source")?.count, 1)
    }

    func testDeleteKeyRemovesTheSelection() {
        let store = makeStore()
        var deleted: [String] = []
        store.ondelete.set { nodes, _ in deleted = nodes.map { $0.id } }

        store.addSelectedNodes(["a"])
        store.deleteKeyPressed.set(true)

        XCTAssertEqual(store.nodes.get().map { $0.id }, ["b"])
        XCTAssertEqual(deleted, ["a"])
        // the edge belongs to the node
        XCTAssertEqual(store.edges.get().count, 0)
    }

    func testAwaitedViewportCallsAnswerFalseWithoutAPanZoom() async {
        let instance = FlowInstance(store: makeStore())

        let zoomedIn = await instance.zoomIn()
        let zoomedOut = await instance.zoomOut()
        let zoomSet = await instance.setZoom(1)
        let viewportSet = await instance.setViewport(Viewport(x: 0, y: 0, zoom: 1))
        let centered = await instance.setCenter(0, 0)
        let fitted = await instance.fitBounds(Rect(x: 0, y: 0, width: 10, height: 10))
        let panned = await instance.store.panBy(XYPosition(x: 1, y: 1))

        XCTAssertEqual([zoomedIn, zoomedOut, zoomSet, viewportSet, centered, fitted, panned], Array(repeating: false, count: 7))
    }

    func testAwaitedDeleteAnswersWhatWasDeleted() async {
        let store = makeStore()
        let instance = FlowInstance(store: store)

        let deleted = await instance.deleteElements(nodes: ["a"])

        XCTAssertEqual(deleted.deletedNodes.map { $0.id }, ["a"])
        XCTAssertEqual(deleted.deletedEdges.map { $0.id }, ["e"])
        XCTAssertEqual(store.nodes.get().map { $0.id }, ["b"])
    }

    func testNodeTypesKeepTheBuiltInOnes() {
        let store = makeStore()

        store.setNodeTypes(["custom": { DefaultNodeView() }])

        XCTAssertNotNil(store.nodeTypes.get()["custom"])
        XCTAssertNotNil(store.nodeTypes.get()["input"])
        XCTAssertNotNil(store.nodeTypes.get()["default"])
    }
}
#endif
