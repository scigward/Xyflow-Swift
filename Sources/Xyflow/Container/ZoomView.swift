#if canImport(UIKit)
import UIKit
import XYSystem

/// `Zoom.svelte`: the surface that pans and zooms the flow. It makes the pan and zoom controller
/// of the flow, and keeps it in line with the settings of the flow and with the keys that are held.
final class ZoomView: UIView {
    private let store: SwiftFlowStore
    private var subscriptions: [Unsubscribe] = []
    private var isReady = false

    var onMoveStart: OnPanZoom?
    var onMove: OnPanZoom?
    var onMoveEnd: OnPanZoom?

    var panOnScrollMode: PanOnScrollMode = .free { didSet { updatePanZoom() } }
    var preventScrolling = true { didSet { updatePanZoom() } }
    var zoomOnScroll = true { didSet { updatePanZoom() } }
    var zoomOnDoubleClick = true { didSet { updatePanZoom() } }
    var zoomOnPinch = true { didSet { updatePanZoom() } }
    var panOnScroll = false { didSet { updatePanZoom() } }
    var panOnDrag: PanOnDrag = true { didSet { updatePanZoom() } }

    var paneClickDistance: Double = 0 {
        didSet {
            if paneClickDistance != oldValue {
                store.setPaneClickDistance(paneClickDistance)
            }
        }
    }

    init(store: SwiftFlowStore) {
        self.store = store
        super.init(frame: .zero)

        flowClasses = ["svelte-flow__zoom"]
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscriptions.forEach { $0() }
        store.panZoom.get()?.destroy()
    }

    /// Makes the pan and zoom controller for the flow. `domNode` is what the controller measures and
    /// asks about the views the input started on.
    func setUp(domNode: FlowDomNode, initialViewport: Viewport?) {
        let viewport = initialViewport ?? Viewport(x: 0, y: 0, zoom: 1)

        let instance = XYPanZoom(PanZoomParams(
            domNode: domNode,
            minZoom: store.minZoom.get(),
            maxZoom: store.maxZoom.get(),
            paneClickDistance: paneClickDistance,
            viewport: viewport,
            translateExtent: store.translateExtent.get(),
            onDraggingChange: { [weak store] dragging in
                store?.dragging.set(dragging)
            },
            onPanZoomStart: { [weak self] event, viewport in self?.onMoveStart?(event, viewport) },
            onPanZoom: { [weak self] event, viewport in self?.onMove?(event, viewport) },
            onPanZoomEnd: { [weak self] event, viewport in self?.onMoveEnd?(event, viewport) }))

        store.viewport.set(instance.getViewport())
        store.panZoom.set(instance)

        // the keys that are held and the selection decide what the controller takes
        subscriptions.append(store.panActivationKeyPressed.subscribeAny { [weak self] in self?.updatePanZoom() })
        subscriptions.append(store.zoomActivationKeyPressed.subscribeAny { [weak self] in self?.updatePanZoom() })
        subscriptions.append(store.selectionRect.subscribeAny { [weak self] in self?.updatePanZoom() })
        subscriptions.append(store.lib.subscribeAny { [weak self] in self?.updatePanZoom() })

        isReady = true
        updatePanZoom()

        // `onMount`: the viewport is initialized once the zoom is there
        store.viewportInitialized.set(true)
    }

    /// What the controller of the viewport is told: the settings of the flow, with the pan activation key
    /// making the flow pan on drag and on scroll.
    func updatePanZoom() {
        guard isReady, let panZoom = store.panZoom.get() else { return }

        let panActivation = store.panActivationKeyPressed.get()

        panZoom.update(PanZoomUpdateOptions(
            noWheelClassName: FlowClass.noWheel,
            noPanClassName: FlowClass.noPan,
            onPaneContextMenu: nil,
            preventScrolling: preventScrolling,
            panOnScroll: panActivation || panOnScroll,
            panOnDrag: panActivation ? .enabled(true) : panOnDrag,
            panOnScrollMode: panOnScrollMode,
            panOnScrollSpeed: 0.5,
            userSelectionActive: store.selectionRect.get() != nil,
            zoomOnPinch: zoomOnPinch,
            zoomOnScroll: zoomOnScroll,
            zoomOnDoubleClick: zoomOnDoubleClick,
            zoomActivationKeyPressed: store.zoomActivationKeyPressed.get(),
            lib: store.lib.get(),
            onTransformChange: { [weak store] transform in
                store?.viewport.set(Viewport(x: transform[0], y: transform[1], zoom: transform[2]))
            }))
    }

    /// The zoom behavior that the input of the flow is fed to.
    var zoomBehavior: D3ZoomBehavior? {
        (store.panZoom.get() as? XYPanZoom)?.zoomBehavior
    }

    /// Whether a wheel at the point would do something to the flow. That is what decides whether the
    /// scrolling of a trackpad is taken, or left to the views around the flow, the way the page scrolls
    /// when `preventScrolling` is off.
    func wouldHandleWheel(at clientPoint: CGPoint, ctrlKey: Bool, in flow: SwiftFlow) -> Bool {
        guard let behavior = zoomBehavior else { return false }

        let target = flow.hitTest(flow.convert(clientPoint, from: nil), with: nil)
        guard let view = target, view.isDescendant(of: self) else { return false }

        let probe = ZoomSourceEvent(
            type: "wheel",
            ctrlKey: ctrlKey,
            clientX: Double(clientPoint.x),
            clientY: Double(clientPoint.y),
            point: convert(clientPoint, from: nil).xyPosition,
            deltaY: 1,
            target: target)

        if !behavior.filter(probe) {
            return false
        }

        let isPanOnScroll = (store.panActivationKeyPressed.get() || panOnScroll)
            && !store.zoomActivationKeyPressed.get()
            && store.selectionRect.get() == nil

        if isPanOnScroll {
            return true
        }

        // we still want to enable pinch zooming even if preventScrolling is set to false
        return preventScrolling || ctrlKey
    }
}
#endif
