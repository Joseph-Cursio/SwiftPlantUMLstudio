import Testing
@testable import SwiftUMLBridgeFramework

@Suite("ImportExtractor")
struct ImportExtractorTests {

    // MARK: - Basic extraction

    @Test("single import statement produces one edge")
    func singleImportProducesOneEdge() {
        let source = """
        import Foundation

        struct Foo {}
        """
        let edges = ImportExtractor.extract(from: source, sourceModule: "MyModule")
        #expect(edges.count == 1)
        #expect(edges[0].sourceModule == "MyModule")
        #expect(edges[0].importedModule == "Foundation")
    }

    @Test("multiple imports produce multiple edges")
    func multipleImportsProduceMultipleEdges() {
        let source = """
        import Foundation
        import SwiftUI
        import Combine
        """
        let edges = ImportExtractor.extract(from: source, sourceModule: "App")
        #expect(edges.count == 3)
        let modules = edges.map(\.importedModule)
        #expect(modules.contains("Foundation"))
        #expect(modules.contains("SwiftUI"))
        #expect(modules.contains("Combine"))
    }

    @Test("no import statements produces empty edges")
    func noImportsProducesEmpty() {
        let source = """
        struct Foo {
            var value: Int = 0
        }
        """
        let edges = ImportExtractor.extract(from: source, sourceModule: "Lib")
        #expect(edges.isEmpty)
    }

    @Test("source module label comes from parameter")
    func sourceModuleLabelFromParameter() {
        let source = "import UIKit"
        let edges = ImportExtractor.extract(from: source, sourceModule: "ViewLayer")
        #expect(edges.first?.sourceModule == "ViewLayer")
    }

    @Test("dotted module import is preserved")
    func dottedModuleImportPreserved() {
        let source = "import SwiftUI.Environment"
        let edges = ImportExtractor.extract(from: source, sourceModule: "Mod")
        #expect(edges.count == 1)
        // path components joined with "."
        #expect(edges[0].importedModule == "SwiftUI.Environment")
    }

    @Test("empty source produces no edges")
    func emptySourceProducesNoEdges() {
        let edges = ImportExtractor.extract(from: "", sourceModule: "Empty")
        #expect(edges.isEmpty)
    }

    @Test("duplicate imports produce duplicate edges")
    func duplicateImportsProduceDuplicateEdges() {
        let source = """
        import Foundation
        import Foundation
        """
        let edges = ImportExtractor.extract(from: source, sourceModule: "Dup")
        #expect(edges.count == 2)
    }
}
