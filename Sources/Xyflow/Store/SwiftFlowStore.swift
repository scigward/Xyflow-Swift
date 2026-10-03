#if canImport(UIKit)
import Foundation
import XYSystem

/// The state of a flow and what changes it: the stores the components read and follow, and the
/// actions they call. A store is made without a view, so something outside of the flow (a toolbar, a
/// screen) can hold it and talk to the flow through `FlowInstance`.
public final class SwiftFlowStore {
    // The lookups are the ones the nodes and edges are adopted into; they are maps that change in place.
    private let nodeLookupMap: NodeLookup
    private let parentLookupMap: ParentLookup
    private let connectionLookupMap: ConnectionLookup
    private let edgeLookupMap: EdgeLookup

    // The options the store was made with, which are what the absolute positions are updated with.
    private let initialNodeOrigin: NodeOrigin?
    private let initialNodeExtent: CoordinateExtent?

    public let flowId = Writable<String?>(nil)
    public let nodes: NodesStore
    public let nodeLookup: Readable<NodeLookup>
    public let parentLookup: Readable<ParentLookup>
    public let edgeLookup: Readable<EdgeLookup>
    public let edges: EdgesStore
    public let connectionLookup: Readable<ConnectionLookup>
    public let width = Writable<Double>(500)
    public let height = Writable<Double>(500)
    public let minZoom = Writable<Double>(0.5)
    public let maxZoom = Writable<Double>(2)
    public let nodeOrigin: Writable<NodeOrigin>
    public let nodeDragThreshold = Writable<Double>(1)
    public let nodeExtent: Writable<CoordinateExtent>
    public let translateExtent = Writable<CoordinateExtent>(infiniteExtent)
    public let autoPanOnNodeDrag = Writable<Bool>(true)
    public let autoPanOnConnect = Writable<Bool>(true)
    public let fitViewQueued = Writable<Bool>(false)
    public let fitViewOptions = Writable<FitViewOptions?>(nil)
    public let fitViewResolver = Writable<FitViewResolver?>(nil)
    public let panZoom = Writable<PanZoomInstance?>(nil)
    public let snapGrid = Writable<SnapGrid?>(nil)
    public let dragging = Writable<Bool>(false)
    public let selectionRect = Writable<SelectionRect?>(nil)
    public let selectionKeyPressed = Writable<Bool>(false)
    public let multiselectionKeyPressed = Writable<Bool>(false)
    public let deleteKeyPressed = Writable<Bool>(false)
    public let panActivationKeyPressed = Writable<Bool>(false)
    public let zoomActivationKeyPressed = Writable<Bool>(false)
    public let selectionRectMode = Writable<String?>(nil)
    public let selectionMode = Writable<SelectionMode>(.partial)
    public let nodeTypes = Writable<NodeTypes>(BuiltInTypes.nodeTypes)
    public let edgeTypes = Writable<EdgeTypes>(BuiltInTypes.edgeTypes)
    public let viewport: Writable<Viewport>
    public let connectionMode = Writable<ConnectionMode>(.strict)
    public let domNode = Writable<FlowDomNode?>(nil)
    public let connectionLineType = Writable<ConnectionLineType>(.bezier)
    public let connectionRadius = Writable<Double>(20)
    public let isValidConnection = Writable<IsValidConnection>({ _ in true })
    public let nodesDraggable = Writable<Bool>(true)
    public let nodesConnectable = Writable<Bool>(true)
    public let elementsSelectable = Writable<Bool>(true)
    public let selectNodesOnDrag = Writable<Bool>(true)
    public let defaultMarkerColor = Writable<String>("#b1b1b7")
    public let lib = Readable<String>("swift")
    public let onlyRenderVisibleElements = Writable<Bool>(false)
    public let onerror = Writable<OnError>({ id, message in devWarn(id, message) })
    public let ondelete = Writable<OnDelete?>(nil)
    public let onedgecreate = Writable<OnEdgeCreate?>(nil)
    public let onconnect = Writable<OnConnect?>(nil)
    public let onconnectstart = Writable<OnConnectStart?>(nil)
    public let onconnectend = Writable<OnConnectEnd?>(nil)
    public let onbeforedelete = Writable<OnBeforeDelete?>(nil)
    public let nodesInitialized = Writable<Bool>(false)
    public let edgesInitialized = Writable<Bool>(false)
    public let viewportInitialized = Writable<Bool>(false)

