import Foundation

public struct XYMinimapParams {
    public var panZoom: PanZoomInstance
    public var getTransform: () -> Transform
    public var getViewScale: () -> Double

    public init(
        panZoom: PanZoomInstance,
        getTransform: @escaping () -> Transform,
        getViewScale: @escaping () -> Double
    ) {
        self.panZoom = panZoom
        self.getTransform = getTransform
        self.getViewScale = getViewScale
    }
}

public struct XYMinimapUpdate {
    public var translateExtent: CoordinateExtent
    public var width: Double
    public var height: Double
    public var inversePan: Bool?
    public var zoomStep: Double?
    public var pannable: Bool?
    public var zoomable: Bool?

    public init(
        translateExtent: CoordinateExtent,
        width: Double,
        height: Double,
        inversePan: Bool? = nil,
        zoomStep: Double? = nil,
        pannable: Bool? = nil,
        zoomable: Bool? = nil
    ) {
        self.translateExtent = translateExtent
        self.width = width
        self.height = height
        self.inversePan = inversePan
        self.zoomStep = zoomStep
        self.pannable = pannable
        self.zoomable = zoomable
    }
}

/// The controller of the minimap: dragging it pans the viewport of the flow and the wheel zooms it.
/// The host of the minimap feeds its input to `zoomBehavior`.
public final class XYMinimap {
    /// The zoom behavior the input of the minimap goes to.
    public let zoomBehavior: D3ZoomBehavior

    private let panZoom: PanZoomInstance
    private let getTransform: () -> Transform
    private let getViewScale: () -> Double

    public init(_ params: XYMinimapParams, extent: @escaping () -> CoordinateExtent) {
        panZoom = params.panZoom
        getTransform = params.getTransform
        getViewScale = params.getViewScale
        zoomBehavior = D3ZoomBehavior(extent: extent)
    }

    public func update(_ params: XYMinimapUpdate) {
        let zoomStep = params.zoomStep ?? 10
        let pannable = params.pannable ?? true
        let zoomable = params.zoomable ?? true
        let inversePan = params.inversePan ?? false
        let translateExtent = params.translateExtent
        let width = params.width
        let height = params.height

        let zoomHandler: (ZoomEvent) -> Void = { [self] event in
            let transform = getTransform()

            guard let sourceEvent = event.sourceEvent, sourceEvent.type == "wheel" else {
                return
            }

            let deltaScale: Double = sourceEvent.deltaMode == 1 ? 0.05 : (sourceEvent.deltaMode != 0 ? 1 : 0.002)
            let pinchDelta = -sourceEvent.deltaY * deltaScale * zoomStep
            let nextZoom = transform.scale * pow(2, pinchDelta)

            panZoom.scaleTo(nextZoom)
        }

        var panStart = (x: 0.0, y: 0.0)
        let panStartHandler: (ZoomEvent) -> Void = { event in
            guard let sourceEvent = event.sourceEvent else { return }

            if sourceEvent.type == "mousedown" || sourceEvent.type == "touchstart" {
                let touch = sourceEvent.touches.first
                panStart = (touch?.clientX ?? sourceEvent.clientX, touch?.clientY ?? sourceEvent.clientY)
            }
        }

        let panHandler: (ZoomEvent) -> Void = { [self] event in
            let transform = getTransform()

            guard let sourceEvent = event.sourceEvent,
                  sourceEvent.type == "mousemove" || sourceEvent.type == "touchmove" else {
                return
            }

            let touch = sourceEvent.touches.first
            let panCurrent = (x: touch?.clientX ?? sourceEvent.clientX, y: touch?.clientY ?? sourceEvent.clientY)
            let panDelta = (x: panCurrent.x - panStart.x, y: panCurrent.y - panStart.y)
            panStart = panCurrent

            let moveScale = getViewScale() * jsMax(transform.scale, log(transform.scale)) * (inversePan ? -1 : 1)
            let position = XYPosition(
                x: transform.x - panDelta.x * moveScale,
                y: transform.y - panDelta.y * moveScale)
            let extent = CoordinateExtent(0, 0, width, height)

            panZoom.setViewportConstrained(
                Viewport(x: position.x, y: position.y, zoom: transform.scale),
                extent: extent,
                translateExtent: translateExtent)
        }

        zoomBehavior.listeners.on("start", panStartHandler)
        zoomBehavior.listeners.on("zoom", pannable ? panHandler : nil)
        zoomBehavior.listeners.on("zoom.wheel", zoomable ? zoomHandler : nil)
    }

    public func destroy() {
        zoomBehavior.listeners.on("zoom", nil)
        zoomBehavior.listeners.on("zoom.wheel", nil)
    }
}
