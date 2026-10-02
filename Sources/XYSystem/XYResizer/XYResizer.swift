import Foundation

public struct XYResizerChange: Equatable {
    public var x: Double?
    public var y: Double?
    public var width: Double?
    public var height: Double?

    public init(x: Double? = nil, y: Double? = nil, width: Double? = nil, height: Double? = nil) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct XYResizerChildChange {
    public var id: String
    public var position: XYPosition
    public var extent: NodeExtent?

    public init(id: String, position: XYPosition, extent: NodeExtent? = nil) {
        self.id = id
        self.position = position
        self.extent = extent
    }
}

public struct XYResizerStoreItems {
    public var nodeLookup: NodeLookup
    public var transform: Transform
    public var snapGrid: SnapGrid?
    public var snapToGrid: Bool
    public var nodeOrigin: NodeOrigin
    public var paneDomNode: FlowDomNode?

    public init(
        nodeLookup: NodeLookup,
        transform: Transform,
        snapGrid: SnapGrid? = nil,
        snapToGrid: Bool,
        nodeOrigin: NodeOrigin,
        paneDomNode: FlowDomNode?
    ) {
        self.nodeLookup = nodeLookup
        self.transform = transform
        self.snapGrid = snapGrid
        self.snapToGrid = snapToGrid
        self.nodeOrigin = nodeOrigin
        self.paneDomNode = paneDomNode
    }
}

public struct XYResizerParams {
    public var nodeId: String
    public var getStoreItems: () -> XYResizerStoreItems
    public var onChange: (_ changes: XYResizerChange, _ childChanges: [XYResizerChildChange]) -> Void
    public var onEnd: ((ResizeParams) -> Void)?

    public init(
        nodeId: String,
        getStoreItems: @escaping () -> XYResizerStoreItems,
        onChange: @escaping (_ changes: XYResizerChange, _ childChanges: [XYResizerChildChange]) -> Void,
        onEnd: ((ResizeParams) -> Void)? = nil
    ) {
        self.nodeId = nodeId
        self.getStoreItems = getStoreItems
        self.onChange = onChange
        self.onEnd = onEnd
    }
}

public struct XYResizerUpdateParams {
    public var controlPosition: ControlPosition
    public var boundaries: ResizeBoundaries
    public var keepAspectRatio: Bool
    public var resizeDirection: ResizeControlDirection?
    public var onResizeStart: OnResizeStart?
    public var onResize: OnResize?
    public var onResizeEnd: OnResizeEnd?
    public var shouldResize: ShouldResize?

    public init(
        controlPosition: ControlPosition,
        boundaries: ResizeBoundaries,
        keepAspectRatio: Bool,
        resizeDirection: ResizeControlDirection? = nil,
        onResizeStart: OnResizeStart? = nil,
        onResize: OnResize? = nil,
        onResizeEnd: OnResizeEnd? = nil,
        shouldResize: ShouldResize? = nil
    ) {
        self.controlPosition = controlPosition
        self.boundaries = boundaries
        self.keepAspectRatio = keepAspectRatio
        self.resizeDirection = resizeDirection
        self.onResizeStart = onResizeStart
        self.onResize = onResize
        self.onResizeEnd = onResizeEnd
        self.shouldResize = shouldResize
    }
}

private func nodeToParentExtent(_ node: InternalNode) -> CoordinateExtent {
    CoordinateExtent(0, 0, node.measured.width ?? 0, node.measured.height ?? 0)
}

private func nodeToChildExtent(_ child: InternalNode, _ parent: InternalNode, _ nodeOrigin: NodeOrigin) -> CoordinateExtent {
    let x = parent.position.x + child.position.x
    let y = parent.position.y + child.position.y
    let width = child.measured.width ?? 0
    let height = child.measured.height ?? 0
    let originOffsetX = nodeOrigin.x * width
    let originOffsetY = nodeOrigin.y * height

    return CoordinateExtent(
        x - originOffsetX, y - originOffsetY,
        x + width - originOffsetX, y + height - originOffsetY)
}

/// The controller that resizes a node from one of the controls of its resizer. The host of the
/// control feeds the pointer to `behavior`.
public final class XYResizer {
    /// The drag behavior the pointer of the control goes to.
    public let behavior = D3DragBehavior()

    private let params: XYResizerParams

    public init(_ params: XYResizerParams) {
        self.params = params
    }

