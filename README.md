<h1 align="center">Xyflow-Swift</h1>

<p align="center">
  Node-based graphs for iOS. A Swift and UIKit port of <a href="https://github.com/xyflow/xyflow">xyflow</a>,<br>
  the library behind React Flow and Svelte Flow.
</p>

<p align="center">
  <a href="https://github.com/scigward/Xyflow-Swift/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/scigward/Xyflow-Swift/ci.yml?branch=main&amp;style=flat-square&amp;label=CI"></a>
  <img alt="iOS 16 and later" src="https://img.shields.io/badge/iOS-16%2B-0a84ff?style=flat-square">
  <img alt="Swift 5.9 and later" src="https://img.shields.io/badge/Swift-5.9%2B-f05138?style=flat-square">
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-3b9a5f?style=flat-square"></a>
</p>

<p align="center">
  <a href="#installation">Installation</a> &middot;
  <a href="#quick-start">Quick start</a> &middot;
  <a href="#coming-from-svelte-flow">Coming from Svelte Flow</a> &middot;
  <a href="#customizing">Customizing</a> &middot;
  <a href="#plugins">Plugins</a> &middot;
  <a href="#tests">Tests</a>
</p>

---

Xyflow-Swift follows `@xyflow/svelte` 0.1.39 and `@xyflow/system` 0.0.59. Nodes, edges, handles, the store, key
handling, pan and zoom, dragging, selection, the plugins and the `--xy-*` style variables work the way they do on
the web, and produce the same numbers. Edge paths, zoom and viewport transforms, handle positions and node
measurements are compared against the original JavaScript packages in the tests.

If you know Svelte Flow you know this API: the props of `<SvelteFlow>` are properties of `SwiftFlow` (or arguments
of its initializer), with the same names and the same defaults.

## What is in it

| Area        | What you get                                                                                         |
| ----------- | ---------------------------------------------------------------------------------------------------- |
| Nodes       | `input`, `output`, `default` and `group`, or any `UIView` of your own                                |
| Edges       | `default` (bezier), `straight`, `step` and `smoothstep`, with markers, labels and animation, or an edge of your own that draws into a layer |
| Interaction | Dragging, connecting, a selection box, multi-select, the delete key, snap to grid and auto pan, from touch, trackpad, mouse or a hardware keyboard |
| Viewport    | Pan, pinch and double-tap zoom, `fitView`, `setViewport`, zoom and translate extents, animated transitions |
| Theming     | Light and dark color modes, the `--xy-*` custom properties, style strings on nodes, edges and labels |
| State       | `Readable`, `Writable` and `Derived` stores that behave like `svelte/store`, and `flow.instance` for `useSvelteFlow()` |

The code is split in two libraries, the way xyflow is split in two packages:

- `Xyflow` is the UIKit part: `SwiftFlow` and its store, the built-in nodes and edges, hooks and plugins. It
  re-exports `XYSystem`.
- `XYSystem` is Foundation only: types, geometry, edge paths, the pan and zoom, drag, handle, minimap and resizer
  controllers, and the d3 behaviors under them. It also builds on macOS and Linux.

## Installation

Add the package in Xcode (File > Add Package Dependencies) with the URL of this repository, or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/scigward/Xyflow-Swift.git", branch: "main")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "Xyflow", package: "Xyflow-Swift")
        ]
    )
]
```

`import Xyflow` is enough, it re-exports the types of `XYSystem`. Depend on the `XYSystem` product instead if you
only want the core without the views. There are no tagged releases yet, so the dependency follows `main`.

## Quick start

```swift
import UIKit
import Xyflow

