#if canImport(UIKit)
import UIKit
import XYSystem

public enum BackgroundVariant: String {
    case lines
    case dots
    case cross
}

/// `Background.svelte`: a pattern of dots, lines or crosses behind the flow, which moves and scales with
/// the viewport.
public final class BackgroundView: FlowPluginView {
    public var id: String?

    /// The pattern that is drawn.
    public var variant: BackgroundVariant = .dots {
        didSet { themeDidChange() }
    }

    /// The gap between repetitions of the pattern, for x and for y.
    public var gap: (x: Double, y: Double) = (20, 20) {
        didSet { setNeedsDisplay() }
    }

    /// The size of a single pattern element.
    public var size: Double = 1 {
        didSet { setNeedsDisplay() }
    }

    /// The width of the lines of the lines pattern.
    public var lineWidth: Double = 1 {
        didSet { setNeedsDisplay() }
    }

    /// The color of the background, a color of a style declaration (`black`, `#111`, `rgb(...)`).
    public var bgColor: String? {
        didSet { themeDidChange() }
    }

    /// The color of the pattern.
    public var patternColor: String? {
        didSet { themeDidChange() }
    }

    private var subscription: Unsubscribe?
    private var patternUIColor: UIColor = .clear

    public override var isBackdrop: Bool { true }

    public init(
        variant: BackgroundVariant = .dots,
        gap: Double = 20,
        size: Double = 1,
        lineWidth: Double = 1,
        bgColor: String? = nil,
        patternColor: String? = nil
    ) {
        self.variant = variant
        self.gap = (gap, gap)
        self.size = size
        self.lineWidth = lineWidth
        self.bgColor = bgColor
        self.patternColor = patternColor
        super.init(frame: .zero)

        flowClasses = ["svelte-flow__background"]
        isUserInteractionEnabled = false
        isOpaque = false
        contentMode = .redraw
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscription?()
    }

    public override func attach(to flow: SwiftFlow) {
        subscription?()
        subscription = flow.store.viewport.subscribeAny { [weak self] in
            self?.setNeedsDisplay()
        }

        themeDidChange()
    }

    public override func themeDidChange() {
        guard let flow else { return }

        // the colors of the props are custom properties of the element itself
        var properties: [String: String] = [:]
        if let bgColor { properties["--xy-background-color-props"] = bgColor }
        if let patternColor { properties["--xy-background-pattern-color-props"] = patternColor }

        let scope = FlowStyleScope(parent: flow.rootScope(), properties: properties)

        backgroundColor = scope.color([
            "--xy-background-color", "--xy-background-color-props", "--xy-background-color-default"
        ])?.uiColor ?? .clear

        patternUIColor = scope.color([
            "--xy-background-pattern-color-props",
            "--xy-background-pattern-color",
            "--xy-background-pattern-\(variant.rawValue)-color-default"
        ])?.uiColor ?? .clear

        setNeedsDisplay()
    }

    public override func draw(_ rect: CGRect) {
        guard let flow, let context = UIGraphicsGetCurrentContext() else { return }

        let viewport = flow.store.viewport.get()
        let zoom = viewport.zoom

        // `gap * zoom || 1`
        func scaled(_ value: Double) -> Double {
            let result = value * zoom
            return result == 0 || result.isNaN ? 1 : result
        }

        let gapX = scaled(gap.x)
        let gapY = scaled(gap.y)
        let patternSize = size == 0 ? 1 : size
        let scaledSize = patternSize * zoom

        // the pattern starts where the viewport is, and repeats
        let originX = viewport.x.truncatingRemainder(dividingBy: gapX)
        let originY = viewport.y.truncatingRemainder(dividingBy: gapY)

        let firstColumn = Int((-originX / gapX).rounded(.up))
        let lastColumn = Int(((Double(bounds.width) - originX) / gapX).rounded(.down))
        let firstRow = Int((-originY / gapY).rounded(.up))
        let lastRow = Int(((Double(bounds.height) - originY) / gapY).rounded(.down))

        let columns = max(0, lastColumn - firstColumn + 1)
        let rows = max(0, lastRow - firstRow + 1)

        // a pattern that is too dense to see is not drawn
        guard columns > 0, rows > 0, columns * rows <= 40_000 else { return }

        context.setFillColor(patternUIColor.cgColor)
        context.setStrokeColor(patternUIColor.cgColor)

        switch variant {
        case .dots:
            let radius = scaledSize / 2

            for column in firstColumn...lastColumn {
                let x = originX + Double(column) * gapX

                for row in firstRow...lastRow {
                    let y = originY + Double(row) * gapY
                    context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                }
            }
        case .lines:
            context.setLineWidth(CGFloat(lineWidth))
            context.beginPath()

            for column in firstColumn...lastColumn {
                let x = originX + Double(column) * gapX
                context.move(to: CGPoint(x: CGFloat(x), y: bounds.minY))
                context.addLine(to: CGPoint(x: CGFloat(x), y: bounds.maxY))
            }

            for row in firstRow...lastRow {
                let y = originY + Double(row) * gapY
                context.move(to: CGPoint(x: bounds.minX, y: CGFloat(y)))
                context.addLine(to: CGPoint(x: bounds.maxX, y: CGFloat(y)))
            }

            context.strokePath()
        case .cross:
            context.setLineWidth(CGFloat(lineWidth))
            context.beginPath()

            let half = scaledSize / 2

            for column in firstColumn...lastColumn {
                let x = originX + Double(column) * gapX

                for row in firstRow...lastRow {
                    let y = originY + Double(row) * gapY

                    context.move(to: CGPoint(x: x, y: y - half))
                    context.addLine(to: CGPoint(x: x, y: y + half))
                    context.move(to: CGPoint(x: x - half, y: y))
                    context.addLine(to: CGPoint(x: x + half, y: y))
                }
            }

            context.strokePath()
        }
    }
}
#endif
