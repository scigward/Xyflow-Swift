#if canImport(UIKit)
import UIKit
import XYSystem

/// A value that is the same for every node, or one that is worked out for each of them: what the node
/// color, the stroke color and the class of a minimap can be.
public enum MiniMapAttribute {
    case value(String)
    case function((Node) -> String)

    func resolve(_ node: Node) -> String {
        switch self {
        case .value(let value): return value
        case .function(let function): return function(node)
        }
    }
}

extension MiniMapAttribute: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .value(value)
    }
}

/// `Minimap.svelte`: an overview of the flow in a corner of it. The rectangle that is not dimmed is what
/// the viewport shows, and dragging the minimap pans the flow.
public final class MiniMapView: FlowPanelView {
    public var ariaLabel: String? = "Mini map"
    public var nodeStrokeColor: MiniMapAttribute = "transparent" { didSet { canvas.setNeedsDisplay() } }
    public var nodeColor: MiniMapAttribute? { didSet { canvas.setNeedsDisplay() } }
    public var nodeBorderRadius: Double = 5 { didSet { canvas.setNeedsDisplay() } }
    public var nodeStrokeWidth: Double = 2 { didSet { canvas.setNeedsDisplay() } }
    public var bgColor: String? { didSet { themeDidChange() } }
    public var maskColor: String? { didSet { canvas.setNeedsDisplay() } }
    public var maskStrokeColor: String? { didSet { canvas.setNeedsDisplay() } }
    public var maskStrokeWidth: Double? { didSet { canvas.setNeedsDisplay() } }
    public var width: Double? { didSet { sizeChanged() } }
    public var height: Double? { didSet { sizeChanged() } }
    public var pannable = true { didSet { updateMinimap() } }
    public var zoomable = true { didSet { updateMinimap() } }
    public var inversePan: Bool? { didSet { updateMinimap() } }
    public var zoomStep: Double? { didSet { updateMinimap() } }

    let defaultWidth = 200.0
    let defaultHeight = 150.0

    private let canvas = MiniMapCanvasView()
    private var subscriptions: [Unsubscribe] = []
    private var minimap: XYMinimap?

    public override init(position: PanelPosition = .bottomRight) {
        super.init(position: position)

        flowClasses = ["svelte-flow__panel", "svelte-flow__minimap"]
        canvas.owner = self
        addSubview(canvas)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscriptions.forEach { $0() }
        minimap?.destroy()
    }

    var elementWidth: Double { width ?? defaultWidth }
    var elementHeight: Double { height ?? defaultHeight }

    private func sizeChanged() {
        canvas.setNeedsDisplay()
        updateMinimap()
        superview?.setNeedsLayout()
        setNeedsLayout()
    }

    public override func attach(to flow: SwiftFlow) {
        subscriptions.forEach { $0() }
        subscriptions = []

        let store = flow.store

        for source in [store.nodes, store.viewport, store.width, store.height] as [AnyStore] {
            subscriptions.append(source.subscribeAny { [weak self] in
                self?.canvas.setNeedsDisplay()
                self?.updateMinimap()
            })
        }

        subscriptions.append(store.nodeLookup.subscribeAny { [weak self] in self?.canvas.setNeedsDisplay() })
        subscriptions.append(store.panZoom.subscribeAny { [weak self] in self?.makeMinimap() })
        subscriptions.append(store.translateExtent.subscribeAny { [weak self] in self?.updateMinimap() })

        themeDidChange()
    }

    public override func themeDidChange() {
        guard let flow else { return }

        var properties: [String: String] = [:]
        if let bgColor { properties["--xy-minimap-background-color-props"] = bgColor }

        let scope = FlowStyleScope(parent: flow.rootScope(), properties: properties)
        backgroundColor = scope.color([
            "--xy-minimap-background-color-props",
            "--xy-minimap-background-color",
            "--xy-minimap-background-color-default"
        ])?.uiColor ?? .clear

        canvas.setNeedsDisplay()
    }