    // Derived state
    public private(set) var visibleNodes: Readable<[InternalNode]>!
    public private(set) var visibleEdges: Readable<[EdgeLayouted]>!
    public private(set) var connection: Readable<ConnectionState>!
    public private(set) var markers: Readable<[MarkerProps]>!
    public private(set) var initialized: Readable<Bool>!
    private let currentConnection = Writable<ConnectionState>(initialConnection)

    private var deleteKeySubscription: Unsubscribe?

    public init(
        nodes initialNodes: [Node] = [],
        edges initialEdges: [Edge] = [],
        width initialWidth: Double? = nil,
        height initialHeight: Double? = nil,
        fitView: Bool? = nil,
        nodeOrigin initialOrigin: NodeOrigin? = nil,
        nodeExtent initialExtent: CoordinateExtent? = nil
    ) {
        nodeLookupMap = NodeLookup()
        parentLookupMap = ParentLookup()
        connectionLookupMap = ConnectionLookup()
        edgeLookupMap = EdgeLookup()
        initialNodeOrigin = initialOrigin
        initialNodeExtent = initialExtent

        let storeNodeOrigin = initialOrigin ?? .zero
        let storeNodeExtent = initialExtent ?? infiniteExtent

        adoptUserNodes(
            initialNodes,
            nodeLookupMap,
            parentLookupMap,
            options: UpdateNodesOptions(
                nodeOrigin: storeNodeOrigin,
                nodeExtent: storeNodeExtent,
                elevateNodesOnSelect: false,
                checkEquality: false))

        updateConnectionLookup(connectionLookupMap, edgeLookupMap, initialEdges)

        var initialViewport = Viewport(x: 0, y: 0, zoom: 1)

        if fitView == true, let initialWidth, let initialHeight, initialWidth != 0, initialHeight != 0 {
            let bounds = getInternalNodesBounds(nodeLookupMap) { node in
                ((node.width ?? 0) != 0 || (node.initialWidth ?? 0) != 0)
                    && ((node.height ?? 0) != 0 || (node.initialHeight ?? 0) != 0)
            }
            initialViewport = getViewportForBounds(
                bounds, width: initialWidth, height: initialHeight, minZoom: 0.5, maxZoom: 2, padding: 0.1)
        }

        viewport = Writable<Viewport>(initialViewport)
        nodeOrigin = Writable<NodeOrigin>(storeNodeOrigin)
        nodeExtent = Writable<CoordinateExtent>(storeNodeExtent)
        nodeLookup = Readable<NodeLookup>(nodeLookupMap)
        parentLookup = Readable<ParentLookup>(parentLookupMap)
        edgeLookup = Readable<EdgeLookup>(edgeLookupMap)
        connectionLookup = Readable<ConnectionLookup>(connectionLookupMap)

        nodes = NodesStore(
            nodes: initialNodes,
            nodeLookup: nodeLookupMap,
            parentLookup: parentLookupMap,
            nodeOrigin: storeNodeOrigin,
            nodeExtent: storeNodeExtent,
            fitViewQueued: fitViewQueued,
            fitViewOptions: fitViewOptions,
            fitViewResolver: fitViewResolver,
            panZoom: panZoom,
            width: width,
            height: height,
            minZoom: minZoom,
            maxZoom: maxZoom)
        edges = EdgesStore(edges: initialEdges, connectionLookup: connectionLookupMap, edgeLookup: edgeLookupMap)

        if let initialWidth { width.set(initialWidth) }
        if let initialHeight { height.set(initialHeight) }

        makeDerivedState()
        subscribeToDeleteKey()
    }

    deinit {
        deleteKeySubscription?()
    }

    // MARK: Derived state

