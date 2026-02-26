import Foundation

/// Unified interface for presenting a diagram script
public protocol DiagramPresenting {
    /// Present script/diagram to user
    /// - Parameters:
    ///   - script: in PlantUML notation
    ///   - completionHandler: called when presentation was triggered
    func present(script: DiagramScript, completionHandler: @escaping () -> Void)
}
