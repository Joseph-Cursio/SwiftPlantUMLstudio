import Foundation

/// The kind of relationship a dependency edge represents.
public enum DependencyEdgeKind: String, Sendable, CaseIterable {
    case inherits
    case conforms
    case imports
}

/// A directed dependency relationship between two named nodes.
public struct DependencyEdge: Sendable, Hashable {
    /// The name of the dependent node (the node that depends on `to`).
    public let from: String

    /// The name of the node being depended upon.
    public let to: String

    /// The kind of dependency relationship.
    public let kind: DependencyEdgeKind

    public init(from: String, to: String, kind: DependencyEdgeKind) {
        self.from = from
        self.to = to
        self.kind = kind
    }
}
