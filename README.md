# Xyflow-Swift

A Swift and UIKit port of [xyflow](https://github.com/xyflow/xyflow), the library behind React Flow and
Svelte Flow. It follows `@xyflow/system` 0.0.59 and `@xyflow/svelte` 0.1.39: the same nodes, edges, handles,
store, key handling, pan and zoom, drag, selection, plugins and style variables, and the same numbers coming
out of them.

It is split in two libraries:

| Library    | What is in it                                                                                      |
| ---------- | -------------------------------------------------------------------------------------------------- |
| `XYSystem` | Foundation only. Types, geometry, edge paths, the pan/zoom, drag, handle, minimap and resizer controllers, and the d3 behaviors (zoom, drag, transition, interpolation) they sit on. |
| `Xyflow`   | UIKit. The `SwiftFlow` view, the store, the built in nodes and edges, hooks and the plugins (background, controls, minimap, node resizer, node toolbar). |

Requires iOS 16 or later. `XYSystem` also builds on macOS and Linux.

## Installation

```swift
.package(url: "https://github.com/scigward/Xyflow-Swift.git", branch: "main")
```

then add `Xyflow` (and `XYSystem` if you want the core without the views) to your target.

## Usage

```swift
import Xyflow
import XYSystem

let nodes = [
    Node(id: "1", position: XYPosition(x: 0, y: 0), data: ["label": "Hello"], type: "input"),
    Node(id: "2", position: XYPosition(x: 200, y: 120), data: ["label": "World"])
]
let edges = [Edge(id: "e1-2", source: "1", target: "2", animated: true, label: "says")]

let flow = SwiftFlow(nodes: nodes, edges: edges, fitView: true)
flow.colorMode = .dark
flow.add(BackgroundView())
flow.add(ControlsView())
```

Everything that is a prop of `<SvelteFlow>` is a property of `SwiftFlow`, with the same name and the same
default: `nodesDraggable`, `panOnScroll`, `zoomOnScroll`, `minZoom`, `maxZoom`, `onlyRenderVisibleElements`,
`selectionKey`, `zoomActivationKey`, `snapGrid`, `defaultEdgeOptions` and so on. The events are properties as
well (`onNodeClick`, `onEdgeClick`, `onPaneClick`, `onNodeDragStop`, ...).

### Custom nodes

A node is a view that is told its props. Handles are `HandleView`s inside of it.

```swift
final class TextNode: UIView, FlowNodeComponent {
    private let label = UILabel()
    private let target = HandleView(type: .target, position: .left)
    private let source = HandleView(type: .source, position: .right)

    override init(frame: CGRect) {
        super.init(frame: frame)
        [label, target, source].forEach(addSubview)
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(props: NodeProps) {
        label.text = props.data["label"] as? String
    }

    func preferredSize(width: Double?, height: Double?) -> CGSize? {
        CGSize(width: 150, height: 40)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
}

flow.nodeTypes = ["text": { TextNode() }]
```

A node that does not answer `preferredSize` is sized by its constraints. Style strings work the way they do on
the web: `Node.style`, `Edge.style` and `Edge.labelStyle` take declarations like
`"--xy-edge-stroke: var(--custom)"`, and `flow.styleVariables = ["--custom": "#0059dc"]` provides the
variable. The `--xy-*` properties of the default theme, light and dark, are all there.

### Reading and changing the flow

`flow.instance` is `useSvelteFlow()`: `fitView`, `zoomIn`, `setViewport`, `getNodes`, `screenToFlowPosition`,
`getIntersectingNodes`, `updateNodeData`, `deleteElements` and the rest. Where the web version returns a
promise, the functions take a completion handler. The stores that the hooks return (`nodes`, `edges`,
`viewport`, `connection`, ...) are `Readable` and `Writable` objects with the semantics of `svelte/store`.

A `SwiftFlowStore` can be made first and handed to the flow, which is what `SvelteFlowProvider` is for:

```swift
let store = SwiftFlowStore()
let instance = FlowInstance(store: store)
let flow = SwiftFlow(store: store)
```

### Input

A touch is routed the way the events of a page bubble: a handle starts a connection, a node is dragged, the
pane draws a selection when it is selecting, and what is left pans and zooms the flow. Two fingers pinch,
a double tap zooms in. With a trackpad or a mouse, scrolling and pinching are wheel events, the secondary
button asks for a context menu, and the keys of `selectionKey`, `multiSelectionKey`, `deleteKey`,
`panActivationKey` and `zoomActivationKey` work from a hardware keyboard. A view with one of the classes
`nodrag`, `nopan`, `nowheel` or `nokey` in `flowClasses` opts out of that input.

### Plugins

`BackgroundView`, `ControlsView` (with `ControlButton`s of your own), `MiniMapView`, `NodeResizerView`,
`NodeToolbarView`, and `flow.viewportPortal` for views that move with the viewport.

## Differences from the web version

- Promises are completion handlers, `async` is not used anywhere.
- There are no stylesheets: the style of a flow is the set of custom properties of its root scope
  (`flow.rootScope()`), the theme of its color mode, `flow.style`, and `flow.styleVariables`. Nodes,
  edges and plugins resolve their colors against them.
- Edges are drawn in layers below the nodes, so an edge with a `zIndex` above the nodes of the flow is still
  below them.
- Keyboard events need the flow to be the first responder, which it becomes when it is touched.

## Tests

`swift test --filter XYSystemTests` runs the tests of the core, on macOS and on Linux. Most of their expected
values are not written by hand: they were produced by running the same inputs, many of them random, through the
original `@xyflow/system` and `d3` packages. The tests of the UIKit part run on the iOS simulator:

```
xcodebuild test -scheme Xyflow-Package -destination 'platform=iOS Simulator,name=<a simulator you have>'
```

## License

MIT, as xyflow is. See [LICENSE](LICENSE), and [NOTICE](NOTICE) for the d3 code the behaviors are based on.
