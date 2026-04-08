import Foundation

/// Shared protocol for any diagram output (class diagram, sequence diagram, etc.).
/// Used by the GUI layer (DiagramWebView) and presenter layer to avoid type coupling.
public protocol DiagramOutputting: Sendable {
    var text: String { get }
    var format: DiagramFormat { get }
    func encodeText() -> String

    /// Positioned layout graph (available when format is `.svg`).
    var layoutGraph: LayoutGraph? { get }

    /// Positioned sequence layout (available for sequence diagrams when format is `.svg`).
    var sequenceLayout: SequenceLayout? { get }
}

/// Default nil implementations for optional layout data.
public extension DiagramOutputting {
    var layoutGraph: LayoutGraph? { nil }
    var sequenceLayout: SequenceLayout? { nil }
}

extension DiagramScript: DiagramOutputting {}
