import Foundation

/// Named listeners of events of a few types, like the dispatch the zoom and drag behaviors keep.
/// A typename is a type with an optional name, `"zoom"` or `"zoom.wheel"`; listeners of the same
/// type and name replace each other, and run in the order they were added.
public final class D3Dispatch<Event> {
    private struct Listener {
        var name: String
        var callback: (Event) -> Void
    }

    private var listeners: [String: [Listener]]

    public init(_ types: [String]) {
        listeners = [:]
        for type in types {
            listeners[type] = []
        }
    }

    private func parse(_ typenames: String) -> [(type: String, name: String)] {
        typenames
            .split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
            .map { part in
                let text = String(part)
                if let dot = text.firstIndex(of: ".") {
                    return (String(text[..<dot]), String(text[text.index(after: dot)...]))
                }
                return (text, "")
            }
    }

    /// Adds, replaces or (with `nil`) removes the listeners of the typenames.
    public func on(_ typenames: String, _ callback: ((Event) -> Void)?) {
        for (type, name) in parse(typenames) {
            guard listeners[type] != nil else { continue }
            listeners[type]?.removeAll { $0.name == name }
            if let callback {
                listeners[type]?.append(Listener(name: name, callback: callback))
            }
        }
    }

    /// Whether there is a listener for the typename, `"zoom"` or `"zoom.wheel"`.
    public func has(_ typename: String) -> Bool {
        parse(typename).contains { parsed in
            listeners[parsed.type]?.contains { $0.name == parsed.name } ?? false
        }
    }

    public func call(_ type: String, _ event: Event) {
        // the list is copied so that a listener may change the listeners
        for listener in listeners[type] ?? [] {
            listener.callback(event)
        }
    }

    public func copy() -> D3Dispatch<Event> {
        let result = D3Dispatch<Event>([])
        result.listeners = listeners
        return result
    }
}

extension D3Dispatch where Event == Void {
    /// For the dispatches that carry no event, the listeners of a transition.
    public func call(_ type: String) {
        call(type, Void())
    }
}
