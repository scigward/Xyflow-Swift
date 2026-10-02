import Foundation

public func clamp(_ value: Double, _ min: Double = 0, _ max: Double = 1) -> Double {
    jsMin(jsMax(value, min), max)
}

public func clampPosition(
    _ position: XYPosition = XYPosition(x: 0, y: 0),
    extent: CoordinateExtent,
    dimensions: Measured
) -> XYPosition {
    XYPosition(
        x: clamp(position.x, extent.minX, extent.maxX - (dimensions.width ?? 0)),
        y: clamp(position.y, extent.minY, extent.maxY - (dimensions.height ?? 0)))
}

public func clampPosition(
    _ position: XYPosition = XYPosition(x: 0, y: 0),
    extent: CoordinateExtent,
    dimensions: Dimensions
) -> XYPosition {
    clampPosition(position, extent: extent, dimensions: Measured(width: dimensions.width, height: dimensions.height))
}

public func clampPositionToParent(
    _ childPosition: XYPosition,
    childDimensions: Dimensions,
    parent: InternalNode
) -> XYPosition {
    let parentDimensions = getNodeDimensions(parent)
    let parentPosition = parent.internals.positionAbsolute

    return clampPosition(
        childPosition,
        extent: CoordinateExtent(
            parentPosition.x, parentPosition.y,
            parentPosition.x + parentDimensions.width, parentPosition.y + parentDimensions.height),
        dimensions: childDimensions)
}

/// Calculates the velocity of panning when the mouse is close to the edge of the canvas.
/// - Parameters:
///   - value: One dimensional position of the mouse (x or y)
///   - min: Minimal position on canvas before panning starts
///   - max: Maximal position on canvas before panning starts
/// - Returns: A number between 0 and 1 that represents the velocity of panning
func calcAutoPanVelocity(_ value: Double, _ min: Double, _ max: Double) -> Double {
    if value < min {
        return clamp(abs(value - min), 1, min) / min
    } else if value > max {
        return -clamp(abs(value - max), 1, min) / min
    }

    return 0
}

public func calcAutoPan(
    _ pos: XYPosition,
    bounds: Dimensions,
    speed: Double = 15,
    distance: Double = 40
) -> [Double] {
    let xMovement = calcAutoPanVelocity(pos.x, distance, bounds.width - distance) * speed
    let yMovement = calcAutoPanVelocity(pos.y, distance, bounds.height - distance) * speed

    return [xMovement, yMovement]
}

public func getBoundsOfBoxes(_ box1: Box, _ box2: Box) -> Box {
    Box(
        x: jsMin(box1.x, box2.x),
        y: jsMin(box1.y, box2.y),
        x2: jsMax(box1.x2, box2.x2),
        y2: jsMax(box1.y2, box2.y2))
}

public func rectToBox(_ rect: Rect) -> Box {
    Box(x: rect.x, y: rect.y, x2: rect.x + rect.width, y2: rect.y + rect.height)
}

public func boxToRect(_ box: Box) -> Rect {
    Rect(x: box.x, y: box.y, width: box.x2 - box.x, height: box.y2 - box.y)
}

public func nodeToRect(_ node: AbsolutelyPositioned) -> Rect {
    let position = node.absolutePosition
    let dimensions = getNodeDimensions(node)

    return Rect(x: position.x, y: position.y, width: dimensions.width, height: dimensions.height)
}

public func nodeToRect(_ node: Node, nodeOrigin: NodeOrigin = .zero) -> Rect {
    let position = getNodePositionWithOrigin(node, nodeOrigin: nodeOrigin)
    let dimensions = getNodeDimensions(node)

    return Rect(x: position.x, y: position.y, width: dimensions.width, height: dimensions.height)
}

public func nodeToBox(_ node: AbsolutelyPositioned) -> Box {
    let position = node.absolutePosition
    let dimensions = getNodeDimensions(node)

    return Box(x: position.x, y: position.y, x2: position.x + dimensions.width, y2: position.y + dimensions.height)
}

public func nodeToBox(_ node: Node, nodeOrigin: NodeOrigin = .zero) -> Box {
    let position = getNodePositionWithOrigin(node, nodeOrigin: nodeOrigin)
    let dimensions = getNodeDimensions(node)

    return Box(x: position.x, y: position.y, x2: position.x + dimensions.width, y2: position.y + dimensions.height)
}

public func getBoundsOfRects(_ rect1: Rect, _ rect2: Rect) -> Rect {
    boxToRect(getBoundsOfBoxes(rectToBox(rect1), rectToBox(rect2)))
}

public func getOverlappingArea(_ rectA: Rect, _ rectB: Rect) -> Double {
    let xOverlap = jsMax(0, jsMin(rectA.x + rectA.width, rectB.x + rectB.width) - jsMax(rectA.x, rectB.x))
    let yOverlap = jsMax(0, jsMin(rectA.y + rectA.height, rectB.y + rectB.height) - jsMax(rectA.y, rectB.y))

    return (xOverlap * yOverlap).rounded(.up)
}

