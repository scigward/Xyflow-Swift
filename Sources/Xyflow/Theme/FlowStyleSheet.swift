#if canImport(UIKit)
import Foundation

/// A stylesheet, as far as a flow reads one: rules of class selectors that give the elements of the
/// flow declarations, like the ones of a `style` string.
///
/// A selector is a list, separated by commas, of chains of compound selectors. A compound selector is
/// `*` or classes put together (`.svelte-flow__node.selected`), and chains are joined by a space
/// (descendant) or by `>` (child). `!important` is understood. A rule whose selector uses anything else
/// (an id, a tag, an attribute, a pseudo class) never matches, and at-rules are skipped.
///
/// The classes of the elements are the ones of Svelte Flow, `svelte-flow__node` and the like. The
/// classes this package gives its views, `swift-flow__node`, are the same ones under the other name.
public final class FlowStyleSheet {
    private enum Combinator {
        case descendant
        case child
    }

    private struct Selector {
        var compounds: [[String]]
        /// `combinators[i]` joins `compounds[i]` and `compounds[i + 1]`.
        var combinators: [Combinator]
        var specificity: Int
    }

    private struct Rule {
        var selector: Selector
        var declarations: [(name: String, value: String, important: Bool)]
        var order: Int
    }

    private let rules: [Rule]

    public var isEmpty: Bool {
        rules.isEmpty
    }

