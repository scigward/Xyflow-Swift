import XCTest
@testable import XYSystem

/// The helpers and controllers of the flow, with random input: the answers are the ones of @xyflow/system 0.0.59.
final class ControllerGoldenTests: XCTestCase {
    private typealias Object = [String: Any]

    private static let golden: Object = {
        let data = Data(controllerGoldenJSON.utf8)
        return (try? JSONSerialization.jsonObject(with: data)) as? Object ?? [:]
    }()

    private func cases(_ key: String) -> [Object] {
        let list = (Self.golden[key] as? [Object]) ?? []
        XCTAssertFalse(list.isEmpty, "there are no cases for \(key)")
        return list
    }

    // MARK: Reading the data

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

    private func text(_ value: Any?) -> String? {
        value as? String
    }

    private func position(_ value: Any?) -> XYPosition {
        let object = value as? Object ?? [:]
        return XYPosition(x: number(object["x"]), y: number(object["y"]))
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
        _ actual: Double,
        _ expected: Any?,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual, number(expected), accuracy: 1e-9, label, file: file, line: line)
    }

    // MARK: Scenarios

    private func buildScenario(_ index: Int) -> (lookup: NodeLookup, parents: ParentLookup, object: Object) {
        let object = (Self.golden["scenarios"] as! [Object])[index]

        let nodes = (object["nodes"] as! [Object]).map { entry -> Node in
            let node = Node(id: entry["id"] as! String, position: XYPosition(x: number(entry["x"]), y: number(entry["y"])))

            if let width = entry["mw"] {
                node.measured = Measured(width: number(width), height: number(entry["mh"]))
            }

            if let width = entry["w"] {
                node.width = number(width)
                node.height = number(entry["h"])
            }

            node.parentId = entry["parentId"] as? String

            if let value = entry["extent"] {
                node.extent = text(value) == "parent" ? .parent : extent(value).map { .coordinates($0) }
            }

            if flag(entry["expandParent"]) {
                node.expandParent = true
            }

            if let value = entry["origin"] {
                node.origin = origin(value)
            }

            if let handles = entry["handles"] as? [Object] {
                node.handles = handles.map { handle in
                    NodeHandle(
                        id: text(handle["id"]),
                        x: number(handle["x"]),
                        y: number(handle["y"]),
                        position: Position(rawValue: text(handle["position"])!)!,
                        type: HandleType(rawValue: text(handle["type"])!)!,
                        width: handle["width"].map { number($0) },
                        height: handle["height"].map { number($0) })
                }
            }

            return node
        }

        let lookup = NodeLookup()
        let parents = ParentLookup()
        adoptUserNodes(
            nodes, lookup, parents,
            options: UpdateNodesOptions(
                nodeOrigin: origin(object["origin"]), elevateNodesOnSelect: false, checkEquality: false))

        for entry in object["nodes"] as! [Object] {
            guard let bounds = entry["hb"] as? Object, let node = lookup.get(entry["id"] as! String) else {
                continue
            }

            func handles(_ key: String, _ type: HandleType) -> [Handle] {
                (bounds[key] as! [Object]).map { handle in
                    Handle(
                        id: text(handle["id"]),
                        nodeId: node.id,
                        x: number(handle["x"]),
                        y: number(handle["y"]),
                        position: Position(rawValue: text(handle["position"])!)!,
                        type: type,
                        width: 6,
                        height: 6)
                }
            }

            node.internals.handleBounds = NodeHandleBounds(source: handles("source", .source), target: handles("target", .target))
        }

        return (lookup, parents, object)
    }

    // MARK: Resizing

    func testResize() {
        let all = cases("resize")
        XCTAssertGreaterThan(all.count, 100)

        for (index, entry) in all.enumerated() {
            let start = entry["start"] as! Object
            let pointer = entry["pointer"] as! Object
            let bounds = entry["bounds"] as! Object
            let control = ControlPosition(rawValue: text(entry["pos"])!)!
            let direction = getControlDirection(control)

            let expectedDirection = entry["direction"] as! Object
            XCTAssertEqual(direction.isHorizontal, flag(expectedDirection["isHorizontal"]), "case \(index)")
            XCTAssertEqual(direction.isVertical, flag(expectedDirection["isVertical"]), "case \(index)")
            XCTAssertEqual(direction.affectsX, flag(expectedDirection["affectsX"]), "case \(index)")
            XCTAssertEqual(direction.affectsY, flag(expectedDirection["affectsY"]), "case \(index)")

            let result = getDimensionsAfterResize(
                ResizeStartValues(
                    width: number(start["width"]),
                    height: number(start["height"]),
                    x: number(start["x"]),
                    y: number(start["y"]),
                    pointerX: number(start["pointerX"]),
                    pointerY: number(start["pointerY"]),
                    aspectRatio: number(start["aspectRatio"])),
                direction,
                PointerPosition(x: 0, y: 0, xSnapped: number(pointer["xSnapped"]), ySnapped: number(pointer["ySnapped"])),
                ResizeBoundaries(
                    minWidth: number(bounds["minWidth"]),
                    maxWidth: number(bounds["maxWidth"]),
                    minHeight: number(bounds["minHeight"]),
                    maxHeight: number(bounds["maxHeight"])),
                flag(entry["keep"]),
                origin(entry["origin"]),
                extent(entry["extent"]),
                extent(entry["childExtent"]))

            let expected = entry["expected"] as! Object
            assertEqual(result.x, expected["x"], "x of case \(index) (\(entry))")
            assertEqual(result.y, expected["y"], "y of case \(index) (\(entry))")
            assertEqual(result.width, expected["width"], "width of case \(index) (\(entry))")
            assertEqual(result.height, expected["height"], "height of case \(index) (\(entry))")
        }
    }

    func testResizeDirection() {
        for (index, entry) in cases("resizeDirection").enumerated() {
            let result = getResizeDirection(
                width: number(entry["width"]),
                prevWidth: number(entry["prevWidth"]),
                height: number(entry["height"]),
                prevHeight: number(entry["prevHeight"]),
                affectsX: flag(entry["affectsX"]),
                affectsY: flag(entry["affectsY"]))

            XCTAssertEqual(result, numbers(entry["expected"]), "case \(index)")
        }
    }

    // MARK: Where nodes go

    func testCalculateNodePosition() {
        for (index, entry) in cases("nodePosition").enumerated() {
            let scenario = buildScenario(Int(number(entry["scenario"])))
            var errors: [String] = []

            let result = calculateNodePosition(
                nodeId: text(entry["nodeId"])!,
                nextPosition: position(entry["next"]),
                nodeLookup: scenario.lookup,
                nodeOrigin: origin(entry["origin"]),
                nodeExtent: extent(entry["extent"]),
                onError: { code, _ in errors.append(code) })

            let expected = entry["expected"] as! Object
            let expectedPosition = expected["position"] as! Object
            let expectedAbsolute = expected["positionAbsolute"] as! Object

            assertEqual(result.position.x, expectedPosition["x"], "position.x of case \(index)")
            assertEqual(result.position.y, expectedPosition["y"], "position.y of case \(index)")
            assertEqual(result.positionAbsolute.x, expectedAbsolute["x"], "positionAbsolute.x of case \(index)")
            assertEqual(result.positionAbsolute.y, expectedAbsolute["y"], "positionAbsolute.y of case \(index)")
            XCTAssertEqual(errors, (entry["errors"] as! [Any]).map { $0 as! String }, "errors of case \(index)")
        }
    }

    // MARK: Handles

    private func handlesOf(_ node: InternalNode) -> [Handle] {
        (node.internals.handleBounds?.source ?? []) + (node.internals.handleBounds?.target ?? [])
    }

    func testHandlePosition() {
        for (index, entry) in cases("handlePosition").enumerated() {
            let scenario = buildScenario(Int(number(entry["scenario"])))
            let node = scenario.lookup.get(text(entry["nodeId"])!)!

            var chosen: Handle?
            if isNumber(entry["handleIndex"]) {
                chosen = handlesOf(node)[Int(number(entry["handleIndex"]))]
            }

            let result = getHandlePosition(
                node,
                handle: chosen,
                fallbackPosition: Position(rawValue: text(entry["fallback"])!)!,
                center: flag(entry["center"]))

            let expected = entry["expected"] as! Object
            assertEqual(result.x, expected["x"], "x of case \(index)")
            assertEqual(result.y, expected["y"], "y of case \(index)")
        }
    }

    func testEdgePosition() {
        for (index, entry) in cases("edgePosition").enumerated() {
            let scenario = buildScenario(Int(number(entry["scenario"])))
            var errors: [[String]] = []

            let result = getEdgePosition(GetEdgePositionParams(
                id: "e",
                sourceNode: scenario.lookup.get(text(entry["source"])!)!,
                sourceHandle: text(entry["sourceHandle"]),
                targetNode: scenario.lookup.get(text(entry["target"])!)!,
                targetHandle: text(entry["targetHandle"]),
                connectionMode: ConnectionMode(rawValue: text(entry["connectionMode"])!)!,
                onError: { code, message in errors.append([code, message]) }))

            if let expected = entry["expected"] as? Object {
                guard let result else {
                    XCTFail("case \(index) has no position")
                    continue
                }

                assertEqual(result.sourceX, expected["sourceX"], "sourceX of case \(index)")
                assertEqual(result.sourceY, expected["sourceY"], "sourceY of case \(index)")
                assertEqual(result.targetX, expected["targetX"], "targetX of case \(index)")
                assertEqual(result.targetY, expected["targetY"], "targetY of case \(index)")
                XCTAssertEqual(result.sourcePosition.rawValue, text(expected["sourcePosition"]), "case \(index)")
                XCTAssertEqual(result.targetPosition.rawValue, text(expected["targetPosition"]), "case \(index)")
            } else {
                XCTAssertNil(result, "case \(index)")
            }

            let expectedErrors = (entry["errors"] as! [[Any]]).map { $0.map { $0 as! String } }
            XCTAssertEqual(errors, expectedErrors, "errors of case \(index)")
        }
    }

    private func assertHandle(_ actual: Handle?, _ expected: Any?, _ label: String) {
        guard let expected = expected as? Object else {
            XCTAssertNil(actual, label)
            return
        }

        guard let actual else {
            XCTFail("\(label) has no handle")
            return
        }

        XCTAssertEqual(actual.id, text(expected["id"]), label)
        XCTAssertEqual(actual.nodeId, text(expected["nodeId"]), label)
        XCTAssertEqual(actual.type.rawValue, text(expected["type"]), label)
        XCTAssertEqual(actual.position.rawValue, text(expected["position"]), label)
        assertEqual(actual.x, expected["x"], "x of \(label)")
        assertEqual(actual.y, expected["y"], "y of \(label)")
        assertEqual(actual.width, expected["width"], "width of \(label)")
        assertEqual(actual.height, expected["height"], "height of \(label)")
    }

    func testClosestHandle() {
        for (index, entry) in cases("closestHandle").enumerated() {
            let scenario = buildScenario(Int(number(entry["scenario"])))
            let from = entry["fromHandle"] as! Object

            let result = getClosestHandle(
                position(entry["position"]),
                number(entry["radius"]),
                scenario.lookup,
                FromHandle(
                    nodeId: text(from["nodeId"])!,
                    type: HandleType(rawValue: text(from["type"])!)!,
                    id: text(from["id"])))

            assertHandle(result, entry["expected"], "case \(index)")
        }
    }

    func testHandleLookup() {
        for (index, entry) in cases("handleLookup").enumerated() {
            let scenario = buildScenario(Int(number(entry["scenario"])))

            let result = getHandle(
                text(entry["nodeId"])!,
                HandleType(rawValue: text(entry["type"])!)!,
                text(entry["handleId"]),
                scenario.lookup,
                ConnectionMode(rawValue: text(entry["mode"])!)!,
                withAbsolutePosition: flag(entry["absolute"]))

            assertHandle(result, entry["expected"], "case \(index)")
        }
    }

    // MARK: Parents

    func testExpandParent() {
        for (index, entry) in cases("expandParent").enumerated() {
            let scenario = buildScenario(Int(number(entry["scenario"])))

            let children = (entry["children"] as! [Object]).map { child -> ParentExpandChild in
                let rect = child["rect"] as! Object
                return ParentExpandChild(
                    id: text(child["id"])!,
                    parentId: text(child["parentId"])!,
                    rect: Rect(x: number(rect["x"]), y: number(rect["y"]), width: number(rect["width"]), height: number(rect["height"])))
            }

            let changes = handleExpandParent(children, scenario.lookup, scenario.parents, nodeOrigin: origin(entry["origin"]))
            let expected = entry["expected"] as! [Object]
            XCTAssertEqual(changes.count, expected.count, "number of changes of case \(index)")

            for (changeIndex, change) in changes.enumerated() where changeIndex < expected.count {
                let want = expected[changeIndex]
                let label = "change \(changeIndex) of case \(index)"
                XCTAssertEqual(change.id, text(want["id"]), label)

                switch change {
                case .position(let positionChange):
                    XCTAssertEqual(text(want["type"]), "position", label)
                    let wanted = want["position"] as! Object
                    assertEqual(positionChange.position?.x ?? .nan, wanted["x"], "x of \(label)")
                    assertEqual(positionChange.position?.y ?? .nan, wanted["y"], "y of \(label)")
                case .dimensions(let dimensionChange):
                    XCTAssertEqual(text(want["type"]), "dimensions", label)
                    XCTAssertEqual(dimensionChange.setAttributes, .enabled(true), label)
                    let wanted = want["dimensions"] as! Object
                    assertEqual(dimensionChange.dimensions?.width ?? .nan, wanted["width"], "width of \(label)")
                    assertEqual(dimensionChange.dimensions?.height ?? .nan, wanted["height"], "height of \(label)")
                }
            }
        }
    }

    // MARK: Deleting

    func testElementsToRemove() {
        for (index, entry) in cases("removal").enumerated() {
            let nodes = (entry["nodes"] as! [Object]).map { object -> Node in
                Node(
                    id: text(object["id"])!,
                    position: XYPosition(x: 0, y: 0),
                    deletable: object["deletable"].map { flag($0) },
                    parentId: text(object["parentId"]))
            }
            let edges = (entry["edges"] as! [Object]).map { object -> Edge in
                Edge(
                    id: text(object["id"])!,
                    source: text(object["source"])!,
                    target: text(object["target"])!,
                    deletable: object["deletable"].map { flag($0) })
            }

            var removed: (nodes: [String], edges: [String])?
            getElementsToRemove(
                nodesToRemove: (entry["nodesToRemove"] as! [Any]).map { $0 as! String },
                edgesToRemove: (entry["edgesToRemove"] as! [Any]).map { $0 as! String },
                nodes: nodes,
                edges: edges
            ) { matchingNodes, matchingEdges in
                removed = (matchingNodes.map { $0.id }, matchingEdges.map { $0.id })
            }

            let expected = entry["expected"] as! Object
            XCTAssertEqual(removed?.nodes, (expected["nodes"] as! [Any]).map { $0 as! String }, "nodes of case \(index)")
            XCTAssertEqual(removed?.edges, (expected["edges"] as! [Any]).map { $0 as! String }, "edges of case \(index)")
        }
    }

    // MARK: Edges

    func testEdgeZIndex() {
        let scenario = buildScenario(0)
        let ids = (scenario.object["nodes"] as! [Object]).map { $0["id"] as! String }

        for (index, entry) in cases("edgeZIndex").enumerated() {
            // any two nodes will do: only their z index and their selection count
            let source = scenario.lookup.get(ids[0])!
            let target = scenario.lookup.get(ids[1])!
            source.internals.z = number(entry["sourceZ"])
            target.internals.z = number(entry["targetZ"])
            source.selected = flag(entry["sourceSelected"])
            target.selected = flag(entry["targetSelected"])

            let result = getElevatedEdgeZIndex(GetEdgeZIndexParams(
                sourceNode: source,
                targetNode: target,
                selected: flag(entry["selected"]),
                zIndex: number(entry["zIndex"]),
                elevateOnSelect: flag(entry["elevateOnSelect"])))

            assertEqual(result, entry["expected"], "case \(index)")
        }
    }

    func testEdgeVisibility() {
        for (index, entry) in cases("edgeVisible").enumerated() {
            let scenario = buildScenario(Int(number(entry["scenario"])))
            let transform = numbers(entry["transform"])

            let result = isEdgeVisible(IsEdgeVisibleParams(
                sourceNode: scenario.lookup.get(text(entry["source"])!)!,
                targetNode: scenario.lookup.get(text(entry["target"])!)!,
                width: number(entry["width"]),
                height: number(entry["height"]),
                transform: Transform(transform[0], transform[1], transform[2])))

            XCTAssertEqual(result, flag(entry["expected"]), "case \(index)")
        }
    }
}
