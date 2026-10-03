#if canImport(UIKit)
import UIKit
import XYSystem

/// Draws a connection line of your own while a connection is made, instead of the path of the flow.
/// The view is told the connection every time it changes, and it sits in the coordinates of the flow.
public protocol FlowConnectionLineComponent: AnyObject {
    func update(connection: ConnectionState)
}

public typealias ConnectionLineComponentFactory = () -> (UIView & FlowConnectionLineComponent)

/// `ConnectionLine.svelte`: the line from the handle a connection starts at to the pointer, drawn
/// while the connection is in progress.
final class ConnectionLineView: FlowPassthroughView {
    private let store: SwiftFlowStore
    private let pathLayer = CAShapeLayer()
    private var subscriptions: [Unsubscribe] = []
    private var customView: (UIView & FlowConnectionLineComponent)?

    /// What the path of the line is styled with (`connectionLineStyle`).
    var style: String = "" {
        didSet { if style != oldValue { update() } }
    }

    /// `connectionLineContainerStyle`: the style of the box the line is in.
    var containerStyle: String = "" {
        didSet { if containerStyle != oldValue { update() } }
    }

    /// A view that draws the line instead of the path.
    var customComponent: ConnectionLineComponentFactory? {
        didSet {
            customView?.removeFromSuperview()
            customView = nil
            update()
        }
    }

    /// What the line reads its style from.
    var styleScope: () -> FlowStyleScope = { FlowStyleScope(properties: FlowTheme.light) }

    init(store: SwiftFlowStore) {
        self.store = store
        super.init(frame: .zero)

        flowClasses = ["svelte-flow__connectionline"]
        isUserInteractionEnabled = false
        isHidden = true

        pathLayer.fillColor = nil
        layer.addSublayer(pathLayer)

        subscriptions.append(store.connection.subscribeAny { [weak self] in self?.update() })
        subscriptions.append(store.connectionLineType.subscribeAny { [weak self] in self?.update() })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscriptions.forEach { $0() }
    }

    func update() {
        let connection = store.connection.get()

        guard connection.inProgress else {
            isHidden = true
            pathLayer.path = nil
            return
        }

        isHidden = false

        if let customComponent {
            pathLayer.path = nil

            if customView == nil {
                let made = customComponent()
                addSubview(made)
                customView = made
            }

            customView?.update(connection: connection)
            return
        }

        guard let from = connection.from, let to = connection.to else {
            pathLayer.path = nil
            return
        }

        let sourcePosition = connection.fromPosition ?? .bottom
        let targetPosition = connection.toPosition ?? .top

        let result: EdgePathResult
        switch store.connectionLineType.get() {
        case .bezier:
            result = getBezierPath(GetBezierPathParams(
                sourceX: from.x, sourceY: from.y, sourcePosition: sourcePosition,
                targetX: to.x, targetY: to.y, targetPosition: targetPosition))
        case .step:
            result = getSmoothStepPath(GetSmoothStepPathParams(
                sourceX: from.x, sourceY: from.y, sourcePosition: sourcePosition,
                targetX: to.x, targetY: to.y, targetPosition: targetPosition,
                borderRadius: 0))
        case .smoothstep:
            result = getSmoothStepPath(GetSmoothStepPathParams(
                sourceX: from.x, sourceY: from.y, sourcePosition: sourcePosition,
                targetX: to.x, targetY: to.y, targetPosition: targetPosition))
        default:
            result = getStraightPath(GetStraightPathParams(
                sourceX: from.x, sourceY: from.y, targetX: to.x, targetY: to.y))
        }

        applyStyle()
        pathLayer.path = SVGPath.cgPath(from: result.path)
    }

    /// `.svelte-flow__connection-path`, under the `style` of the line.
    private func applyStyle() {
        let parentScope = styleScope()
        let inline = FlowCSS.declarationMap(style)
        let scope = FlowStyleScope(parent: parentScope, properties: inline)

        var stroke = scope.color(["--xy-connectionline-stroke", "--xy-connectionline-stroke-default"])
        if let declared = inline["stroke"] {
            stroke = declared.lowercased() == "none" ? nil : (scope.resolvedColor(declared) ?? stroke)
        }

        var width = scope.number(["--xy-connectionline-stroke-width", "--xy-connectionline-stroke-width-default"]) ?? 1
        if let declared = scope.resolvedNumber(inline["stroke-width"]) {
            width = declared
        }

        pathLayer.strokeColor = stroke?.uiColor.cgColor
        pathLayer.lineWidth = CGFloat(width)

        if let list = inline["stroke-dasharray"].flatMap({ FlowCSS.parseNumberList($0) }), list.contains(where: { $0 > 0 }) {
            let pattern = list.count % 2 == 1 ? list + list : list
            pathLayer.lineDashPattern = pattern.map { NSNumber(value: $0) }
        } else {
            pathLayer.lineDashPattern = nil
        }

        pathLayer.opacity = Float(inline["opacity"].flatMap { Double($0) } ?? 1)
    }
}
#endif
