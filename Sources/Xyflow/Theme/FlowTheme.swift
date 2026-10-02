import Foundation
import XYSystem

/// The custom properties the default style sheet of a flow defines, light and dark, as `init.css`,
/// `style.css` and `node-resizer.css` of xyflow do.
public enum FlowTheme {
    /// What `.xy-flow` defines.
    public static let light: [String: String] = [
        "--xy-edge-stroke-default": "#b1b1b7",
        "--xy-edge-stroke-width-default": "1",
        "--xy-edge-stroke-selected-default": "#555",

        "--xy-connectionline-stroke-default": "#b1b1b7",
        "--xy-connectionline-stroke-width-default": "1",

        "--xy-attribution-background-color-default": "rgba(255, 255, 255, 0.5)",

        "--xy-minimap-background-color-default": "#fff",
        "--xy-minimap-mask-background-color-default": "rgba(240, 240, 240, 0.6)",
        "--xy-minimap-mask-stroke-color-default": "transparent",
        "--xy-minimap-mask-stroke-width-default": "1",
        "--xy-minimap-node-background-color-default": "#e2e2e2",
        "--xy-minimap-node-stroke-color-default": "transparent",
        "--xy-minimap-node-stroke-width-default": "2",

        "--xy-background-color-default": "transparent",
        "--xy-background-pattern-dots-color-default": "#91919a",
        "--xy-background-pattern-lines-color-default": "#eee",
        "--xy-background-pattern-cross-color-default": "#e2e2e2",

        "--xy-node-color-default": "inherit",
        "--xy-node-border-default": "1px solid #1a192b",
        "--xy-node-background-color-default": "#fff",
        "--xy-node-group-background-color-default": "rgba(240, 240, 240, 0.25)",
        "--xy-node-boxshadow-hover-default": "0 1px 4px 1px rgba(0, 0, 0, 0.08)",
        "--xy-node-boxshadow-selected-default": "0 0 0 0.5px #1a192b",
        "--xy-node-border-radius-default": "3px",

        "--xy-handle-background-color-default": "#1a192b",
        "--xy-handle-border-color-default": "#fff",

        "--xy-selection-background-color-default": "rgba(0, 89, 220, 0.08)",
        "--xy-selection-border-default": "1px dotted rgba(0, 89, 220, 0.8)",

        "--xy-controls-button-background-color-default": "#fefefe",
        "--xy-controls-button-background-color-hover-default": "#f4f4f4",
        "--xy-controls-button-color-default": "inherit",
        "--xy-controls-button-color-hover-default": "inherit",
        "--xy-controls-button-border-color-default": "#eee",
        "--xy-controls-box-shadow-default": "0 0 2px 1px rgba(0, 0, 0, 0.08)",

        "--xy-edge-label-background-color-default": "#ffffff",
        "--xy-edge-label-color-default": "inherit",

        "--xy-resize-background-color-default": "#3367d9"
    ]

    /// What `.xy-flow.dark` defines on top of the light ones.
    public static let dark: [String: String] = [
        "--xy-edge-stroke-default": "#3e3e3e",
        "--xy-edge-stroke-width-default": "1",
        "--xy-edge-stroke-selected-default": "#727272",

        "--xy-connectionline-stroke-default": "#b1b1b7",
        "--xy-connectionline-stroke-width-default": "1",

        "--xy-attribution-background-color-default": "rgba(150, 150, 150, 0.25)",

        "--xy-minimap-background-color-default": "#141414",
        "--xy-minimap-mask-background-color-default": "rgba(60, 60, 60, 0.6)",
        "--xy-minimap-mask-stroke-color-default": "transparent",
        "--xy-minimap-mask-stroke-width-default": "1",
        "--xy-minimap-node-background-color-default": "#2b2b2b",
        "--xy-minimap-node-stroke-color-default": "transparent",
        "--xy-minimap-node-stroke-width-default": "2",

        "--xy-background-color-default": "#141414",
        "--xy-background-pattern-dots-color-default": "#777",
        "--xy-background-pattern-lines-color-default": "#777",
        "--xy-background-pattern-cross-color-default": "#777",

        "--xy-node-color-default": "#f8f8f8",
        "--xy-node-border-default": "1px solid #3c3c3c",
        "--xy-node-background-color-default": "#1e1e1e",
        "--xy-node-group-background-color-default": "rgba(240, 240, 240, 0.25)",
        "--xy-node-boxshadow-hover-default": "0 1px 4px 1px rgba(255, 255, 255, 0.08)",
        "--xy-node-boxshadow-selected-default": "0 0 0 0.5px #999",

        "--xy-handle-background-color-default": "#bebebe",
        "--xy-handle-border-color-default": "#1e1e1e",

        "--xy-selection-background-color-default": "rgba(200, 200, 220, 0.08)",
        "--xy-selection-border-default": "1px dotted rgba(200, 200, 220, 0.8)",

        "--xy-controls-button-background-color-default": "#2b2b2b",
        "--xy-controls-button-background-color-hover-default": "#3e3e3e",
        "--xy-controls-button-color-default": "#f8f8f8",
        "--xy-controls-button-color-hover-default": "#fff",
        "--xy-controls-button-border-color-default": "#5b5b5b",
        "--xy-controls-box-shadow-default": "0 0 2px 1px rgba(0, 0, 0, 0.08)",

        "--xy-edge-label-background-color-default": "#141414",
        "--xy-edge-label-color-default": "#f8f8f8"
    ]

    /// The custom properties of the root of a flow in a color mode.
    public static func variables(for mode: ColorModeClass) -> [String: String] {
        switch mode {
        case .light:
            return light
        case .dark:
            return light.merging(dark) { _, new in new }
        }
    }
}
