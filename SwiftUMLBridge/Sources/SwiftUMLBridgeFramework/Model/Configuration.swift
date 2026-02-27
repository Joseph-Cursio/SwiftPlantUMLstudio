import Foundation

/// Access Level for Swift variables and methods
public enum AccessLevel: String, Codable, Sendable {
    case open
    case `public`
    case `package`
    case `internal`
    case `private`
    case `fileprivate`
}

/// Configuration options to influence the generation and visual representation of the class diagram
public struct Configuration: Codable, Sendable {
    public init(
        files: FileOptions = FileOptions(),
        elements: ElementOptions = ElementOptions(),
        hideShowCommands: [String]? = ["hide empty members"],
        skinparamCommands: [String]? = ["skinparam shadowing false"],
        includeRemoteURL: String? = nil,
        theme: Theme? = nil,
        relationships: RelationshipOptions = RelationshipOptions(),
        stereotypes: Stereotypes = Stereotypes.default,
        texts: PageTexts? = nil
    ) {
        self.files = files
        self.elements = elements
        self.hideShowCommands = hideShowCommands
        self.skinparamCommands = skinparamCommands
        self.includeRemoteURL = includeRemoteURL
        self.theme = theme
        self.relationships = relationships
        self.stereotypes = stereotypes
        self.texts = texts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let files = try container.decodeIfPresent(FileOptions.self, forKey: .files) {
            self.files = files
        }
        if let elements = try container.decodeIfPresent(ElementOptions.self, forKey: .elements) {
            self.elements = elements
        }
        if let hideShowCommands = try container.decodeIfPresent([String].self, forKey: .hideShowCommands) {
            self.hideShowCommands = hideShowCommands
        }
        if let skinparamCommands = try container.decodeIfPresent([String].self, forKey: .skinparamCommands) {
            self.skinparamCommands = skinparamCommands
        }
        if let includeRemoteURL = try container.decodeIfPresent(String.self, forKey: .includeRemoteURL) {
            self.includeRemoteURL = includeRemoteURL
        }
        if let theme = try container.decodeIfPresent(String.self, forKey: .theme) {
            self.theme = Theme.__directive__(theme)
        }
        if let relationships = try container.decodeIfPresent(RelationshipOptions.self, forKey: .relationships) {
            self.relationships = relationships
        }
        if let stereotypes = try container.decodeIfPresent(Stereotypes.self, forKey: .stereotypes) {
            self.stereotypes = stereotypes
        }
        if let texts = try container.decodeIfPresent(PageTexts.self, forKey: .texts) {
            self.texts = texts
        }
    }

    public static let `default` = Configuration()

    public var files = FileOptions()
    public var elements = ElementOptions()
    public private(set) var hideShowCommands: [String]? = ["hide empty members"]
    public private(set) var skinparamCommands: [String]? = ["skinparam shadowing false"]
    public private(set) var includeRemoteURL: String?
    public private(set) var theme: Theme?
    public var relationships = RelationshipOptions()
    public private(set) var stereotypes = Stereotypes(
        classStereotype: Stereotype.class,
        structStereotype: Stereotype.struct,
        extensionStereotype: Stereotype.extension,
        enumStereotype: Stereotype.enum,
        protocolStereotype: Stereotype.protocol
    )
    public var texts: PageTexts?

    internal var shallExtensionsBeMerged: Bool {
        elements.showExtensions.safelyUnwrap == .merged
    }
}
