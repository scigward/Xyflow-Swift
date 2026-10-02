#if canImport(UIKit)
import UIKit
import XYSystem

/// A glyph made of SVG paths, which is how the buttons of the controls are drawn.
public struct FlowIcon {
    /// The size of the view box of the paths.
    public var viewBox: CGSize
    public var paths: [String]
    /// Whether the paths are filled.
    public var fills: Bool
    /// The width of the stroke of the paths, in the units of the view box. Without one they have no stroke.
    public var strokeWidth: Double?

    public init(viewBox: CGSize, paths: [String], fills: Bool = true, strokeWidth: Double? = nil) {
        self.viewBox = viewBox
        self.paths = paths
        self.fills = fills
        self.strokeWidth = strokeWidth
    }

    public static let plus = FlowIcon(
        viewBox: CGSize(width: 32, height: 32),
        paths: ["M32 18.133H18.133V32h-4.266V18.133H0v-4.266h13.867V0h4.266v13.867H32z"])

    public static let minus = FlowIcon(
        viewBox: CGSize(width: 32, height: 5),
        paths: ["M0 0h32v4.2H0z"])

    public static let fit = FlowIcon(
        viewBox: CGSize(width: 32, height: 30),
        paths: [
            "M3.692 4.63c0-.53.4-.938.939-.938h5.215V0H4.708C2.13 0 0 2.054 0 4.63v5.216h3.692V4.631zM27.354 0h-5.2v3.692h5.17c.53 0 .984.4.984.939v5.215H32V4.631A4.624 4.624 0 0027.354 0zm.954 24.83c0 .532-.4.94-.939.94h-5.215v3.768h5.215c2.577 0 4.631-2.13 4.631-4.707v-5.139h-3.692v5.139zm-23.677.94c-.531 0-.939-.4-.939-.94v-5.138H0v5.139c0 2.577 2.13 4.707 4.708 4.707h5.138V25.77H4.631z"
        ])

    public static let lock = FlowIcon(
        viewBox: CGSize(width: 25, height: 32),
        paths: [
            "M21.333 10.667H19.81V7.619C19.81 3.429 16.38 0 12.19 0 8 0 4.571 3.429 4.571 7.619v3.048H3.048A3.056 3.056 0 000 13.714v15.238A3.056 3.056 0 003.048 32h18.285a3.056 3.056 0 003.048-3.048V13.714a3.056 3.056 0 00-3.048-3.047zM12.19 24.533a3.056 3.056 0 01-3.047-3.047 3.056 3.056 0 013.047-3.048 3.056 3.056 0 013.048 3.048 3.056 3.056 0 01-3.048 3.047zm4.724-13.866H7.467V7.619c0-2.59 2.133-4.724 4.723-4.724 2.591 0 4.724 2.133 4.724 4.724v3.048z"
        ])

    public static let unlock = FlowIcon(
        viewBox: CGSize(width: 25, height: 32),
        paths: [
            "M21.333 10.667H19.81V7.619C19.81 3.429 16.38 0 12.19 0c-4.114 1.828-1.37 2.133.305 2.438 1.676.305 4.42 2.59 4.42 5.181v3.048H3.047A3.056 3.056 0 000 13.714v15.238A3.056 3.056 0 003.048 32h18.285a3.056 3.056 0 003.048-3.048V13.714a3.056 3.056 0 00-3.048-3.047zM12.19 24.533a3.056 3.056 0 01-3.047-3.047 3.056 3.056 0 013.047-3.048 3.056 3.056 0 013.048 3.048 3.056 3.056 0 01-3.048 3.047z"
        ])
}

/// A glyph, drawn in the tint color of the view. It is as big as fits in a square of `maxSide`.
public final class FlowIconView: UIView {
    public var icon: FlowIcon {
        didSet { rebuild() }
    }

    /// `max-width: 12px; max-height: 12px`
    public var maxSide: CGFloat = 12 {
        didSet { setNeedsLayout() }
    }

    private var shapeLayers: [CAShapeLayer] = []

