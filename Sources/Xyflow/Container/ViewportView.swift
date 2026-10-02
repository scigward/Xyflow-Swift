#if canImport(UIKit)
import UIKit
import XYSystem

/// `Viewport.svelte`: the content of the flow, which is moved and scaled with the viewport.
/// `transform-origin` is the top left corner: the view is translated by the viewport and then scaled.
final class FlowViewportView: FlowPassthroughView {
    private let store: SwiftFlowStore
    private var subscription: Unsubscribe?

    /// The scale the content is shown at.
    private(set) var zoom: Double = 1

    init(store: SwiftFlowStore) {
        self.store = store
        super.init(frame: .zero)

        flowClasses = ["svelte-flow__viewport", "xyflow__viewport"]
        layer.anchorPoint = .zero

        subscription = store.viewport.subscribe { [weak self] viewport in
            self?.apply(viewport)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        subscription?()
    }

    /// `transform: translate(x, y) scale(zoom)`
    private func apply(_ viewport: Viewport) {
        zoom = viewport.zoom

        // a view that is not at its own origin: position is where the top left corner is
        layer.position = CGPoint(x: viewport.x, y: viewport.y)
        transform = CGAffineTransform(scaleX: CGFloat(viewport.zoom), y: CGFloat(viewport.zoom))
    }

    /// The size of the viewport is the size of the flow. The anchor stays at the top left corner.
    func setContainerSize(_ size: CGSize) {
        if bounds.size == size { return }

        let position = layer.position
        let current = transform
        transform = .identity
        bounds = CGRect(origin: .zero, size: size)
        layer.position = position
        transform = current
    }
}
#endif
