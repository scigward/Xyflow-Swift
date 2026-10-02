import Foundation

/// A transition of an element, like `selection.transition()` makes one: it starts on the next
/// frame, runs its tweens with an eased time for `duration` milliseconds and then ends. Starting
/// another transition on the element interrupts the one that runs.
public final class D3Transition {
    public enum State: Int {
        case created
        case scheduled
        case starting
        case started
        case running
        case ending
        case ended
    }

    fileprivate let id: Int
    public let duration: Double
    public var ease: (Double) -> Double = easeCubicInOut
    fileprivate let time: Double
    public fileprivate(set) var state: State = .created
    /// The listeners of `start`, `end`, `cancel` and `interrupt`.
    public let on = D3Dispatch<Void>(["start", "end", "cancel", "interrupt"])

    fileprivate weak var host: D3TransitionHost?
    private var tweenFactories: [() -> ((Double) -> Void)?] = []
    private var tweens: [(Double) -> Void] = []
    private var frame: Int?

    fileprivate init(host: D3TransitionHost, id: Int, duration: Double) {
        self.host = host
        self.id = id
        self.duration = duration
        self.time = FlowRuntime.scheduler.now()
    }

    /// Adds a tween. `factory` runs when the transition starts, after its start listeners, and
    /// returns what is called with the eased time on every frame.
    public func tween(_ factory: @escaping () -> ((Double) -> Void)?) {
        tweenFactories.append(factory)
    }

    fileprivate func begin() {
        requestFrame { [weak self] time in
            self?.schedule(elapsed: time - (self?.time ?? time))
        }
    }

    private func requestFrame(_ callback: @escaping (Double) -> Void) {
        frame = FlowRuntime.scheduler.requestAnimationFrame { callback($0) }
    }

    fileprivate func stopTimer() {
        if let frame {
            FlowRuntime.scheduler.cancelAnimationFrame(frame)
        }
        frame = nil
    }

    private func schedule(elapsed: Double) {
        guard state == .created else { return }
        state = .scheduled
        start(elapsed: elapsed)
    }

    private func start(elapsed: Double) {
        guard state == .scheduled else {
            stop()
            return
        }

        guard let host else { return }

        for (otherId, other) in host.schedules.sorted(by: { $0.key < $1.key }) where otherId != id {
            // Interrupt the active transition, if any.
            if other.state == .started || other.state == .running {
                other.state = .ended
                other.stopTimer()
                other.on.call("interrupt")
                host.schedules[otherId] = nil
            }
            // Cancel any pre-empted transitions.
            else if otherId < id {
                other.state = .ended
                other.stopTimer()
                other.on.call("cancel")
                host.schedules[otherId] = nil
            }
        }

        // Dispatch the start event. Note this must be done before the tween are initialized.
        state = .starting
        on.call("start")
        if state != .starting { return } // interrupted
        state = .started

        // Initialize the tween, deleting null tween.
        tweens = tweenFactories.compactMap { $0() }

        state = .running
        tick(elapsed: elapsed)

        if state == .running {
            requestFrame { [weak self] time in
                self?.frameTick(time)
            }
        }
    }

    private func frameTick(_ time: Double) {
        guard state == .running else { return }
        tick(elapsed: time - self.time)

        if state == .running {
            requestFrame { [weak self] time in
                self?.frameTick(time)
            }
        }
    }

    private func tick(elapsed: Double) {
        let t: Double
        if elapsed < duration {
            t = ease(elapsed / duration)
        } else {
            stopTimer()
            state = .ending
            t = 1
        }

        for tween in tweens {
            tween(t)
        }

        // Dispatch the end event.
        if state == .ending {
            on.call("end")
            stop()
        }
    }

    private func stop() {
        state = .ended
        stopTimer()
        host?.schedules[id] = nil
    }

    fileprivate func interruptNow() {
        let active = state.rawValue > State.starting.rawValue && state.rawValue < State.ending.rawValue
        state = .ended
        stopTimer()
        on.call(active ? "interrupt" : "cancel")
    }
}

/// What an element keeps of its transitions, `node.__transition`.
public final class D3TransitionHost {
    fileprivate var schedules: [Int: D3Transition] = [:]
    private var nextId = 0

    public init() {}

    /// `selection.transition().duration(duration)`, started on the next frame.
    @discardableResult
    public func transition(duration: Double, configure: (D3Transition) -> Void) -> D3Transition {
        nextId += 1
        let transition = D3Transition(host: self, id: nextId, duration: duration)
        schedules[nextId] = transition
        configure(transition)
        transition.begin()
        return transition
    }

    /// `selection.interrupt()`: the transitions of the element end where they are.
    public func interrupt() {
        let current = schedules.sorted { $0.key < $1.key }
        schedules.removeAll()
        for (_, transition) in current {
            transition.interruptNow()
        }
    }

    public var isTransitioning: Bool {
        !schedules.isEmpty
    }
}