public func isNumeric(_ n: Double?) -> Bool {
    guard let n else { return false }
    return !n.isNaN && n.isFinite
}

/// Reports a problem of the flow's configuration. It only does so in debug builds.
public func devWarn(_ id: String, _ message: String) {
    #if DEBUG
    print("[Xyflow]: \(message) (\(id))")
    #endif
}

public func snapPosition(_ position: XYPosition, snapGrid: SnapGrid = (1, 1)) -> XYPosition {
    XYPosition(
        x: snapGrid.0 * jsRound(position.x / snapGrid.0),
        y: snapGrid.1 * jsRound(position.y / snapGrid.1))
}

public func pointToRendererPoint(
    _ point: XYPosition,
    transform: Transform,
    snapToGrid: Bool = false,
    snapGrid: SnapGrid = (1, 1)
) -> XYPosition {
    let position = XYPosition(
        x: (point.x - transform.x) / transform.scale,
        y: (point.y - transform.y) / transform.scale)

    return snapToGrid ? snapPosition(position, snapGrid: snapGrid) : position
}

public func pointToRendererPoint(_ rect: Rect, transform: Transform) -> XYPosition {
    pointToRendererPoint(XYPosition(x: rect.x, y: rect.y), transform: transform)
}

public func rendererPointToPoint(_ point: XYPosition, transform: Transform) -> XYPosition {
    XYPosition(
        x: point.x * transform.scale + transform.x,
        y: point.y * transform.scale + transform.y)
}

/// Parses a single padding value to a number.
/// - Parameters:
///   - padding: Padding to parse
///   - viewport: Width or height of the viewport
/// - Returns: The padding in pixels
func parsePadding(_ padding: PaddingWithUnit, _ viewport: Double) -> Double {
    switch padding {
    case .number(let value):
        return ((viewport - viewport / (1 + value)) * 0.5).rounded(.down)
    case .string(let text):
        if text.hasSuffix("px") {
            if let value = parseFloat(text), !value.isNaN {
                return value.rounded(.down)
            }
        }

        if text.hasSuffix("%") {
            if let value = parseFloat(text), !value.isNaN {
                return (viewport * value * 0.01).rounded(.down)
            }
        }

        print("[Xyflow] The padding value \"\(text)\" is invalid. Please provide a number or a string with a valid unit (px or %).")
        return 0
    }
}

/// `parseFloat`: the number a string starts with, ignoring what follows it.
func parseFloat(_ text: String) -> Double? {
    let trimmed = text.drop(while: { $0.isWhitespace })
    var end = trimmed.startIndex
    var seenDigit = false
    var seenDot = false
    var seenExponent = false
    var index = trimmed.startIndex

    if index < trimmed.endIndex, trimmed[index] == "+" || trimmed[index] == "-" {
        index = trimmed.index(after: index)
    }

    while index < trimmed.endIndex {
        let character = trimmed[index]
        if character.isASCII, character.isNumber {
            seenDigit = true
            end = trimmed.index(after: index)
        } else if character == ".", !seenDot, !seenExponent {
            seenDot = true
            if seenDigit { end = trimmed.index(after: index) }
        } else if (character == "e" || character == "E"), seenDigit, !seenExponent {
            let next = trimmed.index(after: index)
            var probe = next
            if probe < trimmed.endIndex, trimmed[probe] == "+" || trimmed[probe] == "-" {
                probe = trimmed.index(after: probe)
            }
            guard probe < trimmed.endIndex, trimmed[probe].isASCII, trimmed[probe].isNumber else { break }
            seenExponent = true
            index = probe
            continue
        } else {
            break
        }
        index = trimmed.index(after: index)
    }

    guard seenDigit else { return nil }
    return Double(String(trimmed[trimmed.startIndex..<end]))
}

struct ParsedPaddings {
    var top: Double
    var right: Double
    var bottom: Double
    var left: Double
    var x: Double
    var y: Double
}

/// Parses the paddings to an object with top, right, bottom, left, x and y paddings.
/// - Parameters:
///   - padding: Padding to parse
///   - width: Width of the viewport
///   - height: Height of the viewport
func parsePaddings(_ padding: Padding, _ width: Double, _ height: Double) -> ParsedPaddings {
    switch padding {
    case .all(let value):
        let paddingY = parsePadding(value, height)
        let paddingX = parsePadding(value, width)
        return ParsedPaddings(
            top: paddingY, right: paddingX, bottom: paddingY, left: paddingX,
            x: paddingX * 2, y: paddingY * 2)
    case .sides(let top, let right, let bottom, let left, let x, let y):
        let zero = PaddingWithUnit.number(0)
        let topValue = parsePadding(top ?? y ?? zero, height)
        let bottomValue = parsePadding(bottom ?? y ?? zero, height)
        let leftValue = parsePadding(left ?? x ?? zero, width)
        let rightValue = parsePadding(right ?? x ?? zero, width)
        return ParsedPaddings(
            top: topValue, right: rightValue, bottom: bottomValue, left: leftValue,
            x: leftValue + rightValue, y: topValue + bottomValue)
    }
}