final class GraphViewController: UIViewController {
    private let flow = SwiftFlow(
        nodes: [
            Node(id: "1", position: XYPosition(x: 0, y: 0), data: ["label": "Hello"], type: "input"),
            Node(id: "2", position: XYPosition(x: 200, y: 120), data: ["label": "World"])
        ],
        edges: [
            Edge(id: "e1-2", source: "1", target: "2", animated: true, label: "says")
        ],
        fitView: true
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        flow.colorMode = .dark
        flow.add(BackgroundView())
        flow.add(ControlsView())

        flow.frame = view.bounds
        flow.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(flow)
    }
}
```

The other props are set the same way, and the events are closures:

```swift
flow.nodesDraggable = false
flow.minZoom = 0.25
flow.snapGrid = (20, 20)
flow.onNodeClick = { event in
    print("clicked", event.node.id)
}
```

`fitView`, `width`, `height`, `viewport`, `initialViewport` and `nodeExtent` are parameters of the initializer. The
rest, such as `panOnScroll`, `zoomOnScroll`, `onlyRenderVisibleElements`, `selectionKey`, `zoomActivationKey` and
`defaultEdgeOptions`, are properties. The events are `onNodeClick`, `onEdgeClick`, `onPaneClick`,
`onNodeDragStop` and so on.

## Coming from Svelte Flow

| Svelte Flow                            | Xyflow-Swift                                         |
| -------------------------------------- | ---------------------------------------------------- |
| `<SvelteFlow>`                         | `SwiftFlow`                                          |
| `<SvelteFlowProvider>`                 | `SwiftFlowStore`, handed to `SwiftFlow(store:)`      |
| `useSvelteFlow()`                      | `flow.instance`, or `FlowInstance(store:)`           |
| `$nodes`, `$edges`                     | `flow.nodes`, `flow.edges` (`Writable` stores)       |
| `nodeTypes`, `edgeTypes`               | `flow.nodeTypes`, `flow.edgeTypes`                   |
| `<Handle>`                             | `HandleView`                                         |
| `<Background>`                         | `BackgroundView`                                     |
| `<Controls>`, `<ControlButton>`        | `ControlsView`, `ControlButton`                      |
| `<MiniMap>`                            | `MiniMapView`                                        |
| `<NodeResizer>`, `<NodeResizeControl>` | `NodeResizerView`, `ResizeControlView`               |
| `<NodeToolbar>`                        | `NodeToolbarView`                                    |
| `<Panel>`                              | `FlowPanelView`                                      |
| `<ViewportPortal>`                     | `flow.viewportPortal`                                |
| the `nodrag`, `nopan`, `nowheel` and `nokey` classes | `view.flowClasses = [FlowClass.noDrag]` and the like |
| promises                               | completion handlers                                  |

## Customizing

### Nodes

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

A node that does not answer `preferredSize` is sized by its constraints.

### Edges

The edges that ship with the flow are paths that `PathEdgeComponent` draws. Subclass it and return the path:

```swift
final class RoundedStepEdge: PathEdgeComponent {
    override func path(for props: EdgeProps) -> EdgePathResult {
        getSmoothStepPath(GetSmoothStepPathParams(
            sourceX: props.sourceX, sourceY: props.sourceY, sourcePosition: props.sourcePosition,
            targetX: props.targetX, targetY: props.targetY, targetPosition: props.targetPosition,
            borderRadius: 24))
    }
}

flow.edgeTypes = ["rounded": { RoundedStepEdge() }]
```

For an edge that is not a single path, implement `FlowEdgeComponent`: it provides a layer to draw in and the
views of its labels.

### Styles

There are no stylesheets. The style of a flow is the set of custom properties of its root scope
(`flow.rootScope()`): the theme of its color mode, then `flow.styleVariables`, then the declarations of
`flow.style`, each overriding the one before. Nodes, edges and plugins resolve their colors against it. Style
strings work the way they do on the web: `Node.style`, `Edge.style` and `Edge.labelStyle` take declarations, and
`var()` finds the variables. All the `--xy-*` properties of the default theme are there, light and dark.

```swift
flow.styleVariables = ["--accent": "#0059dc"]

let edge = Edge(id: "e1-2", source: "1", target: "2")
edge.style = "--xy-edge-stroke: var(--accent)"
edge.labelStyle = "--xy-edge-label-color: var(--accent)"
```

## Reading and changing the flow

`flow.instance` is `useSvelteFlow()`: `fitView`, `zoomIn`, `zoomOut`, `setViewport`, `getNodes`,
`screenToFlowPosition`, `getIntersectingNodes`, `updateNodeData`, `deleteElements` and the rest. Where the web
version returns a promise, the function takes a completion handler. The stores behind the hooks (`nodes`, `edges`,
`viewport`, `connection` and so on) are `Readable` and `Writable` objects with the semantics of `svelte/store`.

```swift
flow.instance.fitView()
flow.instance.setViewport(Viewport(x: 0, y: 0, zoom: 1))
flow.instance.updateNodeData("1", ["label": "Hi"])

