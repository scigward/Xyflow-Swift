import XCTest
@testable import XYSystem

/// Measuring nodes: what happens to the nodes is what @xyflow/system 0.0.59 does with the same elements.
final class InternalsGoldenTests: XCTestCase {
    private typealias Object = [String: Any]

    // MARK: Elements

    private final class FakeHandle: HandleElement {
        let handleNodeId: String?
        let handleId: String?
        let handlePosition: Position?
        let handleType: HandleType?
        let handleIsConnectable = true
        let handleIsConnectableEnd = true
        let boundingClientRect: Rect
        let dimensions: Dimensions

        init(nodeId: String, id: String?, position: Position, type: HandleType, rect: Rect, dimensions: Dimensions) {
            handleNodeId = nodeId
            handleId = id
            handlePosition = position
            handleType = type
            boundingClientRect = rect
            self.dimensions = dimensions
        }
    }

    private final class FakeNodeElement: NodeElement {
        let dimensions: Dimensions
        let boundingClientRect: Rect
        private let handles: [FakeHandle]

        init(dimensions: Dimensions, rect: Rect, handles: [FakeHandle]) {
            self.dimensions = dimensions
            boundingClientRect = rect
            self.handles = handles
        }

        func handleElements(of type: HandleType) -> [HandleElement] {
            handles.filter { $0.handleType == type }
        }
    }

    private final class FakeDom: FlowDomNode {
        let boundingClientRect = Rect.zero
        let viewportScale: Double?

        init(zoom: Double) {
            viewportScale = zoom
        }

        func isWrapped(_ target: AnyObject?, withClass className: String) -> Bool { false }
        func target(atX x: Double, y: Double) -> AnyObject? { nil }
        func matches(_ target: AnyObject?, selector: String) -> Bool { false }
        func parent(of target: AnyObject) -> AnyObject? { nil }
    }

    // MARK: Reading the data

    private static let golden: Object = {
        let data = Data(internalsGoldenJSON.utf8)
        return (try? JSONSerialization.jsonObject(with: data)) as? Object ?? [:]
    }()

    private func number(_ value: Any?) -> Double {
        if let number = value as? NSNumber { return number.doubleValue }
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        XCTFail("not a number: \(String(describing: value))")
        return .nan
    }

    private func isNumber(_ value: Any?) -> Bool {
        value is NSNumber || value is Double || value is Int
    }

    private func numbers(_ value: Any?) -> [Double] {
        ((value as? [Any]) ?? []).map { number($0) }
    }

    private func flag(_ value: Any?) -> Bool {
        if let number = value as? NSNumber { return number.boolValue }
        return value as? Bool ?? false
    }

    private func extent(_ value: Any?) -> CoordinateExtent? {
        guard let pairs = value as? [[Any]], pairs.count == 2 else { return nil }
        let min = numbers(pairs[0])
        let max = numbers(pairs[1])
        return CoordinateExtent(min[0], min[1], max[0], max[1])
    }

    private func origin(_ value: Any?) -> NodeOrigin {
        let values = numbers(value)
        return NodeOrigin(values[0], values[1])
    }

    private func assertEqual(
        _ actual: Double?,
        _ expected: Any?,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if isNumber(expected) {
            XCTAssertEqual(actual ?? .nan, number(expected), accuracy: 1e-9, label, file: file, line: line)
        } else {
            XCTAssertNil(actual, label, file: file, line: line)
        }
    }

    // MARK: Nodes

    private func buildNodes(_ scenario: Object) -> (lookup: NodeLookup, parents: ParentLookup, nodes: [Object]) {
        let entries = scenario["nodes"] as! [Object]

        let nodes = entries.map { entry -> Node in
            let node = Node(id: entry["id"] as! String, position: XYPosition(x: number(entry["x"]), y: number(entry["y"])))

            if isNumber(entry["mw"]) {
                node.measured = Measured(width: number(entry["mw"]), height: number(entry["mh"]))
            }

            if isNumber(entry["w"]) {
                node.width = number(entry["w"])
                node.height = number(entry["h"])
            }

            node.parentId = entry["parentId"] as? String

            if let value = entry["extent"] {
                node.extent = (value as? String) == "parent" ? .parent : extent(value).map { .coordinates($0) }
            }

            if flag(entry["expandParent"]) {
                node.expandParent = true
            }

            if let value = entry["origin"] {
                node.origin = origin(value)
            }

            if flag(entry["hidden"]) {
                node.hidden = true
            }

            return node
        }

        let lookup = NodeLookup()
        let parents = ParentLookup()
        adoptUserNodes(
            nodes, lookup, parents,
            options: UpdateNodesOptions(
                nodeOrigin: origin(scenario["origin"]), elevateNodesOnSelect: false, checkEquality: false))

        return (lookup, parents, entries)
    }

    // MARK: Test

