import Foundation

public struct UpdateNodesOptions {
    public var nodeOrigin: NodeOrigin?
    public var nodeExtent: CoordinateExtent?
    public var elevateNodesOnSelect: Bool?
    public var defaults: NodeDefaults?
    public var checkEquality: Bool?

    public init(
        nodeOrigin: NodeOrigin? = nil,
        nodeExtent: CoordinateExtent? = nil,
        elevateNodesOnSelect: Bool? = nil,
        defaults: NodeDefaults? = nil,
        checkEquality: Bool? = nil
    ) {
        self.nodeOrigin = nodeOrigin
        self.nodeExtent = nodeExtent
        self.elevateNodesOnSelect = elevateNodesOnSelect
        self.defaults = defaults
        self.checkEquality = checkEquality
    }
}

/// The properties every node gets unless it sets them itself: `defaultNodeOptions`.
public struct NodeDefaults {
    public var type: String?
    public var sourcePosition: Position?
    public var targetPosition: Position?
    public var hidden: Bool?
    public var selected: Bool?
    public var dragging: Bool?
    public var draggable: Bool?
    public var selectable: Bool?
    public var connectable: Bool?
    public var deletable: Bool?
    public var dragHandle: String?
    public var width: Double?
    public var height: Double?
    public var initialWidth: Double?
    public var initialHeight: Double?
    public var parentId: String?
    public var zIndex: Double?
    public var extent: NodeExtent?
    public var expandParent: Bool?
    public var ariaLabel: String?
    public var origin: NodeOrigin?
    public var className: String?
    public var style: String?

    public init(
        type: String? = nil,
        sourcePosition: Position? = nil,
        targetPosition: Position? = nil,
        hidden: Bool? = nil,
        selected: Bool? = nil,
        dragging: Bool? = nil,
        draggable: Bool? = nil,
        selectable: Bool? = nil,
        connectable: Bool? = nil,
        deletable: Bool? = nil,
        dragHandle: String? = nil,
        width: Double? = nil,
        height: Double? = nil,
        initialWidth: Double? = nil,
        initialHeight: Double? = nil,
        parentId: String? = nil,
        zIndex: Double? = nil,
        extent: NodeExtent? = nil,
        expandParent: Bool? = nil,
        ariaLabel: String? = nil,
        origin: NodeOrigin? = nil,
        className: String? = nil,
        style: String? = nil
    ) {
        self.type = type
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
        self.hidden = hidden
        self.selected = selected
        self.dragging = dragging
        self.draggable = draggable
        self.selectable = selectable
        self.connectable = connectable
        self.deletable = deletable
        self.dragHandle = dragHandle
        self.width = width
        self.height = height
        self.initialWidth = initialWidth
        self.initialHeight = initialHeight
        self.parentId = parentId
        self.zIndex = zIndex
        self.extent = extent
        self.expandParent = expandParent
        self.ariaLabel = ariaLabel
        self.origin = origin
        self.className = className
        self.style = style
    }

    /// `{ ...defaults, ...userNode }`: what the node does not set is taken from the defaults.
    fileprivate func apply(to node: InternalNode) {
        if node.type == nil { node.type = type }
        if node.sourcePosition == nil { node.sourcePosition = sourcePosition }
        if node.targetPosition == nil { node.targetPosition = targetPosition }
        if node.hidden == nil { node.hidden = hidden }
        if node.selected == nil { node.selected = selected }
        if node.dragging == nil { node.dragging = dragging }
        if node.draggable == nil { node.draggable = draggable }
        if node.selectable == nil { node.selectable = selectable }
        if node.connectable == nil { node.connectable = connectable }
        if node.deletable == nil { node.deletable = deletable }
        if node.dragHandle == nil { node.dragHandle = dragHandle }
        if node.width == nil { node.width = width }
        if node.height == nil { node.height = height }
        if node.initialWidth == nil { node.initialWidth = initialWidth }
        if node.initialHeight == nil { node.initialHeight = initialHeight }
        if node.parentId == nil { node.parentId = parentId }
        if node.zIndex == nil { node.zIndex = zIndex }
        if node.extent == nil { node.extent = extent }
        if node.expandParent == nil { node.expandParent = expandParent }
        if node.ariaLabel == nil { node.ariaLabel = ariaLabel }
        if node.origin == nil { node.origin = origin }
        if node.className == nil { node.className = className }
        if node.style == nil { node.style = style }
    }
}

