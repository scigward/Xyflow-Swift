#if canImport(UIKit)
import UIKit
import XYSystem

/// `NodeRenderer.svelte`: the nodes of the flow, each one in a `NodeWrapperView`. The renderer also
/// stands in for the `ResizeObserver` of the interface: it hears when a node changed its size and
/// has the flow measure it again.
final class NodeRenderer: FlowPassthroughView {
    let store: SwiftFlowStore

    /// What the nodes read their style from.
    var styleScope: () -> FlowStyleScope = { FlowStyleScope(properties: FlowTheme.light) }
    var styleSheet: () -> FlowStyleSheet? = { nil }

    var nodeClickDistance: Double = 0 {
        didSet {
            if nodeClickDistance != oldValue {
                wrappers.values.forEach { $0.nodeClickDistance = nodeClickDistance }
            }
        }
    }

    /// What is in front of a node that an edge is above: the z index of the edge at a point of the flow,
    /// and the view that takes the touch for it.
    var edgeZIndexAt: ((CGPoint) -> Double?)?
    var edgeTarget: (() -> UIView?)?

    var onNodeClick: ((NodeEvent) -> Void)?
    var onNodeMouseEnter: ((NodeEvent) -> Void)?
    var onNodeMouseLeave: ((NodeEvent) -> Void)?
    var onNodeMouseMove: ((NodeEvent) -> Void)?
    var onNodeContextMenu: ((NodeEvent) -> Void)?
    var onNodeDragStart: ((NodeDragEvent) -> Void)?
    var onNodeDrag: ((NodeDragEvent) -> Void)?
    var onNodeDragStop: ((NodeDragEvent) -> Void)?

    private var wrappers: [String: NodeWrapperView] = [:]
    /// The nodes that went off screen. Their views are kept, so a node that comes back is not built and
    /// measured again, until there are more of them than `detachedLimit`.
    private var detached: [String: NodeWrapperView] = [:]
    private var detachedOrder: [String] = []
    private let detachedLimit = 256
    private var subscriptions: [Unsubscribe] = []
    private var pendingResizes = OrderedMap<String, InternalNodeUpdate>()
    private var isFlushScheduled = false
    private var isReconciling = false
    private var needsReconcile = false
    private var isReady = false

    init(store: SwiftFlowStore) {
        self.store = store
        super.init(frame: .zero)

        flowClasses = ["svelte-flow__nodes"]

        subscriptions.append(store.visibleNodes.subscribeAny { [weak self] in self?.reconcile() })
        subscriptions.append(store.nodesDraggable.subscribeAny { [weak self] in self?.reconcile() })
        subscriptions.append(store.nodesConnectable.subscribeAny { [weak self] in self?.reconcile() })
        subscriptions.append(store.elementsSelectable.subscribeAny { [weak self] in self?.reconcile() })

        var firstNodeTypes = true
        subscriptions.append(store.nodeTypes.subscribeAny { [weak self] in
            if firstNodeTypes {
                firstNodeTypes = false
                return
            }
            self?.nodeTypesChanged()
        })

        isReady = true
        reconcile()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscriptions.forEach { $0() }
    }

    private func nodeTypesChanged() {
        wrappers.values.forEach { $0.nodeTypesDidChange() }
        detached = [:]
        detachedOrder = []
    }

    // MARK: Touches

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else { return nil }

        // Edge labels share this host with nodes. UIKit's default hit test follows subview order,
        // not layer zPosition, so choose the frontmost hit without sorting on every touch.
        var frontHit: UIView?
        var frontZ = -CGFloat.infinity
        for subview in subviews.reversed() where subview.layer.zPosition > frontZ {
            if let hit = subview.hitTest(convert(point, to: subview), with: event) {
                frontHit = hit
                frontZ = subview.layer.zPosition
            }
        }
        guard let hit = frontHit else { return nil }

        // an edge with a z index above the one of the node is in front of it
        if let edgeZ = edgeZIndexAt?(point),
           let wrapper = hit.enclosingNodeWrapper,
           edgeZ > wrapper.internalNode.internals.z,
           let target = edgeTarget?() {
            return target
        }

