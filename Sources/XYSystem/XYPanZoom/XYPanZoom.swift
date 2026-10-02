import Foundation

/// The controller of the viewport of a flow: it holds the zoom behavior, decides which input
/// pans and zooms, and moves the viewport programmatically. The host of the container feeds its
/// input to `zoomBehavior`.
public final class XYPanZoom: PanZoomInstance {
    /// The zoom behavior the container's input goes to: wheel, mouse and touch events, and double clicks.
    public let zoomBehavior: D3ZoomBehavior

    private let domNode: FlowDomNode
    private let zoomPanValues = ZoomPanValues()
    private let onPanZoomStart: OnPanZoom?
    private let onPanZoom: OnPanZoom?
    private let onPanZoomEnd: OnPanZoom?
    private let onDraggingChange: OnDraggingChange
    private let d3ZoomHandler: (ZoomSourceEvent) -> Void
    private let d3DblClickZoomHandler: (ZoomSourceEvent) -> Void

    public init(_ params: PanZoomParams) {
        domNode = params.domNode
        onPanZoomStart = params.onPanZoomStart
        onPanZoom = params.onPanZoom
        onPanZoomEnd = params.onPanZoomEnd
        onDraggingChange = params.onDraggingChange

        let bbox = params.domNode.boundingClientRect
        let node = params.domNode
        zoomBehavior = D3ZoomBehavior(extent: {
            let rect = node.boundingClientRect
            return CoordinateExtent(0, 0, rect.width, rect.height)
        })
        zoomBehavior
            .setClickDistance(!isNumeric(params.paneClickDistance) || params.paneClickDistance < 0 ? 0 : params.paneClickDistance)
            .setScaleExtent((params.minZoom, params.maxZoom))
            .setTranslateExtent(params.translateExtent)

        d3ZoomHandler = zoomBehavior.wheelHandler ?? { _ in }
        d3DblClickZoomHandler = zoomBehavior.dblclickHandler ?? { _ in }
        zoomBehavior.wheelDelta = wheelDelta

        setViewportConstrained(
            Viewport(x: params.viewport.x, y: params.viewport.y, zoom: clamp(params.viewport.zoom, params.minZoom, params.maxZoom)),
            extent: CoordinateExtent(0, 0, bbox.width, bbox.height),
            translateExtent: params.translateExtent,
            completion: nil)
    }

    private func setTransform(_ transform: ZoomTransform, options: PanZoomTransformOptions?, completion: ((Bool) -> Void)?) {
        zoomBehavior.applyTransform(transform, duration: options?.duration) {
            completion?(true)
        }
    }

    // MARK: Public functions

