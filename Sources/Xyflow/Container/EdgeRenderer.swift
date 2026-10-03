#if canImport(UIKit)
import UIKit
import XYSystem

/// What an edge is drawn from. When none of it changed since the last time, the edge is not drawn again.
private struct EdgeSignature: Equatable {
    var dataRevision: Int
    var type: String?
    var source: String
    var target: String
    var sourceHandle: String?
    var targetHandle: String?
    var hidden: Bool
    var animated: Bool
    var selected: Bool
    var selectable: Bool
    var deletable: Bool
    var markerStart: EdgeMarkerType?
    var markerEnd: EdgeMarkerType?
    var interactionWidth: Double?
    var label: String?
    var labelStyle: String?
    var style: String?
    var pathOptions: EdgePathOptions?
    var className: String?
    var zIndex: Double?
    var position: EdgePosition
    /// Changes when something the edges are drawn with does: the style of the flow, the markers, the font.
    var context: Int
}

/// `EdgeWrapper.svelte`: one edge of the flow, drawn by the component of its type.
final class EdgeWrapper {
    let id: String
    /// The layer in the edge layer of the flow that the edge draws in.
    let layer = CALayer()

    private(set) var edge: Edge
    private(set) var component: FlowEdgeComponent?
    private var componentType: String?
    private(set) var isHidden = false
    private var lastSignature: EdgeSignature?

    init(edge: Edge) {
        self.id = edge.id
        self.edge = edge
    }

    var labelViews: [UIView] {
        component?.labelViews ?? []
    }

    func apply(_ layouted: EdgeLayouted, store: SwiftFlowStore, context: EdgeRenderContext, contextVersion: Int) {
        let edge = layouted.edge
        let replaced = edge !== self.edge
        self.edge = edge

        let signature = EdgeSignature(
            dataRevision: edge.dataRevision,
            type: edge.type,
            source: edge.source,
            target: edge.target,
            sourceHandle: edge.sourceHandle,
            targetHandle: edge.targetHandle,
            hidden: edge.hidden == true,
            animated: edge.animated ?? false,
            selected: edge.selected ?? false,
            selectable: edge.selectable ?? store.elementsSelectable.get(),
            deletable: edge.deletable ?? true,
            markerStart: edge.markerStart,
            markerEnd: edge.markerEnd,
            interactionWidth: edge.interactionWidth,
            label: edge.label,
            labelStyle: edge.labelStyle,
            style: edge.style,
            pathOptions: edge.pathOptions,
            className: edge.className,
            zIndex: layouted.zIndex,
            position: layouted.position,
            context: contextVersion)

        // an edge that is drawn the way it already is costs nothing
        if !replaced, component != nil || signature.hidden, signature == lastSignature {
            return
        }
        lastSignature = signature

        isHidden = edge.hidden == true
        layer.isHidden = isHidden
        layer.zPosition = CGFloat(layouted.zIndex ?? 0)

        if isHidden {
            labelViews.forEach { $0.isHidden = true }
            return
        }

        // `$edgeTypes[edgeType] || BezierEdgeInternal`
        let edgeType = (edge.type?.isEmpty ?? true) ? "default" : edge.type!
        if component == nil || componentType != edgeType {
            component?.layer.removeFromSuperlayer()
            labelViews.forEach { $0.removeFromSuperview() }

            let factory = store.edgeTypes.get()[edgeType] ?? BuiltInTypes.edgeTypes["default"]!
            let made = factory()
            layer.addSublayer(made.layer)
            component = made
            componentType = edgeType
        }

        guard let component else { return }

        // the stylesheet comes before the style of the edge, which wins
        var style = edge.style
        var labelStyle = edge.labelStyle

        if let sheet = context.styleSheet {
            var classes: Set<String> = [FlowClass.edge, "\(FlowClass.edge)-\(edgeType)"]
            for name in (edge.className ?? "").split(separator: " ") {
                classes.insert(String(name))
            }
            if edge.animated == true { classes.insert("animated") }
            if edge.selected == true { classes.insert("selected") }
            if signature.selectable { classes.insert("selectable") }

            // the edge is a group of elements: what is set on it is what its path inherits
            let group = sheet.style(classes: classes, ancestors: context.edgeAncestors)
            let path = sheet.style(classes: ["svelte-flow__edge-path"], ancestors: [classes] + context.edgeAncestors)
            style = [group, path, edge.style].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "; ")

            labelStyle = sheet.style(
                classes: ["svelte-flow__edge-label"], ancestors: context.labelAncestors, inline: edge.labelStyle)
        }

