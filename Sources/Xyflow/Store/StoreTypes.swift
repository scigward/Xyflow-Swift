#if canImport(UIKit)
import UIKit
import XYSystem

// MARK: Custom nodes

/// The content of a node. A custom node is a view that is told its props whenever they change;
/// the handles of the node are `HandleView`s inside of it.
public protocol FlowNodeComponent: AnyObject {
    func update(props: NodeProps)

    /// How big the node is when nothing sets its size: the size of its content, for the width and height
    /// that are given. A node that is laid out with constraints does not have to answer, its fitting
    /// size is used then.
    func preferredSize(width: Double?, height: Double?) -> CGSize?
}

extension FlowNodeComponent {
    public func preferredSize(width: Double?, height: Double?) -> CGSize? {
        nil
    }
}

public typealias FlowNodeView = UIView & FlowNodeComponent
public typealias NodeComponentFactory = () -> FlowNodeView

/// The node types of a flow by name. The built in ones are `input`, `output`, `default` and `group`.
public typealias NodeTypes = [String: NodeComponentFactory]

// MARK: Custom edges

/// The props a custom edge is given.
public struct EdgeProps {
    public var id: String
    public var source: String
    public var target: String
    public var sourceX: Double
    public var sourceY: Double
    public var targetX: Double
    public var targetY: Double
    public var sourcePosition: Position
    public var targetPosition: Position
    public var type: String
    public var data: [String: Any]?
    public var animated: Bool
    public var selected: Bool
    public var selectable: Bool
    public var deletable: Bool
    public var label: String?
    public var labelStyle: String?
    public var style: String?
    public var interactionWidth: Double?
    public var sourceHandleId: String?
    public var targetHandleId: String?
    /// The id of the marker at the start of the edge, `url('#id')` of the interface.
    public var markerStart: String?
    public var markerEnd: String?
    public var pathOptions: EdgePathOptions?

    public init(
        id: String,
        source: String,
        target: String,
        sourceX: Double,
        sourceY: Double,
        targetX: Double,
        targetY: Double,
        sourcePosition: Position,
        targetPosition: Position,
        type: String = "default",
        data: [String: Any]? = nil,
        animated: Bool = false,
        selected: Bool = false,
        selectable: Bool = true,
        deletable: Bool = true,
        label: String? = nil,
        labelStyle: String? = nil,
        style: String? = nil,
        interactionWidth: Double? = nil,
        sourceHandleId: String? = nil,
        targetHandleId: String? = nil,
        markerStart: String? = nil,
        markerEnd: String? = nil,
        pathOptions: EdgePathOptions? = nil
    ) {
        self.id = id
        self.source = source
        self.target = target
        self.sourceX = sourceX
        self.sourceY = sourceY
        self.targetX = targetX
        self.targetY = targetY
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
        self.type = type
        self.data = data
        self.animated = animated
        self.selected = selected
        self.selectable = selectable
        self.deletable = deletable
        self.label = label
        self.labelStyle = labelStyle
        self.style = style
        self.interactionWidth = interactionWidth
        self.sourceHandleId = sourceHandleId
        self.targetHandleId = targetHandleId
        self.markerStart = markerStart
        self.markerEnd = markerEnd
        self.pathOptions = pathOptions
    }
}

/// The drawing of an edge: a layer in the viewport, and the views of its labels, which sit in the
/// label layer of the viewport. An edge is told its props whenever they change.
public protocol FlowEdgeComponent: AnyObject {
    /// What the edge draws, in the coordinates of the flow.
    var layer: CALayer { get }
    /// The labels of the edge, in the coordinates of the flow.
    var labelViews: [UIView] { get }
    func update(props: EdgeProps, context: EdgeRenderContext)
    /// Restores presentation animations after reattachment, even when cached props have not changed.
    func restoreAnimations()
    /// Whether a point of the flow is on the edge, which is what a click on it hits.
    func contains(point: CGPoint) -> Bool
}

extension FlowEdgeComponent {
    /// Custom components without presentation animations need no lifecycle work.
    public func restoreAnimations() {}
}

/// What an edge needs of the flow it is drawn in.
public struct EdgeRenderContext {
    public var styleScope: FlowStyleScope
    public var markers: [MarkerProps]
    public var flowId: String?
    public var theme: ColorModeClass
    /// Selects the edge with the id the way a click on it does (`useHandleEdgeSelect`).
    public var selectEdge: (String) -> Void
    /// The font of the text of the flow, for a size and a weight.
    public var font: (CGFloat, UIFont.Weight) -> UIFont
    /// The stylesheet of the flow, and the classes of the views the edges and their labels are among.
    public var styleSheet: FlowStyleSheet?
    public var edgeAncestors: [Set<String>]
    public var labelAncestors: [Set<String>]

