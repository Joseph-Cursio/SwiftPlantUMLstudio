import Foundation

// MARK: - Class Diagram Generator Protocol

/// Abstraction for class diagram generation, enabling mock injection in tests.
public protocol ClassDiagramGenerating: Sendable {
    func generateScript(
        for paths: [String],
        with configuration: Configuration,
        sdkPath: String?
    ) -> DiagramScript
}

/// Default parameter for sdkPath so callers don't need to pass it.
public extension ClassDiagramGenerating {
    func generateScript(
        for paths: [String],
        with configuration: Configuration
    ) -> DiagramScript {
        generateScript(for: paths, with: configuration, sdkPath: nil)
    }
}

// MARK: - Sequence Diagram Generator Protocol

/// Abstraction for sequence diagram generation, enabling mock injection in tests.
public protocol SequenceDiagramGenerating: Sendable {
    func findEntryPoints(for paths: [String]) -> [String]

    func generateScript(
        for paths: [String],
        entryType: String,
        entryMethod: String,
        depth: Int,
        with configuration: Configuration
    ) -> SequenceScript
}

// MARK: - Dependency Graph Generator Protocol

/// Abstraction for dependency graph generation, enabling mock injection in tests.
public protocol DependencyGraphGenerating: Sendable {
    func generateScript(
        for paths: [String],
        mode: DepsMode,
        with configuration: Configuration
    ) -> DepsScript
}
