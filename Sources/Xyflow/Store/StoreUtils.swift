#if canImport(UIKit)
import Foundation
import XYSystem

/// What `fitView` hands back: everyone who asked for a fit while one was queued is told when it is done.
public final class FitViewResolver {
    private var completions: [(Bool) -> Void] = []

    public init() {}

    public func wait(_ completion: ((Bool) -> Void)?) {
        if let completion {
            completions.append(completion)
        }
    }

    public func resolve(_ value: Bool) {
        let pending = completions
        completions = []
        pending.forEach { $0(value) }
    }
}

/// The store of the nodes the flow works with. Setting it adopts the nodes into the lookups, which is
/// what turns them into internal nodes with absolute positions and a z index, and it runs the fit
/// view that was queued as soon as all nodes are measured.
public final class NodesStore: Writable<[Node]> {
    private let nodeLookup: NodeLookup
    private let parentLookup: ParentLookup
    private let nodeOrigin: NodeOrigin
    private let nodeExtent: CoordinateExtent
    private let fitViewQueued: Writable<Bool>
    private let fitViewOptions: Writable<FitViewOptions?>
    private let fitViewResolver: Writable<FitViewResolver?>
    private let panZoom: Writable<PanZoomInstance?>
    private let width: Writable<Double>
    private let height: Writable<Double>
    private let minZoom: Writable<Double>
    private let maxZoom: Writable<Double>

    public private(set) var defaults = NodeDefaults()
    private var elevateNodesOnSelect = true

    init(
        nodes: [Node],
        nodeLookup: NodeLookup,
        parentLookup: ParentLookup,
        nodeOrigin: NodeOrigin,
        nodeExtent: CoordinateExtent,
        fitViewQueued: Writable<Bool>,
        fitViewOptions: Writable<FitViewOptions?>,
        fitViewResolver: Writable<FitViewResolver?>,
        panZoom: Writable<PanZoomInstance?>,
        width: Writable<Double>,
        height: Writable<Double>,
        minZoom: Writable<Double>,
        maxZoom: Writable<Double>
    ) {
        self.nodeLookup = nodeLookup
        self.parentLookup = parentLookup
        self.nodeOrigin = nodeOrigin
        self.nodeExtent = nodeExtent
        self.fitViewQueued = fitViewQueued
        self.fitViewOptions = fitViewOptions
        self.fitViewResolver = fitViewResolver
        self.panZoom = panZoom
        self.width = width
        self.height = height
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        super.init([])
        rawSet(nodes)
    }

    public override func rawSet(_ nds: [Node]) {
        let nodesInitialized = adoptUserNodes(
            nds,
            nodeLookup,
            parentLookup,
            options: UpdateNodesOptions(
                nodeOrigin: nodeOrigin,
                nodeExtent: nodeExtent,
                elevateNodesOnSelect: elevateNodesOnSelect,
                defaults: defaults,
                checkEquality: false))

        if fitViewQueued.get(), nodesInitialized, let panZoomInstance = panZoom.get() {
            let options = fitViewOptions.get()

            fitViewQueued.set(false)
            fitViewOptions.set(nil)

            fitViewport(
                FitViewParams(
                    nodes: nodeLookup,
                    width: width.get(),
                    height: height.get(),
                    panZoom: panZoomInstance,
                    minZoom: minZoom.get(),
                    maxZoom: maxZoom.get()),
                options: options
            ) { [weak self] value in
                let resolver = self?.fitViewResolver.get()
                self?.fitViewResolver.set(nil)
                resolver?.resolve(value)
            }
        }

        super.rawSet(nds)
    }

    /// `setDefaultOptions`: what every node gets that does not set it itself.
    public func setDefaultOptions(_ options: NodeDefaults) {
        defaults = options
    }

    public func setOptions(elevateNodesOnSelect: Bool?) {
        self.elevateNodesOnSelect = elevateNodesOnSelect ?? self.elevateNodesOnSelect
    }
}

