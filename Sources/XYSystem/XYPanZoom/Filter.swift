import Foundation

struct FilterParams {
    var zoomActivationKeyPressed: Bool
    var zoomOnScroll: Bool
    var zoomOnPinch: Bool
    var panOnDrag: PanOnDrag
    var panOnScroll: Bool
    var zoomOnDoubleClick: Bool
    var userSelectionActive: Bool
    var noWheelClassName: String
    var noPanClassName: String
    var lib: String
}

/// Decides which events the zoom behavior takes: the one of the pane's configuration.
func createFilter(_ params: FilterParams, domNode: FlowDomNode) -> (ZoomSourceEvent) -> Bool {
    { event in
        let zoomScroll = params.zoomActivationKeyPressed || params.zoomOnScroll
        let pinchZoom = params.zoomOnPinch && event.ctrlKey

        if event.button == 1
            && event.type == "mousedown"
            && (isWrappedWithClass(event, "\(params.lib)-flow__node", in: domNode)
                || isWrappedWithClass(event, "\(params.lib)-flow__edge", in: domNode)) {
            return true
        }

        // if all interactions are disabled, we prevent all zoom events
        if !params.panOnDrag.isTruthy && !zoomScroll && !params.panOnScroll && !params.zoomOnDoubleClick
            && !params.zoomOnPinch {
            return false
        }

        // during a selection we prevent all other interactions
        if params.userSelectionActive {
            return false
        }

        // if the target element is inside an element with the nowheel class, we prevent zooming
        if isWrappedWithClass(event, params.noWheelClassName, in: domNode) && event.type == "wheel" {
            return false
        }

        // if the target element is inside an element with the nopan class, we prevent panning
        if isWrappedWithClass(event, params.noPanClassName, in: domNode)
            && (event.type != "wheel"
                || (params.panOnScroll && event.type == "wheel" && !params.zoomActivationKeyPressed)) {
            return false
        }

        if !params.zoomOnPinch && event.ctrlKey && event.type == "wheel" {
            return false
        }

        if !params.zoomOnPinch && event.type == "touchstart" && event.touches.count > 1 {
            // if you manage to start with 2 touches, we prevent native zoom
            event.preventDefault()
            return false
        }

        // when there is no scroll handling enabled, we prevent all wheel events
        if !zoomScroll && !params.panOnScroll && !pinchZoom && event.type == "wheel" {
            return false
        }

        // if the pane is not movable, we prevent dragging it with mousestart or touchstart
        if !params.panOnDrag.isTruthy && (event.type == "mousedown" || event.type == "touchstart") {
            return false
        }

        // if the pane is only movable using allowed clicks
        if let buttons = params.panOnDrag.buttonList, !buttons.contains(event.button), event.type == "mousedown" {
            return false
        }

        // We only allow right clicks if pan on drag is set to right click
        let buttonAllowed = (params.panOnDrag.buttonList?.contains(event.button) ?? false)
            || event.button == 0
            || event.button <= 1

        // default filter for d3-zoom
        return (!event.ctrlKey || event.type == "wheel") && buttonAllowed
    }
}
