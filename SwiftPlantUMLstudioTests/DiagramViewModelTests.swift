//
//  DiagramViewModelTests.swift
//  SwiftPlantUMLstudioTests
//
//  Unit tests for DiagramViewModel default values, guard logic, and history operations.
//

import CoreData
import Foundation
import Testing
import SwiftUMLBridgeFramework
@testable import SwiftPlantUMLstudio

// MARK: - GCD dispatch helpers

private func runOnMain(_ block: @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(block)
    } else {
        DispatchQueue.main.sync { MainActor.assumeIsolated(block) }
    }
}

private func runOnMain(_ block: @MainActor () throws -> Void) throws {
    if Thread.isMainThread {
        try MainActor.assumeIsolated(block)
    } else {
        var thrownError: (any Error)?
        DispatchQueue.main.sync {
            do { try MainActor.assumeIsolated(block) } catch { thrownError = error }
        }
        if let err = thrownError { throw err }
    }
}

// MARK: - DiagramViewModel Tests

@Suite("DiagramViewModel")
struct DiagramViewModelTests {

    // MARK: Default property values

    @Test("default diagramMode is classDiagram")
    func defaultDiagramMode() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            #expect(viewModel.diagramMode == .classDiagram)
        }
    }

    @Test("default diagramFormat is plantuml")
    func defaultDiagramFormat() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            #expect(viewModel.diagramFormat == .plantuml)
        }
    }

    @Test("default depsMode is types")
    func defaultDepsMode() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            #expect(viewModel.depsMode == .types)
        }
    }

    @Test("default sequenceDepth is 3")
    func defaultSequenceDepth() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            #expect(viewModel.sequenceDepth == 3)
        }
    }

    @Test("default entryPoint is empty string")
    func defaultEntryPoint() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            #expect(viewModel.entryPoint == "")
        }
    }

    @Test("default selectedPaths is empty")
    func defaultSelectedPaths() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            #expect(viewModel.selectedPaths.isEmpty)
        }
    }

    @Test("default isGenerating is false")
    func defaultIsGenerating() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            #expect(viewModel.isGenerating == false)
        }
    }

    @Test("default errorMessage is nil")
    func defaultErrorMessage() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            #expect(viewModel.errorMessage == nil)
        }
    }

    // MARK: currentScript

    @Test("currentScript is nil initially for classDiagram mode")
    func currentScriptNilForClassDiagram() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            viewModel.diagramMode = .classDiagram
            #expect(viewModel.currentScript == nil)
        }
    }

    @Test("currentScript is nil initially for sequenceDiagram mode")
    func currentScriptNilForSequenceDiagram() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            viewModel.diagramMode = .sequenceDiagram
            #expect(viewModel.currentScript == nil)
        }
    }

    @Test("currentScript is nil initially for dependencyGraph mode")
    func currentScriptNilForDependencyGraph() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            viewModel.diagramMode = .dependencyGraph
            #expect(viewModel.currentScript == nil)
        }
    }

    // MARK: generate() guard logic

    @Test("generate resets isGenerating when selectedPaths is empty for classDiagram")
    @MainActor
    func generateGuardsEmptyPathsClassDiagram() async {
        let isGenerating = await generateAndWait(mode: .classDiagram, paths: [])
        #expect(isGenerating == false)
    }

    @Test("generate resets isGenerating when selectedPaths is empty for dependencyGraph")
    @MainActor
    func generateGuardsEmptyPathsDependencyGraph() async {
        let isGenerating = await generateAndWait(mode: .dependencyGraph, paths: [])
        #expect(isGenerating == false)
    }

    @Test("generate resets isGenerating when selectedPaths is empty for sequenceDiagram")
    @MainActor
    func generateGuardsEmptyPathsSequenceDiagram() async {
        let isGenerating = await generateAndWait(
            mode: .sequenceDiagram, paths: [], entryPoint: "Foo.bar"
        )
        #expect(isGenerating == false)
    }

    @Test("generate resets isGenerating for sequenceDiagram with empty entryPoint")
    @MainActor
    func generateGuardsEmptyEntryPoint() async {
        let isGenerating = await generateAndWait(
            mode: .sequenceDiagram, paths: ["/some/path.swift"], entryPoint: ""
        )
        #expect(isGenerating == false)
    }

    @Test("generate resets isGenerating for sequenceDiagram with malformed entryPoint (no dot)")
    @MainActor
    func generateGuardsMalformedEntryPointNoDot() async {
        let isGenerating = await generateAndWait(
            mode: .sequenceDiagram, paths: ["/some/path.swift"], entryPoint: "FooBar"
        )
        #expect(isGenerating == false)
    }

    @Test("generate resets isGenerating for sequenceDiagram with too many dots in entryPoint")
    @MainActor
    func generateGuardsMalformedEntryPointTooManyDots() async {
        let isGenerating = await generateAndWait(
            mode: .sequenceDiagram, paths: ["/some/path.swift"], entryPoint: "Foo.bar.baz"
        )
        #expect(isGenerating == false)
    }

    @Test("refreshEntryPoints clears when no paths selected")
    func refreshEntryPointsClearsWhenNoPathsSelected() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            viewModel.availableEntryPoints = ["Foo.bar"]
            viewModel.selectedPaths = []
            viewModel.refreshEntryPoints()
            #expect(viewModel.availableEntryPoints.isEmpty)
        }
    }

    // MARK: pathSummary

    @Test("pathSummary with no paths")
    func pathSummaryNoPaths() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            #expect(viewModel.pathSummary == "No source selected")
        }
    }

    @Test("pathSummary with one path shows filename")
    func pathSummaryOnePath() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            viewModel.selectedPaths = ["/Users/test/MyApp/Sources/AppDelegate.swift"]
            #expect(viewModel.pathSummary == "AppDelegate.swift")
        }
    }

    @Test("pathSummary with multiple paths shows count")
    func pathSummaryMultiplePaths() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            viewModel.selectedPaths = ["/a/First.swift", "/b/Second.swift", "/c/Third.swift"]
            #expect(viewModel.pathSummary == "First.swift + 2 more")
        }
    }

    // MARK: save / history

    @Test("save creates a history entity")
    func saveCreatesHistoryEntity() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)
            viewModel.selectedPaths = ["/tmp/Foo.swift"]
            viewModel.diagramMode = .classDiagram
            viewModel.diagramFormat = .plantuml

            // We need a currentScript for save to work.
            // Load a fake history item to set restoredScript.
            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.id = UUID()
            entity.timestamp = Date()
            entity.mode = DiagramMode.classDiagram.rawValue
            entity.format = DiagramFormat.plantuml.rawValue
            entity.scriptText = "@startuml\nclass Foo\n@enduml"
            entity.paths = try? JSONEncoder().encode(["/tmp/Foo.swift"])
            entity.name = "Foo.swift"
            try? persistence.container.viewContext.save()

            viewModel.loadHistory()
            viewModel.loadDiagram(entity)
            #expect(viewModel.currentScript != nil)

            let countBefore = viewModel.history.count
            viewModel.save()
            #expect(viewModel.history.count == countBefore + 1)
        }
    }

    @Test("loadDiagram restores all properties from entity")
    func loadDiagramRestoresProperties() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)

            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.id = UUID()
            entity.timestamp = Date()
            entity.mode = DiagramMode.sequenceDiagram.rawValue
            entity.format = DiagramFormat.mermaid.rawValue
            entity.entryPoint = "Foo.bar"
            entity.sequenceDepth = 5
            entity.scriptText = "sequenceDiagram\nFoo->>Bar: bar()"
            entity.paths = try? JSONEncoder().encode(["/tmp/Foo.swift"])

            viewModel.loadDiagram(entity)

            #expect(viewModel.diagramMode == .sequenceDiagram)
            #expect(viewModel.diagramFormat == .mermaid)
            #expect(viewModel.entryPoint == "Foo.bar")
            #expect(viewModel.sequenceDepth == 5)
            #expect(viewModel.selectedPaths == ["/tmp/Foo.swift"])
            #expect(viewModel.currentScript?.text == "sequenceDiagram\nFoo->>Bar: bar()")
        }
    }

    @Test("deleteHistoryItem removes entity and clears selection")
    func deleteHistoryItemRemovesAndClears() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)

            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.id = UUID()
            entity.timestamp = Date()
            entity.mode = DiagramMode.classDiagram.rawValue
            entity.format = DiagramFormat.plantuml.rawValue
            entity.scriptText = "@startuml\n@enduml"
            entity.name = "Test"
            try? persistence.container.viewContext.save()

            viewModel.loadHistory()
            #expect(viewModel.history.count == 1)

            viewModel.selectedHistoryItem = entity
            viewModel.deleteHistoryItem(entity)

            #expect(viewModel.history.isEmpty)
            #expect(viewModel.selectedHistoryItem == nil)
        }
    }

    @Test("loadHistory returns entities sorted by timestamp descending")
    func loadHistorySorted() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)
            let ctx = persistence.container.viewContext

            for idx in 0..<3 {
                let entity = DiagramEntity(context: ctx)
                entity.id = UUID()
                entity.timestamp = Date().addingTimeInterval(TimeInterval(idx * 100))
                entity.mode = DiagramMode.classDiagram.rawValue
                entity.format = DiagramFormat.plantuml.rawValue
                entity.name = "Diagram \(idx)"
            }
            try? ctx.save()

            viewModel.loadHistory()
            #expect(viewModel.history.count == 3)
            // Most recent first
            #expect(viewModel.history[0].name == "Diagram 2")
            #expect(viewModel.history[2].name == "Diagram 0")
        }
    }
}

// MARK: - generate() guard helper

@MainActor
private func generateAndWait(
    mode: DiagramMode,
    paths: [String],
    entryPoint: String = ""
) async -> Bool {
    let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
    viewModel.diagramMode = mode
    viewModel.selectedPaths = paths
    viewModel.entryPoint = entryPoint

    viewModel.generate()

    // Give the Task a moment to start and run its synchronous guard checks.
    // The ViewModel now has a 300ms debounce sleep, so we must wait longer than that.
    try? await Task.sleep(nanoseconds: 400_000_000) // 400ms
    await Task.yield()

    return viewModel.isGenerating
}
