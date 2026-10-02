import Foundation

public typealias OnDrag = (
    _ event: FlowPointerEvent,
    _ dragItems: OrderedMap<String, NodeDragItem>,
    _ node: Node,
    _ nodes: [Node]
) -> Void

/// What a node drag callback gets: the event, the node that is dragged (or the first of the nodes
/// of a selection that is dragged) and all the nodes that move.
public typealias OnNodeDrag = (_ event: FlowPointerEvent, _ node: Node, _ nodes: [Node]) -> Void

/// Pans the viewport by the delta. `completion` is told whether it moved.
public typealias PanBy = (_ delta: XYPosition, _ completion: @escaping (Bool) -> Void) -> Void

/// What the drag controller reads of the state of the flow, every time it needs it.
public struct XYDragStoreItems {
    public var nodes: [Node]
    public var nodeLookup: NodeLookup
    public var edges: [Edge]
    public var nodeExtent: CoordinateExtent
    public var snapGrid: SnapGrid
    public var snapToGrid: Bool
    public var nodeOrigin: NodeOrigin
    public var multiSelectionActive: Bool
    public var domNode: FlowDomNode?
    public var transform: Transform
    public var autoPanOnNodeDrag: Bool
    public var nodesDraggable: Bool
    public var selectNodesOnDrag: Bool
    public var nodeDragThreshold: Double
    public var panBy: PanBy
    public var unselectNodesAndEdges: (_ nodes: [Node]?, _ edges: [Edge]?) -> Void
    public var onError: OnError?
    public var onNodeDragStart: OnNodeDrag?
    public var onNodeDrag: OnNodeDrag?
    public var onNodeDragStop: OnNodeDrag?
    public var onSelectionDragStart: OnSelectionDrag?
    public var onSelectionDrag: OnSelectionDrag?
    public var onSelectionDragStop: OnSelectionDrag?
    public var updateNodePositions: UpdateNodePositions
    public var autoPanSpeed: Double?

    public init(
        nodes: [Node],
        nodeLookup: NodeLookup,
        edges: [Edge],
        nodeExtent: CoordinateExtent,
        snapGrid: SnapGrid,
        snapToGrid: Bool,
        nodeOrigin: NodeOrigin,
        multiSelectionActive: Bool,
        domNode: FlowDomNode?,
        transform: Transform,
        autoPanOnNodeDrag: Bool,
        nodesDraggable: Bool,
        selectNodesOnDrag: Bool,
        nodeDragThreshold: Double,
        panBy: @escaping PanBy,
        unselectNodesAndEdges: @escaping (_ nodes: [Node]?, _ edges: [Edge]?) -> Void,
        onError: OnError? = nil,
        onNodeDragStart: OnNodeDrag? = nil,
        onNodeDrag: OnNodeDrag? = nil,
        onNodeDragStop: OnNodeDrag? = nil,
        onSelectionDragStart: OnSelectionDrag? = nil,
        onSelectionDrag: OnSelectionDrag? = nil,
        onSelectionDragStop: OnSelectionDrag? = nil,
        updateNodePositions: @escaping UpdateNodePositions,
        autoPanSpeed: Double? = nil
    ) {
        self.nodes = nodes
        self.nodeLookup = nodeLookup
        self.edges = edges
        self.nodeExtent = nodeExtent
        self.snapGrid = snapGrid
        self.snapToGrid = snapToGrid
        self.nodeOrigin = nodeOrigin
        self.multiSelectionActive = multiSelectionActive
        self.domNode = domNode
        self.transform = transform
        self.autoPanOnNodeDrag = autoPanOnNodeDrag
        self.nodesDraggable = nodesDraggable
        self.selectNodesOnDrag = selectNodesOnDrag
        self.nodeDragThreshold = nodeDragThreshold
        self.panBy = panBy
        self.unselectNodesAndEdges = unselectNodesAndEdges
        self.onError = onError
        self.onNodeDragStart = onNodeDragStart
        self.onNodeDrag = onNodeDrag
        self.onNodeDragStop = onNodeDragStop
        self.onSelectionDragStart = onSelectionDragStart
        self.onSelectionDrag = onSelectionDrag
        self.onSelectionDragStop = onSelectionDragStop
        self.updateNodePositions = updateNodePositions
        self.autoPanSpeed = autoPanSpeed
    }
}

