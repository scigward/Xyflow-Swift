import Foundation

/// The nodes that are connected to the given node as the _target_ of an edge.
/// - Parameters:
///   - node: The node to get the connected nodes from.
///   - nodes: The array of all nodes.
///   - edges: The array of all edges.
/// - Returns: An array of nodes that are connected over edges where the source is the given node.
public func getOutgoers(_ node: Node, nodes: [Node], edges: [Edge]) -> [Node] {
    getOutgoers(id: node.id, nodes: nodes, edges: edges)
}

public func getOutgoers(id: String, nodes: [Node], edges: [Edge]) -> [Node] {
    if id.isEmpty {
        return []
    }

    var outgoerIds = Set<String>()
    for edge in edges where edge.source == id {
        outgoerIds.insert(edge.target)
    }

    return nodes.filter { outgoerIds.contains($0.id) }
}

/// The nodes that are connected to the given node as the _source_ of an edge.
/// - Returns: An array of nodes that are connected over edges where the target is the given node.
public func getIncomers(_ node: Node, nodes: [Node], edges: [Edge]) -> [Node] {
    getIncomers(id: node.id, nodes: nodes, edges: edges)
}

public func getIncomers(id: String, nodes: [Node], edges: [Edge]) -> [Node] {
    if id.isEmpty {
        return []
    }

    var incomerIds = Set<String>()
    for edge in edges where edge.target == id {
        incomerIds.insert(edge.source)
    }

    return nodes.filter { incomerIds.contains($0.id) }
}

public func getNodePositionWithOrigin(_ node: Node, nodeOrigin: NodeOrigin = .zero) -> XYPosition {
    let dimensions = getNodeDimensions(node)
    let origin = node.origin ?? nodeOrigin
    let offsetX = dimensions.width * origin.x
    let offsetY = dimensions.height * origin.y

    return XYPosition(x: node.position.x - offsetX, y: node.position.y - offsetY)
}

public func getNodePositionWithOrigin(_ node: InternalNode, nodeOrigin: NodeOrigin = .zero) -> XYPosition {
    let dimensions = getNodeDimensions(node)
    let origin = node.origin ?? nodeOrigin
    let offsetX = dimensions.width * origin.x
    let offsetY = dimensions.height * origin.y

    return XYPosition(x: node.position.x - offsetX, y: node.position.y - offsetY)
}

/// What `getNodesBounds` takes for a node: the node, the node of the lookup or its id.
public enum NodeOrId {
    case node(Node)
    case internalNode(InternalNode)
    case id(String)
}

/// Returns the bounding box that contains all the given nodes in an array. This can be useful when
/// combined with `getViewportForBounds` to calculate the correct transform to fit the given nodes
/// in a viewport.
/// - Parameters:
///   - nodes: Nodes to calculate the bounds for.
///   - nodeOrigin: Origin of the nodes: `[0, 0]` for top-left, `[0.5, 0.5]` for center.
///   - nodeLookup: The lookup of the flow, which is needed to get the bounds of sub flows right.
/// - Returns: Bounding box enclosing all nodes.
public func getNodesBounds(
    _ nodes: [NodeOrId],
    nodeOrigin: NodeOrigin = .zero,
    nodeLookup: NodeLookup? = nil
) -> Rect {
    if nodes.isEmpty {
        return Rect(x: 0, y: 0, width: 0, height: 0)
    }

    var box = Box(x: .infinity, y: .infinity, x2: -.infinity, y2: -.infinity)

    for nodeOrId in nodes {
        var nodeBox: Box?

        if let nodeLookup {
            switch nodeOrId {
            case .id(let id):
                if let internalNode = nodeLookup.get(id) { nodeBox = nodeToBox(internalNode) }
            case .node(let node):
                if let internalNode = nodeLookup.get(node.id) { nodeBox = nodeToBox(internalNode) }
            case .internalNode(let internalNode):
                nodeBox = nodeToBox(internalNode)
            }
        } else {
            switch nodeOrId {
            case .id:
                break
            case .node(let node):
                nodeBox = nodeToBox(node, nodeOrigin: nodeOrigin)
            case .internalNode(let internalNode):
                nodeBox = nodeToBox(internalNode)
            }
        }

        box = getBoundsOfBoxes(box, nodeBox ?? Box(x: 0, y: 0, x2: 0, y2: 0))
    }

    return boxToRect(box)
}