    private func makeDerivedState() {
        let nodes = self.nodes
        let edges = self.edges
        let nodeLookup = self.nodeLookup
        let width = self.width
        let height = self.height
        let viewport = self.viewport
        let onlyRenderVisibleElements = self.onlyRenderVisibleElements

        // The viewport moves with every frame of a pan, and most of the time the same nodes are on
        // screen after it: then nobody is told.
        visibleNodes = Derived<[InternalNode]>(
            [nodeLookup, onlyRenderVisibleElements, nodes],
            quiet: [width, height, viewport],
            isEqual: sameObjects
        ) {
            let lookup = nodeLookup.get()
            let current = viewport.get()
            let transform = Transform(current.x, current.y, current.zoom)

            if onlyRenderVisibleElements.get() {
                return getNodesInside(
                    lookup,
                    rect: Rect(x: 0, y: 0, width: width.get(), height: height.get()),
                    transform: transform,
                    partially: true)
            }

            return lookup.values
        }

        let connectionMode = self.connectionMode
        let onerror = self.onerror

        let visibleEdgesUnlayouted = Derived<[Edge]>(
            [edges, nodes, nodeLookup, onlyRenderVisibleElements],
            quiet: [viewport, width, height],
            isEqual: sameObjects
        ) {
            let allEdges = edges.get()
            let lookup = nodeLookup.get()
            let currentWidth = width.get()
            let currentHeight = height.get()
            let current = viewport.get()

            guard onlyRenderVisibleElements.get(), currentWidth != 0, currentHeight != 0 else {
                return allEdges
            }

            return allEdges.filter { edge in
                guard let sourceNode = lookup.get(edge.source), let targetNode = lookup.get(edge.target) else {
                    return false
                }

                return isEdgeVisible(IsEdgeVisibleParams(
                    sourceNode: sourceNode,
                    targetNode: targetNode,
                    width: currentWidth,
                    height: currentHeight,
                    transform: Transform(current.x, current.y, current.zoom)))
            }
        }

        visibleEdges = Derived<[EdgeLayouted]>(
            [visibleEdgesUnlayouted, nodes, nodeLookup, connectionMode, onerror]
        ) {
            let lookup = nodeLookup.get()
            var layouted: [EdgeLayouted] = []

            for edge in visibleEdgesUnlayouted.get() {
                guard let sourceNode = lookup.get(edge.source), let targetNode = lookup.get(edge.target) else {
                    continue
                }

                let position = getEdgePosition(GetEdgePositionParams(
                    id: edge.id,
                    sourceNode: sourceNode,
                    sourceHandle: edge.sourceHandle,
                    targetNode: targetNode,
                    targetHandle: edge.targetHandle,
                    connectionMode: connectionMode.get(),
                    onError: onerror.get()))

                if let position {
                    layouted.append(EdgeLayouted(
                        edge: edge,
                        zIndex: getElevatedEdgeZIndex(GetEdgeZIndexParams(
                            sourceNode: sourceNode,
                            targetNode: targetNode,
                            selected: edge.selected ?? false,
                            zIndex: edge.zIndex ?? 0,
                            elevateOnSelect: false)),
                        position: position))
                }
            }

            return layouted
        }

        let currentConnection = self.currentConnection
        // the viewport only changes the connection while one is being made
        connection = Derived<ConnectionState>(
            [currentConnection],
            quiet: [viewport],
            isEqual: { _, next in !(next.inProgress && next.to != nil) }
        ) {
            let state = currentConnection.get()
            let current = viewport.get()

            guard state.inProgress, let to = state.to else {
                return state
            }

            var converted = state
            converted.to = pointToRendererPoint(to, transform: Transform(current.x, current.y, current.zoom))
            return converted
        }

        let defaultMarkerColor = self.defaultMarkerColor
        let flowId = self.flowId
        markers = Derived<[MarkerProps]>([edges, defaultMarkerColor, flowId]) {
            createMarkerIds(edges.get(), id: flowId.get(), defaultColor: defaultMarkerColor.get())
        }

        let initialNodesLength = nodes.get().count
        let initialEdgesLength = edges.get().count
        let nodesInitialized = self.nodesInitialized
        let edgesInitialized = self.edgesInitialized
        let viewportInitialized = self.viewportInitialized
        var isInitialized = false
        initialized = Derived<Bool>([nodesInitialized, edgesInitialized, viewportInitialized]) {
            // If it was already initialized, return true from then on
            if isInitialized { return isInitialized }

            // if it hasn't been initialised check if it's now
            if initialNodesLength == 0 {
                isInitialized = viewportInitialized.get()
            } else if initialEdgesLength == 0 {
                isInitialized = viewportInitialized.get() && nodesInitialized.get()
            } else {
                isInitialized = viewportInitialized.get() && nodesInitialized.get() && edgesInitialized.get()
            }

            return isInitialized
        }
    }

    // MARK: The delete key

    private func subscribeToDeleteKey() {
        deleteKeySubscription = deleteKeyPressed.subscribe { [weak self] pressed in
            guard let self, pressed else { return }

            let allNodes = self.nodes.get()
            let allEdges = self.edges.get()
            let selectedNodes = allNodes.filter { $0.selected == true }
            let selectedEdges = allEdges.filter { $0.selected == true }

            getElementsToRemove(
                nodesToRemove: selectedNodes.map { $0.id },
                edgesToRemove: selectedEdges.map { $0.id },
                nodes: allNodes,
                edges: allEdges,
                onBeforeDelete: self.onbeforedelete.get()
            ) { [weak self] matchingNodes, matchingEdges in
                guard let self else { return }

                if !matchingNodes.isEmpty || !matchingEdges.isEmpty {
                    let nodeIds = Set(matchingNodes.map { $0.id })
                    let edgeIds = Set(matchingEdges.map { $0.id })

                    self.nodes.update { nds in nds.filter { !nodeIds.contains($0.id) } }
                    self.edges.update { eds in eds.filter { !edgeIds.contains($0.id) } }

                    self.ondelete.get()?(matchingNodes, matchingEdges)
                }
            }
        }
    }

