import Foundation

public struct OnPointerDownParams {
    public var autoPanOnConnect: Bool
    public var connectionMode: ConnectionMode
    public var connectionRadius: Double
    public var domNode: FlowDomNode?
    public var document: FlowDocument
    public var handleId: String?
    public var nodeId: String
    public var isTarget: Bool
    public var nodeLookup: NodeLookup
    public var lib: String
    public var flowId: String?
    public var edgeUpdaterType: HandleType?
    public var updateConnection: UpdateConnection
    public var panBy: PanBy
    public var cancelConnection: () -> Void
    public var onConnectStart: OnConnectStart?
    public var onConnect: OnConnect?
    public var onConnectEnd: OnConnectEnd?
    public var isValidConnection: IsValidConnection?
    public var onReconnectEnd: ((FlowPointerEvent, FinalConnectionState) -> Void)?
    public var getTransform: () -> Transform
    public var getFromHandle: () -> Handle?
    public var autoPanSpeed: Double?

    public init(
        autoPanOnConnect: Bool,
        connectionMode: ConnectionMode,
        connectionRadius: Double,
        domNode: FlowDomNode?,
        document: FlowDocument,
        handleId: String?,
        nodeId: String,
        isTarget: Bool,
        nodeLookup: NodeLookup,
        lib: String,
        flowId: String?,
        edgeUpdaterType: HandleType? = nil,
        updateConnection: @escaping UpdateConnection,
        panBy: @escaping PanBy,
        cancelConnection: @escaping () -> Void,
        onConnectStart: OnConnectStart? = nil,
        onConnect: OnConnect? = nil,
        onConnectEnd: OnConnectEnd? = nil,
        isValidConnection: IsValidConnection? = nil,
        onReconnectEnd: ((FlowPointerEvent, FinalConnectionState) -> Void)? = nil,
        getTransform: @escaping () -> Transform,
        getFromHandle: @escaping () -> Handle?,
        autoPanSpeed: Double? = nil
    ) {
        self.autoPanOnConnect = autoPanOnConnect
        self.connectionMode = connectionMode
        self.connectionRadius = connectionRadius
        self.domNode = domNode
        self.document = document
        self.handleId = handleId
        self.nodeId = nodeId
        self.isTarget = isTarget
        self.nodeLookup = nodeLookup
        self.lib = lib
        self.flowId = flowId
        self.edgeUpdaterType = edgeUpdaterType
        self.updateConnection = updateConnection
        self.panBy = panBy
        self.cancelConnection = cancelConnection
        self.onConnectStart = onConnectStart
        self.onConnect = onConnect
        self.onConnectEnd = onConnectEnd
        self.isValidConnection = isValidConnection
        self.onReconnectEnd = onReconnectEnd
        self.getTransform = getTransform
        self.getFromHandle = getFromHandle
        self.autoPanSpeed = autoPanSpeed
    }
}

public struct IsValidParams {
    public var handle: Handle?
    public var connectionMode: ConnectionMode
    public var fromNodeId: String
    public var fromHandleId: String?
    public var fromType: HandleType
    public var isValidConnection: IsValidConnection?
    public var document: FlowDocument
    public var lib: String
    public var flowId: String?
    public var nodeLookup: NodeLookup

    public init(
        handle: Handle?,
        connectionMode: ConnectionMode,
        fromNodeId: String,
        fromHandleId: String?,
        fromType: HandleType,
        isValidConnection: IsValidConnection? = nil,
        document: FlowDocument,
        lib: String,
        flowId: String?,
        nodeLookup: NodeLookup
    ) {
        self.handle = handle
        self.connectionMode = connectionMode
        self.fromNodeId = fromNodeId
        self.fromHandleId = fromHandleId
        self.fromType = fromType
        self.isValidConnection = isValidConnection
        self.document = document
        self.lib = lib
        self.flowId = flowId
        self.nodeLookup = nodeLookup
    }
}

public struct HandleValidationResult {
    public var handleDomNode: HandleElement?
    public var isValid: Bool
    public var connection: Connection?
    public var toHandle: Handle?

