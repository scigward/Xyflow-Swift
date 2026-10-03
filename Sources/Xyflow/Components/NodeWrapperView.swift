#if canImport(UIKit)
import UIKit
import XYSystem

/// What a node is told, and what makes it different from the last time: a node is only updated when
/// one of these changed.
private struct NodeSignature: Equatable {
    var dataRevision: Int
    var type: String
    var selected: Bool
    var dragging: Bool
    var draggable: Bool
    var selectable: Bool
    var deletable: Bool
    var connectable: Bool
    var zIndex: Double
    var positionX: Double
    var positionY: Double
    var width: Double?
    var height: Double?
    var sourcePosition: Position?
    var targetPosition: Position?
    var dragHandle: String?
    var parentId: String?
    var hidden: Bool
    var hasDimensions: Bool
    var measuredWidth: Double?
    var measuredHeight: Double?
    var initialWidth: Double?
    var initialHeight: Double?
    var style: String?
    var className: String?
}

/// The element of a node (`.svelte-flow__node`): it holds the view of the node's type, is placed where
/// the node is, is measured, and the drag of the node starts on it.
public final class NodeWrapperView: UIView, NodeElement, FlowElement, FlowDragHost, FlowClickable, FlowContextMenuHandling {
    public let nodeId: String
    public let store: SwiftFlowStore

    /// Whether the handles of the node can connect (the context a node's handles read).
    public let connectable = Writable<Bool>(true)

    public private(set) var internalNode: InternalNode

    /// Where the style of the node starts from: the root of the flow. Set by whoever makes the node.
    var parentScope: () -> FlowStyleScope = { FlowStyleScope(properties: FlowTheme.light) }

    /// The stylesheet of the flow, and the classes of the views the node is among.
    var parentSheet: () -> FlowStyleSheet? = { nil }
    var parentAncestors: () -> [Set<String>] = { [] }

    // Events, which the renderer hands on to the callbacks of the flow.
    var onNodeClick: ((NodeEvent) -> Void)?
    var onNodeMouseEnter: ((NodeEvent) -> Void)?
    var onNodeMouseLeave: ((NodeEvent) -> Void)?
    var onNodeMouseMove: ((NodeEvent) -> Void)?
    var onNodeContextMenu: ((NodeEvent) -> Void)?
    var onNodeDragStart: ((NodeDragEvent) -> Void)?
    var onNodeDrag: ((NodeDragEvent) -> Void)?
    var onNodeDragStop: ((NodeDragEvent) -> Void)?
    /// Told when the node has a size that is not the one that was reported last.
    var onSizeChange: ((NodeWrapperView) -> Void)?

    var nodeClickDistance: Double = 0 {
        didSet { if nodeClickDistance != oldValue { updateDrag() } }
    }

    private var contentView: FlowNodeView?
    private var contentType: String?
    private var xyDrag: XYDrag!
    private var lastSignature: NodeSignature?
    /// The style of the flow the node was drawn with: a node is drawn again when the flow got another.
    private var lastParentScope: FlowStyleScope?
    /// A node that was replaced by another object is a different node, whatever its values are.
    private var lastUserNode: Node?
    /// The style of the node: what the stylesheet gives it, and then its own `style`.
    private var effectiveStyle: String?
    /// The spread of the shadow that is drawn, so its path can follow the size of the node.
    private var shadowSpread: CGFloat?
    private var lastReportedSize: CGSize?
    private var lastLayoutKey: String?
    private var isSelected = false
    private var isDraggable = false
    private var isSelectable = false
    private var isHovered = false

    static let builtInTypes: Set<String> = ["default", "input", "output", "group"]

    public init(node: InternalNode, store: SwiftFlowStore) {
        self.nodeId = node.id
        self.store = store
        self.internalNode = node
        super.init(frame: .zero)

        clipsToBounds = false
        backgroundColor = .clear

        xyDrag = XYDrag(XYDragParams(
            getStoreItems: { [store] in
                store.dragStoreItems()
            },
            onDragStart: { [weak self] event, _, targetNode, nodes in
                self?.onNodeDragStart?(NodeDragEvent(targetNode: targetNode, nodes: nodes, event: event))
            },
            onDrag: { [weak self] event, _, targetNode, nodes in
                self?.onNodeDrag?(NodeDragEvent(targetNode: targetNode, nodes: nodes, event: event))
            },
            onDragStop: { [weak self] event, _, targetNode, nodes in
                self?.onNodeDragStop?(NodeDragEvent(targetNode: targetNode, nodes: nodes, event: event))
            },
            onNodeMouseDown: { [weak store] id in
                store?.handleNodeSelection(id)
            }))

        let hover = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
        addGestureRecognizer(hover)

        apply(node)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        xyDrag.destroy()
    }

