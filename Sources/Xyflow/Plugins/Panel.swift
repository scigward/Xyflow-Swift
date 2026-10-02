#if canImport(UIKit)
import UIKit
import XYSystem

/// A view that is added to a flow with `add(_:)`: the controls, the background, the minimap and the like.
/// It is told about the flow it is added to, and when the style of the flow changes.
open class FlowPluginView: UIView {
    /// The flow the view is added to, as long as it is part of it.
    public internal(set) weak var flow: SwiftFlow?

    /// Whether the view is the ground of the flow, which everything else is drawn above (`z-index: -1`).
    open var isBackdrop: Bool { false }

    /// Called once the view is added to a flow, with the flow the view is in.
    open func attach(to flow: SwiftFlow) {}

    /// Called when the colors of the flow changed, which is when its color mode or its style did.
    open func themeDidChange() {}
}

/// `Panel.svelte`: a view that sits on a side or a corner of the flow, `15` points from it.
open class FlowPanelView: FlowPluginView {
    /// Where the panel is.
    public var position: PanelPosition {
        didSet {
            if position != oldValue { superview?.setNeedsLayout() }
        }
    }

    /// The space around the panel, `margin: 15px`.
    public var margin: CGFloat = 15 {
        didSet {
            if margin != oldValue { superview?.setNeedsLayout() }
        }
    }

    public init(position: PanelPosition = .topRight) {
        self.position = position
        super.init(frame: .zero)
        flowClasses = ["svelte-flow__panel"]
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// The size the panel has. By default that is the size of its subviews.
    open func panelSize(fitting container: CGSize) -> CGSize {
        sizeThatFits(container)
    }

    /// Puts the panel where its position says, in the bounds of the flow.
    func place(in container: CGRect) {
        let size = panelSize(fitting: container.size)
        var x: CGFloat
        var y: CGFloat

        switch position {
        case .topLeft, .centerLeft, .bottomLeft:
            x = container.minX + margin
        case .topRight, .centerRight, .bottomRight:
            x = container.maxX - margin - size.width
        case .topCenter, .bottomCenter:
            x = container.minX + (container.width - size.width) / 2
        }

        switch position {
        case .topLeft, .topCenter, .topRight:
            y = container.minY + margin
        case .bottomLeft, .bottomCenter, .bottomRight:
            y = container.maxY - margin - size.height
        case .centerLeft, .centerRight:
            y = container.minY + (container.height - size.height) / 2
        }

        frame = CGRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height)
    }
}

/// `Attribution.svelte`: the name of the library, in the corner of the flow.
final class AttributionView: FlowPanelView {
    private let label = UILabel()
    private let padding = UIEdgeInsets(top: 2, left: 3, bottom: 2, right: 3)

    override init(position: PanelPosition = .bottomRight) {
        super.init(position: position)

        margin = 0
        flowClasses = ["svelte-flow__panel", "svelte-flow__attribution"]

        label.text = "Swift Flow"
        label.font = .systemFont(ofSize: 10)
        label.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func attach(to flow: SwiftFlow) {
        themeDidChange()
    }

    override func themeDidChange() {
        guard let scope = flow?.rootScope() else { return }

        backgroundColor = scope.color([
            "--xy-attribution-background-color", "--xy-attribution-background-color-default"
        ])?.uiColor ?? .clear
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let text = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(
            width: ceil(text.width) + padding.left + padding.right,
            height: ceil(text.height) + padding.top + padding.bottom)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds.inset(by: padding)
    }
}
#endif
