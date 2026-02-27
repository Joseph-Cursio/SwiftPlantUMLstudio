import Testing
@testable import SwiftUMLBridgeFramework
import Foundation

@Suite("ClassDiagramGenerator")
struct ClassDiagramGeneratorTests {

    private let generator = ClassDiagramGenerator()

    private var projectMockURL: URL {
        Bundle.module.resourceURL!
            .appendingPathComponent("TestData")
            .appendingPathComponent("ProjectMock")
    }

    // MARK: - generateScript from string

    @Test("generateScript produces valid @startuml/@enduml for class source")
    func generateScriptClassSource() {
        let source = "class MyClass { var name: String = \"\" }"
        let script = generator.generateScript(for: source)
        #expect(script.text.hasPrefix("@startuml"))
        #expect(script.text.hasSuffix("@enduml"))
    }

    @Test("generateScript includes class name in output")
    func generateScriptIncludesClassName() {
        let script = generator.generateScript(for: "class Greeter {}")
        #expect(script.text.contains("Greeter"))
    }

    @Test("generateScript handles empty source")
    func generateScriptEmptySource() {
        let script = generator.generateScript(for: "")
        #expect(script.text.hasPrefix("@startuml"))
        #expect(script.text.hasSuffix("@enduml"))
    }

    @Test("generateScript with struct source includes struct stereotype")
    func generateScriptStructSource() {
        let script = generator.generateScript(for: "struct Point { var x: Double; var y: Double }")
        #expect(script.text.contains("Point"))
    }

    @Test("generateScript with protocol source")
    func generateScriptProtocolSource() {
        let script = generator.generateScript(for: "protocol Drawable { func draw() }")
        #expect(script.text.contains("Drawable"))
    }

    @Test("generateScript with custom configuration respects theme")
    func generateScriptWithTheme() {
        var config = Configuration.default
        config = Configuration(
            theme: .amiga,
            relationships: config.relationships
        )
        let script = generator.generateScript(for: "class Foo {}", with: config)
        #expect(script.text.contains("!theme"))
        #expect(script.text.contains("amiga"))
    }

    // MARK: - generateScript from files

    @Test("generateScript from swift file contains parsed content")
    func generateScriptFromFile() {
        let swiftFile = projectMockURL.appendingPathComponent("Level 0.swift")
        let script = generator.generateScript(for: [swiftFile.path])
        #expect(script.text.hasPrefix("@startuml"))
    }

    @Test("generateScript from empty files list produces minimal script")
    func generateScriptFromEmptyFiles() {
        let script = generator.generateScript(for: [String]())
        #expect(script.text.hasPrefix("@startuml"))
        #expect(script.text.hasSuffix("@enduml"))
    }

    // MARK: - generate (end-to-end with ConsolePresenter)

    @Test("generate from string with ConsolePresenter completes without error")
    func generateFromStringWithConsolePresenter() async {
        let presenter = ConsolePresenter()
        await generator.generate(from: "class Foo {}", with: .default, presentedBy: presenter)
        // If we reach here, no crash occurred
        #expect(Bool(true))
    }

    @Test("generate from files with ConsolePresenter completes without error")
    func generateFromFilesWithConsolePresenter() async {
        let presenter = ConsolePresenter()
        await generator.generate(for: [String](), with: .default, presentedBy: presenter)
        #expect(Bool(true))
    }

    // MARK: - logProcessingDuration

    @Test("logProcessingDuration does not crash")
    func logProcessingDurationNoCrash() {
        let start = Date().addingTimeInterval(-1.0)
        generator.logProcessingDuration(started: start)
        #expect(Bool(true))
    }
}
