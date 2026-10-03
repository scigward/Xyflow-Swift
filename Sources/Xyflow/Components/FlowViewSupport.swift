#if canImport(UIKit)
import UIKit
import ObjectiveC
import XYSystem

/// The style classes the flow itself puts on its views, and the ones a view can carry to tell the
/// flow how to treat input that starts on it.
public enum FlowClass {
    public static let flow = "swift-flow"
    public static let node = "swift-flow__node"
    public static let edge = "swift-flow__edge"
    public static let handle = "swift-flow__handle"
    public static let pane = "swift-flow__pane"
    /// The view does not drag the node it is in.
    public static let noDrag = "nodrag"
    /// The view does not pan the flow.
    public static let noPan = "nopan"
    /// The view does not zoom the flow when the wheel turns over it.
    public static let noWheel = "nowheel"
    /// Keys typed while the view is focused are not the keys of the flow.
    public static let noKey = "nokey"
}

private var flowClassesKey: UInt8 = 0

extension UIView {
    /// The style classes of the view, like the `class` attribute of an element: `nodrag`, `nopan`,
    /// `nowheel` and `nokey` change how the flow treats input on the view.
    public var flowClasses: Set<String> {
        get {
            (objc_getAssociatedObject(self, &flowClassesKey) as? Set<String>) ?? []
        }
        set {
            objc_setAssociatedObject(self, &flowClassesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The classes of the views this one is in, the nearest first, as a stylesheet sees the elements
    /// around an element. A flow also has the class of its color mode.
    func styleAncestors() -> [Set<String>] {
        var result: [Set<String>] = []
        var current = superview

        while let view = current {
            if let flow = view as? SwiftFlow {
                result.append(flow.styleClasses)
            } else {
                result.append(view.flowClasses)
            }
            current = view.superview
        }

        return result
    }

    /// `closest('.className')`: this view or the first one above it with the class.
    public func flowClosest(withClass className: String) -> UIView? {
        var current: UIView? = self
        while let view = current {
            if view.flowClasses.contains(className) { return view }
            current = view.superview
        }
        return nil
    }

    /// Where the view is in the window, as the interface's `getBoundingClientRect()` says.
    var clientRect: Rect {
        let rect = convert(bounds, to: nil)
        return Rect(x: Double(rect.origin.x), y: Double(rect.origin.y), width: Double(rect.size.width), height: Double(rect.size.height))
    }
}

/// A view that holds others and is nothing to touch itself: what is not on one of its subviews goes
/// to the views behind it. Its subviews are touched wherever they are, also outside of its bounds,
/// which is where the content of a flow is once the viewport moves it.
open class FlowPassthroughView: UIView {
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        true
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else { return nil }

        for subview in subviews.reversed() {
            let converted = convert(point, to: subview)
            if let hit = subview.hitTest(converted, with: event) {
                return hit
            }
        }

        return nil
    }
}

extension CGPoint {
    var xyPosition: XYPosition {
        XYPosition(x: Double(x), y: Double(y))
    }
}

extension XYPosition {
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

extension FlowColor {
    /// The color as UIKit has it.
    public var uiColor: UIColor {
        UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }

    public init(_ color: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(alpha))
    }

    /// `#rrggbbaa`
    public var cssHex: String {
        func component(_ value: Double) -> String {
            let byte = Int((min(1, max(0, value)) * 255).rounded())
            return String(format: "%02x", byte)
        }
        return "#" + component(red) + component(green) + component(blue) + component(alpha)
    }
}
#endif
