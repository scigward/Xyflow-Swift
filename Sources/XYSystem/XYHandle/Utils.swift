import Foundation

private func getNodesWithinDistance(_ position: XYPosition, _ nodeLookup: NodeLookup, _ distance: Double) -> [InternalNode] {
    var nodes: [InternalNode] = []
    let rect = Rect(
        x: position.x - distance,
        y: position.y - distance,
        width: distance * 2,
        height: distance * 2)

    for (_, node) in nodeLookup {
        if getOverlappingArea(rect, nodeToRect(node)) > 0 {
            nodes.append(node)
        }
    }

    return nodes
}

/// this distance is used for the area around the user pointer
/// while doing a connection for finding the closest nodes
private let additionalDistance: Double = 250

/// The handle of a handle that a connection starts from, to find the others around it.
public struct FromHandle: Equatable {
    public var nodeId: String
    public var type: HandleType
    public var id: String?

    public init(nodeId: String, type: HandleType, id: String? = nil) {
        self.nodeId = nodeId
        self.type = type
        self.id = id
    }
}

public func getClosestHandle(
    _ position: XYPosition,
    _ connectionRadius: Double,
    _ nodeLookup: NodeLookup,
    _ fromHandle: FromHandle
) -> Handle? {
    var closestHandles: [Handle] = []
    var minDistance = Double.infinity

    let closeNodes = getNodesWithinDistance(position, nodeLookup, connectionRadius + additionalDistance)

    for node in closeNodes {
        let allHandles = (node.internals.handleBounds?.source ?? []) + (node.internals.handleBounds?.target ?? [])

        for handle in allHandles {
            // if the handle is the same as the fromHandle we skip it
            if fromHandle.nodeId == handle.nodeId && fromHandle.type == handle.type && fromHandle.id == handle.id {
                continue
            }

            // determine absolute position of the handle
            let center = getHandlePosition(node, handle: handle, fallbackPosition: handle.position, center: true)

            let distance = (pow(center.x - position.x, 2) + pow(center.y - position.y, 2)).squareRoot()
            if distance > connectionRadius {
                continue
            }

            var absolute = handle
            absolute.x = center.x
            absolute.y = center.y

            if distance < minDistance {
                closestHandles = [absolute]
                minDistance = distance
            } else if distance == minDistance {
                // when multiple handles are on the same distance we collect all of them
                closestHandles.append(absolute)
            }
        }
    }

    if closestHandles.isEmpty {
        return nil
    }
    // when multiple handles overlay each other we prefer the opposite handle
    if closestHandles.count > 1 {
        let oppositeHandleType: HandleType = fromHandle.type == .source ? .target : .source
        return closestHandles.first { $0.type == oppositeHandleType } ?? closestHandles[0]
    }

    return closestHandles[0]
}

public func getHandle(
    _ nodeId: String,
    _ handleType: HandleType,
    _ handleId: String?,
    _ nodeLookup: NodeLookup,
    _ connectionMode: ConnectionMode,
    withAbsolutePosition: Bool = false
) -> Handle? {
    guard let node = nodeLookup.get(nodeId) else {
        return nil
    }

    let handles: [Handle]?
    if connectionMode == .strict {
        handles = handleType == .source ? node.internals.handleBounds?.source : node.internals.handleBounds?.target
    } else {
        handles = (node.internals.handleBounds?.source ?? []) + (node.internals.handleBounds?.target ?? [])
    }

    let handle: Handle?
    if let handleId, !handleId.isEmpty {
        handle = handles?.first { $0.id == handleId }
    } else {
        handle = handles?.first
    }

    guard var found = handle, withAbsolutePosition else {
        return handle
    }

    let position = getHandlePosition(node, handle: found, fallbackPosition: found.position, center: true)
    found.x = position.x
    found.y = position.y
    return found
}

public func getHandleType(_ edgeUpdaterType: HandleType?, _ handleDomNode: HandleElement?) -> HandleType? {
    if let edgeUpdaterType {
        return edgeUpdaterType
    }

    return handleDomNode?.handleType
}

public func isConnectionValid(_ isInsideConnectionRadius: Bool, _ isHandleValid: Bool) -> Bool? {
    var isValid: Bool?

    if isHandleValid {
        isValid = true
    } else if isInsideConnectionRadius && !isHandleValid {
        isValid = false
    }

    return isValid
}
