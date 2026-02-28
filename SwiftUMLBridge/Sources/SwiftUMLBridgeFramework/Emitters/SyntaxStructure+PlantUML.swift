import Foundation

extension SyntaxStructure {
    /// Textual representation of this element in PlantUML scripting language
    func plantuml(context: DiagramContext) -> String? {
        guard let kind = kind else { return nil }
        guard skip(element: self, basedOn: context.configuration) == false else { return nil }

        let generics: String? = context.configuration.elements.showGenerics ? genericsStatement() : nil
        guard let textualRepresentation = plantUMLText(for: kind, generics: generics, context: context) else {
            return nil
        }
        addLinking(context: context)
        return textualRepresentation
    }

    // Maps an ElementKind to its PlantUML textual representation.
    private func plantUMLText(
        for kind: ElementKind,
        generics: String?,
        context: DiagramContext
    ) -> String? {
        let stereotypes = context.configuration.stereotypes
        switch kind {
        case ElementKind.class:
            return plantUMLClassNode(
                relationship: "inherits",
                stereotype: stereotypes.class?.plantuml ?? Stereotype.class.plantuml,
                generics: generics, context: context
            )
        case ElementKind.struct:
            return plantUMLClassNode(
                relationship: "inherits",
                stereotype: stereotypes.struct?.plantuml ?? Stereotype.struct.plantuml,
                generics: generics, context: context
            )
        case ElementKind.extension:
            return plantUMLClassNode(
                relationship: "ext",
                stereotype: stereotypes.extension?.plantuml ?? Stereotype.extension.plantuml,
                generics: generics, context: context
            )
        case ElementKind.enum:
            return plantUMLClassNode(
                relationship: "",
                stereotype: stereotypes.enum?.plantuml ?? Stereotype.enum.plantuml,
                generics: generics, context: context
            )
        case ElementKind.protocol:
            return plantUMLClassNode(
                relationship: "conforms to",
                stereotype: stereotypes.protocol?.plantuml ?? Stereotype.protocol.plantuml,
                generics: generics, context: context
            )
        case ElementKind.actor:
            return plantUMLClassNode(
                relationship: "actor",
                stereotype: Stereotype.actor.plantuml,
                generics: generics, context: context
            )
        case ElementKind.macro:
            let macroName = context.uniqName(item: self, relationship: "macro")
            return "note as \(macroName)\n  <<macro>> \(displayName ?? "unknown")\nend note"
        default:
            BridgeLogger.shared.error("element kind not supported for PlantUML rendering: \(kind.rawValue)")
            return nil
        }
    }

    /// Build a PlantUML class-node declaration line for this element.
    private func plantUMLClassNode(
        relationship: String,
        stereotype: String,
        generics: String?,
        context: DiagramContext
    ) -> String {
        let alias = context.uniqName(item: self, relationship: relationship)
        let genericsStr = generics ?? ""
        let body = members(context: context)
        return "class \"\(displayName!)\" as \(alias)\(genericsStr) \(stereotype) { \(body) \n}"
    }

    func addLinking(context: DiagramContext) {
        if inheritedTypes != nil, inheritedTypes!.count > 0 {
            inheritedTypes!.forEach { parent in
                if parent.name?.contains("&") == true {
                    parent.name?
                        .components(separatedBy: "&")
                        .forEach {
                            let name = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                            context.addLinking(item: self, parent: SyntaxStructure(name: name))
                        }
                } else {
                    context.addLinking(item: self, parent: parent)
                }
            }
        }
    }

    private func members(context: DiagramContext) -> String {
        var members = ""

        guard let substructure = substructure, substructure.count > 0 else { return members }

        for sub in substructure {
            if let msig = member(element: sub, context: context) {
                members.appendAsNewLine(msig)
            }
        }

        return members
    }

