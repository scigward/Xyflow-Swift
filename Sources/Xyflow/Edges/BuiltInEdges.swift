#if canImport(UIKit)
import UIKit
import XYSystem

/// An edge that is a single path that `BaseEdge` draws, which is what the edge types that ship with
/// the flow are.
open class PathEdgeComponent: FlowEdgeComponent {
    public let base = BaseEdge()

    public init() {}

    public var layer: CALayer {
        base.layer
    }

    public var labelViews: [UIView] {
        base.labelViews
    }

    public func update(props: EdgeProps, context: EdgeRenderContext) {
        let result = path(for: props)
        base.update(path: result.path, labelX: result.labelX, labelY: result.labelY, props: props, context: context)
    }

    public func contains(point: CGPoint) -> Bool {
        base.contains(point: point)
    }

    public func restoreAnimations() {
        base.restoreAnimations()
    }

    /// The path of the edge with the props it is given.
    open func path(for props: EdgeProps) -> EdgePathResult {
        fatalError("PathEdgeComponent.path(for:) has to be overridden")
    }
}

/// `BezierEdgeInternal.svelte`, the edge of the type `default`.
public final class BezierEdgeComponent: PathEdgeComponent {
    public override func path(for props: EdgeProps) -> EdgePathResult {
        getBezierPath(GetBezierPathParams(
            sourceX: props.sourceX,
            sourceY: props.sourceY,
            sourcePosition: props.sourcePosition,
            targetX: props.targetX,
            targetY: props.targetY,
            targetPosition: props.targetPosition))
    }
}

/// `SmoothStepEdgeInternal.svelte`, the edge of the type `smoothstep`.
public final class SmoothStepEdgeComponent: PathEdgeComponent {
    public override func path(for props: EdgeProps) -> EdgePathResult {
        getSmoothStepPath(GetSmoothStepPathParams(
            sourceX: props.sourceX,
            sourceY: props.sourceY,
            sourcePosition: props.sourcePosition,
            targetX: props.targetX,
            targetY: props.targetY,
            targetPosition: props.targetPosition))
    }
}

/// `StepEdgeInternal.svelte`, the edge of the type `step`: a smooth step without the rounded corners.
public final class StepEdgeComponent: PathEdgeComponent {
    public override func path(for props: EdgeProps) -> EdgePathResult {
        getSmoothStepPath(GetSmoothStepPathParams(
            sourceX: props.sourceX,
            sourceY: props.sourceY,
            sourcePosition: props.sourcePosition,
            targetX: props.targetX,
            targetY: props.targetY,
            targetPosition: props.targetPosition,
            borderRadius: 0))
    }
}

/// `StraightEdgeInternal.svelte`, the edge of the type `straight`.
public final class StraightEdgeComponent: PathEdgeComponent {
    public override func path(for props: EdgeProps) -> EdgePathResult {
        getStraightPath(GetStraightPathParams(
            sourceX: props.sourceX,
            sourceY: props.sourceY,
            targetX: props.targetX,
            targetY: props.targetY))
    }
}

/// The node types and edge types a flow has before the ones of the user are added.
public enum BuiltInTypes {
    public static let nodeTypes: NodeTypes = [
        "input": { InputNodeView() },
        "output": { OutputNodeView() },
        "default": { DefaultNodeView() },
        "group": { GroupNodeView() }
    ]

    public static let edgeTypes: EdgeTypes = [
        "straight": { StraightEdgeComponent() },
        "smoothstep": { SmoothStepEdgeComponent() },
        "default": { BezierEdgeComponent() },
        "step": { StepEdgeComponent() }
    ]
}
#endif
