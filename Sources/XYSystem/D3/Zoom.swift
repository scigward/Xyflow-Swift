import Foundation

/// A touch of a touch event: where it is in the coordinates of the element the zoom behavior
/// is on, and which finger it is.
public struct ZoomTouch: Equatable {
    public var identifier: Int
    public var point: XYPosition
    public var clientX: Double
    public var clientY: Double

    public init(identifier: Int, point: XYPosition, clientX: Double = 0, clientY: Double = 0) {
        self.identifier = identifier
        self.point = point
        self.clientX = clientX
        self.clientY = clientY
    }
}

/// The event that made a zoom happen: a wheel, a mouse or a touch event, as the DOM events the
/// zoom behavior of d3 is made for. `point` is where the pointer is in the coordinates of the
/// element, which is what `d3.pointer(event)` answers.
public final class ZoomSourceEvent {
    /// `"wheel"`, `"mousedown"`, `"mousemove"`, `"mouseup"`, `"dblclick"`, `"touchstart"`,
    /// `"touchmove"`, `"touchend"` or `"touchcancel"`.
    public var type: String
    public var button: Int
    public var ctrlKey: Bool
    public var shiftKey: Bool
    public var altKey: Bool
    public var metaKey: Bool
    public var clientX: Double
    public var clientY: Double
    public var point: XYPosition
    public var deltaX: Double
    public var deltaY: Double
    public var deltaMode: Int
    /// The view the event started on.
    public var target: AnyObject?
    /// `event.touches`
    public var touches: [ZoomTouch]
    /// `event.changedTouches`
    public var changedTouches: [ZoomTouch]
    /// Zooms that were asked for by the flow itself (`{ internal: true }`) and are no user input.
    public var isInternal: Bool
    /// Zooms that only bring the behavior in line with the viewport (`{ sync: true }`).
    public var isSync: Bool
    public var defaultPrevented = false

    public init(
        type: String,
        button: Int = 0,
        ctrlKey: Bool = false,
        shiftKey: Bool = false,
        altKey: Bool = false,
        metaKey: Bool = false,
        clientX: Double = 0,
        clientY: Double = 0,
        point: XYPosition = .zero,
        deltaX: Double = 0,
        deltaY: Double = 0,
        deltaMode: Int = 0,
        target: AnyObject? = nil,
        touches: [ZoomTouch] = [],
        changedTouches: [ZoomTouch] = [],
        isInternal: Bool = false,
        isSync: Bool = false
    ) {
        self.type = type
        self.button = button
        self.ctrlKey = ctrlKey
        self.shiftKey = shiftKey
        self.altKey = altKey
        self.metaKey = metaKey
        self.clientX = clientX
        self.clientY = clientY
        self.point = point
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.deltaMode = deltaMode
        self.target = target
        self.touches = touches
        self.changedTouches = changedTouches
        self.isInternal = isInternal
        self.isSync = isSync
    }

    public func preventDefault() {
        defaultPrevented = true
    }

    /// The event as the callbacks of a flow get it.
    public var pointerEvent: FlowPointerEvent {
        var modifiers: EventModifiers = []
        if shiftKey { modifiers.insert(.shift) }
        if ctrlKey { modifiers.insert(.control) }
        if altKey { modifiers.insert(.alt) }
        if metaKey { modifiers.insert(.meta) }

        return FlowPointerEvent(
            kind: type.hasPrefix("touch") ? .touch : .mouse,
            clientX: clientX,
            clientY: clientY,
            modifiers: modifiers,
            button: button,
            buttons: type == "mouseup" ? 0 : 1,
            target: target,
            native: self)
    }
}

/// What a zoom behavior tells its listeners.
public struct ZoomEvent {
    public var type: String
    public var sourceEvent: ZoomSourceEvent?
    public var transform: ZoomTransform

    public init(type: String, sourceEvent: ZoomSourceEvent?, transform: ZoomTransform) {
        self.type = type
        self.sourceEvent = sourceEvent
        self.transform = transform
    }
}

