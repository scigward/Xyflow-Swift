#if canImport(UIKit)
import UIKit
import XYSystem

/// Takes the touches and the pointer of the flow to where the events of the interface go. A press goes
/// from the view it started on up through the views around it, the way the events of a page bubble:
/// the handle of a node starts a connection, a node (or the selection) is dragged, the pane draws a
/// selection, and what none of them takes pans and zooms the flow. Releasing without moving is a click.
final class FlowTouchRouter: UIGestureRecognizer, UIGestureRecognizerDelegate {
    private unowned let flow: SwiftFlow

    /// How far a finger can move and still tap, which is what a browser lets it do.
    private let touchSlop: CGFloat = 10

    /// One finger, or the pointer, that is on the flow, and what took it.
    private final class Track {
        let id: Int
        let isPointer: Bool
        let button: Int
        let startClient: CGPoint
        var lastClient: CGPoint
        weak var target: UIView?
        var handleOwner = false
        var dragHost: FlowDragHost?
        var ownsPane = false
        var ownsZoom = false

        init(id: Int, isPointer: Bool, button: Int, client: CGPoint, target: UIView?) {
            self.id = id
            self.isPointer = isPointer
            self.button = button
            self.startClient = client
            self.lastClient = client
            self.target = target
        }
    }

    private var tracks: [ObjectIdentifier: Track] = [:]
    private var nextTouchId = 0
    private var lastPointerClick: (time: TimeInterval, point: CGPoint)?

    init(flow: SwiftFlow) {
        self.flow = flow
        super.init(target: nil, action: nil)

        delegate = self
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        allowedTouchTypes = [
            UITouch.TouchType.direct,
            UITouch.TouchType.indirect,
            UITouch.TouchType.pencil,
            UITouch.TouchType.indirectPointer
        ].map { NSNumber(value: $0.rawValue) }
    }

    // MARK: Delegate

