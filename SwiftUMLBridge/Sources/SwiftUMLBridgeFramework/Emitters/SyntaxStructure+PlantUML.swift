import Foundation

extension SyntaxStructure {
    /// Textual representation of this element in PlantUML scripting language
    func plantuml(context: DiagramContext) -> String? {
        guard let kind = kind else { return nil }

        guard skip(element: self, basedOn: context.configuration) == false else { return nil }

        var generics: String?
        if context.configuration.elements.showGenerics {
            generics = genericsStatement()
        }

        var textualRepresentation = ""
        switch kind {
        case ElementKind.class:
            textualRepresentation = "class \"\(displayName!)\" as \(context.uniqName(item: self, relationship: "inherits"))\(generics ?? "") \(context.configuration.stereotypes.class?.plantuml ?? Stereotype.class.plantuml) { \(members(context: context)) \n}"
        case ElementKind.struct:
            textualRepresentation = "class \"\(displayName!)\" as \(context.uniqName(item: self, relationship: "inherits"))\(generics ?? "") \(context.configuration.stereotypes.struct?.plantuml ?? Stereotype.struct.plantuml) { \(members(context: context)) \n}"
        case ElementKind.extension:
            textualRepresentation = "class \"\(displayName!)\" as \(context.uniqName(item: self, relationship: "ext"))\(generics ?? "") \(context.configuration.stereotypes.extension?.plantuml ?? Stereotype.extension.plantuml) { \(members(context: context)) \n}"
        case ElementKind.enum:
            textualRepresentation = "class \"\(displayName!)\" as \(context.uniqName(item: self, relationship: ""))\(generics ?? "") \(context.configuration.stereotypes.enum?.plantuml ?? Stereotype.enum.plantuml) { \(members(context: context)) \n}"
        case ElementKind.protocol:
            textualRepresentation = "class \"\(displayName!)\" as \(context.uniqName(item: self, relationship: "conforms to"))\(generics ?? "") \(context.configuration.stereotypes.protocol?.plantuml ?? Stereotype.protocol.plantuml) { \(members(context: context)) \n}"
        case ElementKind.actor:
            // Render Swift actors as a class node with <<actor>> stereotype
            textualRepresentation = "class \"\(displayName!)\" as \(context.uniqName(item: self, relationship: "actor"))\(generics ?? "") \(Stereotype.actor.plantuml) { \(members(context: context)) \n}"
        case ElementKind.macro:
            // Render Swift macros as a note placeholder
            textualRepresentation = "note as \(context.uniqName(item: self, relationship: "macro"))\n  <<macro>> \(displayName ?? "unknown")\nend note"
        default:
            BridgeLogger.shared.error("element kind not supported for PlantUML rendering: \(kind.rawValue)")
            return nil
        }
        addLinking(context: context)
        return textualRepresentation
    }

    private func addLinking(context: DiagramContext) {
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
            let generateMembersWithAccessLevel: [ElementAccessibility] = context.configuration.elements.showMembersWithAccessLevel.map { ElementAccessibility(orig: $0)! }
            if generateMembersWithAccessLevel.contains(actualElement.accessibility ?? ElementAccessibility.internal) == false {
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

    private func skip(element: SyntaxStructure, basedOn configuration: Configuration) -> Bool {
        guard skip(element: self, basedOn: configuration.elements.exclude) == false else { return true }

        guard let elementKind = element.kind else { return true }

        if elementKind != .extension {
            let generateElementsWithAccessLevel: [ElementAccessibility] = configuration.elements.havingAccessLevel.map { ElementAccessibility(orig: $0)! }
            guard generateElementsWithAccessLevel.contains(accessibility ?? ElementAccessibility.internal) else { return true }
        }

        if configuration.elements.showExtensions.safelyUnwrap == .none, kind == .extension {
            return true
        }

        return false
    }

    private func skip(element: SyntaxStructure, basedOn excludeElements: [String]?) -> Bool {
        guard let elementName = element.name else { return false }
        guard let excludedElements = excludeElements else { return false }
        return !excludedElements.filter { elementName.isMatching(searchPattern: $0) }.isEmpty
    }

    private func genericsStatement() -> String? {
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
