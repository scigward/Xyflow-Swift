import Foundation

public func isParentSelected(_ node: InternalNode, _ nodeLookup: NodeLookup) -> Bool {
    guard let parentId = node.parentId else {
        return false
    }

    guard let parentNode = nodeLookup.get(parentId) else {
        return false
    }

    if parentNode.selected == true {
        return true
    }

    return isParentSelected(parentNode, nodeLookup)
}

/// Whether the view an event started on, or one of the views above it up to `domNode`, matches
/// the selector.
public func hasSelector(_ target: AnyObject?, _ selector: String, _ domNode: FlowElement) -> Bool {
    var current = target

    while let element = current {
        if domNode.matches(element, selector: selector) { return true }
        if element === domNode { return false }
        current = domNode.parent(of: element)
    }

    return false
}

/// looks for all selected nodes and created a NodeDragItem for each of them
public func getDragItems(
    _ nodeLookup: NodeLookup,
    nodesDraggable: Bool,
    mousePos: XYPosition,
    nodeId: String? = nil
) -> OrderedMap<String, NodeDragItem> {
    let dragItems = OrderedMap<String, NodeDragItem>()

    for (id, node) in nodeLookup {
        if (node.selected == true || node.id == nodeId)
            && (node.parentId == nil || !isParentSelected(node, nodeLookup))
            && (node.draggable == true || (nodesDraggable && node.draggable == nil)) {
            if let internalNode = nodeLookup.get(id) {
                dragItems.set(
                    id,
                    NodeDragItem(
                        id: id,
                        position: internalNode.position,
                        distance: XYPosition(
                            x: mousePos.x - internalNode.internals.positionAbsolute.x,
                            y: mousePos.y - internalNode.internals.positionAbsolute.y),
                        measured: Dimensions(
                            width: internalNode.measured.width ?? 0,
                            height: internalNode.measured.height ?? 0),
                        internals: NodeDragItem.Internals(positionAbsolute: internalNode.internals.positionAbsolute),
                        extent: internalNode.extent,
                        parentId: internalNode.parentId,
                        origin: internalNode.origin,
                        expandParent: internalNode.expandParent))
            }
        }
    }

    return dragItems
}

/// Returns two params:
/// 1. the dragged node (or the first of the list, if we are dragging a node selection)
/// 2. array of selected nodes (for multi selections)
public func getEventHandlerParams(
    nodeId: String?,
    dragItems: OrderedMap<String, NodeDragItem>,
    nodeLookup: NodeLookup,
    dragging: Bool = true
) -> (node: Node?, nodes: [Node]) {
    var nodesFromDragItems: [Node] = []

    for (id, dragItem) in dragItems {
        if let node = nodeLookup.get(id)?.internals.userNode {
            let copy = node.copy()
            copy.position = dragItem.position
            copy.dragging = dragging
            nodesFromDragItems.append(copy)
        }
    }

    guard let nodeId, !nodeId.isEmpty else {
        return (nodesFromDragItems.first, nodesFromDragItems)
    }

    guard let node = nodeLookup.get(nodeId)?.internals.userNode else {
        return (nodesFromDragItems.first, nodesFromDragItems)
    }

    let copy = node.copy()
    copy.position = dragItems.get(nodeId)?.position ?? node.position
    copy.dragging = dragging

    return (copy, nodesFromDragItems)
}