    public init(icon: FlowIcon) {
        self.icon = icon
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        rebuild()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func rebuild() {
        shapeLayers.forEach { $0.removeFromSuperlayer() }

        shapeLayers = icon.paths.map { path in
            let shape = CAShapeLayer()
            shape.path = SVGPath.cgPath(from: path)
            if let strokeWidth = icon.strokeWidth {
                shape.lineWidth = CGFloat(strokeWidth)
                shape.lineCap = .round
                shape.lineJoin = .round
            }
            layer.addSublayer(shape)
            return shape
        }

        applyTint()

        setNeedsLayout()
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        applyTint()
    }

    /// `fill: currentColor` and `stroke: currentColor`
    private func applyTint() {
        for shape in shapeLayers {
            shape.fillColor = icon.fills ? tintColor.cgColor : nil
            shape.strokeColor = icon.strokeWidth != nil ? tintColor.cgColor : nil
        }
    }

    private var fittedSize: CGSize {
        guard icon.viewBox.width > 0, icon.viewBox.height > 0 else { return .zero }

        let scale = min(maxSide / icon.viewBox.width, maxSide / icon.viewBox.height)
        return CGSize(width: icon.viewBox.width * scale, height: icon.viewBox.height * scale)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        fittedSize
    }

    public override var intrinsicContentSize: CGSize {
        fittedSize
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        guard icon.viewBox.width > 0, icon.viewBox.height > 0 else { return }

        let scale = bounds.width / icon.viewBox.width
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for shape in shapeLayers {
            shape.frame = .zero
            shape.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
        }
        CATransaction.commit()
    }
}

/// `ControlButton.svelte`: a button of the controls.
public final class ControlButton: UIControl {
    /// What the button looks like, as the properties of the component say it: colors of a style
    /// declaration, like `#fff` or `rgb(0, 0, 0)`.
    public var bgColor: String? { didSet { refresh() } }
    public var bgColorHover: String? { didSet { refresh() } }
    public var color: String? { didSet { refresh() } }
    public var colorHover: String? { didSet { refresh() } }
    public var borderColor: String? { didSet { refresh() } }

    /// Called when the button is tapped.
    public var onClick: (() -> Void)?

    /// Called when a pointer comes over the button, and when it leaves it.
    public var onHover: ((Bool) -> Void)?

    /// What is in the button, centered. The tint color of the button is the color of the content.
    public private(set) var contentView: UIView?

    enum Separator {
        case none
        case bottom
        case right
    }

    var separator: Separator = .none {
        didSet { setNeedsLayout() }
    }

    private let separatorLayer = CALayer()
    private var isHovered = false

    public override var isEnabled: Bool {
        didSet { refresh() }
    }

    public init(icon: FlowIcon? = nil) {
        super.init(frame: .zero)

        flowClasses = ["svelte-flow__controls-button", FlowClass.noPan]
        layer.addSublayer(separatorLayer)
        isAccessibilityElement = true
        accessibilityTraits = .button

        if let icon {
            setContent(FlowIconView(icon: icon))
        }

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        addGestureRecognizer(UIHoverGestureRecognizer(target: self, action: #selector(hovered(_:))))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public func setContent(_ view: UIView) {
        contentView?.removeFromSuperview()
        addSubview(view)
        contentView = view
        setNeedsLayout()
        refresh()
    }

    @objc private func tapped() {
        onClick?()
    }

    @objc private func hovered(_ recognizer: UIHoverGestureRecognizer) {
        let hovering: Bool
        switch recognizer.state {
        case .began, .changed:
            hovering = true
        default:
            hovering = false
        }

        if hovering != isHovered {
            isHovered = hovering
            onHover?(hovering)
        }
        refresh()
    }

    /// The style the button reads its colors from: the style of the flow and the props of the button.
    func applyStyle() {
        refresh()
    }

    private var parentScope: FlowStyleScope {
        (superview as? ControlsView)?.flow?.rootScope() ?? FlowStyleScope(properties: FlowTheme.light)
    }

    func refresh() {
        var properties: [String: String] = [:]
        if let bgColor { properties["--xy-controls-button-background-color-props"] = bgColor }
        if let bgColorHover { properties["--xy-controls-button-background-color-hover-props"] = bgColorHover }
        if let color { properties["--xy-controls-button-color-props"] = color }
        if let colorHover { properties["--xy-controls-button-color-hover-props"] = colorHover }
        if let borderColor { properties["--xy-controls-button-border-color-props"] = borderColor }

        let scope = FlowStyleScope(parent: parentScope, properties: properties)

        let background: FlowColor?
        let foreground: FlowColor?

        if isHovered && isEnabled {
            background = scope.color([
                "--xy-controls-button-background-color-hover-props",
                "--xy-controls-button-background-color-hover",
                "--xy-controls-button-background-color-hover-default"
            ])
            foreground = scope.color([
                "--xy-controls-button-color-hover-props",
                "--xy-controls-button-color-hover",
                "--xy-controls-button-color-hover-default"
            ])
        } else {
            background = scope.color([
                "--xy-controls-button-background-color-props",
                "--xy-controls-button-background-color",
                "--xy-controls-button-background-color-default"
            ])
            foreground = scope.color([
                "--xy-controls-button-color-props",
                "--xy-controls-button-color",
                "--xy-controls-button-color-default"
            ])
        }

        backgroundColor = background?.uiColor ?? .clear

        let resolvedForeground = (foreground ?? scope.inheritedColor()).map { $0.uiColor } ?? UIColor.label
        tintColor = resolvedForeground
        // `:disabled svg { fill-opacity: 0.4 }`
        contentView?.alpha = isEnabled ? 1 : 0.4

        separatorLayer.backgroundColor = scope.color([
            "--xy-controls-button-border-color-props",
            "--xy-controls-button-border-color",
            "--xy-controls-button-border-color-default"
        ])?.uiColor.cgColor
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        // `padding: 4px`; the content is centered in what is left
        var inner = bounds.insetBy(dx: 4, dy: 4)
        switch separator {
        case .bottom: inner.size.height -= 1
        case .right: inner.size.width -= 1
        case .none: break
        }

        if let contentView {
            // bounds and center, so the content can be rotated
            let size = contentView.sizeThatFits(inner.size)
            contentView.bounds = CGRect(origin: .zero, size: size)
            contentView.center = CGPoint(x: inner.midX, y: inner.midY)
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        switch separator {
        case .none:
            separatorLayer.isHidden = true
        case .bottom:
            separatorLayer.isHidden = false
            separatorLayer.frame = CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1)
        case .right:
            separatorLayer.isHidden = false
            separatorLayer.frame = CGRect(x: bounds.width - 1, y: 0, width: 1, height: bounds.height)
        }
        CATransaction.commit()
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: 26, height: 26)
    }
}

public enum ControlsOrientation {
    case vertical
    case horizontal
}

/// `Controls.svelte`: buttons to zoom in and out, to fit the view and to lock the flow.
public final class ControlsView: FlowPanelView {
    public var showZoom = true { didSet { rebuild() } }
    public var showFitView = true { didSet { rebuild() } }
    public var showLock = true { didSet { rebuild() } }
    public var orientation: ControlsOrientation = .vertical {
        didSet {
            setNeedsLayout()
            updateSeparators()
        }
    }
    public var fitViewOptions: FitViewOptions?

