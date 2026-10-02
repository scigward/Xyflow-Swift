import Foundation

// this is used for straight edges and simple smoothstep edges (LTR, RTL, BTT, TTB)
public func getEdgeCenter(
    sourceX: Double,
    sourceY: Double,
    targetX: Double,
    targetY: Double
) -> (centerX: Double, centerY: Double, offsetX: Double, offsetY: Double) {
    let xOffset = abs(targetX - sourceX) / 2
    let centerX = targetX < sourceX ? targetX + xOffset : targetX - xOffset

    let yOffset = abs(targetY - sourceY) / 2
    let centerY = targetY < sourceY ? targetY + yOffset : targetY - yOffset

    return (centerX, centerY, xOffset, yOffset)
}

public struct GetEdgeZIndexParams {
    public var sourceNode: InternalNode
    public var targetNode: InternalNode
    public var selected: Bool
    public var zIndex: Double
    public var elevateOnSelect: Bool

    public init(
        sourceNode: InternalNode,
        targetNode: InternalNode,
        selected: Bool = false,
        zIndex: Double = 0,
        elevateOnSelect: Bool = false
    ) {
        self.sourceNode = sourceNode
        self.targetNode = targetNode
        self.selected = selected
        self.zIndex = zIndex
        self.elevateOnSelect = elevateOnSelect
    }
}

public func getElevatedEdgeZIndex(_ params: GetEdgeZIndexParams) -> Double {
    if !params.elevateOnSelect {
        return params.zIndex
    }

    let edgeOrConnectedNodeSelected = params.selected
        || params.targetNode.selected == true
        || params.sourceNode.selected == true
    let selectedZIndex = jsMax(
        jsMax(params.sourceNode.internals.z, params.targetNode.internals.z), 1000)

    return params.zIndex + (edgeOrConnectedNodeSelected ? selectedZIndex : 0)
}

public struct IsEdgeVisibleParams {
    public var sourceNode: InternalNode
    public var targetNode: InternalNode
    public var width: Double
    public var height: Double
    public var transform: Transform

    public init(sourceNode: InternalNode, targetNode: InternalNode, width: Double, height: Double, transform: Transform) {
        self.sourceNode = sourceNode
        self.targetNode = targetNode
        self.width = width
        self.height = height
        self.transform = transform
    }
}

public func isEdgeVisible(_ params: IsEdgeVisibleParams) -> Bool {
    var edgeBox = getBoundsOfBoxes(nodeToBox(params.sourceNode), nodeToBox(params.targetNode))

    if edgeBox.x == edgeBox.x2 {
        edgeBox.x2 += 1
    }

    if edgeBox.y == edgeBox.y2 {
        edgeBox.y2 += 1
    }

    let transform = params.transform
    let viewRect = Rect(
        x: -transform.x / transform.scale,
        y: -transform.y / transform.scale,
        width: params.width / transform.scale,
        height: params.height / transform.scale)

    return getOverlappingArea(viewRect, boxToRect(edgeBox)) > 0
}

func getEdgeId(source: String, sourceHandle: String?, target: String, targetHandle: String?) -> String {
    let sourcePart = (sourceHandle?.isEmpty ?? true) ? "" : sourceHandle!
    let targetPart = (targetHandle?.isEmpty ?? true) ? "" : targetHandle!
    return "xy-edge__\(source)\(sourcePart)-\(target)\(targetPart)"
}

func getEdgeId(_ connection: Connection) -> String {
    getEdgeId(
        source: connection.source, sourceHandle: connection.sourceHandle,
        target: connection.target, targetHandle: connection.targetHandle)
}

func connectionExists(_ edge: Edge, _ edges: [Edge]) -> Bool {
    edges.contains { el in
        el.source == edge.source
            && el.target == edge.target
            && (el.sourceHandle == edge.sourceHandle || ((el.sourceHandle?.isEmpty ?? true) && (edge.sourceHandle?.isEmpty ?? true)))
            && (el.targetHandle == edge.targetHandle || ((el.targetHandle?.isEmpty ?? true) && (edge.targetHandle?.isEmpty ?? true)))
    }
}

/// A convenience function to add a new `Edge` to an array of edges. It also performs some
/// validation to make sure you don't add an invalid edge or duplicate an existing one.
/// - Parameters:
///   - edgeParams: Either an `Edge` or a `Connection` you want to add.
///   - edges: The array of all current edges.
/// - Returns: A new array of edges with the new edge added.
///
/// If an edge with the same `target` and `source` already exists (and the same `targetHandle` and
/// `sourceHandle` if those are set), then this won't add a new edge even if the `id` is different.
public func addEdge(_ edgeParams: EdgeOrConnection, _ edges: [Edge]) -> [Edge] {
    if edgeParams.source.isEmpty || edgeParams.target.isEmpty {
        devWarn("006", ErrorMessages.error006())

        return edges
    }

    let edge: Edge
    switch edgeParams {
    case .edge(let value):
        edge = value.copy()
    case .connection(let connection):
        edge = Edge(
            id: getEdgeId(connection),
            source: connection.source,
            target: connection.target,
            sourceHandle: connection.sourceHandle,
            targetHandle: connection.targetHandle)
    }

    if connectionExists(edge, edges) {
        return edges
    }

    return edges + [edge]
}

public struct ReconnectEdgeOptions {
    /// Should the id of the old edge be replaced with the new connection id.
    public var shouldReplaceId: Bool

    public init(shouldReplaceId: Bool = true) {
        self.shouldReplaceId = shouldReplaceId
    }
}

/// Updates an existing `Edge` with new properties. This searches your edge array for an edge with
/// a matching `id` and updates its properties with the connection you provide.
/// - Parameters:
///   - oldEdge: The edge you want to update.
///   - newConnection: The new connection you want to update the edge with.
///   - edges: The array of all current edges.
/// - Returns: The updated edges array.
public func reconnectEdge(
    _ oldEdge: Edge,
    _ newConnection: Connection,
    _ edges: [Edge],
    options: ReconnectEdgeOptions = ReconnectEdgeOptions()
) -> [Edge] {
    if newConnection.source.isEmpty || newConnection.target.isEmpty {
        devWarn("006", ErrorMessages.error006())

        return edges
    }

    guard edges.contains(where: { $0.id == oldEdge.id }) else {
        devWarn("007", ErrorMessages.error007(oldEdge.id))

        return edges
    }

    // Remove old edge and create the new edge with parameters of old edge.
    let edge = oldEdge.copy()
    edge.id = options.shouldReplaceId ? getEdgeId(newConnection) : oldEdge.id
    edge.source = newConnection.source
    edge.target = newConnection.target
    edge.sourceHandle = newConnection.sourceHandle
    edge.targetHandle = newConnection.targetHandle

    return edges.filter { $0.id != oldEdge.id } + [edge]
}
