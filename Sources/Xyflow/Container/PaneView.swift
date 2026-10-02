#if canImport(UIKit)
import UIKit
import XYSystem

/// `Pane.svelte`: the surface the content of the flow is on. Clicking it unselects everything and, when
/// the selection is active, dragging on it draws the rectangle that selects nodes.
final class PaneView: UIView, FlowClickable, FlowContextMenuHandling {
    let store: SwiftFlowStore

    /// What drags the pane: the flow's own `panOnDrag` setting.
    var panOnDrag: PanOnDrag = true
    var selectionOnDrag: Bool?

    var onPaneClick: ((FlowPointerEvent) -> Void)?
    var onPaneContextMenu: ((FlowPointerEvent) -> Void)?

    private var containerBounds: Rect?
    private var selectedNodes: [InternalNode] = []

    /// Used to prevent click events when the user lets go of the selectionKey during a selection.
    private var selectionInProgress = false

    init(store: SwiftFlowStore) {
        self.store = store
        super.init(frame: .zero)

        flowClasses = [FlowClass.pane]
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: What is going on

    private var effectivePanOnDrag: PanOnDrag {
        store.panActivationKeyPressed.get() ? .enabled(true) : panOnDrag
    }

    /// Whether dragging on the pane selects instead of panning.
    var isSelecting: Bool {
        store.selectionKeyPressed.get()
            || store.selectionRect.get() != nil
            || (selectionOnDrag == true && effectivePanOnDrag != .enabled(true))
    }

    /// Whether the pointer on the pane is part of a selection, which keeps the pane from taking clicks.
    var hasActiveSelection: Bool {
        store.elementsSelectable.get() && (isSelecting || store.selectionRectMode.get() == "user")
    }

    // MARK: Click

    func flowClick(event: FlowPointerEvent) {
        // the handler of the click is only there while there is no selection, and it only takes clicks
        // on the pane itself
        if hasActiveSelection || event.target !== self { return }
        handleClick(event)
    }

    private func handleClick(_ event: FlowPointerEvent) {
        // We prevent click events when the user let go of the selectionKey during a selection
        // We also prevent click events when a connection is in progress
        if selectionInProgress || store.connection.get().inProgress {
            selectionInProgress = false
            return
        }

        onPaneClick?(event)
        store.unselectNodesAndEdges()
        store.selectionRectMode.set(nil)
    }

    func flowContextMenu(event: FlowPointerEvent) {
        if event.target !== self { return }

        if case .buttons(let buttons) = effectivePanOnDrag, buttons.contains(2) {
            return
        }

        onPaneContextMenu?(event)
    }

    // MARK: Selecting

    func pointerDown(_ event: FlowPointerEvent) {
        containerBounds = clientRect

        guard isSelecting, event.button == 0, event.target === self, let containerBounds else {
            return
        }

        let position = getEventPosition(event, containerBounds)

        store.unselectNodesAndEdges()

        store.selectionRect.set(SelectionRect(
            x: position.x,
            y: position.y,
            width: 0,
            height: 0,
            startX: position.x,
            startY: position.y))
    }

    func pointerMove(_ event: FlowPointerEvent) {
        guard isSelecting, let containerBounds, let selectionRect = store.selectionRect.get() else {
            return
        }

        selectionInProgress = true

        let mousePosition = getEventPosition(event, containerBounds)
        let startX = selectionRect.startX
        let startY = selectionRect.startY

        var nextUserSelectRect = selectionRect
        nextUserSelectRect.x = mousePosition.x < startX ? mousePosition.x : startX
        nextUserSelectRect.y = mousePosition.y < startY ? mousePosition.y : startY
        nextUserSelectRect.width = abs(mousePosition.x - startX)
        nextUserSelectRect.height = abs(mousePosition.y - startY)

        let allEdges = store.edges.get()
        let previousNodeIds = selectedNodes.map { $0.id }
        let previousEdgeIds = getConnectedEdges(selectedNodes.map { $0.internals.userNode }, allEdges).map { $0.id }

        let viewport = store.viewport.get()
        selectedNodes = getNodesInside(
            store.nodeLookup.get(),
            rect: Rect(
                x: nextUserSelectRect.x,
                y: nextUserSelectRect.y,
                width: nextUserSelectRect.width,
                height: nextUserSelectRect.height),
            transform: Transform(viewport.x, viewport.y, viewport.zoom),
            partially: store.selectionMode.get() == .partial,
            excludeNonSelectableNodes: true)

        let selectedEdgeIds = getConnectedEdges(selectedNodes.map { $0.internals.userNode }, allEdges).map { $0.id }
        let selectedNodeIds = selectedNodes.map { $0.id }

        // this prevents unnecessary updates while updating the selection rectangle
        if previousNodeIds.count != selectedNodeIds.count
            || selectedNodeIds.contains(where: { !previousNodeIds.contains($0) }) {
            store.nodes.update { nodes in nodes.map { PaneView.toggleSelected($0, selectedNodeIds) } }
        }

        if previousEdgeIds.count != selectedEdgeIds.count
            || selectedEdgeIds.contains(where: { !previousEdgeIds.contains($0) }) {
            store.edges.update { edges in edges.map { PaneView.toggleSelected($0, selectedEdgeIds) } }
        }

        store.selectionRectMode.set("user")
        store.selectionRect.set(nextUserSelectRect)
    }

    func pointerUp(_ event: FlowPointerEvent) {
        if event.button != 0 { return }

        // We only want to trigger click functions when in selection mode if
        // the user did not move the mouse.
        if !isSelecting && store.selectionRectMode.get() == "user" && event.target === self {
            handleClick(event)
        }

        store.selectionRect.set(nil)

        if !selectedNodes.isEmpty {
            store.selectionRectMode.set("nodes")
        }

        // If the user kept holding the selectionKey during the selection,
        // we need to reset the selectionInProgress, so the next click event is not prevented
        if store.selectionKeyPressed.get() {
            selectionInProgress = false
        }
    }

    static func toggleSelected(_ node: Node, _ ids: [String]) -> Node {
        let isSelected = ids.contains(node.id)

        if node.selected != isSelected {
            node.selected = isSelected
        }

        return node
    }

    static func toggleSelected(_ edge: Edge, _ ids: [String]) -> Edge {
        let isSelected = ids.contains(edge.id)

        if edge.selected != isSelected {
            edge.selected = isSelected
        }

        return edge
    }
}
#endif
