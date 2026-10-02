#if canImport(UIKit)
import UIKit
import XYSystem

/// The part of a node that connections are made from and to. Put it inside a custom node:
/// the node it belongs to is the one it is inside of.
public final class HandleView: UIView, HandleElement, FlowPointerDownHandling {
    /// Id of the handle, needed when a node has more than one handle of a type.
    public var id: String? {
        didSet { if id != oldValue { handleChanged() } }
    }

    /// Type of the handle.
    public var type: HandleType = .source {
        didSet { if type != oldValue { handleChanged() } }
    }

    /// The side of the node the handle sits on.
    public var position: Position = .top {
        didSet { if position != oldValue { updatePositionConstraints() } }
    }

    /// Called when a connection is dragged to this handle, for validation that is specific to it.
    public var isValidConnection: IsValidConnection?

    /// Called with the connections that were added to this handle.
    public var onconnect: (([Connection]) -> Void)? {
        didSet { observeConnections() }
    }

    /// Called with the connections that were removed from this handle.
    public var ondisconnect: (([Connection]) -> Void)? {
        didSet { observeConnections() }
    }

    /// Whether connections can be made with this handle. By default the node decides.
    public var isConnectable: Bool? {
        didSet { updateAppearance() }
    }

    /// Style declarations of the handle, e.g. `"--xy-handle-background-color: red; width: 10px"`.
    public var style: String? {
        didSet { updateAppearance() }
    }

    // MARK: State

    private var positionConstraints: [NSLayoutConstraint] = []
    private var sizeConstraints: [NSLayoutConstraint] = []
    private var storeSubscriptions: [Unsubscribe] = []
    private var edgeSubscription: Unsubscribe?
    private var previousConnections: OrderedMap<String, HandleConnection>?
    private weak var observedStore: SwiftFlowStore?
    private weak var observedWrapper: NodeWrapperView?

    private(set) var isConnectingFrom = false
    private(set) var isConnectingTo = false
    private(set) var isValid = false
    private(set) var isConnectionIndicator = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public convenience init(type: HandleType = .source, position: Position = .top, id: String? = nil) {
        self.init(frame: .zero)
        self.type = type
        self.position = position
        self.id = id
        handleChanged()
        updatePositionConstraints()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        flowClasses = [FlowClass.handle, FlowClass.noDrag, FlowClass.noPan]
        clipsToBounds = false
        updateSize()
        updatePositionConstraints()
        updateAppearance()
    }

    deinit {
        storeSubscriptions.forEach { $0() }
        edgeSubscription?()
    }

    // MARK: Layout

    /// `width: 6px; height: 6px; border: 1px solid` of a handle: the box is 8 points square.
    private func updateSize() {
        NSLayoutConstraint.deactivate(sizeConstraints)

        let scope = styleScope()
        let border = 1.0
        let width = (declaredLength("width") ?? scope.number(["--xy-handle-width"]) ?? 6) + border * 2
        let height = (declaredLength("height") ?? scope.number(["--xy-handle-height"]) ?? 6) + border * 2

        sizeConstraints = [
            widthAnchor.constraint(equalToConstant: CGFloat(max(width, 5))),
            heightAnchor.constraint(equalToConstant: CGFloat(max(height, 5)))
        ]
        NSLayoutConstraint.activate(sizeConstraints)
    }

    /// The handle sits on the edge of the view it is in, centered on it:
    /// `.xy-flow__handle-top { top: 0; left: 50%; transform: translate(-50%, -50%) }` and the like.
    private func updatePositionConstraints() {
        NSLayoutConstraint.deactivate(positionConstraints)
        positionConstraints = []

        guard let superview else { return }

        switch position {
        case .top:
            positionConstraints = [
                centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                centerYAnchor.constraint(equalTo: superview.topAnchor)
            ]
        case .bottom:
            positionConstraints = [
                centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                centerYAnchor.constraint(equalTo: superview.bottomAnchor)
            ]
        case .left:
            positionConstraints = [
                centerXAnchor.constraint(equalTo: superview.leadingAnchor),
                centerYAnchor.constraint(equalTo: superview.centerYAnchor)
            ]
        case .right:
            positionConstraints = [
                centerXAnchor.constraint(equalTo: superview.trailingAnchor),
                centerYAnchor.constraint(equalTo: superview.centerYAnchor)
            ]
        }

        NSLayoutConstraint.activate(positionConstraints)
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updatePositionConstraints()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        observeStore()
        updateAppearance()
    }

