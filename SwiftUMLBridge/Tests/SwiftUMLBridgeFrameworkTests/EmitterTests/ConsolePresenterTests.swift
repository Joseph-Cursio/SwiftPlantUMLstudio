import Testing
@testable import SwiftUMLBridgeFramework

@Suite("ConsolePresenter")
struct ConsolePresenterTests {

    @Test("present() calls the completion handler")
    func presentCallsCompletionHandler() {
        let presenter = ConsolePresenter()
        let script = DiagramScript(items: [], configuration: .default)
        var completed = false
        presenter.present(script: script) { completed = true }
        #expect(completed)
    }

    @Test("ConsolePresenter can be instantiated with default init")
    func defaultInit() {
        let presenter = ConsolePresenter()
        #expect(presenter is DiagramPresenting)
    }

    @Test("present() does not throw")
    func presentDoesNotThrow() {
        let presenter = ConsolePresenter()
        let generator = ClassDiagramGenerator()
        let script = generator.generateScript(for: "struct Foo {}")
        var completed = false
        presenter.present(script: script) { completed = true }
        #expect(completed)
    }
}
