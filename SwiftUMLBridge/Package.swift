// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftUMLBridge",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SwiftUMLBridgeFramework", targets: ["SwiftUMLBridgeFramework"]),
        .executable(name: "swiftumlbridge", targets: ["swiftumlbridge"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.34.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "SwiftUMLBridgeFramework",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "Yams", package: "Yams")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "swiftumlbridge",
            dependencies: [
                "SwiftUMLBridgeFramework",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SwiftUMLBridgeFrameworkTests",
            dependencies: ["SwiftUMLBridgeFramework"],
            resources: [.copy("TestData")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
