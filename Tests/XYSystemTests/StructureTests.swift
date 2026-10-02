import XCTest
@testable import XYSystem

final class OrderedMapTests: XCTestCase {
    func testKeepsInsertionOrder() {
        let map = OrderedMap<String, Int>()
        map.set("b", 2)
        map.set("a", 1)
        map.set("c", 3)

        XCTAssertEqual(map.keys, ["b", "a", "c"])
        XCTAssertEqual(map.values, [2, 1, 3])
    }

    func testSettingAgainKeepsThePlace() {
        let map = OrderedMap<String, Int>([("a", 1), ("b", 2)])
        map.set("a", 10)

        XCTAssertEqual(map.keys, ["a", "b"])
        XCTAssertEqual(map.get("a"), 10)
    }

    func testDeletingAndSettingAgainMovesToTheEnd() {
        let map = OrderedMap<String, Int>([("a", 1), ("b", 2), ("c", 3)])

        XCTAssertTrue(map.delete("a"))
        XCTAssertFalse(map.delete("a"))
        map.set("a", 4)

        XCTAssertEqual(map.keys, ["b", "c", "a"])
        XCTAssertEqual(map.count, 3)
    }

    func testIterationIsNotAffectedByChangesWhileIterating() {
        let map = OrderedMap<String, Int>([("a", 1), ("b", 2), ("c", 3)])
        var seen: [String] = []

        for (key, _) in map {
            seen.append(key)
            map.delete("c")
        }

        // what was deleted before it was reached is skipped, like the entries of a Map
        XCTAssertEqual(seen, ["a", "b"])
    }

    func testIsAReferenceType() {
        let map = OrderedMap<String, Int>()
        let same = map
        same.set("x", 1)

        XCTAssertEqual(map.get("x"), 1)
    }

    func testCopyDoesNotShareEntries() {
        let map = OrderedMap<String, Int>([("a", 1)])
        let copy = OrderedMap(map)
        copy.set("b", 2)

        XCTAssertEqual(map.keys, ["a"])
        XCTAssertEqual(copy.keys, ["a", "b"])
    }
}

final class DispatchTests: XCTestCase {
    func testCallsListenersInTheOrderTheyWereAdded() {
        let dispatch = D3Dispatch<Int>(["start", "end"])
        var calls: [String] = []

        dispatch.on("start") { calls.append("one \($0)") }
        dispatch.on("start.second") { calls.append("two \($0)") }
        dispatch.call("start", 7)

        XCTAssertEqual(calls, ["one 7", "two 7"])
    }

    func testSettingTheSameNameReplacesTheListener() {
        let dispatch = D3Dispatch<Int>(["start"])
        var calls: [String] = []

        dispatch.on("start") { _ in calls.append("old") }
        dispatch.on("start") { _ in calls.append("new") }
        dispatch.call("start", 0)

        XCTAssertEqual(calls, ["new"])
    }

    func testRemovingAListener() {
        let dispatch = D3Dispatch<Int>(["start"])
        var calls = 0

        dispatch.on("start.a") { _ in calls += 1 }
        dispatch.on("start.a", nil)
        dispatch.call("start", 0)

        XCTAssertEqual(calls, 0)
        XCTAssertFalse(dispatch.has("start.a"))
    }
}

final class ZoomTransformTests: XCTestCase {
    func testApplyAndInvertAreInverse() {
        let transform = ZoomTransform(k: 2, x: 30, y: -10)
        let point = XYPosition(x: 12.5, y: 40)

        let applied = transform.apply(point)
        XCTAssertEqual(applied.x, 55, accuracy: 1e-9)
        XCTAssertEqual(applied.y, 70, accuracy: 1e-9)

        let back = transform.invert(applied)
        XCTAssertEqual(back.x, point.x, accuracy: 1e-9)
        XCTAssertEqual(back.y, point.y, accuracy: 1e-9)
    }

    func testScaleAndTranslate() {
        let transform = ZoomTransform.identity.translate(10, 20).scale(2)

        XCTAssertEqual(transform.k, 2)
        XCTAssertEqual(transform.x, 10)
        XCTAssertEqual(transform.y, 20)

        let moved = transform.translate(5, 5)
        XCTAssertEqual(moved.x, 20)
        XCTAssertEqual(moved.y, 30)
    }
}

final class ZoomBehaviorTests: XCTestCase {
    private func makeBehavior() -> D3ZoomBehavior {
        let behavior = D3ZoomBehavior(extent: { CoordinateExtent(0, 0, 400, 300) })
        behavior.setScaleExtent((0.5, 4))
        return behavior
    }

