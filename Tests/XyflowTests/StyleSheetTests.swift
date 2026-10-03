#if canImport(UIKit)
import XCTest
@testable import Xyflow

final class StyleSheetTests: XCTestCase {
    private func values(_ sheet: FlowStyleSheet, _ classes: Set<String>, _ ancestors: [Set<String>] = []) -> [String] {
        sheet.declarations(classes: classes, ancestors: ancestors).map { "\($0.name): \($0.value)" }
    }

    func testAClassSelectorMatchesTheElementsWithTheClass() {
        let sheet = FlowStyleSheet(".svelte-flow__node { color: red }")

        XCTAssertEqual(values(sheet, ["svelte-flow__node"]), ["color: red"])
        XCTAssertEqual(values(sheet, ["svelte-flow__edge"]), [])
    }

    func testCompoundSelectorsNeedAllTheirClasses() {
        let sheet = FlowStyleSheet(".svelte-flow__node.selected { --xy-node-border: 1px solid red }")

        XCTAssertEqual(values(sheet, ["svelte-flow__node", "selected"]), ["--xy-node-border: 1px solid red"])
        XCTAssertEqual(values(sheet, ["svelte-flow__node"]), [])
    }

    func testTheSwiftNamesAreTheSameClasses() {
        let sheet = FlowStyleSheet(".svelte-flow__node { color: red } .swift-flow__handle { color: blue }")

        XCTAssertEqual(values(sheet, ["swift-flow__node"]), ["color: red"])
        XCTAssertEqual(values(sheet, ["svelte-flow__handle"]), ["color: blue"])
    }

    func testDescendantAndChildCombinators() {
        let sheet = FlowStyleSheet("""
        .dark .svelte-flow__node { color: white }
        .svelte-flow__nodes > .svelte-flow__node { width: 10px }
        """)

        let node: Set<String> = ["svelte-flow__node"]
        let nodes: Set<String> = ["svelte-flow__nodes"]
        let viewport: Set<String> = ["svelte-flow__viewport"]
        let root: Set<String> = ["svelte-flow", "dark"]

        XCTAssertEqual(values(sheet, node, [nodes, viewport, root]), ["color: white", "width: 10px"])
        // the child has to be the parent, the descendant can be anywhere above
        XCTAssertEqual(values(sheet, node, [viewport, nodes, root]), ["color: white"])
        XCTAssertEqual(values(sheet, node, [nodes, viewport]), ["width: 10px"])
    }

    func testTheMoreSpecificRuleWinsWhateverComesFirst() {
        let sheet = FlowStyleSheet("""
        .a.b { color: blue }
        .a { color: red }
        """)

        XCTAssertEqual(values(sheet, ["a", "b"]), ["color: red", "color: blue"])
    }

    func testALaterRuleComesAfterAnEarlierOneOfTheSameSpecificity() {
        let sheet = FlowStyleSheet(".a { color: red } .a { color: blue }")

        XCTAssertEqual(values(sheet, ["a"]), ["color: red", "color: blue"])
    }

    func testImportantComesLast() {
        let sheet = FlowStyleSheet("""
        .a { color: red !important }
        .a.b { color: blue }
        """)

        XCTAssertEqual(values(sheet, ["a", "b"]), ["color: blue", "color: red"])
    }

    func testCommaListsAndTheUniversalSelector() {
        let sheet = FlowStyleSheet(".a, .b { color: red } * { opacity: 1 }")

        XCTAssertEqual(values(sheet, ["a"]), ["opacity: 1", "color: red"])
        XCTAssertEqual(values(sheet, ["b"]), ["opacity: 1", "color: red"])
        XCTAssertEqual(values(sheet, ["c"]), ["opacity: 1"])
    }

    func testWhatIsNotUnderstoodNeverMatches() {
        let sheet = FlowStyleSheet("""
        div { color: red }
        #id { color: red }
        .a:hover { color: red }
        .a[data-id="1"] { color: red }
        .a + .b { color: red }
        .a > { color: red }
        .a { color: green }
        """)

        XCTAssertEqual(values(sheet, ["a", "b"]), ["color: green"])
    }

    func testAtRulesAndCommentsAreSkipped() {
        let sheet = FlowStyleSheet("""
        @import url("x.css");
        /* .a { color: red } */
        @media (max-width: 100px) { .a { color: red } }
        @keyframes spin { from { opacity: 0 } to { opacity: 1 } }
        .a { color: green }
        """)

        XCTAssertEqual(values(sheet, ["a"]), ["color: green"])
    }

    func testTheStyleOfTheElementComesAfterTheSheet() {
        let sheet = FlowStyleSheet(".a { color: red; width: 10px }")

        XCTAssertEqual(sheet.style(classes: ["a"], inline: "color: blue"), "color: red; width: 10px; color: blue")
        XCTAssertEqual(sheet.style(classes: ["b"], inline: "color: blue"), "color: blue")
        XCTAssertNil(sheet.style(classes: ["b"]))
    }

    func testValuesKeepTheirParenthesesAndSemicolonsInside() {
        let sheet = FlowStyleSheet(".a { background: url(\"a;b\"); --x: var(--y, 1px) }")

        XCTAssertEqual(values(sheet, ["a"]), ["background: url(\"a;b\")", "--x: var(--y, 1px)"])
    }

    func testAnEmptySheetIsEmpty() {
        XCTAssertTrue(FlowStyleSheet("").isEmpty)
        XCTAssertTrue(FlowStyleSheet("/* nothing */ .a { }").isEmpty)
        XCTAssertFalse(FlowStyleSheet(".a { color: red }").isEmpty)
    }
}
#endif
