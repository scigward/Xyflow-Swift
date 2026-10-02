import Foundation

/// Which attributes a dimension change writes to the node: `true` sets `width` and `height`
/// next to the measured dimensions, `.width` and `.height` only that attribute.
public enum SetAttributes: Equatable {
    case enabled(Bool)
    case width
    case height

    public var isEnabled: Bool {
        switch self {
        case .enabled(let value): return value
        case .width, .height: return true
        }
    }
}

public struct NodeDimensionChange {
    public var id: String
    public var dimensions: Dimensions?
    /// if this is true, the node is currently being resized via the NodeResizer
    public var resizing: Bool?
    /// if this is true, we will set width and height of the node and not just the measured dimensions
    public var setAttributes: SetAttributes?

    public init(id: String, dimensions: Dimensions? = nil, resizing: Bool? = nil, setAttributes: SetAttributes? = nil) {
        self.id = id
        self.dimensions = dimensions
        self.resizing = resizing
        self.setAttributes = setAttributes
    }
}

public struct NodePositionChange {
    public var id: String
    public var position: XYPosition?
    public var positionAbsolute: XYPosition?
    public var dragging: Bool?

    public init(id: String, position: XYPosition? = nil, positionAbsolute: XYPosition? = nil, dragging: Bool? = nil) {
        self.id = id
        self.position = position
        self.positionAbsolute = positionAbsolute
        self.dragging = dragging
    }
}

public struct NodeSelectionChange {
    public var id: String
    public var selected: Bool

    public init(id: String, selected: Bool) {
        self.id = id
        self.selected = selected
    }
}

public struct NodeRemoveChange {
    public var id: String

    public init(id: String) {
        self.id = id
    }
}

public struct NodeAddChange {
    public var item: Node
    public var index: Int?

    public init(item: Node, index: Int? = nil) {
        self.item = item
        self.index = index
    }
}

public struct NodeReplaceChange {
    public var id: String
    public var item: Node

    public init(id: String, item: Node) {
        self.id = id
        self.item = item
    }
}

/// The ways a node can change in a flow, to be applied to the state of the flow.
public enum NodeChange {
    case dimensions(NodeDimensionChange)
    case position(NodePositionChange)
    case select(NodeSelectionChange)
    case remove(NodeRemoveChange)
    case add(NodeAddChange)
    case replace(NodeReplaceChange)
}

/// The changes the node internals produce: a node that was measured, or one that has moved.
public enum NodeInternalsChange {
    case dimensions(NodeDimensionChange)
    case position(NodePositionChange)

    public var id: String {
        switch self {
        case .dimensions(let change): return change.id
        case .position(let change): return change.id
        }
    }
}

public typealias EdgeSelectionChange = NodeSelectionChange
public typealias EdgeRemoveChange = NodeRemoveChange

public struct EdgeAddChange {
    public var item: Edge
    public var index: Int?

    public init(item: Edge, index: Int? = nil) {
        self.item = item
        self.index = index
    }
}

public struct EdgeReplaceChange {
    public var id: String
    public var item: Edge

    public init(id: String, item: Edge) {
        self.id = id
        self.item = item
    }
}

/// The ways an edge can change in a flow.
public enum EdgeChange {
    case select(EdgeSelectionChange)
    case remove(EdgeRemoveChange)
    case add(EdgeAddChange)
    case replace(EdgeReplaceChange)
}