    // MARK: Actions

    public func setNodeTypes(_ nodeTypes: NodeTypes) {
        self.nodeTypes.set(BuiltInTypes.nodeTypes.merging(nodeTypes) { _, new in new })
    }

    public func setEdgeTypes(_ edgeTypes: EdgeTypes) {
        self.edgeTypes.set(BuiltInTypes.edgeTypes.merging(edgeTypes) { _, new in new })
    }

    public func syncNodeStores(_ userNodes: Writable<[Node]>) {
        Xyflow.syncNodeStores(nodes, userNodes)
    }

    public func syncEdgeStores(_ userEdges: Writable<[Edge]>) {
        Xyflow.syncEdgeStores(edges, userEdges)
    }

    public func syncViewport(_ userViewport: Writable<Viewport>?) {
        Xyflow.syncViewportStores(panZoom, viewport, userViewport)
    }

    public func addEdge(_ edgeParams: EdgeOrConnection) {
        edges.set(XYSystem.addEdge(edgeParams, edges.get()))
    }

    /// Moves the nodes that are dragged. The nodes of the user are changed in place.
    public func updateNodePositions(_ nodeDragItems: OrderedMap<String, NodeDragItem>, _ dragging: Bool = false) {
        let lookup = nodeLookup.get()

        for (id, dragItem) in nodeDragItems {
            guard let node = lookup.get(id)?.internals.userNode else {
                continue
            }

            node.position = dragItem.position
            node.dragging = dragging
        }

        nodes.update { $0 }
    }

    /// Measures nodes: what is found goes into the internals of the lookup and into the nodes of the user.
    public func updateNodeInternals(_ updates: OrderedMap<String, InternalNodeUpdate>) {
        let lookup = nodeLookup.get()
        let parents = parentLookup.get()
        let result = XYSystem.updateNodeInternals(
            updates,
            lookup,
            parents,
            domNode: domNode.get(),
            nodeOrigin: nodeOrigin.get())

        if !result.updatedInternals {
            return
        }

        updateAbsolutePositions(
            lookup, parents,
            options: UpdateNodesOptions(nodeOrigin: initialNodeOrigin, nodeExtent: initialNodeExtent))

        for change in result.changes {
            guard let node = lookup.get(change.id)?.internals.userNode else {
                continue
            }

            switch change {
            case .dimensions(let dimensionChange):
                var measured = node.measured ?? Measured()
                if let dimensions = dimensionChange.dimensions {
                    measured.width = dimensions.width
                    measured.height = dimensions.height
                }

                if dimensionChange.setAttributes?.isEnabled == true {
                    node.width = dimensionChange.dimensions?.width ?? node.width
                    node.height = dimensionChange.dimensions?.height ?? node.height
                }

                node.measured = measured
            case .position(let positionChange):
                node.position = positionChange.position ?? node.position
            }
        }

        nodes.update { $0 }

        if !nodesInitialized.get() {
            nodesInitialized.set(true)
        }
    }

    /// Fits the view to the nodes once they are measured. Everyone who asks while a fit is queued is
    /// told when it is done.
    public func fitView(_ options: FitViewOptions? = nil, completion: ((Bool) -> Void)? = nil) {
        // We either create a new resolver or reuse the existing one
        // Even if fitView is called multiple times in a row, we only end up with a single fit
        let resolver = fitViewResolver.get() ?? FitViewResolver()
        resolver.wait(completion)

        // We schedule a fitView by setting fitViewQueued and triggering a setNodes
        fitViewQueued.set(true)
        fitViewOptions.set(options)
        fitViewResolver.set(resolver)
        nodes.set(nodes.get())
    }

    public func zoomBy(_ factor: Double, _ options: ViewportHelperFunctionOptions? = nil, completion: ((Bool) -> Void)? = nil) {
        guard let panZoomInstance = panZoom.get() else {
            completion?(false)
            return
        }

        panZoomInstance.scaleBy(factor, options: PanZoomTransformOptions(duration: options?.duration), completion: completion)
    }