    public init(
        styleScope: FlowStyleScope,
        markers: [MarkerProps],
        flowId: String?,
        theme: ColorModeClass,
        selectEdge: @escaping (String) -> Void = { _ in },
        font: @escaping (CGFloat, UIFont.Weight) -> UIFont = { UIFont.systemFont(ofSize: $0, weight: $1) },
        styleSheet: FlowStyleSheet? = nil,
        edgeAncestors: [Set<String>] = [],
        labelAncestors: [Set<String>] = []
    ) {
        self.styleScope = styleScope
        self.markers = markers
        self.flowId = flowId
        self.theme = theme
        self.selectEdge = selectEdge
        self.font = font
        self.styleSheet = styleSheet
        self.edgeAncestors = edgeAncestors
        self.labelAncestors = labelAncestors
    }
}

public typealias EdgeComponentFactory = () -> FlowEdgeComponent

/// The edge types of a flow by name. The built in ones are `default` (bezier), `straight`,
/// `step` and `smoothstep`.
public typealias EdgeTypes = [String: EdgeComponentFactory]

/// An edge with the position it is drawn at (`EdgeLayouted`).
public struct EdgeLayouted {
    public var edge: Edge
    public var zIndex: Double?
    public var position: EdgePosition

    public init(edge: Edge, zIndex: Double?, position: EdgePosition) {
        self.edge = edge
        self.zIndex = zIndex
        self.position = position
    }

    public var id: String { edge.id }
}

// MARK: Callbacks

public typealias OnDelete = (_ nodes: [Node], _ edges: [Edge]) -> Void

/// Called with the connection that was made: the edge to add, or `nil` for no edge.
public typealias OnEdgeCreate = (Connection) -> EdgeOrConnection?

/// What a node event of the flow carries.
public struct NodeEvent {
    public var node: Node
    public var event: FlowPointerEvent
}

public struct NodeDragEvent {
    public var targetNode: Node?
    public var nodes: [Node]
    public var event: FlowPointerEvent
}

public struct EdgeEvent {
    public var edge: Edge
    public var event: FlowPointerEvent
}

public struct SelectionEvent {
    public var nodes: [Node]
    public var event: FlowPointerEvent
}

// MARK: Keys

/// A key of a shortcut: its name as `KeyboardEvent.key` has it (`"Shift"`, `"Backspace"`, `" "`,
/// `"a"`), with the modifiers that have to be held with it.
public struct KeyDefinition: Equatable, ExpressibleByStringLiteral {
    public var key: String
    /// The modifiers that have to be held with the key. Every set of modifiers is an alternative: the
    /// shortcut works when all the modifiers of one of them are held. No set means no modifier is needed.
    public var modifier: [EventModifiers]

    public init(key: String, modifier: [EventModifiers] = []) {
        self.key = key
        self.modifier = modifier
    }

    /// A key that needs all of the modifiers to be held.
    public init(key: String, requiring modifiers: EventModifiers) {
        self.key = key
        self.modifier = modifiers.isEmpty ? [] : [modifiers]
    }

    public init(stringLiteral value: String) {
        self.key = value
        self.modifier = []
    }

    /// Whether the key event is this key, with the modifiers it needs.
    func matches(_ event: FlowKeyEvent) -> Bool {
        if !modifier.isEmpty && !modifier.contains(where: { event.modifiers.isSuperset(of: $0) }) {
            return false
        }

        return event.key == key
    }
}

/// One key, several of them, or none (`KeyDefinition | KeyDefinition[] | null`).
public struct KeyDefinitions: Equatable, ExpressibleByStringLiteral, ExpressibleByArrayLiteral {
    public var definitions: [KeyDefinition]

    public init(_ definitions: [KeyDefinition]) {
        self.definitions = definitions
    }

    public init(stringLiteral value: String) {
        self.definitions = [KeyDefinition(key: value)]
    }

    public init(arrayLiteral elements: KeyDefinition...) {
        self.definitions = elements
    }

    public static let none = KeyDefinitions([])
}

public struct ConnectionData {
    public var connectionPosition: XYPosition?
    public var connectionStartHandle: Handle?
    public var connectionEndHandle: Handle?
    public var connectionStatus: String?
}
#endif
