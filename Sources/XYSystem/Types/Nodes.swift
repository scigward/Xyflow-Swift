import Foundation

public enum HandleType: String, Equatable, Hashable {
    case source
    case target
}

/// A connection point of a node, measured relative to the node it sits on.
public struct Handle: Equatable {
    public var id: String?
    public var nodeId: String
    public var x: Double
    public var y: Double
    public var position: Position
    public var type: HandleType
    public var width: Double
    public var height: Double

    public init(
        id: String? = nil,
        nodeId: String,
        x: Double,
        y: Double,
        position: Position,
        type: HandleType,
        width: Double,
        height: Double
    ) {
        self.id = id
        self.nodeId = nodeId
        self.x = x
        self.y = y
        self.position = position
        self.type = type
        self.width = width
        self.height = height
    }
}

/// A handle a node declares up front, so its edges can render before the node is measured.
public struct NodeHandle: Equatable {
    public var id: String?
    public var x: Double
    public var y: Double
    public var position: Position
    public var type: HandleType
    public var width: Double?
    public var height: Double?

    public init(
        id: String? = nil,
        x: Double,
        y: Double,
        position: Position,
        type: HandleType,
        width: Double? = nil,
        height: Double? = nil
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.position = position
        self.type = type
        self.width = width
        self.height = height
    }
}

public struct NodeHandleBounds: Equatable {
    public var source: [Handle]?
    public var target: [Handle]?

    public init(source: [Handle]? = nil, target: [Handle]? = nil) {
        self.source = source
        self.target = target
    }
}

public struct NodeBounds: Equatable {
    public var x: Double
    public var y: Double
    public var width: Double?
    public var height: Double?

    public init(x: Double, y: Double, width: Double?, height: Double?) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// Where a node sits relative to its own position: `[0, 0]` is the top left corner,
/// `[0.5, 0.5]` the center and `[1, 1]` the bottom right corner.
public struct NodeOrigin: Equatable, Hashable {
    public var x: Double
    public var y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = NodeOrigin(0, 0)
}

/// The boundary a node can be moved in: its parent, or an explicit extent.
public enum NodeExtent: Equatable {
    case parent
    case coordinates(CoordinateExtent)
}

public struct Measured: Equatable {
    public var width: Double?
    public var height: Double?

    public init(width: Double? = nil, height: Double? = nil) {
        self.width = width
        self.height = height
    }
}

public enum Align: String, Equatable {
    case center
    case start
    case end
}

/// What `getNodeDimensions`, `nodeToRect` and `nodeToBox` read of a node, a node that went
/// through `adoptUserNodes` or a drag item.
public protocol NodeGeometry {
    var measuredWidth: Double? { get }
    var measuredHeight: Double? { get }
    var width: Double? { get }
    var height: Double? { get }
    var initialWidth: Double? { get }
    var initialHeight: Double? { get }
}

/// A node that has an absolute position, which is what everything that went through the lookup has.
public protocol AbsolutelyPositioned: NodeGeometry {
    var absolutePosition: XYPosition { get }
}

/// The node data structure that gets used for the `nodes` of a flow.
public final class Node: NodeGeometry {
    /// Unique id of a node.
    public var id: String
    /// Position of a node on the pane.
    public var position: XYPosition
    /// Arbitrary data passed to a node. Replacing or changing it bumps `dataRevision`.
    public var data: [String: Any] {
        didSet { dataRevision &+= 1 }
    }
    public private(set) var dataRevision: Int = 0
    /// Type of node defined in `nodeTypes`.
    public var type: String?
    /// Only relevant for default, source, target nodeType. Controls source position.
    public var sourcePosition: Position?
    /// Only relevant for default, source, target nodeType. Controls target position.
    public var targetPosition: Position?
    /// Whether or not the node should be visible on the canvas.
    public var hidden: Bool?
    public var selected: Bool?
    /// Whether or not the node is currently being dragged.
    public var dragging: Bool?
    /// Whether or not the node is able to be dragged.
    public var draggable: Bool?
    public var selectable: Bool?
    public var connectable: Bool?
    public var deletable: Bool?
    /// A class name that marks the views inside the node that act as drag handles.
    public var dragHandle: String?
    public var width: Double?
    public var height: Double?
    public var initialWidth: Double?
    public var initialHeight: Double?
    /// Parent node id, used for creating sub-flows.
    public var parentId: String?
    public var zIndex: Double?
    /// Boundary a node can be moved in.
    public var extent: NodeExtent?
    /// When `true`, the parent node expands if this node is dragged to the edge of the parent.
    public var expandParent: Bool?
    public var ariaLabel: String?
    /// Origin of the node relative to its position.
    public var origin: NodeOrigin?
    public var handles: [NodeHandle]?
    public var measured: Measured?
    /// Style classes of the node, as a space separated list.
    public var className: String?
    /// Style declarations of the node, e.g. `"width: 150px; --xy-node-border: 1px solid red"`.
    public var style: String?