    // MARK: The node it is in

    var nodeWrapper: NodeWrapperView? {
        enclosingNodeWrapper
    }

    private var store: SwiftFlowStore? {
        nodeWrapper?.store
    }

    private var isConnectableValue: Bool {
        if let isConnectable { return isConnectable }
        return nodeWrapper?.connectable.get() ?? true
    }

    // MARK: Following the store

    private func observeStore() {
        guard let store, let wrapper = nodeWrapper else { return }
        if observedStore === store && observedWrapper === wrapper { return }

        storeSubscriptions.forEach { $0() }
        storeSubscriptions = []
        observedStore = store
        observedWrapper = wrapper

        storeSubscriptions.append(store.connection.subscribeAny { [weak self] in self?.connectionChanged() })
        storeSubscriptions.append(store.connectionMode.subscribeAny { [weak self] in self?.connectionChanged() })
        storeSubscriptions.append(wrapper.connectable.subscribeAny { [weak self] in self?.connectionChanged() })

        observeConnections()
    }

    private func handleChanged() {
        connectionChanged()
        observeConnections()
    }

    private func connectionChanged() {
        guard let store, let wrapper = nodeWrapper else {
            isConnectionIndicator = false
            return
        }

        let state = store.connection.get()
        let nodeId = wrapper.nodeId
        let handleId = (id?.isEmpty ?? true) ? nil : id

        let connectionInProcess = state.fromHandle != nil
        isConnectingFrom = state.fromHandle?.nodeId == nodeId
            && state.fromHandle?.type == type
            && state.fromHandle?.id == handleId
        isConnectingTo = state.toHandle?.nodeId == nodeId
            && state.toHandle?.type == type
            && state.toHandle?.id == handleId

        let isPossibleEndHandle: Bool
        if store.connectionMode.get() == .strict {
            isPossibleEndHandle = state.fromHandle?.type != type
        } else {
            isPossibleEndHandle = nodeId != state.fromHandle?.nodeId || handleId != state.fromHandle?.id
        }

        isValid = isConnectingTo && state.isValid == true
        isConnectionIndicator = isConnectableValue && (!connectionInProcess || isPossibleEndHandle)
    }

    /// `onconnect` and `ondisconnect`: the connections of this handle are looked up again when the edges change.
    private func observeConnections() {
        edgeSubscription?()
        edgeSubscription = nil

        guard (onconnect != nil || ondisconnect != nil), let store, let wrapper = nodeWrapper else { return }

        var key = "\(wrapper.nodeId)-\(type.rawValue)"
        if let id, !id.isEmpty {
            key += "-" + id
        }
        previousConnections = nil

        edgeSubscription = store.edges.subscribeAny { [weak self] in
            guard let self, let store = self.store else { return }

            let connections = store.connectionLookup.get().get(key)
            if let previous = self.previousConnections, !areConnectionMapsEqual(connections, previous) {
                let current = connections ?? OrderedMap<String, HandleConnection>()

                handleConnectionChange(previous, current) { diff in
                    self.ondisconnect?(diff.map { $0.connection })
                }
                handleConnectionChange(current, previous) { diff in
                    self.onconnect?(diff.map { $0.connection })
                }
            }

            self.previousConnections = connections.map { OrderedMap($0) } ?? OrderedMap<String, HandleConnection>()
        }
    }

    // MARK: Look

    private func declaredLength(_ name: String) -> Double? {
        for declaration in FlowCSS.parseDeclarations(style) where declaration.name == name {
            return FlowCSS.parseLength(declaration.value)
        }
        return nil
    }

    private func declaredValue(_ name: String) -> String? {
        var found: String?
        for declaration in FlowCSS.parseDeclarations(style) where declaration.name == name {
            found = declaration.value
        }
        return found
    }

