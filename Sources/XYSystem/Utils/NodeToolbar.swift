import Foundation

/// Where a node toolbar goes: a position in the coordinates of the viewport and how much of the
/// toolbar's own size it is shifted by, in percent.
public struct NodeToolbarTransform: Equatable {
    public var x: Double
    public var y: Double
    public var shiftX: Double
    public var shiftY: Double

    public init(x: Double, y: Double, shiftX: Double, shiftY: Double) {
        self.x = x
        self.y = y
        self.shiftX = shiftX
        self.shiftY = shiftY
    }

    /// The same as the CSS transform of the interface: `translate(x px, y px) translate(shiftX%, shiftY%)`.
    public var cssTransform: String {
        "translate(\(formatNumber(x))px, \(formatNumber(y))px) translate(\(formatNumber(shiftX))%, \(formatNumber(shiftY))%)"
    }
}

public func getNodeToolbarTransform(
    _ nodeRect: Rect,
    _ viewport: Viewport,
    _ position: Position,
    _ offset: Double,
    _ align: Align
) -> NodeToolbarTransform {
    var alignmentOffset = 0.5

    if align == .start {
        alignmentOffset = 0
    } else if align == .end {
        alignmentOffset = 1
    }

    // position === Position.Top
    // we set the x any y position of the toolbar based on the nodes position
    var pos = [
        (nodeRect.x + nodeRect.width * alignmentOffset) * viewport.zoom + viewport.x,
        nodeRect.y * viewport.zoom + viewport.y - offset
    ]
    // and than shift it based on the alignment. The shift values are in %.
    var shift = [-100 * alignmentOffset, -100]

    switch position {
    case .right:
        pos = [
            (nodeRect.x + nodeRect.width) * viewport.zoom + viewport.x + offset,
            (nodeRect.y + nodeRect.height * alignmentOffset) * viewport.zoom + viewport.y
        ]
        shift = [0, -100 * alignmentOffset]
    case .bottom:
        pos[1] = (nodeRect.y + nodeRect.height) * viewport.zoom + viewport.y + offset
        shift[1] = 0
    case .left:
        pos = [
            nodeRect.x * viewport.zoom + viewport.x - offset,
            (nodeRect.y + nodeRect.height * alignmentOffset) * viewport.zoom + viewport.y
        ]
        shift = [-100, -100 * alignmentOffset]
    case .top:
        break
    }

    return NodeToolbarTransform(x: pos[0], y: pos[1], shiftX: shift[0], shiftY: shift[1])
}
