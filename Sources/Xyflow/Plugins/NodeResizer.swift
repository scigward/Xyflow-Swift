#if canImport(UIKit)
import UIKit
import XYSystem

/// `ResizeControl.svelte`: one handle, or one line, that resizes the node it is in when it is dragged.
public final class ResizeControlView: UIView, FlowElement, FlowDragHost {
    public var variant: ResizeControlVariant {
        didSet { updateAppearance() }
    }

    public var controlPosition: ControlPosition {
        didSet { controlsChanged() }
    }

    /// The node the control resizes. It is the node the control is in unless this is set.
    public var nodeId: String? {
        didSet { setUpResizer() }
    }

    /// The color of the control, a color of a style declaration.
    public var color: String? {
        didSet { updateAppearance() }
    }

    public var minWidth: Double = 10 { didSet { controlsChanged() } }
    public var minHeight: Double = 10 { didSet { controlsChanged() } }
    public var maxWidth: Double = .greatestFiniteMagnitude { didSet { controlsChanged() } }
    public var maxHeight: Double = .greatestFiniteMagnitude { didSet { controlsChanged() } }
    public var keepAspectRatio = false { didSet { controlsChanged() } }
    public var shouldResize: ShouldResize? { didSet { controlsChanged() } }
    public var onResizeStart: OnResizeStart? { didSet { controlsChanged() } }
    public var onResize: OnResize? { didSet { controlsChanged() } }
    public var onResizeEnd: OnResizeEnd? { didSet { controlsChanged() } }

    private var resizer: XYResizer?
    private var resizerNodeId: String?
    private weak var resizerStore: SwiftFlowStore?

    public init(variant: ResizeControlVariant = .handle, position: ControlPosition? = nil) {
        self.variant = variant
        self.controlPosition = position ?? (variant == .line ? .right : .bottomRight)
        super.init(frame: .zero)

        updateClasses()
        updateAppearance()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        resizer?.destroy()
    }

    private func updateClasses() {
        var classes: Set<String> = ["svelte-flow__resize-control", FlowClass.noDrag, variant.rawValue]
        for part in controlPosition.rawValue.split(separator: "-") {
            classes.insert(String(part))
        }
        flowClasses = classes
    }

    private func controlsChanged() {
        updateClasses()
        resizer?.update(updateParams())
        superview?.setNeedsLayout()
    }

    private func updateParams() -> XYResizerUpdateParams {
        XYResizerUpdateParams(
            controlPosition: controlPosition,
            boundaries: ResizeBoundaries(
                minWidth: minWidth == 0 ? 10 : minWidth,
                maxWidth: maxWidth == 0 ? .greatestFiniteMagnitude : maxWidth,
                minHeight: minHeight == 0 ? 10 : minHeight,
                maxHeight: maxHeight == 0 ? .greatestFiniteMagnitude : maxHeight),
            keepAspectRatio: keepAspectRatio,
            onResizeStart: onResizeStart,
            onResize: onResize,
            onResizeEnd: onResizeEnd,
            shouldResize: shouldResize)
    }

    // MARK: Look

    private var scope: FlowStyleScope {
        enclosingFlow?.rootScope() ?? FlowStyleScope(properties: FlowTheme.light)
    }

    func updateAppearance() {
        let base = scope
        var properties: [String: String] = [:]
        if let color { properties["--xy-resize-background-color"] = color }
        let resolved = FlowStyleScope(parent: base, properties: properties)
        let fill = resolved.color(["--xy-resize-background-color", "--xy-resize-background-color-default"])

        switch variant {
        case .handle:
            backgroundColor = fill?.uiColor ?? .clear
            layer.borderWidth = 1
            layer.borderColor = UIColor.white.cgColor
            layer.cornerRadius = 1
        case .line:
            backgroundColor = fill?.uiColor ?? .clear
            layer.borderWidth = 0
            layer.cornerRadius = 0
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            updateAppearance()
            setUpResizer()
        }
    }

    // MARK: Resizing

    private var resolvedNodeId: String? {
        nodeId ?? enclosingNodeWrapper?.nodeId
    }

