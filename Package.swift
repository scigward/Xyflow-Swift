// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Xyflow",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // The framework independent core: types, geometry, edge paths and the pan/zoom,
        // drag, handle, minimap and resizer controllers.
        .library(name: "XYSystem", targets: ["XYSystem"]),
        // The UIKit flow view, its store and the built in nodes, edges and plugins.
        .library(name: "Xyflow", targets: ["Xyflow"])
    ],
    targets: [
        .target(name: "XYSystem"),
        .target(name: "Xyflow", dependencies: ["XYSystem"]),
        .testTarget(name: "XYSystemTests", dependencies: ["XYSystem"]),
        .testTarget(name: "XyflowTests", dependencies: ["Xyflow", "XYSystem"])
    ],
    swiftLanguageVersions: [.v5]
)
