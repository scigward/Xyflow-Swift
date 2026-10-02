#if canImport(UIKit)
import UIKit
import XYSystem

/// What every edge is made of: the path, the markers at its ends, the invisible path around it that
/// makes it easy to hit, and its label. The edge types that ship with the flow, and custom edges,
/// draw themselves with it.
public final class BaseEdge {
    /// What the edge draws, in the coordinates of the flow.
    public let layer = CALayer()

    public private(set) var labelView: EdgeLabelView?

    /// The views the edge needs in the label layer of the flow.
    public var labelViews: [UIView] {
        labelView.map { [$0] } ?? []
    }

    private let pathLayer = CAShapeLayer()
    private var markerLayers: [CAShapeLayer] = []
    private var currentPath: String?
    private var cgPath: CGPath = CGMutablePath()
    private var ends: SVGPathEnds?
    private var hitPath: CGPath?
    private var hitWidth: Double = 20
    private var strokeWidth: Double = 1
    private var markerKey: String?

    public init() {
        pathLayer.fillColor = nil
        layer.addSublayer(pathLayer)
    }

    /// Draws the edge: `path` is the path data of the edge, and the label sits at `labelX` and `labelY`.
    public func update(
        path: String,
        labelX: Double?,
        labelY: Double?,
        props: EdgeProps,
        context: EdgeRenderContext
    ) {
        let scope = FlowStyleScope(parent: context.styleScope, style: props.style)
        let inline = FlowCSS.declarationMap(props.style)

        if path != currentPath {
            currentPath = path
            cgPath = SVGPath.cgPath(from: path)
            ends = SVGPath.ends(of: cgPath)
            pathLayer.path = cgPath
            hitPath = nil
            markerKey = nil
        }

        updateStroke(props: props, scope: scope, inline: inline)

        hitWidth = props.interactionWidth ?? 20
        hitPath = nil

        updateMarkers(props: props, context: context)
        updateLabel(props: props, labelX: labelX, labelY: labelY, context: context)
    }

    // MARK: Stroke

    private func updateStroke(props: EdgeProps, scope: FlowStyleScope, inline: [String: String]) {
        // `.svelte-flow__edge-path` and `.selected .svelte-flow__edge-path`, under the style of the edge
        var stroke = scope.color(props.selected
            ? ["--xy-edge-stroke-selected", "--xy-edge-stroke-selected-default"]
            : ["--xy-edge-stroke", "--xy-edge-stroke-default"])

        if let declared = inline["stroke"] {
            stroke = declared.lowercased() == "none" ? nil : (scope.resolvedColor(declared) ?? stroke)
        }

        var width = scope.number(["--xy-edge-stroke-width", "--xy-edge-stroke-width-default"]) ?? 1
        if let declared = scope.resolvedNumber(inline["stroke-width"]) {
            width = declared
        }

        if let opacity = inline["stroke-opacity"].flatMap({ Double($0) }), let color = stroke {
            stroke = color.withAlpha(color.alpha * min(1, max(0, opacity)))
        }

        strokeWidth = width
        pathLayer.strokeColor = stroke?.uiColor.cgColor
        pathLayer.lineWidth = CGFloat(width)
        pathLayer.opacity = Float(inline["opacity"].flatMap { Double($0) } ?? 1)

        switch inline["stroke-linecap"] {
        case "round": pathLayer.lineCap = .round
        case "square": pathLayer.lineCap = .square
        default: pathLayer.lineCap = .butt
        }

        switch inline["stroke-linejoin"] {
        case "round": pathLayer.lineJoin = .round
        case "bevel": pathLayer.lineJoin = .bevel
        default: pathLayer.lineJoin = .miter
        }

        // `.animated path { stroke-dasharray: 5; animation: dashdraw 0.5s linear infinite }`
        var dashes: [Double]?
        if let declared = inline["stroke-dasharray"] {
            dashes = FlowCSS.parseNumberList(declared)
        } else if props.animated {
            dashes = [5]
        }

        if let list = dashes, list.contains(where: { $0 > 0 }) {
            let pattern = list.count % 2 == 1 ? list + list : list
            pathLayer.lineDashPattern = pattern.map { NSNumber(value: $0) }
        } else {
            dashes = nil
            pathLayer.lineDashPattern = nil
        }

        pathLayer.lineDashPhase = CGFloat(inline["stroke-dashoffset"].flatMap { FlowCSS.parseLength($0) } ?? 0)

        if props.animated && dashes != nil {
            if pathLayer.animation(forKey: "dashdraw") == nil {
                let animation = CABasicAnimation(keyPath: "lineDashPhase")
                animation.fromValue = 10
                animation.toValue = 0
                animation.duration = 0.5
                animation.repeatCount = .infinity
                animation.timingFunction = CAMediaTimingFunction(name: .linear)
                pathLayer.add(animation, forKey: "dashdraw")
            }
        } else {
            pathLayer.removeAnimation(forKey: "dashdraw")
        }
    }

