#if canImport(UIKit)
import Foundation
import XYSystem

/// A node, a node by its id, or a rectangle: what `getIntersectingNodes` and `isNodeIntersecting` take.
public enum NodeOrRect {
    case node(Node)
    case id(String)
    case rect(Rect)
}

/// `useSvelteFlow()`: the functions that read and change a flow. They work on the store of the flow,
/// so they can be used from anywhere that holds it, not only from inside a node.
///
/// Where the functions of the interface return a promise, these take a completion handler that is
/// told whether it worked.
public final class FlowInstance {
    public let store: SwiftFlowStore

    public init(store: SwiftFlowStore) {
        self.store = store
    }

    public convenience init(flow: SwiftFlow) {
        self.init(store: flow.store)
    }

    // MARK: Viewport

    /// Zooms the viewport in by 1.2.
    public func zoomIn(_ options: ViewportHelperFunctionOptions? = nil, completion: ((Bool) -> Void)? = nil) {
        store.zoomIn(options, completion: completion)
    }

    /// Zooms the viewport out by 1 / 1.2.
    public func zoomOut(_ options: ViewportHelperFunctionOptions? = nil, completion: ((Bool) -> Void)? = nil) {
        store.zoomOut(options, completion: completion)
    }

    public func setZoom(
        _ zoomLevel: Double,
        _ options: ViewportHelperFunctionOptions? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let panZoom = store.panZoom.get() else {
            completion?(false)
            return
        }

        panZoom.scaleTo(zoomLevel, options: PanZoomTransformOptions(duration: options?.duration), completion: completion)
    }

    public func getZoom() -> Double {
        store.viewport.get().zoom
    }

    public func setViewport(
        _ viewport: Viewport,
        _ options: ViewportHelperFunctionOptions? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let panZoom = store.panZoom.get() else {
            completion?(false)
            return
        }

        panZoom.setViewport(viewport, options: PanZoomTransformOptions(duration: options?.duration)) { _ in
            completion?(true)
        }
    }

    public func getViewport() -> Viewport {
        store.viewport.get()
    }

    /// The viewport as a store, which can be followed.
    public var viewport: Writable<Viewport> {
        store.viewport
    }

    /// Sets the center of the view to the position. The zoom is the maximum zoom unless it is given.
    public func setCenter(
        _ x: Double,
        _ y: Double,
        _ options: SetCenterOptions? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        let nextZoom = options?.zoom ?? store.maxZoom.get()

        guard let panZoom = store.panZoom.get() else {
            completion?(false)
            return
        }

        panZoom.setViewport(
            Viewport(
                x: store.width.get() / 2 - x * nextZoom,
                y: store.height.get() / 2 - y * nextZoom,
                zoom: nextZoom),
            options: PanZoomTransformOptions(duration: options?.duration)
        ) { _ in
            completion?(true)
        }
    }

    /// Fits the view to the nodes, once they are measured.
    public func fitView(_ options: FitViewOptions? = nil, completion: ((Bool) -> Void)? = nil) {
        store.fitView(options, completion: completion)
    }

    /// Fits the view to the bounds.
    public func fitBounds(_ bounds: Rect, _ options: FitBoundsOptions? = nil, completion: ((Bool) -> Void)? = nil) {
        guard let panZoom = store.panZoom.get() else {
            completion?(false)
            return
        }

        let viewport = getViewportForBounds(
            bounds,
            width: store.width.get(),
            height: store.height.get(),
            minZoom: store.minZoom.get(),
            maxZoom: store.maxZoom.get(),
            padding: .all(.number(options?.padding ?? 0.1)))

        panZoom.setViewport(viewport, options: PanZoomTransformOptions(duration: options?.duration)) { _ in
            completion?(true)
        }
    }

    // MARK: Nodes and edges

    public func getInternalNode(_ id: String) -> InternalNode? {
        store.nodeLookup.get().get(id)
    }

    public func getNode(_ id: String) -> Node? {
        getInternalNode(id)?.internals.userNode
    }

    public func getNodes(_ ids: [String]? = nil) -> [Node] {
        guard let ids else { return store.nodes.get() }

        return ids.compactMap { getNode($0) }
    }

    public func getEdge(_ id: String) -> Edge? {
        store.edgeLookup.get().get(id)
    }

    public func getEdges(_ ids: [String]? = nil) -> [Edge] {
        guard let ids else { return store.edges.get() }

        return ids.compactMap { getEdge($0) }
    }