        let position = layouted.position
        let markerStart = edge.markerStart.flatMap { marker -> String? in
            let markerId = getMarkerId(marker, id: context.flowId)
            return markerId.isEmpty ? nil : markerId
        }
        let markerEnd = edge.markerEnd.flatMap { marker -> String? in
            let markerId = getMarkerId(marker, id: context.flowId)
            return markerId.isEmpty ? nil : markerId
        }

        component.update(
            props: EdgeProps(
                id: edge.id,
                source: edge.source,
                target: edge.target,
                sourceX: position.sourceX,
                sourceY: position.sourceY,
                targetX: position.targetX,
                targetY: position.targetY,
                sourcePosition: position.sourcePosition,
                targetPosition: position.targetPosition,
                type: edgeType,
                data: edge.data,
                animated: edge.animated ?? false,
                selected: edge.selected ?? false,
                selectable: edge.selectable ?? store.elementsSelectable.get(),
                deletable: edge.deletable ?? true,
                label: edge.label,
                labelStyle: labelStyle,
                style: style,
                interactionWidth: edge.interactionWidth,
                sourceHandleId: edge.sourceHandle,
                targetHandleId: edge.targetHandle,
                markerStart: markerStart,
                markerEnd: markerEnd,
                pathOptions: edge.pathOptions),
            context: context)

        labelViews.forEach { $0.isHidden = false }
    }

    func contains(point: CGPoint) -> Bool {
        guard !isHidden, let component else { return false }
        return component.contains(point: point)
    }

    func tearDown() {
        layer.removeFromSuperlayer()
        labelViews.forEach { $0.removeFromSuperview() }
    }
}

/// `EdgeRenderer.svelte`: the edges of the flow, each drawn in a layer of this view. The view is the
/// size of the flow and is only touched where an edge is.
final class EdgeRenderer: FlowPassthroughView, FlowClickable, FlowHoverable, FlowContextMenuHandling {
    let store: SwiftFlowStore

    /// Where the labels of the edges go.
    private weak var labelHost: UIView?

    /// The layer the layers of the edges are put in, below the ones of the nodes. It is the layer of the
    /// node renderer, which makes the `zIndex` of an edge count against the ones of the nodes the way it
    /// does on the web: both are `zPosition`s of siblings. Without one the renderer draws in its own layer.
    private weak var layerHost: CALayer?

    /// What the edges read their style from.
    var styleScope: () -> FlowStyleScope = { FlowStyleScope(properties: FlowTheme.light) }
    var colorModeClass: () -> ColorModeClass = { .light }
    var font: (CGFloat, UIFont.Weight) -> UIFont = { UIFont.systemFont(ofSize: $0, weight: $1) } {
        didSet { contextVersion += 1 }
    }

    var styleSheet: () -> FlowStyleSheet? = { nil }

    var onEdgeClick: ((EdgeEvent) -> Void)?
    var onEdgeContextMenu: ((EdgeEvent) -> Void)?
    var onEdgeMouseEnter: ((EdgeEvent) -> Void)?
    var onEdgeMouseLeave: ((EdgeEvent) -> Void)?