private struct ResolvedOptions {
    var nodeOrigin: NodeOrigin
    var nodeExtent: CoordinateExtent
    var elevateNodesOnSelect: Bool
    var defaults: NodeDefaults?
    var checkEquality: Bool

    /// `mergeObjects(defaultOptions, options)`: what the options do not set stays as it is by default.
    init(_ options: UpdateNodesOptions?, checkEquality defaultCheckEquality: Bool = false) {
        nodeOrigin = options?.nodeOrigin ?? .zero
        nodeExtent = options?.nodeExtent ?? infiniteExtent
        elevateNodesOnSelect = options?.elevateNodesOnSelect ?? true
        defaults = options?.defaults
        checkEquality = options?.checkEquality ?? defaultCheckEquality
    }
}

public func updateAbsolutePositions(
    _ nodeLookup: NodeLookup,
    _ parentLookup: ParentLookup,
    options: UpdateNodesOptions? = nil
) {
    let resolved = ResolvedOptions(options)

    for (_, node) in nodeLookup {
        if node.parentId != nil {
            updateChildNode(node, nodeLookup, parentLookup, resolved)
        } else {
            let positionWithOrigin = getNodePositionWithOrigin(node, nodeOrigin: resolved.nodeOrigin)
            let extent = coordinateExtent(of: node.extent) ?? resolved.nodeExtent
            let clampedPosition = clampPosition(
                positionWithOrigin, extent: extent, dimensions: getNodeDimensions(node))
            node.internals.positionAbsolute = clampedPosition
        }
    }
}

/// Puts the nodes of the user into the lookup the flow works with. Nodes that were already there
/// and did not change keep what the flow found out of them; the others are made anew.
/// - Returns: Whether all nodes have been measured.
@discardableResult
public func adoptUserNodes(
    _ nodes: [Node],
    _ nodeLookup: NodeLookup,
    _ parentLookup: ParentLookup,
    options: UpdateNodesOptions? = nil
) -> Bool {
    let resolved = ResolvedOptions(options, checkEquality: true)

    var nodesInitialized = !nodes.isEmpty
    let tmpLookup = OrderedMap(nodeLookup)
    let selectedNodeZ: Double = resolved.elevateNodesOnSelect ? 1000 : 0

    nodeLookup.clear()
    parentLookup.clear()

    for userNode in nodes {
        var internalNode = tmpLookup.get(userNode.id)

        if resolved.checkEquality, let existing = internalNode, userNode === existing.internals.userNode {
            nodeLookup.set(userNode.id, existing)
        } else {
            let positionWithOrigin = getNodePositionWithOrigin(userNode, nodeOrigin: resolved.nodeOrigin)
            let extent = coordinateExtent(of: userNode.extent) ?? resolved.nodeExtent
            let clampedPosition = clampPosition(
                positionWithOrigin, extent: extent, dimensions: getNodeDimensions(userNode))

            let created = InternalNode(
                userNode: userNode,
                measured: Measured(width: userNode.measured?.width, height: userNode.measured?.height),
                internals: InternalNode.Internals(
                    positionAbsolute: clampedPosition,
                    // if user re-initializes the node or removes `measured` for whatever reason, we reset
                    // the handleBounds so that the node gets re-measured
                    z: calculateZ(userNode, selectedNodeZ),
                    userNode: userNode,
                    handleBounds: userNode.measured == nil ? nil : internalNode?.internals.handleBounds))
            resolved.defaults?.apply(to: created)

            nodeLookup.set(userNode.id, created)
            internalNode = created
        }

        if let node = internalNode {
            if (node.measured.width == nil || node.measured.height == nil) && node.hidden != true {
                nodesInitialized = false
            }

            if userNode.parentId != nil {
                updateChildNode(node, nodeLookup, parentLookup, ResolvedOptions(options))
            }
        }
    }

    return nodesInitialized
}

private func updateParentLookup(_ node: InternalNode, _ parentLookup: ParentLookup) {
    guard let parentId = node.parentId else {
        return
    }

    if let childNodes = parentLookup.get(parentId) {
        childNodes.set(node.id, node)
    } else {
        let childNodes = OrderedMap<String, InternalNode>()
        childNodes.set(node.id, node)
        parentLookup.set(parentId, childNodes)
    }
}