    public var measuredWidth: Double? { measured?.width }
    public var measuredHeight: Double? { measured?.height }

    public init(
        id: String,
        position: XYPosition,
        data: [String: Any] = [:],
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
        handles: [NodeHandle]? = nil,
        measured: Measured? = nil,
        className: String? = nil,
        style: String? = nil
    ) {
        self.id = id
        self.position = position
        self.data = data
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
        self.handles = handles
        self.measured = measured
        self.className = className
        self.style = style
    }

    /// A copy with the same property values, `{ ...node }`.
    public func copy() -> Node {
        Node(
            id: id, position: position, data: data, type: type,
            sourcePosition: sourcePosition, targetPosition: targetPosition,
            hidden: hidden, selected: selected, dragging: dragging, draggable: draggable,
            selectable: selectable, connectable: connectable, deletable: deletable,
            dragHandle: dragHandle, width: width, height: height,
            initialWidth: initialWidth, initialHeight: initialHeight,
            parentId: parentId, zIndex: zIndex, extent: extent, expandParent: expandParent,
            ariaLabel: ariaLabel, origin: origin, handles: handles, measured: measured,
            className: className, style: style)
    }
}

/// The node data structure that gets used for internal nodes. It is a node with the things
/// that are needed to track it, under `internals`.
public final class InternalNode: AbsolutelyPositioned {
    public struct Internals {
        public var positionAbsolute: XYPosition
        public var z: Double
        /// Holds a reference to the original node object provided by the user. Used as an
        /// optimization to avoid certain operations.
        public var userNode: Node
        public var handleBounds: NodeHandleBounds?
        public var bounds: NodeBounds?

        public init(
            positionAbsolute: XYPosition,
            z: Double,
            userNode: Node,
            handleBounds: NodeHandleBounds? = nil,
            bounds: NodeBounds? = nil
        ) {
            self.positionAbsolute = positionAbsolute
            self.z = z
            self.userNode = userNode
            self.handleBounds = handleBounds
            self.bounds = bounds
        }
    }

    public var id: String
    public var position: XYPosition
    public var data: [String: Any]
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
    public var handles: [NodeHandle]?
    public var measured: Measured
    public var className: String?
    public var style: String?
    public var internals: Internals

    public var measuredWidth: Double? { measured.width }
    public var measuredHeight: Double? { measured.height }
    public var absolutePosition: XYPosition { internals.positionAbsolute }

    /// `{ ...defaults, ...userNode, measured, internals }`
    public init(userNode: Node, measured: Measured, internals: Internals) {
        self.id = userNode.id
        self.position = userNode.position
        self.data = userNode.data
        self.type = userNode.type
        self.sourcePosition = userNode.sourcePosition
        self.targetPosition = userNode.targetPosition
        self.hidden = userNode.hidden
        self.selected = userNode.selected
        self.dragging = userNode.dragging
        self.draggable = userNode.draggable
        self.selectable = userNode.selectable
        self.connectable = userNode.connectable
        self.deletable = userNode.deletable
        self.dragHandle = userNode.dragHandle
        self.width = userNode.width
        self.height = userNode.height
        self.initialWidth = userNode.initialWidth
        self.initialHeight = userNode.initialHeight
        self.parentId = userNode.parentId
        self.zIndex = userNode.zIndex
        self.extent = userNode.extent
        self.expandParent = userNode.expandParent
        self.ariaLabel = userNode.ariaLabel
        self.origin = userNode.origin
        self.handles = userNode.handles
        self.className = userNode.className
        self.style = userNode.style
        self.measured = measured
        self.internals = internals
    }