    // MARK: Style

    /// The custom properties of the node: its `style` on top of the ones of the flow.
    public var styleScope: FlowStyleScope {
        FlowStyleScope(parent: parentScope(), style: effectiveStyle)
    }

    // MARK: Updating

    /// Brings the view in line with the node: its type, its place, its size, its looks and the props of its content.
    /// A node that is the same as the last time is left alone, unless `force` says that something around it changed.
    func apply(_ node: InternalNode, force: Bool = false) {
        internalNode = node
        let userNode = node.internals.userNode

        let nodeType = (node.type?.isEmpty ?? true) ? "default" : node.type!
        let hidden = node.hidden == true

        let selected = node.selected == true
        let nodesDraggable = store.nodesDraggable.get()
        let elementsSelectable = store.elementsSelectable.get()
        let nodesConnectable = store.nodesConnectable.get()
        let draggable = node.draggable == true || (nodesDraggable && node.draggable == nil)
        let selectable = node.selectable == true || (elementsSelectable && node.selectable == nil)
        let isConnectable = node.connectable == true || (nodesConnectable && node.connectable == nil)
        let position = node.internals.positionAbsolute

        isSelected = selected
        isDraggable = draggable
        isSelectable = selectable
        isHidden = hidden

        if connectable.get() != isConnectable {
            connectable.set(isConnectable)
        }

        // the content of the type
        let typeChanged = contentType != nil && contentType != nodeType
        let handleSidesChanged = lastSignature != nil
            && (lastSignature?.sourcePosition != node.sourcePosition || lastSignature?.targetPosition != node.targetPosition)

        if contentView == nil || contentType != nodeType {
            rebuildContent(type: nodeType)
        }

        let hasDimensions = nodeHasDimensions(node)
        let signature = NodeSignature(
            dataRevision: userNode.dataRevision,
            type: nodeType,
            selected: selected,
            dragging: node.dragging == true,
            draggable: draggable,
            selectable: selectable,
            deletable: node.deletable ?? true,
            connectable: isConnectable,
            zIndex: node.internals.z,
            positionX: position.x,
            positionY: position.y,
            width: node.width,
            height: node.height,
            sourcePosition: node.sourcePosition,
            targetPosition: node.targetPosition,
            dragHandle: node.dragHandle,
            parentId: node.parentId,
            hidden: hidden,
            hasDimensions: hasDimensions,
            measuredWidth: node.measured.width,
            measuredHeight: node.measured.height,
            initialWidth: node.initialWidth,
            initialHeight: node.initialHeight,
            style: userNode.style ?? node.style,
            className: userNode.className ?? node.className)

        let scope = parentScope()
        let changed = signature != lastSignature
        let scopeChanged = lastParentScope !== scope
        let unchanged = !changed && !force && !scopeChanged && lastUserNode === userNode
        lastSignature = signature
        lastParentScope = scope
        lastUserNode = userNode

        // everything below only depends on what is in the signature and on the style of the flow;
        // a node without dimensions is measured again every time it is told, until it has them
        if unchanged && (hidden || hasDimensions) {
            return
        }

        var classes: Set<String> = [FlowClass.node, "\(FlowClass.node)-\(nodeType)"]
        for name in (userNode.className ?? node.className ?? "").split(separator: " ") {
            classes.insert(String(name))
        }
        if draggable { classes.insert(FlowClass.noPan) }
        if selected { classes.insert("selected") }
        if selectable { classes.insert("selectable") }
        if draggable { classes.insert("draggable") }
        if node.dragging == true { classes.insert("dragging") }
        flowClasses = classes

        let ownStyle = userNode.style ?? node.style
        let sheet = parentSheet()
        effectiveStyle = sheet?.style(classes: classes, ancestors: parentAncestors(), inline: ownStyle) ?? ownStyle

        if changed {
            contentView?.update(props: NodeProps(
                id: node.id,
                data: node.data,
                width: node.width,
                height: node.height,
                sourcePosition: node.sourcePosition,
                targetPosition: node.targetPosition,
                dragHandle: node.dragHandle,
                parentId: node.parentId,
                type: nodeType,
                dragging: node.dragging == true,
                zIndex: node.internals.z,
                selectable: selectable,
                deletable: node.deletable ?? true,
                selected: selected,
                draggable: draggable,
                isConnectable: isConnectable,
                positionAbsoluteX: position.x,
                positionAbsoluteY: position.y))
        }

        // nodes and edges are in front of each other by their z index
        layer.zPosition = CGFloat(node.internals.z)

        if hidden {
            return
        }

        updateAppearance()
        layoutNode(at: position)

        // the handles are drawn from the style of the node, and from the classes of it a stylesheet sees
        if scopeChanged || (changed && sheet != nil) {
            for handle in handleViews(in: self) {
                handle.updateAppearance()
            }
        }

        // `style:visibility={initialized ? 'visible' : 'hidden'}`
        alpha = hasDimensions ? 1 : 0

        updateDrag()

        if typeChanged || handleSidesChanged {
            // if type, sourcePosition or targetPosition changes, we need to re-calculate the handle positions
            requestAnimationFrame { [weak self] in
                guard let self else { return }
                self.store.updateNodeInternals(OrderedMap<String, InternalNodeUpdate>([
                    (self.nodeId, InternalNodeUpdate(id: self.nodeId, nodeElement: self, force: true))
                ]))
            }
        }

        // the node is measured again, for as long as it has no dimensions
        if !hasDimensions {
            lastReportedSize = nil
        }

        reportSizeIfNeeded()
    }

