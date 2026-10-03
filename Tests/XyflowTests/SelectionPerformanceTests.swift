#if canImport(UIKit)
import XCTest
import XYSystem
@testable import Xyflow

final class SelectionPerformanceTests: XCTestCase {
    private func makeStore() -> SwiftFlowStore {
        SwiftFlowStore(
            nodes: [
                Node(id: "z", position: .zero, selected: false),
                Node(id: "a", position: .zero, selected: true),
                Node(id: "b", position: .zero, selected: false)
            ],
            edges: [
                Edge(id: "e-z", source: "z", target: "a", selected: false),
                Edge(id: "e-a", source: "a", target: "b", selected: true),
                Edge(id: "e-b", source: "b", target: "z", selected: false)
            ])
    }

    func testNodeSelectionKeepsOrderIdentityAndPublicationOrder() {
        let store = makeStore()
        let originalNodes = store.nodes.get()
        var publications: [String] = []
        let stopNodes = store.nodes.subscribeAny { publications.append("nodes") }
        let stopEdges = store.edges.subscribeAny { publications.append("edges") }
        defer { stopNodes(); stopEdges() }
        publications.removeAll()

        store.addSelectedNodes(["b", "missing", "b", "z"])

        XCTAssertEqual(store.nodes.get().map { $0.id }, ["z", "a", "b"])
        XCTAssertEqual(store.nodes.get().map { $0.selected }, [true, false, true])
        XCTAssertEqual(store.edges.get().map { $0.selected }, [false, false, false])
        XCTAssertTrue(zip(originalNodes, store.nodes.get()).allSatisfy { $0.0 === $0.1 })
        XCTAssertEqual(publications, ["nodes", "edges"])

        // An unchanged selection still publishes both stores, as before.
        store.addSelectedNodes(["z", "b"])
        XCTAssertEqual(publications, ["nodes", "edges", "nodes", "edges"])
    }

    func testEdgeSelectionKeepsMutationCopyAndPublicationOrder() {
        let store = makeStore()
        let originalEdges = store.edges.get()
        let originalNodes = store.nodes.get()
        var publications: [String] = []
        let stopNodes = store.nodes.subscribeAny { publications.append("nodes") }
        let stopEdges = store.edges.subscribeAny { publications.append("edges") }
        defer { stopNodes(); stopEdges() }
        publications.removeAll()

        store.addSelectedEdges(["e-b", "missing", "e-b", "e-z"])

        XCTAssertEqual(store.edges.get().map { $0.id }, ["e-z", "e-a", "e-b"])
        XCTAssertEqual(store.edges.get().map { $0.selected }, [true, false, true])
        XCTAssertEqual(originalEdges.map { $0.selected }, [true, false, true])
        // EdgesStore still copies the mutated edges while applying defaults.
        XCTAssertTrue(zip(originalEdges, store.edges.get()).allSatisfy { $0.0 !== $0.1 })
        XCTAssertEqual(store.nodes.get().map { $0.selected }, [false, false, false])
        XCTAssertTrue(zip(originalNodes, store.nodes.get()).allSatisfy { $0.0 === $0.1 })
        XCTAssertEqual(publications, ["edges", "nodes"])
    }

    func testNodeMultiSelectionKeepsOtherSelectionsAndOnlyPublishesNodes() {
        let store = makeStore()
        store.multiselectionKeyPressed.set(true)
        let originalEdges = store.edges.get()
        var publications: [String] = []
        let stopNodes = store.nodes.subscribeAny { publications.append("nodes") }
        let stopEdges = store.edges.subscribeAny { publications.append("edges") }
        defer { stopNodes(); stopEdges() }
        publications.removeAll()

        store.addSelectedNodes(["b", "b", "missing"])
        store.addSelectedNodes([])

        XCTAssertEqual(store.nodes.get().map { $0.selected }, [false, true, true])
        XCTAssertEqual(store.edges.get().map { $0.selected }, [false, true, false])
        XCTAssertTrue(zip(originalEdges, store.edges.get()).allSatisfy { $0.0 === $0.1 })
        XCTAssertEqual(publications, ["nodes", "nodes"])
    }

    func testEdgeMultiSelectionKeepsOtherSelectionsAndOnlyPublishesEdges() {
        let store = makeStore()
        store.multiselectionKeyPressed.set(true)
        var publications: [String] = []
        let stopNodes = store.nodes.subscribeAny { publications.append("nodes") }
        let stopEdges = store.edges.subscribeAny { publications.append("edges") }
        defer { stopNodes(); stopEdges() }
        publications.removeAll()

        store.addSelectedEdges(["e-b", "e-b", "missing"])
        store.addSelectedEdges([])

        XCTAssertEqual(store.edges.get().map { $0.selected }, [false, true, true])
        XCTAssertEqual(store.nodes.get().map { $0.selected }, [false, true, false])
        XCTAssertEqual(publications, ["edges", "edges"])
    }

    func testEmptySelectionClearsAllInSingleSelectionMode() {
        let nodeStore = makeStore()
        nodeStore.addSelectedNodes([])
        XCTAssertEqual(nodeStore.nodes.get().map { $0.selected }, [false, false, false])
        XCTAssertEqual(nodeStore.edges.get().map { $0.selected }, [false, false, false])

        let edgeStore = makeStore()
        edgeStore.addSelectedEdges([])
        XCTAssertEqual(edgeStore.nodes.get().map { $0.selected }, [false, false, false])
        XCTAssertEqual(edgeStore.edges.get().map { $0.selected }, [false, false, false])
    }

    func testEmptyStringIdRemainsASelectableId() {
        let store = SwiftFlowStore(
            nodes: [Node(id: "", position: .zero), Node(id: "other", position: .zero)],
            edges: [Edge(id: "", source: "", target: "other")])

        store.addSelectedNodes(["", "", "missing"])
        XCTAssertEqual(store.nodes.get().map { $0.selected }, [true, false])
        store.addSelectedEdges(["", "", "missing"])
        XCTAssertEqual(store.edges.get().map { $0.selected }, [true])
        XCTAssertEqual(store.nodes.get().map { $0.selected }, [false, false])
    }

    func testNodeClickStillTogglesOnlyDuringMultiSelection() {
        let store = makeStore()
        store.handleNodeSelection("b")
        store.handleNodeSelection("b")
        XCTAssertEqual(store.nodes.get().map { $0.selected }, [false, false, true])

        store.multiselectionKeyPressed.set(true)
        store.handleNodeSelection("a")
        XCTAssertEqual(store.nodes.get().map { $0.selected }, [false, true, true])
        store.handleNodeSelection("b")
        XCTAssertEqual(store.nodes.get().map { $0.selected }, [false, true, false])
    }
}
#endif