    /// A copy that is a different object, `{ ...node }`, which is what marks a node as updated.
    public func copy() -> InternalNode {
        let node = InternalNode(userNode: internals.userNode, measured: measured, internals: internals)
        node.id = id
        node.position = position
        node.data = data
        node.type = type
        node.sourcePosition = sourcePosition
        node.targetPosition = targetPosition
        node.hidden = hidden
        node.selected = selected
        node.dragging = dragging
        node.draggable = draggable
        node.selectable = selectable
        node.connectable = connectable
        node.deletable = deletable
        node.dragHandle = dragHandle
        node.width = width
        node.height = height
        node.initialWidth = initialWidth
        node.initialHeight = initialHeight
        node.parentId = parentId
        node.zIndex = zIndex
        node.extent = extent
        node.expandParent = expandParent
        node.ariaLabel = ariaLabel
        node.origin = origin
        node.handles = handles
        node.className = className
        node.style = style
        return node
    }
}

/// A node as it is dragged: where it is, and how far from the pointer it was picked up.
public final class NodeDragItem: AbsolutelyPositioned {
    public struct Internals {
        public var positionAbsolute: XYPosition

        public init(positionAbsolute: XYPosition) {
            self.positionAbsolute = positionAbsolute
        }
    }

    public var id: String
    public var position: XYPosition
    /// distance from the mouse cursor to the node when start dragging
    public var distance: XYPosition
    public var measured: Dimensions
    public var internals: Internals
    public var extent: NodeExtent?
    public var parentId: String?
    public var dragging: Bool?
    public var origin: NodeOrigin?
    public var expandParent: Bool?

    public var measuredWidth: Double? { measured.width }
    public var measuredHeight: Double? { measured.height }
    public var width: Double? { nil }
    public var height: Double? { nil }
    public var initialWidth: Double? { nil }
    public var initialHeight: Double? { nil }
    public var absolutePosition: XYPosition { internals.positionAbsolute }

    public init(
        id: String,
        position: XYPosition,
        distance: XYPosition,
        measured: Dimensions,
        internals: Internals,
        extent: NodeExtent? = nil,
        parentId: String? = nil,
        dragging: Bool? = nil,
        origin: NodeOrigin? = nil,
        expandParent: Bool? = nil
    ) {
        self.id = id
        self.position = position
        self.distance = distance
        self.measured = measured
        self.internals = internals
        self.extent = extent
        self.parentId = parentId
        self.dragging = dragging
        self.origin = origin
        self.expandParent = expandParent
    }
}

extension Node {
    /// The node as a `NodeProps` for a custom node: everything a node view is told of its node.
    public struct Props {
        public var id: String
        public var data: [String: Any]
        public var width: Double?
        public var height: Double?
        public var sourcePosition: Position?
        public var targetPosition: Position?
        public var dragHandle: String?
        public var parentId: String?
        public var type: String
        public var dragging: Bool
        public var zIndex: Double
        public var selectable: Bool
        public var deletable: Bool
        public var selected: Bool
        public var draggable: Bool
        /// Whether a node is connectable or not.
        public var isConnectable: Bool
        /// Position absolute x value.
        public var positionAbsoluteX: Double
        /// Position absolute y value.
        public var positionAbsoluteY: Double

        public init(
            id: String,
            data: [String: Any] = [:],
            width: Double? = nil,
            height: Double? = nil,
            sourcePosition: Position? = nil,
            targetPosition: Position? = nil,
            dragHandle: String? = nil,
            parentId: String? = nil,
            type: String = "default",
            dragging: Bool = false,
            zIndex: Double = 0,
            selectable: Bool = true,
            deletable: Bool = true,
            selected: Bool = false,
            draggable: Bool = true,
            isConnectable: Bool = true,
            positionAbsoluteX: Double = 0,
            positionAbsoluteY: Double = 0
        ) {
            self.id = id
            self.data = data
            self.width = width
            self.height = height
            self.sourcePosition = sourcePosition
            self.targetPosition = targetPosition
            self.dragHandle = dragHandle
            self.parentId = parentId
            self.type = type
            self.dragging = dragging
            self.zIndex = zIndex
            self.selectable = selectable
            self.deletable = deletable
            self.selected = selected
            self.draggable = draggable
            self.isConnectable = isConnectable
            self.positionAbsoluteX = positionAbsoluteX
            self.positionAbsoluteY = positionAbsoluteY
        }
    }
}

/// The props a custom node is given.
public typealias NodeProps = Node.Props

public typealias NodeLookup = OrderedMap<String, InternalNode>
public typealias ParentLookup = OrderedMap<String, OrderedMap<String, InternalNode>>