    func testScaleToIsClampedToTheScaleExtent() {
        let behavior = makeBehavior()

        behavior.scaleTo(10)
        XCTAssertEqual(behavior.transform.k, 4, accuracy: 1e-9)

        behavior.scaleTo(0.01)
        XCTAssertEqual(behavior.transform.k, 0.5, accuracy: 1e-9)
    }

    func testScaleByMultipliesTheScale() {
        let behavior = makeBehavior()

        behavior.scaleBy(2)
        XCTAssertEqual(behavior.transform.k, 2, accuracy: 1e-9)

        behavior.scaleBy(1.5)
        XCTAssertEqual(behavior.transform.k, 3, accuracy: 1e-9)
    }

    func testTranslateByMovesTheView() {
        let behavior = makeBehavior()

        behavior.translateBy(10, 20)
        XCTAssertEqual(behavior.transform.x, 10, accuracy: 1e-9)
        XCTAssertEqual(behavior.transform.y, 20, accuracy: 1e-9)
    }

    func testListenersAreToldOfTheGesture() {
        let behavior = makeBehavior()
        var events: [String] = []

        behavior.listeners.on("start") { _ in events.append("start") }
        behavior.listeners.on("zoom") { _ in events.append("zoom") }
        behavior.listeners.on("end") { _ in events.append("end") }

        behavior.scaleBy(2)

        XCTAssertEqual(events, ["start", "zoom", "end"])
    }

    func testMouseGesturePans() {
        let behavior = makeBehavior()

        let start = ZoomSourceEvent(type: "mousedown", clientX: 100, clientY: 100, point: XYPosition(x: 100, y: 100))
        XCTAssertTrue(behavior.mousedowned(start))

        let move = ZoomSourceEvent(type: "mousemove", clientX: 130, clientY: 90, point: XYPosition(x: 130, y: 90))
        behavior.mousemoved(move)

        let end = ZoomSourceEvent(type: "mouseup", clientX: 130, clientY: 90, point: XYPosition(x: 130, y: 90))
        behavior.mouseupped(end)

        XCTAssertEqual(behavior.transform.x, 30, accuracy: 1e-9)
        XCTAssertEqual(behavior.transform.y, -10, accuracy: 1e-9)
        XCTAssertFalse(behavior.isMouseGestureActive)
    }

    func testRightButtonDoesNotStartAGesture() {
        let behavior = makeBehavior()
        let start = ZoomSourceEvent(type: "mousedown", button: 2, clientX: 1, clientY: 1, point: XYPosition(x: 1, y: 1))

        XCTAssertFalse(behavior.mousedowned(start))
    }
}

final class DragBehaviorTests: XCTestCase {
    func testStartDragAndEnd() {
        let behavior = D3DragBehavior()
        var log: [String] = []

        behavior.listeners.on("start") { _ in log.append("start") }
        behavior.listeners.on("drag") { event in log.append("drag \(Int(event.dx)),\(Int(event.dy))") }
        behavior.listeners.on("end") { event in log.append("end \(event.moved)") }

        let down = FlowPointerEvent(clientX: 10, clientY: 10)
        XCTAssertTrue(behavior.pointerDown(down, point: XYPosition(x: 10, y: 10)))

        behavior.pointerMove(FlowPointerEvent(clientX: 15, clientY: 12), point: XYPosition(x: 15, y: 12))
        behavior.pointerUp(FlowPointerEvent(clientX: 15, clientY: 12), point: XYPosition(x: 15, y: 12))

        XCTAssertEqual(log, ["start", "drag 5,2", "end true"])
        XCTAssertFalse(behavior.isActive)
    }

    func testFilterDecidesWhetherItStarts() {
        let behavior = D3DragBehavior()
        behavior.filter = { _ in false }

        XCTAssertFalse(behavior.pointerDown(FlowPointerEvent(clientX: 0, clientY: 0), point: .zero))
    }

    func testAClickWithoutMovingIsNotMoved() {
        let behavior = D3DragBehavior()
        var moved: Bool?

        behavior.listeners.on("end") { moved = $0.moved }

        behavior.pointerDown(FlowPointerEvent(clientX: 5, clientY: 5), point: .zero)
        behavior.pointerUp(FlowPointerEvent(clientX: 5, clientY: 5), point: .zero)

        XCTAssertEqual(moved, false)
    }
}

final class ResizeTests: XCTestCase {
    func testClampIsInclusive() {
        XCTAssertEqual(clamp(5, 0, 10), 5)
        XCTAssertEqual(clamp(-5, 0, 10), 0)
        XCTAssertEqual(clamp(15, 0, 10), 10)
    }
}
