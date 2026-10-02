import Foundation

/// What a drag behavior tells its listeners.
public struct D3DragEvent {
    public var type: String
    /// The pointer event that moved the drag.
    public var sourceEvent: FlowPointerEvent
    /// `"mouse"` or the identifier of the touch.
    public var identifier: Int
    /// How many gestures are active, the one of this event included.
    public var active: Int
    public var x: Double
    public var y: Double
    public var dx: Double
    public var dy: Double
    /// Whether the pointer moved further than the click distance since it went down.
    public var moved: Bool

    public init(
        type: String,
        sourceEvent: FlowPointerEvent,
        identifier: Int,
        active: Int,
        x: Double,
        y: Double,
        dx: Double,
        dy: Double,
        moved: Bool
    ) {
        self.type = type
        self.sourceEvent = sourceEvent
        self.identifier = identifier
        self.active = active
        self.x = x
        self.y = y
        self.dx = dx
        self.dy = dy
        self.moved = moved
    }
}

/// A drag behavior: the pointer going down, moving and coming up, as `start`, `drag` and `end`
/// events. This is d3-drag; the pointer events come from whoever hosts the element instead of
/// the DOM.
public final class D3DragBehavior {
    /// The identifier of the mouse; touches have their own.
    public static let mouseIdentifier = -1

    /// The default filter ignores right-click, since that should open the context menu.
    public static func defaultFilter(_ event: FlowPointerEvent) -> Bool {
        !event.ctrlKey && event.button == 0
    }

    public var filter: (FlowPointerEvent) -> Bool = D3DragBehavior.defaultFilter
    public let listeners = D3Dispatch<D3DragEvent>(["start", "drag", "end"])

    private var clickDistance2: Double = 0
    private var active = 0
    private var gestures: [Int: Gesture] = [:]

    private final class Gesture {
        var point: XYPosition
        var moved = false
        let downX: Double
        let downY: Double

        init(point: XYPosition, downX: Double, downY: Double) {
            self.point = point
            self.downX = downX
            self.downY = downY
        }
    }

    public init() {}

    @discardableResult
    public func setClickDistance(_ value: Double) -> D3DragBehavior {
        clickDistance2 = value * value
        return self
    }

    public var clickDistance: Double {
        clickDistance2.squareRoot()
    }

    /// The pointer went down. Returns whether a gesture started, which the filter decides.
    /// `point` is where the pointer is in the coordinates of the container of the element.
    @discardableResult
    public func pointerDown(
        _ event: FlowPointerEvent,
        point: XYPosition,
        identifier: Int = D3DragBehavior.mouseIdentifier
    ) -> Bool {
        if !filter(event) || gestures[identifier] != nil { return false }

        let gesture = Gesture(point: point, downX: event.clientX, downY: event.clientY)
        gestures[identifier] = gesture
        let n = active
        active += 1
        listeners.call(
            "start",
            D3DragEvent(
                type: "start", sourceEvent: event, identifier: identifier, active: n,
                x: point.x, y: point.y, dx: 0, dy: 0, moved: false))
        return true
    }

    public func pointerMove(
        _ event: FlowPointerEvent,
        point: XYPosition,
        identifier: Int = D3DragBehavior.mouseIdentifier
    ) {
        guard let gesture = gestures[identifier] else { return }

        if !gesture.moved {
            let dx = event.clientX - gesture.downX
            let dy = event.clientY - gesture.downY
            gesture.moved = dx * dx + dy * dy > clickDistance2
        }

        let previous = gesture.point
        gesture.point = point
        listeners.call(
            "drag",
            D3DragEvent(
                type: "drag", sourceEvent: event, identifier: identifier, active: active,
                x: point.x, y: point.y, dx: point.x - previous.x, dy: point.y - previous.y,
                moved: gesture.moved))
    }

    public func pointerUp(
        _ event: FlowPointerEvent,
        point: XYPosition,
        identifier: Int = D3DragBehavior.mouseIdentifier
    ) {
        guard let gesture = gestures[identifier] else { return }
        gestures[identifier] = nil
        active -= 1

        let previous = gesture.point
        gesture.point = point
        listeners.call(
            "end",
            D3DragEvent(
                type: "end", sourceEvent: event, identifier: identifier, active: active,
                x: point.x, y: point.y, dx: point.x - previous.x, dy: point.y - previous.y,
                moved: gesture.moved))
    }

    /// The pointer was lost, for instance by the system taking the touch: the drag ends where it is.
    public func cancel(identifier: Int = D3DragBehavior.mouseIdentifier, event: FlowPointerEvent) {
        guard let gesture = gestures[identifier] else { return }
        pointerUp(event, point: gesture.point, identifier: identifier)
    }

    public var isActive: Bool {
        active > 0
    }
}
