import Foundation

public typealias OnDraggingChange = (Bool) -> Void
public typealias OnTransformChange = (Transform) -> Void
public typealias OnPanZoom = (FlowPointerEvent?, Viewport) -> Void

/// Which mouse buttons pan the viewport when they are dragged: all of the primary one (`true`),
/// none (`false`), or the ones listed (`0` is the left button, `1` the middle one, `2` the right one).
public enum PanOnDrag: Equatable, ExpressibleByBooleanLiteral, ExpressibleByArrayLiteral {
    case enabled(Bool)
    case buttons([Int])

    public init(booleanLiteral value: Bool) {
        self = .enabled(value)
    }

    public init(arrayLiteral elements: Int...) {
        self = .buttons(elements)
    }

    /// `!!panOnDrag`: an array, even an empty one, is truthy.
    public var isTruthy: Bool {
        switch self {
        case .enabled(let value): return value
        case .buttons: return true
        }
    }

    public var buttonList: [Int]? {
        if case .buttons(let buttons) = self { return buttons }
        return nil
    }
}

public struct PanZoomParams {
    public var domNode: FlowDomNode
    public var minZoom: Double
    public var maxZoom: Double
    public var paneClickDistance: Double
    public var viewport: Viewport
    public var translateExtent: CoordinateExtent
    public var onDraggingChange: OnDraggingChange
    public var onPanZoomStart: OnPanZoom?
    public var onPanZoom: OnPanZoom?
    public var onPanZoomEnd: OnPanZoom?

    public init(
        domNode: FlowDomNode,
        minZoom: Double,
        maxZoom: Double,
        paneClickDistance: Double,
        viewport: Viewport,
        translateExtent: CoordinateExtent,
        onDraggingChange: @escaping OnDraggingChange,
        onPanZoomStart: OnPanZoom? = nil,
        onPanZoom: OnPanZoom? = nil,
        onPanZoomEnd: OnPanZoom? = nil
    ) {
        self.domNode = domNode
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.paneClickDistance = paneClickDistance
        self.viewport = viewport
        self.translateExtent = translateExtent
        self.onDraggingChange = onDraggingChange
        self.onPanZoomStart = onPanZoomStart
        self.onPanZoom = onPanZoom
        self.onPanZoomEnd = onPanZoomEnd
    }
}

public struct PanZoomTransformOptions: Equatable {
    public var duration: Double?

    public init(duration: Double? = nil) {
        self.duration = duration
    }
}

public struct PanZoomUpdateOptions {
    public var noWheelClassName: String
    public var noPanClassName: String
    public var onPaneContextMenu: ((FlowPointerEvent) -> Void)?
    public var preventScrolling: Bool
    public var panOnScroll: Bool
    public var panOnDrag: PanOnDrag
    public var panOnScrollMode: PanOnScrollMode
    public var panOnScrollSpeed: Double
    public var userSelectionActive: Bool
    public var zoomOnPinch: Bool
    public var zoomOnScroll: Bool
    public var zoomOnDoubleClick: Bool
    public var zoomActivationKeyPressed: Bool
    public var lib: String
    public var onTransformChange: OnTransformChange

    public init(
        noWheelClassName: String,
        noPanClassName: String,
        onPaneContextMenu: ((FlowPointerEvent) -> Void)? = nil,
        preventScrolling: Bool,
        panOnScroll: Bool,
        panOnDrag: PanOnDrag,
        panOnScrollMode: PanOnScrollMode,
        panOnScrollSpeed: Double,
        userSelectionActive: Bool,
        zoomOnPinch: Bool,
        zoomOnScroll: Bool,
        zoomOnDoubleClick: Bool,
        zoomActivationKeyPressed: Bool,
        lib: String,
        onTransformChange: @escaping OnTransformChange
    ) {
        self.noWheelClassName = noWheelClassName
        self.noPanClassName = noPanClassName
        self.onPaneContextMenu = onPaneContextMenu
        self.preventScrolling = preventScrolling
        self.panOnScroll = panOnScroll
        self.panOnDrag = panOnDrag
        self.panOnScrollMode = panOnScrollMode
        self.panOnScrollSpeed = panOnScrollSpeed
        self.userSelectionActive = userSelectionActive
        self.zoomOnPinch = zoomOnPinch
        self.zoomOnScroll = zoomOnScroll
        self.zoomOnDoubleClick = zoomOnDoubleClick
        self.zoomActivationKeyPressed = zoomActivationKeyPressed
        self.lib = lib
        self.onTransformChange = onTransformChange
    }
}

/// The controller of the viewport: pan and zoom of the container of a flow.
public protocol PanZoomInstance: AnyObject {
    func update(_ params: PanZoomUpdateOptions)
    func destroy()
    func getViewport() -> Viewport
    /// Moves the viewport. `completion` is told the transform it was set to; for a transition that
    /// is interrupted it is not called.
    func setViewport(
        _ viewport: Viewport,
        options: PanZoomTransformOptions?,
        completion: ((ZoomTransform?) -> Void)?)
    func setViewportConstrained(
        _ viewport: Viewport,
        extent: CoordinateExtent,
        translateExtent: CoordinateExtent,
        completion: ((ZoomTransform?) -> Void)?)
    func setScaleExtent(_ scaleExtent: (Double, Double))
    func setTranslateExtent(_ translateExtent: CoordinateExtent)
    func scaleTo(_ scale: Double, options: PanZoomTransformOptions?, completion: ((Bool) -> Void)?)
    func scaleBy(_ factor: Double, options: PanZoomTransformOptions?, completion: ((Bool) -> Void)?)
    func syncViewport(_ viewport: Viewport)
    func setClickDistance(_ distance: Double)
}

extension PanZoomInstance {
    public func setViewport(_ viewport: Viewport, options: PanZoomTransformOptions? = nil) {
        setViewport(viewport, options: options, completion: nil)
    }

    public func setViewportConstrained(
        _ viewport: Viewport,
        extent: CoordinateExtent,
        translateExtent: CoordinateExtent
    ) {
        setViewportConstrained(viewport, extent: extent, translateExtent: translateExtent, completion: nil)
    }

    public func scaleTo(_ scale: Double, options: PanZoomTransformOptions? = nil) {
        scaleTo(scale, options: options, completion: nil)
    }

    public func scaleBy(_ factor: Double, options: PanZoomTransformOptions? = nil) {
        scaleBy(factor, options: options, completion: nil)
    }
}
