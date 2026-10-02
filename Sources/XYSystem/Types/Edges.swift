import Foundation

/// Edges may optionally have a marker on either end. `MarkerType` enumerates the options.
public enum MarkerType: String, Equatable, Hashable {
    case arrow
    case arrowclosed
}

/// Edges can optionally have markers at the start and end of an edge.
public struct EdgeMarker: Equatable {
    public var type: MarkerType
    public var color: String?
    public var width: Double?
    public var height: Double?
    public var markerUnits: String?
    public var orient: String?
    public var strokeWidth: Double?

    public init(
        type: MarkerType,
        color: String? = nil,
        width: Double? = nil,
        height: Double? = nil,
        markerUnits: String? = nil,
        orient: String? = nil,
        strokeWidth: Double? = nil
    ) {
        self.type = type
        self.color = color
        self.width = width
        self.height = height
        self.markerUnits = markerUnits
        self.orient = orient
        self.strokeWidth = strokeWidth
    }
}

/// A marker is either the id of a marker that is defined elsewhere, or the description of one.
public enum EdgeMarkerType: Equatable {
    case id(String)
    case marker(EdgeMarker)
}

public struct MarkerProps: Equatable {
    public var id: String
    public var marker: EdgeMarker

    public init(id: String, marker: EdgeMarker) {
        self.id = id
        self.marker = marker
    }
}

/// The style of connection line rendered when creating new edges.
public enum ConnectionLineType: String, Equatable {
    case bezier = "default"
    case straight
    case step
    case smoothstep
    case simplebezier
}

public struct SmoothStepPathOptions: Equatable {
    public var offset: Double?
    public var borderRadius: Double?

    public init(offset: Double? = nil, borderRadius: Double? = nil) {
        self.offset = offset
        self.borderRadius = borderRadius
    }
}

public struct StepPathOptions: Equatable {
    public var offset: Double?

    public init(offset: Double? = nil) {
        self.offset = offset
    }
}

public struct BezierPathOptions: Equatable {
    public var curvature: Double?

    public init(curvature: Double? = nil) {
        self.curvature = curvature
    }
}

/// The `pathOptions` an edge of a built in type can carry.
public enum EdgePathOptions: Equatable {
    case smoothStep(SmoothStepPathOptions)
    case step(StepPathOptions)
    case bezier(BezierPathOptions)
}

public struct EdgePosition: Equatable {
    public var sourceX: Double
    public var sourceY: Double
    public var targetX: Double
    public var targetY: Double
    public var sourcePosition: Position
    public var targetPosition: Position

    public init(
        sourceX: Double,
        sourceY: Double,
        targetX: Double,
        targetY: Double,
        sourcePosition: Position,
        targetPosition: Position
    ) {
        self.sourceX = sourceX
        self.sourceY = sourceY
        self.targetX = targetX
        self.targetY = targetY
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
    }
}

/// An `Edge` is the complete description with everything a flow needs to know in order to render it.
public final class Edge {
    /// Unique id of an edge.
    public var id: String
    /// Type of edge defined in `edgeTypes`.
    public var type: String?
    /// Id of source node.
    public var source: String
    /// Id of target node.
    public var target: String
    /// Id of source handle, only needed if there are multiple handles per node.
    public var sourceHandle: String?
    /// Id of target handle, only needed if there are multiple handles per node.
    public var targetHandle: String?
    public var animated: Bool?
    public var hidden: Bool?
    public var deletable: Bool?
    public var selectable: Bool?
    /// Arbitrary data passed to an edge.
    public var data: [String: Any]?
    public var selected: Bool?
    /// Set the marker on the beginning of an edge.
    public var markerStart: EdgeMarkerType?
    /// Set the marker on the end of an edge.
    public var markerEnd: EdgeMarkerType?
    public var zIndex: Double?
    public var ariaLabel: String?
    /// An invisible path is rendered around each edge to make it easier to click or tap on.
    /// This is the width of that invisible path.
    public var interactionWidth: Double?
    public var label: String?
    public var labelStyle: String?
    public var style: String?
    public var className: String?
    /// Options of the path of the built in edge types.
    public var pathOptions: EdgePathOptions?

