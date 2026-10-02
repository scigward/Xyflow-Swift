import Foundation

public struct GetPointerPositionParams {
    public var transform: Transform
    public var snapGrid: SnapGrid
    public var snapToGrid: Bool
    public var containerBounds: Rect?

    public init(
        transform: Transform,
        snapGrid: SnapGrid = (0, 0),
        snapToGrid: Bool = false,
        containerBounds: Rect?
    ) {
        self.transform = transform
        self.snapGrid = snapGrid
        self.snapToGrid = snapToGrid
        self.containerBounds = containerBounds
    }
}

/// A position in the coordinates of the flow, and the same position snapped to the grid.
public struct PointerPosition: Equatable {
    public var x: Double
    public var y: Double
    public var xSnapped: Double
    public var ySnapped: Double

    public init(x: Double, y: Double, xSnapped: Double, ySnapped: Double) {
        self.x = x
        self.y = y
        self.xSnapped = xSnapped
        self.ySnapped = ySnapped
    }
}

public func getPointerPosition(_ event: FlowPointerEvent, _ params: GetPointerPositionParams) -> PointerPosition {
    let position = getEventPosition(event)
    let pointerPos = pointToRendererPoint(
        XYPosition(
            x: position.x - (params.containerBounds?.x ?? 0),
            y: position.y - (params.containerBounds?.y ?? 0)),
        transform: params.transform)
    let snapped = params.snapToGrid ? snapPosition(pointerPos, snapGrid: params.snapGrid) : pointerPos

    // we need the snapped position in order to be able to skip unnecessary drag events
    return PointerPosition(x: pointerPos.x, y: pointerPos.y, xSnapped: snapped.x, ySnapped: snapped.y)
}

public func getDimensions(_ node: NodeElement) -> Dimensions {
    node.dimensions
}

/// Whether a key event is for an input field: when one is focused, keys must not delete or move nodes.
public func isInputDOMNode(_ event: FlowKeyEvent, domNode: FlowDomNode? = nil) -> Bool {
    guard let target = event.target else { return false }

    if target is FlowTextInput {
        return true
    }

    // `closest('.nokey')`
    return domNode?.isWrapped(target, withClass: "nokey") ?? false
}

/// Views that take text implement this, so keys typed into them are not taken for the keys of the flow.
public protocol FlowTextInput: AnyObject {}

public func getEventPosition(_ event: FlowPointerEvent, _ bounds: Rect? = nil) -> XYPosition {
    XYPosition(x: event.clientX - (bounds?.x ?? 0), y: event.clientY - (bounds?.y ?? 0))
}

/// The handle bounds are calculated relative to the node element. We store them in the internals
/// object of the node in order to avoid unnecessary recalculations.
public func getHandleBounds(
    _ type: HandleType,
    nodeElement: NodeElement,
    nodeBounds: Rect,
    zoom: Double,
    nodeId: String
) -> [Handle]? {
    let handles = nodeElement.handleElements(of: type)

    if handles.isEmpty {
        return nil
    }

    return handles.map { handle in
        let handleBounds = handle.boundingClientRect
        let dimensions = handle.dimensions

        return Handle(
            id: handle.handleId,
            nodeId: nodeId,
            x: (handleBounds.x - nodeBounds.x) / zoom,
            y: (handleBounds.y - nodeBounds.y) / zoom,
            position: handle.handlePosition ?? .left,
            type: type,
            width: dimensions.width,
            height: dimensions.height)
    }
}
