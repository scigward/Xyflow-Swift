#if canImport(UIKit)
import UIKit
import XCTest
import XYSystem
@testable import Xyflow

final class EdgePerformanceTests: XCTestCase {
    private func makeProps(style: String? = nil, interactionWidth: Double? = nil) -> EdgeProps {
        EdgeProps(id: "e", source: "a", target: "b",
                  sourceX: 0, sourceY: 0, targetX: 100, targetY: 0,
                  sourcePosition: .right, targetPosition: .left,
                  style: style, interactionWidth: interactionWidth)
    }

    private func makeContext(scope: FlowStyleScope) -> EdgeRenderContext {
        EdgeRenderContext(styleScope: scope, markers: [], flowId: nil, theme: .light)
    }

    private func shape(in layer: CALayer) throws -> CAShapeLayer {
        try XCTUnwrap(layer.sublayers?.compactMap { $0 as? CAShapeLayer }.first)
    }

    func testSingleParseScopeHasExactlyTheOriginalDeclarationsAndResolution() {
        let parent = FlowStyleScope(properties: ["--accent": "#123456", "color": "#abcdef"])
        let styles: [String?] = [
            nil, "", "stroke: red; stroke: var(--accent)",
            "--accent: blue; --accent: green; color: var(--accent)",
            "STROKE: var(--missing, #987654); --quoted: 'one;two'; invalid",
            "--case: 1; --Case: 2; width: 2px; width: 6px"
        ]
        for style in styles {
            let original = FlowStyleScope(parent: parent, style: style)
            let optimized = FlowStyleScope(parent: parent, properties: FlowCSS.declarationMap(style))
            XCTAssertEqual(optimized.properties, original.properties)
            for name in ["stroke", "color", "--accent", "--quoted", "--case", "--Case", "width"] {
                XCTAssertEqual(optimized.value(of: name), original.value(of: name))
            }
            parent.set("--accent", "#654321")
            XCTAssertEqual(optimized.value(of: "stroke"), original.value(of: "stroke"))
        }
    }

    func testEdgeStrokeKeepsDuplicateDeclarationsVariablesAndMutableParentValues() throws {
        let parent = FlowStyleScope(properties: FlowTheme.light)
        parent.set("--accent", "#123456")
        parent.set("--width", "4")
        let style = """
        stroke: red; stroke: var(--accent); stroke-width: 1; stroke-width: var(--width);
        stroke-dasharray: 2; stroke-dasharray: 3 4; stroke-linecap: round; stroke-linejoin: bevel; opacity: 0.4
        """
        let originalScope = FlowStyleScope(parent: parent, style: style)
        let edge = BaseEdge()
        edge.update(path: "M0 0 L100 0", labelX: nil, labelY: nil,
                    props: makeProps(style: style), context: makeContext(scope: parent))
        let path = try shape(in: edge.layer)
        XCTAssertEqual(UIColor(cgColor: try XCTUnwrap(path.strokeColor)),
                       originalScope.resolvedColor(originalScope.properties["stroke"])?.uiColor)
        XCTAssertEqual(path.lineWidth, 4)
        XCTAssertEqual(path.lineDashPattern, [NSNumber(value: 3), NSNumber(value: 4)])
        XCTAssertEqual(path.lineCap, .round)
        XCTAssertEqual(path.lineJoin, .bevel)
        XCTAssertEqual(path.opacity, 0.4, accuracy: 0.0001)

        parent.set("--accent", "#654321")
        parent.set("--width", "8")
        edge.update(path: "M0 0 L100 0", labelX: nil, labelY: nil,
                    props: makeProps(style: style), context: makeContext(scope: parent))
        XCTAssertEqual(UIColor(cgColor: try XCTUnwrap(path.strokeColor)),
                       originalScope.resolvedColor(originalScope.properties["stroke"])?.uiColor)
        XCTAssertEqual(path.lineWidth, 8)
    }

    func testLabelRenderingKeepsStylesAndLiveParentResolution() {
        let parent = FlowStyleScope(properties: FlowTheme.light)
        parent.set("--accent", "#123456")
        parent.set("--label-size", "14")
        let style = """
        color: red; color: var(--accent); background: #222222; background-color: #112233;
        font-size: 10; font-size: var(--label-size); font-weight: 700
        """
        let originalScope = FlowStyleScope(parent: parent, style: style)
        let label = EdgeLabelView()
        label.update(text: "SEQUEL", x: 50, y: 25, style: style, scope: parent)
        XCTAssertEqual(label.textLabel.textColor,
                       originalScope.resolvedColor(originalScope.properties["color"])?.uiColor)
        XCTAssertEqual(label.backgroundColor, FlowCSS.parseColor("#112233")?.uiColor)
        XCTAssertEqual(label.textLabel.font, UIFont.systemFont(ofSize: 14, weight: .bold))
        XCTAssertEqual(label.center, CGPoint(x: 50, y: 25))

        parent.set("--accent", "#654321")
        parent.set("--label-size", "18")
        label.update(text: "SEQUEL", x: 60, y: 30, style: style, scope: parent)
        XCTAssertEqual(label.textLabel.textColor,
                       originalScope.resolvedColor(originalScope.properties["color"])?.uiColor)
        XCTAssertEqual(label.textLabel.font.pointSize, 18)
        XCTAssertEqual(label.center, CGPoint(x: 60, y: 30))
    }

