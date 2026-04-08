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

    // MARK: - loadDiagram edge cases

    @Test("loadDiagram with dependencyGraph mode restores depsMode from entryPoint")
    func loadDiagramDependencyGraphMode() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)

            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.id = UUID()
            entity.timestamp = Date()
            entity.mode = DiagramMode.dependencyGraph.rawValue
            entity.format = DiagramFormat.plantuml.rawValue
            entity.entryPoint = DepsMode.modules.rawValue

            viewModel.loadDiagram(entity)

            #expect(viewModel.diagramMode == .dependencyGraph)
            #expect(viewModel.depsMode == .modules)
        }
    }

    @Test("loadDiagram with nil scriptText sets no restoredScript")
    func loadDiagramNilScriptText() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)

            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.id = UUID()
            entity.timestamp = Date()
            entity.mode = DiagramMode.classDiagram.rawValue
            entity.format = DiagramFormat.plantuml.rawValue
            entity.scriptText = nil

            viewModel.loadDiagram(entity)

            #expect(viewModel.currentScript == nil)
        }
    }

    @Test("loadDiagram with invalid mode string defaults to classDiagram")
    func loadDiagramInvalidMode() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)

            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.id = UUID()
            entity.timestamp = Date()
            entity.mode = "invalid_mode"
            entity.format = "invalid_format"

            viewModel.loadDiagram(entity)

            #expect(viewModel.diagramMode == .classDiagram)
            #expect(viewModel.diagramFormat == .plantuml)
        }
    }

    @Test("loadDiagram with nil paths does not crash")
    func loadDiagramNilPaths() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)

            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.id = UUID()
            entity.timestamp = Date()
            entity.mode = DiagramMode.classDiagram.rawValue
            entity.paths = nil

            viewModel.loadDiagram(entity)

            // selectedPaths should remain unchanged (empty default)
            #expect(viewModel.selectedPaths.isEmpty)
        }
    }

    // MARK: - deleteHistoryItem edge cases

    @Test("deleteHistoryItem when item is not the selected one does not clear selection")
    func deleteHistoryItemNotSelected() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)
            let ctx = persistence.container.viewContext

            let entity1 = DiagramEntity(context: ctx)
            entity1.id = UUID()
            entity1.timestamp = Date()
            entity1.mode = DiagramMode.classDiagram.rawValue
            entity1.name = "Entity1"

            let entity2 = DiagramEntity(context: ctx)
            entity2.id = UUID()
            entity2.timestamp = Date().addingTimeInterval(100)
            entity2.mode = DiagramMode.classDiagram.rawValue
            entity2.name = "Entity2"
            entity2.scriptText = "@startuml\n@enduml"
            try? ctx.save()

            viewModel.loadHistory()
            viewModel.selectedHistoryItem = entity2
            viewModel.loadDiagram(entity2)

            // Delete entity1 (not the selected one)
            viewModel.deleteHistoryItem(entity1)

            // Selection should remain
            #expect(viewModel.selectedHistoryItem === entity2)
        }
    }

    // MARK: - analyzeProject

    @Test("analyzeProject with empty paths clears summary and insights")
    func analyzeProjectEmptyPaths() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)
            viewModel.selectedPaths = []

            viewModel.analyzeProject()

            #expect(viewModel.projectSummary == nil)
            #expect(viewModel.insights.isEmpty)
            #expect(viewModel.suggestions.isEmpty)
        }
    }

    // MARK: - saveToHistory name generation

    @Test("save with multiple paths generates name with count")
    func saveMultiplePathsName() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)
            viewModel.selectedPaths = ["/a/First.swift", "/b/Second.swift"]
            viewModel.diagramMode = .classDiagram
            viewModel.diagramFormat = .plantuml

            // Set up a restoredScript so save works
            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.scriptText = "@startuml\n@enduml"
            viewModel.loadDiagram(entity)

            viewModel.save()
            viewModel.loadHistory()

            let saved = viewModel.history.first
            #expect(saved?.name == "First.swift + 1")
        }
    }

    @Test("save with no paths generates Untitled Diagram name")
    func saveNoPathsName() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)
            viewModel.selectedPaths = []
            viewModel.diagramMode = .classDiagram

            // Set up a restoredScript so save works
            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.scriptText = "@startuml\n@enduml"
            viewModel.loadDiagram(entity)

            viewModel.save()
            viewModel.loadHistory()

            let saved = viewModel.history.first
            #expect(saved?.name == "Untitled Diagram")
        }
    }

    @Test("save for sequence diagram stores entryPoint")
    func saveSequenceDiagramStoresEntryPoint() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)
            viewModel.selectedPaths = ["/tmp/Foo.swift"]
            viewModel.diagramMode = .sequenceDiagram
            viewModel.entryPoint = "Foo.bar"
            viewModel.diagramFormat = .plantuml

            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.mode = DiagramMode.sequenceDiagram.rawValue
            entity.scriptText = "sequenceDiagram\nFoo->>Bar: bar()"
            viewModel.loadDiagram(entity)

            viewModel.save()
            viewModel.loadHistory()

            let saved = viewModel.history.first
            #expect(saved?.entryPoint == "Foo.bar")
        }
    }

    @Test("save for dependency graph stores depsMode in entryPoint field")
    func saveDependencyGraphStoresDepsMode() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)
            viewModel.selectedPaths = ["/tmp/Foo.swift"]
            viewModel.diagramMode = .dependencyGraph
            viewModel.depsMode = .modules
            viewModel.diagramFormat = .plantuml

            let entity = DiagramEntity(context: persistence.container.viewContext)
            entity.mode = DiagramMode.dependencyGraph.rawValue
            entity.entryPoint = DepsMode.modules.rawValue
            entity.scriptText = "@startuml\ndeps\n@enduml"
            viewModel.loadDiagram(entity)

            viewModel.save()
            viewModel.loadHistory()

            let saved = viewModel.history.first
            #expect(saved?.entryPoint == DepsMode.modules.rawValue)
        }
    }

    // MARK: - selectFile edge cases

    @Test("selectFile with unreadable URL shows fallback message")
    func selectFileUnreadable() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            let bogusURL = URL(fileURLWithPath: "/nonexistent/path/Fake.swift")
            viewModel.selectFile(bogusURL)
            #expect(viewModel.selectedFileContent == "// Could not read file")
            #expect(viewModel.selectedFileURL == bogusURL)
        }
    }

    // MARK: - updateArchitectureDiff

    @Test("updateArchitectureDiff sets nil when no summary")
    func updateArchitectureDiffNoSummary() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            viewModel.selectedPaths = ["/tmp/something"]
            viewModel.projectSummary = nil

            viewModel.updateArchitectureDiff()

            #expect(viewModel.architectureDiff == nil)
        }
    }

    @Test("updateArchitectureDiff sets nil when paths empty")
    func updateArchitectureDiffEmptyPaths() {
        runOnMain {
            let viewModel = DiagramViewModel(persistenceController: PersistenceController(inMemory: true))
            viewModel.selectedPaths = []

            viewModel.updateArchitectureDiff()

            #expect(viewModel.architectureDiff == nil)
        }
    }

    // MARK: - saveSnapshot

    @Test("saveSnapshot does nothing when not pro unlocked")
    func saveSnapshotNotPro() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)
            viewModel.selectedPaths = ["/tmp/Foo.swift"]

            viewModel.saveSnapshot(isProUnlocked: false)

            viewModel.loadSnapshots()
            #expect(viewModel.snapshots.isEmpty)
        }
    }

    @Test("saveSnapshot does nothing when summary is nil")
    func saveSnapshotNoSummary() {
        runOnMain {
            let persistence = PersistenceController(inMemory: true)
            let viewModel = DiagramViewModel(persistenceController: persistence)
            viewModel.selectedPaths = ["/tmp/Foo.swift"]
            viewModel.projectSummary = nil

            viewModel.saveSnapshot(isProUnlocked: true)

            viewModel.loadSnapshots()
            #expect(viewModel.snapshots.isEmpty)
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