    private func nodeRect(_ nodeOrRect: NodeOrRect) -> Rect? {
        let lookup = store.nodeLookup.get()

        let node: Node?
        switch nodeOrRect {
        case .rect(let rect):
            return rect
        case .node(let value):
            node = value
        case .id(let id):
            node = lookup.get(id)?.internals.userNode
        }

        guard let node else { return nil }

        let position: XYPosition
        if let parentId = node.parentId {
            position = evaluateAbsolutePosition(
                node.position,
                dimensions: node.measured ?? Measured(),
                parentId: parentId,
                nodeLookup: lookup,
                nodeOrigin: store.nodeOrigin.get())
        } else {
            position = node.position
        }

        let dimensions = getNodeDimensions(node)
        return Rect(
            x: position.x,
            y: position.y,
            width: node.measured?.width ?? node.width ?? dimensions.width,
            height: node.measured?.height ?? node.height ?? dimensions.height)
    }

    /// The nodes that intersect with the node or the rectangle. With `partially` they only need to overlap.
    public func getIntersectingNodes(
        _ nodeOrRect: NodeOrRect,
        partially: Bool = true,
        nodes nodesToIntersect: [Node]? = nil
    ) -> [Node] {
        var isRect = false
        if case .rect = nodeOrRect { isRect = true }

        guard let rect = nodeRect(nodeOrRect) else { return [] }

        var excludedId: String?
        switch nodeOrRect {
        case .node(let node): excludedId = node.id
        case .id(let id): excludedId = id
        case .rect: break
        }

        let lookup = store.nodeLookup.get()

        return (nodesToIntersect ?? store.nodes.get()).filter { node in
            guard let internalNode = lookup.get(node.id), isRect || node.id != excludedId else {
                return false
            }

            let current = nodeToRect(internalNode)
            let overlappingArea = getOverlappingArea(current, rect)
            let partiallyVisible = partially && overlappingArea > 0

            return partiallyVisible || overlappingArea >= rect.width * rect.height
        }
    }

    public func isNodeIntersecting(_ nodeOrRect: NodeOrRect, area: Rect, partially: Bool = true) -> Bool {
        guard let rect = nodeRect(nodeOrRect) else { return false }

        let overlappingArea = getOverlappingArea(rect, area)
        let partiallyVisible = partially && overlappingArea > 0

        return partiallyVisible || overlappingArea >= rect.width * rect.height
    }

    /// Deletes nodes and edges, and the edges that belong to the nodes. What was deleted is handed to
    /// the completion.
    public func deleteElements(
        nodes nodesToRemove: [String] = [],
        edges edgesToRemove: [String] = [],
        completion: ((_ deletedNodes: [Node], _ deletedEdges: [Edge]) -> Void)? = nil
    ) {
        getElementsToRemove(
            nodesToRemove: nodesToRemove,
            edgesToRemove: edgesToRemove,
            nodes: store.nodes.get(),
            edges: store.edges.get(),
            onBeforeDelete: store.onbeforedelete.get()
        ) { [store] matchingNodes, matchingEdges in
            let nodeIds = Set(matchingNodes.map { $0.id })
            let edgeIds = Set(matchingEdges.map { $0.id })

            store.nodes.update { nodes in nodes.filter { !nodeIds.contains($0.id) } }
            store.edges.update { edges in edges.filter { !edgeIds.contains($0.id) } }

            completion?(matchingNodes, matchingEdges)
        }
    }

    // MARK: Positions

    /// Converts a position in the window to a position in the flow.
    public func screenToFlowPosition(_ position: XYPosition, snapToGrid: Bool = true) -> XYPosition {
        guard let domNode = store.domNode.get() else { return position }

        let grid = snapToGrid ? store.snapGrid.get() : nil
        let viewport = store.viewport.get()
        let bounds = domNode.boundingClientRect

        return pointToRendererPoint(
            XYPosition(x: position.x - bounds.x, y: position.y - bounds.y),
            transform: Transform(viewport.x, viewport.y, viewport.zoom),
            snapToGrid: grid != nil,
            snapGrid: grid ?? (1, 1))
    }

    /// Converts a position in the flow to a position in the window.
    public func flowToScreenPosition(_ position: XYPosition) -> XYPosition {
        guard let domNode = store.domNode.get() else { return position }

        let viewport = store.viewport.get()
        let bounds = domNode.boundingClientRect
        let rendererPosition = rendererPointToPoint(position, transform: Transform(viewport.x, viewport.y, viewport.zoom))

        return XYPosition(x: rendererPosition.x + bounds.x, y: rendererPosition.y + bounds.y)
    }