/// Updates positionAbsolute and zIndex of a child node and the parentLookup.
private func updateChildNode(
    _ node: InternalNode,
    _ nodeLookup: NodeLookup,
    _ parentLookup: ParentLookup,
    _ options: ResolvedOptions
) {
    let parentId = node.parentId!
    guard let parentNode = nodeLookup.get(parentId) else {
        print("Parent node \(parentId) not found. Please make sure that parent nodes are in front of their child nodes in the nodes array.")
        return
    }

    updateParentLookup(node, parentLookup)

    let selectedNodeZ: Double = options.elevateNodesOnSelect ? 1000 : 0
    let (x, y, z) = calculateChildXYZ(node, parentNode, options.nodeOrigin, options.nodeExtent, selectedNodeZ)
    let positionAbsolute = node.internals.positionAbsolute
    let positionChanged = x != positionAbsolute.x || y != positionAbsolute.y

    if positionChanged || z != node.internals.z {
        // we create a new object to mark the node as updated
        let updated = node.copy()
        updated.internals.positionAbsolute = positionChanged ? XYPosition(x: x, y: y) : positionAbsolute
        updated.internals.z = z
        nodeLookup.set(node.id, updated)
    }
}

private func calculateZ(_ node: Node, _ selectedNodeZ: Double) -> Double {
    (isNumeric(node.zIndex) ? node.zIndex! : 0) + (node.selected == true ? selectedNodeZ : 0)
}

private func calculateZ(_ node: InternalNode, _ selectedNodeZ: Double) -> Double {
    (isNumeric(node.zIndex) ? node.zIndex! : 0) + (node.selected == true ? selectedNodeZ : 0)
}

private func calculateChildXYZ(
    _ childNode: InternalNode,
    _ parentNode: InternalNode,
    _ nodeOrigin: NodeOrigin,
    _ nodeExtent: CoordinateExtent,
    _ selectedNodeZ: Double
) -> (Double, Double, Double) {
    let parentPosition = parentNode.internals.positionAbsolute
    let childDimensions = getNodeDimensions(childNode)
    let positionWithOrigin = getNodePositionWithOrigin(childNode, nodeOrigin: nodeOrigin)
    let clampedPosition = coordinateExtent(of: childNode.extent).map {
        clampPosition(positionWithOrigin, extent: $0, dimensions: childDimensions)
    } ?? positionWithOrigin

    var absolutePosition = clampPosition(
        XYPosition(x: parentPosition.x + clampedPosition.x, y: parentPosition.y + clampedPosition.y),
        extent: nodeExtent,
        dimensions: childDimensions)

    if case .parent? = childNode.extent {
        absolutePosition = clampPositionToParent(absolutePosition, childDimensions: childDimensions, parent: parentNode)
    }

    let childZ = calculateZ(childNode, selectedNodeZ)
    let parentZ = parentNode.internals.z

    return (absolutePosition.x, absolutePosition.y, parentZ > childZ ? parentZ : childZ)
}

public struct ParentExpandChild {
    public var id: String
    public var parentId: String
    public var rect: Rect

    public init(id: String, parentId: String, rect: Rect) {
        self.id = id
        self.parentId = parentId
        self.rect = rect
    }
}

