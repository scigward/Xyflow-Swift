import XCTest
@testable import XYSystem

/// Expected values come from running the same nodes and edges through @xyflow/system 0.0.59.
final class GraphGoldenTests: XCTestCase {
    func test_plain() {
        let nodes = [
            Node(id: "a", position: XYPosition(x: 0, y: 0), measured: Measured(width: 100, height: 40)),
            Node(id: "b", position: XYPosition(x: 200, y: 80), measured: Measured(width: 150, height: 60)),
            Node(id: "c", position: XYPosition(x: -50, y: 300), width: 80, height: 80)
        ]
        let edges = [
            Edge(id: "e1", source: "a", target: "b"),
            Edge(id: "e2", source: "b", target: "c"),
            Edge(id: "e3", source: "c", target: "a")
        ]
        let lookup = NodeLookup()
        let parents = ParentLookup()
        adoptUserNodes(nodes, lookup, parents, options: UpdateNodesOptions(nodeOrigin: NodeOrigin(0, 0), elevateNodesOnSelect: false, checkEquality: false))

        XCTAssertEqual(lookup.get("a")?.internals.positionAbsolute.x ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("a")?.internals.positionAbsolute.y ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("a")?.internals.z ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("b")?.internals.positionAbsolute.x ?? .nan, 200, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("b")?.internals.positionAbsolute.y ?? .nan, 80, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("b")?.internals.z ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("c")?.internals.positionAbsolute.x ?? .nan, -50, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("c")?.internals.positionAbsolute.y ?? .nan, 300, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("c")?.internals.z ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.keys, ["a","b","c"])
        XCTAssertEqual(parents.keys, [])

        do {
            let bounds = getInternalNodesBounds(lookup)
            XCTAssertEqual(bounds.x, -50, accuracy: 1e-9)
            XCTAssertEqual(bounds.y, 0, accuracy: 1e-9)
            XCTAssertEqual(bounds.width, 400, accuracy: 1e-9)
            XCTAssertEqual(bounds.height, 380, accuracy: 1e-9)
        }
        do {
            let bounds = getNodesBounds(nodes, nodeOrigin: NodeOrigin(0, 0))
            XCTAssertEqual(bounds.x, -50, accuracy: 1e-9)
            XCTAssertEqual(bounds.y, 0, accuracy: 1e-9)
            XCTAssertEqual(bounds.width, 400, accuracy: 1e-9)
            XCTAssertEqual(bounds.height, 380, accuracy: 1e-9)
        }
        for node in lookup.values { node.internals.handleBounds = NodeHandleBounds(source: [], target: []) }
        XCTAssertEqual(getNodesInside(lookup, rect: Rect(x: 0, y: 0, width: 120, height: 100), transform: Transform(0, 0, 1), partially: true).map { $0.id }, ["a"])
        XCTAssertEqual(getNodesInside(lookup, rect: Rect(x: 0, y: 0, width: 120, height: 100), transform: Transform(0, 0, 1), partially: false).map { $0.id }, ["a"])
        XCTAssertEqual(getNodesInside(lookup, rect: Rect(x: 100, y: 50, width: 300, height: 300), transform: Transform(20, -10, 0.5), partially: true).map { $0.id }, ["b"])
        XCTAssertEqual(getConnectedEdges([nodes[0]], edges).map { $0.id }, ["e1","e3"])
        XCTAssertEqual(getIncomers(nodes[0], nodes: nodes, edges: edges).map { $0.id }, ["c"])
        XCTAssertEqual(getOutgoers(nodes[0], nodes: nodes, edges: edges).map { $0.id }, ["b"])
        do {
            let connections = ConnectionLookup()
            let edgeLookup = EdgeLookup()
            updateConnectionLookup(connections, edgeLookup, edges)
            XCTAssertEqual(connections.keys, ["a","a-source","b","b-target","b-source","c","c-target","c-source","a-target"])
            XCTAssertEqual(connections.get("a")?.keys ?? [], ["b-null--a-null","c-null--a-null"])
            XCTAssertEqual(connections.get("a-source")?.keys ?? [], ["b-null--a-null"])
            XCTAssertEqual(connections.get("b")?.keys ?? [], ["a-null--b-null","c-null--b-null"])
            XCTAssertEqual(connections.get("b-target")?.keys ?? [], ["a-null--b-null"])
            XCTAssertEqual(connections.get("b-source")?.keys ?? [], ["c-null--b-null"])
            XCTAssertEqual(connections.get("c")?.keys ?? [], ["b-null--c-null","a-null--c-null"])
            XCTAssertEqual(connections.get("c-target")?.keys ?? [], ["b-null--c-null"])
            XCTAssertEqual(connections.get("c-source")?.keys ?? [], ["a-null--c-null"])
            XCTAssertEqual(connections.get("a-target")?.keys ?? [], ["c-null--a-null"])
            XCTAssertEqual(edgeLookup.keys, ["e1","e2","e3"])
        }
    }