    func testConnectionRenderingKeepsDuplicateDeclarationsAndVariables() throws {
        let store = SwiftFlowStore()
        let parent = FlowStyleScope(properties: FlowTheme.light)
        parent.set("--accent", "#123456")
        parent.set("--width", "4")
        let line = ConnectionLineView(store: store)
        line.styleScope = { parent }
        line.style = "stroke: red; stroke: var(--accent); stroke-width: 1; stroke-width: var(--width); stroke-dasharray: 3 4; opacity: 0.5"
        let originalScope = FlowStyleScope(parent: parent, style: line.style)
        store.updateConnection(ConnectionState(inProgress: true,
                                              from: XYPosition(x: 0, y: 0), fromPosition: .right,
                                              to: XYPosition(x: 100, y: 0), toPosition: .left))
        let path = try shape(in: line.layer)
        XCTAssertFalse(line.isHidden)
        XCTAssertNotNil(path.path)
        XCTAssertEqual(UIColor(cgColor: try XCTUnwrap(path.strokeColor)),
                       originalScope.resolvedColor(originalScope.properties["stroke"])?.uiColor)
        XCTAssertEqual(path.lineWidth, 4)
        XCTAssertEqual(path.lineDashPattern, [NSNumber(value: 3), NSNumber(value: 4)])
        XCTAssertEqual(path.opacity, 0.5)

        parent.set("--accent", "#654321")
        parent.set("--width", "8")
        line.update()
        XCTAssertEqual(UIColor(cgColor: try XCTUnwrap(path.strokeColor)),
                       originalScope.resolvedColor(originalScope.properties["stroke"])?.uiColor)
        XCTAssertEqual(path.lineWidth, 8)
    }

    private func assertHits(_ edge: BaseEdge, path: String, width: CGFloat,
                            file: StaticString = #filePath, line: UInt = #line) {
        let expected = SVGPath.cgPath(from: path).copy(strokingWithWidth: width,
                                                     lineCap: .butt, lineJoin: .miter, miterLimit: 10)
        let offsets: [CGFloat] = [-20, -14, -8, -2.1, -1.9, 0, 1.9, 2.1, 8, 14, 20, 30, 31.9, 32.1, 40]
        for y in offsets {
            let point = CGPoint(x: 50, y: y)
            XCTAssertEqual(edge.contains(point: point), expected.contains(point),
                           "hit at \(point) must be unchanged", file: file, line: line)
        }
    }

    func testHitGeometrySurvivesUnrelatedStylesAndInvalidatesForWidthOrPathChanges() {
        let parent = FlowStyleScope(properties: FlowTheme.light)
        let context = makeContext(scope: parent)
        let edge = BaseEdge()
        let path = "M0 0 L100 0"
        var props = makeProps(style: "stroke-width: 2", interactionWidth: 4)
        edge.update(path: path, labelX: nil, labelY: nil, props: props, context: context)
        assertHits(edge, path: path, width: 4) // populates the cached hit path

        props.style = "stroke-width: 2; stroke: red; opacity: 0.5"
        props.label = "SEQUEL"
        edge.update(path: path, labelX: 50, labelY: 0, props: props, context: context)
        assertHits(edge, path: path, width: 4)

        props.interactionWidth = 24
        edge.update(path: path, labelX: 50, labelY: 0, props: props, context: context)
        assertHits(edge, path: path, width: 24)

        props.interactionWidth = 4
        props.style = "stroke-width: 32"
        edge.update(path: path, labelX: 50, labelY: 0, props: props, context: context)
        assertHits(edge, path: path, width: 32)

        props.style = "stroke-width: 6"
        edge.update(path: path, labelX: 50, labelY: 0, props: props, context: context)
        assertHits(edge, path: path, width: 6)

        props.style = nil
        parent.set("--xy-edge-stroke-width", "20")
        edge.update(path: path, labelX: 50, labelY: 0, props: props, context: context)
        assertHits(edge, path: path, width: 20)

        let movedPath = "M0 30 L100 30"
        edge.update(path: movedPath, labelX: 50, labelY: 30, props: props, context: context)
        assertHits(edge, path: movedPath, width: 20)
    }
}
#endif
