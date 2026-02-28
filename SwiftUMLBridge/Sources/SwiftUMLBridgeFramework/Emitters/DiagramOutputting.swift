import Foundation

/// Shared protocol for any diagram output (class diagram, sequence diagram, etc.).
/// Used by the GUI layer (DiagramWebView) and presenter layer to avoid type coupling.
public protocol DiagramOutputting: Sendable {
    var text: String { get }
    var format: DiagramFormat { get }
    func encodeText() -> String
}

extension DiagramScript: DiagramOutputting {}