    public init(handleDomNode: HandleElement? = nil, isValid: Bool = false, connection: Connection? = nil, toHandle: Handle? = nil) {
        self.handleDomNode = handleDomNode
        self.isValid = isValid
        self.connection = connection
        self.toHandle = toHandle
    }
}

private let alwaysValid: IsValidConnection = { _ in true }

/// The controller that makes connections: a pointer going down on a handle and dragging to
/// another one.
public enum XYHandle {
    public static func onPointerDown(_ event: FlowPointerEvent, _ params: OnPointerDownParams) {
        let doc = params.document
        let nodeId = params.nodeId
        let handleId = params.handleId
        let connectionRadius = params.connectionRadius
        let connectionMode = params.connectionMode
        let isValidConnection = params.isValidConnection ?? alwaysValid

        var autoPanId = 0
        var closestHandle: Handle?

        let clickedHandle = doc.handleElement(atX: event.clientX, y: event.clientY)

        guard let handleType = getHandleType(params.edgeUpdaterType, clickedHandle),
              let containerBounds = params.domNode?.boundingClientRect else {
            return
        }

        guard let fromHandleInternal = getHandle(nodeId, handleType, handleId, params.nodeLookup, connectionMode) else {
            return
        }

        var position = getEventPosition(event, containerBounds)
        var autoPanStarted = false
        var connection: Connection?
        var isValid: Bool? = false
        var handleDomNode: HandleElement?

        // when the user is moving the mouse close to the edge of the canvas while connecting we move the canvas
        func autoPan() {
            if !params.autoPanOnConnect {
                return
            }

            let movement = calcAutoPan(
                position,
                bounds: Dimensions(width: containerBounds.width, height: containerBounds.height),
                speed: params.autoPanSpeed ?? 15)

            params.panBy(XYPosition(x: movement[0], y: movement[1])) { _ in }
            autoPanId = requestAnimationFrame { autoPan() }
        }

        // Stays the same for all consecutive pointermove events
        var fromHandle = fromHandleInternal
        fromHandle.nodeId = nodeId
        fromHandle.type = handleType

        let fromNodeInternal = params.nodeLookup.get(nodeId)!

        let from = getHandlePosition(fromNodeInternal, handle: fromHandle, fallbackPosition: .left, center: true)

        let newConnection = ConnectionState(
            inProgress: true,
            isValid: nil,
            from: from,
            fromHandle: fromHandle,
            fromPosition: fromHandle.position,
            fromNode: fromNodeInternal,
            to: position,
            toHandle: nil,
            toPosition: oppositePosition[fromHandle.position],
            toNode: nil)

        params.updateConnection(newConnection)
        var previousConnection = newConnection

        params.onConnectStart?(event, OnConnectStartParams(nodeId: nodeId, handleId: handleId, handleType: handleType))

        var stopListening: (() -> Void)?

        func onPointerUp(_ event: FlowPointerEvent) {
            if (closestHandle != nil || handleDomNode != nil), connection != nil, isValid == true {
                params.onConnect?(connection!)
            }

            // it's important to get a fresh reference from the store here
            // in order to get the latest state of onConnectEnd
            var finalConnectionState = previousConnection.final
            finalConnectionState.toPosition = previousConnection.toHandle != nil ? previousConnection.toPosition : nil
            params.onConnectEnd?(event, finalConnectionState)

            if params.edgeUpdaterType != nil {
                params.onReconnectEnd?(event, finalConnectionState)
            }

            params.cancelConnection()
            cancelAnimationFrame(autoPanId)
            autoPanStarted = false
            isValid = false
            connection = nil
            handleDomNode = nil

            stopListening?()
            stopListening = nil
        }

        func onPointerMove(_ event: FlowPointerEvent) {
            if params.getFromHandle() == nil {
                onPointerUp(event)
                return
            }

            let transform = params.getTransform()
            position = getEventPosition(event, containerBounds)
            closestHandle = getClosestHandle(
                pointToRendererPoint(position, transform: transform, snapToGrid: false, snapGrid: (1, 1)),
                connectionRadius,
                params.nodeLookup,
                FromHandle(nodeId: fromHandle.nodeId, type: fromHandle.type, id: fromHandle.id))

            if !autoPanStarted {
                autoPan()
                autoPanStarted = true
            }

            let result = isValidHandle(
                event,
                IsValidParams(
                    handle: closestHandle,
                    connectionMode: connectionMode,
                    fromNodeId: nodeId,
                    fromHandleId: handleId,
                    fromType: params.isTarget ? .target : .source,
                    isValidConnection: isValidConnection,
                    document: doc,
                    lib: params.lib,
                    flowId: params.flowId,
                    nodeLookup: params.nodeLookup))

            handleDomNode = result.handleDomNode
            connection = result.connection
            isValid = isConnectionValid(closestHandle != nil, result.isValid)

            var next = previousConnection
            next.isValid = isValid
            if let closestHandle, isValid == true {
                next.to = rendererPointToPoint(XYPosition(x: closestHandle.x, y: closestHandle.y), transform: transform)
            } else {
                next.to = position
            }
            next.toHandle = result.toHandle
            if isValid == true, let toHandle = result.toHandle {
                next.toPosition = toHandle.position
            } else {
                next.toPosition = oppositePosition[fromHandle.position]
            }
            next.toNode = result.toHandle.flatMap { params.nodeLookup.get($0.nodeId) }

            // we don't want to trigger an update when the connection
            // is snapped to the same handle as before
            if isValid == true,
               closestHandle != nil,
               let previousToHandle = previousConnection.toHandle,
               let nextToHandle = next.toHandle,
               previousToHandle.type == nextToHandle.type,
               previousToHandle.nodeId == nextToHandle.nodeId,
               previousToHandle.id == nextToHandle.id,
               previousConnection.to?.x == next.to?.x,
               previousConnection.to?.y == next.to?.y {
                return
            }

            params.updateConnection(next)
            previousConnection = next
        }

        stopListening = doc.addPointerListeners(move: onPointerMove, up: onPointerUp)
    }