    private func setUpResizer() {
        guard let id = resolvedNodeId, let store = enclosingNodeWrapper?.store ?? enclosingFlow?.store else {
            return
        }

        if resizer != nil && resizerNodeId == id && resizerStore === store {
            return
        }

        resizer?.destroy()
        resizerNodeId = id
        resizerStore = store

        let instance = XYResizer(XYResizerParams(
            nodeId: id,
            getStoreItems: { [weak store] in
                guard let store else {
                    return XYResizerStoreItems(
                        nodeLookup: NodeLookup(),
                        transform: Transform(0, 0, 1),
                        snapToGrid: false,
                        nodeOrigin: .zero,
                        paneDomNode: nil)
                }

                let viewport = store.viewport.get()
                let grid = store.snapGrid.get()

                return XYResizerStoreItems(
                    nodeLookup: store.nodeLookup.get(),
                    transform: Transform(viewport.x, viewport.y, viewport.zoom),
                    snapGrid: grid,
                    snapToGrid: grid != nil,
                    nodeOrigin: store.nodeOrigin.get(),
                    paneDomNode: store.domNode.get())
            },
            onChange: { [weak store] change, childChanges in
                guard let store, let node = store.nodeLookup.get().get(id)?.internals.userNode else {
                    return
                }

                if let x = change.x, let y = change.y {
                    node.position = XYPosition(x: x, y: y)
                }

                if let width = change.width, let height = change.height {
                    node.width = width
                    node.height = height
                }

                for childChange in childChanges {
                    if let childNode = store.nodeLookup.get().get(childChange.id)?.internals.userNode {
                        childNode.position = childChange.position
                    }
                }

                store.nodes.set(store.nodes.get())
            }))

        instance.update(updateParams())
        resizer = instance
    }

    var flowDragBehavior: D3DragBehavior {
        if resizer == nil { setUpResizer() }
        return resizer?.behavior ?? D3DragBehavior()
    }
}

/// `NodeResizer.svelte`: the lines and the handles that resize a node. Put it in a custom node, it
/// resizes the node it is in.
public final class NodeResizerView: UIView {
    /// The node it resizes, which is the node it is in unless this is set.
    public var nodeId: String? {
        didSet { controls.forEach { $0.nodeId = nodeId } }
    }

    /// Whether the controls are there.
    public var isVisible = true {
        didSet {
            controls.forEach { $0.isHidden = !isVisible }
        }
    }

    public var color: String? { didSet { controls.forEach { $0.color = color } } }
    public var minWidth: Double = 10 { didSet { controls.forEach { $0.minWidth = minWidth } } }
    public var minHeight: Double = 10 { didSet { controls.forEach { $0.minHeight = minHeight } } }
    public var maxWidth: Double = .greatestFiniteMagnitude { didSet { controls.forEach { $0.maxWidth = maxWidth } } }
    public var maxHeight: Double = .greatestFiniteMagnitude { didSet { controls.forEach { $0.maxHeight = maxHeight } } }
    public var keepAspectRatio = false { didSet { controls.forEach { $0.keepAspectRatio = keepAspectRatio } } }
    public var shouldResize: ShouldResize? { didSet { controls.forEach { $0.shouldResize = shouldResize } } }
    public var onResizeStart: OnResizeStart? { didSet { controls.forEach { $0.onResizeStart = onResizeStart } } }
    public var onResize: OnResize? { didSet { controls.forEach { $0.onResize = onResize } } }
    public var onResizeEnd: OnResizeEnd? { didSet { controls.forEach { $0.onResizeEnd = onResizeEnd } } }

    private let lines: [ResizeControlView]
    private let handles: [ResizeControlView]

    private var controls: [ResizeControlView] {
        lines + handles
    }

    public override init(frame: CGRect) {
        lines = xyResizerLinePositions.map {
            ResizeControlView(variant: .line, position: ControlPosition(line: $0))
        }
        handles = xyResizerHandlePositions.map {
            ResizeControlView(variant: .handle, position: $0)
        }

        super.init(frame: frame)

        isUserInteractionEnabled = true
        backgroundColor = .clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // the lines are under the handles
        controls.forEach { addSubview($0) }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if let superview {
            frame = superview.bounds
        }
    }

    /// The controls are as big as the node, which the view is: they sit on its sides and corners.
    public override func layoutSubviews() {
        super.layoutSubviews()

        let width = bounds.width
        let height = bounds.height

        for control in lines {
            switch control.controlPosition {
            case .left:
                control.frame = CGRect(x: -1, y: 0, width: 1, height: height)
            case .right:
                control.frame = CGRect(x: width, y: 0, width: 1, height: height)
            case .top:
                control.frame = CGRect(x: 0, y: -1, width: width, height: 1)
            default:
                control.frame = CGRect(x: 0, y: height, width: width, height: 1)
            }
        }

        // a handle is 6 points wide (4 and a border of 1 on each side), and is centered on its corner
        for control in handles {
            let x: CGFloat = control.controlPosition == .topLeft || control.controlPosition == .bottomLeft ? 0 : width
            let y: CGFloat = control.controlPosition == .topLeft || control.controlPosition == .topRight ? 0 : height
            control.frame = CGRect(x: x - 3, y: y - 3, width: 6, height: 6)
        }
    }

    /// Only the controls are touched, which are outside of the view as often as inside of it.
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isVisible, !isHidden else { return nil }

        // the handles are over the lines
        for control in controls.reversed() {
            let converted = convert(point, to: control)
            if control.bounds.contains(converted) {
                return control
            }
        }

        return nil
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        hitTest(point, with: event) != nil
    }
}
#endif
