import Foundation

/// Hands what a function with a completion handler answers to code that awaits it. `start` is given the
/// handler to pass on. The answer is `nil` when the handler is let go of without being called, which is
/// what happens to the handler of a transition that is interrupted: the promises of the web version are
/// left open then, and awaiting one here would never come back.
public func awaitHandler<Value>(_ start: (_ handler: @escaping (Value) -> Void) -> Void) async -> Value? {
    await withCheckedContinuation { (continuation: CheckedContinuation<Value?, Never>) in
        let box = HandlerBox<Value>(continuation)
        start { value in box.resume(value) }
    }
}

/// `awaitHandler` for the `Bool` that tells whether something worked, which is `false` when it did not
/// finish.
public func awaitCompletion(_ start: (_ completion: @escaping (Bool) -> Void) -> Void) async -> Bool {
    await awaitHandler(start) ?? false
}

private final class HandlerBox<Value> {
    private var continuation: CheckedContinuation<Value?, Never>?
    private let lock = NSLock()

    init(_ continuation: CheckedContinuation<Value?, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: Value?) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()

        pending?.resume(returning: value)
    }

    deinit {
        resume(nil)
    }
}

/// `onbeforedelete` for a function that is `async`, which is what it is on the web (it returns a
/// promise). The answer is used on the main actor, where the stores are changed.
public func asyncOnBeforeDelete(
    _ handler: @escaping (_ nodes: [Node], _ edges: [Edge]) async -> BeforeDeleteResult
) -> OnBeforeDelete {
    { nodes, edges, completion in
        Task { @MainActor in
            completion(await handler(nodes, edges))
        }
    }
}

extension PanZoomInstance {
    public func setViewport(_ viewport: Viewport, options: PanZoomTransformOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            setViewport(viewport, options: options) { done($0 != nil) }
        }
    }

    public func setViewportConstrained(
        _ viewport: Viewport,
        extent: CoordinateExtent,
        translateExtent: CoordinateExtent
    ) async -> Bool {
        await awaitCompletion { done in
            setViewportConstrained(viewport, extent: extent, translateExtent: translateExtent) { done($0 != nil) }
        }
    }

    public func scaleTo(_ scale: Double, options: PanZoomTransformOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            scaleTo(scale, options: options, completion: done)
        }
    }

    public func scaleBy(_ factor: Double, options: PanZoomTransformOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            scaleBy(factor, options: options, completion: done)
        }
    }
}

/// `getElementsToRemove` for an `onBeforeDelete` that answers later, awaited.
public func getElementsToRemove(
    nodesToRemove: [String] = [],
    edgesToRemove: [String] = [],
    nodes: [Node],
    edges: [Edge],
    onBeforeDelete: OnBeforeDelete? = nil
) async -> (nodes: [Node], edges: [Edge]) {
    let answer: (nodes: [Node], edges: [Edge])? = await awaitHandler { handler in
        getElementsToRemove(
            nodesToRemove: nodesToRemove,
            edgesToRemove: edgesToRemove,
            nodes: nodes,
            edges: edges,
            onBeforeDelete: onBeforeDelete
        ) { matchingNodes, matchingEdges in
            handler((matchingNodes, matchingEdges))
        }
    }

    return answer ?? ([], [])
}
