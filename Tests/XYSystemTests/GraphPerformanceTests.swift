import XCTest
@testable import XYSystem

/// Narrow optimizations must keep the original ordered graph traversal and mutable-object results.
final class GraphPerformanceTests: XCTestCase {
    func testRemovalKeepsOrderedParentProcessingAndDuplicateNodes() {
        let nodes = [
            Node(id: "early", position: .zero, parentId: "parent"),
            Node(id: "parent", position: .zero),
            Node(id: "child", position: .zero, parentId: "parent"),
            Node(id: "grandchild", position: .zero, parentId: "child"),
            Node(id: "locked", position: .zero, deletable: false, parentId: "parent"),
            Node(id: "locked-child", position: .zero, parentId: "locked"),
            Node(id: "parent", position: .zero),
            Node(id: "child", position: .zero, parentId: "parent")
        ]
        var result: [Node] = []
        getElementsToRemove(nodesToRemove: ["parent", "parent"], nodes: nodes, edges: []) {
            result = $0
            XCTAssertTrue($1.isEmpty)
        }
        XCTAssertEqual(result.map { $0.id }, ["parent", "child", "grandchild", "parent", "child"])
        XCTAssertEqual(result.map { ObjectIdentifier($0) }, [1, 2, 3, 6, 7].map { ObjectIdentifier(nodes[$0]) })
    }

    func testRemovalKeepsConnectedEdgesFirstAndOnlyDeduplicatesExplicitExtras() {
        let node = Node(id: "parent", position: .zero)
        let edges = [
            Edge(id: "explicit", source: "x", target: "y"),
            Edge(id: "duplicate", source: "parent", target: "x"),
            Edge(id: "duplicate", source: "x", target: "y"),
            Edge(id: "duplicate", source: "parent", target: "y"),
            Edge(id: "locked", source: "parent", target: "x", deletable: false),
            Edge(id: "extra", source: "x", target: "y"),
            Edge(id: "extra", source: "y", target: "x")
        ]
        var result: [Edge] = []
        getElementsToRemove(nodesToRemove: [node.id],
                            edgesToRemove: ["explicit", "duplicate", "extra", "locked"],
                            nodes: [node], edges: edges) {
            XCTAssertTrue($0.first === node)
            result = $1
        }
        XCTAssertEqual(result.map { $0.id }, ["duplicate", "duplicate", "explicit", "extra"])
        XCTAssertEqual(result.map { ObjectIdentifier($0) }, [1, 3, 0, 5].map { ObjectIdentifier(edges[$0]) })
    }

    func testRemovalWaitsForCallbackAndPreservesReplacementObjects() {
        let selected = Node(id: "selected", position: .zero)
        let replacement = Node(id: "replacement", position: .zero)
        let edge = Edge(id: "edge", source: selected.id, target: "other")
        var reply: ((BeforeDeleteResult) -> Void)?
        var hookCalls = 0
        var completionCalls = 0
        getElementsToRemove(nodesToRemove: [selected.id], nodes: [selected], edges: [edge],
                            onBeforeDelete: { nodes, edges, done in
            hookCalls += 1
            XCTAssertTrue(nodes.first === selected)
            XCTAssertTrue(edges.first === edge)
            reply = done
        }) { nodes, edges in
            completionCalls += 1
            XCTAssertTrue(nodes.first === replacement)
            XCTAssertTrue(edges.isEmpty)
        }
        XCTAssertEqual(hookCalls, 1)
        XCTAssertEqual(completionCalls, 0)
        // The hook still receives the original mutable objects, not copies or an ID-only snapshot.
        selected.deletable = false
        reply?(.replace(nodes: [replacement], edges: []))
        XCTAssertEqual(completionCalls, 1)
    }

    func testRemovalCallbackAllowAndDenyAreUnchanged() {
        let node = Node(id: "node", position: .zero)
        let edge = Edge(id: "edge", source: node.id, target: "other")
        for allow in [true, false] {
            var calls = 0
            getElementsToRemove(nodesToRemove: [node.id], nodes: [node], edges: [edge],
                                onBeforeDelete: { _, _, done in done(allow ? .allow : .deny) }) { nodes, edges in
                calls += 1
                XCTAssertEqual(nodes.count, allow ? 1 : 0)
                XCTAssertEqual(edges.count, allow ? 1 : 0)
                if allow {
                    XCTAssertTrue(nodes.first === node)
                    XCTAssertTrue(edges.first === edge)
                }
            }
            XCTAssertEqual(calls, 1)
        }
    }

