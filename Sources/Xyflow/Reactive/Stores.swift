#if canImport(UIKit)
import Foundation

/// Stops a subscription.
public typealias Unsubscribe = () -> Void

/// Something that tells when it changes, whatever its value is.
public protocol AnyStore: AnyObject {
    /// Calls `run` whenever the store changes, and once right away.
    @discardableResult
    func subscribeAny(_ run: @escaping () -> Void) -> Unsubscribe
}

/// A store the value of which can be read and followed (`svelte/store` `Readable`).
open class Readable<Value>: AnyStore {
    fileprivate var storedValue: Value
    private var subscribers: [Int: (Value) -> Void] = [:]
    private var order: [Int] = []
    private var nextId = 0
    private var isNotifying = false
    private var pending: [Value] = []

    public init(_ value: Value) {
        storedValue = value
    }

    /// The current value, `get(store)`.
    public func get() -> Value {
        storedValue
    }

    /// Calls `run` with the current value and with every value that follows.
    @discardableResult
    public func subscribe(_ run: @escaping (Value) -> Void) -> Unsubscribe {
        let id = nextId
        nextId += 1
        subscribers[id] = run
        order.append(id)
        run(storedValue)

        return { [weak self] in
            self?.subscribers[id] = nil
            self?.order.removeAll { $0 == id }
        }
    }

    @discardableResult
    public func subscribeAny(_ run: @escaping () -> Void) -> Unsubscribe {
        subscribe { _ in run() }
    }

    /// Tells the subscribers. A value that is set while they are told is told after them, in order.
    fileprivate func publish(_ value: Value) {
        pending.append(value)

        if isNotifying {
            return
        }

        isNotifying = true
        defer { isNotifying = false }

        while !pending.isEmpty {
            let next = pending.removeFirst()
            for id in order {
                subscribers[id]?(next)
            }
        }
    }

    /// Sets the value and tells the subscribers when the value is a different one: numbers, strings
    /// and booleans are compared, everything else counts as changed (`safe_not_equal`).
    fileprivate func assign(_ newValue: Value) {
        if let equal = Readable.primitivesAreEqual(storedValue, newValue), equal {
            return
        }

        storedValue = newValue
        publish(newValue)
    }

    private static func primitivesAreEqual(_ a: Value, _ b: Value) -> Bool? {
        let x: Any = a
        let y: Any = b

        if let x = x as? Bool, let y = y as? Bool { return x == y }
        if let x = x as? Int, let y = y as? Int { return x == y }
        if let x = x as? Double, let y = y as? Double { return x == y }
        if let x = x as? String, let y = y as? String { return x == y }

        return nil
    }
}

/// A store the value of which can be set (`svelte/store` `Writable`).
open class Writable<Value>: Readable<Value> {
    /// When a store is kept in sync with another one, its setter goes through this.
    public var setOverride: ((Value) -> Void)?

    public override init(_ value: Value) {
        super.init(value)
    }

    open func set(_ newValue: Value) {
        if let setOverride {
            setOverride(newValue)
            return
        }

        rawSet(newValue)
    }

    /// Sets the value without anything that was put around the setter.
    open func rawSet(_ newValue: Value) {
        assign(newValue)
    }

    public func update(_ updater: (Value) -> Value) {
        set(updater(get()))
    }
}

/// A store derived from others: it is computed again whenever one of them changes (`derived`).
///
/// The stores in `quiet` are the ones that change all the time while the value rarely does, like the
/// viewport that a list of what is on screen is derived from. When one of them changed the value is
/// computed, but the subscribers are only told if `isEqual` says that it is another value than before.
public final class Derived<Value>: Readable<Value> {
    private var unsubscribers: [Unsubscribe] = []
    private let compute: () -> Value
    private let isEqual: ((Value, Value) -> Bool)?

    public init(
        _ dependencies: [AnyStore],
        quiet quietDependencies: [AnyStore] = [],
        isEqual: ((Value, Value) -> Bool)? = nil,
        compute: @escaping () -> Value
    ) {
        self.compute = compute
        self.isEqual = isEqual
        super.init(compute())

        for dependency in dependencies {
            follow(dependency, quiet: false)
        }
        for dependency in quietDependencies {
            follow(dependency, quiet: true)
        }
    }

    private func follow(_ dependency: AnyStore, quiet: Bool) {
        var first = true
        unsubscribers.append(dependency.subscribeAny { [weak self] in
            if first {
                first = false
                return
            }
            self?.recompute(quiet: quiet)
        })
    }

    private func recompute(quiet: Bool) {
        let value = compute()
        if quiet, let isEqual, isEqual(storedValue, value) {
            return
        }
        assign(value)
    }

    deinit {
        unsubscribers.forEach { $0() }
    }
}

/// Whether two lists hold the very same objects in the same order.
func sameObjects<Element: AnyObject>(_ first: [Element], _ second: [Element]) -> Bool {
    if first.count != second.count { return false }
    for index in first.indices where first[index] !== second[index] {
        return false
    }
    return true
}

/// A store with a value that never changes, `readable(value)`.
public func readable<Value>(_ initial: Value) -> Readable<Value> {
    Readable(initial)
}
#endif
