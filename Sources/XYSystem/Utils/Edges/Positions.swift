import Foundation

public struct GetEdgePositionParams {
    public var id: String
    public var sourceNode: InternalNode
    public var sourceHandle: String?
    public var targetNode: InternalNode
    public var targetHandle: String?
    public var connectionMode: ConnectionMode
    public var onError: OnError?

    public init(
        id: String,
        sourceNode: InternalNode,
        sourceHandle: String?,
        targetNode: InternalNode,
        targetHandle: String?,
        connectionMode: ConnectionMode,
        onError: OnError? = nil
    ) {
        self.id = id
        self.sourceNode = sourceNode
        self.sourceHandle = sourceHandle
        self.targetNode = targetNode
        self.targetHandle = targetHandle
        self.connectionMode = connectionMode
        self.onError = onError
    }
}

private func isNodeInitialized(_ node: InternalNode) -> Bool {
    (node.internals.handleBounds != nil || !(node.handles ?? []).isEmpty)
        && ((node.measured.width ?? 0) != 0 || (node.width ?? 0) != 0 || (node.initialWidth ?? 0) != 0)
}

public func getEdgePosition(_ params: GetEdgePositionParams) -> EdgePosition? {
    let sourceNode = params.sourceNode
    let targetNode = params.targetNode

    if !isNodeInitialized(sourceNode) || !isNodeInitialized(targetNode) {
        return nil
    }

    let sourceHandleBounds = sourceNode.internals.handleBounds ?? toHandleBounds(sourceNode.handles, nodeId: sourceNode.id)
    let targetHandleBounds = targetNode.internals.handleBounds ?? toHandleBounds(targetNode.handles, nodeId: targetNode.id)

    let foundSource = getHandle(sourceHandleBounds?.source ?? [], params.sourceHandle)
    let foundTarget = getHandle(
        // when connection type is loose we can define all handles as sources and connect source -> source
        params.connectionMode == .strict
            ? targetHandleBounds?.target ?? []
            : (targetHandleBounds?.target ?? []) + (targetHandleBounds?.source ?? []),
        params.targetHandle)

    guard let sourceHandle = foundSource, let targetHandle = foundTarget else {
        params.onError?(
            "008",
            ErrorMessages.error008(
                foundSource == nil ? .source : .target,
                id: params.id,
                sourceHandle: params.sourceHandle,
                targetHandle: params.targetHandle))

        return nil
    }

    let sourcePosition = sourceHandle.position
    let targetPosition = targetHandle.position
    let source = getHandlePosition(sourceNode, handle: sourceHandle, fallbackPosition: sourcePosition)
    let target = getHandlePosition(targetNode, handle: targetHandle, fallbackPosition: targetPosition)

    return EdgePosition(
        sourceX: source.x,
        sourceY: source.y,
        targetX: target.x,
        targetY: target.y,
        sourcePosition: sourcePosition,
        targetPosition: targetPosition)
}

private func toHandleBounds(_ handles: [NodeHandle]?, nodeId: String) -> NodeHandleBounds? {
    guard let handles else {
        return nil
    }

    var source: [Handle] = []
    var target: [Handle] = []

    for handle in handles {
        let converted = Handle(
            id: handle.id,
            nodeId: nodeId,
            x: handle.x,
            y: handle.y,
            position: handle.position,
            type: handle.type,
            width: handle.width ?? 1,
            height: handle.height ?? 1)

        if handle.type == .source {
            source.append(converted)
        } else if handle.type == .target {
            target.append(converted)
        }
    }

    return NodeHandleBounds(source: source, target: target)
}

public func getHandlePosition(
    _ node: InternalNode,
    handle: Handle?,
    fallbackPosition: Position = .left,
    center: Bool = false
) -> XYPosition {
    let x = (handle?.x ?? 0) + node.internals.positionAbsolute.x
    let y = (handle?.y ?? 0) + node.internals.positionAbsolute.y
    let nodeDimensions = getNodeDimensions(node)
    let width = handle?.width ?? nodeDimensions.width
    let height = handle?.height ?? nodeDimensions.height

    if center {
        return XYPosition(x: x + width / 2, y: y + height / 2)
    }

    let position = handle?.position ?? fallbackPosition

    switch position {
    case .top:
        return XYPosition(x: x + width / 2, y: y)
    case .right:
        return XYPosition(x: x + width, y: y + height / 2)
    case .bottom:
        return XYPosition(x: x + width / 2, y: y + height)
    case .left:
        return XYPosition(x: x, y: y + height / 2)
    }
}

private func getHandle(_ bounds: [Handle], _ handleId: String?) -> Handle? {
    // if no handleId is given, we use the first handle, otherwise we check for the id
    if handleId == nil || handleId!.isEmpty {
        return bounds.first
    }

    return bounds.first { $0.id == handleId }
}
