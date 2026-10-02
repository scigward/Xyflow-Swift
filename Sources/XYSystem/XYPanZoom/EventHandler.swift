import Foundation

/// The state the pan and zoom handlers share.
final class ZoomPanValues {
    var isZoomingOrPanning = false
    var usedRightMouseButton = false
    var prevViewport = Viewport(x: 0, y: 0, zoom: 0)
    var mouseButton = 0
    var timerId: Int?
    var panScrollTimeout: Int?
    var isPanScrolling = false
}

/// What happens on a wheel event when the wheel pans the viewport.
func createPanOnScrollHandler(
    zoomPanValues: ZoomPanValues,
    noWheelClassName: String,
    domNode: FlowDomNode,
    d3Zoom: D3ZoomBehavior,
    panOnScrollMode: PanOnScrollMode,
    panOnScrollSpeed: Double,
    zoomOnPinch: Bool,
    onPanZoomStart: OnPanZoom?,
    onPanZoom: OnPanZoom?,
    onPanZoomEnd: OnPanZoom?
) -> (ZoomSourceEvent) -> Void {
    { event in
        if isWrappedWithClass(event, noWheelClassName, in: domNode) {
            return
        }
        event.preventDefault()

        let currentZoom = d3Zoom.transform.k != 0 ? d3Zoom.transform.k : 1

        // macos sets ctrlKey=true for pinch gesture on a trackpad
        if event.ctrlKey && zoomOnPinch {
            let point = event.point
            let pinchDelta = wheelDelta(event)
            let zoom = currentZoom * pow(2, pinchDelta)
            d3Zoom.scaleTo(zoom, point: point, event: event)

            return
        }

        // increase scroll speed in firefox
        // firefox: deltaMode === 1; chrome: deltaMode === 0
        let deltaNormalize: Double = event.deltaMode == 1 ? 20 : 1
        var deltaX = panOnScrollMode == .vertical ? 0 : event.deltaX * deltaNormalize
        var deltaY = panOnScrollMode == .horizontal ? 0 : event.deltaY * deltaNormalize

        // this enables vertical scrolling with shift + scroll on windows
        if !isMacOs() && event.shiftKey && panOnScrollMode != .vertical {
            deltaX = event.deltaY * deltaNormalize
            deltaY = 0
        }

        d3Zoom.translateBy(
            -(deltaX / currentZoom) * panOnScrollSpeed,
            -(deltaY / currentZoom) * panOnScrollSpeed,
            event: ZoomSourceEvent(type: "internal", isInternal: true))

        let nextViewport = transformToViewport(d3Zoom.transform)

        clearTimeout(zoomPanValues.panScrollTimeout)

        // for pan on scroll we need to handle the event calls on our own
        // we can't use the start, zoom and end events from d3-zoom
        // because start and move gets called on every scroll event and not once at the beginning
        if !zoomPanValues.isPanScrolling {
            zoomPanValues.isPanScrolling = true

            onPanZoomStart?(event.pointerEvent, nextViewport)
        }

        if zoomPanValues.isPanScrolling {
            onPanZoom?(event.pointerEvent, nextViewport)

            zoomPanValues.panScrollTimeout = setTimeout(150) {
                onPanZoomEnd?(event.pointerEvent, nextViewport)

                zoomPanValues.isPanScrolling = false
            }
        }
    }
}

/// What happens on a wheel event when the wheel zooms the viewport.
func createZoomOnScrollHandler(
    noWheelClassName: String,
    preventScrolling: Bool,
    domNode: FlowDomNode,
    d3ZoomHandler: @escaping (ZoomSourceEvent) -> Void
) -> (ZoomSourceEvent) -> Void {
    { event in
        let isWheel = event.type == "wheel"
        // we still want to enable pinch zooming even if preventScrolling is set to false
        let preventZoom = !preventScrolling && isWheel && !event.ctrlKey
        let hasNoWheelClass = isWrappedWithClass(event, noWheelClassName, in: domNode)

        // if user is pinch zooming above a nowheel element, we don't want the browser to zoom
        if event.ctrlKey && isWheel && hasNoWheelClass {
            event.preventDefault()
        }

        if preventZoom || hasNoWheelClass {
            return
        }

        event.preventDefault()

        d3ZoomHandler(event)
    }
}

func createPanZoomStartHandler(
    zoomPanValues: ZoomPanValues,
    onDraggingChange: @escaping OnDraggingChange,
    onPanZoomStart: OnPanZoom?
) -> (ZoomEvent) -> Void {
    { event in
        if event.sourceEvent?.isInternal == true {
            return
        }

        let viewport = transformToViewport(event.transform)

        // we need to remember it here, because it's always 0 in the "zoom" event
        zoomPanValues.mouseButton = event.sourceEvent?.button ?? 0
        zoomPanValues.isZoomingOrPanning = true
        zoomPanValues.prevViewport = viewport

        if event.sourceEvent?.type == "mousedown" {
            onDraggingChange(true)
        }

        if let onPanZoomStart {
            onPanZoomStart(event.sourceEvent?.pointerEvent, viewport)
        }
    }
}

func createPanZoomHandler(
    zoomPanValues: ZoomPanValues,
    panOnDrag: PanOnDrag,
    onPaneContextMenu: Bool,
    onTransformChange: @escaping OnTransformChange,
    onPanZoom: OnPanZoom?
) -> (ZoomEvent) -> Void {
    { event in
        zoomPanValues.usedRightMouseButton = onPaneContextMenu && isRightClickPan(panOnDrag, zoomPanValues.mouseButton)

        if event.sourceEvent?.isSync != true {
            onTransformChange(Transform(event.transform.x, event.transform.y, event.transform.k))
        }

        if let onPanZoom, event.sourceEvent?.isInternal != true {
            onPanZoom(event.sourceEvent?.pointerEvent, transformToViewport(event.transform))
        }
    }
}

func createPanZoomEndHandler(
    zoomPanValues: ZoomPanValues,
    panOnDrag: PanOnDrag,
    panOnScroll: Bool,
    onDraggingChange: @escaping OnDraggingChange,
    onPanZoomEnd: OnPanZoom?,
    onPaneContextMenu: ((FlowPointerEvent) -> Void)?
) -> (ZoomEvent) -> Void {
    { event in
        if event.sourceEvent?.isInternal == true {
            return
        }

        zoomPanValues.isZoomingOrPanning = false

        if let onPaneContextMenu,
           isRightClickPan(panOnDrag, zoomPanValues.mouseButton),
           !zoomPanValues.usedRightMouseButton,
           let sourceEvent = event.sourceEvent {
            onPaneContextMenu(sourceEvent.pointerEvent)
        }
        zoomPanValues.usedRightMouseButton = false

        onDraggingChange(false)

        if let onPanZoomEnd, viewChanged(zoomPanValues.prevViewport, event.transform) {
            let viewport = transformToViewport(event.transform)
            zoomPanValues.prevViewport = viewport

            clearTimeout(zoomPanValues.timerId)
            // we need a setTimeout for panOnScroll to suppress multiple end events fired during scroll
            zoomPanValues.timerId = setTimeout(panOnScroll ? 150 : 0) {
                onPanZoomEnd(event.sourceEvent?.pointerEvent, viewport)
            }
        }
    }
}
