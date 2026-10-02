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

    var nodeClickDistance: Double = 0 {
        didSet {
            if nodeClickDistance != oldValue {
                wrappers.values.forEach { $0.nodeClickDistance = nodeClickDistance }
            }
        }
    }

    var onNodeClick: ((NodeEvent) -> Void)?
    var onNodeMouseEnter: ((NodeEvent) -> Void)?
    var onNodeMouseLeave: ((NodeEvent) -> Void)?
    var onNodeMouseMove: ((NodeEvent) -> Void)?
    var onNodeContextMenu: ((NodeEvent) -> Void)?
    var onNodeDragStart: ((NodeDragEvent) -> Void)?
    var onNodeDrag: ((NodeDragEvent) -> Void)?
    var onNodeDragStop: ((NodeDragEvent) -> Void)?

    private var wrappers: [String: NodeWrapperView] = [:]
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
        }

        // the nodes are stacked by their z index, and by their order when it is the same
        let stacked = next.enumerated()
            .sorted { first, second in
                let a = first.element.internalNode.internals.z
                let b = second.element.internalNode.internals.z
                return a != b ? a < b : first.offset < second.offset
            }
            .map { $0.element }

        let current = subviews
        let inOrder = current.count == stacked.count && zip(current, stacked).allSatisfy { $0 === $1 }
        if !inOrder {
            for wrapper in stacked {
                bringSubviewToFront(wrapper)
            }
        }
    }

    private func makeWrapper(for node: InternalNode) -> NodeWrapperView {
        let wrapper = NodeWrapperView(node: node, store: store)

        wrapper.parentScope = { [weak self] in
            self?.styleScope() ?? FlowStyleScope(properties: FlowTheme.light)
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