/// A zoom behavior: the translation and scale of an element, changed by wheel, mouse and touch
/// input and by transitions, and constrained to a scale extent and a translate extent. This is
/// d3-zoom; the events come from whoever hosts the element instead of the DOM.
public final class D3ZoomBehavior {
    public typealias Constrain = (ZoomTransform, CoordinateExtent, CoordinateExtent) -> ZoomTransform

    /// The default filter: ignore right-click, since that should open the context menu, except
    /// for pinch-to-zoom, which is sent as a wheel and ctrl key event.
    public static func defaultFilter(_ event: ZoomSourceEvent) -> Bool {
        (!event.ctrlKey || event.type == "wheel") && event.button == 0
    }

    public static func defaultWheelDelta(_ event: ZoomSourceEvent) -> Double {
        -event.deltaY * (event.deltaMode == 1 ? 0.05 : (event.deltaMode != 0 ? 1 : 0.002)) * (event.ctrlKey ? 10 : 1)
    }

    public static func defaultConstrain(
        _ transform: ZoomTransform,
        _ extent: CoordinateExtent,
        _ translateExtent: CoordinateExtent
    ) -> ZoomTransform {
        let dx0 = transform.invertX(extent.minX) - translateExtent.minX
        let dx1 = transform.invertX(extent.maxX) - translateExtent.maxX
        let dy0 = transform.invertY(extent.minY) - translateExtent.minY
        let dy1 = transform.invertY(extent.maxY) - translateExtent.maxY

        // `Math.min(0, dx0) || Math.max(0, dx1)`
        func pick(_ low: Double, _ high: Double) -> Double {
            let minimum = jsMin(0, low)
            return minimum != 0 && !minimum.isNaN ? minimum : jsMax(0, high)
        }

        return transform.translate(
            dx1 > dx0 ? (dx0 + dx1) / 2 : pick(dx0, dx1),
            dy1 > dy0 ? (dy0 + dy1) / 2 : pick(dy0, dy1))
    }

    // MARK: Configuration

    public var filter: (ZoomSourceEvent) -> Bool = D3ZoomBehavior.defaultFilter
    /// The extent of the viewport, `[[0, 0], [width, height]]` of the element.
    public var extent: () -> CoordinateExtent
    public var constrain: Constrain = D3ZoomBehavior.defaultConstrain
    public var wheelDelta: (ZoomSourceEvent) -> Double = D3ZoomBehavior.defaultWheelDelta
    public private(set) var scaleExtent: (Double, Double) = (0, .infinity)
    public private(set) var translateExtent: CoordinateExtent = .infinite
    /// How long the transition of a double click takes, in milliseconds.
    public var duration: Double = 250
    public var interpolate: (ZoomRegion, ZoomRegion) -> ZoomInterpolator = { interpolateZoom($0, $1) }
    public let listeners = D3Dispatch<ZoomEvent>(["start", "zoom", "end"])
    public var tapDistance: Double = 10

    private var clickDistance2: Double = 0
    private let touchDelay: Double = 500
    private let wheelDelay: Double = 150

    /// What happens on a wheel event. It is the behavior's own `wheeled` unless something replaces it.
    public var wheelHandler: ((ZoomSourceEvent) -> Void)?
    /// What happens on a double click, `dblclick.zoom`. `nil` means a double click does nothing.
    public var dblclickHandler: ((ZoomSourceEvent) -> Void)?

    // MARK: Element state

    /// `element.__zoom`
    public private(set) var transform: ZoomTransform = .identity
    fileprivate var zooming: ZoomGesture?
    private var touchStarting: Int?
    private var touchFirst: XYPosition?
    private var touchEnding: Int?
    private var mouseGesture: (gesture: ZoomGesture, x0: Double, y0: Double)?
    public let transitions = D3TransitionHost()

    public init(extent: @escaping () -> CoordinateExtent) {
        self.extent = extent
        wheelHandler = { [unowned self] event in self.wheeled(event) }
        dblclickHandler = { [unowned self] event in self.dblclicked(event) }
    }