    func testMeasuringNodes() {
        let scenarios = Self.golden["scenarios"] as? [Object] ?? []
        let all = Self.golden["cases"] as? [Object] ?? []
        XCTAssertFalse(all.isEmpty)

        var comparedChanges = 0
        var comparedHandles = 0

        for (index, entry) in all.enumerated() {
            let scenario = scenarios[Int(number(entry["scenario"]))]
            let built = buildNodes(scenario)

            for id in (entry["measuredBefore"] as? [Any]) ?? [] {
                built.lookup.get(id as! String)?.internals.handleBounds = NodeHandleBounds(
                    source: [Handle(id: "s", nodeId: id as! String, x: 10, y: 10, position: .right, type: .source, width: 6, height: 6)],
                    target: [])
            }

            let updates = OrderedMap<String, InternalNodeUpdate>()
            for update in entry["updates"] as! [Object] {
                let id = update["id"] as! String
                let bounds = update["bounds"] as! Object

                func handles(_ key: String, _ type: HandleType) -> [FakeHandle] {
                    (update[key] as! [Object]).map { handle in
                        FakeHandle(
                            nodeId: id,
                            id: handle["id"] as? String,
                            position: Position(rawValue: handle["position"] as! String)!,
                            type: type,
                            rect: Rect(x: number(handle["left"]), y: number(handle["top"]), width: 0, height: 0),
                            dimensions: Dimensions(width: number(handle["width"]), height: number(handle["height"])))
                    }
                }

                let element = FakeNodeElement(
                    dimensions: Dimensions(width: number(update["width"]), height: number(update["height"])),
                    rect: Rect(x: number(bounds["left"]), y: number(bounds["top"]), width: 0, height: 0),
                    handles: handles("source", .source) + handles("target", .target))

                updates.set(id, InternalNodeUpdate(
                    id: id,
                    nodeElement: element,
                    force: update["force"].map { flag($0) }))
            }

            let result = updateNodeInternals(
                updates,
                built.lookup,
                built.parents,
                domNode: FakeDom(zoom: number(entry["zoom"])),
                nodeOrigin: origin(entry["nodeOrigin"]),
                nodeExtent: extent(entry["nodeExtent"]))

            let expected = entry["expected"] as! Object
            XCTAssertEqual(result.updatedInternals, flag(expected["updatedInternals"]), "updatedInternals of case \(index)")

            // the changes
            let expectedChanges = expected["changes"] as! [Object]
            XCTAssertEqual(result.changes.count, expectedChanges.count, "number of changes of case \(index)")

            for (changeIndex, change) in result.changes.enumerated() where changeIndex < expectedChanges.count {
                let want = expectedChanges[changeIndex]
                let label = "change \(changeIndex) of case \(index)"
                comparedChanges += 1
                XCTAssertEqual(change.id, want["id"] as? String, label)

                switch change {
                case .position(let positionChange):
                    XCTAssertEqual(want["type"] as? String, "position", label)
                    let wanted = want["position"] as! Object
                    assertEqual(positionChange.position?.x, wanted["x"], "x of \(label)")
                    assertEqual(positionChange.position?.y, wanted["y"], "y of \(label)")
                case .dimensions(let dimensionChange):
                    XCTAssertEqual(want["type"] as? String, "dimensions", label)
                    XCTAssertEqual(dimensionChange.setAttributes != nil, flag(want["setAttributes"]), label)
                    let wanted = want["dimensions"] as! Object
                    assertEqual(dimensionChange.dimensions?.width, wanted["width"], "width of \(label)")
                    assertEqual(dimensionChange.dimensions?.height, wanted["height"], "height of \(label)")
                }
            }

            // what became of the nodes
            for want in expected["after"] as! [Object] {
                let id = want["id"] as! String
                let label = "\(id) of case \(index)"

                guard let node = built.lookup.get(id) else {
                    XCTFail("\(label) is gone")
                    continue
                }

                if let measured = want["measured"] as? Object {
                    assertEqual(node.measured.width, measured["width"], "measured width of \(label)")
                    assertEqual(node.measured.height, measured["height"], "measured height of \(label)")
                }

                let absolute = want["positionAbsolute"] as! Object
                assertEqual(node.internals.positionAbsolute.x, absolute["x"], "x of \(label)")
                assertEqual(node.internals.positionAbsolute.y, absolute["y"], "y of \(label)")
                assertEqual(node.internals.z, want["z"], "z of \(label)")

                guard let bounds = want["handleBounds"] as? Object else {
                    XCTAssertNil(node.internals.handleBounds, "handle bounds of \(label)")
                    continue
                }

                guard let actualBounds = node.internals.handleBounds else {
                    XCTFail("\(label) has no handle bounds")
                    continue
                }

                for (key, actualList) in [("source", actualBounds.source), ("target", actualBounds.target)] {
                    guard let wanted = bounds[key] as? [Object] else {
                        XCTAssertNil(actualList, "\(key) handles of \(label)")
                        continue
                    }

                    XCTAssertEqual(actualList?.count, wanted.count, "number of \(key) handles of \(label)")

                    for (handleIndex, handle) in (actualList ?? []).enumerated() where handleIndex < wanted.count {
                        let item = wanted[handleIndex]
                        let handleLabel = "\(key) handle \(handleIndex) of \(label)"
                        comparedHandles += 1
                        XCTAssertEqual(handle.id, item["id"] as? String, handleLabel)
                        XCTAssertEqual(handle.nodeId, item["nodeId"] as? String, handleLabel)
                        XCTAssertEqual(handle.type.rawValue, item["type"] as? String, handleLabel)
                        XCTAssertEqual(handle.position.rawValue, item["position"] as? String, handleLabel)
                        assertEqual(handle.x, item["x"], "x of \(handleLabel)")
                        assertEqual(handle.y, item["y"], "y of \(handleLabel)")
                        assertEqual(handle.width, item["width"], "width of \(handleLabel)")
                        assertEqual(handle.height, item["height"], "height of \(handleLabel)")
                    }
                }
            }
        }

        // the cases do measure nodes and find handles, so the loops above do compare something
        XCTAssertGreaterThan(comparedChanges, 50)
        XCTAssertGreaterThan(comparedHandles, 100)
    }
}
