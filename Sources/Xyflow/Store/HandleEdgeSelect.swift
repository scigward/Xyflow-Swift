#if canImport(UIKit)
import Foundation
import XYSystem

extension SwiftFlowStore {
    /// Selects an edge the way a click on it does: when the edge can be selected, the selection
    /// rectangle goes away and the edge is selected, or unselected again with the multi selection key.
    public func handleEdgeSelect(_ id: String) {
        guard let edge = edgeLookup.get().get(id) else {
            devWarn("012", ErrorMessages.error012(id))
            return
        }

        let selectable = edge.selectable == true || (elementsSelectable.get() && edge.selectable == nil)

        if selectable {
            selectionRect.set(nil)
            selectionRectMode.set(nil)

            if edge.selected != true {
                addSelectedEdges([id])
            } else if edge.selected == true && multiselectionKeyPressed.get() {
                unselectNodesAndEdges(nodes: [], edges: [edge])
            }
        }
    }
}
#endif
