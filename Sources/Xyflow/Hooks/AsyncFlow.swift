#if canImport(UIKit)
import Foundation
import XYSystem

// The promises of the web version, as `async` functions. Each answers what the completion handler of the
// function of the same name is told. Like the promise of the interface, the one of a viewport change
// that is cut short by the user answers `false`.

extension SwiftFlowStore {
    public func fitView(_ options: FitViewOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            fitView(options, completion: done)
        }
    }

    public func zoomBy(_ factor: Double, _ options: ViewportHelperFunctionOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            zoomBy(factor, options, completion: done)
        }
    }

    public func zoomIn(_ options: ViewportHelperFunctionOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            zoomIn(options, completion: done)
        }
    }

    public func zoomOut(_ options: ViewportHelperFunctionOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            zoomOut(options, completion: done)
        }
    }

    public func panBy(_ delta: XYPosition) async -> Bool {
        await awaitCompletion { done in
            panBy(delta, completion: done)
        }
    }
}

extension FlowInstance {
    public func zoomIn(_ options: ViewportHelperFunctionOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            zoomIn(options, completion: done)
        }
    }

    public func zoomOut(_ options: ViewportHelperFunctionOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            zoomOut(options, completion: done)
        }
    }

    public func setZoom(_ zoomLevel: Double, _ options: ViewportHelperFunctionOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            setZoom(zoomLevel, options, completion: done)
        }
    }

    public func setViewport(_ viewport: Viewport, _ options: ViewportHelperFunctionOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            setViewport(viewport, options, completion: done)
        }
    }

    public func setCenter(_ x: Double, _ y: Double, _ options: SetCenterOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            setCenter(x, y, options, completion: done)
        }
    }

    public func fitView(_ options: FitViewOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            fitView(options, completion: done)
        }
    }

    public func fitBounds(_ bounds: Rect, _ options: FitBoundsOptions? = nil) async -> Bool {
        await awaitCompletion { done in
            fitBounds(bounds, options, completion: done)
        }
    }

    /// Deletes nodes and edges, and the edges that belong to the nodes. Answers what was deleted.
    public func deleteElements(
        nodes nodesToRemove: [String] = [],
        edges edgesToRemove: [String] = []
    ) async -> (deletedNodes: [Node], deletedEdges: [Edge]) {
        let deleted: (nodes: [Node], edges: [Edge])? = await awaitHandler { handler in
            deleteElements(nodes: nodesToRemove, edges: edgesToRemove) { deletedNodes, deletedEdges in
                handler((deletedNodes, deletedEdges))
            }
        }

        return (deleted?.nodes ?? [], deleted?.edges ?? [])
    }
}
#endif
