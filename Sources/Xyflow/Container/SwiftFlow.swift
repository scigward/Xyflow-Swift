#if canImport(UIKit)
import UIKit
import XYSystem

/// Stands in for the flow in the controllers that keep it (the store holds them, and the flow holds the
/// store), so that they do not keep the view alive.
final class WeakDomNode: FlowDomNode {
    private weak var flow: SwiftFlow?

    init(_ flow: SwiftFlow) {
        self.flow = flow
    }

    var boundingClientRect: Rect {
        flow?.boundingClientRect ?? Rect(x: 0, y: 0, width: 0, height: 0)
    }

    var viewportScale: Double? {
        flow?.viewportScale
    }

    func isWrapped(_ target: AnyObject?, withClass className: String) -> Bool {
        flow?.isWrapped(target, withClass: className) ?? false
    }

    func target(atX x: Double, y: Double) -> AnyObject? {
        flow?.target(atX: x, y: y)
    }

    func matches(_ target: AnyObject?, selector: String) -> Bool {
        flow?.matches(target, selector: selector) ?? false
    }

    func parent(of target: AnyObject) -> AnyObject? {
        (target as? UIView)?.superview
    }

    /// The view of the node with the id, when the node is on screen.
    func nodeWrapper(for id: String) -> NodeWrapperView? {
        flow?.nodeRenderer.wrapper(for: id)
    }
}

/// `SvelteFlow.svelte`: a flow of nodes and edges, in a view. The nodes and edges are the ones of the
/// `nodes` and `edges` stores, or the ones the flow is given, and every setting of the component is a
/// property.
///
///     let flow = SwiftFlow(nodes: [...], edges: [...])
///     flow.nodeTypes = ["custom": { CustomNodeView() }]
///     flow.add(BackgroundView())
///     flow.add(ControlsView())
public final class SwiftFlow: UIView, FlowDomNode, FlowDocument, UIGestureRecognizerDelegate {
    /// The state of the flow, which `FlowInstance` and the plugins read.
    public let store: SwiftFlowStore

    /// The functions that read and change the flow (`useSvelteFlow`).
    public lazy var instance = FlowInstance(store: store)

    /// The nodes of the flow, as the user holds them. Setting them changes the flow, and what changes
    /// the flow (dragging a node, deleting) is set on them.
    public let nodes: Writable<[Node]>
    public let edges: Writable<[Edge]>

    // MARK: Views

    let zoomView: ZoomView
    let paneView: PaneView
    let viewportView: FlowViewportView
    let edgeRenderer: EdgeRenderer
    let edgeLabelRenderer: FlowPassthroughView
    let viewportPortalView = FlowPassthroughView()
    let connectionLineView: ConnectionLineView
    let nodeRenderer: NodeRenderer
    let nodeSelectionView: NodeSelectionView
    let userSelectionView: UserSelectionView

    private var attributionView: AttributionView?
    private let keyHandler: KeyHandler
    private var router: FlowTouchRouter!
    private var pointerListeners: [(id: Int, move: (FlowPointerEvent) -> Void, up: (FlowPointerEvent) -> Void)] = []
    private var nextListenerId = 0
    private var lastScroll = CGPoint.zero
    private var lastPinchScale: CGFloat = 1
    private var onInitCalled = false
    private var initializedSubscription: Unsubscribe?
    private var observers: [NSObjectProtocol] = []

    // MARK: Settings

    /// The id of the flow, which the ids of its markers have in them.
    public var id: String = "1" {
        didSet { store.flowId.set(id) }
    }

    public var nodeTypes: NodeTypes? {
        didSet { if let nodeTypes { store.setNodeTypes(nodeTypes) } }
    }

    public var edgeTypes: EdgeTypes? {
        didSet { if let edgeTypes { store.setEdgeTypes(edgeTypes) } }
    }

    public var minZoom: Double? {
        didSet { if let minZoom { store.setMinZoom(minZoom) } }
    }

    public var maxZoom: Double? {
        didSet { if let maxZoom { store.setMaxZoom(maxZoom) } }
    }

    public var translateExtent: CoordinateExtent? {
        didSet { if let translateExtent { store.setTranslateExtent(translateExtent) } }
    }

