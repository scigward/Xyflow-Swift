#if canImport(UIKit)
import UIKit
import XYSystem

/// `EdgeWrapper.svelte`: one edge of the flow, drawn by the component of its type.
final class EdgeWrapper {
    let id: String
    /// The layer in the edge layer of the flow that the edge draws in.
    let layer = CALayer()

    private(set) var edge: Edge
    private(set) var component: FlowEdgeComponent?
    private var componentType: String?
    private(set) var isHidden = false

    init(edge: Edge) {
        self.id = edge.id
        self.edge = edge
    }

    var labelViews: [UIView] {
        component?.labelViews ?? []
    }

    func apply(_ layouted: EdgeLayouted, store: SwiftFlowStore, context: EdgeRenderContext) {
        let edge = layouted.edge
        self.edge = edge

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
                labelStyle: edge.labelStyle,
                style: edge.style,
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

    /// What the edges read their style from.
    var styleScope: () -> FlowStyleScope = { FlowStyleScope(properties: FlowTheme.light) }
    var colorModeClass: () -> ColorModeClass = { .light }

    var onEdgeClick: ((EdgeEvent) -> Void)?
    var onEdgeContextMenu: ((EdgeEvent) -> Void)?
    var onEdgeMouseEnter: ((EdgeEvent) -> Void)?
    var onEdgeMouseLeave: ((EdgeEvent) -> Void)?

    private var wrappers: [String: EdgeWrapper] = [:]
    private var ordered: [EdgeWrapper] = []
    private var hitOrder: [EdgeWrapper] = []
    private var managedLabels: [ObjectIdentifier: UIView] = [:]
    private var subscriptions: [Unsubscribe] = []
    private var hoveredId: String?
    private var hasEdges = false
    private var isReconciling = false

    init(store: SwiftFlowStore, labelHost: UIView) {
        self.store = store
        self.labelHost = labelHost
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
        ordered = []
        current.values.forEach { $0.tearDown() }
        reconcile()
    }

    // MARK: Rendering

    func reconcile() {
        if isReconciling { return }
        isReconciling = true
        defer { isReconciling = false }

        let layouted = store.visibleEdges.get()
        let context = EdgeRenderContext(
            styleScope: styleScope(),
            markers: store.markers.get(),
            flowId: store.flowId.get(),
            theme: colorModeClass(),
            selectEdge: { [weak store] id in store?.handleEdgeSelect(id) })

        var next: [EdgeWrapper] = []
        var seen = Set<String>()

        for item in layouted {
            // an edge id is unique
            if !seen.insert(item.id).inserted { continue }

            let wrapper: EdgeWrapper
            if let existing = wrappers[item.id] {
                wrapper = existing
            } else {
                wrapper = EdgeWrapper(edge: item.edge)
                wrappers[item.id] = wrapper
            }

            wrapper.apply(item, store: store, context: context)
            next.append(wrapper)
        }

        for (id, wrapper) in wrappers where !seen.contains(id) {
            wrapper.tearDown()
            wrappers[id] = nil
        }

        // the order of the layers is the order of the edges
        let needsReorder = next.count != ordered.count || zip(next, ordered).contains { $0 !== $1 }
        ordered = next
        if needsReorder || layer.sublayers?.count != next.count {
            for wrapper in next {
                wrapper.layer.removeFromSuperlayer()
                layer.addSublayer(wrapper.layer)
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
