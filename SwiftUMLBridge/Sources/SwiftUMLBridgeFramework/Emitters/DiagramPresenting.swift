import Foundation

/// Unified interface for presenting a diagram script
public protocol DiagramPresenting: Sendable {
    /// Present script/diagram to user
    /// - Parameter script: in PlantUML notation
    func present(script: DiagramScript) async
}