/// `{ ...defaults, ...edge }`: a copy of the edge that has the defaults for what the edge does not set.
func applyDefaults(_ defaults: DefaultEdgeOptions, to edge: Edge) -> Edge {
    let copy = edge.copy()

    if copy.type == nil { copy.type = defaults.type }
    if copy.animated == nil { copy.animated = defaults.animated }
    if copy.hidden == nil { copy.hidden = defaults.hidden }
    if copy.deletable == nil { copy.deletable = defaults.deletable }
    if copy.selectable == nil { copy.selectable = defaults.selectable }
    if copy.data == nil { copy.data = defaults.data }
    if copy.markerStart == nil { copy.markerStart = defaults.markerStart }
    if copy.markerEnd == nil { copy.markerEnd = defaults.markerEnd }
    if copy.zIndex == nil { copy.zIndex = defaults.zIndex }
    if copy.ariaLabel == nil { copy.ariaLabel = defaults.ariaLabel }
    if copy.interactionWidth == nil { copy.interactionWidth = defaults.interactionWidth }
    if copy.label == nil { copy.label = defaults.label }
    if copy.labelStyle == nil { copy.labelStyle = defaults.labelStyle }
    if copy.style == nil { copy.style = defaults.style }
    if copy.className == nil { copy.className = defaults.className }
    if copy.pathOptions == nil { copy.pathOptions = defaults.pathOptions }

    return copy
}

/// The store of the edges. Setting it gives every edge the default options and updates the lookups
/// that tell what is connected to what.
public final class EdgesStore: Writable<[Edge]> {
    private let connectionLookup: ConnectionLookup
    private let edgeLookup: EdgeLookup
    private var defaults: DefaultEdgeOptions

    init(
        edges: [Edge],
        connectionLookup: ConnectionLookup,
        edgeLookup: EdgeLookup,
        defaultOptions: DefaultEdgeOptions? = nil
    ) {
        self.connectionLookup = connectionLookup
        self.edgeLookup = edgeLookup
        self.defaults = defaultOptions ?? DefaultEdgeOptions()
        super.init([])
        rawSet(edges)
    }

    public override func rawSet(_ eds: [Edge]) {
        let nextEdges = eds.map { applyDefaults(defaults, to: $0) }

        updateConnectionLookup(connectionLookup, edgeLookup, nextEdges)

        super.rawSet(nextEdges)
    }

    public func setDefaultOptions(_ options: DefaultEdgeOptions) {
        defaults = options
    }
}

/// We need to sync the user nodes and the internal nodes so that the user can receive the updates
/// made by the flow (like dragging or selecting a node).
public func syncNodeStores(_ nodesStore: NodesStore, _ userNodesStore: Writable<[Node]>) {
    let currentNodesStore = nodesStore.get()
    let currentUserNodesStore = userNodesStore.get()
    // depending how the user initializes the nodes, we need to decide if we want to use the user nodes
    // or the internal nodes for initialization. A flow can be used with a store that was created
    // without any nodes, in that case we want to use the nodes passed by the user. By default we are
    // using the store nodes, because they already have the absolute positions.
    let initWithUserNodes = currentNodesStore.isEmpty && !currentUserNodesStore.isEmpty

    var value = initWithUserNodes ? currentUserNodesStore : currentNodesStore
    nodesStore.set(value)

    let combined: ([Node]) -> Void = { [weak nodesStore, weak userNodesStore] nds in
        nodesStore?.rawSet(nds)
        value = nds
        userNodesStore?.rawSet(value)
    }

    nodesStore.setOverride = combined
    userNodesStore.setOverride = combined
}

/// same for edges
public func syncEdgeStores(_ edgesStore: EdgesStore, _ userEdgesStore: Writable<[Edge]>) {
    var value = userEdgesStore.get()
    edgesStore.set(value)

    let combined: ([Edge]) -> Void = { [weak edgesStore, weak userEdgesStore] eds in
        edgesStore?.rawSet(eds)
        userEdgesStore?.rawSet(eds)
        value = eds
    }

    edgesStore.setOverride = combined
    userEdgesStore.setOverride = combined
}

/// It is possible to pass a viewport store to the flow for having more control. If that's the case we
/// need to sync the internal viewport with the user viewport.
public func syncViewportStores(
    _ panZoomStore: Writable<PanZoomInstance?>,
    _ viewportStore: Writable<Viewport>,
    _ userViewportStore: Writable<Viewport>?
) {
    guard let userViewportStore else {
        return
    }

    let panZoom = panZoomStore.get()

    viewportStore.set(userViewportStore.get())

    viewportStore.setOverride = { [weak viewportStore, weak userViewportStore] viewport in
        viewportStore?.rawSet(viewport)
        userViewportStore?.rawSet(viewport)
    }

    userViewportStore.setOverride = { [weak viewportStore, weak userViewportStore] viewport in
        panZoom?.syncViewport(viewport)

        viewportStore?.rawSet(viewport)
        userViewportStore?.rawSet(viewport)
    }
}
#endif