        return hit
    }

    // MARK: Rendering

    func reconcile() {
        guard isReady else { return }

        if isReconciling {
            needsReconcile = true
            return
        }

        isReconciling = true
        defer { isReconciling = false }

        repeat {
            needsReconcile = false
            performReconcile()
        } while needsReconcile
    }

    private func performReconcile() {
        let nodes = store.visibleNodes.get()

        var next: [NodeWrapperView] = []
        var seen = Set<String>()

        for node in nodes {
            // a node id is unique
            if !seen.insert(node.id).inserted { continue }

            let wrapper: NodeWrapperView
            if let existing = wrappers[node.id] {
                wrapper = existing
            } else if let kept = detached.removeValue(forKey: node.id) {
                detachedOrder.removeAll { $0 == node.id }
                addSubview(kept)
                wrapper = kept
                wrappers[node.id] = kept
            } else {
                wrapper = makeWrapper(for: node)
                wrappers[node.id] = wrapper
            }

            wrapper.apply(node)
            next.append(wrapper)
        }

        for (id, wrapper) in wrappers where !seen.contains(id) {
            wrapper.removeFromSuperview()
            wrappers[id] = nil
            pendingResizes.delete(id)
            keepDetached(wrapper, id: id)
        }

        // the nodes are stacked by their z index, and by their order when it is the same
        let stacked = next.enumerated()
            .sorted { first, second in
                let a = first.element.internalNode.internals.z
                let b = second.element.internalNode.internals.z
                return a != b ? a < b : first.offset < second.offset
            }
            .map { $0.element }

        let current = subviews.compactMap { $0 as? NodeWrapperView }
        let inOrder = current.count == stacked.count && zip(current, stacked).allSatisfy { $0 === $1 }
        if !inOrder {
            for wrapper in stacked {
                bringSubviewToFront(wrapper)
            }
        }
    }

    private func keepDetached(_ wrapper: NodeWrapperView, id: String) {
        // a node that is gone from the flow is not kept
        guard store.nodeLookup.get().get(id) != nil else { return }

        detached[id] = wrapper
        detachedOrder.removeAll { $0 == id }
        detachedOrder.append(id)

        while detachedOrder.count > detachedLimit {
            detached[detachedOrder.removeFirst()] = nil
        }
    }

    private func makeWrapper(for node: InternalNode) -> NodeWrapperView {
        let wrapper = NodeWrapperView(node: node, store: store)

        wrapper.parentScope = { [weak self] in
            self?.styleScope() ?? FlowStyleScope(properties: FlowTheme.light)
        }
        wrapper.parentSheet = { [weak self] in self?.styleSheet() }
        wrapper.parentAncestors = { [weak self] in
            guard let self else { return [] }
            return [self.flowClasses] + self.styleAncestors()
        }
        wrapper.nodeClickDistance = nodeClickDistance
        wrapper.onSizeChange = { [weak self] wrapper in self?.sizeChanged(wrapper) }
        wrapper.onNodeClick = { [weak self] event in self?.onNodeClick?(event) }
        wrapper.onNodeMouseEnter = { [weak self] event in self?.onNodeMouseEnter?(event) }
        wrapper.onNodeMouseLeave = { [weak self] event in self?.onNodeMouseLeave?(event) }
        wrapper.onNodeMouseMove = { [weak self] event in self?.onNodeMouseMove?(event) }
        wrapper.onNodeContextMenu = { [weak self] event in self?.onNodeContextMenu?(event) }
        wrapper.onNodeDragStart = { [weak self] event in self?.onNodeDragStart?(event) }
        wrapper.onNodeDrag = { [weak self] event in self?.onNodeDrag?(event) }
        wrapper.onNodeDragStop = { [weak self] event in self?.onNodeDragStop?(event) }

        addSubview(wrapper)
        return wrapper
    }

    // MARK: Measuring

    /// The nodes that changed their size are measured together, once everything that changed
    /// them is done.
    private func sizeChanged(_ wrapper: NodeWrapperView) {
        pendingResizes.set(
            wrapper.nodeId,
            InternalNodeUpdate(id: wrapper.nodeId, nodeElement: wrapper, force: true))

        if isFlushScheduled { return }
        isFlushScheduled = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.isFlushScheduled = false
            let updates = self.pendingResizes
            self.pendingResizes = OrderedMap<String, InternalNodeUpdate>()

            if !updates.isEmpty {
                self.store.updateNodeInternals(updates)
            }
        }
    }

    /// The node with the id, if it is on screen.
    func wrapper(for id: String) -> NodeWrapperView? {
        wrappers[id]
    }
}
#endif
