import Foundation
import SwiftUMLBridgeFramework

struct DiagramSuggestion: Identifiable, Sendable {
    let identifier = UUID()
    let icon: String
    let title: String
    let description: String
    let action: SuggestionAction
    let requiresPro: Bool

    var id: UUID { identifier }
}

enum SuggestionAction: Sendable {
    case classDiagram
    case sequenceDiagram(entryPoint: String)
    case dependencyGraph(mode: DepsMode)
    case stateMachine(identifier: String)
}

nonisolated enum SuggestionEngine {
    static func generate(from summary: ProjectSummary, isProUnlocked: Bool) -> [DiagramSuggestion] {
        var suggestions: [DiagramSuggestion] = []

        // Always suggest a class diagram if there are types
        if summary.totalTypes > 0 {
            suggestions.append(DiagramSuggestion(
                icon: "rectangle.3.group",
                title: "See how your types are connected",
                description: "\(summary.totalTypes) types with \(summary.totalRelationships) relationships.",
                action: .classDiagram,
                requiresPro: false
            ))
        }

        // Suggest sequence diagrams for top entry points
        for entryPoint in summary.entryPoints.prefix(3) {
            suggestions.append(DiagramSuggestion(
                icon: "arrow.right.arrow.left",
                title: "Trace \(entryPoint)",
                description: "See the execution flow when this method runs.",
                action: .sequenceDiagram(entryPoint: entryPoint),
                requiresPro: true
            ))
        }

        // Suggest dependency graph if there are relationships
        if summary.totalRelationships > 0 {
            suggestions.append(DiagramSuggestion(
                icon: "arrow.triangle.branch",
                title: "See which types depend on each other",
                description: "\(summary.totalRelationships) dependency edges found.",
                action: .dependencyGraph(mode: .types),
                requiresPro: true
            ))
        }

        // Suggest module dependency graph if multiple modules imported
        if summary.moduleImports.count >= 2 {
            suggestions.append(DiagramSuggestion(
                icon: "shippingbox.and.arrow.backward",
                title: "See module dependencies",
                description: "\(summary.moduleImports.count) external modules detected.",
                action: .dependencyGraph(mode: .modules),
                requiresPro: true
            ))
        }

        // Suggest state machine diagrams for detected candidates, highest-confidence first
        let sortedStateMachines = summary.stateMachines
            .sorted { lhs, rhs in lhs.confidence > rhs.confidence }
            .prefix(3)
        for model in sortedStateMachines {
            let transitionCount = model.transitions.count
            let summaryText: String
            switch model.confidence {
            case .high:
                summaryText = "\(model.states.count) states, \(transitionCount) transitions."
            case .medium:
                summaryText = "\(model.states.count) states — type inferred from initializer."
            case .low:
                summaryText = "\(transitionCount) transitions — sources unknown."
            }
            suggestions.append(DiagramSuggestion(
                icon: "arrow.triangle.2.circlepath",
                title: "Diagram \(model.identifier)",
                description: summaryText,
                action: .stateMachine(identifier: model.identifier),
                requiresPro: true
            ))
        }

        return suggestions
    }
}
