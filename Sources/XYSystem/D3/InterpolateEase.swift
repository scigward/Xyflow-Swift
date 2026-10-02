import Foundation

private let epsilon2 = 1e-12

private func d3Cosh(_ value: Double) -> Double {
    let e = exp(value)
    return (e + 1 / e) / 2
}

private func d3Sinh(_ value: Double) -> Double {
    let e = exp(value)
    return (e - 1 / e) / 2
}

private func d3Tanh(_ value: Double) -> Double {
    let e = exp(2 * value)
    return (e - 1) / (e + 1)
}

/// The view `[ux, uy, w]` a zoom is at: the center of the view in the coordinates of the content
/// and the width that is visible of it.
public typealias ZoomRegion = (ux: Double, uy: Double, w: Double)

/// An interpolator between two views, with how long the transition takes at this `rho`.
public struct ZoomInterpolator {
    public var duration: Double
    private let function: (Double) -> ZoomRegion

    init(duration: Double, function: @escaping (Double) -> ZoomRegion) {
        self.duration = duration
        self.function = function
    }

    public func callAsFunction(_ t: Double) -> ZoomRegion {
        function(t)
    }
}

/// Smooth zooming and panning along the optimal path of van Wijk and Nuij,
/// "Smooth and efficient zooming and panning" (`d3.interpolateZoom`).
public func interpolateZoom(_ p0: ZoomRegion, _ p1: ZoomRegion, rho: Double = 2.0.squareRoot()) -> ZoomInterpolator {
    let rho = max(1e-3, rho)
    let rho2 = rho * rho
    let rho4 = rho2 * rho2

    let ux0 = p0.ux, uy0 = p0.uy, w0 = p0.w
    let ux1 = p1.ux, uy1 = p1.uy, w1 = p1.w
    let dx = ux1 - ux0
    let dy = uy1 - uy0
    let d2 = dx * dx + dy * dy

    let S: Double
    let function: (Double) -> ZoomRegion

    // Special case for u0 ≅ u1.
    if d2 < epsilon2 {
        S = log(w1 / w0) / rho
        function = { t in
            (ux0 + t * dx, uy0 + t * dy, w0 * exp(rho * t * S))
        }
    }

    // General case.
    else {
        let d1 = d2.squareRoot()
        let b0 = (w1 * w1 - w0 * w0 + rho4 * d2) / (2 * w0 * rho2 * d1)
        let b1 = (w1 * w1 - w0 * w0 - rho4 * d2) / (2 * w1 * rho2 * d1)
        let r0 = log((b0 * b0 + 1).squareRoot() - b0)
        let r1 = log((b1 * b1 + 1).squareRoot() - b1)
        S = (r1 - r0) / rho
        function = { t in
            let s = t * S
            let coshr0 = d3Cosh(r0)
            let u = w0 / (rho2 * d1) * (coshr0 * d3Tanh(rho * s + r0) - d3Sinh(r0))
            return (ux0 + u * dx, uy0 + u * dy, w0 * coshr0 / d3Cosh(rho * s + r0))
        }
    }

    return ZoomInterpolator(duration: S * 1000 * rho / 2.0.squareRoot(), function: function)
}

/// `d3.easeCubicInOut`, the default easing of a transition.
public func easeCubicInOut(_ time: Double) -> Double {
    var t = time * 2
    if t <= 1 {
        return t * t * t / 2
    }
    t -= 2
    return (t * t * t + 2) / 2
}