    public var buttonBgColor: String? { didSet { applyButtonProps() } }
    public var buttonBgColorHover: String? { didSet { applyButtonProps() } }
    public var buttonColor: String? { didSet { applyButtonProps() } }
    public var buttonColorHover: String? { didSet { applyButtonProps() } }
    public var buttonBorderColor: String? { didSet { applyButtonProps() } }

    /// Buttons that are put before the buttons of the controls.
    public private(set) var leadingButtons: [ControlButton] = []
    /// Buttons that are put after the buttons of the controls: what is in the default slot.
    public private(set) var trailingButtons: [ControlButton] = []

    private let zoomInButton = ControlButton(icon: .plus)
    private let zoomOutButton = ControlButton(icon: .minus)
    private let fitViewButton = ControlButton(icon: .fit)
    private let lockButton = ControlButton(icon: .lock)
    private var subscriptions: [Unsubscribe] = []
    private var visibleButtons: [ControlButton] = []
    private var lockShowsInteractive: Bool?

    public init(position: PanelPosition = .bottomLeft, orientation: ControlsOrientation = .vertical) {
        self.orientation = orientation
        super.init(position: position)

        flowClasses = ["svelte-flow__panel", "svelte-flow__controls"]

        zoomInButton.accessibilityLabel = "zoom in"
        zoomOutButton.accessibilityLabel = "zoom out"
        fitViewButton.accessibilityLabel = "fit view"
        lockButton.accessibilityLabel = "toggle interactivity"

        zoomInButton.onClick = { [weak self] in self?.flow?.store.zoomIn() }
        zoomOutButton.onClick = { [weak self] in self?.flow?.store.zoomOut() }
        fitViewButton.onClick = { [weak self] in
            guard let self else { return }
            self.flow?.store.fitView(self.fitViewOptions)
        }
        lockButton.onClick = { [weak self] in self?.toggleInteractivity() }

        rebuild()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscriptions.forEach { $0() }
    }

    // MARK: Buttons

    /// Puts a button after the others (the default slot).
    public func addButton(_ button: ControlButton) {
        trailingButtons.append(button)
        rebuild()
    }

    /// Puts a button before the others.
    public func addLeadingButton(_ button: ControlButton) {
        leadingButtons.append(button)
        rebuild()
    }