    // MARK: Markers

    private func updateMarkers(props: EdgeProps, context: EdgeRenderContext) {
        let start = props.markerStart.flatMap { id in context.markers.first { $0.id == id } }
        let end = props.markerEnd.flatMap { id in context.markers.first { $0.id == id } }

        let key = [
            start.map { "\($0.id)|\($0.marker.color ?? "")" } ?? "-",
            end.map { "\($0.id)|\($0.marker.color ?? "")" } ?? "-",
            "\(strokeWidth)",
            currentPath ?? ""
        ].joined(separator: "#")

        if key == markerKey {
            return
        }
        markerKey = key

        markerLayers.forEach { $0.removeFromSuperlayer() }
        markerLayers = []

        guard let ends else { return }

        if let start {
            markerLayers.append(makeMarker(start.marker, at: ends.start, angle: ends.startAngle, isStart: true, scope: context.styleScope))
        }

        if let end {
            markerLayers.append(makeMarker(end.marker, at: ends.end, angle: ends.endAngle, isStart: false, scope: context.styleScope))
        }

        markerLayers.forEach { layer.addSublayer($0) }
    }

    /// `Marker.svelte`: a marker with a 20 by 20 view box around the point it is at, which is scaled
    /// to its size and, by default, to the stroke width of the edge.
    private func makeMarker(
        _ marker: EdgeMarker,
        at vertex: CGPoint,
        angle: CGFloat,
        isStart: Bool,
        scope: FlowStyleScope
    ) -> CAShapeLayer {
        let width = marker.width ?? 12.5
        let height = marker.height ?? 12.5
        let unitScale = (marker.markerUnits ?? "strokeWidth") == "strokeWidth" ? strokeWidth : 1
        let scale = CGFloat(min(width, height) / 20 * unitScale)

        let orient = marker.orient ?? "auto-start-reverse"
        let rotation: CGFloat
        switch orient {
        case "auto":
            rotation = angle
        case "auto-start-reverse":
            rotation = isStart ? angle + .pi : angle
        default:
            let degrees = Double(orient.replacingOccurrences(of: "deg", with: "")) ?? 0
            rotation = CGFloat(degrees * Double.pi / 180)
        }

        let path = CGMutablePath()
        path.move(to: CGPoint(x: -5, y: -4))
        path.addLine(to: .zero)
        path.addLine(to: CGPoint(x: -5, y: 4))
        if marker.type == .arrowclosed {
            path.addLine(to: CGPoint(x: -5, y: -4))
        }

        let color = marker.color.flatMap { scope.resolvedColor($0) }

        let shape = CAShapeLayer()
        shape.path = path
        shape.strokeColor = color?.uiColor.cgColor
        shape.fillColor = marker.type == .arrowclosed ? color?.uiColor.cgColor : nil
        shape.lineWidth = CGFloat(marker.strokeWidth ?? 1)
        shape.lineCap = .round
        shape.lineJoin = .round
        shape.position = vertex
        shape.setAffineTransform(CGAffineTransform(rotationAngle: rotation).scaledBy(x: scale, y: scale))

        return shape
    }

    // MARK: Label

    private func updateLabel(props: EdgeProps, labelX: Double?, labelY: Double?, context: EdgeRenderContext) {
        guard let text = props.label, !text.isEmpty else {
            labelView?.removeFromSuperview()
            labelView = nil
            return
        }

        let view: EdgeLabelView
        if let existing = labelView {
            view = existing
        } else {
            view = EdgeLabelView()
            labelView = view
        }

        let edgeId = props.id
        let select = context.selectEdge
        view.onSelect = { select(edgeId) }
        view.update(text: text, x: labelX ?? 0, y: labelY ?? 0, style: props.labelStyle, scope: context.styleScope)
    }

    // MARK: Hit testing

    /// Whether a point of the flow is on the edge: within the interaction width of its path, or on
    /// its stroke when that is wider.
    public func contains(point: CGPoint) -> Bool {
        if hitPath == nil {
            let width = max(hitWidth, strokeWidth)
            hitPath = cgPath.copy(
                strokingWithWidth: CGFloat(width), lineCap: .butt, lineJoin: .miter, miterLimit: 10)
        }

        return hitPath?.contains(point) ?? false
    }
}
#endif