    func test_centeredOrigin() {
        let nodes = [
            Node(id: "a", position: XYPosition(x: 100, y: 100), measured: Measured(width: 100, height: 40)),
            Node(id: "b", position: XYPosition(x: 300, y: 100), measured: Measured(width: 60, height: 60))
        ]
        let edges = [
            Edge(id: "e1", source: "a", target: "b")
        ]
        let lookup = NodeLookup()
        let parents = ParentLookup()
        adoptUserNodes(nodes, lookup, parents, options: UpdateNodesOptions(nodeOrigin: NodeOrigin(0.5, 0.5), elevateNodesOnSelect: false, checkEquality: false))

        XCTAssertEqual(lookup.get("a")?.internals.positionAbsolute.x ?? .nan, 50, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("a")?.internals.positionAbsolute.y ?? .nan, 80, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("a")?.internals.z ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("b")?.internals.positionAbsolute.x ?? .nan, 270, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("b")?.internals.positionAbsolute.y ?? .nan, 70, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("b")?.internals.z ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.keys, ["a","b"])
        XCTAssertEqual(parents.keys, [])

        do {
            let bounds = getInternalNodesBounds(lookup)
            XCTAssertEqual(bounds.x, 50, accuracy: 1e-9)
            XCTAssertEqual(bounds.y, 70, accuracy: 1e-9)
            XCTAssertEqual(bounds.width, 280, accuracy: 1e-9)
            XCTAssertEqual(bounds.height, 60, accuracy: 1e-9)
        }
        do {
            let bounds = getNodesBounds(nodes, nodeOrigin: NodeOrigin(0.5, 0.5))
            XCTAssertEqual(bounds.x, 50, accuracy: 1e-9)
            XCTAssertEqual(bounds.y, 70, accuracy: 1e-9)
            XCTAssertEqual(bounds.width, 280, accuracy: 1e-9)
            XCTAssertEqual(bounds.height, 60, accuracy: 1e-9)
        }
        for node in lookup.values { node.internals.handleBounds = NodeHandleBounds(source: [], target: []) }
        XCTAssertEqual(getNodesInside(lookup, rect: Rect(x: 0, y: 0, width: 200, height: 200), transform: Transform(0, 0, 1), partially: true).map { $0.id }, ["a"])
        XCTAssertEqual(getConnectedEdges([nodes[0]], edges).map { $0.id }, ["e1"])
        XCTAssertEqual(getIncomers(nodes[0], nodes: nodes, edges: edges).map { $0.id }, [])
        XCTAssertEqual(getOutgoers(nodes[0], nodes: nodes, edges: edges).map { $0.id }, ["b"])
        do {
            let connections = ConnectionLookup()
            let edgeLookup = EdgeLookup()
            updateConnectionLookup(connections, edgeLookup, edges)
            XCTAssertEqual(connections.keys, ["a","a-source","b","b-target"])
            XCTAssertEqual(connections.get("a")?.keys ?? [], ["b-null--a-null"])
            XCTAssertEqual(connections.get("a-source")?.keys ?? [], ["b-null--a-null"])
            XCTAssertEqual(connections.get("b")?.keys ?? [], ["a-null--b-null"])
            XCTAssertEqual(connections.get("b-target")?.keys ?? [], ["a-null--b-null"])
            XCTAssertEqual(edgeLookup.keys, ["e1"])
        }
    }