    private func rebuildContent(type nodeType: String) {
        contentView?.removeFromSuperview()

        let types = store.nodeTypes.get()
        var factory = types[nodeType]
        if factory == nil {
            devWarn("003", ErrorMessages.error003(nodeType))
            factory = BuiltInTypes.nodeTypes["default"]
        }

        let view = factory!()
        view.autoresizingMask = []
        addSubview(view)
        contentView = view
        contentType = nodeType
        lastSignature = nil
        lastLayoutKey = nil
    }

    /// The node types of the flow were replaced: the view of the node is made again by the new ones.
    func nodeTypesDidChange() {
        contentView?.removeFromSuperview()
        contentView = nil
        contentType = nil
        lastSignature = nil
        apply(internalNode, force: true)
    }

    // MARK: Drag

    private func updateDrag() {
        let node = internalNode.internals.userNode

        xyDrag.update(DragUpdateParams(
            noDragClassName: FlowClass.noDrag,
            handleSelector: node.dragHandle,
            isSelectable: isSelectable,
            nodeId: nodeId,
            domNode: self,
            nodeClickDistance: nodeClickDistance))
    }

    var flowDragEnabled: Bool { isDraggable }

    var flowDragBehavior: D3DragBehavior {
        xyDrag.behavior
    }

    // MARK: Looks

    private var isBuiltIn: Bool {
        NodeWrapperView.builtInTypes.contains(contentType ?? "")
    }

    /// The declarations of the node's `style` that are set on the node's own box.
    private func inlineStyle() -> [String: String] {
        var values: [String: String] = [:]
        for declaration in FlowCSS.parseDeclarations(effectiveStyle) {
            values[declaration.name] = declaration.value
        }
        return values
    }

    private var contentInsets: UIEdgeInsets {
        guard isBuiltIn else { return .zero }

        let scope = styleScope
        let inline = inlineStyle()
        var border = scope.border(["--xy-node-border", "--xy-node-border-default"])
        if let declared = inline["border"], let resolved = scope.resolve(declared) {
            border = FlowCSS.parseBorder(resolved)
        }
        let width = CGFloat(border?.width ?? 0)
        return UIEdgeInsets(top: width, left: width, bottom: width, right: width)
    }

