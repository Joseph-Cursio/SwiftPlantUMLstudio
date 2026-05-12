// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ComponentDiagramSample",
    products: [
        .library(name: "App", targets: ["App"])
    ],
    targets: [
        .target(name: "Core"),
        .target(name: "Storage", dependencies: ["Core"]),
        .target(name: "App", dependencies: ["Core", "Storage"])
    ]
)
