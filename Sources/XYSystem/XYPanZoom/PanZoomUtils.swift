import Foundation

func viewChanged(_ prevViewport: Viewport, _ transform: ZoomTransform) -> Bool {
    prevViewport.x != transform.x || prevViewport.y != transform.y || prevViewport.zoom != transform.k
}

func transformToViewport(_ transform: ZoomTransform) -> Viewport {
    Viewport(x: transform.x, y: transform.y, zoom: transform.k)
}

func viewportToTransform(_ viewport: Viewport) -> ZoomTransform {
    ZoomTransform.identity.translate(viewport.x, viewport.y).scale(viewport.zoom)
}

/// `event.target.closest('.className')`
func isWrappedWithClass(_ event: ZoomSourceEvent, _ className: String?, in domNode: FlowDomNode) -> Bool {
    guard let className else { return false }
    return domNode.isWrapped(event.target, withClass: className)
}

func isRightClickPan(_ panOnDrag: PanOnDrag, _ usedButton: Int) -> Bool {
    usedButton == 2 && (panOnDrag.buttonList?.contains(2) ?? false)
}

func wheelDelta(_ event: ZoomSourceEvent) -> Double {
    let factor: Double = event.ctrlKey && isMacOs() ? 10 : 1

    return -event.deltaY * (event.deltaMode == 1 ? 0.05 : (event.deltaMode != 0 ? 1 : 0.002)) * factor
}
