import Foundation

public typealias Project = (XYPosition) -> XYPosition

public typealias OnMove = (FlowPointerEvent?, Viewport) -> Void
public typealias OnMoveStart = OnMove
public typealias OnMoveEnd = OnMove

/// The `Connection` type is the basic minimal description of an `Edge` between two nodes.
/// `addEdge` can be used to upgrade a `Connection` to an `Edge`.
public struct Connection: Equatable, Hashable {
    /// The id of the node this connection originates from.
    public var source: String
    /// The id of the node this connection terminates at.
    public var target: String
    /// When not `nil`, the id of the handle on the source node that this connection originates from.
    public var sourceHandle: String?
    /// When not `nil`, the id of the handle on the target node that this connection terminates at.
    public var targetHandle: String?

    public init(source: String, target: String, sourceHandle: String? = nil, targetHandle: String? = nil) {
        self.source = source
        self.target = target
        self.sourceHandle = sourceHandle
        self.targetHandle = targetHandle
    }
}

/// A `Connection` that includes the `edgeId` of the edge it belongs to.
public struct HandleConnection: Equatable, Hashable {
    public var source: String
    public var target: String
    public var sourceHandle: String?
    public var targetHandle: String?
    public var edgeId: String

    public init(
        source: String,
        target: String,
        sourceHandle: String? = nil,
        targetHandle: String? = nil,
        edgeId: String
    ) {
        self.source = source
        self.target = target
        self.sourceHandle = sourceHandle
        self.targetHandle = targetHandle
        self.edgeId = edgeId
    }

    public var connection: Connection {
        Connection(source: source, target: target, sourceHandle: sourceHandle, targetHandle: targetHandle)
    }
}

public typealias NodeConnection = HandleConnection

/// The `ConnectionMode` is used to set the mode of connection between nodes. `strict` is the
/// default one and only allows source to target edges. `loose` allows source to source and
/// target to target edges as well.
public enum ConnectionMode: String, Equatable {
    case strict
    case loose
}

public struct OnConnectStartParams: Equatable {
    public var nodeId: String?
    public var handleId: String?
    public var handleType: HandleType?

    public init(nodeId: String? = nil, handleId: String? = nil, handleType: HandleType? = nil) {
        self.nodeId = nodeId
        self.handleId = handleId
        self.handleType = handleType
    }
}

/// What `isValidConnection` is asked about: an edge, or a connection that is not one yet.
public enum EdgeOrConnection {
    case edge(Edge)
    case connection(Connection)

    public var source: String {
        switch self {
        case .edge(let edge): return edge.source
        case .connection(let connection): return connection.source
        }
    }

    public var target: String {
        switch self {
        case .edge(let edge): return edge.target
        case .connection(let connection): return connection.target
        }
    }

    public var sourceHandle: String? {
        switch self {
        case .edge(let edge): return edge.sourceHandle
        case .connection(let connection): return connection.sourceHandle
        }
    }

    public var targetHandle: String? {
        switch self {
        case .edge(let edge): return edge.targetHandle
        case .connection(let connection): return connection.targetHandle
        }
    }
}

public typealias IsValidConnection = (EdgeOrConnection) -> Bool

/// The state of a connection when it ended: the same as `ConnectionState` without `inProgress`.
public struct FinalConnectionState {
    public var isValid: Bool?
    public var from: XYPosition?
    public var fromHandle: Handle?
    public var fromPosition: Position?
    public var fromNode: InternalNode?
    public var to: XYPosition?
    public var toHandle: Handle?
    public var toPosition: Position?
    public var toNode: InternalNode?

    public init(
        isValid: Bool? = nil,
        from: XYPosition? = nil,
        fromHandle: Handle? = nil,
        fromPosition: Position? = nil,
        fromNode: InternalNode? = nil,
        to: XYPosition? = nil,
        toHandle: Handle? = nil,
        toPosition: Position? = nil,
        toNode: InternalNode? = nil
    ) {
        self.isValid = isValid
        self.from = from
        self.fromHandle = fromHandle
        self.fromPosition = fromPosition
        self.fromNode = fromNode
        self.to = to
        self.toHandle = toHandle
        self.toPosition = toPosition
        self.toNode = toNode
    }
}

