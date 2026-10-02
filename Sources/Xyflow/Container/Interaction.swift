#if canImport(UIKit)
import UIKit
import XYSystem

/// A view the drag of a node, or of a selection of nodes, starts on.
protocol FlowDragHost: AnyObject {
    var flowDragBehavior: D3DragBehavior { get }
}

/// A view that is clicked (tapped), or a pointer goes down on.
protocol FlowClickable: AnyObject {
    func flowClick(event: FlowPointerEvent)
}

/// A view that does something when the pointer goes down on it, before anything else does: the handle
/// of a node starts a connection.
protocol FlowPointerDownHandling: AnyObject {
    func flowPointerDown(event: FlowPointerEvent)
}

/// A view that wants to know where the pointer is while it is over it.
protocol FlowHoverable: AnyObject {
    func flowHover(event: FlowPointerEvent, phase: UIGestureRecognizer.State)
}

/// A view that is told when a context menu is asked for on it: the secondary button of a pointer.
protocol FlowContextMenuHandling: AnyObject {
    func flowContextMenu(event: FlowPointerEvent)
}

extension UIView {
    /// The flow this view is part of.
    var enclosingFlow: SwiftFlow? {
        var current: UIView? = self
        while let view = current {
            if let flow = view as? SwiftFlow { return flow }
            current = view.superview
        }
        return nil
    }

    /// The node this view is inside of, for the views a custom node is made of.
    public var enclosingNodeWrapper: NodeWrapperView? {
        var current: UIView? = self
        while let view = current {
            if let wrapper = view as? NodeWrapperView { return wrapper }
            current = view.superview
        }
        return nil
    }
}
#endif