    // MARK: Interaction

    private func makeMinimap() {
        guard let store = flow?.store else { return }

        minimap?.destroy()
        minimap = nil
        canvas.zoomBehavior = nil

        guard let panZoom = store.panZoom.get() else {
            canvas.setNeedsDisplay()
            return
        }

        let instance = XYMinimap(
            XYMinimapParams(
                panZoom: panZoom,
                getTransform: {
                    let viewport = store.viewport.get()
                    return Transform(viewport.x, viewport.y, viewport.zoom)
                },
                getViewScale: { [weak self] in self?.canvas.viewScale ?? 1 }),
            extent: { [weak self] in
                CoordinateExtent(0, 0, self?.elementWidth ?? 200, self?.elementHeight ?? 150)
            })

        minimap = instance
        canvas.zoomBehavior = instance.zoomBehavior
        updateMinimap()
        canvas.setNeedsDisplay()
    }

    private func updateMinimap() {
        guard let store = flow?.store, let minimap else { return }

        minimap.update(XYMinimapUpdate(
            translateExtent: store.translateExtent.get(),
            width: store.width.get(),
            height: store.height.get(),
            inversePan: inversePan,
            zoomStep: zoomStep,
            pannable: pannable,
            zoomable: zoomable))
    }

    // MARK: Layout

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        flow?.store.panZoom.get() == nil ? .zero : CGSize(width: elementWidth, height: elementHeight)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        canvas.frame = bounds
        canvas.setNeedsDisplay()
    }
}

/// The drawing of the minimap: the nodes and the mask over what is outside of the viewport. It is drawn
/// in the coordinates of the flow, scaled to fit.
final class MiniMapCanvasView: UIView {
    weak var owner: MiniMapView?

    /// What input of the canvas goes to, once the flow has a pan and zoom controller.
    var zoomBehavior: D3ZoomBehavior?

    private(set) var viewScale: Double = 1
    private var activeTouches: [ObjectIdentifier: ZoomTouch] = [:]
    private var touchIds: [ObjectIdentifier: Int] = [:]
    private var nextTouchId = 0

