import Foundation

/// The messages of the warnings and errors the flow reports, keyed by the number it reports them with.
public enum ErrorMessages {
    public static func error001() -> String {
        "Seems like you have not used a flow store as an ancestor."
    }

    public static func error002() -> String {
        "It looks like you've created a new nodeTypes or edgeTypes object. If this wasn't on purpose please define the nodeTypes/edgeTypes once and reuse them."
    }

    public static func error003(_ nodeType: String) -> String {
        "Node type \"\(nodeType)\" not found. Using fallback type \"default\"."
    }

    public static func error004() -> String {
        "The flow's parent container needs a width and a height to render the graph."
    }

    public static func error005() -> String {
        "Only child nodes can use a parent extent."
    }

    public static func error006() -> String {
        "Can't create edge. An edge needs a source and a target."
    }

    public static func error007(_ id: String) -> String {
        "The old edge with id=\(id) does not exist."
    }

    public static func error009(_ type: String) -> String {
        "Marker type \"\(type)\" doesn't exist."
    }

    public static func error008(
        _ handleType: HandleType,
        id: String,
        sourceHandle: String?,
        targetHandle: String?
    ) -> String {
        let handleId = handleType == .source ? sourceHandle : targetHandle
        return "Couldn't create edge for \(handleType.rawValue) handle id: \"\(handleId ?? "null")\", edge id: \(id)."
    }

    public static func error010() -> String {
        "Handle: No node id found. Make sure to only use a Handle inside a custom Node."
    }

    public static func error011(_ edgeType: String) -> String {
        "Edge type \"\(edgeType)\" not found. Using fallback type \"default\"."
    }

    public static func error012(_ id: String) -> String {
        "Node with id \"\(id)\" does not exist, it may have been removed. This can happen when a node is deleted before the \"onNodeClick\" handler is called."
    }

    public static func error014() -> String {
        "useNodeConnections: No node ID found. Call useNodeConnections inside a custom Node or provide a node ID."
    }

    public static func error015() -> String {
        "It seems that you are trying to drag a node that is not initialized. Please use onNodesChange as explained in the docs."
    }
}

public let infiniteExtent = CoordinateExtent.infinite

public let elementSelectionKeys = ["Enter", " ", "Escape"]
