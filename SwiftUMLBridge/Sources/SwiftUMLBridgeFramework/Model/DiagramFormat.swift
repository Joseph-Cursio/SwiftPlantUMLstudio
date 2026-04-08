/// Output diagram format
public enum DiagramFormat: String, Codable, Sendable, CaseIterable {
    case plantuml
    case mermaid
    case nomnoml
    case svg
}