    // MARK: Updating

    /// Changes a node in place, and tells the flow about it.
    public func updateNode(_ id: String, _ update: (Node) -> Void) {
        guard let node = getNode(id) else { return }

        update(node)
        store.nodes.update { $0 }
    }

    /// Replaces a node with another one.
    public func replaceNode(_ id: String, with replacement: Node) {
        store.nodes.update { nodes in
            nodes.map { $0.id == id ? replacement : $0 }
        }
    }

    /// Changes the data of a node. The changes are merged into its data, or are its data with `replace`.
    public func updateNodeData(_ id: String, _ dataUpdate: [String: Any], replace: Bool = false) {
        guard let node = getNode(id) else { return }

        node.data = replace ? dataUpdate : node.data.merging(dataUpdate) { _, new in new }
        store.nodes.update { $0 }
    }

    public func updateNodeData(_ id: String, replace: Bool = false, _ dataUpdate: (Node) -> [String: Any]) {
        guard let node = getNode(id) else { return }

        updateNodeData(id, dataUpdate(node), replace: replace)
    }

    /// The nodes, edges and viewport as copies, which can change without changing the flow.
    public func toObject() -> (nodes: [Node], edges: [Edge], viewport: Viewport) {
        (
            nodes: store.nodes.get().map { $0.copy() },
            edges: store.edges.get().map { $0.copy() },
            viewport: store.viewport.get()
        )
    }

    public func getNodesBounds(_ nodes: [Node]) -> Rect {
        XYSystem.getNodesBounds(nodes, nodeOrigin: store.nodeOrigin.get(), nodeLookup: store.nodeLookup.get())
    }

    public func getNodesBounds(ids: [String]) -> Rect {
        XYSystem.getNodesBounds(ids: ids, nodeOrigin: store.nodeOrigin.get(), nodeLookup: store.nodeLookup.get())
    }

    /// The connections of a handle of a node.
    public func getHandleConnections(type: HandleType, nodeId: String, id: String? = nil) -> [HandleConnection] {
        store.connectionLookup.get()
            .get("\(nodeId)-\(type.rawValue)-\(id ?? "null")")?
            .values ?? []
    }

    // MARK: Hooks

    /// `useNodesData`: the id, type and data of the nodes, which changes when one of them does.
    public func nodesData(_ ids: [String]) -> Readable<[NodeDataSnapshot]> {
        let store = self.store
        var previous: [NodeDataSnapshot] = []
        var isFirstRun = true

        return Derived<[NodeDataSnapshot]>([store.nodes, store.nodeLookup]) {
            let lookup = store.nodeLookup.get()
            let next = ids.compactMap { lookup.get($0)?.internals.userNode }.map { NodeDataSnapshot($0) }

            if !shallowNodeData(next, previous) || isFirstRun {
                previous = next
                isFirstRun = false
            }

            return previous
        }
    }

    /// `useInternalNode`: the internal node with the id, which changes when the nodes do.
    public func internalNode(_ id: String) -> Readable<InternalNode?> {
        let store = self.store

        return Derived<InternalNode?>([store.nodeLookup, store.nodes]) {
            store.nodeLookup.get().get(id)
        }
    }

    /// `useNodeConnections`: the connections of a node, which can be those of its handles of a type, or of
    /// one handle.
    public func nodeConnections(nodeId: String, handleType: HandleType? = nil, handleId: String? = nil) -> Readable<[HandleConnection]> {
        let store = self.store
        var previous: OrderedMap<String, HandleConnection>?
        var current: [HandleConnection] = []

        var key = nodeId
        if let handleType {
            key += handleId.map { "-\(handleType.rawValue)-\($0)" } ?? "-\(handleType.rawValue)"
        }

        return Derived<[HandleConnection]>([store.edges, store.connectionLookup]) {
            let next = store.connectionLookup.get().get(key)

            if !areConnectionMapsEqual(next, previous) {
                previous = next
                current = next?.values ?? []
            }

            return current
        }
    }

    /// `useUpdateNodeInternals`: measures the nodes again, on the next frame.
    public func updateNodeInternals(_ ids: [String]) {
        let store = self.store
        let updates = OrderedMap<String, InternalNodeUpdate>()

        for id in ids {
            if let wrapper = (store.domNode.get() as? WeakDomNode)?.nodeWrapper(for: id) {
                updates.set(id, InternalNodeUpdate(id: id, nodeElement: wrapper, force: true))
            }
        }

        requestAnimationFrame {
            store.updateNodeInternals(updates)
        }
    }
}
#endif
