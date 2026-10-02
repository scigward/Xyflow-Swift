import Foundation

/// A dictionary that iterates in insertion order and has reference semantics, like the `Map` the
/// lookups of a flow are built on. Setting a key that is already there keeps its place, deleting a
/// key and setting it again moves it to the end.
public final class OrderedMap<Key: Hashable, Value>: Sequence {
    private var order: [Key] = []
    private var storage: [Key: Value] = [:]

    public init() {}

    public init(_ other: OrderedMap<Key, Value>) {
        order = other.order
        storage = other.storage
    }

    public init<S: Sequence>(_ pairs: S) where S.Element == (Key, Value) {
        for (key, value) in pairs { set(key, value) }
    }

    public var count: Int { order.count }
    public var isEmpty: Bool { order.isEmpty }
    public var size: Int { order.count }
    public var keys: [Key] { order }
    public var values: [Value] { order.compactMap { storage[$0] } }

    public func get(_ key: Key) -> Value? {
        storage[key]
    }

    public func has(_ key: Key) -> Bool {
        storage[key] != nil
    }

    @discardableResult
    public func set(_ key: Key, _ value: Value) -> OrderedMap<Key, Value> {
        if storage.updateValue(value, forKey: key) == nil {
            order.append(key)
        }
        return self
    }

    @discardableResult
    public func delete(_ key: Key) -> Bool {
        guard storage.removeValue(forKey: key) != nil else { return false }
        if let index = order.firstIndex(of: key) {
            order.remove(at: index)
        }
        return true
    }

    public func clear() {
        order.removeAll()
        storage.removeAll()
    }

    public subscript(key: Key) -> Value? {
        get { storage[key] }
        set {
            if let newValue {
                set(key, newValue)
            } else {
                delete(key)
            }
        }
    }

    public func forEach(_ body: (Value, Key) -> Void) {
        for key in order {
            if let value = storage[key] {
                body(value, key)
            }
        }
    }

    public func makeIterator() -> AnyIterator<(key: Key, value: Value)> {
        var index = 0
        let snapshot = order
        return AnyIterator {
            while index < snapshot.count {
                let key = snapshot[index]
                index += 1
                if let value = self.storage[key] {
                    return (key: key, value: value)
                }
            }
            return nil
        }
    }
}