    private func updateAppearance() {
        let scope = styleScope
        let inline = inlineStyle()

        func inlineColor(_ names: [String]) -> FlowColor? {
            for name in names {
                if let declared = inline[name], let resolved = scope.resolve(declared), let color = FlowCSS.parseColor(resolved) {
                    return color
                }
            }
            return nil
        }

        var background: FlowColor?
        var border: FlowBorder?
        var radius: Double?
        var shadow: FlowShadow?
        var textColor: FlowColor?

        if isBuiltIn {
            let isGroup = contentType == "group"
            background = scope.color(isGroup
                ? ["--xy-node-group-background-color", "--xy-node-group-background-color-default"]
                : ["--xy-node-background-color", "--xy-node-background-color-default"])
            border = scope.border(["--xy-node-border", "--xy-node-border-default"])
            radius = scope.number(["--xy-node-border-radius", "--xy-node-border-radius-default"])
            textColor = scope.color(["--xy-node-color", "--xy-node-color-default"])

            if isSelectable {
                if isSelected {
                    shadow = scope.shadow(["--xy-node-boxshadow-selected", "--xy-node-boxshadow-selected-default"])
                } else if isHovered {
                    shadow = scope.shadow(["--xy-node-boxshadow-hover", "--xy-node-boxshadow-hover-default"])
                }
            }
        }

        if let color = inlineColor(["background-color", "background"]) { background = color }
        if let declared = inline["border"], let resolved = scope.resolve(declared) { border = FlowCSS.parseBorder(resolved) }
        if let declared = inline["border-radius"], let length = FlowCSS.parseLength(declared) { radius = length }
        if let declared = inline["box-shadow"], let resolved = scope.resolve(declared) { shadow = FlowCSS.parseShadow(resolved) }
        if let color = inlineColor(["color"]) { textColor = color }

        backgroundColor = background?.uiColor ?? .clear
        layer.cornerRadius = CGFloat(radius ?? 0)
        layer.borderWidth = CGFloat(border?.width ?? 0)
        layer.borderColor = (border?.color ?? FlowColor.clear).uiColor.cgColor

        if let shadow {
            layer.shadowColor = shadow.color.uiColor.cgColor
            layer.shadowOpacity = 1
            layer.shadowOffset = CGSize(width: shadow.offsetX, height: shadow.offsetY)
            layer.shadowRadius = CGFloat(shadow.blur / 2)
            shadowSpread = CGFloat(shadow.spread)
            updateShadowPath()
        } else {
            shadowSpread = nil
            layer.shadowOpacity = 0
            layer.shadowPath = nil
        }

        if let opacity = inline["opacity"].flatMap({ Double($0) }), alpha > 0 {
            alpha = CGFloat(opacity)
        }

        if let component = contentView as? BuiltInNodeContent {
            component.textColor = (textColor ?? scope.inheritedColor()).map { $0.uiColor } ?? .label
        }
    }