public struct XYDragParams {
    public var getStoreItems: () -> XYDragStoreItems
    public var onDragStart: OnDrag?
    public var onDrag: OnDrag?
    public var onDragStop: OnDrag?
    public var onNodeMouseDown: ((String) -> Void)?
    public var autoPanSpeed: Double?

    public init(
        getStoreItems: @escaping () -> XYDragStoreItems,
        onDragStart: OnDrag? = nil,
        onDrag: OnDrag? = nil,
        onDragStop: OnDrag? = nil,
        onNodeMouseDown: ((String) -> Void)? = nil,
        autoPanSpeed: Double? = nil
    ) {
        self.getStoreItems = getStoreItems
        self.onDragStart = onDragStart
        self.onDrag = onDrag
        self.onDragStop = onDragStop
        self.onNodeMouseDown = onNodeMouseDown
        self.autoPanSpeed = autoPanSpeed
    }
}

public struct DragUpdateParams {
    public var noDragClassName: String?
    public var handleSelector: String?
    public var isSelectable: Bool?
    public var nodeId: String?
    public var domNode: FlowElement
    public var nodeClickDistance: Double?

    public init(
        noDragClassName: String? = nil,
        handleSelector: String? = nil,
        isSelectable: Bool? = nil,
        nodeId: String? = nil,
        domNode: FlowElement,
        nodeClickDistance: Double? = nil
    ) {
        self.noDragClassName = noDragClassName
        self.handleSelector = handleSelector
        self.isSelectable = isSelectable
        self.nodeId = nodeId
        self.domNode = domNode
        self.nodeClickDistance = nodeClickDistance
    }
}

/// The controller that drags nodes, or a selection of them. The host of the node feeds the pointer
/// to `behavior`.
public final class XYDrag {
    /// The drag behavior the pointer of the dragged view goes to.
    public let behavior = D3DragBehavior()

    private let params: XYDragParams
    private var lastPos: (x: Double?, y: Double?) = (nil, nil)
    private var autoPanId = 0
    private var dragItems = OrderedMap<String, NodeDragItem>()
    private var autoPanStarted = false
    private var mousePosition = XYPosition(x: 0, y: 0)
    private var containerBounds: Rect?
    private var dragStarted = false
    /// prevents unintentional dragging on multitouch
    private var abortDrag = false
    private var attached = false

    public init(_ params: XYDragParams) {
        self.params = params
    }

    // MARK: Public functions

