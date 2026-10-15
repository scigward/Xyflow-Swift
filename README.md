<h1 align="center">Xyflow-Swift</h1>

<p align="center">
  Node-based graphs for iOS.<br>
  A Swift and UIKit port of <a href="https://github.com/xyflow/xyflow">xyflow</a>, the library behind React Flow and Svelte Flow.
</p>

> [!NOTE]
> Xyflow-Swift follows `@xyflow/svelte` 0.1.39 and `@xyflow/system` 0.0.59. It needs iOS 16 or later and Swift 5.9 or later. The xyflow team did not make this port. The license is MIT.

Nodes, edges, handles, the store, and key handling work like the web version. So do pan and zoom, dragging, selection, the plugins, and the `--xy-*` style variables. They give the same numbers. The tests compare edge paths, zoom and viewport transforms, handle positions, and node measurements with the original JavaScript packages.

If you know Svelte Flow, you know this API. The props of `<SvelteFlow>` are properties of `SwiftFlow` (or arguments of its initializer). They have the same names and the same defaults.

## What is in it

- Nodes: `input`, `output`, `default` and `group`, or any `UIView` of your own.
- Edges: `default` (bezier), `straight`, `step` and `smoothstep`, with markers, labels and animation. You can also write an edge that draws into a layer.
- Interaction: dragging, connecting, a selection box, multi-select, the delete key, snap to grid and auto pan. Input comes from touch, trackpad, mouse or a hardware keyboard.
- Viewport: pan, pinch and double-tap zoom, `fitView`, `setViewport`, zoom and translate extents, and animated transitions.
- Theming: light and dark color modes, the `--xy-*` custom properties, and style strings on nodes, edges and labels.
- State: `Readable`, `Writable` and `Derived` stores that behave like `svelte/store`, and `flow.instance` for `useSvelteFlow()`.

The code is split in two libraries, as xyflow is split in two packages:

- `Xyflow` is the UIKit part. It has `SwiftFlow` and its store, the built-in nodes and edges, the hooks, and the plugins. It re-exports `XYSystem`.
- `XYSystem` uses Foundation only. It has the types, the geometry, the edge paths, the pan and zoom, drag, handle, minimap and resizer controllers, and the d3 behaviors under them. It also builds on macOS and Linux.

## Installation

Add the package in Xcode (File > Add Package Dependencies) with the URL of this repository. You can also add it to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/scigward/Xyflow-Swift.git", from: "1.0.2")
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

> [!TIP]
> `import Xyflow` is enough, because it re-exports the types of `XYSystem`. If you only need the core without the views, depend on the `XYSystem` product instead.

