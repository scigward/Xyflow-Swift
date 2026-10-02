import Foundation

public func areConnectionMapsEqual(
    _ a: OrderedMap<String, HandleConnection>?,
    _ b: OrderedMap<String, HandleConnection>?
) -> Bool {
    if a == nil && b == nil {
        return true
    }

    guard let a, let b, a.count == b.count else {
        return false
    }

    if a.count == 0 && b.count == 0 {
        return true
    }

    for key in a.keys {
        if !b.has(key) {
            return false
        }
    }

    return true
}

/// We call the callback for all connections in a that are not in b.
public func handleConnectionChange(
    _ a: OrderedMap<String, HandleConnection>,
    _ b: OrderedMap<String, HandleConnection>,
    callback: (([HandleConnection]) -> Void)?
) {
    guard let callback else {
        return
    }

    var diff: [HandleConnection] = []

    a.forEach { connection, key in
        if !b.has(key) {
            diff.append(connection)
        }
    }

    if !diff.isEmpty {
        callback(diff)
    }
}

/// `"valid"` or `"invalid"` for a connection that is over a handle, `nil` for one that is not.
public func getConnectionStatus(_ isValid: Bool?) -> String? {
    guard let isValid else { return nil }
    return isValid ? "valid" : "invalid"
}