    /// checks if and returns connection in form of an object { source: 123, target: 312 }
    public static func isValid(_ event: FlowPointerEvent, _ params: IsValidParams) -> HandleValidationResult {
        isValidHandle(event, params)
    }
}

private func isValidHandle(_ event: FlowPointerEvent, _ params: IsValidParams) -> HandleValidationResult {
    let isTarget = params.fromType == .target
    let isValidConnection = params.isValidConnection ?? alwaysValid
    let doc = params.document

    let handleDomNode: HandleElement? = params.handle.flatMap {
        doc.handleElement(flowId: params.flowId, nodeId: $0.nodeId, handleId: $0.id, type: $0.type)
    }

    let handleBelow = doc.handleElement(atX: event.clientX, y: event.clientY)
    // we always want to prioritize the handle below the mouse cursor over the closest distance handle,
    // because it could be that the center of another handle is closer to the mouse pointer than the handle below the cursor
    let handleToCheck = handleBelow ?? handleDomNode

    var result = HandleValidationResult(handleDomNode: handleToCheck, isValid: false, connection: nil, toHandle: nil)

    if let handleToCheck {
        let handleId = handleToCheck.handleId
        let connectable = handleToCheck.handleIsConnectable
        let connectableEnd = handleToCheck.handleIsConnectableEnd

        guard let handleNodeId = handleToCheck.handleNodeId, !handleNodeId.isEmpty,
              let handleType = getHandleType(nil, handleToCheck) else {
            return result
        }

        let connection = Connection(
            source: isTarget ? handleNodeId : params.fromNodeId,
            target: isTarget ? params.fromNodeId : handleNodeId,
            sourceHandle: isTarget ? handleId : params.fromHandleId,
            targetHandle: isTarget ? params.fromHandleId : handleId)

        result.connection = connection

        let isConnectable = connectable && connectableEnd
        // in strict mode we don't allow target to target or source to source connections
        let isValid: Bool
        if isConnectable {
            if params.connectionMode == .strict {
                isValid = (isTarget && handleType == .source) || (!isTarget && handleType == .target)
            } else {
                isValid = handleNodeId != params.fromNodeId || handleId != params.fromHandleId
            }
        } else {
            isValid = false
        }

        result.isValid = isValid && isValidConnection(.connection(connection))

        result.toHandle = getHandle(handleNodeId, handleType, handleId, params.nodeLookup, params.connectionMode)
    }

    return result
}