    public var paneClickDistance: Double = 0 {
        didSet { zoomView.paneClickDistance = paneClickDistance }
    }

    public var nodeClickDistance: Double = 0 {
        didSet { nodeRenderer.nodeClickDistance = nodeClickDistance }
    }

    public var connectionLineType: ConnectionLineType? {
        didSet { if let connectionLineType { store.connectionLineType.set(connectionLineType) } }
    }

    public var connectionRadius: Double? {
        didSet { if let connectionRadius { store.connectionRadius.set(connectionRadius) } }
    }

    public var selectionMode: SelectionMode? {
        didSet { if let selectionMode { store.selectionMode.set(selectionMode) } }
    }

    public var snapGrid: SnapGrid? {
        didSet { if let snapGrid { store.snapGrid.set(snapGrid) } }
    }

    public var defaultMarkerColor: String = "#b1b1b7" {
        didSet { store.defaultMarkerColor.set(defaultMarkerColor) }
    }

    public var nodesDraggable: Bool? {
        didSet { if let nodesDraggable { store.nodesDraggable.set(nodesDraggable) } }
    }

    public var nodesConnectable: Bool? {
        didSet { if let nodesConnectable { store.nodesConnectable.set(nodesConnectable) } }
    }

    public var elementsSelectable: Bool? {
        didSet { if let elementsSelectable { store.elementsSelectable.set(elementsSelectable) } }
    }

    public var onlyRenderVisibleElements: Bool? {
        didSet { if let onlyRenderVisibleElements { store.onlyRenderVisibleElements.set(onlyRenderVisibleElements) } }
    }

    public var isValidConnection: IsValidConnection? {
        didSet { if let isValidConnection { store.isValidConnection.set(isValidConnection) } }
    }

    public var autoPanOnConnect: Bool = true {
        didSet { store.autoPanOnConnect.set(autoPanOnConnect) }
    }

    public var autoPanOnNodeDrag: Bool = true {
        didSet { store.autoPanOnNodeDrag.set(autoPanOnNodeDrag) }
    }

    public var connectionMode: ConnectionMode = .strict {
        didSet { store.connectionMode.set(connectionMode) }
    }

    public var nodeDragThreshold: Double? {
        didSet { if let nodeDragThreshold { store.nodeDragThreshold.set(nodeDragThreshold) } }
    }

    public var nodeOrigin: NodeOrigin? {
        didSet { if let nodeOrigin { store.nodeOrigin.set(nodeOrigin) } }
    }

    public var onerror: OnError? {
        didSet { if let onerror { store.onerror.set(onerror) } }
    }

    public var ondelete: OnDelete? {
        didSet { if let ondelete { store.ondelete.set(ondelete) } }
    }

    public var onedgecreate: OnEdgeCreate? {
        didSet { if let onedgecreate { store.onedgecreate.set(onedgecreate) } }
    }

    public var onconnect: OnConnect? {
        didSet { if let onconnect { store.onconnect.set(onconnect) } }
    }

    public var onconnectstart: OnConnectStart? {
        didSet { if let onconnectstart { store.onconnectstart.set(onconnectstart) } }
    }

    public var onconnectend: OnConnectEnd? {
        didSet { if let onconnectend { store.onconnectend.set(onconnectend) } }
    }

    public var onbeforedelete: OnBeforeDelete? {
        didSet { if let onbeforedelete { store.onbeforedelete.set(onbeforedelete) } }
    }

    public var defaultEdgeOptions: DefaultEdgeOptions? {
        didSet { if let defaultEdgeOptions { store.edges.setDefaultOptions(defaultEdgeOptions) } }
    }

    public var fitViewOptions: FitViewOptions? {
        didSet { if let fitViewOptions { store.fitViewOptions.set(fitViewOptions) } }
    }

    public var selectionKey: KeyDefinitions {
        get { keyHandler.selectionKey }
        set { keyHandler.selectionKey = newValue }
    }

    public var multiSelectionKey: KeyDefinitions {
        get { keyHandler.multiSelectionKey }
        set { keyHandler.multiSelectionKey = newValue }
    }

