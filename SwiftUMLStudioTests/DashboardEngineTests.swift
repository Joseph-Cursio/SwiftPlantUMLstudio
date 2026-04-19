import Foundation
import Testing
import SwiftUMLBridgeFramework
@testable import SwiftUMLStudio

// MARK: - GCD dispatch helpers

private func runOnMain(_ block: @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(block)
    } else {
        DispatchQueue.main.sync { MainActor.assumeIsolated(block) }
    }
}

private func makeSummary(
    totalFiles: Int = 3,
    totalTypes: Int = 5,
    typeBreakdown: [String: Int] = ["Classes": 5],
    totalRelationships: Int = 2,
    moduleImports: [String] = [],
    topConnectedTypes: [(name: String, connectionCount: Int)] = [],
    cycleWarnings: [String] = [],
    entryPoints: [String] = [],
    stateMachines: [StateMachineModel] = []
) -> ProjectSummary {
    ProjectSummary(
        totalFiles: totalFiles,
        totalTypes: totalTypes,
        typeBreakdown: typeBreakdown,
        totalRelationships: totalRelationships,
        moduleImports: moduleImports,
        topConnectedTypes: topConnectedTypes,
        cycleWarnings: cycleWarnings,
        entryPoints: entryPoints,
        stateMachines: stateMachines
    )
}

// MARK: - InsightEngine Tests

struct InsightEngineTests {

    @Test("generates cycle warning when cycles present")
    func cycleWarning() throws {
        runOnMain {
            let summary = makeSummary(cycleWarnings: ["TypeA", "TypeB"])
            let insights = InsightEngine.generate(from: summary)
            let cycleInsight = insights.first { $0.title.contains("Circular") }
            #expect(cycleInsight != nil, "Expected a cycle warning insight")
            #expect(cycleInsight?.severity == .warning)
        }
    }

    @Test("generates composition insight when types exist")
    func compositionInsight() {
        runOnMain {
            let summary = makeSummary(totalTypes: 7, typeBreakdown: ["Classes": 4, "Structs": 3])
            let insights = InsightEngine.generate(from: summary)
            let comp = insights.first { $0.title.contains("composition") }
            #expect(comp != nil, "Expected a composition insight")
        }
    }

    @Test("generates high-connectivity insight for popular types")
    func highConnectivity() {
        runOnMain {
            let summary = makeSummary(
                topConnectedTypes: [(name: "Database", connectionCount: 12)]
            )
            let insights = InsightEngine.generate(from: summary)
            let conn = insights.first { $0.title.contains("Database") }
            #expect(conn != nil, "Expected a connectivity insight for Database")
            #expect(conn?.severity == .noteworthy)
        }
    }

    @Test("generates entry points insight when methods available")
    func entryPointInsight() {
        runOnMain {
            let summary = makeSummary(entryPoints: ["Foo.bar", "Baz.qux"])
            let insights = InsightEngine.generate(from: summary)
            let method = insights.first { $0.title.contains("methods") }
            #expect(method != nil, "Expected an entry points insight")
        }
    }

    @Test("generates state machine insight when candidates detected")
    func stateMachineInsight() {
        runOnMain {
            let model = StateMachineModel(
                hostType: "TrafficLight", enumType: "Light",
                states: [StateMachineState(name: "red", isInitial: true)],
                transitions: []
            )
            let summary = makeSummary(stateMachines: [model])
            let insights = InsightEngine.generate(from: summary)
            let stateInsight = insights.first { $0.title.contains("state machine") }
            #expect(stateInsight != nil, "Expected a state machine insight")
            #expect(stateInsight?.description.contains("TrafficLight") == true)
        }
    }
}

// MARK: - SuggestionEngine Tests

struct SuggestionEngineTests {

    @Test("always suggests class diagram when types exist")
    func classDiagramSuggestion() {
        runOnMain {
            let summary = makeSummary()
            let suggestions = SuggestionEngine.generate(from: summary, isProUnlocked: false)
            let classSug = suggestions.first { $0.requiresPro == false }
            #expect(classSug != nil, "Expected a free class diagram suggestion")
        }
    }

    @Test("suggests sequence diagrams for entry points as Pro")
    func sequenceSuggestionIsPro() {
        runOnMain {
            let summary = makeSummary(entryPoints: ["Foo.bar"])
            let suggestions = SuggestionEngine.generate(from: summary, isProUnlocked: false)
            let seqSug = suggestions.first { $0.title.contains("Trace") }
            #expect(seqSug != nil, "Expected a sequence diagram suggestion")
            #expect(seqSug?.requiresPro == true)
        }
    }

    @Test("suggests dependency graph when relationships exist")
    func dependencyGraphSuggestion() {
        runOnMain {
            let summary = makeSummary(totalRelationships: 8)
            let suggestions = SuggestionEngine.generate(from: summary, isProUnlocked: true)
            let deps = suggestions.first { $0.title.contains("depend") }
            #expect(deps != nil, "Expected a dependency graph suggestion")
        }
    }

    @Test("no suggestions when no types")
    func emptyProject() {
        runOnMain {
            let summary = makeSummary(totalFiles: 0, totalTypes: 0, typeBreakdown: [:], totalRelationships: 0)
            let suggestions = SuggestionEngine.generate(from: summary, isProUnlocked: true)
            #expect(suggestions.isEmpty)
        }
    }

    @Test("suggests state machine diagrams as Pro for each detected candidate")
    func stateMachineSuggestionIsPro() {
        runOnMain {
            let model = StateMachineModel(
                hostType: "Loader", enumType: "State",
                states: [StateMachineState(name: "idle", isInitial: true)],
                transitions: [StateTransition(from: "idle", toState: "busy", trigger: "start")]
            )
            let summary = makeSummary(stateMachines: [model])
            let suggestions = SuggestionEngine.generate(from: summary, isProUnlocked: false)
            let stateSug = suggestions.first { $0.title.contains("Loader.State") }
            #expect(stateSug != nil, "Expected a state machine suggestion")
            #expect(stateSug?.requiresPro == true)
            switch stateSug?.action {
            case .stateMachine(let identifier): #expect(identifier == "Loader.State")
            default: Issue.record("Expected a stateMachine action")
            }
        }
    }

    @Test("state machine suggestions are ordered by confidence (high first)")
    func stateMachineSuggestionsOrderedByConfidence() {
        runOnMain {
            let low = StateMachineModel(
                hostType: "Lo", enumType: "L",
                states: [], transitions: [], confidence: .low, notes: []
            )
            let high = StateMachineModel(
                hostType: "Hi", enumType: "H",
                states: [], transitions: [], confidence: .high, notes: []
            )
            let medium = StateMachineModel(
                hostType: "Me", enumType: "M",
                states: [], transitions: [], confidence: .medium, notes: []
            )
            let summary = makeSummary(stateMachines: [low, high, medium])
            let suggestions = SuggestionEngine.generate(from: summary, isProUnlocked: true)
            let stateSuggestions = suggestions.compactMap { suggestion -> String? in
                if case .stateMachine(let identifier) = suggestion.action { return identifier }
                return nil
            }
            #expect(stateSuggestions == ["Hi.H", "Me.M", "Lo.L"])
        }
    }
}