    private func updateShadowPath() {
        guard let spread = shadowSpread else { return }
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds.insetBy(dx: -spread, dy: -spread),
            cornerRadius: layer.cornerRadius + spread).cgPath
    }

    // MARK: Size and place

    /// The inline `width` and `height` of the element: the node's own, which are before measuring the
    /// initial ones, and the ones of its `style`.
    private func explicitDimensions() -> (width: Double?, height: Double?) {
        let node = internalNode
        let inline = inlineStyle()

        var styleWidth: Double?
        var styleHeight: Double?

        if node.measured.width == nil && node.measured.height == nil {
            let width = node.width ?? node.initialWidth
            let height = node.height ?? node.initialHeight
            styleWidth = (width ?? 0) != 0 ? width : nil
            styleHeight = (height ?? 0) != 0 ? height : nil
        } else {
            styleWidth = (node.width ?? 0) != 0 ? node.width : nil
            styleHeight = (node.height ?? 0) != 0 ? node.height : nil
        }

        let width = styleWidth ?? inline["width"].flatMap { FlowCSS.parseLength($0) }
        let height = styleHeight ?? inline["height"].flatMap { FlowCSS.parseLength($0) }

        // `.xy-flow__node-default { width: 150px }`
        if width == nil && isBuiltIn {
            return (150, height)
        }

        return (width, height)
    }

    private func layoutNode(at position: XYPosition) {
        let dimensions = explicitDimensions()
        let insets = contentInsets
        let key = "\(dimensions.width ?? -1)|\(dimensions.height ?? -1)|\(insets.top)|\(lastSignature?.dataRevision ?? 0)|\(lastSignature?.type ?? "")"

        var size = bounds.size
        if key != lastLayoutKey || size == .zero {
            size = fittingSize(dimensions: dimensions, insets: insets)
            lastLayoutKey = key
        }

        frame = CGRect(x: CGFloat(position.x), y: CGFloat(position.y), width: size.width, height: size.height)
        updateShadowPath()

        if let contentView {
            contentView.frame = CGRect(
                x: insets.left,
                y: insets.top,
                width: max(0, size.width - insets.left - insets.right),
                height: max(0, size.height - insets.top - insets.bottom))
            contentView.setNeedsLayout()
            contentView.layoutIfNeeded()
        }
    }

    /// Whatever the content needs, with the width and height that are given.
    private func fittingSize(dimensions: (width: Double?, height: Double?), insets: UIEdgeInsets) -> CGSize {
        guard let contentView else {
            return CGSize(width: dimensions.width ?? 0, height: dimensions.height ?? 0)
        }

        let horizontalInsets = insets.left + insets.right
        let verticalInsets = insets.top + insets.bottom

        let innerWidth = dimensions.width.map { max(0, CGFloat($0) - horizontalInsets) }
        let innerHeight = dimensions.height.map { max(0, CGFloat($0) - verticalInsets) }

        var size: CGSize

        if let preferred = (contentView as FlowNodeComponent).preferredSize(
            width: innerWidth.map { Double($0) }, height: innerHeight.map { Double($0) }) {
            size = preferred
        } else {
            let target = CGSize(
                width: innerWidth ?? UIView.layoutFittingCompressedSize.width,
                height: innerHeight ?? UIView.layoutFittingCompressedSize.height)
            size = contentView.systemLayoutSizeFitting(
                target,
                withHorizontalFittingPriority: innerWidth != nil ? .required : .fittingSizeLevel,
                verticalFittingPriority: innerHeight != nil ? .required : .fittingSizeLevel)

            if size.width <= 0 || size.height <= 0 {
                let fallback = contentView.sizeThatFits(CGSize(
                    width: innerWidth ?? CGFloat.greatestFiniteMagnitude,
                    height: innerHeight ?? CGFloat.greatestFiniteMagnitude))
                if size.width <= 0 { size.width = fallback.width }
                if size.height <= 0 { size.height = fallback.height }
            }
        }

        if let innerWidth { size.width = innerWidth }
        if let innerHeight { size.height = innerHeight }

        return CGSize(width: size.width + horizontalInsets, height: size.height + verticalInsets)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        reportSizeIfNeeded()
    }

    /// What the `ResizeObserver` of the interface does: the node is measured again when its size changed.
    func reportSizeIfNeeded() {
        guard !isHidden, bounds.width > 0, bounds.height > 0 else { return }
        if let lastReportedSize, lastReportedSize == bounds.size { return }

        lastReportedSize = bounds.size
        onSizeChange?(self)
    }

    /// The size of the node changed from the inside: it is laid out again.
    public func contentSizeDidChange() {
        lastLayoutKey = nil
        apply(internalNode, force: true)
    }

    // MARK: Touches

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else { return nil }

        // handles sit on the edge of the node, half of them outside of it
        for handle in handleViews(in: self).reversed() {
            let converted = convert(point, to: handle)
            if handle.point(inside: converted, with: event) {
                return handle
            }
        }

        return super.hitTest(point, with: event)
    }

    private func handleViews(in view: UIView) -> [HandleView] {
        var result: [HandleView] = []
        for subview in view.subviews {
            if let handle = subview as? HandleView {
                result.append(handle)
            }
            result.append(contentsOf: handleViews(in: subview))
        }
        return result
    }

    func flowClick(event: FlowPointerEvent) {
        // this handler gets called by XYDrag on drag start when selectNodesOnDrag=true
        // here we only need to call it when selectNodesOnDrag=false
        if isSelectable && (!store.selectNodesOnDrag.get() || !isDraggable || store.nodeDragThreshold.get() > 0) {
            store.handleNodeSelection(nodeId)
        }

        onNodeClick?(NodeEvent(node: internalNode.internals.userNode, event: event))
    }

    func flowContextMenu(event: FlowPointerEvent) {
        onNodeContextMenu?(NodeEvent(node: internalNode.internals.userNode, event: event))
    }

    @objc private func handleHover(_ recognizer: UIHoverGestureRecognizer) {
        let location = recognizer.location(in: nil)
        let event = FlowPointerEvent(kind: .mouse, clientX: Double(location.x), clientY: Double(location.y), target: self)
        let nodeEvent = NodeEvent(node: internalNode.internals.userNode, event: event)

        switch recognizer.state {
        case .began:
            isHovered = true
            updateAppearance()
            onNodeMouseEnter?(nodeEvent)
        case .changed:
            onNodeMouseMove?(nodeEvent)
        case .ended, .cancelled, .failed:
            isHovered = false
            updateAppearance()
            onNodeMouseLeave?(nodeEvent)
        default:
            break
        }
    }

    // MARK: NodeElement

    public var dimensions: Dimensions {
        Dimensions(width: Double(bounds.width), height: Double(bounds.height))
    }

    public var boundingClientRect: Rect {
        clientRect
    }

    public func handleElements(of type: HandleType) -> [HandleElement] {
        // the handles are laid out with constraints, which are not solved until the layout pass
        layoutIfNeeded()
        return handleViews(in: self).filter { $0.type == type }
    }

    // MARK: FlowElement

    public func matches(_ target: AnyObject?, selector: String) -> Bool {
        guard let view = target as? UIView else { return false }

        if selector.hasPrefix(".") {
            return view.flowClasses.contains(String(selector.dropFirst()))
        }

        return false
    }

    public func parent(of target: AnyObject) -> AnyObject? {
        (target as? UIView)?.superview
    }
}
#endif