    /// The panels and plugins around the content are not where the pan and zoom are: only what is
    /// on the surface of the flow is routed.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else { return false }
        return view.isDescendant(of: flow.zoomView)
    }

    private func isScrollPan(of other: UIGestureRecognizer) -> Bool {
        guard other is UIPanGestureRecognizer, let scrollView = other.view as? UIScrollView else { return false }
        return flow.isDescendant(of: scrollView)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // what is going on in the flow is not scrolled away by the view it is in
        !isScrollPan(of: otherGestureRecognizer)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        isScrollPan(of: otherGestureRecognizer)
    }

    // MARK: Events

    private func modifiers(of event: UIEvent?) -> EventModifiers {
        var modifiers: EventModifiers = []
        guard let flags = event?.modifierFlags else { return modifiers }

        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.alternate) { modifiers.insert(.alt) }
        if flags.contains(.command) { modifiers.insert(.meta) }
        return modifiers
    }

    private func pointerEvent(_ track: Track, _ event: UIEvent?, ended: Bool = false) -> FlowPointerEvent {
        let touchCount = tracks.values.filter { !$0.isPointer }.count
        let buttons = ended ? 0 : (track.button == 2 ? 2 : 1)

        return FlowPointerEvent(
            kind: track.isPointer ? .mouse : .touch,
            clientX: Double(track.lastClient.x),
            clientY: Double(track.lastClient.y),
            modifiers: modifiers(of: event),
            button: track.button,
            buttons: buttons,
            touchCount: track.isPointer ? 0 : touchCount,
            target: track.target)
    }

    private func zoomEvent(_ type: String, _ track: Track, _ event: FlowPointerEvent) -> ZoomSourceEvent {
        ZoomSourceEvent(
            type: type,
            button: event.button,
            ctrlKey: event.ctrlKey,
            shiftKey: event.shiftKey,
            altKey: event.altKey,
            metaKey: event.metaKey,
            clientX: event.clientX,
            clientY: event.clientY,
            point: flow.zoomPoint(for: event),
            target: track.target)
    }

    private func zoomTouch(_ track: Track) -> ZoomTouch {
        ZoomTouch(
            identifier: track.id,
            point: flow.zoomView.convert(track.lastClient, from: nil).xyPosition,
            clientX: Double(track.lastClient.x),
            clientY: Double(track.lastClient.y))
    }

    /// A touch event the way the zoom behavior reads it: all the fingers that are down, and the ones
    /// that changed.
    private func zoomTouchEvent(_ type: String, changed: [Track], _ event: UIEvent?) -> ZoomSourceEvent {
        let all = tracks.values.filter { !$0.isPointer }.sorted { $0.id < $1.id }
        let first = changed.first

        let source = modifiers(of: event)
        let client = first?.lastClient ?? .zero

        return ZoomSourceEvent(
            type: type,
            ctrlKey: source.contains(.control),
            shiftKey: source.contains(.shift),
            altKey: source.contains(.alt),
            metaKey: source.contains(.meta),
            clientX: Double(client.x),
            clientY: Double(client.y),
            point: flow.zoomView.convert(client, from: nil).xyPosition,
            target: first?.target,
            touches: all.map { zoomTouch($0) },
            changedTouches: changed.map { zoomTouch($0) })
    }

    private func ancestor<T>(of view: UIView?, as type: T.Type) -> T? {
        var current = view
        while let candidate = current {
            if let match = candidate as? T { return match }
            current = candidate.superview
        }
        return nil
    }

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        flow.takeKeyboardFocus()

        for touch in touches {
            guard let view = touch.view else { continue }

            let isPointer = touch.type == .indirectPointer
            let button = isPointer && event.buttonMask.contains(.secondary) ? 2 : 0

            nextTouchId += 1
            let track = Track(
                id: nextTouchId,
                isPointer: isPointer,
                button: button,
                client: touch.location(in: nil),
                target: view)
            tracks[ObjectIdentifier(touch)] = track

            routeDown(track, event)
        }

        if state == .possible && !tracks.isEmpty {
            state = .began
        }
    }

    private func routeDown(_ track: Track, _ event: UIEvent?) {
        let pointerEvent = self.pointerEvent(track, event)
        let target = track.target

        // a handle takes the press, which none of the views around it get
        if let handle = ancestor(of: target, as: FlowPointerDownHandling.self) {
            track.handleOwner = true
            handle.flowPointerDown(event: pointerEvent)
            return
        }

        // the pane starts a selection when it is selecting
        if target === flow.paneView && flow.paneView.hasActiveSelection {
            flow.paneView.pointerDown(pointerEvent)

            if flow.store.selectionRect.get() != nil {
                track.ownsPane = true
                return
            }
        }

        // a node, or the selection of nodes, is dragged: when the filter of the drag lets the press
        // through, the views around the node do not get it
        if let host = ancestor(of: target, as: FlowDragHost.self) {
            let started = host.flowDragBehavior.pointerDown(
                pointerEvent,
                point: flow.zoomPoint(for: pointerEvent),
                identifier: track.id)

            if started {
                track.dragHost = host
                return
            }
        }

        // what is left pans and zooms the flow
        guard let zoom = flow.zoomView.zoomBehavior else { return }

        if track.isPointer {
            track.ownsZoom = zoom.mousedowned(zoomEvent("mousedown", track, pointerEvent))
        } else {
            zoom.touchstarted(zoomTouchEvent("touchstart", changed: [track], event))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        var zoomMoved: [Track] = []

        for touch in touches {
            guard let track = tracks[ObjectIdentifier(touch)] else { continue }

            track.lastClient = touch.location(in: nil)
            let pointerEvent = self.pointerEvent(track, event)

            if track.handleOwner {
                flow.dispatchPointerMove(pointerEvent)
            } else if let host = track.dragHost {
                host.flowDragBehavior.pointerMove(
                    pointerEvent,
                    point: flow.zoomPoint(for: pointerEvent),
                    identifier: track.id)
            } else if track.ownsPane {
                flow.paneView.pointerMove(pointerEvent)
            } else if track.isPointer {
                if track.ownsZoom {
                    flow.zoomView.zoomBehavior?.mousemoved(zoomEvent("mousemove", track, pointerEvent))
                }
            } else {
                zoomMoved.append(track)
            }
        }

        if !zoomMoved.isEmpty {
            flow.zoomView.zoomBehavior?.touchmoved(zoomTouchEvent("touchmove", changed: zoomMoved, event))
        }

        if state == .began || state == .changed {
            state = .changed
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        finish(touches, event, cancelled: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        finish(touches, event, cancelled: true)
    }

    private func finish(_ touches: Set<UITouch>, _ event: UIEvent, cancelled: Bool) {
        var zoomEnded: [Track] = []
        var released: [(track: Track, event: FlowPointerEvent)] = []

        for touch in touches {
            guard let track = tracks.removeValue(forKey: ObjectIdentifier(touch)) else { continue }

            track.lastClient = touch.location(in: nil)
            let pointerEvent = self.pointerEvent(track, event, ended: true)

            if track.handleOwner {
                flow.dispatchPointerUp(pointerEvent)
            } else if let host = track.dragHost {
                if cancelled {
                    host.flowDragBehavior.cancel(identifier: track.id, event: pointerEvent)
                } else {
                    host.flowDragBehavior.pointerUp(
                        pointerEvent,
                        point: flow.zoomPoint(for: pointerEvent),
                        identifier: track.id)
                }
            } else if track.ownsPane {
                flow.paneView.pointerUp(pointerEvent)
            } else if track.isPointer {
                if track.ownsZoom {
                    flow.zoomView.zoomBehavior?.mouseupped(zoomEvent("mouseup", track, pointerEvent))
                }
            } else {
                zoomEnded.append(track)
            }

            released.append((track, pointerEvent))
        }

        if !zoomEnded.isEmpty {
            let type = cancelled ? "touchcancel" : "touchend"
            flow.zoomView.zoomBehavior?.touchended(zoomTouchEvent(type, changed: zoomEnded, event))
        }

        if !cancelled {
            for item in released {
                deliverClick(item.track, item.event)
            }
        }

        if tracks.isEmpty {
            state = cancelled ? .cancelled : .ended
        }
    }

    /// A press that is let go of without moving much is a click on the view it started on.
    private func deliverClick(_ track: Track, _ event: FlowPointerEvent) {
        let dx = track.lastClient.x - track.startClient.x
        let dy = track.lastClient.y - track.startClient.y
        let distance = (dx * dx + dy * dy).squareRoot()

        let isClick: Bool
        if track.isPointer {
            // a click is suppressed when the pointer moved further than the click distance
            let threshold = CGFloat(
                track.dragHost?.flowDragBehavior.clickDistance
                    ?? flow.zoomView.zoomBehavior?.clickDistance
                    ?? 0)
            isClick = distance * distance <= threshold * threshold
        } else {
            isClick = distance <= touchSlop
        }

        guard isClick else { return }

        if track.button == 2 {
            flow.resetKeys()
            flow.dispatchContextMenu(event)
            return
        }

        flow.dispatchClick(event)

        if track.isPointer && track.button == 0 {
            let now = Date().timeIntervalSinceReferenceDate
            let point = CGPoint(x: event.clientX, y: event.clientY)

            if let last = lastPointerClick,
               now - last.time <= 0.4,
               hypot(last.point.x - point.x, last.point.y - point.y) <= 6 {
                lastPointerClick = nil
                flow.zoomView.zoomBehavior?.handleDoubleClick(zoomEvent("dblclick", track, event))
            } else {
                lastPointerClick = (now, point)
            }
        }
    }

    /// The system took the touches away without telling the touches: whatever is going on ends where it is.
    override func reset() {
        let remaining = Array(tracks.values)
        tracks.removeAll()

        var zoomEnded: [Track] = []

        for track in remaining {
            let pointerEvent = self.pointerEvent(track, nil, ended: true)

            if track.handleOwner {
                flow.dispatchPointerUp(pointerEvent)
            } else if let host = track.dragHost {
                host.flowDragBehavior.cancel(identifier: track.id, event: pointerEvent)
            } else if track.ownsPane {
                flow.paneView.pointerUp(pointerEvent)
            } else if track.isPointer {
                if track.ownsZoom {
                    flow.zoomView.zoomBehavior?.mouseupped(zoomEvent("mouseup", track, pointerEvent))
                }
            } else {
                zoomEnded.append(track)
            }
        }

        if !zoomEnded.isEmpty {
            flow.zoomView.zoomBehavior?.touchended(zoomTouchEvent("touchcancel", changed: zoomEnded, nil))
        }
    }
}
#endif
