import Foundation

/// A color the way the style declarations of a flow give it.
public struct FlowColor: Equatable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let clear = FlowColor(red: 0, green: 0, blue: 0, alpha: 0)
    public static let black = FlowColor(red: 0, green: 0, blue: 0)
    public static let white = FlowColor(red: 1, green: 1, blue: 1)

    /// `#rgb`, `#rgba`, `#rrggbb` or `#rrggbbaa`
    public init?(hex: String) {
        var text = hex.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("#") { text.removeFirst() }

        guard text.allSatisfy({ $0.isHexDigit }) else { return nil }

        func component(_ value: String) -> Double? {
            guard let number = UInt8(value, radix: 16) else { return nil }
            return Double(number) / 255
        }

        switch text.count {
        case 3, 4:
            let digits = text.map { String($0) + String($0) }
            guard let r = component(digits[0]), let g = component(digits[1]), let b = component(digits[2]) else { return nil }
            let a = digits.count == 4 ? component(digits[3]) ?? 1 : 1
            self.init(red: r, green: g, blue: b, alpha: a)
        case 6, 8:
            let characters = Array(text)
            let pairs = stride(from: 0, to: characters.count, by: 2).map { String(characters[$0..<$0 + 2]) }
            guard let r = component(pairs[0]), let g = component(pairs[1]), let b = component(pairs[2]) else { return nil }
            let a = pairs.count == 4 ? component(pairs[3]) ?? 1 : 1
            self.init(red: r, green: g, blue: b, alpha: a)
        default:
            return nil
        }
    }

    public func withAlpha(_ alpha: Double) -> FlowColor {
        FlowColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

/// A border: `1px solid #1a192b`.
public struct FlowBorder: Equatable {
    public var width: Double
    public var color: FlowColor?
    public var isDotted: Bool

    public init(width: Double, color: FlowColor?, isDotted: Bool = false) {
        self.width = width
        self.color = color
        self.isDotted = isDotted
    }
}

/// A box shadow: `0 0 2px 1px rgba(0, 0, 0, 0.08)`.
public struct FlowShadow: Equatable {
    public var offsetX: Double
    public var offsetY: Double
    public var blur: Double
    public var spread: Double
    public var color: FlowColor

    public init(offsetX: Double, offsetY: Double, blur: Double, spread: Double, color: FlowColor) {
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.blur = blur
        self.spread = spread
        self.color = color
    }
}

public enum FlowCSS {
    // MARK: Declarations

    /// `"a: b; c: d"` as the pairs it is made of, in order. Parentheses and quotes keep a `;` inside a value.
    public static func parseDeclarations(_ text: String?) -> [(name: String, value: String)] {
        guard let text, !text.isEmpty else { return [] }

        var result: [(name: String, value: String)] = []
        var current = ""
        var depth = 0
        var quote: Character?

        func finish() {
            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            current = ""
            guard let colon = trimmed.firstIndex(of: ":") else { return }
            let name = trimmed[..<colon].trimmingCharacters(in: .whitespaces)
            let value = trimmed[trimmed.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                result.append((name.hasPrefix("--") ? name : name.lowercased(), value))
            }
        }

        for character in text {
            if let q = quote {
                current.append(character)
                if character == q { quote = nil }
                continue
            }

            switch character {
            case "\"", "'":
                quote = character
                current.append(character)
            case "(":
                depth += 1
                current.append(character)
            case ")":
                depth = max(0, depth - 1)
                current.append(character)
            case ";" where depth == 0:
                finish()
            default:
                current.append(character)
            }
        }
        finish()

        return result
    }

    // MARK: Colors

    private static let namedColors: [String: FlowColor] = [
        "transparent": .clear,
        "none": .clear,
        "black": .black,
        "white": .white,
        "red": FlowColor(red: 1, green: 0, blue: 0),
        "green": FlowColor(red: 0, green: 128 / 255, blue: 0),
        "blue": FlowColor(red: 0, green: 0, blue: 1),
        "yellow": FlowColor(red: 1, green: 1, blue: 0),
        "orange": FlowColor(red: 1, green: 165 / 255, blue: 0),
        "purple": FlowColor(red: 128 / 255, green: 0, blue: 128 / 255),
        "gray": FlowColor(red: 128 / 255, green: 128 / 255, blue: 128 / 255),
        "grey": FlowColor(red: 128 / 255, green: 128 / 255, blue: 128 / 255),
        "silver": FlowColor(red: 192 / 255, green: 192 / 255, blue: 192 / 255),
        "cyan": FlowColor(red: 0, green: 1, blue: 1),
        "magenta": FlowColor(red: 1, green: 0, blue: 1),
        "pink": FlowColor(red: 1, green: 192 / 255, blue: 203 / 255),
        "brown": FlowColor(red: 165 / 255, green: 42 / 255, blue: 42 / 255),
        "lime": FlowColor(red: 0, green: 1, blue: 0),
        "navy": FlowColor(red: 0, green: 0, blue: 128 / 255),
        "teal": FlowColor(red: 0, green: 128 / 255, blue: 128 / 255)
    ]

    /// A color of a declaration: a name, `#hex`, `rgb()`, `rgba()`, `hsl()` or `hsla()`. `var()` has to
    /// be resolved before.
    public static func parseColor(_ text: String) -> FlowColor? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if value.hasPrefix("#") {
            return FlowColor(hex: value)
        }

        if let named = namedColors[value] {
            return named
        }

        if let open = value.firstIndex(of: "("), value.hasSuffix(")") {
            let function = String(value[..<open])
            let inner = String(value[value.index(after: open)..<value.index(before: value.endIndex)])
            let parts = inner
                .replacingOccurrences(of: "/", with: " ")
                .split(whereSeparator: { $0 == "," || $0 == " " })
                .map { String($0) }

            func number(_ text: String, percentScale: Double) -> Double? {
                if text.hasSuffix("%"), let v = Double(text.dropLast()) { return v / 100 * percentScale }
                return Double(text)
            }

            func alpha(_ index: Int) -> Double {
                guard parts.count > index else { return 1 }
                return min(1, max(0, number(parts[index], percentScale: 1) ?? 1))
            }

            switch function {
            case "rgb", "rgba":
                guard parts.count >= 3,
                      let r = number(parts[0], percentScale: 255),
                      let g = number(parts[1], percentScale: 255),
                      let b = number(parts[2], percentScale: 255) else { return nil }
                return FlowColor(red: r / 255, green: g / 255, blue: b / 255, alpha: alpha(3))
            case "hsl", "hsla":
                guard parts.count >= 3,
                      let h = Double(parts[0].replacingOccurrences(of: "deg", with: "")),
                      let s = number(parts[1], percentScale: 1),
                      let l = number(parts[2], percentScale: 1) else { return nil }
                return hslToColor(h: h, s: s, l: l, a: alpha(3))
            default:
                return nil
            }
        }

        return nil
    }

    private static func hslToColor(h: Double, s: Double, l: Double, a: Double) -> FlowColor {
        let hue = (h.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / 360
        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q

        func channel(_ t: Double) -> Double {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1.0 / 6 { return p + (q - p) * 6 * t }
            if t < 0.5 { return q }
            if t < 2.0 / 3 { return p + (q - p) * (2.0 / 3 - t) * 6 }
            return p
        }

        return FlowColor(red: channel(hue + 1.0 / 3), green: channel(hue), blue: channel(hue - 1.0 / 3), alpha: a)
    }

    // MARK: Lengths, borders and shadows

    /// `12px`, `12`, `0.5px`
    public static func parseLength(_ text: String) -> Double? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.hasSuffix("px"), let number = Double(value.dropLast(2)) { return number }
        return Double(value)
    }

    /// `1px solid #1a192b`, `1px dotted rgba(0, 89, 220, 0.8)` or `none`.
    public static func parseBorder(_ text: String) -> FlowBorder? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if value == "none" || value.isEmpty { return nil }

        let parts = splitTopLevel(value)
        var width = 1.0
        var color: FlowColor?
        var dotted = false

        for part in parts {
            if let length = parseLength(part) {
                width = length
            } else if part == "dotted" || part == "dashed" {
                dotted = true
            } else if part == "solid" {
                continue
            } else if let parsed = parseColor(part) {
                color = parsed
            }
        }

        return FlowBorder(width: width, color: color, isDotted: dotted)
    }

    /// `0 0 2px 1px rgba(0, 0, 0, 0.08)` (the first shadow of a list).
    public static func parseShadow(_ text: String) -> FlowShadow? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if value == "none" || value.isEmpty { return nil }

        let first = splitTopLevel(value, separator: ",").first ?? value
        var lengths: [Double] = []
        var color = FlowColor.black

        for part in splitTopLevel(first) {
            if let length = parseLength(part) {
                lengths.append(length)
            } else if let parsed = parseColor(part) {
                color = parsed
            }
        }

        guard lengths.count >= 2 else { return nil }

        return FlowShadow(
            offsetX: lengths[0],
            offsetY: lengths[1],
            blur: lengths.count > 2 ? lengths[2] : 0,
            spread: lengths.count > 3 ? lengths[3] : 0,
            color: color)
    }

    /// Splits at the separator outside of parentheses; spaces by default.
    static func splitTopLevel(_ text: String, separator: Character = " ") -> [String] {
        var parts: [String] = []
        var current = ""
        var depth = 0

        for character in text {
            if character == "(" { depth += 1 }
            if character == ")" { depth = max(0, depth - 1) }

            if depth == 0 && (character == separator || (separator == " " && character.isWhitespace)) {
                if !current.isEmpty { parts.append(current) }
                current = ""
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty { parts.append(current) }

        return parts
    }
}

/// The custom properties of an element and of the elements around it. `var(--name, fallback)` is
/// resolved against them, the way the cascade of CSS does it for custom properties: what an
/// element does not set it takes from the element it is in.
public final class FlowStyleScope {
    public let parent: FlowStyleScope?
    public private(set) var properties: [String: String]

    public init(parent: FlowStyleScope? = nil, properties: [String: String] = [:]) {
        self.parent = parent
        self.properties = properties
    }

    /// A scope with the declarations of a `style` string of an element on top of its parent.
    public convenience init(parent: FlowStyleScope?, style: String?) {
        var properties: [String: String] = [:]
        for declaration in FlowCSS.parseDeclarations(style) {
            properties[declaration.name] = declaration.value
        }
        self.init(parent: parent, properties: properties)
    }

    public func set(_ name: String, _ value: String?) {
        properties[name] = value
    }

    /// The declared value of a property of this element, or of the element it is in.
    public func rawValue(_ name: String) -> String? {
        if let value = properties[name] { return value }
        return parent?.rawValue(name)
    }

    /// The value of a property with every `var()` in it replaced; `nil` when it, or a variable it
    /// needs, is not there.
    public func value(of name: String, depth: Int = 0) -> String? {
        guard depth < 16, let raw = rawValue(name) else { return nil }
        return resolve(raw, depth: depth + 1)
    }

    /// `text` with its `var(--name, fallback)` replaced.
    public func resolve(_ text: String, depth: Int = 0) -> String? {
        var result = ""
        var index = text.startIndex

        while index < text.endIndex {
            guard let range = text.range(of: "var(", range: index..<text.endIndex) else {
                result += text[index...]
                break
            }

            result += text[index..<range.lowerBound]

            // find the matching parenthesis
            var depthCount = 1
            var cursor = range.upperBound
            while cursor < text.endIndex && depthCount > 0 {
                if text[cursor] == "(" { depthCount += 1 }
                if text[cursor] == ")" { depthCount -= 1 }
                if depthCount > 0 { cursor = text.index(after: cursor) }
            }

            guard depthCount == 0 else { return nil }

            let inner = String(text[range.upperBound..<cursor])
            let name: String
            var fallback: String?
            if let comma = inner.firstIndex(of: ",") {
                name = inner[..<comma].trimmingCharacters(in: .whitespaces)
                fallback = String(inner[inner.index(after: comma)...]).trimmingCharacters(in: .whitespaces)
            } else {
                name = inner.trimmingCharacters(in: .whitespaces)
            }

            if let resolved = value(of: name, depth: depth) {
                result += resolved
            } else if let fallback, let resolved = resolve(fallback, depth: depth + 1) {
                result += resolved
            } else {
                return nil
            }

            index = text.index(after: cursor)
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The first of the properties that has a value, as a color. `inherit` is the color of the element
    /// this one is in.
    public func color(_ names: [String]) -> FlowColor? {
        for name in names {
            guard let value = value(of: name) else { continue }

            let keyword = value.trimmingCharacters(in: .whitespaces).lowercased()
            if keyword == "inherit" || keyword == "currentcolor" {
                if let inherited = (parent ?? self).inheritedColor() {
                    return inherited
                }
                continue
            }

            if let color = FlowCSS.parseColor(value) {
                return color
            }
        }
        return nil
    }

    /// The `color` of the element, which is what elements that say `inherit` take.
    public func inheritedColor() -> FlowColor? {
        guard let raw = rawValue("color"), let resolved = resolve(raw) else { return nil }
        return FlowCSS.parseColor(resolved)
    }

    public func number(_ names: [String]) -> Double? {
        for name in names {
            if let value = value(of: name), let number = FlowCSS.parseLength(value) {
                return number
            }
        }
        return nil
    }

    public func border(_ names: [String]) -> FlowBorder? {
        for name in names {
            if let value = value(of: name) {
                return FlowCSS.parseBorder(value)
            }
        }
        return nil
    }

    public func shadow(_ names: [String]) -> FlowShadow? {
        for name in names {
            if let value = value(of: name) {
                return FlowCSS.parseShadow(value)
            }
        }
        return nil
    }
}

extension FlowCSS {
    /// The declarations of a style string by name. A name that is declared twice has its last value.
    public static func declarationMap(_ text: String?) -> [String: String] {
        var result: [String: String] = [:]
        for declaration in parseDeclarations(text) {
            result[declaration.name] = declaration.value
        }
        return result
    }

    /// The numbers of a list like `5`, `5 5` or `4, 2`; `none` is no list.
    public static func parseNumberList(_ text: String) -> [Double]? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value == "none" || value.isEmpty { return nil }

        let numbers = value
            .split(whereSeparator: { $0 == "," || $0 == " " })
            .compactMap { parseLength(String($0)) }

        return numbers.isEmpty ? nil : numbers
    }
}

extension FlowStyleScope {
    /// A color written in a declaration, with its `var()` replaced.
    public func resolvedColor(_ declared: String?) -> FlowColor? {
        guard let declared, let resolved = resolve(declared) else { return nil }
        return FlowCSS.parseColor(resolved)
    }

    /// A length written in a declaration, with its `var()` replaced.
    public func resolvedNumber(_ declared: String?) -> Double? {
        guard let declared, let resolved = resolve(declared) else { return nil }
        return FlowCSS.parseLength(resolved)
    }
}