    override init(frame: CGRect) {
        super.init(frame: frame)

        isOpaque = false
        contentMode = .redraw
        backgroundColor = .clear
        flowClasses = ["svelte-flow__minimap-svg", FlowClass.noPan]

        let scroll = UIPanGestureRecognizer(target: self, action: #selector(scrolled(_:)))
        scroll.allowedScrollTypesMask = [.continuous, .discrete]
        scroll.allowedTouchTypes = []
        addGestureRecognizer(scroll)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Drawing

    override func draw(_ rect: CGRect) {
        guard let owner, let flow = owner.flow, flow.store.panZoom.get() != nil,
              let context = UIGraphicsGetCurrentContext() else { return }

        let store = flow.store
        let viewport = store.viewport.get()
        let lookup = store.nodeLookup.get()
        let containerWidth = store.width.get()
        let containerHeight = store.height.get()

        let viewBB = Rect(
            x: -viewport.x / viewport.zoom,
            y: -viewport.y / viewport.zoom,
            width: containerWidth / viewport.zoom,
            height: containerHeight / viewport.zoom)

        var boundingRect = viewBB
        if lookup.count > 0 {
            boundingRect = getBoundsOfRects(
                getInternalNodesBounds(lookup) { $0.hidden != true },
                viewBB)
        }

        let elementWidth = owner.elementWidth
        let elementHeight = owner.elementHeight
        let scaledWidth = boundingRect.width / elementWidth
        let scaledHeight = boundingRect.height / elementHeight
        let scale = max(scaledWidth, scaledHeight)
        viewScale = scale

        let viewWidth = scale * elementWidth
        let viewHeight = scale * elementHeight
        let offset = 5 * scale
        let x = boundingRect.x - (viewWidth - boundingRect.width) / 2 - offset
        let y = boundingRect.y - (viewHeight - boundingRect.height) / 2 - offset
        let viewboxWidth = viewWidth + offset * 2
        let viewboxHeight = viewHeight + offset * 2

        // the view box is fitted into the view and centered in it (`preserveAspectRatio="xMidYMid meet"`)
        let fit = min(elementWidth / viewboxWidth, elementHeight / viewboxHeight)
        guard fit.isFinite, fit > 0 else { return }

        context.saveGState()
        context.translateBy(
            x: CGFloat((elementWidth - viewboxWidth * fit) / 2 - x * fit),
            y: CGFloat((elementHeight - viewboxHeight * fit) / 2 - y * fit))
        context.scaleBy(x: CGFloat(fit), y: CGFloat(fit))

        var properties: [String: String] = [:]
        if let maskColor = owner.maskColor { properties["--xy-minimap-mask-background-color-props"] = maskColor }
        if let maskStrokeColor = owner.maskStrokeColor { properties["--xy-minimap-mask-stroke-color-props"] = maskStrokeColor }
        if let maskStrokeWidth = owner.maskStrokeWidth, maskStrokeWidth != 0 {
            properties["--xy-minimap-mask-stroke-width-props"] = formatNumber(maskStrokeWidth * scale)
        }
        let scope = FlowStyleScope(parent: flow.rootScope(), properties: properties)

        // the nodes
        for userNode in store.nodes.get() {
            guard let node = lookup.get(userNode.id), nodeHasDimensions(node) else { continue }

            let dimensions = getNodeDimensions(node)
            let nodeRect = CGRect(
                x: node.internals.positionAbsolute.x,
                y: node.internals.positionAbsolute.y,
                width: dimensions.width,
                height: dimensions.height)

            var fill = scope.color([
                "--xy-minimap-node-background-color-props",
                "--xy-minimap-node-background-color",
                "--xy-minimap-node-background-color-default"
            ])
            if let color = owner.nodeColor?.resolve(node.internals.userNode),
               let parsed = scope.resolvedColor(color) {
                fill = parsed
            }

            var stroke = scope.color([
                "--xy-minimap-node-stroke-color-props",
                "--xy-minimap-node-stroke-color",
                "--xy-minimap-node-stroke-color-default"
            ])
            if let parsed = scope.resolvedColor(owner.nodeStrokeColor.resolve(node.internals.userNode)) {
                stroke = parsed
            }

            let strokeWidth = owner.nodeStrokeWidth != 0
                ? owner.nodeStrokeWidth
                : (scope.number([
                    "--xy-minimap-node-stroke-width-props",
                    "--xy-minimap-node-stroke-width",
                    "--xy-minimap-node-stroke-width-default"
                ]) ?? 0)

            let radius = CGFloat(min(owner.nodeBorderRadius, Double(min(nodeRect.width, nodeRect.height)) / 2))
            let path = UIBezierPath(roundedRect: nodeRect, cornerRadius: radius)

            if let fill {
                context.setFillColor(fill.uiColor.cgColor)
                context.addPath(path.cgPath)
                context.fillPath()
            }

            if let stroke, stroke.alpha > 0, strokeWidth > 0 {
                context.setStrokeColor(stroke.uiColor.cgColor)
                context.setLineWidth(CGFloat(strokeWidth))
                context.addPath(path.cgPath)
                context.strokePath()
            }
        }

        // the mask over what the viewport does not show, which is the outer rectangle without the inner one
        let maskPath = CGMutablePath()
        maskPath.addRect(CGRect(
            x: x - offset,
            y: y - offset,
            width: viewboxWidth + offset * 2,
            height: viewboxHeight + offset * 2))
        maskPath.addRect(CGRect(x: viewBB.x, y: viewBB.y, width: viewBB.width, height: viewBB.height))

        if let maskFill = scope.color([
            "--xy-minimap-mask-background-color-props",
            "--xy-minimap-mask-background-color",
            "--xy-minimap-mask-background-color-default"
        ]) {
            context.setFillColor(maskFill.uiColor.cgColor)
            context.addPath(maskPath)
            context.fillPath(using: .evenOdd)
        }

        let maskStroke = scope.color([
            "--xy-minimap-mask-stroke-color-props",
            "--xy-minimap-mask-stroke-color",
            "--xy-minimap-mask-stroke-color-default"
        ])
        let maskStrokeWidth = scope.number([
            "--xy-minimap-mask-stroke-width-props",
            "--xy-minimap-mask-stroke-width",
            "--xy-minimap-mask-stroke-width-default"
        ]) ?? 1

        if let maskStroke, maskStroke.alpha > 0 {
            context.setStrokeColor(maskStroke.uiColor.cgColor)
            context.setLineWidth(CGFloat(maskStrokeWidth))
            context.addPath(maskPath)
            context.strokePath()
        }

        context.restoreGState()
    }

    // MARK: Input

    private func zoomTouch(_ touch: UITouch, id: Int) -> ZoomTouch {
        let point = touch.location(in: self)
        let client = touch.location(in: nil)

        return ZoomTouch(
            identifier: id,
            point: XYPosition(x: Double(point.x), y: Double(point.y)),
            clientX: Double(client.x),
            clientY: Double(client.y))
    }

    private func touchEvent(_ type: String, changed: [ZoomTouch]) -> ZoomSourceEvent {
        let first = changed.first

        return ZoomSourceEvent(
            type: type,
            clientX: first?.clientX ?? 0,
            clientY: first?.clientY ?? 0,
            point: first?.point ?? .zero,
            target: self,
            touches: activeTouches.values.sorted { $0.identifier < $1.identifier },
            changedTouches: changed)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let zoomBehavior else { return }

        var changed: [ZoomTouch] = []
        for touch in touches {
            nextTouchId += 1
            let key = ObjectIdentifier(touch)
            touchIds[key] = nextTouchId

            let converted = zoomTouch(touch, id: nextTouchId)
            activeTouches[key] = converted
            changed.append(converted)
        }

        zoomBehavior.touchstarted(touchEvent("touchstart", changed: changed))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let zoomBehavior else { return }

        var changed: [ZoomTouch] = []
        for touch in touches {
            let key = ObjectIdentifier(touch)
            guard let id = touchIds[key] else { continue }

            let converted = zoomTouch(touch, id: id)
            activeTouches[key] = converted
            changed.append(converted)
        }

        if !changed.isEmpty {
            zoomBehavior.touchmoved(touchEvent("touchmove", changed: changed))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches, type: "touchend")
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches, type: "touchcancel")
    }

    private func finish(_ touches: Set<UITouch>, type: String) {
        var changed: [ZoomTouch] = []

        for touch in touches {
            let key = ObjectIdentifier(touch)
            guard let id = touchIds[key] else { continue }

            changed.append(zoomTouch(touch, id: id))
            activeTouches[key] = nil
            touchIds[key] = nil
        }

        if !changed.isEmpty {
            zoomBehavior?.touchended(touchEvent(type, changed: changed))
        }
    }

    /// The scrolling of a trackpad or a mouse wheel zooms the minimap.
    @objc private func scrolled(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state == .changed, let zoomBehavior else { return }

        let translation = recognizer.translation(in: self)
        recognizer.setTranslation(.zero, in: self)

        let location = recognizer.location(in: self)
        let client = recognizer.location(in: nil)

        zoomBehavior.handleWheel(ZoomSourceEvent(
            type: "wheel",
            clientX: Double(client.x),
            clientY: Double(client.y),
            point: XYPosition(x: Double(location.x), y: Double(location.y)),
            deltaX: -Double(translation.x),
            deltaY: -Double(translation.y),
            target: self))
    }
}
#endif