    // MARK: Setters

    @discardableResult
    public func setScaleExtent(_ value: (Double, Double)) -> D3ZoomBehavior {
        scaleExtent = value
        return self
    }

    @discardableResult
    public func setTranslateExtent(_ value: CoordinateExtent) -> D3ZoomBehavior {
        translateExtent = value
        return self
    }

    @discardableResult
    public func setClickDistance(_ value: Double) -> D3ZoomBehavior {
        clickDistance2 = value * value
        return self
    }

    public var clickDistance: Double {
        clickDistance2.squareRoot()
    }

    // MARK: Programmatic zoom

    /// `zoom.transform`: sets the transform, in a transition when there is a duration. `onEnd` is
    /// told when it is set; a transition that is interrupted never ends.
    public func applyTransform(
        _ target: ZoomTransform,
        point: XYPosition? = nil,
        event: ZoomSourceEvent? = nil,
        duration: Double? = nil,
        onEnd: (() -> Void)? = nil
    ) {
        applyTransform(provider: { target }, point: point, event: event, duration: duration, onEnd: onEnd)
    }

    public func applyTransform(
        provider: @escaping () -> ZoomTransform,
        point: XYPosition?,
        event: ZoomSourceEvent?,
        duration: Double?,
        onEnd: (() -> Void)?
    ) {
        if let duration, duration > 0 {
            transitions.transition(duration: duration) { transition in
                schedule(transition, provider, point, event)
                // after the end of the gesture: whoever waits for the transition finds it done
                if let onEnd {
                    transition.on.on("end") { _ in onEnd() }
                }
            }
        } else {
            transitions.interrupt()
            gesture().event(event).start().zoom(nil, provider()).end()
            onEnd?()
        }
    }

    public func scaleBy(
        _ factor: Double,
        point: XYPosition? = nil,
        event: ZoomSourceEvent? = nil,
        duration: Double? = nil,
        onEnd: (() -> Void)? = nil
    ) {
        scaleTo(provider: { [unowned self] in self.transform.k * factor }, point: point, event: event, duration: duration, onEnd: onEnd)
    }

    public func scaleTo(
        _ k: Double,
        point: XYPosition? = nil,
        event: ZoomSourceEvent? = nil,
        duration: Double? = nil,
        onEnd: (() -> Void)? = nil
    ) {
        scaleTo(provider: { k }, point: point, event: event, duration: duration, onEnd: onEnd)
    }

    private func scaleTo(
        provider k: @escaping () -> Double,
        point: XYPosition?,
        event: ZoomSourceEvent?,
        duration: Double?,
        onEnd: (() -> Void)?
    ) {
        applyTransform(
            provider: { [unowned self] in
                let e = self.extent()
                let t0 = self.transform
                let p0 = point ?? self.centroid(e)
                let p1 = t0.invert(p0)
                let k1 = k()
                return self.constrain(self.translate(self.scale(t0, k1), p0, p1), e, self.translateExtent)
            },
            point: point, event: event, duration: duration, onEnd: onEnd)
    }

    public func translateBy(
        _ x: Double,
        _ y: Double,
        event: ZoomSourceEvent? = nil,
        duration: Double? = nil,
        onEnd: (() -> Void)? = nil
    ) {
        applyTransform(
            provider: { [unowned self] in
                self.constrain(self.transform.translate(x, y), self.extent(), self.translateExtent)
            },
            point: nil, event: event, duration: duration, onEnd: onEnd)
    }

    public func translateTo(
        _ x: Double,
        _ y: Double,
        point: XYPosition? = nil,
        event: ZoomSourceEvent? = nil,
        duration: Double? = nil,
        onEnd: (() -> Void)? = nil
    ) {
        applyTransform(
            provider: { [unowned self] in
                let e = self.extent()
                let t = self.transform
                let p0 = point ?? self.centroid(e)
                return self.constrain(
                    ZoomTransform.identity.translate(p0.x, p0.y).scale(t.k).translate(-x, -y),
                    e, self.translateExtent)
            },
            point: point, event: event, duration: duration, onEnd: onEnd)
    }