    public init(_ css: String) {
        var parsed: [Rule] = []
        let text = FlowStyleSheet.removeComments(css)
        var index = text.startIndex
        var order = 0

        while index < text.endIndex {
            // the part before a block, or before the `;` of an at-rule that has none
            guard let stop = text[index...].firstIndex(where: { $0 == "{" || $0 == ";" }) else { break }

            let prelude = text[index..<stop].trimmingCharacters(in: .whitespacesAndNewlines)

            if text[stop] == ";" {
                index = text.index(after: stop)
                continue
            }

            // the block, which holds other blocks in an at-rule
            var depth = 1
            var cursor = text.index(after: stop)
            let bodyStart = cursor
            while cursor < text.endIndex {
                if text[cursor] == "{" { depth += 1 }
                if text[cursor] == "}" { depth -= 1 }
                if depth == 0 { break }
                cursor = text.index(after: cursor)
            }

            let body = String(text[bodyStart..<cursor])
            index = cursor < text.endIndex ? text.index(after: cursor) : text.endIndex

            if prelude.isEmpty || prelude.hasPrefix("@") {
                continue
            }

            let declarations = FlowCSS.parseDeclarations(body).map { declaration -> (name: String, value: String, important: Bool) in
                let value = declaration.value
                if let range = value.range(of: "!important", options: [.caseInsensitive, .backwards]),
                   value[range.upperBound...].trimmingCharacters(in: .whitespaces).isEmpty {
                    let stripped = value[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
                    return (declaration.name, stripped, true)
                }
                return (declaration.name, value, false)
            }

            if declarations.isEmpty {
                continue
            }

            for selectorText in prelude.split(separator: ",") {
                guard let selector = FlowStyleSheet.parseSelector(String(selectorText)) else { continue }

                parsed.append(Rule(selector: selector, declarations: declarations, order: order))
                order += 1
            }
        }

        rules = parsed
    }

    // MARK: Parsing

    private static func removeComments(_ css: String) -> String {
        var result = ""
        var index = css.startIndex

        while index < css.endIndex {
            if let start = css.range(of: "/*", range: index..<css.endIndex) {
                result += css[index..<start.lowerBound]

                if let end = css.range(of: "*/", range: start.upperBound..<css.endIndex) {
                    index = end.upperBound
                } else {
                    index = css.endIndex
                }
            } else {
                result += css[index...]
                break
            }
        }

        return result
    }

    private static func parseSelector(_ text: String) -> Selector? {
        let spaced = text.replacingOccurrences(of: ">", with: " > ")
        let tokens = spaced.split(whereSeparator: { $0.isWhitespace }).map(String.init)

        var compounds: [[String]] = []
        var combinators: [Combinator] = []
        var expectsCompound = true
        var pendingChild = false

        for token in tokens {
            if token == ">" {
                // a combinator needs a compound before it, and not another combinator
                if expectsCompound { return nil }
                pendingChild = true
                expectsCompound = true
                continue
            }

            guard let classes = parseCompound(token) else { return nil }

            if !compounds.isEmpty {
                combinators.append(pendingChild ? .child : .descendant)
            }
            compounds.append(classes)
            pendingChild = false
            expectsCompound = false
        }

        // nothing, or a combinator at the end
        if compounds.isEmpty || expectsCompound { return nil }

        return Selector(
            compounds: compounds,
            combinators: combinators,
            specificity: compounds.reduce(0) { $0 + $1.count })
    }

    /// The classes of `.a.b`; none for `*`; `nil` for anything this does not understand.
    private static func parseCompound(_ token: String) -> [String]? {
        if token == "*" { return [] }
        guard token.hasPrefix(".") else { return nil }

        let names = token.dropFirst().split(separator: ".", omittingEmptySubsequences: false).map(String.init)

        for name in names {
            if name.isEmpty { return nil }

            for character in name where !(character.isLetter || character.isNumber || character == "-" || character == "_") {
                return nil
            }
        }

        return names
    }

    // MARK: Matching

    /// `svelte-flow__x` and `swift-flow__x` are the same class.
    private static func aliased(_ classes: Set<String>) -> Set<String> {
        var result = classes

        for name in classes {
            if name.hasPrefix("swift-flow") {
                result.insert("svelte-flow" + name.dropFirst("swift-flow".count))
            } else if name.hasPrefix("svelte-flow") {
                result.insert("swift-flow" + name.dropFirst("svelte-flow".count))
            }
        }

        return result
    }

    private func matches(_ compound: [String], _ classes: Set<String>) -> Bool {
        compound.allSatisfy { classes.contains($0) }
    }

    private func matchesAncestors(_ selector: Selector, index: Int, from: Int, _ ancestors: [Set<String>]) -> Bool {
        if index < 0 { return true }

        let compound = selector.compounds[index]

        switch selector.combinators[index] {
        case .child:
            guard from < ancestors.count, matches(compound, ancestors[from]) else { return false }
            return matchesAncestors(selector, index: index - 1, from: from + 1, ancestors)
        case .descendant:
            var position = from
            while position < ancestors.count {
                if matches(compound, ancestors[position]),
                   matchesAncestors(selector, index: index - 1, from: position + 1, ancestors) {
                    return true
                }
                position += 1
            }
            return false
        }
    }

    /// The declarations that apply to an element with the classes, inside the elements whose classes
    /// are `ancestors` (the nearest one first), in the order the cascade applies them: the one that
    /// comes last wins. The more specific rule comes after the less specific one, a later rule after an
    /// earlier one, and `!important` after everything else.
    public func declarations(classes: Set<String>, ancestors: [Set<String>] = []) -> [(name: String, value: String)] {
        if rules.isEmpty { return [] }

        let element = FlowStyleSheet.aliased(classes)
        var aliasedAncestors: [Set<String>]?

        var matching: [(rule: Rule, important: Bool, declaration: Int)] = []

        for rule in rules {
            let selector = rule.selector
            guard matches(selector.compounds[selector.compounds.count - 1], element) else { continue }

            if selector.compounds.count > 1 {
                if aliasedAncestors == nil {
                    aliasedAncestors = ancestors.map { FlowStyleSheet.aliased($0) }
                }
                guard matchesAncestors(selector, index: selector.compounds.count - 2, from: 0, aliasedAncestors ?? []) else {
                    continue
                }
            }

            for (offset, declaration) in rule.declarations.enumerated() {
                matching.append((rule, declaration.important, offset))
            }
        }

        let sorted = matching.enumerated().sorted { first, second in
            let a = first.element
            let b = second.element

            if a.important != b.important { return !a.important }
            if a.rule.selector.specificity != b.rule.selector.specificity {
                return a.rule.selector.specificity < b.rule.selector.specificity
            }
            if a.rule.order != b.rule.order { return a.rule.order < b.rule.order }
            return first.offset < second.offset
        }

        return sorted.map { entry in
            let declaration = entry.element.rule.declarations[entry.element.declaration]
            return (declaration.name, declaration.value)
        }
    }

    /// `declarations` as the text of a `style` attribute, with the style of the element itself after
    /// it, which is what wins over a stylesheet.
    public func style(classes: Set<String>, ancestors: [Set<String>] = [], inline: String? = nil) -> String? {
        let found = declarations(classes: classes, ancestors: ancestors)
        if found.isEmpty { return inline }

        var text = found.map { "\($0.name): \($0.value)" }.joined(separator: "; ")

        if let inline, !inline.isEmpty {
            text += "; " + inline
        }

        return text
    }
}
#endif
