import Foundation
import Testing
@testable import SwiftUMLBridgeFramework

private let sampleJSON = """
{
  "name": "DemoPackage",
  "targets": [
    {
      "name": "Networking",
      "type": "library",
      "path": "Sources/Networking",
      "sources": ["HttpClient.swift", "URLSession+Extensions.swift"],
      "target_dependencies": ["Core"]
    },
    {
      "name": "UI",
      "type": "library",
      "path": "Sources/UI",
      "sources": ["LoginView.swift"],
      "target_dependencies": ["Networking"]
    },
    {
      "name": "DemoPackageTests",
      "type": "test",
      "path": "Tests/DemoPackageTests",
      "sources": ["NetworkingTests.swift"],
      "target_dependencies": ["Networking"]
    }
  ]
}
""".data(using: .utf8)!

@Suite("SPMPackageReader.parse")
struct SPMPackageReaderParseTests {

    @Test("parses package name and target count")
    func basicShape() throws {
        let pkg = try SPMPackageReader.parse(sampleJSON)
        #expect(pkg.name == "DemoPackage")
        #expect(pkg.targets.count == 3)
    }

    @Test("preserves target name, kind, path, sources, and dependencies")
    func preservesTargetFields() throws {
        let pkg = try SPMPackageReader.parse(sampleJSON)
        let networking = try #require(pkg.targets.first { $0.name == "Networking" })
        #expect(networking.kind == .library)
        #expect(networking.path == "Sources/Networking")
        #expect(networking.sources == ["HttpClient.swift", "URLSession+Extensions.swift"])
        #expect(networking.dependencies == ["Core"])
    }

    @Test("recognises test targets")
    func recognisesTestTarget() throws {
        let pkg = try SPMPackageReader.parse(sampleJSON)
        let tests = try #require(pkg.targets.first { $0.name == "DemoPackageTests" })
        #expect(tests.kind == .test)
    }

    @Test("malformed JSON throws ReadError.malformedJSON")
    func malformedThrows() {
        let bad = "not json".data(using: .utf8)!
        #expect(throws: SPMPackageReader.ReadError.self) {
            try SPMPackageReader.parse(bad)
        }
    }

    @Test("unknown target type maps to .other")
    func unknownTypeMapsToOther() throws {
        let weird = """
        { "name": "X", "targets": [
          { "name": "Plug", "type": "plugin", "path": "Plugins/Plug",
            "sources": ["main.swift"], "target_dependencies": [] }
        ]}
        """.data(using: .utf8)!
        let pkg = try SPMPackageReader.parse(weird)
        #expect(pkg.targets.first?.kind == .other)
    }
}

@Suite("SPMPackageDescription.sourceFileToModuleMap")
struct SPMPackageDescriptionMapTests {

    @Test("joins target.path + each source path under packageRoot")
    func joinsPaths() throws {
        let pkg = try SPMPackageReader.parse(sampleJSON)
        let root = URL(fileURLWithPath: "/Users/me/DemoPackage")
        let map = pkg.sourceFileToModuleMap(packageRoot: root)
        #expect(map["/Users/me/DemoPackage/Sources/Networking/HttpClient.swift"] == "Networking")
        #expect(map["/Users/me/DemoPackage/Sources/UI/LoginView.swift"] == "UI")
    }

    @Test("excludes test targets from the map")
    func excludesTests() throws {
        let pkg = try SPMPackageReader.parse(sampleJSON)
        let root = URL(fileURLWithPath: "/Users/me/DemoPackage")
        let map = pkg.sourceFileToModuleMap(packageRoot: root)
        #expect(map["/Users/me/DemoPackage/Tests/DemoPackageTests/NetworkingTests.swift"] == nil)
    }
}

@Suite("ClassDiagramGenerator.generateScript(forPackage:)")
struct ClassDiagramGeneratorPackageTests {

    /// Build a temp directory mimicking a small SPM package, run the
    /// generator against it, and check the resulting LayoutGraph carries
    /// module info on each node.
    @Test("tags each LayoutNode with its owning target name")
    func tagsLayoutNodesWithModule() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("spm-test-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let networkingDir = tempRoot.appendingPathComponent("Sources/Networking", isDirectory: true)
        let uiDir = tempRoot.appendingPathComponent("Sources/UI", isDirectory: true)
        try FileManager.default.createDirectory(at: networkingDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: uiDir, withIntermediateDirectories: true)
        try "class HttpClient {}".write(
            to: networkingDir.appendingPathComponent("HttpClient.swift"),
            atomically: true, encoding: .utf8
        )
        try "class LoginView {}".write(
            to: uiDir.appendingPathComponent("LoginView.swift"),
            atomically: true, encoding: .utf8
        )

        let description = SPMPackageDescription(
            name: "Demo",
            targets: [
                SPMTargetDescription(
                    name: "Networking", kind: .library,
                    path: "Sources/Networking",
                    sources: ["HttpClient.swift"], dependencies: []
                ),
                SPMTargetDescription(
                    name: "UI", kind: .library,
                    path: "Sources/UI",
                    sources: ["LoginView.swift"], dependencies: ["Networking"]
                )
            ]
        )

        var configuration = Configuration.default
        configuration.format = .svg
        let script = ClassDiagramGenerator().generateScript(
            forPackage: description,
            packageRoot: tempRoot,
            with: configuration,
            sdkPath: nil
        )
        let nodes = try #require(script.layoutGraph?.nodes)
        let httpClient = try #require(nodes.first { $0.label == "HttpClient" })
        let loginView = try #require(nodes.first { $0.label == "LoginView" })
        #expect(httpClient.module == "Networking")
        #expect(loginView.module == "UI")
    }

    @Test("PlantUML output includes the module name as an additional stereotype")
    func plantUMLIncludesModuleStereotype() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("spm-test-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let dir = tempRoot.appendingPathComponent("Sources/Networking", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try "class HttpClient {}".write(
            to: dir.appendingPathComponent("HttpClient.swift"),
            atomically: true, encoding: .utf8
        )

        let description = SPMPackageDescription(
            name: "Demo",
            targets: [
                SPMTargetDescription(
                    name: "Networking", kind: .library,
                    path: "Sources/Networking",
                    sources: ["HttpClient.swift"], dependencies: []
                )
            ]
        )

        var configuration = Configuration.default
        configuration.format = .plantuml
        let script = ClassDiagramGenerator().generateScript(
            forPackage: description,
            packageRoot: tempRoot,
            with: configuration,
            sdkPath: nil
        )
        #expect(script.text.contains("<<Networking>>"))
    }
}
