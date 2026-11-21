#if canImport(UIKit)
import UIKit
import XYSystem

/// `.svelte-flow__edge-label`: the text of an edge, in a box that sits on the middle of it.
public final class EdgeLabelView: UIView, FlowClickable {
    /// Called when the label is clicked, which selects the edge it belongs to.
    public var onSelect: (() -> Void)?

    public let textLabel = UILabel()
    private let padding: CGFloat = 2

    public override init(frame: CGRect) {
        super.init(frame: frame)

        // EdgeLabel.svelte 1.7.1 keeps labels clickable but does not suppress canvas gestures.
        flowClasses = ["svelte-flow__edge-label"]
        textLabel.font = .systemFont(ofSize: 10)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        addSubview(textLabel)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Puts the label with its text at the point of the flow it is on the middle of. The style is the
    /// `labelStyle` of the edge, which sits on top of the style of the flow.
    public func update(
        text: String,
        x: Double,
        y: Double,
        style: String?,
        scope: FlowStyleScope,
        font: (CGFloat, UIFont.Weight) -> UIFont = { UIFont.systemFont(ofSize: $0, weight: $1) },
        lineHeight: (CGFloat) -> CGFloat? = { _ in nil }
    ) {
        let inline = FlowCSS.declarationMap(style)
        let labelScope = FlowStyleScope(parent: scope, properties: inline)

        var color = labelScope.color(["--xy-edge-label-color", "--xy-edge-label-color-default"])
        if let declared = labelScope.resolvedColor(inline["color"]) {
            color = declared
        }

        var background = labelScope.color([
            "--xy-edge-label-background-color", "--xy-edge-label-background-color-default"
        ])
        if let declared = labelScope.resolvedColor(inline["background-color"] ?? inline["background"]) {
            background = declared
        }

        let fontSize = labelScope.resolvedNumber(inline["font-size"]) ?? 10
        let weight: UIFont.Weight = {
            switch inline["font-weight"] {
            case "bold", "700": return .bold
            case "600": return .semibold
            case "500": return .medium
            default: return .regular
            }
        }()

        let labelFont = font(CGFloat(fontSize), weight)
        let textColor = (color ?? labelScope.inheritedColor()).map { $0.uiColor } ?? .label
        backgroundColor = background?.uiColor ?? .clear

        // the label inherits the `line-height` of the page, and the glyphs sit in the middle of the line box
        let boxHeight = lineHeight(CGFloat(fontSize))
        if let boxHeight {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.minimumLineHeight = boxHeight
            paragraph.maximumLineHeight = boxHeight
            textLabel.attributedText = NSAttributedString(string: text, attributes: [
                .font: labelFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraph,
                .baselineOffset: (boxHeight - labelFont.lineHeight) / 2
            ])
        } else {
            textLabel.attributedText = nil
            textLabel.font = labelFont
            textLabel.text = text
            textLabel.textColor = textColor
        }

        let fitted = textLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        let size = CGSize(
            width: ceil(fitted.width) + padding * 2,
            height: (boxHeight ?? ceil(fitted.height)) + padding * 2)

        // `transform: translate(-50%, -50%) translate(x, y)`: the middle of the box is on the point
        bounds = CGRect(origin: .zero, size: size)
        center = CGPoint(x: x, y: y)
        textLabel.frame = bounds.insetBy(dx: padding, dy: padding)
    }

    func flowClick(event: FlowPointerEvent) {
        onSelect?()
    }
}
#endif