Releases are tagged and listed under [Releases](https://github.com/scigward/Xyflow-Swift/releases).

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

You set the other props the same way. The events are closures:

```swift
flow.nodesDraggable = false
flow.minZoom = 0.25
flow.snapGrid = (20, 20)
flow.onNodeClick = { event in
    print("clicked", event.node.id)
}
```

`fitView`, `width`, `height`, `viewport`, `initialViewport` and `nodeExtent` are parameters of the initializer. All other props are properties, for example `panOnScroll`, `zoomOnScroll`, `onlyRenderVisibleElements`, `selectionKey`, `zoomActivationKey` and `defaultEdgeOptions`. The events are `onNodeClick`, `onEdgeClick`, `onPaneClick`, `onNodeDragStop` and more.

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
| promises                               | `async` functions, or completion handlers            |

## Customizing

### Nodes

A node is a view that receives its props. Handles are `HandleView`s inside it.

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

> [!NOTE]
> If a node does not answer `preferredSize`, its constraints set its size.

### Edges

The built-in edges are paths that `PathEdgeComponent` draws. To change one, subclass `PathEdgeComponent` and return the path:

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

For an edge that is not a single path, implement `FlowEdgeComponent`. It provides a layer to draw in and the views of its labels.

### Styles

The style of a flow is the set of custom properties of its root scope (`flow.rootScope()`). Each of these overrides the one before it: the theme of the color mode, `flow.styleSheet`, `flow.styleVariables`, and the declarations of `flow.style`. Nodes, edges, and plugins resolve their colors against this scope.

Style strings work like they do on the web. `Node.style`, `Edge.style`, `Edge.labelStyle` and `HandleView.style` take declarations, and `var()` finds the variables. The scope has all the `--xy-*` properties of the default theme, light and dark.

```swift
flow.styleVariables = ["--accent": "#0059dc"]

let edge = Edge(id: "e1-2", source: "1", target: "2")
edge.style = "--xy-edge-stroke: var(--accent)"
edge.labelStyle = "--xy-edge-label-color: var(--accent)"
```

`flow.styleSheet` takes CSS. Use it for nodes, edges, and handles that share a look:

```swift
flow.styleSheet = """
.svelte-flow__node.selected { --xy-node-border: 1px solid var(--accent) }
.dark .svelte-flow__edge-path { stroke-width: 2 }
.svelte-flow__handle.connectingfrom { --xy-handle-background-color: var(--accent) }
.important-node { background-color: #fff3d6 !important }
"""
```

> [!NOTE]
> Xyflow-Swift reads only a part of CSS. A selector is a list of chains of classes (`.a.b`) or `*`, joined by a space or `>`. Ids, tags, attributes, and pseudo classes such as `:hover` never match. At-rules such as `@media` are skipped. A declaration is read like a declaration in a style string. A declaration in a stylesheet loses against the style of the node, edge, or handle itself.

The classes are the ones of Svelte Flow. `swift-flow__node` is the same class as `svelte-flow__node`.

| Element | Classes |
| ------- | ------- |
| The flow | `svelte-flow`, `light` or `dark`, and its `flowClasses` |
| A node | `svelte-flow__node`, `svelte-flow__node-<type>`, its `className`, `selected`, `selectable`, `draggable`, `dragging` |
| A handle | `svelte-flow__handle`, `svelte-flow__handle-<position>`, `source` or `target`, the position, `connectionindicator`, `connectingfrom`, `connectingto`, `valid` |
| An edge | `svelte-flow__edge`, `svelte-flow__edge-<type>`, its `className`, `animated`, `selected`, `selectable` |
| The path and the label of an edge | `svelte-flow__edge-path`, `svelte-flow__edge-label` |

## Reading and changing the flow

`flow.instance` is `useSvelteFlow()`. It has `fitView`, `zoomIn`, `zoomOut`, `setViewport`, `getNodes`, `screenToFlowPosition`, `getIntersectingNodes`, `updateNodeData`, `deleteElements` and more. Where the web version returns a promise, the function takes a completion handler, or you can `await` it.

The stores behind the hooks are `Readable` and `Writable` objects with the semantics of `svelte/store`. Examples are `nodes`, `edges`, `viewport` and `connection`.

```swift
flow.instance.fitView()
flow.instance.setViewport(Viewport(x: 0, y: 0, zoom: 1))
flow.instance.updateNodeData("1", ["label": "Hi"])

let fitted = await flow.instance.fitView(FitViewOptions(duration: 300))
let deleted = await flow.instance.deleteElements(nodes: ["2"])

flow.nodes.update { $0 + [Node(id: "3", position: XYPosition(x: 400, y: 0))] }
```

To have the state before the view (the job of `SvelteFlowProvider`), make the store first:

```swift
let store = SwiftFlowStore()
let instance = FlowInstance(store: store)
let flow = SwiftFlow(store: store)
```

## Input

A touch goes the way the events of a page bubble: from the view it started on, up through the views around it.

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

> [!NOTE]
> A view with the class `nodrag`, `nopan`, `nowheel` or `nokey` in `flowClasses` opts out of that input.

A hardware keyboard reaches every flow on screen, like the keys that a page listens to on `window`. You do not have to touch a flow first. A text field that has the focus keeps its keys.

## Plugins

| View              | What it does                                                                |
| ----------------- | --------------------------------------------------------------------------- |
| `BackgroundView`  | A pattern of dots, lines or crosses behind the flow                         |
| `ControlsView`    | Zoom in, zoom out, fit view and lock buttons, and `ControlButton`s of your own |
| `MiniMapView`     | An overview of the flow that can be panned and zoomed                       |
| `NodeResizerView` | Handles to resize a node                                                    |
| `NodeToolbarView` | A toolbar that sits at one or more nodes                                    |
| `FlowPanelView`   | A view pinned to a side or a corner of the flow                             |

Add them with `flow.add(_:)`. `flow.viewportPortal` is a view that moves with the viewport. Use it for anything else that belongs to the coordinates of the flow.

```swift
flow.add(BackgroundView(variant: .lines, gap: 24))
flow.add(MiniMapView(position: .bottomRight))

let controls = ControlsView(position: .bottomLeft, orientation: .horizontal)
controls.showLock = false
flow.add(controls)
```

## Differences from the web version

- If the user cuts a viewport change short (for example by touching the flow during a `fitView`), `await` returns `false`. The promise of the web version stays open.
- Stylesheets read a part of CSS. See [Styles](#styles).
- An edge and its label are drawn in front of the nodes with a lower `zIndex` than their own, and behind the other nodes. At the default `zIndex`, both stay behind the nodes.
- When the flow does not have the focus, key events come from GameController. Only a hardware keyboard sends them, and the held modifier keys are the ones of that keyboard.

## Big graphs

> [!TIP]
> Set `onlyRenderVisibleElements` for a graph of a few hundred nodes. It keeps the views of nodes and edges that are off screen out of the flow.

The flow does these things to stay fast while you pan and zoom:

- If the list of nodes and edges on screen is the same list, the flow does not pass it on. Panning over the same nodes does not touch any view.
- If none of the values that a node, an edge, or a handle is drawn from changes, the flow does not draw it again. These values are its own values, the style of the flow, and its stylesheet.
- The flow keeps the views of nodes and edges that left the screen, ready for their return.
- The flow draws the background pattern once and moves it. It draws the pattern again for another zoom.
- The flow does not animate changes to edge geometry implicitly. Animated dashes follow the half-second linear loop of the web, without a frame-rate cap. When a cached edge returns to the layer tree, its dashes resume.
- Selection, deletion, edge style parsing, and the order of nodes and edges that already arrive in stacking order avoid repeated work.

## Layout of the repository

The folders follow the ones of xyflow, so you can compare the port with the original.

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

`swift test --filter XYSystemTests` runs the core tests on macOS and Linux. Most expected values were not written by hand. They come from running the same inputs through the original `@xyflow/system` and `d3` packages, and many of the inputs are random. This covers edge paths, viewport and zoom transforms, handle and edge positions, resizing, node measuring, and the graph helpers.

The tests of the UIKit part run on the iOS simulator:

```
xcodebuild test -scheme Xyflow-Package -destination 'platform=iOS Simulator,name=<a simulator you have>'
```

CI runs the core tests on macOS and the whole suite on an iOS simulator for every push to `main` and every pull request.

## License

MIT, like xyflow. See [LICENSE](LICENSE), which keeps the copyright of the xyflow authors, and [NOTICE](NOTICE) for the d3 code that the behaviors are based on.