    public func zoomIn(_ options: ViewportHelperFunctionOptions? = nil, completion: ((Bool) -> Void)? = nil) {
        zoomBy(1.2, options, completion: completion)
    }

    public func zoomOut(_ options: ViewportHelperFunctionOptions? = nil, completion: ((Bool) -> Void)? = nil) {
        zoomBy(1 / 1.2, options, completion: completion)
    }

    public func setMinZoom(_ minimum: Double) {
        guard let panZoomInstance = panZoom.get() else { return }

        panZoomInstance.setScaleExtent((minimum, maxZoom.get()))
        minZoom.set(minimum)
    }

    public func setMaxZoom(_ maximum: Double) {
        guard let panZoomInstance = panZoom.get() else { return }

        panZoomInstance.setScaleExtent((minZoom.get(), maximum))
        maxZoom.set(maximum)
    }

    public func setTranslateExtent(_ extent: CoordinateExtent) {
        guard let panZoomInstance = panZoom.get() else { return }

        panZoomInstance.setTranslateExtent(extent)
        translateExtent.set(extent)
    }

    private func resetSelectedElements(_ elements: [Node]) -> Bool {
        var elementsChanged = false
        for element in elements where element.selected == true {
            element.selected = false
            elementsChanged = true
        }
        return elementsChanged
    }

    private func resetSelectedElements(_ elements: [Edge]) -> Bool {
        var elementsChanged = false
        for element in elements where element.selected == true {
            element.selected = false
            elementsChanged = true
        }
        return elementsChanged
    }

    public func setPaneClickDistance(_ distance: Double) {
        panZoom.get()?.setClickDistance(distance)
    }

    public func unselectNodesAndEdges(nodes unselectNodes: [Node]? = nil, edges unselectEdges: [Edge]? = nil) {
        let resetNodes = resetSelectedElements(unselectNodes ?? nodes.get())
        if resetNodes { nodes.set(nodes.get()) }

        let resetEdges = resetSelectedElements(unselectEdges ?? edges.get())
        if resetEdges { edges.set(edges.get()) }
    }

    public func addSelectedNodes(_ ids: [String]) {
        let isMultiSelection = multiselectionKeyPressed.get()
        let selectedIds = Set(ids)

        nodes.update { ns in
            ns.map { node in
                let nodeWillBeSelected = selectedIds.contains(node.id)
                let selected = isMultiSelection
                    ? (node.selected == true || nodeWillBeSelected)
                    : nodeWillBeSelected

                // we need to mutate the node here in order to have the correct selected state in the drag handler
                node.selected = selected

                return node
            }
        }

        if !isMultiSelection {
            edges.update { es in
                es.map { edge in
                    edge.selected = false
                    return edge
                }
            }
        }
    }

    public func addSelectedEdges(_ ids: [String]) {
        let isMultiSelection = multiselectionKeyPressed.get()
        let selectedIds = Set(ids)

        edges.update { eds in
            eds.map { edge in
                let edgeWillBeSelected = selectedIds.contains(edge.id)
                let selected = isMultiSelection
                    ? (edge.selected == true || edgeWillBeSelected)
                    : edgeWillBeSelected

                edge.selected = selected

                return edge
            }
        }

        if !isMultiSelection {
            nodes.update { ns in
                ns.map { node in
                    node.selected = false
                    return node
                }
            }
        }
    }

    public func handleNodeSelection(_ id: String) {
        guard let node = nodes.get().first(where: { $0.id == id }) else {
            devWarn("012", ErrorMessages.error012(id))
            return
        }

        selectionRect.set(nil)
        selectionRectMode.set(nil)

        if node.selected != true {
            addSelectedNodes([id])
        } else if node.selected == true && multiselectionKeyPressed.get() {
            unselectNodesAndEdges(nodes: [node], edges: [])
        }
    }

    public func panBy(_ delta: XYPosition, completion: ((Bool) -> Void)? = nil) {
        let current = viewport.get()

        XYSystem.panBy(
            delta: delta,
            panZoom: panZoom.get(),
            transform: Transform(current.x, current.y, current.zoom),
            translateExtent: translateExtent.get(),
            width: width.get(),
            height: height.get(),
            completion: completion)
    }

    public func updateConnection(_ newConnection: ConnectionState) {
        currentConnection.set(newConnection)
    }

    public func cancelConnection() {
        currentConnection.set(initialConnection)
    }

    public func reset() {
        selectionRect.set(nil)
        selectionRectMode.set(nil)
        snapGrid.set(nil)
        isValidConnection.set({ _ in true })

        unselectNodesAndEdges()
        cancelConnection()
    }
}
#endif