    public func update(_ updateParams: XYResizerUpdateParams) {
        let params = self.params
        let nodeId = params.nodeId
        let getStoreItems = params.getStoreItems
        let boundaries = updateParams.boundaries
        let keepAspectRatio = updateParams.keepAspectRatio
        let resizeDirection = updateParams.resizeDirection

        var prevValues = ResizeParams(x: 0, y: 0, width: 0, height: 0)
        var startValues = ResizeStartValues()

        let controlDirection = getControlDirection(updateParams.controlPosition)

        var node: InternalNode?
        var containerBounds: Rect?
        var childNodes: [XYResizerChildChange] = []
        // Needed to fix expandParent
        var parentNode: InternalNode?
        var parentExtent: CoordinateExtent?
        var childExtent: CoordinateExtent?

        behavior.listeners.on("start") { event in
            let items = getStoreItems()
            node = items.nodeLookup.get(nodeId)

            guard let node else {
                return
            }

            containerBounds = items.paneDomNode?.boundingClientRect
            let pointer = getPointerPosition(
                event.sourceEvent,
                GetPointerPositionParams(
                    transform: items.transform,
                    snapGrid: items.snapGrid ?? (0, 0),
                    snapToGrid: items.snapToGrid,
                    containerBounds: containerBounds))

            prevValues = ResizeParams(
                x: node.position.x,
                y: node.position.y,
                width: node.measured.width ?? 0,
                height: node.measured.height ?? 0)

            startValues = ResizeStartValues(
                width: prevValues.width,
                height: prevValues.height,
                x: prevValues.x,
                y: prevValues.y,
                pointerX: pointer.xSnapped,
                pointerY: pointer.ySnapped,
                aspectRatio: prevValues.width / prevValues.height)

            parentNode = nil

            if let parentId = node.parentId {
                var isParentExtent = false
                if case .parent? = node.extent { isParentExtent = true }

                if isParentExtent || node.expandParent == true {
                    parentNode = items.nodeLookup.get(parentId)
                    parentExtent = parentNode != nil && isParentExtent ? nodeToParentExtent(parentNode!) : nil
                }
            }

            // Collect all child nodes to correct their relative positions when top/left changes
            // Determine largest minimal extent the parent node is allowed to resize to
            childNodes = []
            childExtent = nil

            for (childId, child) in items.nodeLookup {
                if child.parentId == nodeId {
                    childNodes.append(XYResizerChildChange(id: childId, position: child.position, extent: child.extent))

                    var isChildParentExtent = false
                    if case .parent? = child.extent { isChildParentExtent = true }

                    if isChildParentExtent || child.expandParent == true {
                        let extent = nodeToChildExtent(child, node, child.origin ?? items.nodeOrigin)

                        if let current = childExtent {
                            childExtent = CoordinateExtent(
                                jsMin(extent.minX, current.minX), jsMin(extent.minY, current.minY),
                                jsMax(extent.maxX, current.maxX), jsMax(extent.maxY, current.maxY))
                        } else {
                            childExtent = extent
                        }
                    }
                }
            }

            updateParams.onResizeStart?(event, prevValues)
        }

        behavior.listeners.on("drag") { event in
            let items = getStoreItems()
            let pointerPosition = getPointerPosition(
                event.sourceEvent,
                GetPointerPositionParams(
                    transform: items.transform,
                    snapGrid: items.snapGrid ?? (0, 0),
                    snapToGrid: items.snapToGrid,
                    containerBounds: containerBounds))

            var childChanges: [XYResizerChildChange] = []

            guard let node else {
                return
            }

            let prevX = prevValues.x
            let prevY = prevValues.y
            let prevWidth = prevValues.width
            let prevHeight = prevValues.height
            var change = XYResizerChange()
            let nodeOrigin = node.origin ?? items.nodeOrigin

            let resized = getDimensionsAfterResize(
                startValues,
                controlDirection,
                pointerPosition,
                boundaries,
                keepAspectRatio,
                nodeOrigin,
                parentExtent,
                childExtent)
            let width = resized.width
            let height = resized.height
            let x = resized.x
            let y = resized.y

            let isWidthChange = width != prevWidth
            let isHeightChange = height != prevHeight

            let isXPosChange = x != prevX && isWidthChange
            let isYPosChange = y != prevY && isHeightChange

            if !isXPosChange && !isYPosChange && !isWidthChange && !isHeightChange {
                return
            }

            if isXPosChange || isYPosChange || nodeOrigin.x == 1 || nodeOrigin.y == 1 {
                change.x = isXPosChange ? x : prevValues.x
                change.y = isYPosChange ? y : prevValues.y

                prevValues.x = change.x!
                prevValues.y = change.y!

                // when top/left changes, correct the relative positions of child nodes
                // so that they stay in the same position
                if !childNodes.isEmpty {
                    let xChange = x - prevX
                    let yChange = y - prevY

                    for index in childNodes.indices {
                        childNodes[index].position = XYPosition(
                            x: childNodes[index].position.x - xChange + nodeOrigin.x * (width - prevWidth),
                            y: childNodes[index].position.y - yChange + nodeOrigin.y * (height - prevHeight))
                        childChanges.append(childNodes[index])
                    }
                }
            }

            if isWidthChange || isHeightChange {
                change.width = isWidthChange && (resizeDirection == nil || resizeDirection == .horizontal)
                    ? width : prevValues.width
                change.height = isHeightChange && (resizeDirection == nil || resizeDirection == .vertical)
                    ? height : prevValues.height
                prevValues.width = change.width!
                prevValues.height = change.height!
            }

            // Fix expandParent when resizing from top/left
            if parentNode != nil && node.expandParent == true {
                let xLimit = nodeOrigin.x * (change.width ?? 0)
                if let changeX = change.x, changeX != 0, changeX < xLimit {
                    prevValues.x = xLimit
                    startValues.x = startValues.x - (changeX - xLimit)
                }

                let yLimit = nodeOrigin.y * (change.height ?? 0)
                if let changeY = change.y, changeY != 0, changeY < yLimit {
                    prevValues.y = yLimit
                    startValues.y = startValues.y - (changeY - yLimit)
                }
            }

            let direction = getResizeDirection(
                width: prevValues.width,
                prevWidth: prevWidth,
                height: prevValues.height,
                prevHeight: prevHeight,
                affectsX: controlDirection.affectsX,
                affectsY: controlDirection.affectsY)

            let nextValues = ResizeParamsWithDirection(
                x: prevValues.x, y: prevValues.y, width: prevValues.width, height: prevValues.height,
                direction: direction)

            let callResize = updateParams.shouldResize?(event, nextValues)

            if callResize == false {
                return
            }

            updateParams.onResize?(event, nextValues)
            params.onChange(change, childChanges)
        }

        behavior.listeners.on("end") { event in
            updateParams.onResizeEnd?(event, prevValues)
            params.onEnd?(prevValues)
        }
    }

    public func destroy() {
        behavior.listeners.on("start drag end", nil)
    }
}