public func handleExpandParent(
    _ children: [ParentExpandChild],
    _ nodeLookup: NodeLookup,
    _ parentLookup: ParentLookup,
    nodeOrigin: NodeOrigin = .zero
) -> [NodeInternalsChange] {
    var changes: [NodeInternalsChange] = []
    let parentExpansions = OrderedMap<String, (expandedRect: Rect, parent: InternalNode)>()

    // determine the expanded rectangle the child nodes would take for each parent
    for child in children {
        guard let parent = nodeLookup.get(child.parentId) else {
            continue
        }

        let parentRect = parentExpansions.get(child.parentId)?.expandedRect ?? nodeToRect(parent)
        let expandedRect = getBoundsOfRects(parentRect, child.rect)

        parentExpansions.set(child.parentId, (expandedRect, parent))
    }

    if parentExpansions.count > 0 {
        parentExpansions.forEachEntry { expansion, parentId in
            let expandedRect = expansion.expandedRect
            let parent = expansion.parent

            // determine the position & dimensions of the parent
            let positionAbsolute = parent.internals.positionAbsolute
            let dimensions = getNodeDimensions(parent)
            let origin = parent.origin ?? nodeOrigin

            // determine how much the parent expands in width and position
            let xChange = expandedRect.x < positionAbsolute.x ? jsRound(abs(positionAbsolute.x - expandedRect.x)) : 0
            let yChange = expandedRect.y < positionAbsolute.y ? jsRound(abs(positionAbsolute.y - expandedRect.y)) : 0

            let newWidth = jsMax(dimensions.width, jsRound(expandedRect.width))
            let newHeight = jsMax(dimensions.height, jsRound(expandedRect.height))

            let widthChange = (newWidth - dimensions.width) * origin.x
            let heightChange = (newHeight - dimensions.height) * origin.y

            // We need to correct the position of the parent node if the origin is not [0,0]
            if xChange > 0 || yChange > 0 || widthChange != 0 || heightChange != 0 {
                changes.append(.position(NodePositionChange(
                    id: parentId,
                    position: XYPosition(
                        x: parent.position.x - xChange + widthChange,
                        y: parent.position.y - yChange + heightChange))))

                // We move all child nodes in the opposite direction
                // so the x,y changes of the parent do not move the children
                parentLookup.get(parentId)?.forEachEntry { childNode, _ in
                    if !children.contains(where: { $0.id == childNode.id }) {
                        changes.append(.position(NodePositionChange(
                            id: childNode.id,
                            position: XYPosition(
                                x: childNode.position.x + xChange,
                                y: childNode.position.y + yChange))))
                    }
                }
            }

            // We need to correct the dimensions of the parent node if the origin is not [0,0]
            if dimensions.width < expandedRect.width || dimensions.height < expandedRect.height
                || xChange != 0 || yChange != 0 {
                changes.append(.dimensions(NodeDimensionChange(
                    id: parentId,
                    dimensions: Dimensions(
                        width: newWidth + (xChange != 0 ? origin.x * xChange - widthChange : 0),
                        height: newHeight + (yChange != 0 ? origin.y * yChange - heightChange : 0)),
                    setAttributes: .enabled(true))))
            }
        }
    }

    return changes
}

/// Measures the nodes that were asked for and puts what it finds into the lookup.
/// - Returns: The changes of the nodes, and whether anything of the internals was updated.
public func updateNodeInternals(
    _ updates: OrderedMap<String, InternalNodeUpdate>,
    _ nodeLookup: NodeLookup,
    _ parentLookup: ParentLookup,
    domNode: FlowDomNode?,
    nodeOrigin: NodeOrigin? = nil,
    nodeExtent: CoordinateExtent? = nil
) -> (changes: [NodeInternalsChange], updatedInternals: Bool) {
    var updatedInternals = false

    guard let zoom = domNode?.viewportScale else {
        return ([], updatedInternals)
    }

    var changes: [NodeInternalsChange] = []
    // in this array we collect nodes, that might trigger changes (like expanding parent)
    var parentExpandChildren: [ParentExpandChild] = []

    for (_, update) in updates {
        guard let node = nodeLookup.get(update.id) else {
            continue
        }

        if node.hidden == true {
            let hiddenNode = node.copy()
            hiddenNode.internals.handleBounds = nil
            nodeLookup.set(node.id, hiddenNode)
            updatedInternals = true
            continue
        }

        let dimensions = getDimensions(update.nodeElement)
        let dimensionChanged = node.measured.width != dimensions.width || node.measured.height != dimensions.height
        let doUpdate = dimensions.width != 0
            && dimensions.height != 0
            && (dimensionChanged || node.internals.handleBounds == nil || update.force == true)

        if doUpdate {
            let nodeBounds = update.nodeElement.boundingClientRect
            let extent = coordinateExtent(of: node.extent) ?? nodeExtent
            var positionAbsolute = node.internals.positionAbsolute

            if let parentId = node.parentId, case .parent? = node.extent, let parent = nodeLookup.get(parentId) {
                positionAbsolute = clampPositionToParent(positionAbsolute, childDimensions: dimensions, parent: parent)
            } else if let extent {
                positionAbsolute = clampPosition(positionAbsolute, extent: extent, dimensions: dimensions)
            }

            let newNode = node.copy()
            newNode.measured = Measured(width: dimensions.width, height: dimensions.height)
            newNode.internals.positionAbsolute = positionAbsolute
            newNode.internals.handleBounds = NodeHandleBounds(
                source: getHandleBounds(.source, nodeElement: update.nodeElement, nodeBounds: nodeBounds, zoom: zoom, nodeId: node.id),
                target: getHandleBounds(.target, nodeElement: update.nodeElement, nodeBounds: nodeBounds, zoom: zoom, nodeId: node.id))

            nodeLookup.set(node.id, newNode)

            if node.parentId != nil {
                updateChildNode(newNode, nodeLookup, parentLookup, ResolvedOptions(UpdateNodesOptions(nodeOrigin: nodeOrigin)))
            }

            updatedInternals = true

            if dimensionChanged {
                changes.append(.dimensions(NodeDimensionChange(id: node.id, dimensions: dimensions)))

                if node.expandParent == true, let parentId = node.parentId {
                    parentExpandChildren.append(ParentExpandChild(
                        id: node.id,
                        parentId: parentId,
                        rect: nodeToRect(newNode)))
                }
            }
        }
    }

    if !parentExpandChildren.isEmpty {
        let parentExpandChanges = handleExpandParent(
            parentExpandChildren, nodeLookup, parentLookup, nodeOrigin: nodeOrigin ?? .zero)
        changes.append(contentsOf: parentExpandChanges)
    }

    return (changes, updatedInternals)
}

