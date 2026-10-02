#if canImport(UIKit)
import UIKit
import XYSystem

/// What the node views that ship with the flow have in common: the color of their text, which the
/// node that holds them takes from its style.
protocol BuiltInNodeContent: AnyObject {
    var textColor: UIColor { get set }
}

/// The nodes of the types `default`, `input` and `output`: the label of the node, with the handles it needs.
open class LabelNodeView: UIView, FlowNodeComponent, BuiltInNodeContent {
    public let label = UILabel()
    public private(set) var targetHandle: HandleView?
    public private(set) var sourceHandle: HandleView?

    private let inset: CGFloat = 10

    var textColor: UIColor {
        get { label.textColor }
        set { label.textColor = newValue }
    }

    public init(target: Bool, source: Bool) {
        super.init(frame: .zero)

        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        addSubview(label)

        if target {
            let handle = HandleView(type: .target, position: .top)
            addSubview(handle)
            targetHandle = handle
        }

        if source {
            let handle = HandleView(type: .source, position: .bottom)
            addSubview(handle)
            sourceHandle = handle
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public func update(props: NodeProps) {
        label.text = LabelNodeView.text(of: props.data["label"])

        targetHandle?.position = props.targetPosition ?? .top
        sourceHandle?.position = props.sourcePosition ?? .bottom
        setNeedsLayout()
    }

    static func text(of value: Any?) -> String {
        guard let value else { return "" }
        if let text = value as? String { return text }
        if let number = value as? Double { return formatNumber(number) }
        return String(describing: value)
    }

    /// The label wraps at the width of the node, with the padding of the node (`padding: 10px`) around it.
    public func preferredSize(width: Double?, height: Double?) -> CGSize? {
        let fixedWidth = width.map { CGFloat($0) }
        let available = max(0, (fixedWidth ?? CGFloat.greatestFiniteMagnitude) - inset * 2)
        let fitted = label.text?.isEmpty == false
            ? label.sizeThatFits(CGSize(width: available, height: CGFloat.greatestFiniteMagnitude))
            : .zero

        return CGSize(
            width: fixedWidth ?? ceil(fitted.width) + inset * 2,
            height: ceil(fitted.height) + inset * 2)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds.insetBy(dx: inset, dy: inset)
    }
}

public final class DefaultNodeView: LabelNodeView {
    public init() {
        super.init(target: true, source: true)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

public final class InputNodeView: LabelNodeView {
    public init() {
        super.init(target: false, source: true)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

public final class OutputNodeView: LabelNodeView {
    public init() {
        super.init(target: true, source: false)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

/// `GroupNode.svelte`: nothing but the box of the node, which is as big as it is told to be.
public final class GroupNodeView: UIView, FlowNodeComponent, BuiltInNodeContent {
    var textColor: UIColor = .label

    public init() {
        super.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public func update(props: NodeProps) {}

    public func preferredSize(width: Double?, height: Double?) -> CGSize? {
        CGSize(width: width ?? 0, height: height ?? 0)
    }
}
#endif
