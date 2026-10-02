import Foundation

/// Formats a number the way a path string needs it: the shortest decimal that reads back as the
/// same number, `100` instead of `100.0`, and exponents only for very small or very large values.
public func formatNumber(_ value: Double) -> String {
    if value.isNaN { return "NaN" }
    if value.isInfinite { return value < 0 ? "-Infinity" : "Infinity" }
    if value == 0 { return "0" }

    let negative = value < 0
    // `description` is the shortest representation that round trips: `1.5e-05`, `123.456`, `100.0`
    var text = "\(abs(value))"
    var exponent = 0
    if let e = text.firstIndex(where: { $0 == "e" || $0 == "E" }) {
        exponent = Int(text[text.index(after: e)...].replacingOccurrences(of: "+", with: "")) ?? 0
        text = String(text[..<e])
    }

    var digits: String
    var pointPosition: Int
    if let dot = text.firstIndex(of: ".") {
        pointPosition = text.distance(from: text.startIndex, to: dot)
        digits = text.replacingOccurrences(of: ".", with: "")
    } else {
        pointPosition = text.count
        digits = text
    }

    // value = 0.digits × 10^n
    var n = pointPosition + exponent
    while digits.hasPrefix("0") && digits.count > 1 {
        digits.removeFirst()
        n -= 1
    }
    while digits.hasSuffix("0") && digits.count > 1 {
        digits.removeLast()
    }
    let k = digits.count

    var result: String
    if k <= n && n <= 21 {
        result = digits + String(repeating: "0", count: n - k)
    } else if 0 < n && n <= 21 {
        let index = digits.index(digits.startIndex, offsetBy: n)
        result = String(digits[..<index]) + "." + String(digits[index...])
    } else if -6 < n && n <= 0 {
        result = "0." + String(repeating: "0", count: -n) + digits
    } else {
        let e = n - 1
        let sign = e < 0 ? "-" : "+"
        if k == 1 {
            result = digits + "e" + sign + String(abs(e))
        } else {
            let first = String(digits.prefix(1))
            let rest = String(digits.dropFirst())
            result = first + "." + rest + "e" + sign + String(abs(e))
        }
    }

    return negative ? "-" + result : result
}