    private var wrappers: [String: EdgeWrapper] = [:]
    /// The edges that went off screen. They are kept so an edge that comes back is not made again,
    /// until there are more of them than `detachedLimit`.
    private var detached: [String: EdgeWrapper] = [:]
    private var detachedOrder: [String] = []
    private let detachedLimit = 256
    private var ordered: [EdgeWrapper] = []
    private var hitOrder: [EdgeWrapper] = []
    private var managedLabels: [ObjectIdentifier: UIView] = [:]
    private var subscriptions: [Unsubscribe] = []
    private var hoveredId: String?
    private var hasEdges = false
    private var isReconciling = false

    // What the edges were drawn with the last time: when it differs they are all drawn again.
    private var contextVersion = 0
    private var lastScope: FlowStyleScope?
    private var lastMarkers: [MarkerProps]?
    private var lastFlowId: String?
    private var lastTheme: ColorModeClass?

    init(store: SwiftFlowStore, labelHost: UIView, layerHost: CALayer? = nil) {
        self.store = store
        self.labelHost = labelHost
        self.layerHost = layerHost
        super.init(frame: .zero)

        flowClasses = ["svelte-flow__edges"]
        isUserInteractionEnabled = true

        subscriptions.append(store.visibleEdges.subscribeAny { [weak self] in self?.reconcile() })
        subscriptions.append(store.markers.subscribeAny { [weak self] in self?.reconcile() })
        subscriptions.append(store.elementsSelectable.subscribeAny { [weak self] in self?.reconcile() })
        subscriptions.append(store.edgeTypes.subscribeAny { [weak self] in
            self?.edgeTypesChanged()
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscriptions.forEach { $0() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // animations are dropped when the layers leave the screen
        if window != nil {
            reconcile()
        }
    }

    private func edgeTypesChanged() {
        // the components of the edges are made again by the types that are given now
        let current = wrappers
        wrappers = [:]
        detached = [:]
        detachedOrder = []
        ordered = []
        current.values.forEach { $0.tearDown() }
        reconcile()
    }

    // MARK: Rendering

    func reconcile() {
        if isReconciling { return }
        isReconciling = true
        defer { isReconciling = false }

        // the paths of the edges change from one frame to the next: they are not animated
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let layouted = store.visibleEdges.get()
        let sheet = styleSheet()
        let context = EdgeRenderContext(
            styleScope: styleScope(),
            markers: store.markers.get(),
            flowId: store.flowId.get(),
            theme: colorModeClass(),
            selectEdge: { [weak store] id in store?.handleEdgeSelect(id) },
            font: font,
            styleSheet: sheet,
            edgeAncestors: sheet == nil ? [] : [flowClasses] + styleAncestors(),
            labelAncestors: sheet == nil ? [] : labelHost.map { [$0.flowClasses] + $0.styleAncestors() } ?? [])

        if context.styleScope !== lastScope || context.markers != lastMarkers
            || context.flowId != lastFlowId || context.theme != lastTheme {
            lastScope = context.styleScope
            lastMarkers = context.markers
            lastFlowId = context.flowId
            lastTheme = context.theme
            contextVersion += 1
        }

        var next: [EdgeWrapper] = []
        var seen = Set<String>()

        for item in layouted {
            // an edge id is unique
            if !seen.insert(item.id).inserted { continue }

            let wrapper: EdgeWrapper
            if let existing = wrappers[item.id] {
                wrapper = existing
            } else if let kept = detached.removeValue(forKey: item.id) {
                detachedOrder.removeAll { $0 == item.id }
                wrapper = kept
                wrappers[item.id] = kept
            } else {
                wrapper = EdgeWrapper(edge: item.edge)
                wrappers[item.id] = wrapper
            }

            wrapper.apply(item, store: store, context: context, contextVersion: contextVersion)
            next.append(wrapper)
        }

        for (id, wrapper) in wrappers where !seen.contains(id) {
            wrapper.tearDown()
            wrappers[id] = nil
            keepDetached(wrapper, id: id)
        }

        // the order of the layers is the order of the edges, all of them below the nodes
        let host = layerHost ?? layer
        let needsReorder = next.count != ordered.count
            || zip(next, ordered).contains { $0 !== $1 }
            || next.contains { $0.layer.superlayer !== host }
        ordered = next
        if needsReorder {
            for (index, wrapper) in next.enumerated() {
                wrapper.layer.removeFromSuperlayer()
                host.insertSublayer(wrapper.layer, at: UInt32(index))
            }
        }

        // the edge that is drawn last is on top, which is the one a touch finds first
        hitOrder = next.enumerated()
            .sorted { first, second in
                if first.element.layer.zPosition != second.element.layer.zPosition {
                    return first.element.layer.zPosition > second.element.layer.zPosition
                }
                return first.offset > second.offset
            }
            .map { $0.element }

        syncLabels()

        // `CallOnMount`: the edges are initialized once there are some
        let has = !layouted.isEmpty
        if has != hasEdges {
            hasEdges = has
            store.edgesInitialized.set(has)
        }
    }

    private func keepDetached(_ wrapper: EdgeWrapper, id: String) {
        // an edge that is gone from the flow is not kept
        guard store.edgeLookup.get().get(id) != nil else { return }

        detached[id] = wrapper
        detachedOrder.removeAll { $0 == id }
        detachedOrder.append(id)

        while detachedOrder.count > detachedLimit {
            detached[detachedOrder.removeFirst()] = nil
        }
    }

    private func syncLabels() {
        guard let labelHost else { return }

        var wanted: [ObjectIdentifier: UIView] = [:]
        for wrapper in ordered {
            for view in wrapper.labelViews {
                wanted[ObjectIdentifier(view)] = view
                if view.superview !== labelHost {
                    labelHost.addSubview(view)
                }
            }
        }

        for (key, view) in managedLabels where wanted[key] == nil {
            view.removeFromSuperview()
        }

        managedLabels = wanted
    }

    // MARK: Hit testing

    private func wrapper(containing point: CGPoint) -> EdgeWrapper? {
        for wrapper in hitOrder where wrapper.contains(point: point) {
            return wrapper
        }
        return nil
    }

    private func wrapper(at event: FlowPointerEvent) -> EdgeWrapper? {
        wrapper(containing: convert(CGPoint(x: event.clientX, y: event.clientY), from: nil))
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, isUserInteractionEnabled else { return nil }
        return wrapper(containing: point) != nil ? self : nil
    }

    /// The z index of the edge that is drawn on top at a point, if there is one.
    func zIndexOfEdge(at point: CGPoint) -> Double? {
        guard !isHidden, let wrapper = wrapper(containing: point) else { return nil }
        return Double(wrapper.layer.zPosition)
    }

    func edge(at event: FlowPointerEvent) -> Edge? {
        wrapper(at: event)?.edge
    }

    // MARK: Events

    func flowClick(event: FlowPointerEvent) {
        guard let wrapper = wrapper(at: event), let edge = store.edgeLookup.get().get(wrapper.id) else { return }

        store.handleEdgeSelect(wrapper.id)
        onEdgeClick?(EdgeEvent(edge: edge, event: event))
    }

    func flowContextMenu(event: FlowPointerEvent) {
        guard let wrapper = wrapper(at: event), let edge = store.edgeLookup.get().get(wrapper.id) else { return }
        onEdgeContextMenu?(EdgeEvent(edge: edge, event: event))
    }

    func flowHover(event: FlowPointerEvent, phase: UIGestureRecognizer.State) {
        let id: String?
        switch phase {
        case .began, .changed:
            id = wrapper(at: event)?.id
        default:
            id = nil
        }

        if id == hoveredId { return }

        let previous = hoveredId
        hoveredId = id

        if let previous, let edge = store.edgeLookup.get().get(previous) {
            onEdgeMouseLeave?(EdgeEvent(edge: edge, event: event))
        }

        if let id, let edge = store.edgeLookup.get().get(id) {
            onEdgeMouseEnter?(EdgeEvent(edge: edge, event: event))
        }
    }
}
#endif