    private func member(element: SyntaxStructure, context: DiagramContext) -> String? {
        guard
            element.kind == ElementKind.functionMethodInstance ||
            element.kind == ElementKind.functionMethodStatic ||
            element.kind == ElementKind.varInstance ||
            element.kind == ElementKind.varStatic ||
            element.kind == ElementKind.enumcase else { return nil }

        let actualElement: SyntaxStructure
        if element.kind == ElementKind.enumcase {
            guard let first = element.substructure?.first else { return nil }
            actualElement = first
        } else {
            actualElement = element
        }

        if kind! != .extension {
            let generateMembersWithAccessLevel: [ElementAccessibility] = context.configuration.elements
                .showMembersWithAccessLevel.map { ElementAccessibility(orig: $0)! }
            let effectiveAccessibility = actualElement.accessibility ?? ElementAccessibility.internal
            if generateMembersWithAccessLevel.contains(effectiveAccessibility) == false {
                return nil
            }
        }

        var msig = "  "

        msig.addOrSkipMemberAccessLevelAttribute(for: actualElement, basedOn: context.configuration)

        msig += memberName(of: actualElement)

        if let memberSuffix = actualElement.memberSuffix {
            msig += " " + memberSuffix
        }

        return msig
    }

    private func memberName(of element: SyntaxStructure) -> String {
        let kind = element.kind!
        switch kind {
        case .functionMethodInstance:
            // Detect async/throws from typename field (SourceKitten encodes these in return type)
            let typeName = element.typename ?? ""
            let asyncLabel = typeName.contains("async") ? " async" : ""
            let throwsLabel = typeName.contains("throws") ? " throws" : ""
            return "\(element.name!)\(asyncLabel)\(throwsLabel)"
        case .functionMethodStatic:
            let typeName = element.typename ?? ""
            let asyncLabel = typeName.contains("async") ? " async" : ""
            let throwsLabel = typeName.contains("throws") ? " throws" : ""
            return "{static} \(element.name!)\(asyncLabel)\(throwsLabel)"
        case .varInstance:
            if element.typename != nil {
                return "\(element.name!) : \(element.typename!)"
            } else {
                return "\(element.name!)"
            }
        case .varStatic:
            if element.typename != nil {
                return "{static} \(element.name!) : \(element.typename!)"
            } else {
                return "{static} \(element.name!)"
            }
        case .enumelement:
            return "\(element.name!)"
        default:
            return ""
        }
    }

    func skip(element: SyntaxStructure, basedOn configuration: Configuration) -> Bool {
        guard skip(element: self, basedOn: configuration.elements.exclude) == false else { return true }

        guard let elementKind = element.kind else { return true }

        if elementKind != .extension {
            let generateElementsWithAccessLevel: [ElementAccessibility] = configuration.elements
                .havingAccessLevel.map { ElementAccessibility(orig: $0)! }
            let effectiveAccessibility = accessibility ?? ElementAccessibility.internal
            guard generateElementsWithAccessLevel.contains(effectiveAccessibility) else { return true }
        }

        if configuration.elements.showExtensions.safelyUnwrap == .none, kind == .extension {
            return true
        }

        return false
    }

    func skip(element: SyntaxStructure, basedOn excludeElements: [String]?) -> Bool {
        guard let elementName = element.name else { return false }
        guard let excludedElements = excludeElements else { return false }
        return !excludedElements.filter { elementName.isMatching(searchPattern: $0) }.isEmpty
    }

    func genericsStatement() -> String? {
        guard let substructure = substructure else {
            guard let parent = inheritedTypes?.first else { return nil }
            return parent.name?.getAngleBracketsWithContent()
        }
        let params = substructure.filter { $0.kind == ElementKind.genericTypeParam }
        var genParts: [String] = []
        for param in params {
            guard let name = param.name else { continue }
            if let typeName = param.inheritedTypes?[0].name {
                genParts.append("\(name): \(typeName)")
            } else {
                genParts.append("\(name)")
            }
        }
        let genStatement = genParts.joined(separator: "\\n")
        guard genStatement.count > 0 else { return nil }
        return "<\(genStatement)>"
    }
}
