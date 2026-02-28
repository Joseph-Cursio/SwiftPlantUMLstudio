import Foundation

/// Format-agnostic context accumulated while building a diagram from SyntaxStructures
class DiagramContext {
    private(set) var configuration: Configuration
    let format: DiagramFormat

    var uniqueNameForElement: [SyntaxStructure: String] = [:]

    var uniqElementNames: [String] = []
    var uniqElementAndTypes: [String: String] = [:]
    private(set) var connections: [String] = []
    private(set) var extnConnections: [String] = []

    private let linkTypeInheritance = "<|--"
    private let linkTypeRealize = "<|.."
    private let linkTypeDependency = "<.."
    private let linkTypeGeneric = "--"

    init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.format = configuration.format
    }

    var index = 0

    func addLinking(item: SyntaxStructure, parent: SyntaxStructure) {
        var linkTo = parent.name?.removeAngleBracketsWithContent() ?? "___"

        if linkTo.starts(with: "@") {
            linkTo = "\"\(linkTo)\""
        }

        guard skipLinking(
            element: parent,
            basedOn: configuration.relationships.inheritance?.exclude
        ) == false else { return }
        guard let fullName = item.fullName else { return }
        let namedConnection = (uniqElementAndTypes[linkTo] != nil)
            ? "\(uniqElementAndTypes[linkTo] ?? "--ERROR--")"
            : "inherits"
        var linkTypeKey = fullName + "LinkType"

        if uniqElementAndTypes[linkTo] == "conforms to" {
            linkTypeKey = linkTo + "LinkType"
        }

        var connect = "\(linkTo) \(uniqElementAndTypes[linkTypeKey] ?? "--ERROR--") \(fullName)"
        if format == .plantuml, let relStyle = relationshipStyle(for: namedConnection)?.plantuml {
            connect += " \(relStyle)"
        }
        if let relationshipLabel = relationshipLabel(for: namedConnection) {
            connect += " : \(relationshipLabel)"
        }
        connections.append(connect)
    }

    private func skipLinking(element: SyntaxStructure, basedOn excludeElements: [String]?) -> Bool {
        guard let elementName = element.name else { return false }
        guard let excludedElements = excludeElements else { return false }
        return !excludedElements.filter { elementName.isMatching(searchPattern: $0) }.isEmpty
    }

    func relationshipLabel(for name: String) -> String? {
        if name == "inherits" {
            return configuration.relationships.inheritance?.label
        } else if name == "conforms to" {
            return configuration.relationships.realize?.label
        } else if name == "ext" {
            return configuration.relationships.dependency?.label
        } else {
            return nil
        }
    }

    func relationshipStyle(for name: String) -> RelationshipStyle? {
        if name == "inherits" {
            return configuration.relationships.inheritance?.style
        } else if name == "conforms to" {
            return configuration.relationships.realize?.style
        } else if name == "ext" {
            return configuration.relationships.dependency?.style
        } else {
            return nil
        }
    }

    func uniqName(item: SyntaxStructure, relationship: String) -> String {
        guard let name = item.fullName else { return "" }
        var newName = name
        let linkTypeKey = name + "LinkType"
        if uniqElementNames.contains(name) {
            newName += "\(index)"
            index += 1
            let hasMatchingParent = uniqueNameForElement.keys
                .first(where: { $0.name == name && $0.kind != .extension }) != nil
            if item.kind == ElementKind.extension, hasMatchingParent {
                var connect = "\(name) \(linkTypeDependency) \(newName)"
                if format == .plantuml, let relStyle = configuration.relationships.dependency?.style?.plantuml {
                    connect += " \(relStyle)"
                }
                connect += " : \(configuration.relationships.dependency?.label ?? relationship)"
                extnConnections.append(connect)
            }
        } else {
            uniqElementNames.append(name)
            uniqElementAndTypes[name] = relationship

            if relationship == "inherits" {
                uniqElementAndTypes[linkTypeKey] = linkTypeInheritance
            } else if relationship == "conforms to" {
                uniqElementAndTypes[linkTypeKey] = linkTypeRealize
            } else if relationship == "ext" {
                uniqElementAndTypes[linkTypeKey] = linkTypeDependency
            } else {
                uniqElementAndTypes[linkTypeKey] = linkTypeGeneric
            }
        }
        uniqueNameForElement[item] = newName
        return newName
    }

    func collectNestedTypeConnections(items: [SyntaxStructure]) {
        guard format == .plantuml else { return }
        for item in items where item.parent != nil {
            guard let name = uniqueNameForElement[item],
                  let parent = item.parent,
                  let parentName = uniqueNameForElement[parent] ?? parent.name
            else {
                continue
            }
            connections.append("\(parentName) +-- \(name)")
        }
    }
}