public func getNodesBounds(
    _ nodes: [Node],
    nodeOrigin: NodeOrigin = .zero,
    nodeLookup: NodeLookup? = nil
) -> Rect {
    getNodesBounds(nodes.map { NodeOrId.node($0) }, nodeOrigin: nodeOrigin, nodeLookup: nodeLookup)
}

public func getNodesBounds(
    ids: [String],
    nodeOrigin: NodeOrigin = .zero,
    nodeLookup: NodeLookup? = nil
) -> Rect {
    getNodesBounds(ids.map { NodeOrId.id($0) }, nodeOrigin: nodeOrigin, nodeLookup: nodeLookup)
}

/// Determines a bounding box that contains all given nodes in a lookup.
public func getInternalNodesBounds<NodeType: AbsolutelyPositioned>(
    _ nodeLookup: OrderedMap<String, NodeType>,
    filter: ((NodeType) -> Bool)? = nil
) -> Rect {
    if nodeLookup.count == 0 {
        return Rect(x: 0, y: 0, width: 0, height: 0)
    }

    var box = Box(x: .infinity, y: .infinity, x2: -.infinity, y2: -.infinity)

    nodeLookup.forEachEntry { node, _ in
        if filter == nil || filter?(node) == true {
            box = getBoundsOfBoxes(box, nodeToBox(node))
        }
    }

    return boxToRect(box)
}

public func getNodesInside(
    _ nodes: NodeLookup,
    rect: Rect,
    transform: Transform = Transform(0, 0, 1),
    partially: Bool = false,
    // set excludeNonSelectableNodes if you want to pay attention to the nodes "selectable" attribute
    excludeNonSelectableNodes: Bool = false
) -> [InternalNode] {
    let origin = pointToRendererPoint(rect, transform: transform)
    let paneRect = Rect(
        x: origin.x, y: origin.y,
        width: rect.width / transform.scale,
        height: rect.height / transform.scale)

    var visibleNodes: [InternalNode] = []

    for (_, node) in nodes {
        let selectable = node.selectable ?? true
        let hidden = node.hidden ?? false

        if (excludeNonSelectableNodes && !selectable) || hidden {
            continue
        }

        let width = node.measured.width ?? node.width ?? node.initialWidth
        let height = node.measured.height ?? node.height ?? node.initialHeight

        let overlappingArea = getOverlappingArea(paneRect, nodeToRect(node))
        let area = (width ?? 0) * (height ?? 0)

        let partiallyVisible = partially && overlappingArea > 0
        let forceInitialRender = node.internals.handleBounds == nil
        let isVisible = forceInitialRender || partiallyVisible || overlappingArea >= area

        if isVisible || node.dragging == true {
            visibleNodes.append(node)
        }
    }

    return visibleNodes
}

/// Filters an array of edges, keeping only those where either the source or target node is present
/// in the given array of nodes.
/// - Parameters:
///   - nodes: Nodes you want to get the connected edges for.
///   - edges: All edges.
/// - Returns: Array of edges that connect any of the given nodes with each other.
public func getConnectedEdges(_ nodes: [Node], _ edges: [Edge]) -> [Edge] {
    var nodeIds = Set<String>()
    for node in nodes {
        nodeIds.insert(node.id)
    }

    return edges.filter { nodeIds.contains($0.source) || nodeIds.contains($0.target) }
}

func getFitViewNodes(_ nodeLookup: NodeLookup, options: FitViewOptions?) -> NodeLookup {
    let fitViewNodes = NodeLookup()
    let optionNodeIds: Set<String>? = options?.nodes.map { Set($0.map { $0.id }) }

    nodeLookup.forEachEntry { node, _ in
        let isVisible = (node.measured.width ?? 0) != 0
            && (node.measured.height ?? 0) != 0
            && (options?.includeHiddenNodes == true || node.hidden != true)

        if isVisible && (optionNodeIds == nil || optionNodeIds?.contains(node.id) == true) {
            fitViewNodes.set(node.id, node)
        }
    }

    return fitViewNodes
}

/// Moves the viewport so that the nodes fit into it. `completion` is told when that is done.
public func fitViewport(
    _ params: FitViewParams,
    options: FitViewOptions? = nil,
    completion: ((Bool) -> Void)? = nil
) {
    if params.nodes.count == 0 {
        completion?(true)
        return
    }

    let nodesToFit = getFitViewNodes(params.nodes, options: options)

    let bounds = getInternalNodesBounds(nodesToFit)

    let viewport = getViewportForBounds(
        bounds,
        width: params.width,
        height: params.height,
        minZoom: options?.minZoom ?? params.minZoom,
        maxZoom: options?.maxZoom ?? params.maxZoom,
        padding: options?.padding ?? 0.1)

    params.panZoom.setViewport(viewport, options: PanZoomTransformOptions(duration: options?.duration)) { _ in
        completion?(true)
    }
}