    public func update(_ updateParams: DragUpdateParams) {
        let nodeId = updateParams.nodeId
        let isSelectable = updateParams.isSelectable
        let domNode = updateParams.domNode
        let nodeClickDistance = updateParams.nodeClickDistance ?? 0

        attached = true

        func updateNodes(_ position: XYPosition, _ dragEvent: FlowPointerEvent?) {
            let items = params.getStoreItems()
            let nodeLookup = items.nodeLookup
            let nodeExtent = items.nodeExtent

            lastPos = (position.x, position.y)

            var hasChange = false
            var nodesBox = Box(x: 0, y: 0, x2: 0, y2: 0)

            if dragItems.count > 1 {
                let rect = getInternalNodesBounds(dragItems)
                nodesBox = rectToBox(rect)
            }

            for (id, dragItem) in dragItems {
                if !nodeLookup.has(id) {
                    // if the node is not in the nodeLookup anymore, it was probably deleted while dragging
                    // and we don't need to update it anymore
                    continue
                }

                var nextPosition = XYPosition(x: position.x - dragItem.distance.x, y: position.y - dragItem.distance.y)
                if items.snapToGrid {
                    nextPosition = snapPosition(nextPosition, snapGrid: items.snapGrid)
                }

                // if there is selection with multiple nodes and a node extent is set, we need to adjust the
                // node extent for each node based on its position so that the node stays at it's position
                // relative to the selection.
                var adjustedNodeExtent = nodeExtent

                if dragItems.count > 1 && dragItem.extent == nil {
                    let positionAbsolute = dragItem.internals.positionAbsolute
                    let x1 = positionAbsolute.x - nodesBox.x + nodeExtent.minX
                    let x2 = positionAbsolute.x + dragItem.measured.width - nodesBox.x2 + nodeExtent.maxX

                    let y1 = positionAbsolute.y - nodesBox.y + nodeExtent.minY
                    let y2 = positionAbsolute.y + dragItem.measured.height - nodesBox.y2 + nodeExtent.maxY

                    adjustedNodeExtent = CoordinateExtent(x1, y1, x2, y2)
                }

                let result = calculateNodePosition(
                    nodeId: id,
                    nextPosition: nextPosition,
                    nodeLookup: nodeLookup,
                    nodeOrigin: items.nodeOrigin,
                    nodeExtent: adjustedNodeExtent,
                    onError: items.onError)

                // we want to make sure that we only fire a change event when there is a change
                hasChange = hasChange || dragItem.position.x != result.position.x || dragItem.position.y != result.position.y

                dragItem.position = result.position
                dragItem.internals.positionAbsolute = result.positionAbsolute
            }

            if !hasChange {
                return
            }

            items.updateNodePositions(dragItems, true)

            if let dragEvent, params.onDrag != nil || items.onNodeDrag != nil || (nodeId == nil && items.onSelectionDrag != nil) {
                let (currentNode, currentNodes) = getEventHandlerParams(
                    nodeId: nodeId, dragItems: dragItems, nodeLookup: nodeLookup)

                if let currentNode {
                    params.onDrag?(dragEvent, dragItems, currentNode, currentNodes)
                    items.onNodeDrag?(dragEvent, currentNode, currentNodes)
                }

                if nodeId == nil {
                    items.onSelectionDrag?(dragEvent, currentNodes)
                }
            }
        }

        func autoPan() {
            guard let containerBounds else {
                return
            }

            let items = params.getStoreItems()

            if !items.autoPanOnNodeDrag {
                autoPanStarted = false
                cancelAnimationFrame(autoPanId)
                return
            }

            let movement = calcAutoPan(
                mousePosition,
                bounds: Dimensions(width: containerBounds.width, height: containerBounds.height),
                speed: items.autoPanSpeed ?? params.autoPanSpeed ?? 15)
            let xMovement = movement[0]
            let yMovement = movement[1]

            if xMovement != 0 || yMovement != 0 {
                lastPos.x = (lastPos.x ?? 0) - xMovement / items.transform.scale
                lastPos.y = (lastPos.y ?? 0) - yMovement / items.transform.scale

                items.panBy(XYPosition(x: xMovement, y: yMovement)) { [self] moved in
                    if moved {
                        updateNodes(XYPosition(x: lastPos.x ?? 0, y: lastPos.y ?? 0), nil)
                    }

                    autoPanId = requestAnimationFrame { autoPan() }
                }
            } else {
                autoPanId = requestAnimationFrame { autoPan() }
            }
        }

        func startDrag(_ event: D3DragEvent) {
            let items = params.getStoreItems()
            let nodeLookup = items.nodeLookup

            dragStarted = true

            if (!items.selectNodesOnDrag || isSelectable != true) && !items.multiSelectionActive, let nodeId {
                if nodeLookup.get(nodeId)?.selected != true {
                    // we need to reset selected nodes when selectNodesOnDrag=false
                    items.unselectNodesAndEdges(nil, nil)
                }
            }

            if isSelectable == true && items.selectNodesOnDrag, let nodeId {
                params.onNodeMouseDown?(nodeId)
            }

            let pointerPos = getPointerPosition(
                event.sourceEvent,
                GetPointerPositionParams(
                    transform: items.transform, snapGrid: items.snapGrid, snapToGrid: items.snapToGrid,
                    containerBounds: containerBounds))
            lastPos = (pointerPos.x, pointerPos.y)
            dragItems = getDragItems(
                nodeLookup,
                nodesDraggable: items.nodesDraggable,
                mousePos: XYPosition(x: pointerPos.x, y: pointerPos.y),
                nodeId: nodeId)

            if dragItems.count > 0
                && (params.onDragStart != nil || items.onNodeDragStart != nil || (nodeId == nil && items.onSelectionDragStart != nil)) {
                let (currentNode, currentNodes) = getEventHandlerParams(
                    nodeId: nodeId, dragItems: dragItems, nodeLookup: nodeLookup)

                if let currentNode {
                    params.onDragStart?(event.sourceEvent, dragItems, currentNode, currentNodes)
                    items.onNodeDragStart?(event.sourceEvent, currentNode, currentNodes)
                }

                if nodeId == nil {
                    items.onSelectionDragStart?(event.sourceEvent, currentNodes)
                }
            }
        }

        behavior.setClickDistance(nodeClickDistance)

        behavior.listeners.on("start") { [self] event in
            let items = params.getStoreItems()
            containerBounds = items.domNode?.boundingClientRect

            abortDrag = false

            if items.nodeDragThreshold == 0 {
                startDrag(event)
            }

            let pointerPos = getPointerPosition(
                event.sourceEvent,
                GetPointerPositionParams(
                    transform: items.transform, snapGrid: items.snapGrid, snapToGrid: items.snapToGrid,
                    containerBounds: containerBounds))
            lastPos = (pointerPos.x, pointerPos.y)
            mousePosition = getEventPosition(event.sourceEvent, containerBounds)
        }

        behavior.listeners.on("drag") { [self] event in
            let items = params.getStoreItems()
            let pointerPos = getPointerPosition(
                event.sourceEvent,
                GetPointerPositionParams(
                    transform: items.transform, snapGrid: items.snapGrid, snapToGrid: items.snapToGrid,
                    containerBounds: containerBounds))

            if (event.sourceEvent.kind == .touch && event.sourceEvent.touchCount > 1)
                // if user deletes a node while dragging, we need to abort the drag to prevent errors
                || (nodeId != nil && !items.nodeLookup.has(nodeId!)) {
                abortDrag = true
            }

            if abortDrag {
                return
            }

            if !autoPanStarted && items.autoPanOnNodeDrag && dragStarted {
                autoPanStarted = true
                autoPan()
            }

            if !dragStarted {
                let x = pointerPos.xSnapped - (lastPos.x ?? 0)
                let y = pointerPos.ySnapped - (lastPos.y ?? 0)
                let distance = (x * x + y * y).squareRoot()

                if distance > items.nodeDragThreshold {
                    startDrag(event)
                }
            }

            // skip events without movement
            if (lastPos.x != pointerPos.xSnapped || lastPos.y != pointerPos.ySnapped) && dragStarted {
                mousePosition = getEventPosition(event.sourceEvent, containerBounds)

                updateNodes(XYPosition(x: pointerPos.x, y: pointerPos.y), event.sourceEvent)
            }
        }

        behavior.listeners.on("end") { [self] event in
            if !dragStarted || abortDrag {
                return
            }

            autoPanStarted = false
            dragStarted = false
            cancelAnimationFrame(autoPanId)

            if dragItems.count > 0 {
                let items = params.getStoreItems()
                let nodeLookup = items.nodeLookup

                items.updateNodePositions(dragItems, false)

                if params.onDragStop != nil || items.onNodeDragStop != nil || (nodeId == nil && items.onSelectionDragStop != nil) {
                    let (currentNode, currentNodes) = getEventHandlerParams(
                        nodeId: nodeId, dragItems: dragItems, nodeLookup: nodeLookup, dragging: false)

                    if let currentNode {
                        params.onDragStop?(event.sourceEvent, dragItems, currentNode, currentNodes)
                        items.onNodeDragStop?(event.sourceEvent, currentNode, currentNodes)
                    }

                    if nodeId == nil {
                        items.onSelectionDragStop?(event.sourceEvent, currentNodes)
                    }
                }
            }
        }

        behavior.filter = { event in
            let target = event.target
            let isDraggable = event.button == 0
                && (updateParams.noDragClassName == nil
                    || !hasSelector(target, ".\(updateParams.noDragClassName!)", domNode))
                && (updateParams.handleSelector == nil
                    || hasSelector(target, updateParams.handleSelector!, domNode))

            return isDraggable
        }
    }

    public func destroy() {
        attached = false
        behavior.listeners.on("start drag end", nil)
    }
}