    private func internalNode(_ node: Node, measuredHandles: Bool = true) -> InternalNode {
        InternalNode(userNode: node, measured: node.measured ?? Measured(),
                     internals: InternalNode.Internals(positionAbsolute: node.position, z: 0, userNode: node,
                                                       handleBounds: measuredHandles ? NodeHandleBounds(source: [], target: []) : nil))
    }

    /// The pre-optimization formula, retained as an independent oracle for numerical edge cases.
    private func originalNodesInside(_ nodes: NodeLookup, rect: Rect, transform: Transform,
                                     partially: Bool, excludeNonSelectableNodes: Bool) -> [InternalNode] {
        let origin = pointToRendererPoint(rect, transform: transform)
        let paneRect = Rect(x: origin.x, y: origin.y,
                            width: rect.width / transform.scale, height: rect.height / transform.scale)
        var result: [InternalNode] = []
        for (_, node) in nodes {
            if (excludeNonSelectableNodes && !(node.selectable ?? true)) || (node.hidden ?? false) { continue }
            let width = node.measured.width ?? node.width ?? node.initialWidth
            let height = node.measured.height ?? node.height ?? node.initialHeight
            let overlap = getOverlappingArea(paneRect, nodeToRect(node))
            let area = (width ?? 0) * (height ?? 0)
            let visible = node.internals.handleBounds == nil || (partially && overlap > 0) || overlap >= area
            if visible || node.dragging == true { result.append(node) }
        }
        return result
    }

    func testVisibilityMatchesOriginalForDimensionFallbacksAndNumericalEdgeCases() {
        let lookup = NodeLookup()
        let nodes = [
            Node(id: "measured", position: XYPosition(x: 20, y: 20), width: 800, height: 800,
                 initialWidth: 900, initialHeight: 900, measured: Measured(width: 20, height: 20)),
            Node(id: "explicit", position: XYPosition(x: 20, y: 20), width: 20, height: 20,
                 initialWidth: 900, initialHeight: 900),
            Node(id: "initial", position: XYPosition(x: 20, y: 20), initialWidth: 20, initialHeight: 20),
            Node(id: "missing", position: XYPosition(x: 3000, y: 3000)),
            Node(id: "mixed", position: .zero, width: 15, height: 900,
                 initialHeight: 900, measured: Measured(height: 15)),
            Node(id: "hidden", position: .zero, hidden: true, measured: Measured(width: 20, height: 20)),
            Node(id: "dragging", position: XYPosition(x: 3000, y: 3000), dragging: true,
                 measured: Measured(width: 20, height: 20)),
            Node(id: "nonselectable", position: .zero, selectable: false, measured: Measured(width: 20, height: 20)),
            Node(id: "zero", position: .zero, measured: Measured(width: 0, height: 0)),
            Node(id: "nan", position: .zero, measured: Measured(width: .nan, height: 20)),
            Node(id: "infinite", position: .zero, measured: Measured(width: .infinity, height: 20)),
            Node(id: "unmeasured-handles", position: XYPosition(x: 3000, y: 3000), width: 20, height: 20)
        ]
        for node in nodes {
            lookup.set(node.id, internalNode(node, measuredHandles: node.id != "unmeasured-handles"))
        }
        let rect = Rect(x: 0, y: 0, width: 100, height: 100)
        for transform in [Transform(0, 0, 1), Transform(20, -10, 0.5), Transform(0, 0, 0), Transform(0, 0, .infinity)] {
            for partially in [false, true] {
                for exclude in [false, true] {
                    let actual = getNodesInside(lookup, rect: rect, transform: transform,
                                                partially: partially, excludeNonSelectableNodes: exclude)
                    let expected = originalNodesInside(lookup, rect: rect, transform: transform,
                                                       partially: partially, excludeNonSelectableNodes: exclude)
                    XCTAssertEqual(actual.map { ObjectIdentifier($0) }, expected.map { ObjectIdentifier($0) })
                }
            }
        }
        // No persistent cache: in-place dimension changes are visible on the next call.
        let measured = lookup.get("measured")!
        measured.measured = Measured(width: 800, height: 800)
        let actual = getNodesInside(lookup, rect: rect)
        let expected = originalNodesInside(lookup, rect: rect, transform: Transform(0, 0, 1),
                                           partially: false, excludeNonSelectableNodes: false)
        XCTAssertEqual(actual.map { ObjectIdentifier($0) }, expected.map { ObjectIdentifier($0) })
        XCTAssertFalse(actual.contains { $0 === measured })
    }
}
