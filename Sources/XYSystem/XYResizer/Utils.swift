import Foundation

/// Which way a resize went on each axis: `0` is no change, `1` an increase and `-1` a decrease.
/// - Parameters:
///   - width: new width of the node
///   - prevWidth: previous width of the node
///   - height: new height of the node
///   - prevHeight: previous height of the node
///   - affectsX: whether to invert the resize direction for the x axis
///   - affectsY: whether to invert the resize direction for the y axis
public func getResizeDirection(
    width: Double,
    prevWidth: Double,
    height: Double,
    prevHeight: Double,
    affectsX: Bool,
    affectsY: Bool
) -> [Double] {
    let deltaWidth = width - prevWidth
    let deltaHeight = height - prevHeight

    var direction: [Double] = [
        deltaWidth > 0 ? 1 : (deltaWidth < 0 ? -1 : 0),
        deltaHeight > 0 ? 1 : (deltaHeight < 0 ? -1 : 0)
    ]

    if deltaWidth != 0 && affectsX {
        direction[0] = direction[0] * -1
    }

    if deltaHeight != 0 && affectsY {
        direction[1] = direction[1] * -1
    }

    return direction
}

public struct ControlDirection: Equatable {
    public var isHorizontal: Bool
    public var isVertical: Bool
    public var affectsX: Bool
    public var affectsY: Bool

    public init(isHorizontal: Bool, isVertical: Bool, affectsX: Bool, affectsY: Bool) {
        self.isHorizontal = isHorizontal
        self.isVertical = isVertical
        self.affectsX = affectsX
        self.affectsY = affectsY
    }
}

/// Parses the control position that is being dragged to dimensions that are being resized.
public func getControlDirection(_ controlPosition: ControlPosition) -> ControlDirection {
    let name = controlPosition.rawValue
    let isHorizontal = name.contains("right") || name.contains("left")
    let isVertical = name.contains("bottom") || name.contains("top")
    let affectsX = name.contains("left")
    let affectsY = name.contains("top")

    return ControlDirection(isHorizontal: isHorizontal, isVertical: isVertical, affectsX: affectsX, affectsY: affectsY)
}

public struct ResizeBoundaries: Equatable {
    public var minWidth: Double
    public var maxWidth: Double
    public var minHeight: Double
    public var maxHeight: Double

    public init(minWidth: Double, maxWidth: Double, minHeight: Double, maxHeight: Double) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
}

public struct ResizeStartValues: Equatable {
    public var width: Double
    public var height: Double
    public var x: Double
    public var y: Double
    public var pointerX: Double
    public var pointerY: Double
    public var aspectRatio: Double

    public init(
        width: Double = 0,
        height: Double = 0,
        x: Double = 0,
        y: Double = 0,
        pointerX: Double = 0,
        pointerY: Double = 0,
        aspectRatio: Double = 1
    ) {
        self.width = width
        self.height = height
        self.x = x
        self.y = y
        self.pointerX = pointerX
        self.pointerY = pointerY
        self.aspectRatio = aspectRatio
    }
}

private func getLowerExtentClamp(_ lowerExtent: Double, _ lowerBound: Double) -> Double {
    jsMax(0, lowerBound - lowerExtent)
}

private func getUpperExtentClamp(_ upperExtent: Double, _ upperBound: Double) -> Double {
    jsMax(0, upperExtent - upperBound)
}

private func getSizeClamp(_ size: Double, _ minSize: Double, _ maxSize: Double) -> Double {
    jsMax(jsMax(0, minSize - size), size - maxSize)
}

private func xor(_ a: Bool, _ b: Bool) -> Bool {
    a ? !b : b
}