    public var deleteKey: KeyDefinitions {
        get { keyHandler.deleteKey }
        set { keyHandler.deleteKey = newValue }
    }

    public var panActivationKey: KeyDefinitions {
        get { keyHandler.panActivationKey }
        set { keyHandler.panActivationKey = newValue }
    }

    public var zoomActivationKey: KeyDefinitions {
        get { keyHandler.zoomActivationKey }
        set { keyHandler.zoomActivationKey = newValue }
    }

    public var panOnScrollMode: PanOnScrollMode = .free {
        didSet { zoomView.panOnScrollMode = panOnScrollMode }
    }

    public var preventScrolling: Bool = true {
        didSet { zoomView.preventScrolling = preventScrolling }
    }

    public var zoomOnScroll: Bool = true {
        didSet { zoomView.zoomOnScroll = zoomOnScroll }
    }

    public var zoomOnDoubleClick: Bool = true {
        didSet { zoomView.zoomOnDoubleClick = zoomOnDoubleClick }
    }

    public var zoomOnPinch: Bool = true {
        didSet { zoomView.zoomOnPinch = zoomOnPinch }
    }

    public var panOnScroll: Bool = false {
        didSet { zoomView.panOnScroll = panOnScroll }
    }

    public var panOnDrag: PanOnDrag = true {
        didSet {
            zoomView.panOnDrag = panOnDrag
            paneView.panOnDrag = panOnDrag
        }
    }

    public var selectionOnDrag: Bool? {
        didSet { paneView.selectionOnDrag = selectionOnDrag }
    }

    public var onMoveStart: OnPanZoom? {
        didSet { zoomView.onMoveStart = onMoveStart }
    }

    public var onMove: OnPanZoom? {
        didSet { zoomView.onMove = onMove }
    }

    public var onMoveEnd: OnPanZoom? {
        didSet { zoomView.onMoveEnd = onMoveEnd }
    }

    /// Called once, when the flow is initialized: its nodes are measured and it has a viewport.
    public var oninit: (() -> Void)? {
        didSet { callInitIfNeeded() }
    }

    public var connectionLineStyle: String = "" {
        didSet { connectionLineView.style = connectionLineStyle }
    }

    public var connectionLineContainerStyle: String = "" {
        didSet { connectionLineView.containerStyle = connectionLineContainerStyle }
    }

    /// A view that draws the line of a connection that is made, instead of the path of the flow.
    public var connectionLine: ConnectionLineComponentFactory? {
        didSet { connectionLineView.customComponent = connectionLine }
    }

    public var attributionPosition: PanelPosition? {
        didSet { updateAttribution() }
    }

    public var proOptions: ProOptions? {
        didSet { updateAttribution() }
    }

    // MARK: Events

    public var onNodeClick: ((NodeEvent) -> Void)?
    public var onNodeMouseEnter: ((NodeEvent) -> Void)?
    public var onNodeMouseMove: ((NodeEvent) -> Void)?
    public var onNodeMouseLeave: ((NodeEvent) -> Void)?
    public var onNodeContextMenu: ((NodeEvent) -> Void)?
    public var onNodeDragStart: ((NodeDragEvent) -> Void)?
    public var onNodeDrag: ((NodeDragEvent) -> Void)?
    public var onNodeDragStop: ((NodeDragEvent) -> Void)?
    public var onEdgeClick: ((EdgeEvent) -> Void)?
    public var onEdgeContextMenu: ((EdgeEvent) -> Void)?
    public var onEdgeMouseEnter: ((EdgeEvent) -> Void)?
    public var onEdgeMouseLeave: ((EdgeEvent) -> Void)?
    public var onSelectionClick: ((SelectionEvent) -> Void)?
    public var onSelectionContextMenu: ((SelectionEvent) -> Void)?
    public var onPaneClick: ((FlowPointerEvent) -> Void)?
    public var onPaneContextMenu: ((FlowPointerEvent) -> Void)?

    // MARK: Style

    /// The color mode of the flow. `system` follows the interface style of the screen.
    public var colorMode: ColorMode = .light {
        didSet { updateColorModeClass() }
    }

    /// `dark` or `light`, what the color mode comes to.
    public private(set) var colorModeClass: ColorModeClass = .light