/// Bundles all information about an ongoing connection. While `inProgress` is `false` there is no
/// connection and everything else is `nil`.
public struct ConnectionState {
    /// Indicates whether a connection is currently in progress.
    public var inProgress: Bool
    /// If an ongoing connection is above a handle or inside the connection radius, this will be
    /// `true` or `false`, otherwise `nil`.
    public var isValid: Bool?
    /// The xy start position.
    public var from: XYPosition?
    /// The start handle.
    public var fromHandle: Handle?
    /// The side (called position) of the start handle.
    public var fromPosition: Position?
    /// The start node.
    public var fromNode: InternalNode?
    /// The xy end position.
    public var to: XYPosition?
    /// The end handle.
    public var toHandle: Handle?
    /// The side (called position) of the end handle.
    public var toPosition: Position?
    /// The end node.
    public var toNode: InternalNode?

    public init(
        inProgress: Bool = false,
        isValid: Bool? = nil,
        from: XYPosition? = nil,
        fromHandle: Handle? = nil,
        fromPosition: Position? = nil,
        fromNode: InternalNode? = nil,
        to: XYPosition? = nil,
        toHandle: Handle? = nil,
        toPosition: Position? = nil,
        toNode: InternalNode? = nil
    ) {
        self.inProgress = inProgress
        self.isValid = isValid
        self.from = from
        self.fromHandle = fromHandle
        self.fromPosition = fromPosition
        self.fromNode = fromNode
        self.to = to
        self.toHandle = toHandle
        self.toPosition = toPosition
        self.toNode = toNode
    }

    public var final: FinalConnectionState {
        FinalConnectionState(
            isValid: isValid, from: from, fromHandle: fromHandle, fromPosition: fromPosition,
            fromNode: fromNode, to: to, toHandle: toHandle, toPosition: toPosition, toNode: toNode)
    }
}

/// No connection is in progress.
public let initialConnection = ConnectionState()

public typealias OnConnectStart = (FlowPointerEvent, OnConnectStartParams) -> Void
public typealias OnConnect = (Connection) -> Void
public typealias OnConnectEnd = (FlowPointerEvent, FinalConnectionState) -> Void

public typealias OnReconnect = (_ oldEdge: Edge, _ newConnection: Connection) -> Void
public typealias OnReconnectStart = (_ event: FlowPointerEvent, _ edge: Edge, _ handleType: HandleType) -> Void
public typealias OnReconnectEnd = (
    _ event: FlowPointerEvent, _ edge: Edge, _ handleType: HandleType, _ connectionState: FinalConnectionState
) -> Void

public typealias UpdateConnection = (ConnectionState) -> Void

public enum PaddingUnit: String {
    case px
    case percent = "%"
}

/// A padding is a number (a fraction of the viewport), or a string with a unit: `"20px"` or `"10%"`.
public enum PaddingWithUnit: Equatable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByStringLiteral {
    case number(Double)
    case string(String)

    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }

    public init(floatLiteral value: Double) {
        self = .number(value)
    }

    public init(stringLiteral value: String) {
        self = .string(value)
    }

    public static func px(_ value: Double) -> PaddingWithUnit {
        .string("\(formatNumber(value))px")
    }

    public static func percent(_ value: Double) -> PaddingWithUnit {
        .string("\(formatNumber(value))%")
    }
}

/// The padding around the bounds that are fitted into a viewport.
public enum Padding: Equatable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByStringLiteral {
    case all(PaddingWithUnit)
    case sides(top: PaddingWithUnit? = nil, right: PaddingWithUnit? = nil, bottom: PaddingWithUnit? = nil,
               left: PaddingWithUnit? = nil, x: PaddingWithUnit? = nil, y: PaddingWithUnit? = nil)

    public init(integerLiteral value: Int) {
        self = .all(.number(Double(value)))
    }

    public init(floatLiteral value: Double) {
        self = .all(.number(value))
    }

    public init(stringLiteral value: String) {
        self = .all(.string(value))
    }
}

/// Internally, a flow maintains a coordinate system that is independent of the rest of the page.
/// The `Viewport` tells you where in that system your flow is currently being displayed at and
/// how zoomed in or out it is.
public struct Viewport: Equatable, Hashable {
    public var x: Double
    public var y: Double
    public var zoom: Double

    public init(x: Double, y: Double, zoom: Double) {
        self.x = x
        self.y = y
        self.zoom = zoom
    }
}

public typealias SnapGrid = (Double, Double)

