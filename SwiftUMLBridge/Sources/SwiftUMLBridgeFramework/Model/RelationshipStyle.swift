import Foundation

/// Inline style for a relation (linking or arrow)
public enum RelationshipInlineStyle: String, Codable {
    case bold
    case dashed
    case dotted
    case hidden
    case plain
}

/// Style information for a relation and its label
public struct RelationshipStyle: Codable {
    public private(set) var lineStyle: RelationshipInlineStyle = .plain
    public private(set) var lineColor: Color = .Black
    public private(set) var textColor: Color = .Black

    var plantuml: String {
        "#line:\(lineColor);line.\(lineStyle);text:\(textColor)"
    }
}