/// Calculates new width & height and x & y of node after resize based on pointer position.
///
/// Buckle up, this is a chunky one... If you want to determine the new dimensions of a node after a
/// resize, you have to account for all possible restrictions: min/max width/height of the node, the
/// maximum extent the node is allowed to move in (in this case: resize into) determined by the parent
/// node, the minimal extent determined by child nodes with expandParent or extent: 'parent' set and
/// oh yeah, these things also have to work with keepAspectRatio!
/// The way this is done is by determining how much each of these restricting actually restricts the
/// resize and then applying the strongest restriction. Because the resize affects x, y and width,
/// height and width, height of a opposing side with keepAspectRatio, the resize amount is always kept
/// in distX & distY amount (the distance in mouse movement). Instead of clamping each value, we first
/// calculate the biggest 'clamp' (for the lack of a better name) and then apply it to all values.
/// To complicate things nodeOrigin has to be taken into account as well. This is done by offsetting
/// the nodes as if their origin is [0, 0], then calculating the restrictions as usual.
/// - Parameters:
///   - startValues: starting values of resize
///   - controlDirection: dimensions affected by the resize
///   - pointerPosition: the current pointer position corrected for snapping
///   - boundaries: minimum and maximum dimensions of the node
///   - keepAspectRatio: prevent changes of aspect ratio
/// - Returns: x, y, width and height of the node after resize
public func getDimensionsAfterResize(
    _ startValues: ResizeStartValues,
    _ controlDirection: ControlDirection,
    _ pointerPosition: PointerPosition,
    _ boundaries: ResizeBoundaries,
    _ keepAspectRatio: Bool,
    _ nodeOrigin: NodeOrigin,
    _ extent: CoordinateExtent? = nil,
    _ childExtent: CoordinateExtent? = nil
) -> ResizeParams {
    var affectsX = controlDirection.affectsX
    var affectsY = controlDirection.affectsY
    let isHorizontal = controlDirection.isHorizontal
    let isVertical = controlDirection.isVertical
    let isDiagonal = isHorizontal && isVertical

    let xSnapped = pointerPosition.xSnapped
    let ySnapped = pointerPosition.ySnapped
    let minWidth = boundaries.minWidth
    let maxWidth = boundaries.maxWidth
    let minHeight = boundaries.minHeight
    let maxHeight = boundaries.maxHeight

    let startX = startValues.x
    let startY = startValues.y
    let startWidth = startValues.width
    let startHeight = startValues.height
    let aspectRatio = startValues.aspectRatio
    var distX = (isHorizontal ? xSnapped - startValues.pointerX : 0).rounded(.down)
    var distY = (isVertical ? ySnapped - startValues.pointerY : 0).rounded(.down)

    let newWidth = startWidth + (affectsX ? -distX : distX)
    let newHeight = startHeight + (affectsY ? -distY : distY)

    let originOffsetX = -nodeOrigin.x * startWidth
    let originOffsetY = -nodeOrigin.y * startHeight

    // Check if maxWidth, minWWidth, maxHeight, minHeight are restricting the resize
    var clampX = getSizeClamp(newWidth, minWidth, maxWidth)
    var clampY = getSizeClamp(newHeight, minHeight, maxHeight)

    // Check if extent is restricting the resize
    if let extent {
        var xExtentClamp: Double = 0
        var yExtentClamp: Double = 0
        if affectsX && distX < 0 {
            xExtentClamp = getLowerExtentClamp(startX + distX + originOffsetX, extent.minX)
        } else if !affectsX && distX > 0 {
            xExtentClamp = getUpperExtentClamp(startX + newWidth + originOffsetX, extent.maxX)
        }

        if affectsY && distY < 0 {
            yExtentClamp = getLowerExtentClamp(startY + distY + originOffsetY, extent.minY)
        } else if !affectsY && distY > 0 {
            yExtentClamp = getUpperExtentClamp(startY + newHeight + originOffsetY, extent.maxY)
        }

        clampX = jsMax(clampX, xExtentClamp)
        clampY = jsMax(clampY, yExtentClamp)
    }

    // Check if the child extent is restricting the resize
    if let childExtent {
        var xExtentClamp: Double = 0
        var yExtentClamp: Double = 0
        if affectsX && distX > 0 {
            xExtentClamp = getUpperExtentClamp(startX + distX, childExtent.minX)
        } else if !affectsX && distX < 0 {
            xExtentClamp = getLowerExtentClamp(startX + newWidth, childExtent.maxX)
        }

        if affectsY && distY > 0 {
            yExtentClamp = getUpperExtentClamp(startY + distY, childExtent.minY)
        } else if !affectsY && distY < 0 {
            yExtentClamp = getLowerExtentClamp(startY + newHeight, childExtent.maxY)
        }

        clampX = jsMax(clampX, xExtentClamp)
        clampY = jsMax(clampY, yExtentClamp)
    }

    // Check if the aspect ratio resizing of the other side is restricting the resize
    if keepAspectRatio {
        if isHorizontal {
            // Check if the max dimensions might be restricting the resize
            let aspectHeightClamp = getSizeClamp(newWidth / aspectRatio, minHeight, maxHeight) * aspectRatio
            clampX = jsMax(clampX, aspectHeightClamp)

            // Check if the extent is restricting the resize
            if let extent {
                var aspectExtentClamp: Double = 0
                if (!affectsX && !affectsY) || (affectsX && !affectsY && isDiagonal) {
                    aspectExtentClamp =
                        getUpperExtentClamp(startY + originOffsetY + newWidth / aspectRatio, extent.maxY) * aspectRatio
                } else {
                    let lowerClamp = getLowerExtentClamp(
                        startY + originOffsetY + (affectsX ? distX : -distX) / aspectRatio, extent.minY)
                    aspectExtentClamp = lowerClamp * aspectRatio
                }
                clampX = jsMax(clampX, aspectExtentClamp)
            }

            // Check if the child extent is restricting the resize
            if let childExtent {
                var aspectExtentClamp: Double = 0
                if (!affectsX && !affectsY) || (affectsX && !affectsY && isDiagonal) {
                    aspectExtentClamp = getLowerExtentClamp(startY + newWidth / aspectRatio, childExtent.maxY) * aspectRatio
                } else {
                    let upperClamp = getUpperExtentClamp(
                        startY + (affectsX ? distX : -distX) / aspectRatio, childExtent.minY)
                    aspectExtentClamp = upperClamp * aspectRatio
                }
                clampX = jsMax(clampX, aspectExtentClamp)
            }
        }

        // Do the same thing for vertical resizing
        if isVertical {
            let aspectWidthClamp = getSizeClamp(newHeight * aspectRatio, minWidth, maxWidth) / aspectRatio
            clampY = jsMax(clampY, aspectWidthClamp)

            if let extent {
                var aspectExtentClamp: Double = 0
                if (!affectsX && !affectsY) || (affectsY && !affectsX && isDiagonal) {
                    aspectExtentClamp =
                        getUpperExtentClamp(startX + newHeight * aspectRatio + originOffsetX, extent.maxX) / aspectRatio
                } else {
                    let lowerClamp = getLowerExtentClamp(
                        startX + (affectsY ? distY : -distY) * aspectRatio + originOffsetX, extent.minX)
                    aspectExtentClamp = lowerClamp / aspectRatio
                }
                clampY = jsMax(clampY, aspectExtentClamp)
            }

            if let childExtent {
                var aspectExtentClamp: Double = 0
                if (!affectsX && !affectsY) || (affectsY && !affectsX && isDiagonal) {
                    aspectExtentClamp = getLowerExtentClamp(startX + newHeight * aspectRatio, childExtent.maxX) / aspectRatio
                } else {
                    let upperClamp = getUpperExtentClamp(
                        startX + (affectsY ? distY : -distY) * aspectRatio, childExtent.minX)
                    aspectExtentClamp = upperClamp / aspectRatio
                }
                clampY = jsMax(clampY, aspectExtentClamp)
            }
        }
    }

    distY = distY + (distY < 0 ? clampY : -clampY)
    distX = distX + (distX < 0 ? clampX : -clampX)

    if keepAspectRatio {
        if isDiagonal {
            if newWidth > newHeight * aspectRatio {
                distY = (xor(affectsX, affectsY) ? -distX : distX) / aspectRatio
            } else {
                distX = (xor(affectsX, affectsY) ? -distY : distY) * aspectRatio
            }
        } else {
            if isHorizontal {
                distY = distX / aspectRatio
                affectsY = affectsX
            } else {
                distX = distY * aspectRatio
                affectsX = affectsY
            }
        }
    }

    let x = affectsX ? startX + distX : startX
    let y = affectsY ? startY + distY : startY

    return ResizeParams(
        x: nodeOrigin.x * distX * (!affectsX ? 1 : -1) + x,
        y: nodeOrigin.y * distY * (!affectsY ? 1 : -1) + y,
        width: startWidth + (affectsX ? -distX : distX),
        height: startHeight + (affectsY ? -distY : distY))
}
