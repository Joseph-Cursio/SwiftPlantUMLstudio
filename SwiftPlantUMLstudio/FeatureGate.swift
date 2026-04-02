import Foundation

enum ProFeature: String, CaseIterable {
    case sequenceDiagrams
    case dependencyGraphs
    case exportMarkup
    case formatSelection
    case unlimitedProjects
}

@MainActor
enum FeatureGate {
    static func isUnlocked(_ feature: ProFeature, manager: SubscriptionManager) -> Bool {
        manager.isProUnlocked
    }
}
