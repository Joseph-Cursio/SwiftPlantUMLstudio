import Testing
@testable import SwiftUMLBridgeFramework
import Foundation

@Suite("SequenceDiagramGenerator")
struct SequenceDiagramGeneratorTests {

    private let generator = SequenceDiagramGenerator()

    // MARK: - Helper

    /// Writes `source` to a uniquely-named temp `.swift` file and returns its path.
    private func tempSwiftFile(_ source: String) throws -> String {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("swift")
        try source.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    // MARK: - Empty input

    @Test("empty paths produces script with no call arrows")
    func emptyPathsProducesNoArrows() {
        let script = generator.generateScript(for: [], entryType: "Foo", entryMethod: "run")
        #expect(script.text.contains("->") == false)
    }

    @Test("empty paths returns plantuml format by default")
    func emptyPathsDefaultFormatIsPlantuml() {
        let script = generator.generateScript(for: [], entryType: "Foo", entryMethod: "run")
        #expect(script.format == .plantuml)
    }

    // MARK: - Entry point resolution

    @Test("valid source with matching entry point includes callee method in script")
    func validSourceMatchingEntryIncludesCallee() throws {
        let source = """
        class Foo {
            func run() { self.helper() }
            func helper() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        let script = generator.generateScript(for: [path], entryType: "Foo", entryMethod: "run")
        #expect(script.text.contains("helper"))
    }

    @Test("entry point not found in source produces no arrows")
    func entryPointNotFoundProducesNoArrows() throws {
        let source = """
        class Foo {
            func run() { self.helper() }
            func helper() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        let script = generator.generateScript(for: [path], entryType: "Missing", entryMethod: "go")
        #expect(script.text.contains("->") == false)
    }

    @Test("cross-type call appears as arrow in script")
    func crossTypeCallAppearsAsArrow() throws {
        let source = """
        class A {
            func start() { B.step() }
        }
        class B {
            func step() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        let script = generator.generateScript(for: [path], entryType: "A", entryMethod: "start")
        #expect(script.text.contains("step"))
        #expect(script.text.contains("A"))
        #expect(script.text.contains("B"))
    }

    // MARK: - Depth limiting

    @Test("depth 1 includes direct callee but not transitive callee")
    func depthOneLimitsTransitiveCall() throws {
        let source = """
        class A {
            func start() { B.step() }
        }
        class B {
            func step() { C.finish() }
        }
        class C {
            func finish() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        let script = generator.generateScript(
            for: [path], entryType: "A", entryMethod: "start", depth: 1
        )
        #expect(script.text.contains("step"))
        #expect(script.text.contains("finish") == false)
    }

    @Test("depth 2 includes two levels of calls")
    func depthTwoIncludesTwoLevels() throws {
        let source = """
        class A {
            func start() { B.step() }
        }
        class B {
            func step() { C.finish() }
        }
        class C {
            func finish() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        let script = generator.generateScript(
            for: [path], entryType: "A", entryMethod: "start", depth: 2
        )
        #expect(script.text.contains("step"))
        #expect(script.text.contains("finish"))
    }

    // MARK: - Format propagation

    @Test("plantuml format produces @startuml header")
    func plantumlFormatProducesStartuml() throws {
        let source = """
        class Foo {
            func run() { self.helper() }
            func helper() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        let script = generator.generateScript(for: [path], entryType: "Foo", entryMethod: "run")
        #expect(script.format == .plantuml)
        #expect(script.text.hasPrefix("@startuml"))
    }

    @Test("mermaid format produces sequenceDiagram header")
    func mermaidFormatProducesSequenceDiagramHeader() throws {
        let source = """
        class Foo {
            func run() { self.helper() }
            func helper() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        var config = Configuration.default
        config.format = .mermaid
        let script = generator.generateScript(
            for: [path], entryType: "Foo", entryMethod: "run", with: config
        )
        #expect(script.format == .mermaid)
        #expect(script.text.contains("sequenceDiagram"))
    }

    // MARK: - Multiple files

    // MARK: - findEntryPoints

    @Test("findEntryPoints returns sorted list of Type.method strings")
    func findEntryPointsReturnsSorted() throws {
        let source = """
        class Zebra {
            func zap() {}
        }
        class Alpha {
            func act() {}
            func begin() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        let entryPoints = generator.findEntryPoints(for: [path])
        #expect(entryPoints == entryPoints.sorted())
        #expect(entryPoints.contains("Alpha.act"))
        #expect(entryPoints.contains("Alpha.begin"))
        #expect(entryPoints.contains("Zebra.zap"))
    }

    @Test("findEntryPoints returns empty for nonexistent path")
    func findEntryPointsNonexistentPath() {
        let entryPoints = generator.findEntryPoints(for: ["/nonexistent/path/Foo.swift"])
        #expect(entryPoints.isEmpty)
    }

    @Test("findEntryPoints deduplicates across multiple files")
    func findEntryPointsDeduplicates() throws {
        let source1 = """
        class Foo {
            func run() {}
        }
        """
        let source2 = """
        class Bar {
            func execute() {}
        }
        """
        let path1 = try tempSwiftFile(source1)
        let path2 = try tempSwiftFile(source2)
        defer {
            try? FileManager.default.removeItem(atPath: path1)
            try? FileManager.default.removeItem(atPath: path2)
        }

        let entryPoints = generator.findEntryPoints(for: [path1, path2])
        #expect(entryPoints.contains("Foo.run"))
        #expect(entryPoints.contains("Bar.execute"))
    }

    // MARK: - generateScript edge cases

    @Test("generateScript with nonexistent path produces empty-like script")
    func generateScriptNonexistentPath() {
        let script = generator.generateScript(
            for: ["/does/not/exist.swift"],
            entryType: "Foo",
            entryMethod: "run"
        )
        #expect(script.text.contains("->") == false)
    }

    @Test("generateScript with depth 0 includes no calls")
    func generateScriptDepthZero() throws {
        let source = """
        class Foo {
            func run() { self.helper() }
            func helper() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        let script = generator.generateScript(
            for: [path], entryType: "Foo", entryMethod: "run", depth: 0
        )
        #expect(script.text.contains("helper") == false)
    }

    @Test("generateScript with nomnoml format propagates format")
    func nomnomlFormatPropagation() throws {
        let source = """
        class Foo {
            func run() { self.helper() }
            func helper() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        var config = Configuration.default
        config.format = .nomnoml
        let script = generator.generateScript(
            for: [path], entryType: "Foo", entryMethod: "run", with: config
        )
        #expect(script.format == .nomnoml)
    }

    @Test("generateScript with svg format propagates format")
    func svgFormatPropagation() throws {
        let source = """
        class Foo {
            func run() { self.helper() }
            func helper() {}
        }
        """
        let path = try tempSwiftFile(source)
        defer { try? FileManager.default.removeItem(atPath: path) }

        var config = Configuration.default
        config.format = .svg
        let script = generator.generateScript(
            for: [path], entryType: "Foo", entryMethod: "run", with: config
        )
        #expect(script.format == .svg)
    }

    // MARK: - Multiple files

    @Test("edges from multiple files are combined for traversal")
    func multipleFilesCombineEdgesAcrossFiles() throws {
        let source1 = """
        class ServiceA {
            func start() { ServiceB.process() }
        }
        """
        let source2 = """
        class ServiceB {
            func process() { self.finish() }
            func finish() {}
        }
        """
        let path1 = try tempSwiftFile(source1)
        let path2 = try tempSwiftFile(source2)
        defer {
            try? FileManager.default.removeItem(atPath: path1)
            try? FileManager.default.removeItem(atPath: path2)
        }

        let script = generator.generateScript(
            for: [path1, path2],
            entryType: "ServiceA",
            entryMethod: "start",
            depth: 5
        )
        // Both cross-file edge (start → process) and within-file edge (process → finish) should appear.
        #expect(script.text.contains("process"))
        #expect(script.text.contains("finish"))
    }
}