/// Calculates the resulting paddings if the new viewport is applied.
func calculateAppliedPaddings(
    _ bounds: Rect,
    _ x: Double,
    _ y: Double,
    _ zoom: Double,
    _ width: Double,
    _ height: Double
) -> (left: Double, top: Double, right: Double, bottom: Double) {
    let transform = Transform(x, y, zoom)
    let topLeft = rendererPointToPoint(XYPosition(x: bounds.x, y: bounds.y), transform: transform)
    let bottomRight = rendererPointToPoint(
        XYPosition(x: bounds.x + bounds.width, y: bounds.y + bounds.height), transform: transform)

    let right = width - bottomRight.x
    let bottom = height - bottomRight.y

    return (
        left: topLeft.x.rounded(.down),
        top: topLeft.y.rounded(.down),
        right: right.rounded(.down),
        bottom: bottom.rounded(.down))
}

/// Returns a viewport that encloses the given bounds with padding.
/// - Parameters:
///   - bounds: Bounds to fit inside viewport.
///   - width: Width of the viewport.
///   - height: Height of the viewport.
///   - minZoom: Minimum zoom level of the resulting viewport.
///   - maxZoom: Maximum zoom level of the resulting viewport.
///   - padding: Padding around the bounds.
/// - Returns: A transformed `Viewport` that encloses the given bounds.
public func getViewportForBounds(
    _ bounds: Rect,
    width: Double,
    height: Double,
    minZoom: Double,
    maxZoom: Double,
    padding: Padding
) -> Viewport {
    // First we resolve all the paddings to actual pixel values
    let p = parsePaddings(padding, width, height)

    let xZoom = (width - p.x) / bounds.width
    let yZoom = (height - p.y) / bounds.height

    // We calculate the new x, y, zoom for a centered view
    let zoom = jsMin(xZoom, yZoom)
    let clampedZoom = clamp(zoom, minZoom, maxZoom)

    let boundsCenterX = bounds.x + bounds.width / 2
    let boundsCenterY = bounds.y + bounds.height / 2
    let x = width / 2 - boundsCenterX * clampedZoom
    let y = height / 2 - boundsCenterY * clampedZoom

    // Then we calculate the minimum padding, to respect asymmetric paddings
    let newPadding = calculateAppliedPaddings(bounds, x, y, clampedZoom, width, height)

    // We only want to have an offset if the newPadding is smaller than the required padding
    let offsetLeft = jsMin(newPadding.left - p.left, 0)
    let offsetTop = jsMin(newPadding.top - p.top, 0)
    let offsetRight = jsMin(newPadding.right - p.right, 0)
    let offsetBottom = jsMin(newPadding.bottom - p.bottom, 0)

    return Viewport(
        x: x - offsetLeft + offsetRight,
        y: y - offsetTop + offsetBottom,
        zoom: clampedZoom)
}

/// Whether the platform is one where `meta` (the command key) is what a multi selection and
/// the shortcuts of an editor use.
public func isMacOs() -> Bool {
    #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
    return true
    #else
    return false
    #endif
}

public func isCoordinateExtent(_ extent: NodeExtent?) -> Bool {
    if case .coordinates = extent { return true }
    return false
}

public func coordinateExtent(of extent: NodeExtent?) -> CoordinateExtent? {
    if case .coordinates(let value) = extent { return value }
    return nil
}

public func getNodeDimensions(_ node: NodeGeometry) -> Dimensions {
    Dimensions(
        width: node.measuredWidth ?? node.width ?? node.initialWidth ?? 0,
        height: node.measuredHeight ?? node.height ?? node.initialHeight ?? 0)
}

public func nodeHasDimensions(_ node: NodeGeometry) -> Bool {
    (node.measuredWidth ?? node.width ?? node.initialWidth) != nil
        && (node.measuredHeight ?? node.height ?? node.initialHeight) != nil
}

/// Convert child position to absolute position.
public func evaluateAbsolutePosition(
    _ position: XYPosition,
    dimensions: Measured = Measured(width: 0, height: 0),
    parentId: String,
    nodeLookup: NodeLookup,
    nodeOrigin: NodeOrigin
) -> XYPosition {
    var positionAbsolute = position

    if let parent = nodeLookup.get(parentId) {
        let origin = parent.origin ?? nodeOrigin
        positionAbsolute.x += parent.internals.positionAbsolute.x - (dimensions.width ?? 0) * origin.x
        positionAbsolute.y += parent.internals.positionAbsolute.y - (dimensions.height ?? 0) * origin.y
    }

    return positionAbsolute
}

public func areSetsEqual(_ a: Set<String>, _ b: Set<String>) -> Bool {
    a == b
}
