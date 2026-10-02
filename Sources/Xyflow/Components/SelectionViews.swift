#if canImport(UIKit)
import UIKit
import XYSystem

/// `Selection.svelte`: a rectangle with the background and the border of a selection.
class SelectionRectView: UIView {
    private let borderLayer = CAShapeLayer()
    private(set) var borderWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        flowClasses = ["svelte-flow__selection"]
        borderLayer.fillColor = nil
        layer.addSublayer(borderLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Reads the colors and the border from the style of the flow.
    func applyStyle(_ scope: FlowStyleScope) {
        backgroundColor = scope.color([
            "--xy-selection-background-color", "--xy-selection-background-color-default"
        ])?.uiColor ?? .clear

        let border = scope.border(["--xy-selection-border", "--xy-selection-border-default"])
        borderWidth = CGFloat(border?.width ?? 0)

        borderLayer.strokeColor = border?.color?.uiColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.lineDashPattern = (border?.isDotted ?? false)
            ? [NSNumber(value: Double(borderWidth)), NSNumber(value: Double(borderWidth))]
            : nil

        setNeedsLayout()
    }

    /// What the box adds to the size of its content: the border, on both sides.
    var borderExtra: CGFloat {
        borderWidth * 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        borderLayer.frame = bounds
        borderLayer.path = CGPath(rect: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2), transform: nil)
    }
}

/// `UserSelection.svelte`: the rectangle that is drawn while nodes are selected by dragging.
final class UserSelectionView: SelectionRectView {
    private let store: SwiftFlowStore
    private let styleScope: () -> FlowStyleScope
    private var subscriptions: [Unsubscribe] = []

    init(store: SwiftFlowStore, styleScope: @escaping () -> FlowStyleScope) {
        self.store = store
        self.styleScope = styleScope
        super.init(frame: .zero)

        isHidden = true
        subscriptions.append(store.selectionRect.subscribeAny { [weak self] in self?.update() })
        subscriptions.append(store.selectionRectMode.subscribeAny { [weak self] in self?.update() })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscriptions.forEach { $0() }
    }

    func update() {
        guard let rect = store.selectionRect.get(), store.selectionRectMode.get() == "user" else {
            isHidden = true
            return
        }

        applyStyle(styleScope())

        // the rectangle is the size of the content, the border is around it
        frame = CGRect(
            x: rect.x,
            y: rect.y,
            width: rect.width + borderExtra,
            height: rect.height + borderExtra)
        isHidden = false
    }
}

/// `NodeSelection.svelte`: the box around the nodes that were selected with a rectangle. It is what
/// the selection is dragged by, and clicks on the selection are told about.
final class NodeSelectionView: UIView, FlowElement, FlowDragHost, FlowClickable, FlowContextMenuHandling {
    private let store: SwiftFlowStore
    private let styleScope: () -> FlowStyleScope
    private let rectView = SelectionRectView()
    private var xyDrag: XYDrag!
    private var subscriptions: [Unsubscribe] = []

    var onSelectionClick: ((SelectionEvent) -> Void)?
    var onSelectionContextMenu: ((SelectionEvent) -> Void)?
    var onNodeDragStart: ((NodeDragEvent) -> Void)?
    var onNodeDrag: ((NodeDragEvent) -> Void)?
    var onNodeDragStop: ((NodeDragEvent) -> Void)?

    init(store: SwiftFlowStore, styleScope: @escaping () -> FlowStyleScope) {
        self.store = store
        self.styleScope = styleScope
        super.init(frame: .zero)

        flowClasses = ["selection-wrapper", FlowClass.noPan]
        isHidden = true
        addSubview(rectView)

        xyDrag = XYDrag(XYDragParams(
            getStoreItems: { [store] in
                store.dragStoreItems()
            },
            onDragStart: { [weak self] event, _, _, nodes in
                self?.onNodeDragStart?(NodeDragEvent(targetNode: nil, nodes: nodes, event: event))
            },
            onDrag: { [weak self] event, _, _, nodes in
                self?.onNodeDrag?(NodeDragEvent(targetNode: nil, nodes: nodes, event: event))
            },
            onDragStop: { [weak self] event, _, _, nodes in
                self?.onNodeDragStop?(NodeDragEvent(targetNode: nil, nodes: nodes, event: event))
            }))
        xyDrag.update(DragUpdateParams(domNode: self))

        subscriptions.append(store.selectionRectMode.subscribeAny { [weak self] in self?.update() })
        subscriptions.append(store.nodes.subscribeAny { [weak self] in self?.update() })
        subscriptions.append(store.nodeLookup.subscribeAny { [weak self] in self?.update() })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscriptions.forEach { $0() }
        xyDrag.destroy()
    }

    func update() {
        guard store.selectionRectMode.get() == "nodes" else {
            isHidden = true
            return
        }

        let bounds = getInternalNodesBounds(store.nodeLookup.get()) { $0.selected == true }

        guard isNumeric(bounds.x), isNumeric(bounds.y) else {
            isHidden = true
            return
        }

        rectView.applyStyle(styleScope())

        frame = CGRect(x: bounds.x, y: bounds.y, width: bounds.width, height: bounds.height)
        rectView.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width + rectView.borderExtra,
            height: bounds.height + rectView.borderExtra)
        isHidden = false
    }

    var flowDragBehavior: D3DragBehavior {
        xyDrag.behavior
    }

    private func selectedNodes() -> [Node] {
        store.nodes.get().filter { $0.selected == true }
    }

    func flowClick(event: FlowPointerEvent) {
        onSelectionClick?(SelectionEvent(nodes: selectedNodes(), event: event))
    }

    func flowContextMenu(event: FlowPointerEvent) {
        onSelectionContextMenu?(SelectionEvent(nodes: selectedNodes(), event: event))
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        !isHidden && bounds.contains(point)
    }
}
#endif
