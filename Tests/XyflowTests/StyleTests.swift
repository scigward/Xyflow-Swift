import XCTest
import XYSystem
@testable import Xyflow

final class FlowCSSTests: XCTestCase {
    func testDeclarationsAreSplitAtSemicolons() {
        let declarations = FlowCSS.parseDeclarations("width: 150px; --xy-edge-stroke: var(--custom, #fff); color:red")

        XCTAssertEqual(declarations.map { $0.name }, ["width", "--xy-edge-stroke", "color"])
        XCTAssertEqual(declarations[1].value, "var(--custom, #fff)")
        XCTAssertEqual(declarations[2].value, "red")
    }

    func testSemicolonInsideParenthesesStays() {
        let declarations = FlowCSS.parseDeclarations("background: url(data:image/png;base64,AAAA); color: red")

        XCTAssertEqual(declarations.count, 2)
        XCTAssertEqual(declarations[0].value, "url(data:image/png;base64,AAAA)")
    }

    func testNamesAreLowercasedButCustomPropertiesAreNot() {
        let declarations = FlowCSS.parseDeclarations("Border-Radius: 2px; --Mixed-Case: 1")

        XCTAssertEqual(declarations.map { $0.name }, ["border-radius", "--Mixed-Case"])
    }

    func testHexColors() {
        XCTAssertEqual(FlowCSS.parseColor("#fff"), FlowColor(red: 1, green: 1, blue: 1))
        XCTAssertEqual(FlowCSS.parseColor("#000000"), FlowColor(red: 0, green: 0, blue: 0))

        let withAlpha = FlowCSS.parseColor("#ff000080")
        XCTAssertEqual(withAlpha?.red, 1)
        XCTAssertEqual(withAlpha?.alpha ?? 0, 128.0 / 255, accuracy: 1e-9)

        XCTAssertNil(FlowCSS.parseColor("#12"))
        XCTAssertNil(FlowCSS.parseColor("#ggg"))
    }

    func testFunctionalColors() {
        let rgb = FlowCSS.parseColor("rgb(255, 128, 0)")
        XCTAssertEqual(rgb?.red, 1)
        XCTAssertEqual(rgb?.green ?? 0, 128.0 / 255, accuracy: 1e-9)
        XCTAssertEqual(rgb?.blue, 0)

        let rgba = FlowCSS.parseColor("rgba(0, 89, 220, 0.08)")
        XCTAssertEqual(rgba?.alpha ?? 0, 0.08, accuracy: 1e-9)

        let hsl = FlowCSS.parseColor("hsl(120, 100%, 50%)")
        XCTAssertEqual(hsl?.red ?? 1, 0, accuracy: 1e-9)
        XCTAssertEqual(hsl?.green ?? 0, 1, accuracy: 1e-9)
    }

    func testNamedColors() {
        XCTAssertEqual(FlowCSS.parseColor("black"), .black)
        XCTAssertEqual(FlowCSS.parseColor("transparent"), .clear)
        XCTAssertEqual(FlowCSS.parseColor("White"), .white)
    }

    func testBorders() {
        let solid = FlowCSS.parseBorder("1px solid #1a192b")
        XCTAssertEqual(solid?.width, 1)
        XCTAssertEqual(solid?.isDotted, false)
        XCTAssertNotNil(solid?.color)

        let dotted = FlowCSS.parseBorder("1px dotted rgba(0, 89, 220, 0.8)")
        XCTAssertEqual(dotted?.isDotted, true)
        XCTAssertEqual(dotted?.color?.alpha ?? 0, 0.8, accuracy: 1e-9)

        XCTAssertNil(FlowCSS.parseBorder("none"))
    }

    func testShadows() {
        let shadow = FlowCSS.parseShadow("0 0 2px 1px rgba(0, 0, 0, 0.08)")

        XCTAssertEqual(shadow?.offsetX, 0)
        XCTAssertEqual(shadow?.blur, 2)
        XCTAssertEqual(shadow?.spread, 1)
        XCTAssertEqual(shadow?.color.alpha ?? 0, 0.08, accuracy: 1e-9)
    }