    /// The style the handle reads its colors from: its own declarations on top of the ones of its node.
    func styleScope() -> FlowStyleScope {
        let parent = nodeWrapper?.styleScope ?? FlowStyleScope(properties: FlowTheme.light)
        return FlowStyleScope(parent: parent, style: style)
    }

    func updateAppearance() {
        let scope = styleScope()

        var background = scope.color(["--xy-handle-background-color", "--xy-handle-background-color-default"])
        if let declared = declaredValue("background-color") ?? declaredValue("background"),
           let resolved = scope.resolve(declared),
           let color = FlowCSS.parseColor(resolved) {
            background = color
        }

        var border = scope.color(["--xy-handle-border-color", "--xy-handle-border-color-default"])
        if let declared = declaredValue("border-color"), let resolved = scope.resolve(declared),
           let color = FlowCSS.parseColor(resolved) {
            border = color
        }

        backgroundColor = (background ?? .clear).uiColor
        layer.borderWidth = 1
        layer.borderColor = (border ?? .clear).uiColor.cgColor
        layer.cornerRadius = max(bounds.width, bounds.height) / 2
        alpha = CGFloat(declaredValue("opacity").flatMap { Double($0) } ?? 1)

        updateSize()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    // MARK: Touches

    /// `pointer-events` of a handle: it is hit while it can start or end a connection.
    private var acceptsPointer: Bool {
        isConnectingFrom || isConnectionIndicator
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard acceptsPointer else { return false }
        return super.point(inside: point, with: event)
    }

    func flowPointerDown(event: FlowPointerEvent) {
        guard let wrapper = nodeWrapper, let flow = enclosingFlow, let store else { return }

        let isMouseTriggered = event.kind == .mouse
        guard (isMouseTriggered && event.button == 0) || !isMouseTriggered else { return }

        let handleId = (id?.isEmpty ?? true) ? nil : id
        let flowId = store.flowId.get()

        XYHandle.onPointerDown(
            event,
            OnPointerDownParams(
                autoPanOnConnect: store.autoPanOnConnect.get(),
                connectionMode: store.connectionMode.get(),
                connectionRadius: store.connectionRadius.get(),
                domNode: store.domNode.get(),
                document: flow,
                handleId: handleId,
                nodeId: wrapper.nodeId,
                isTarget: type == .target,
                nodeLookup: store.nodeLookup.get(),
                lib: store.lib.get(),
                flowId: flowId,
                updateConnection: { store.updateConnection($0) },
                panBy: { delta, completion in store.panBy(delta, completion: completion) },
                cancelConnection: { store.cancelConnection() },
                onConnectStart: { event, startParams in
                    store.onconnectstart.get()?(event, OnConnectStartParams(
                        nodeId: startParams.nodeId, handleId: startParams.handleId, handleType: startParams.handleType))
                },
                onConnect: { connection in
                    let edge: EdgeOrConnection?
                    if let create = store.onedgecreate.get() {
                        edge = create(connection)
                    } else {
                        edge = .connection(connection)
                    }

                    guard let edge else { return }

                    store.addEdge(edge)
                    store.onconnect.get()?(connection)
                },
                onConnectEnd: { event, connectionState in
                    store.onconnectend.get()?(event, connectionState)
                },
                isValidConnection: isValidConnection ?? store.isValidConnection.get(),
                getTransform: {
                    let viewport = store.viewport.get()
                    return Transform(viewport.x, viewport.y, viewport.zoom)
                },
                getFromHandle: { store.connection.get().fromHandle }))
    }

    // MARK: HandleElement

    public var handleNodeId: String? { nodeWrapper?.nodeId }
    public var handleId: String? { (id?.isEmpty ?? true) ? nil : id }
    public var handlePosition: Position? { position }
    public var handleType: HandleType? { type }
    public var handleIsConnectable: Bool { isConnectableValue }
    public var handleIsConnectableEnd: Bool { isConnectableValue }
    public var boundingClientRect: Rect { clientRect }
    public var dimensions: Dimensions { Dimensions(width: Double(bounds.width), height: Double(bounds.height)) }
}

#endif