    private func rebuild() {
        let previous = Set(visibleButtons.map { ObjectIdentifier($0) })

        var buttons = leadingButtons
        if showZoom { buttons += [zoomInButton, zoomOutButton] }
        if showFitView { buttons.append(fitViewButton) }
        if showLock { buttons.append(lockButton) }
        buttons += trailingButtons

        let next = Set(buttons.map { ObjectIdentifier($0) })

        for button in visibleButtons where !next.contains(ObjectIdentifier(button)) {
            button.removeFromSuperview()
        }

        for button in buttons where !previous.contains(ObjectIdentifier(button)) {
            addSubview(button)
        }

        visibleButtons = buttons
        applyButtonProps()
        updateSeparators()
        refreshState()
        setNeedsLayout()
        superview?.setNeedsLayout()
    }

    private func applyButtonProps() {
        for button in [zoomInButton, zoomOutButton, fitViewButton, lockButton] {
            button.bgColor = buttonBgColor
            button.bgColorHover = buttonBgColorHover
            button.color = buttonColor
            button.colorHover = buttonColorHover
            button.borderColor = buttonBorderColor
        }
    }

    /// `border-bottom` of every button but the last one, or `border-right` when the controls are horizontal.
    private func updateSeparators() {
        for (index, button) in visibleButtons.enumerated() {
            if index == visibleButtons.count - 1 {
                button.separator = .none
            } else {
                button.separator = orientation == .horizontal ? .right : .bottom
            }
        }
    }

    // MARK: Following the flow

    public override func attach(to flow: SwiftFlow) {
        subscriptions.forEach { $0() }
        subscriptions = []

        let store = flow.store
        subscriptions.append(store.viewport.subscribeAny { [weak self] in self?.refreshState() })
        subscriptions.append(store.minZoom.subscribeAny { [weak self] in self?.refreshState() })
        subscriptions.append(store.maxZoom.subscribeAny { [weak self] in self?.refreshState() })
        subscriptions.append(store.nodesDraggable.subscribeAny { [weak self] in self?.refreshState() })
        subscriptions.append(store.nodesConnectable.subscribeAny { [weak self] in self?.refreshState() })
        subscriptions.append(store.elementsSelectable.subscribeAny { [weak self] in self?.refreshState() })
        subscriptions.append(store.selectionRectMode.subscribeAny { [weak self] in
            // `pointer-events: none` while there is a selection
            self?.isUserInteractionEnabled = store.selectionRectMode.get() == nil
        })

        themeDidChange()
        refreshState()
    }

    public override func themeDidChange() {
        visibleButtons.forEach { $0.refresh() }

        guard let scope = flow?.rootScope() else { return }

        if let shadow = scope.shadow(["--xy-controls-box-shadow", "--xy-controls-box-shadow-default"]) {
            layer.shadowColor = shadow.color.uiColor.cgColor
            layer.shadowOpacity = 1
            layer.shadowOffset = CGSize(width: shadow.offsetX, height: shadow.offsetY)
            layer.shadowRadius = CGFloat(shadow.blur / 2)
            layer.shadowPath = UIBezierPath(
                rect: bounds.insetBy(dx: -CGFloat(shadow.spread), dy: -CGFloat(shadow.spread))).cgPath
        } else {
            layer.shadowOpacity = 0
        }
    }

    private func refreshState() {
        guard let store = flow?.store else { return }

        let zoom = store.viewport.get().zoom
        zoomInButton.isEnabled = !(zoom >= store.maxZoom.get())
        zoomOutButton.isEnabled = !(zoom <= store.minZoom.get())

        let isInteractive = store.nodesDraggable.get() || store.nodesConnectable.get() || store.elementsSelectable.get()
        if lockShowsInteractive != isInteractive {
            lockShowsInteractive = isInteractive
            lockButton.setContent(FlowIconView(icon: isInteractive ? .unlock : .lock))
        }
    }

    private func toggleInteractivity() {
        guard let store = flow?.store else { return }

        let isInteractive = !(store.nodesDraggable.get() || store.nodesConnectable.get() || store.elementsSelectable.get())

        store.nodesDraggable.set(isInteractive)
        store.nodesConnectable.set(isInteractive)
        store.elementsSelectable.set(isInteractive)
    }

    // MARK: Layout

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let count = CGFloat(visibleButtons.count)

        switch orientation {
        case .vertical:
            return CGSize(width: count == 0 ? 0 : 26, height: count * 26)
        case .horizontal:
            return CGSize(width: count * 26, height: count == 0 ? 0 : 26)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        for (index, button) in visibleButtons.enumerated() {
            switch orientation {
            case .vertical:
                button.frame = CGRect(x: 0, y: CGFloat(index) * 26, width: 26, height: 26)
            case .horizontal:
                button.frame = CGRect(x: CGFloat(index) * 26, y: 0, width: 26, height: 26)
            }
        }

        themeDidChange()
    }
}
#endif