    /// Brings the transform in line with a viewport that was set elsewhere. Nothing is constrained and
    /// the listeners are told with a `sync` event.
    public func setTransformDirectly(_ value: ZoomTransform) {
        transform = value
    }

    private func scale(_ transform: ZoomTransform, _ k: Double) -> ZoomTransform {
        let value = jsMax(scaleExtent.0, jsMin(scaleExtent.1, k))
        return value == transform.k ? transform : ZoomTransform(k: value, x: transform.x, y: transform.y)
    }

    private func translate(_ transform: ZoomTransform, _ p0: XYPosition, _ p1: XYPosition) -> ZoomTransform {
        let x = p0.x - p1.x * transform.k
        let y = p0.y - p1.y * transform.k
        return x == transform.x && y == transform.y ? transform : ZoomTransform(k: transform.k, x: x, y: y)
    }

    private func centroid(_ extent: CoordinateExtent) -> XYPosition {
        XYPosition(x: (extent.minX + extent.maxX) / 2, y: (extent.minY + extent.maxY) / 2)
    }

    private func schedule(
        _ transition: D3Transition,
        _ target: @escaping () -> ZoomTransform,
        _ point: XYPosition?,
        _ event: ZoomSourceEvent?
    ) {
        transition.on.on("start.zoom") { [unowned self] _ in
            self.gesture().event(event).start()
        }
        transition.on.on("interrupt.zoom end.zoom") { [unowned self] _ in
            self.gesture().event(event).end()
        }
        transition.tween { [unowned self] in
            let g = self.gesture().event(event)
            let e = self.extent()
            let p = point ?? self.centroid(e)
            let w = jsMax(e.maxX - e.minX, e.maxY - e.minY)
            let a = self.transform
            let b = target()
            let ia = a.invert(p)
            let ib = b.invert(p)
            let i = self.interpolate((ia.x, ia.y, w / a.k), (ib.x, ib.y, w / b.k))

            return { t in
                let result: ZoomTransform
                if t == 1 {
                    // Avoid rounding error on end.
                    result = b
                } else {
                    let l = i(t)
                    let k = w / l.w
                    result = ZoomTransform(k: k, x: p.x - l.ux * k, y: p.y - l.uy * k)
                }
                g.zoom(nil, result)
            }
        }
    }

    // MARK: Gestures

    fileprivate func gesture(clean: Bool = false) -> ZoomGesture {
        if !clean, let zooming { return zooming }
        return ZoomGesture(behavior: self, extent: extent())
    }

    fileprivate func emit(_ type: String, _ sourceEvent: ZoomSourceEvent?) {
        listeners.call(type, ZoomEvent(type: type, sourceEvent: sourceEvent, transform: transform))
    }

    fileprivate func storeTransform(_ value: ZoomTransform) {
        transform = value
    }

    // MARK: Input

    /// A wheel event. It goes to `wheelHandler`.
    public func handleWheel(_ event: ZoomSourceEvent) {
        wheelHandler?(event)
    }

    /// A double click. It goes to `dblclickHandler`.
    public func handleDoubleClick(_ event: ZoomSourceEvent) {
        dblclickHandler?(event)
    }

    public func wheeled(_ event: ZoomSourceEvent) {
        if !filter(event) { return }

        let g = gesture().event(event)
        let t = transform
        let k = jsMax(scaleExtent.0, jsMin(scaleExtent.1, t.k * pow(2, wheelDelta(event))))
        let p = event.point

        // If the mouse is in the same location as before, reuse it.
        // If there were recent wheel events, reset the wheel idle timeout.
        if g.wheel != nil {
            if let mouse = g.mouse, mouse.p.x != p.x || mouse.p.y != p.y {
                g.mouse = (p, t.invert(p))
            }
            clearTimeout(g.wheel)
        }

        // If this wheel event won't trigger a transform change, ignore it.
        else if t.k == k { return }

        // Otherwise, capture the mouse point and location at the start.
        else {
            g.mouse = (p, t.invert(p))
            transitions.interrupt()
            g.start()
        }

        event.preventDefault()
        g.wheel = setTimeout(wheelDelay) { [weak g] in
            g?.wheel = nil
            g?.end()
        }

        guard let mouse = g.mouse else { return }
        g.zoom("mouse", constrain(translate(scale(t, k), mouse.p, mouse.l), g.extent, translateExtent))
    }