    public init(
        id: String,
        source: String,
        target: String,
        type: String? = nil,
        sourceHandle: String? = nil,
        targetHandle: String? = nil,
        animated: Bool? = nil,
        hidden: Bool? = nil,
        deletable: Bool? = nil,
        selectable: Bool? = nil,
        data: [String: Any]? = nil,
        selected: Bool? = nil,
        markerStart: EdgeMarkerType? = nil,
        markerEnd: EdgeMarkerType? = nil,
        zIndex: Double? = nil,
        ariaLabel: String? = nil,
        interactionWidth: Double? = nil,
        label: String? = nil,
        labelStyle: String? = nil,
        style: String? = nil,
        className: String? = nil,
        pathOptions: EdgePathOptions? = nil
    ) {
        self.id = id
        self.type = type
        self.source = source
        self.target = target
        self.sourceHandle = sourceHandle
        self.targetHandle = targetHandle
        self.animated = animated
        self.hidden = hidden
        self.deletable = deletable
        self.selectable = selectable
        self.data = data
        self.selected = selected
        self.markerStart = markerStart
        self.markerEnd = markerEnd
        self.zIndex = zIndex
        self.ariaLabel = ariaLabel
        self.interactionWidth = interactionWidth
        self.label = label
        self.labelStyle = labelStyle
        self.style = style
        self.className = className
        self.pathOptions = pathOptions
    }

    /// A copy with the same property values, `{ ...edge }`.
    public func copy() -> Edge {
        Edge(
            id: id, source: source, target: target, type: type,
            sourceHandle: sourceHandle, targetHandle: targetHandle,
            animated: animated, hidden: hidden, deletable: deletable, selectable: selectable,
            data: data, selected: selected, markerStart: markerStart, markerEnd: markerEnd,
            zIndex: zIndex, ariaLabel: ariaLabel, interactionWidth: interactionWidth,
            label: label, labelStyle: labelStyle, style: style, className: className,
            pathOptions: pathOptions)
    }
}

/// Options that every edge gets unless it sets the property itself: `defaultEdgeOptions`.
public struct DefaultEdgeOptions {
    public var type: String?
    public var animated: Bool?
    public var hidden: Bool?
    public var deletable: Bool?
    public var selectable: Bool?
    public var data: [String: Any]?
    public var markerStart: EdgeMarkerType?
    public var markerEnd: EdgeMarkerType?
    public var zIndex: Double?
    public var ariaLabel: String?
    public var interactionWidth: Double?
    public var label: String?
    public var labelStyle: String?
    public var style: String?
    public var className: String?
    public var pathOptions: EdgePathOptions?

    public init(
        type: String? = nil,
        animated: Bool? = nil,
        hidden: Bool? = nil,
        deletable: Bool? = nil,
        selectable: Bool? = nil,
        data: [String: Any]? = nil,
        markerStart: EdgeMarkerType? = nil,
        markerEnd: EdgeMarkerType? = nil,
        zIndex: Double? = nil,
        ariaLabel: String? = nil,
        interactionWidth: Double? = nil,
        label: String? = nil,
        labelStyle: String? = nil,
        style: String? = nil,
        className: String? = nil,
        pathOptions: EdgePathOptions? = nil
    ) {
        self.type = type
        self.animated = animated
        self.hidden = hidden
        self.deletable = deletable
        self.selectable = selectable
        self.data = data
        self.markerStart = markerStart
        self.markerEnd = markerEnd
        self.zIndex = zIndex
        self.ariaLabel = ariaLabel
        self.interactionWidth = interactionWidth
        self.label = label
        self.labelStyle = labelStyle
        self.style = style
        self.className = className
        self.pathOptions = pathOptions
    }
}

public typealias EdgeLookup = OrderedMap<String, Edge>
