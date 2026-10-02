#if canImport(UIKit)
import UIKit
import XYSystem

/// `NodeToolbar.svelte`: a view that sits next to a node, or next to a group of them, and moves and
/// scales with it. It is shown while its node is the only one that is selected.
public final class NodeToolbarView: FlowPluginView {
    /// The nodes the toolbar is at.
    public var nodeIds: [String] {
        didSet { update() }
    }

    /// The side of the node the toolbar is on.
    public var toolbarPosition: Position {
        didSet { update() }
    }

    /// How the toolbar is aligned with that side.
    public var align: Align {
        didSet { update() }
    }

    /// The distance from the node.
    public var offset: Double {
        didSet { update() }
    }

    /// When it is set the toolbar is shown, or not, whatever the selection is.
    public var isVisible: Bool? {
        didSet { update() }
    }

    /// What is in the toolbar. It is as big as the content says.
    public private(set) var contentView: UIView?

    private var subscriptions: [Unsubscribe] = []

    public init(
        nodeIds: [String] = [],
        position: Position = .top,
        align: Align = .center,
        offset: Double = 10,
        isVisible: Bool? = nil
    ) {
        self.nodeIds = nodeIds
        self.toolbarPosition = position
        self.align = align
        self.offset = offset
        self.isVisible = isVisible
        super.init(frame: .zero)

        flowClasses = ["svelte-flow__node-toolbar"]
        isHidden = true
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscriptions.forEach { $0() }
    }

    public func setContent(_ view: UIView) {
        contentView?.removeFromSuperview()
        addSubview(view)
        contentView = view
        update()
    }

    public override func attach(to flow: SwiftFlow) {
        subscriptions.forEach { $0() }
        subscriptions = []

        // the node lookup is only a helper, the nodes tell when something changed
        subscriptions.append(flow.store.nodes.subscribeAny { [weak self] in self?.update() })
        subscriptions.append(flow.store.viewport.subscribeAny { [weak self] in self?.update() })
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView?.sizeThatFits(size) ?? .zero
    }

    private func update() {
        guard let flow else { return }

        let store = flow.store
        let lookup = store.nodeLookup.get()
        let toolbarNodes = nodeIds.compactMap { lookup.get($0) }

        // if isVisible is not set, we show the toolbar only if its node is selected and no other node is selected
        let isActive: Bool
        if let isVisible {
            isActive = isVisible
        } else {
            let selectedCount = store.nodes.get().filter { $0.selected == true }.count
            isActive = toolbarNodes.count == 1 && toolbarNodes[0].selected == true && selectedCount == 1
        }

        guard isActive, !toolbarNodes.isEmpty else {
            isHidden = true
            return
        }

        let rect = flow.instance.getNodesBounds(ids: toolbarNodes.map { $0.id })
        let transform = getNodeToolbarTransform(rect, store.viewport.get(), toolbarPosition, offset, align)

        let size = sizeThatFits(.zero)
        bounds = CGRect(origin: .zero, size: size)
        contentView?.frame = bounds

        // translate(x, y) translate(shiftX%, shiftY%) of the toolbar, in the coordinates of the flow
        frame = CGRect(
            x: transform.x + transform.shiftX / 100 * Double(size.width),
            y: transform.y + transform.shiftY / 100 * Double(size.height),
            width: Double(size.width),
            height: Double(size.height))

        layer.zPosition = CGFloat(toolbarNodes.map { ($0.internals.z == 0 ? 5 : $0.internals.z) + 1 }.max() ?? 1)
        isHidden = false
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView?.frame = bounds
    }
}
#endif