    /// A mouse button went down on the element. When the filter lets it through a gesture starts,
    /// which `mouseMoved` and `mouseUpped` carry on. Returns whether one started.
    @discardableResult
    public func mousedowned(_ event: ZoomSourceEvent) -> Bool {
        if touchEnding != nil || !filter(event) { return false }

        let g = gesture(clean: true).event(event)
        let p = event.point

        mouseGesture = (g, event.clientX, event.clientY)
        g.mouse = (p, transform.invert(p))
        g.moved = false
        transitions.interrupt()
        g.start()
        return true
    }

    public var isMouseGestureActive: Bool {
        mouseGesture != nil
    }

    public func mousemoved(_ event: ZoomSourceEvent) {
        guard let (g, x0, y0) = mouseGesture, let mouse = g.mouse else { return }

        if !g.moved {
            let dx = event.clientX - x0
            let dy = event.clientY - y0
            g.moved = dx * dx + dy * dy > clickDistance2
        }

        let point = event.point
        g.mouse = (point, mouse.l)
        _ = g.event(event).zoom(
            "mouse", constrain(translate(transform, point, mouse.l), g.extent, translateExtent))
    }

    public func mouseupped(_ event: ZoomSourceEvent) {
        guard let (g, _, _) = mouseGesture else { return }
        mouseGesture = nil
        _ = g.event(event).end()
    }

    public func dblclicked(_ event: ZoomSourceEvent) {
        if !filter(event) { return }

        let t0 = transform
        let p0 = event.changedTouches.first?.point ?? event.point
        let p1 = t0.invert(p0)
        let k1 = t0.k * (event.shiftKey ? 0.5 : 2)
        let t1 = constrain(translate(scale(t0, k1), p0, p1), extent(), translateExtent)

        event.preventDefault()
        if duration > 0 {
            transitions.transition(duration: duration) { transition in
                schedule(transition, { t1 }, p0, event)
            }
        } else {
            applyTransform(t1, point: p0, event: event)
        }
    }

    public func touchstarted(_ event: ZoomSourceEvent) {
        if !filter(event) { return }

        let touches = event.touches
        let n = touches.count
        let g = gesture(clean: event.changedTouches.count == n).event(event)
        var started = false
        var lastPoint = XYPosition.zero

        for touch in touches {
            let p = touch.point
            lastPoint = p
            let state = ZoomTouchState(p: p, l: transform.invert(p), identifier: touch.identifier)
            if g.touch0 == nil {
                g.touch0 = state
                started = true
                g.taps = 1 + (touchStarting != nil ? 1 : 0)
            } else if g.touch1 == nil && g.touch0?.identifier != state.identifier {
                g.touch1 = state
                g.taps = 0
            }
        }

        if touchStarting != nil {
            clearTimeout(touchStarting)
            touchStarting = nil
        }

        if started {
            if g.taps < 2 {
                touchFirst = lastPoint
                touchStarting = setTimeout(touchDelay) { [weak self] in
                    self?.touchStarting = nil
                }
            }
            transitions.interrupt()
            g.start()
        }
    }