/// This function calculates the next position of a node, taking into account the node's extent,
/// parent node, and origin.
/// - Returns: position, positionAbsolute
public func calculateNodePosition(
    nodeId: String,
    nextPosition: XYPosition,
    nodeLookup: NodeLookup,
    nodeOrigin: NodeOrigin = .zero,
    nodeExtent: CoordinateExtent? = nil,
    onError: OnError? = nil
) -> (position: XYPosition, positionAbsolute: XYPosition) {
    let node = nodeLookup.get(nodeId)!
    let parentNode = node.parentId.flatMap { nodeLookup.get($0) }
    let parentPosition = parentNode?.internals.positionAbsolute ?? XYPosition(x: 0, y: 0)

    let origin = node.origin ?? nodeOrigin
    var extent = nodeExtent

    if case .parent? = node.extent, node.expandParent != true {
        if let parentNode {
            let parentWidth = parentNode.measured.width
            let parentHeight = parentNode.measured.height

            if let parentWidth, let parentHeight, parentWidth != 0, parentHeight != 0 {
                extent = CoordinateExtent(
                    parentPosition.x, parentPosition.y,
                    parentPosition.x + parentWidth, parentPosition.y + parentHeight)
            }
        } else {
            onError?("005", ErrorMessages.error005())
        }
    } else if parentNode != nil, case .coordinates(let nodeExtentValue)? = node.extent {
        extent = CoordinateExtent(
            nodeExtentValue.minX + parentPosition.x, nodeExtentValue.minY + parentPosition.y,
            nodeExtentValue.maxX + parentPosition.x, nodeExtentValue.maxY + parentPosition.y)
    }

    let positionAbsolute = extent.map { clampPosition(nextPosition, extent: $0, dimensions: node.measured) }
        ?? nextPosition

    if node.measured.width == nil || node.measured.height == nil {
        onError?("015", ErrorMessages.error015())
    }

    return (
        position: XYPosition(
            x: positionAbsolute.x - parentPosition.x + (node.measured.width ?? 0) * origin.x,
            y: positionAbsolute.y - parentPosition.y + (node.measured.height ?? 0) * origin.y),
        positionAbsolute: positionAbsolute)
}

/// Pass in nodes & edges to delete, get arrays of nodes and edges that actually can be deleted.
/// - Parameters:
///   - nodesToRemove: The nodes to remove
///   - edgesToRemove: The edges to remove
///   - nodes: All nodes
///   - edges: All edges
///   - onBeforeDelete: Callback to check which nodes and edges can be deleted
///   - completion: Called with the nodes that can be deleted and the edges that can be deleted
public func getElementsToRemove(
    nodesToRemove: [String] = [],
    edgesToRemove: [String] = [],
    nodes: [Node],
    edges: [Edge],
    onBeforeDelete: OnBeforeDelete? = nil,
    completion: @escaping (_ nodes: [Node], _ edges: [Edge]) -> Void
) {
    let nodeIds = Set(nodesToRemove)
    var matchingNodes: [Node] = []

    for node in nodes {
        if node.deletable == false {
            continue
        }

        let isIncluded = nodeIds.contains(node.id)
        let parentHit = !isIncluded && node.parentId != nil
            && matchingNodes.contains { $0.id == node.parentId }

        if isIncluded || parentHit {
            matchingNodes.append(node)
        }
    }

    let edgeIds = Set(edgesToRemove)
    let deletableEdges = edges.filter { $0.deletable != false }
    let connectedEdges = getConnectedEdges(matchingNodes, deletableEdges)
    var matchingEdges: [Edge] = connectedEdges

    for edge in deletableEdges {
        let isIncluded = edgeIds.contains(edge.id)

        if isIncluded && !matchingEdges.contains(where: { $0.id == edge.id }) {
            matchingEdges.append(edge)
        }
    }

    guard let onBeforeDelete else {
        completion(matchingNodes, matchingEdges)
        return
    }

    let nodesToDelete = matchingNodes
    let edgesToDelete = matchingEdges

    onBeforeDelete(nodesToDelete, edgesToDelete) { result in
        switch result {
        case .allow:
            completion(nodesToDelete, edgesToDelete)
        case .deny:
            completion([], [])
        case .replace(let nodes, let edges):
            completion(nodes, edges)
        }
    }
}
