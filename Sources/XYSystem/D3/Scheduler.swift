import Foundation

/// The clock, the animation frames and the timeouts everything that animates runs on. The default
/// one is driven by the main queue; the UIKit flow view installs one that follows the display.
public protocol FlowScheduler: AnyObject {
    /// `performance.now()`: milliseconds of a monotonic clock.
    func now() -> Double
    /// `requestAnimationFrame`: the callback runs before the next frame, with the clock's time.
    func requestAnimationFrame(_ callback: @escaping (Double) -> Void) -> Int
    func cancelAnimationFrame(_ id: Int)
    /// `setTimeout`: the delay is in milliseconds.
    func setTimeout(_ delay: Double, _ callback: @escaping () -> Void) -> Int
    func clearTimeout(_ id: Int)
}

/// The scheduler everything of the module that animates runs on.
public enum FlowRuntime {
    public static var scheduler: FlowScheduler = DefaultScheduler()
}

/// Frames at about sixty per second, on the main queue.
public final class DefaultScheduler: FlowScheduler {
    private var nextId = 1
    private var frames: [Int: (Double) -> Void] = [:]
    private var frameScheduled = false
    private var timeouts: Set<Int> = []

    public init() {}

    public func now() -> Double {
        ProcessInfo.processInfo.systemUptime * 1000
    }

    public func requestAnimationFrame(_ callback: @escaping (Double) -> Void) -> Int {
        let id = nextId
        nextId += 1
        frames[id] = callback

        if !frameScheduled {
            frameScheduled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 60.0) { [weak self] in
                guard let self else { return }
                self.frameScheduled = false
                let pending = self.frames
                self.frames.removeAll()
                let time = self.now()
                for key in pending.keys.sorted() {
                    pending[key]?(time)
                }
            }
        }

        return id
    }

    public func cancelAnimationFrame(_ id: Int) {
        frames[id] = nil
    }

    public func setTimeout(_ delay: Double, _ callback: @escaping () -> Void) -> Int {
        let id = nextId
        nextId += 1
        timeouts.insert(id)

        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, delay) / 1000) { [weak self] in
            guard let self, self.timeouts.remove(id) != nil else { return }
            callback()
        }

        return id
    }

    public func clearTimeout(_ id: Int) {
        timeouts.remove(id)
    }
}

/// `requestAnimationFrame` on the scheduler of the module.
@discardableResult
public func requestAnimationFrame(_ callback: @escaping () -> Void) -> Int {
    FlowRuntime.scheduler.requestAnimationFrame { _ in callback() }
}

public func cancelAnimationFrame(_ id: Int) {
    FlowRuntime.scheduler.cancelAnimationFrame(id)
}

@discardableResult
public func setTimeout(_ delay: Double, _ callback: @escaping () -> Void) -> Int {
    FlowRuntime.scheduler.setTimeout(delay, callback)
}

public func clearTimeout(_ id: Int?) {
    guard let id else { return }
    FlowRuntime.scheduler.clearTimeout(id)
}