/// Pans the viewport by `delta`. `completion` is told whether the transform changed.
public func panBy(
    delta: XYPosition,
    panZoom: PanZoomInstance?,
    transform: Transform,
    translateExtent: CoordinateExtent,
    width: Double,
    height: Double,
    completion: ((Bool) -> Void)? = nil
) {
    guard let panZoom, delta.x != 0 || delta.y != 0 else {
        completion?(false)
        return
    }

    panZoom.setViewportConstrained(
        Viewport(x: transform.x + delta.x, y: transform.y + delta.y, zoom: transform.scale),
        extent: CoordinateExtent(0, 0, width, height),
        translateExtent: translateExtent
    ) { nextViewport in
        let transformChanged = nextViewport.map {
            $0.x != transform.x || $0.y != transform.y || $0.k != transform.scale
        } ?? false

        completion?(transformChanged)
    }
}

/// this function adds the connection to the connectionLookup at the following keys:
/// nodeId-type-handleId, nodeId-type and nodeId
func addConnectionToLookup(
    _ type: HandleType,
    _ connection: HandleConnection,
    _ connectionKey: String,
    _ connectionLookup: ConnectionLookup,
    _ nodeId: String,
    _ handleId: String?
) {
    // We add the connection to the connectionLookup at the following keys
    // 1. nodeId, 2. nodeId-type, 3. nodeId-type-handleId
    // If the key already exists, we add the connection to the existing map
    var key = nodeId
    let nodeMap = connectionLookup.get(key) ?? OrderedMap()
    connectionLookup.set(key, nodeMap.set(connectionKey, connection))

    key = "\(nodeId)-\(type.rawValue)"
    let typeMap = connectionLookup.get(key) ?? OrderedMap()
    connectionLookup.set(key, typeMap.set(connectionKey, connection))

    if let handleId, !handleId.isEmpty {
        key = "\(nodeId)-\(type.rawValue)-\(handleId)"
        let handleMap = connectionLookup.get(key) ?? OrderedMap()
        connectionLookup.set(key, handleMap.set(connectionKey, connection))
    }
}

public func updateConnectionLookup(_ connectionLookup: ConnectionLookup, _ edgeLookup: EdgeLookup, _ edges: [Edge]) {
    connectionLookup.clear()
    edgeLookup.clear()

    for edge in edges {
        let sourceNode = edge.source
        let targetNode = edge.target
        let sourceHandle = edge.sourceHandle
        let targetHandle = edge.targetHandle

        let connection = HandleConnection(
            source: sourceNode, target: targetNode, sourceHandle: sourceHandle, targetHandle: targetHandle,
            edgeId: edge.id)
        let sourceHandleText = sourceHandle ?? "null"
        let targetHandleText = targetHandle ?? "null"
        let sourceKey = "\(sourceNode)-\(sourceHandleText)--\(targetNode)-\(targetHandleText)"
        let targetKey = "\(targetNode)-\(targetHandleText)--\(sourceNode)-\(sourceHandleText)"

        addConnectionToLookup(.source, connection, targetKey, connectionLookup, sourceNode, sourceHandle)
        addConnectionToLookup(.target, connection, sourceKey, connectionLookup, targetNode, targetHandle)

        edgeLookup.set(edge.id, edge)
    }
}