flow.nodes.update { $0 + [Node(id: "3", position: XYPosition(x: 400, y: 0))] }
```

To have the state before the view, which is what `SvelteFlowProvider` is for, make the store first:

```swift
let store = SwiftFlowStore()
let instance = FlowInstance(store: store)
let flow = SwiftFlow(store: store)
```

## Input

A touch is routed the way the events of a page bubble, from the view it started on up through the views around it:

| Input                                   | What happens                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| Press on a handle, drag                 | Starts a connection                                               |
| Press on a node, drag                   | Moves the node, or the selection it is part of                    |
| Drag on the pane                        | Draws a selection while the pane is selecting, otherwise pans     |
| Two fingers                             | Pinch zoom                                                        |
| Double tap                              | Zooms in                                                          |
| Trackpad or mouse wheel, pinch          | Wheel events: they pan or zoom as `panOnScroll`, `zoomOnScroll` and `zoomOnPinch` say |
| Secondary button                        | Calls `onNodeContextMenu`, `onEdgeContextMenu`, `onPaneContextMenu` and the like |
| Hardware keyboard                       | `selectionKey`, `multiSelectionKey`, `deleteKey`, `panActivationKey` and `zoomActivationKey` |

A view with one of the classes `nodrag`, `nopan`, `nowheel` or `nokey` in `flowClasses` opts out of that input.

## Plugins

| View              | What it does                                                                |
| ----------------- | --------------------------------------------------------------------------- |
| `BackgroundView`  | A pattern of dots, lines or crosses behind the flow                         |
| `ControlsView`    | Zoom in, zoom out, fit view and lock buttons, and `ControlButton`s of your own |
| `MiniMapView`     | An overview of the flow that can be panned and zoomed                       |
| `NodeResizerView` | Handles to resize a node                                                    |
| `NodeToolbarView` | A toolbar that sits at one or more nodes                                    |
| `FlowPanelView`   | A view pinned to a side or a corner of the flow                             |

They are added with `flow.add(_:)`. `flow.viewportPortal` is a view that moves with the viewport, for anything
else that belongs to the coordinates of the flow.

```swift
flow.add(BackgroundView(variant: .lines, gap: 24))
flow.add(MiniMapView(position: .bottomRight))

let controls = ControlsView(position: .bottomLeft, orientation: .horizontal)
controls.showLock = false
flow.add(controls)
```

## Differences from the web version

- Promises are completion handlers, `async` is not used anywhere.
- There are no stylesheets, see [Styles](#styles).
- Edges are drawn in layers below the nodes, so an edge with a `zIndex` above the nodes of the flow is still below
  them.
- Keyboard events need the flow to be the first responder, which it becomes when it is touched.

## Layout of the repository

The folders follow the ones of xyflow, which makes a port easy to compare with its original.

```
Sources/
  XYSystem/            @xyflow/system
    D3/                zoom, drag, transition, interpolation and easing
    Types/             nodes, edges, changes, events, geometry
    Utils/             graph, edge paths, connections, store helpers, number formatting
    XYDrag/  XYHandle/  XYMinimap/  XYPanZoom/  XYResizer/
  Xyflow/              @xyflow/svelte
    Container/         SwiftFlow, the pane, zoom and node and edge renderers, touch routing, keys
    Components/        node wrapper, handle, built-in nodes, selection views
    Edges/             base edge, built-in edges, edge labels
    Plugins/           background, controls, minimap, node resizer, node toolbar, panel
    Store/  Reactive/  Hooks/  Theme/
Tests/
  XYSystemTests/       compared with the JavaScript packages
  XyflowTests/         the views and the store, on the iOS simulator
```

## Tests

`swift test --filter XYSystemTests` runs the tests of the core, on macOS and on Linux. Most of their expected
values are not written by hand: they were produced by running the same inputs, many of them random, through the
original `@xyflow/system` and `d3` packages. That covers edge paths, viewport and zoom transforms, handle and edge
positions, resizing, node measuring and the graph helpers. The tests of the UIKit part run on the iOS simulator:

```
xcodebuild test -scheme Xyflow-Package -destination 'platform=iOS Simulator,name=<a simulator you have>'
```

CI runs the core tests on macOS and the whole suite on an iOS simulator for every push to `main` and every pull
request.

## License

MIT, as xyflow is. See [LICENSE](LICENSE), which keeps the copyright of the xyflow authors, and
[NOTICE](NOTICE) for the d3 code the behaviors are based on.
