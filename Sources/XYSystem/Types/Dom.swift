import Foundation

/// A view of a flow, as far as the selectors of drag handles and the walk up the views of an event
/// are concerned.
public protocol FlowElement: AnyObject {
    /// `target.matches(selector)` for the selectors of a node's `dragHandle` and `noDragClassName`: `.className`.
    func matches(_ target: AnyObject?, selector: String) -> Bool
    /// The parent of a view that is part of the flow, to walk up from a view an event started on.
    func parent(of target: AnyObject) -> AnyObject?
}

/// The container of a flow as the controllers of this module need it. The view layer implements it
/// for the view that hosts the flow; it stands for the DOM element the controllers of xyflow are
/// given.
public protocol FlowDomNode: FlowElement {
    /// `getBoundingClientRect()`: where the container is, in the coordinates of the window.
    var boundingClientRect: Rect { get }
    /// The scale of the viewport view (`m22` of its transform), or `nil` while there is no viewport.
    var viewportScale: Double? { get }
    /// `target.closest('.className')`: whether the view an event started on, or one of the views
    /// around it, has the style class.
    func isWrapped(_ target: AnyObject?, withClass className: String) -> Bool
    /// The view an event started on, `event.target`, given its position in the window.
    func target(atX x: Double, y: Double) -> AnyObject?
}

/// A handle as the view layer knows it: what is told of it through its attributes and style classes.
public protocol HandleElement: AnyObject {
    /// `data-nodeid`
    var handleNodeId: String? { get }
    /// `data-handleid`
    var handleId: String? { get }
    /// `data-handlepos`
    var handlePosition: Position? { get }
    /// `classList.contains('source')` or `classList.contains('target')`
    var handleType: HandleType? { get }
    /// `classList.contains('connectable')`
    var handleIsConnectable: Bool { get }
    /// `classList.contains('connectableend')`
    var handleIsConnectableEnd: Bool { get }
    /// `getBoundingClientRect()`
    var boundingClientRect: Rect { get }
    /// `offsetWidth` and `offsetHeight`
    var dimensions: Dimensions { get }
}

/// A node as the view layer knows it, what `updateNodeInternals` measures.
public protocol NodeElement: AnyObject {
    /// `offsetWidth` and `offsetHeight`
    var dimensions: Dimensions { get }
    /// `getBoundingClientRect()`
    var boundingClientRect: Rect { get }
    /// `querySelectorAll('.source')` or `querySelectorAll('.target')`
    func handleElements(of type: HandleType) -> [HandleElement]
}

/// The document of a flow, in which handles are found and the pointer is followed while a
/// connection is made.
public protocol FlowDocument: AnyObject {
    /// `elementFromPoint(x, y)`, when what is there is a handle.
    func handleElement(atX x: Double, y: Double) -> HandleElement?
    /// `querySelector('.xy-flow__handle[data-id="flowId-nodeId-handleId-type"]')`
    func handleElement(flowId: String?, nodeId: String, handleId: String?, type: HandleType) -> HandleElement?
    /// Follows the pointer: `move` is called for every move of it and `up` when it is released.
    /// Calling the returned function stops following it.
    func addPointerListeners(
        move: @escaping (FlowPointerEvent) -> Void,
        up: @escaping (FlowPointerEvent) -> Void
    ) -> () -> Void
}

/// What `updateNodeInternals` is told of a node whose size might have changed.
public struct InternalNodeUpdate {
    public var id: String
    public var nodeElement: NodeElement
    public var force: Bool?

    public init(id: String, nodeElement: NodeElement, force: Bool? = nil) {
        self.id = id
        self.nodeElement = nodeElement
        self.force = force
    }
}
