#if canImport(UIKit)
import UIKit
import XYSystem

extension SwiftFlowStore {
    /// What the drag controller reads of the flow, every time it needs to (`getStoreItems` of the
    /// drag action).
    func dragStoreItems() -> XYDragStoreItems {
        let grid = snapGrid.get()
        let current = viewport.get()

        return XYDragStoreItems(
            nodes: nodes.get(),
            nodeLookup: nodeLookup.get(),
            edges: edges.get(),
            nodeExtent: nodeExtent.get(),
            snapGrid: grid ?? (0, 0),
            snapToGrid: grid != nil,
            nodeOrigin: nodeOrigin.get(),
            multiSelectionActive: multiselectionKeyPressed.get(),
            domNode: domNode.get(),
            transform: Transform(current.x, current.y, current.zoom),
            autoPanOnNodeDrag: autoPanOnNodeDrag.get(),
            nodesDraggable: nodesDraggable.get(),
            selectNodesOnDrag: selectNodesOnDrag.get(),
            nodeDragThreshold: nodeDragThreshold.get(),
            panBy: { [weak self] delta, completion in
                self?.panBy(delta, completion: completion)
            },
            unselectNodesAndEdges: { [weak self] nodes, edges in
                self?.unselectNodesAndEdges(nodes: nodes, edges: edges)
            },
            updateNodePositions: { [weak self] items, dragging in
                self?.updateNodePositions(items, dragging)
            })
    }
}
#endif