    /// The style of the flow, as the `style` attribute of the component has it: custom properties like
    /// `--xy-background-color` and `--xy-edge-stroke`, and `background-color`.
    public var style: String? {
        didSet { invalidateTheme() }
    }

    /// Custom properties that `var(--name)` of the styles of the nodes and edges can refer to.
    public var styleVariables: [String: String] = [:] {
        didSet { invalidateTheme() }
    }

    /// The color text has where nothing else says, which is what nodes with the color `inherit` take.
    public var textColor: UIColor? {
        didSet { invalidateTheme() }
    }

    /// The font of the text the flow draws itself, such as the labels of edges: it is given a size and a weight.
    public var fontProvider: ((CGFloat, UIFont.Weight) -> UIFont)? {
        didSet {
            edgeRenderer.font = fontProvider ?? { UIFont.systemFont(ofSize: $0, weight: $1) }
            edgeRenderer.reconcile()
        }
    }

    private var cachedScope: FlowStyleScope?

    // MARK: Init

    /// Makes a flow. `nodes` and `edges` are the stores the flow keeps in sync with its own. A `store`
    /// that is given is the state the flow is made on, which is what the provider of the component is for.
    public init(
        nodes: Writable<[Node]> = Writable<[Node]>([]),
        edges: Writable<[Edge]> = Writable<[Edge]>([]),
        store providedStore: SwiftFlowStore? = nil,
        id: String = "1",
        viewport userViewport: Writable<Viewport>? = nil,
        initialViewport: Viewport? = nil,
        fitView: Bool? = nil,
        width: Double? = nil,
        height: Double? = nil,
        nodeOrigin: NodeOrigin? = nil,
        nodeExtent: CoordinateExtent? = nil
    ) {
        let store = providedStore ?? SwiftFlowStore(
            nodes: nodes.get(),
            edges: edges.get(),
            width: width,
            height: height,
            fitView: fitView,
            nodeOrigin: nodeOrigin,
            nodeExtent: nodeExtent)

        self.store = store
        self.nodes = nodes
        self.edges = edges
        self.id = id

        let labelRenderer = FlowPassthroughView()

        zoomView = ZoomView(store: store)
        paneView = PaneView(store: store)
        viewportView = FlowViewportView(store: store)
        edgeLabelRenderer = labelRenderer
        edgeRenderer = EdgeRenderer(store: store, labelHost: labelRenderer)
        connectionLineView = ConnectionLineView(store: store)
        nodeRenderer = NodeRenderer(store: store)
        keyHandler = KeyHandler(store: store)

        // the scope is made by the flow, which the views ask for it
        var scopeProvider: () -> FlowStyleScope = { FlowStyleScope(properties: FlowTheme.light) }
        nodeSelectionView = NodeSelectionView(store: store, styleScope: { scopeProvider() })
        userSelectionView = UserSelectionView(store: store, styleScope: { scopeProvider() })

        super.init(frame: .zero)

        scopeProvider = { [weak self] in self?.rootScope() ?? FlowStyleScope(properties: FlowTheme.light) }

        flowClasses = [FlowClass.flow]
        clipsToBounds = true
        backgroundColor = .white
        isMultipleTouchEnabled = true

        buildViewHierarchy()
        wireEvents()
        mount(userViewport: userViewport, initialViewport: initialViewport, fitView: fitView)
        installGestures()
        updateAttribution()
        updateColorModeClass()
        refreshBackground()
    }

