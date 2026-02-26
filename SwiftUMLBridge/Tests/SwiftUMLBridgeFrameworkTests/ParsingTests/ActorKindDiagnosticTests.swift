import Testing
@testable import SwiftUMLBridgeFramework

// NOTE: As of SourceKitten 0.37.x / SourceKit on macOS 26, actor declarations are
// reported with kind `source.lang.swift.decl.class`. SourceKit internally treats
// actors as a subtype of class. Our `ElementKind.actor` case (raw value
// "source.lang.swift.decl.actor") is present in the enum for future compatibility
// when SourceKit updates its output, but today actors will parse as `.class`.
//
// Actors still appear in diagrams — they just share the class stereotype for now.
// A future M1 enhancement could detect the `actor` keyword via attributes or
// SwiftSyntax to render the `<<actor>>` stereotype correctly.

@Suite("ActorKindDiagnostic")
struct ActorKindDiagnosticTests {

    @Test("actor source parses and appears in diagram as class node")
    func actorAppearsAsDiagramNode() {
        let source = "actor ImageCache { var count: Int = 0 }"
        let generator = ClassDiagramGenerator()
        let script = generator.generateScript(for: source, with: .default)
        // Actors are currently parsed as class by SourceKit — they still appear
        #expect(script.text.contains("ImageCache"))
        #expect(script.text.hasPrefix("@startuml"))
        #expect(script.text.hasSuffix("@enduml"))
    }

    @Test("ElementKind.actor raw value is ready for future SourceKit support")
    func actorKindRawValueIsCorrect() {
        #expect(ElementKind.actor.rawValue == "source.lang.swift.decl.actor")
    }
}