    public func touchmoved(_ event: ZoomSourceEvent) {
        guard zooming != nil else { return }

        let g = gesture().event(event)

        for touch in event.changedTouches {
            if g.touch0?.identifier == touch.identifier {
                g.touch0?.p = touch.point
            } else if g.touch1?.identifier == touch.identifier {
                g.touch1?.p = touch.point
            }
        }

        var t = transform
        let p: XYPosition
        let l: XYPosition

        if let touch1 = g.touch1, let touch0 = g.touch0 {
            let p0 = touch0.p, l0 = touch0.l
            let p1 = touch1.p, l1 = touch1.l
            let dp = (p1.x - p0.x) * (p1.x - p0.x) + (p1.y - p0.y) * (p1.y - p0.y)
            let dl = (l1.x - l0.x) * (l1.x - l0.x) + (l1.y - l0.y) * (l1.y - l0.y)
            t = scale(t, (dp / dl).squareRoot())
            p = XYPosition(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
            l = XYPosition(x: (l0.x + l1.x) / 2, y: (l0.y + l1.y) / 2)
        } else if let touch0 = g.touch0 {
            p = touch0.p
            l = touch0.l
        } else {
            return
        }

        g.zoom("touch", constrain(translate(t, p, l), g.extent, translateExtent))
    }

    public func touchended(_ event: ZoomSourceEvent) {
        guard zooming != nil else { return }

        let g = gesture().event(event)
        let touches = event.changedTouches
        var lastTouch: ZoomTouch?

        if touchEnding != nil { clearTimeout(touchEnding) }
        touchEnding = setTimeout(touchDelay) { [weak self] in
            self?.touchEnding = nil
        }

        for touch in touches {
            lastTouch = touch
            if g.touch0?.identifier == touch.identifier {
                g.touch0 = nil
            } else if g.touch1?.identifier == touch.identifier {
                g.touch1 = nil
            }
        }

        if g.touch1 != nil && g.touch0 == nil {
            g.touch0 = g.touch1
            g.touch1 = nil
        }

        if var touch = g.touch0 {
            touch.l = transform.invert(touch.p)
            g.touch0 = touch
        } else {
            _ = g.end()

            // If this was a dbltap, reroute to the (optional) dblclick.zoom handler.
            if g.taps == 2, let touch = lastTouch, let first = touchFirst {
                let t = touch.point
                if hypot(first.x - t.x, first.y - t.y) < tapDistance {
                    dblclickHandler?(event)
                }
            }
        }
    }
}

struct ZoomTouchState {
    /// where the finger is
    var p: XYPosition
    /// where that is on the content
    var l: XYPosition
    var identifier: Int
}

final class ZoomGesture {
    unowned let behavior: D3ZoomBehavior
    var active = 0
    var sourceEvent: ZoomSourceEvent?
    var extent: CoordinateExtent
    var taps = 0
    var mouse: (p: XYPosition, l: XYPosition)?
    var touch0: ZoomTouchState?
    var touch1: ZoomTouchState?
    var wheel: Int?
    var moved = false

    init(behavior: D3ZoomBehavior, extent: CoordinateExtent) {
        self.behavior = behavior
        self.extent = extent
    }

    @discardableResult
    func event(_ event: ZoomSourceEvent?) -> ZoomGesture {
        if let event { sourceEvent = event }
        return self
    }

    @discardableResult
    func start() -> ZoomGesture {
        active += 1
        if active == 1 {
            behavior.zooming = self
            behavior.emit("start", sourceEvent)
        }
        return self
    }

    @discardableResult
    func zoom(_ key: String?, _ transform: ZoomTransform) -> ZoomGesture {
        if let mouse, key != "mouse" { self.mouse = (mouse.p, transform.invert(mouse.p)) }
        if key != "touch" {
            if var touch = touch0 {
                touch.l = transform.invert(touch.p)
                touch0 = touch
            }
            if var touch = touch1 {
                touch.l = transform.invert(touch.p)
                touch1 = touch
            }
        }
        behavior.storeTransform(transform)
        behavior.emit("zoom", sourceEvent)
        return self
    }

    @discardableResult
    func end() -> ZoomGesture {
        active -= 1
        if active == 0 {
            behavior.zooming = nil
            behavior.emit("end", sourceEvent)
        }
        return self
    }
}