    func test_parentsAndSelection() {
        let nodes = [
            Node(id: "p", position: XYPosition(x: 100, y: 100), measured: Measured(width: 300, height: 200)),
            Node(id: "c1", position: XYPosition(x: 10, y: 20), parentId: "p", measured: Measured(width: 50, height: 30)),
            Node(id: "c2", position: XYPosition(x: 120, y: 60), selected: true, parentId: "p", measured: Measured(width: 50, height: 30)),
            Node(id: "free", position: XYPosition(x: 500, y: 20), zIndex: 3, measured: Measured(width: 40, height: 40)),
            Node(id: "hidden", position: XYPosition(x: 0, y: 0), hidden: true, measured: Measured(width: 10, height: 10))
        ]
        let edges = [
            Edge(id: "e1", source: "c1", target: "c2"),
            Edge(id: "e2", source: "p", target: "free")
        ]
        let lookup = NodeLookup()
        let parents = ParentLookup()
        adoptUserNodes(nodes, lookup, parents, options: UpdateNodesOptions(nodeOrigin: NodeOrigin(0, 0), elevateNodesOnSelect: true, checkEquality: false))

        XCTAssertEqual(lookup.get("p")?.internals.positionAbsolute.x ?? .nan, 100, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("p")?.internals.positionAbsolute.y ?? .nan, 100, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("p")?.internals.z ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("c1")?.internals.positionAbsolute.x ?? .nan, 110, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("c1")?.internals.positionAbsolute.y ?? .nan, 120, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("c1")?.internals.z ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("c2")?.internals.positionAbsolute.x ?? .nan, 220, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("c2")?.internals.positionAbsolute.y ?? .nan, 160, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("c2")?.internals.z ?? .nan, 1000, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("free")?.internals.positionAbsolute.x ?? .nan, 500, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("free")?.internals.positionAbsolute.y ?? .nan, 20, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("free")?.internals.z ?? .nan, 3, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("hidden")?.internals.positionAbsolute.x ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("hidden")?.internals.positionAbsolute.y ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.get("hidden")?.internals.z ?? .nan, 0, accuracy: 1e-9)
        XCTAssertEqual(lookup.keys, ["p","c1","c2","free","hidden"])
        XCTAssertEqual(parents.get("p")?.keys ?? [], ["c1","c2"])
        XCTAssertEqual(parents.keys, ["p"])

        do {
            let bounds = getInternalNodesBounds(lookup)
            XCTAssertEqual(bounds.x, 0, accuracy: 1e-9)
            XCTAssertEqual(bounds.y, 0, accuracy: 1e-9)
            XCTAssertEqual(bounds.width, 540, accuracy: 1e-9)
            XCTAssertEqual(bounds.height, 300, accuracy: 1e-9)
        }
        do {
            let bounds = getNodesBounds(nodes, nodeOrigin: NodeOrigin(0, 0))
            XCTAssertEqual(bounds.x, 0, accuracy: 1e-9)
            XCTAssertEqual(bounds.y, 0, accuracy: 1e-9)
            XCTAssertEqual(bounds.width, 540, accuracy: 1e-9)
            XCTAssertEqual(bounds.height, 300, accuracy: 1e-9)
        }
        for node in lookup.values { node.internals.handleBounds = NodeHandleBounds(source: [], target: []) }
        XCTAssertEqual(getNodesInside(lookup, rect: Rect(x: 100, y: 100, width: 100, height: 100), transform: Transform(0, 0, 1), partially: true).map { $0.id }, ["p","c1"])
        XCTAssertEqual(getNodesInside(lookup, rect: Rect(x: 0, y: 0, width: 1000, height: 1000), transform: Transform(0, 0, 1), partially: false).map { $0.id }, ["p","c1","c2","free"])
        XCTAssertEqual(getConnectedEdges([nodes[0]], edges).map { $0.id }, ["e2"])
        XCTAssertEqual(getIncomers(nodes[0], nodes: nodes, edges: edges).map { $0.id }, [])
        XCTAssertEqual(getOutgoers(nodes[0], nodes: nodes, edges: edges).map { $0.id }, ["free"])
        do {
            let connections = ConnectionLookup()
            let edgeLookup = EdgeLookup()
            updateConnectionLookup(connections, edgeLookup, edges)
            XCTAssertEqual(connections.keys, ["c1","c1-source","c2","c2-target","p","p-source","free","free-target"])
            XCTAssertEqual(connections.get("c1")?.keys ?? [], ["c2-null--c1-null"])
            XCTAssertEqual(connections.get("c1-source")?.keys ?? [], ["c2-null--c1-null"])
            XCTAssertEqual(connections.get("c2")?.keys ?? [], ["c1-null--c2-null"])
            XCTAssertEqual(connections.get("c2-target")?.keys ?? [], ["c1-null--c2-null"])
            XCTAssertEqual(connections.get("p")?.keys ?? [], ["free-null--p-null"])
            XCTAssertEqual(connections.get("p-source")?.keys ?? [], ["free-null--p-null"])
            XCTAssertEqual(connections.get("free")?.keys ?? [], ["p-null--free-null"])
            XCTAssertEqual(connections.get("free-target")?.keys ?? [], ["p-null--free-null"])
            XCTAssertEqual(edgeLookup.keys, ["e1","e2"])
        }
    }

    func testAddEdge() {
        do {
            let existing = [Edge(id: "a", source: "1", target: "2")]
            let result = addEdge(.connection(Connection(source: "2", target: "3", sourceHandle: nil, targetHandle: nil)), existing)
            XCTAssertEqual(result.map { $0.id }, ["a","xy-edge__2-3"])
        }
        do {
            let existing = [Edge(id: "a", source: "1", target: "2")]
            let result = addEdge(.edge(Edge(id: "dup", source: "1", target: "2")), existing)
            XCTAssertEqual(result.map { $0.id }, ["a"])
        }
    }
}
