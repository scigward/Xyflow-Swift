import XCTest
@testable import XYSystem

final class AsyncTests: XCTestCase {
    func testAnswersWhatTheHandlerIsTold() async {
        let value: Int? = await awaitHandler { handler in
            DispatchQueue.global().async { handler(7) }
        }

        XCTAssertEqual(value, 7)
    }

    func testAnswersWhenTheHandlerIsCalledAtOnce() async {
        let done = await awaitCompletion { $0(true) }

        XCTAssertTrue(done)
    }

    func testAHandlerThatIsLetGoOfAnswersNothing() async {
        let value: Int? = await awaitHandler { _ in }

        XCTAssertNil(value)

        let done = await awaitCompletion { _ in }
        XCTAssertFalse(done)
    }

    func testTheHandlerAnswersOnce() async {
        var handler: ((Int) -> Void)?

        let value: Int? = await awaitHandler { received in
            handler = received
            received(1)
        }
        handler?(2)

        XCTAssertEqual(value, 1)
    }

    func testAnInterruptedTransitionAnswersFalse() async {
        let host = D3TransitionHost()

        let finished = await awaitCompletion { done in
            host.transition(duration: 1000) { transition in
                transition.on.on("end") { _ in done(true) }
            }
            host.interrupt()
        }

        XCTAssertFalse(finished)
    }

    func testElementsToRemoveWaitForTheAnswerBeforeDelete() async {
        let nodes = [
            Node(id: "a", position: XYPosition(x: 0, y: 0)),
            Node(id: "b", position: XYPosition(x: 0, y: 0))
        ]
        let edges = [Edge(id: "e", source: "a", target: "b")]

        let onBeforeDelete = asyncOnBeforeDelete { nodes, _ in
            try? await Task.sleep(nanoseconds: 10_000_000)
            return .replace(nodes: nodes.filter { $0.id == "a" }, edges: [])
        }

        let result = await getElementsToRemove(
            nodesToRemove: ["a", "b"], nodes: nodes, edges: edges, onBeforeDelete: onBeforeDelete)

        XCTAssertEqual(result.nodes.map { $0.id }, ["a"])
        XCTAssertEqual(result.edges.count, 0)
    }

    func testElementsToRemoveWithoutAHook() async {
        let nodes = [Node(id: "a", position: XYPosition(x: 0, y: 0))]
        let edges = [Edge(id: "e", source: "a", target: "b")]

        let result = await getElementsToRemove(nodesToRemove: ["a"], nodes: nodes, edges: edges)

        XCTAssertEqual(result.nodes.map { $0.id }, ["a"])
        XCTAssertEqual(result.edges.map { $0.id }, ["e"])
    }

    func testDenyingTheDeleteAnswersNothing() async {
        let nodes = [Node(id: "a", position: XYPosition(x: 0, y: 0))]
        let onBeforeDelete = asyncOnBeforeDelete { _, _ in .deny }

        let result = await getElementsToRemove(nodesToRemove: ["a"], nodes: nodes, edges: [], onBeforeDelete: onBeforeDelete)

        XCTAssertTrue(result.nodes.isEmpty)
        XCTAssertTrue(result.edges.isEmpty)
    }
}
