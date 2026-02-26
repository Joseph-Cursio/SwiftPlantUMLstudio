import Foundation

/// Options which relationships to show and how to style them in a class diagram
public struct RelationshipOptions: Codable {
    public init(inheritance: Relationship? = Relationship(label: "inherits"), realize: Relationship? = Relationship(label: "conforms to"), dependency: Relationship? = Relationship(label: "ext")) {
        self.inheritance = inheritance
        self.realize = realize
        self.dependency = dependency
    }

    public var inheritance: Relationship? = Relationship(label: "inherits")
    public var realize: Relationship? = Relationship(label: "conforms to")
    public var dependency: Relationship? = Relationship(label: "ext")
}

/// Relationship metadata on if/how to visualize them in a class diagram
public struct Relationship: Codable {
    public init(label: String? = nil, style: RelationshipStyle? = nil, exclude: [String]? = nil) {
        self.label = label
        self.style = style
        self.exclude = exclude
    }

    public var label: String?
    public var style: RelationshipStyle?
    public var exclude: [String]?
}