    public convenience init(
        nodes initialNodes: [Node],
        edges initialEdges: [Edge] = [],
        store: SwiftFlowStore? = nil,
        id: String = "1",
        fitView: Bool? = nil
    ) {
        self.init(
            nodes: Writable<[Node]>(initialNodes),
            edges: Writable<[Edge]>(initialEdges),
            store: store,
            id: id,
            fitView: fitView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        initializedSubscription?()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        store.reset()
    }

    private func buildViewHierarchy() {
        // the content of the viewport, from the back to the front
        viewportView.addSubview(edgeRenderer)
        viewportView.addSubview(edgeLabelRenderer)
        viewportView.addSubview(viewportPortalView)
        viewportView.addSubview(nodeRenderer)
        viewportView.addSubview(nodeSelectionView)
        viewportView.addSubview(connectionLineView)

        edgeLabelRenderer.flowClasses = ["svelte-flow__edgelabel-renderer"]
        viewportPortalView.flowClasses = ["svelte-flow__viewport-portal"]

        paneView.addSubview(viewportView)
        paneView.addSubview(userSelectionView)
        zoomView.addSubview(paneView)
        addSubview(zoomView)
    }

    private func wireEvents() {
        nodeRenderer.styleScope = { [weak self] in self?.rootScope() ?? FlowStyleScope(properties: FlowTheme.light) }
        nodeRenderer.onNodeClick = { [weak self] in self?.onNodeClick?($0) }
        nodeRenderer.onNodeMouseEnter = { [weak self] in self?.onNodeMouseEnter?($0) }
        nodeRenderer.onNodeMouseLeave = { [weak self] in self?.onNodeMouseLeave?($0) }
        nodeRenderer.onNodeMouseMove = { [weak self] in self?.onNodeMouseMove?($0) }
        nodeRenderer.onNodeContextMenu = { [weak self] in self?.onNodeContextMenu?($0) }
        nodeRenderer.onNodeDragStart = { [weak self] in self?.onNodeDragStart?($0) }
        nodeRenderer.onNodeDrag = { [weak self] in self?.onNodeDrag?($0) }
        nodeRenderer.onNodeDragStop = { [weak self] in self?.onNodeDragStop?($0) }

        nodeSelectionView.onNodeDragStart = { [weak self] in self?.onNodeDragStart?($0) }
        nodeSelectionView.onNodeDrag = { [weak self] in self?.onNodeDrag?($0) }
        nodeSelectionView.onNodeDragStop = { [weak self] in self?.onNodeDragStop?($0) }
        nodeSelectionView.onSelectionClick = { [weak self] in self?.onSelectionClick?($0) }
        nodeSelectionView.onSelectionContextMenu = { [weak self] in self?.onSelectionContextMenu?($0) }

        edgeRenderer.styleScope = { [weak self] in self?.rootScope() ?? FlowStyleScope(properties: FlowTheme.light) }
        edgeRenderer.colorModeClass = { [weak self] in self?.colorModeClass ?? .light }
        edgeRenderer.onEdgeClick = { [weak self] in self?.onEdgeClick?($0) }
        edgeRenderer.onEdgeContextMenu = { [weak self] in self?.onEdgeContextMenu?($0) }
        edgeRenderer.onEdgeMouseEnter = { [weak self] in self?.onEdgeMouseEnter?($0) }
        edgeRenderer.onEdgeMouseLeave = { [weak self] in self?.onEdgeMouseLeave?($0) }

        connectionLineView.styleScope = { [weak self] in self?.rootScope() ?? FlowStyleScope(properties: FlowTheme.light) }

        paneView.onPaneClick = { [weak self] in self?.onPaneClick?($0) }
        paneView.onPaneContextMenu = { [weak self] in self?.onPaneContextMenu?($0) }
    }

    /// `onMount`: the flow takes the measures of its view, and keeps the stores of the user in sync.
    private func mount(userViewport: Writable<Viewport>?, initialViewport: Viewport?, fitView: Bool?) {
        store.domNode.set(WeakDomNode(self))
        store.flowId.set(id)
        store.width.set(Double(bounds.width))
        store.height.set(Double(bounds.height))

        // `$viewport || initialViewport`
        zoomView.setUp(domNode: WeakDomNode(self), initialViewport: userViewport?.get() ?? initialViewport)

        store.syncNodeStores(nodes)
        store.syncEdgeStores(edges)
        store.syncViewport(userViewport)

        if let fitView {
            store.fitViewQueued.set(fitView)
        }

        initializedSubscription = store.initialized.subscribeAny { [weak self] in
            self?.callInitIfNeeded()
        }

        observers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            // the window lost the focus: no key is held any more
            self?.keyHandler.resetKeysAndSelection()
        })
    }

    /// `oninit` is called once, when the flow is initialized, which is also when it is set if that is later.
    private func callInitIfNeeded() {
        guard !onInitCalled, store.initialized.get(), let oninit else { return }
        onInitCalled = true
        oninit()
    }

    // MARK: Plugins

    /// The layer of the flow whose views are in the coordinates of the flow, so they move and scale with
    /// the viewport (`ViewportPortal`).
    public var viewportPortal: UIView {
        viewportPortalView
    }

    /// Adds a view to the flow, such as `BackgroundView`, `ControlsView`, `MiniMapView`, or the panels
    /// of your own.
    public func add(_ plugin: FlowPluginView) {
        plugin.flow = self

        if plugin.isBackdrop {
            insertSubview(plugin, at: 0)
        } else {
            addSubview(plugin)
        }

        plugin.attach(to: self)
        setNeedsLayout()
    }

    private func updateAttribution() {
        if proOptions?.hideAttribution == true {
            attributionView?.removeFromSuperview()
            attributionView = nil
            return
        }

        if let attributionView {
            attributionView.position = attributionPosition ?? .bottomRight
            return
        }

        let view = AttributionView(position: attributionPosition ?? .bottomRight)
        attributionView = view
        add(view)
    }

    // MARK: Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        let size = bounds.size

        zoomView.frame = bounds
        paneView.frame = zoomView.bounds
        viewportView.setContainerSize(size)

        let content = CGRect(origin: .zero, size: size)
        edgeRenderer.frame = content
        edgeLabelRenderer.frame = content
        viewportPortalView.frame = content
        nodeRenderer.frame = content
        connectionLineView.frame = content

        // `bind:clientWidth` and `bind:clientHeight`
        if store.width.get() != Double(size.width) {
            store.width.set(Double(size.width))
        }
        if store.height.get() != Double(size.height) {
            store.height.set(Double(size.height))
        }

        for subview in subviews {
            if let panel = subview as? FlowPanelView {
                panel.place(in: bounds)
            } else if let plugin = subview as? FlowPluginView, plugin.isBackdrop {
                plugin.frame = bounds
            }
        }
    }

    // MARK: Style

    private func updateColorModeClass() {
        let next: ColorModeClass
        switch colorMode {
        case .light:
            next = .light
        case .dark:
            next = .dark
        case .system:
            next = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        }

        if next != colorModeClass {
            colorModeClass = next
            invalidateTheme()
        } else {
            cachedScope = nil
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if colorMode == .system {
            updateColorModeClass()
        } else if textColor == nil {
            invalidateTheme()
        }
    }

    /// The custom properties of the flow: the style sheet of its color mode, then the ones set on it.
    /// Nodes, edges and plugins start their own styles from them.
    public func rootScope() -> FlowStyleScope {
        if let cachedScope {
            return cachedScope
        }

        var properties = FlowTheme.variables(for: colorModeClass)
        properties["--background-color-default"] = "#fff"

        let inherited = (textColor ?? UIColor.label).resolvedColor(with: traitCollection)
        properties["color"] = FlowColor(inherited).cssHex

        for (name, value) in styleVariables {
            properties[name] = value
        }

        for declaration in FlowCSS.parseDeclarations(style) {
            properties[declaration.name] = declaration.value
        }

        let scope = FlowStyleScope(properties: properties)
        cachedScope = scope
        return scope
    }

    /// The style of the flow changed: everything that is drawn with it is drawn again.
    private func invalidateTheme() {
        cachedScope = nil

        refreshBackground()
        nodeRenderer.reconcile()
        edgeRenderer.reconcile()
        userSelectionView.update()
        nodeSelectionView.update()

        for subview in subviews {
            (subview as? FlowPluginView)?.themeDidChange()
        }
    }

    /// `.svelte-flow { background-color: var(--background-color, var(--background-color-default)) }`
    private func refreshBackground() {
        let scope = rootScope()
        let inline = FlowCSS.declarationMap(style)

        var color = scope.color(["--background-color", "--background-color-default"])
        if let declared = scope.resolvedColor(inline["background-color"] ?? inline["background"]) {
            color = declared
        }

        backgroundColor = color?.uiColor ?? .white
    }

    // MARK: FlowDomNode

    public var boundingClientRect: Rect {
        clientRect
    }

    public var viewportScale: Double? {
        viewportView.zoom
    }

    public func isWrapped(_ target: AnyObject?, withClass className: String) -> Bool {
        (target as? UIView)?.flowClosest(withClass: className) != nil
    }

    public func target(atX x: Double, y: Double) -> AnyObject? {
        hitTest(convert(CGPoint(x: x, y: y), from: nil), with: nil)
    }

    // MARK: FlowDocument

    public func handleElement(atX x: Double, y: Double) -> HandleElement? {
        var view = target(atX: x, y: y) as? UIView

        while let current = view {
            if let handle = current as? HandleView {
                return handle
            }
            view = current.superview
        }

        return nil
    }

    public func handleElement(flowId: String?, nodeId: String, handleId: String?, type: HandleType) -> HandleElement? {
        nodeRenderer.wrapper(for: nodeId)?
            .handleElements(of: type)
            .first { $0.handleId == handleId }
    }

    public func addPointerListeners(
        move: @escaping (FlowPointerEvent) -> Void,
        up: @escaping (FlowPointerEvent) -> Void
    ) -> () -> Void {
        let listenerId = nextListenerId
        nextListenerId += 1
        pointerListeners.append((listenerId, move, up))

        return { [weak self] in
            self?.pointerListeners.removeAll { $0.id == listenerId }
        }
    }

    func dispatchPointerMove(_ event: FlowPointerEvent) {
        for listener in pointerListeners {
            listener.move(event)
        }
    }

    func dispatchPointerUp(_ event: FlowPointerEvent) {
        for listener in pointerListeners {
            listener.up(event)
        }
    }

    var hasPointerListeners: Bool {
        !pointerListeners.isEmpty
    }

    // MARK: Clicks

    /// A click on the view the event started on: the closest view that takes clicks has it.
    func dispatchClick(_ event: FlowPointerEvent) {
        var view = event.target as? UIView

        while let current = view {
            if let clickable = current as? FlowClickable {
                clickable.flowClick(event: event)
                return
            }
            view = current.superview
        }
    }

    func dispatchContextMenu(_ event: FlowPointerEvent) {
        var view = event.target as? UIView

        while let current = view {
            if let handler = current as? FlowContextMenuHandling {
                handler.flowContextMenu(event: event)
                return
            }
            view = current.superview
        }
    }

    /// Where the event is, in the coordinates of the surface that pans and zooms.
    func zoomPoint(for event: FlowPointerEvent) -> XYPosition {
        zoomView.convert(CGPoint(x: event.clientX, y: event.clientY), from: nil).xyPosition
    }

    // MARK: Gestures

    private func installGestures() {
        router = FlowTouchRouter(flow: self)
        addGestureRecognizer(router)

        let scroll = UIPanGestureRecognizer(target: self, action: #selector(handleScroll(_:)))
        scroll.allowedScrollTypesMask = [.continuous, .discrete]
        scroll.allowedTouchTypes = []
        scroll.delegate = self
        addGestureRecognizer(scroll)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        addGestureRecognizer(pinch)

        let hover = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
        addGestureRecognizer(hover)
    }

    private func eventModifiers(of recognizer: UIGestureRecognizer) -> EventModifiers {
        var modifiers: EventModifiers = []
        let flags = recognizer.modifierFlags
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.alternate) { modifiers.insert(.alt) }
        if flags.contains(.command) { modifiers.insert(.meta) }
        return modifiers
    }

    private func wheelEvent(
        for recognizer: UIGestureRecognizer,
        deltaX: Double,
        deltaY: Double,
        extraModifiers: EventModifiers = []
    ) -> ZoomSourceEvent {
        let location = recognizer.location(in: nil)
        let modifiers = eventModifiers(of: recognizer).union(extraModifiers)

        return ZoomSourceEvent(
            type: "wheel",
            ctrlKey: modifiers.contains(.control),
            shiftKey: modifiers.contains(.shift),
            altKey: modifiers.contains(.alt),
            metaKey: modifiers.contains(.meta),
            clientX: Double(location.x),
            clientY: Double(location.y),
            point: zoomView.convert(location, from: nil).xyPosition,
            deltaX: deltaX,
            deltaY: deltaY,
            deltaMode: 0,
            target: hitTest(convert(location, from: nil), with: nil))
    }

    /// The scrolling of a mouse wheel or a trackpad is the wheel of the interface.
    @objc private func handleScroll(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            lastScroll = .zero
        case .changed:
            let translation = recognizer.translation(in: self)
            let deltaX = Double(translation.x - lastScroll.x)
            let deltaY = Double(translation.y - lastScroll.y)
            lastScroll = translation

            // the content moves with the fingers, which scrolls the other way
            zoomView.zoomBehavior?.handleWheel(wheelEvent(for: recognizer, deltaX: -deltaX, deltaY: -deltaY))
        default:
            break
        }
    }

    /// A pinch on a trackpad is a wheel with the control key down, which is what the browsers make of it.
    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            lastPinchScale = 1
        case .changed:
            let factor = recognizer.scale / lastPinchScale
            lastPinchScale = recognizer.scale

            guard factor > 0 else { return }

            // wheelDelta is -deltaY * 0.002 * 10 for a wheel with the control key down
            let deltaY = -log2(Double(factor)) / 0.02
            zoomView.zoomBehavior?.handleWheel(wheelEvent(for: recognizer, deltaX: 0, deltaY: deltaY, extraModifiers: [.control]))
        default:
            break
        }
    }

    @objc private func handleHover(_ recognizer: UIHoverGestureRecognizer) {
        let location = recognizer.location(in: nil)
        let event = FlowPointerEvent(
            kind: .mouse,
            clientX: Double(location.x),
            clientY: Double(location.y),
            modifiers: eventModifiers(of: recognizer),
            buttons: 0,
            target: hitTest(convert(location, from: nil), with: nil))

        if recognizer.state == .began {
            takeKeyboardFocus()
        }

        edgeRenderer.flowHover(event: event, phase: recognizer.state)
    }

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pinch = gestureRecognizer as? UIPinchGestureRecognizer {
            // a pinch of fingers is the business of the touches, only the one of a trackpad is a wheel
            return pinch.numberOfTouches == 0 && zoomView.wouldHandleWheel(at: pinch.location(in: nil), ctrlKey: true, in: self)
        }

        if gestureRecognizer is UIPanGestureRecognizer {
            return zoomView.wouldHandleWheel(
                at: gestureRecognizer.location(in: nil),
                ctrlKey: eventModifiers(of: gestureRecognizer).contains(.control),
                in: self)
        }

        return true
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // the scroll and the pinch of a trackpad, and the hover, go together
        true
    }

    // MARK: Keyboard

    public override var canBecomeFirstResponder: Bool {
        true
    }

    /// No key is held any more, which is what a context menu does to them.
    func resetKeys() {
        keyHandler.resetKeysAndSelection()
    }

    /// Hardware keyboards talk to the flow once it has the focus, unless a text input has it.
    func takeKeyboardFocus() {
        guard !isFirstResponder, window != nil else { return }

        if let current = window?.flowFirstResponder(), current is FlowTextInput {
            return
        }

        becomeFirstResponder()
    }

    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false

        for press in presses {
            if let key = press.key, let keyEvent = FlowKeyEvent(key: key, target: self) {
                keyHandler.keyDown(keyEvent)
                handled = true
            }
        }

        if !handled {
            super.pressesBegan(presses, with: event)
        }
    }

    public override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false

        for press in presses {
            if let key = press.key, let keyEvent = FlowKeyEvent(key: key, target: self) {
                keyHandler.keyUp(keyEvent)
                handled = true
            }
        }

        if !handled {
            super.pressesEnded(presses, with: event)
        }
    }

    public override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        keyHandler.resetKeysAndSelection()
        super.pressesCancelled(presses, with: event)
    }

    public override func resignFirstResponder() -> Bool {
        keyHandler.resetKeysAndSelection()
        return super.resignFirstResponder()
    }
}

extension UIWindow {
    /// The view that has the keyboard focus in the window, if there is one.
    func flowFirstResponder() -> UIResponder? {
        func search(_ view: UIView) -> UIResponder? {
            if view.isFirstResponder { return view }

            for subview in view.subviews {
                if let found = search(subview) { return found }
            }

            return nil
        }

        return search(self)
    }
}
#endif