    public func update(_ params: PanZoomUpdateOptions) {
        if params.userSelectionActive && !zoomPanValues.isZoomingOrPanning {
            destroy()
        }

        let isPanOnScroll = params.panOnScroll && !params.zoomActivationKeyPressed && !params.userSelectionActive

        let wheelHandler: (ZoomSourceEvent) -> Void
        if isPanOnScroll {
            wheelHandler = createPanOnScrollHandler(
                zoomPanValues: zoomPanValues,
                noWheelClassName: params.noWheelClassName,
                domNode: domNode,
                d3Zoom: zoomBehavior,
                panOnScrollMode: params.panOnScrollMode,
                panOnScrollSpeed: params.panOnScrollSpeed,
                zoomOnPinch: params.zoomOnPinch,
                onPanZoomStart: onPanZoomStart,
                onPanZoom: onPanZoom,
                onPanZoomEnd: onPanZoomEnd)
        } else {
            wheelHandler = createZoomOnScrollHandler(
                noWheelClassName: params.noWheelClassName,
                preventScrolling: params.preventScrolling,
                domNode: domNode,
                d3ZoomHandler: d3ZoomHandler)
        }

        zoomBehavior.wheelHandler = wheelHandler

        if !params.userSelectionActive {
            // pan zoom start
            zoomBehavior.listeners.on("start", createPanZoomStartHandler(
                zoomPanValues: zoomPanValues,
                onDraggingChange: onDraggingChange,
                onPanZoomStart: onPanZoomStart))

            // pan zoom
            zoomBehavior.listeners.on("zoom", createPanZoomHandler(
                zoomPanValues: zoomPanValues,
                panOnDrag: params.panOnDrag,
                onPaneContextMenu: params.onPaneContextMenu != nil,
                onTransformChange: params.onTransformChange,
                onPanZoom: onPanZoom))

            // pan zoom end
            zoomBehavior.listeners.on("end", createPanZoomEndHandler(
                zoomPanValues: zoomPanValues,
                panOnDrag: params.panOnDrag,
                panOnScroll: params.panOnScroll,
                onDraggingChange: onDraggingChange,
                onPanZoomEnd: onPanZoomEnd,
                onPaneContextMenu: params.onPaneContextMenu))
        }

        zoomBehavior.filter = createFilter(
            FilterParams(
                zoomActivationKeyPressed: params.zoomActivationKeyPressed,
                zoomOnScroll: params.zoomOnScroll,
                zoomOnPinch: params.zoomOnPinch,
                panOnDrag: params.panOnDrag,
                panOnScroll: params.panOnScroll,
                zoomOnDoubleClick: params.zoomOnDoubleClick,
                userSelectionActive: params.userSelectionActive,
                noWheelClassName: params.noWheelClassName,
                noPanClassName: params.noPanClassName,
                lib: params.lib),
            domNode: domNode)

        // We cannot add zoomOnDoubleClick to the filter above because
        // double tapping on touch screens circumvents the filter and
        // dblclick.zoom is fired on the selection directly
        if params.zoomOnDoubleClick {
            zoomBehavior.dblclickHandler = d3DblClickZoomHandler
        } else {
            zoomBehavior.dblclickHandler = nil
        }
    }

    public func destroy() {
        zoomBehavior.listeners.on("zoom", nil)
    }

    public func setViewportConstrained(
        _ viewport: Viewport,
        extent: CoordinateExtent,
        translateExtent: CoordinateExtent,
        completion: ((ZoomTransform?) -> Void)?
    ) {
        let nextTransform = viewportToTransform(viewport)
        let constrainedTransform = zoomBehavior.constrain(nextTransform, extent, translateExtent)

        setTransform(constrainedTransform, options: nil) { _ in
            completion?(constrainedTransform)
        }
    }

    public func setViewport(
        _ viewport: Viewport,
        options: PanZoomTransformOptions?,
        completion: ((ZoomTransform?) -> Void)?
    ) {
        let nextTransform = viewportToTransform(viewport)

        setTransform(nextTransform, options: options) { _ in
            completion?(nextTransform)
        }
    }

    public func syncViewport(_ viewport: Viewport) {
        let nextTransform = viewportToTransform(viewport)
        let currentTransform = zoomBehavior.transform

        if currentTransform.k != viewport.zoom
            || currentTransform.x != viewport.x
            || currentTransform.y != viewport.y {
            zoomBehavior.applyTransform(nextTransform, event: ZoomSourceEvent(type: "sync", isSync: true))
        }
    }

    public func getViewport() -> Viewport {
        let transform = zoomBehavior.transform
        return Viewport(x: transform.x, y: transform.y, zoom: transform.k)
    }

    public func scaleTo(_ zoom: Double, options: PanZoomTransformOptions?, completion: ((Bool) -> Void)?) {
        zoomBehavior.scaleTo(zoom, duration: options?.duration) {
            completion?(true)
        }
    }

    public func scaleBy(_ factor: Double, options: PanZoomTransformOptions?, completion: ((Bool) -> Void)?) {
        zoomBehavior.scaleBy(factor, duration: options?.duration) {
            completion?(true)
        }
    }

    public func setScaleExtent(_ scaleExtent: (Double, Double)) {
        zoomBehavior.setScaleExtent(scaleExtent)
    }

    public func setTranslateExtent(_ translateExtent: CoordinateExtent) {
        zoomBehavior.setTranslateExtent(translateExtent)
    }

    public func setClickDistance(_ distance: Double) {
        let validDistance = !isNumeric(distance) || distance < 0 ? 0 : distance
        zoomBehavior.setClickDistance(validDistance)
    }
}