    func testLengths() {
        XCTAssertEqual(FlowCSS.parseLength("12px"), 12)
        XCTAssertEqual(FlowCSS.parseLength("0.5"), 0.5)
        XCTAssertNil(FlowCSS.parseLength("auto"))
    }

    func testNumberLists() {
        XCTAssertEqual(FlowCSS.parseNumberList("5"), [5])
        XCTAssertEqual(FlowCSS.parseNumberList("4, 2"), [4, 2])
        XCTAssertNil(FlowCSS.parseNumberList("none"))
    }
}

final class FlowStyleScopeTests: XCTestCase {
    func testVariableResolvesAgainstTheParent() {
        let root = FlowStyleScope(properties: ["--custom": "#0059dc"])
        let child = FlowStyleScope(parent: root, style: "--xy-edge-stroke: var(--custom)")

        XCTAssertEqual(child.value(of: "--xy-edge-stroke"), "#0059dc")
        XCTAssertEqual(child.color(["--xy-edge-stroke"]), FlowCSS.parseColor("#0059dc"))
    }

    func testFallbackIsUsedWhenTheVariableIsMissing() {
        let scope = FlowStyleScope(properties: ["--a": "var(--missing, #123456)"])

        XCTAssertEqual(scope.value(of: "--a"), "#123456")
    }

    func testNestedFallbacks() {
        let scope = FlowStyleScope(properties: ["--b": "red"])

        XCTAssertEqual(scope.resolve("var(--a, var(--b, blue))"), "red")
        XCTAssertEqual(scope.resolve("var(--a, var(--c, blue))"), "blue")
    }

    func testMissingWithoutFallbackIsNil() {
        let scope = FlowStyleScope(properties: [:])

        XCTAssertNil(scope.resolve("var(--nothing)"))
    }

    func testChildOverridesParent() {
        let root = FlowStyleScope(properties: ["--xy-node-color-default": "#fff"])
        let child = FlowStyleScope(parent: root, properties: ["--xy-node-color-default": "#000"])

        XCTAssertEqual(child.color(["--xy-node-color-default"]), .black)
    }

    func testCircularVariablesDoNotLoopForever() {
        let scope = FlowStyleScope(properties: ["--a": "var(--b)", "--b": "var(--a)"])

        XCTAssertNil(scope.value(of: "--a"))
    }

    func testInheritTakesTheColorOfTheParent() {
        let root = FlowStyleScope(properties: ["color": "#f8f8f8"])
        let child = FlowStyleScope(parent: root, properties: ["--xy-node-color-default": "inherit"])

        XCTAssertEqual(child.color(["--xy-node-color", "--xy-node-color-default"]), FlowCSS.parseColor("#f8f8f8"))
    }

    func testFallbackColorOfTheNames() {
        let scope = FlowStyleScope(properties: ["--second": "#00ff00"])

        XCTAssertEqual(scope.color(["--first", "--second"]), FlowColor(red: 0, green: 1, blue: 0))
    }
}

final class FlowThemeTests: XCTestCase {
    func testDarkOverridesLight() {
        let light = FlowTheme.variables(for: .light)
        let dark = FlowTheme.variables(for: .dark)

        XCTAssertEqual(light["--xy-edge-stroke-default"], "#b1b1b7")
        XCTAssertEqual(dark["--xy-edge-stroke-default"], "#3e3e3e")
        XCTAssertEqual(dark["--xy-background-color-default"], "#141414")
    }

    func testDarkKeepsWhatLightDefines() {
        let light = FlowTheme.variables(for: .light)
        let dark = FlowTheme.variables(for: .dark)

        for key in light.keys {
            XCTAssertNotNil(dark[key], "\(key) is missing in the dark theme")
        }
    }
}