/// How the viewport is panned when the user scrolls. `free` pans in any direction, `vertical` and
/// `horizontal` restrict scroll panning to one axis.
public enum PanOnScrollMode: String, Equatable {
    case free
    case vertical
    case horizontal
}

public struct ViewportHelperFunctionOptions: Equatable {
    public var duration: Double?

    public init(duration: Double? = nil) {
        self.duration = duration
    }
}

public struct SetCenterOptions: Equatable {
    public var duration: Double?
    public var zoom: Double?

    public init(duration: Double? = nil, zoom: Double? = nil) {
        self.duration = duration
        self.zoom = zoom
    }
}

public struct FitBoundsOptions: Equatable {
    public var duration: Double?
    public var padding: Double?

    public init(duration: Double? = nil, padding: Double? = nil) {
        self.duration = duration
        self.padding = padding
    }
}

public struct FitViewOptions {
    public var padding: Padding?
    public var includeHiddenNodes: Bool?
    public var minZoom: Double?
    public var maxZoom: Double?
    public var duration: Double?
    /// The nodes to fit, by id. A node is only used for its `id`.
    public var nodes: [Node]?

    public init(
        padding: Padding? = nil,
        includeHiddenNodes: Bool? = nil,
        minZoom: Double? = nil,
        maxZoom: Double? = nil,
        duration: Double? = nil,
        nodes: [Node]? = nil
    ) {
        self.padding = padding
        self.includeHiddenNodes = includeHiddenNodes
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.duration = duration
        self.nodes = nodes
    }
}

public struct FitViewParams {
    public var nodes: NodeLookup
    public var width: Double
    public var height: Double
    public var panZoom: PanZoomInstance
    public var minZoom: Double
    public var maxZoom: Double

    public init(
        nodes: NodeLookup,
        width: Double,
        height: Double,
        panZoom: PanZoomInstance,
        minZoom: Double,
        maxZoom: Double
    ) {
        self.nodes = nodes
        self.width = width
        self.height = height
        self.panZoom = panZoom
        self.minZoom = minZoom
        self.maxZoom = maxZoom
    }
}

/// A key, or several of them: `KeyCode` is a `string | string[]`.
public struct KeyCode: Equatable, ExpressibleByStringLiteral, ExpressibleByArrayLiteral {
    public var keys: [String]

    public init(_ keys: [String]) {
        self.keys = keys
    }

    public init(stringLiteral value: String) {
        self.keys = [value]
    }

    public init(arrayLiteral elements: String...) {
        self.keys = elements
    }
}

/// Where a view is placed on top of the flow: the `position` of the minimap and the controls.
public enum PanelPosition: String, Equatable {
    case topLeft = "top-left"
    case topCenter = "top-center"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomCenter = "bottom-center"
    case bottomRight = "bottom-right"
    case centerLeft = "center-left"
    case centerRight = "center-right"
}

public struct ProOptions: Equatable {
    public var account: String?
    public var hideAttribution: Bool

    public init(account: String? = nil, hideAttribution: Bool) {
        self.account = account
        self.hideAttribution = hideAttribution
    }
}

public enum SelectionMode: String, Equatable {
    case partial
    case full
}

public struct SelectionRect: Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var startX: Double
    public var startY: Double

    public init(x: Double, y: Double, width: Double, height: Double, startX: Double, startY: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.startX = startX
        self.startY = startY
    }
}

public typealias OnError = (_ id: String, _ message: String) -> Void

public typealias UpdateNodePositions = (_ dragItems: OrderedMap<String, NodeDragItem>, _ dragging: Bool) -> Void

public enum ColorModeClass: String, Equatable {
    case light
    case dark
}

public enum ColorMode: String, Equatable {
    case light
    case dark
    case system
}

public typealias ConnectionLookup = OrderedMap<String, OrderedMap<String, HandleConnection>>

/// What `onBeforeDelete` answers: delete what was asked, delete nothing, or delete these instead.
public enum BeforeDeleteResult {
    case allow
    case deny
    case replace(nodes: [Node], edges: [Edge])
}

/// Called with the nodes and edges that are about to be deleted. The answer is given to `completion`,
/// which may happen later.
public typealias OnBeforeDelete = (
    _ nodes: [Node], _ edges: [Edge], _ completion: @escaping (BeforeDeleteResult) -> Void
) -> Void

public typealias OnSelectionDrag = (FlowPointerEvent, [Node]) -> Void

public typealias UpdateNodeInternals = ([String]) -> Void
