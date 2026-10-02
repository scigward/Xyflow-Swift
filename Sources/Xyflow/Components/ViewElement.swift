#if canImport(UIKit)
import UIKit
import XYSystem

/// Selectors a view is matched against are `.className`, which is what the style classes of the
/// views answer to.
extension FlowElement where Self: UIView {
    public func matches(_ target: AnyObject?, selector: String) -> Bool {
        guard let view = target as? UIView else { return false }

        if selector.hasPrefix(".") {
            return view.flowClasses.contains(String(selector.dropFirst()))
        }

        return false
    }

    public func parent(of target: AnyObject) -> AnyObject? {
        (target as? UIView)?.superview
    }
}
#endif
