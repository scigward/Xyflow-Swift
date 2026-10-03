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
        didSet { setNeedsLayout() }
    }

    /// The size of a single pattern element.
    public var size: Double = 1 {
        didSet { setNeedsLayout() }
    }

    /// The width of the lines of the lines pattern.
    public var lineWidth: Double = 1 {
        didSet { setNeedsLayout() }
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

    /// The pattern is drawn once into an image that is a gap larger than the flow on each side. The
    /// viewport then only moves the image, which costs nothing, and the image is drawn again when
    /// something that changes how it looks does: the zoom, the size, the colors.
    private let patternLayer = CALayer()
    private var patternKey: PatternKey?
    private var patternVersion = 0

    private struct PatternKey: Equatable {
        var variant: BackgroundVariant
        var zoom: Double
        var gapX: Double
        var gapY: Double
        var size: Double
        var lineWidth: Double
        var width: CGFloat
        var height: CGFloat
        var scale: CGFloat
        var version: Int
    }

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
        clipsToBounds = true

        patternLayer.anchorPoint = .zero
        patternLayer.isOpaque = false
        layer.addSublayer(patternLayer)
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
            // laid out once per frame, however often the viewport is set in it
            self?.setNeedsLayout()
        }

        themeDidChange()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updatePattern()
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

        patternVersion += 1
        setNeedsLayout()
    }

    private func updatePattern() {
        guard let flow, bounds.width > 0, bounds.height > 0 else { return }

        let viewport = flow.store.viewport.get()
        let zoom = viewport.zoom
        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 2

        // `gap * zoom || 1`
        func scaled(_ value: Double) -> Double {
            let result = value * zoom
            return result == 0 || result.isNaN ? 1 : result
        }

        let gapX = scaled(gap.x)
        let gapY = scaled(gap.y)

        // the pattern starts where the viewport is, and repeats: the grid point that is the closest to
        // the left and the top of the flow, and the one before it, which is where the image starts
        var originX = viewport.x.truncatingRemainder(dividingBy: gapX)
        var originY = viewport.y.truncatingRemainder(dividingBy: gapY)
        if originX < 0 { originX += gapX }
        if originY < 0 { originY += gapY }

        let columns = Int((Double(bounds.width) / gapX).rounded(.up)) + 1
        let rows = Int((Double(bounds.height) / gapY).rounded(.up)) + 1

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        // a pattern that is too dense to see is not drawn
        guard columns > 0, rows > 0, columns * rows <= 40_000 else {
            patternLayer.contents = nil
            patternKey = nil
            return
        }

        // the image is as many whole pixels as its size in points says, so it is not stretched
        let imageSize = CGSize(
            width: (CGFloat(Double(columns) * gapX) * scale).rounded(.up) / scale,
            height: (CGFloat(Double(rows) * gapY) * scale).rounded(.up) / scale)

        let key = PatternKey(
            variant: variant, zoom: zoom, gapX: gapX, gapY: gapY, size: size, lineWidth: lineWidth,
            width: bounds.width, height: bounds.height, scale: scale, version: patternVersion)

        if key != patternKey {
            patternKey = key
            patternLayer.contents = renderPattern(
                size: imageSize, columns: columns, rows: rows, gapX: gapX, gapY: gapY, zoom: zoom, scale: scale)
            patternLayer.contentsScale = scale
        }

        // moved by whole pixels, so the lines stay sharp
        func snapped(_ value: Double) -> CGFloat {
            (CGFloat(value) * scale).rounded() / scale
        }

        patternLayer.frame = CGRect(
            x: snapped(originX - gapX), y: snapped(originY - gapY),
            width: imageSize.width, height: imageSize.height)
    }

    private func renderPattern(
        size imageSize: CGSize,
        columns: Int,
        rows: Int,
        gapX: Double,
        gapY: Double,
        zoom: Double,
        scale: CGFloat
    ) -> CGImage? {
        let patternSize = size == 0 ? 1 : size
        let scaledSize = patternSize * zoom

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false

        let image = UIGraphicsImageRenderer(size: imageSize, format: format).image { rendererContext in
            let context = rendererContext.cgContext
            context.setFillColor(patternUIColor.cgColor)
            context.setStrokeColor(patternUIColor.cgColor)

            switch variant {
            case .dots:
                let radius = scaledSize / 2

                for column in 0...columns {
                    let x = Double(column) * gapX

                    for row in 0...rows {
                        let y = Double(row) * gapY
                        context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    }
                }
            case .lines:
                context.setLineWidth(CGFloat(lineWidth))
                context.beginPath()

                for column in 0...columns {
                    let x = CGFloat(Double(column) * gapX)
                    context.move(to: CGPoint(x: x, y: 0))
                    context.addLine(to: CGPoint(x: x, y: imageSize.height))
                }

                for row in 0...rows {
                    let y = CGFloat(Double(row) * gapY)
                    context.move(to: CGPoint(x: 0, y: y))
                    context.addLine(to: CGPoint(x: imageSize.width, y: y))
                }

                context.strokePath()
            case .cross:
                context.setLineWidth(CGFloat(lineWidth))
                context.beginPath()

                let half = scaledSize / 2

                for column in 0...columns {
                    let x = Double(column) * gapX

                    for row in 0...rows {
                        let y = Double(row) * gapY

                        context.move(to: CGPoint(x: x, y: y - half))
                        context.addLine(to: CGPoint(x: x, y: y + half))
                        context.move(to: CGPoint(x: x - half, y: y))
                        context.addLine(to: CGPoint(x: x + half, y: y))
                    }
                }

                context.strokePath()
            }
        }

        return image.cgImage
    }

}
#endif
