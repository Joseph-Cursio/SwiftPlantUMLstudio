import Foundation

extension SyntaxStructure {
    /// Textual representation of this element in Mermaid classDiagram syntax
    func mermaid(context: DiagramContext) -> String? {
        guard let kind else { return nil }
        guard skip(element: self, basedOn: context.configuration) == false else { return nil }

        let generics: String? = context.configuration.elements.showGenerics ? genericsStatement() : nil
        guard let textualRepresentation = mermaidText(for: kind, generics: generics, context: context) else {
            return nil
        }
        addLinking(context: context)
        return textualRepresentation
    }

    // Maps an ElementKind to its Mermaid textual representation.
    private func mermaidText(
        for kind: ElementKind,
        generics: String?,
        context: DiagramContext
    ) -> String? {
        switch kind {
        case ElementKind.class:
            return mermaidClassNode(relationship: "inherits", stereotype: "class", generics: generics, context: context)
        case ElementKind.struct:
            return mermaidClassNode(
                relationship: "inherits", stereotype: "struct", generics: generics, context: context
            )
        case ElementKind.extension:
            return mermaidClassNode(relationship: "ext", stereotype: "extension", generics: generics, context: context)
        case ElementKind.enum:
            return mermaidClassNode(relationship: "", stereotype: "enum", generics: generics, context: context)
        case ElementKind.protocol:
            return mermaidClassNode(
                relationship: "conforms to",
                stereotype: "protocol",
                generics: generics,
                context: context
            )
        case ElementKind.actor:
            return mermaidClassNode(relationship: "actor", stereotype: "actor", generics: generics, context: context)
        case ElementKind.macro:
            let macroName = context.uniqName(item: self, relationship: "macro")
            return "%% macro: \(displayName ?? "unknown") (\(macroName))"
        default:
            BridgeLogger.shared.error("element kind not supported for Mermaid rendering: \(kind.rawValue)")
            return nil
        }
    }

    /// Build a Mermaid class-node declaration for this element.
    private func mermaidClassNode(
        relationship: String,
        stereotype: String,
        generics: String?,
        context: DiagramContext
    ) -> String {
        let alias = context.uniqName(item: self, relationship: relationship)
        let genericsStr = generics.map { " \($0)" } ?? ""
        let membersText = mermaidMembers(context: context)
        var body = "    <<\(stereotype)>>\(genericsStr)"
        if !membersText.isEmpty {
            body += membersText
        }
        return "class \(alias)[\"\(displayName ?? name ?? "unknown")\"] {\n\(body)\n}"
    }

    private func mermaidMembers(context: DiagramContext) -> String {
        var members = ""
        guard let substructure, !substructure.isEmpty else { return members }

        for sub in substructure {
            if let msig = mermaidMember(element: sub, context: context) {
                members.appendAsNewLine(msig)
            }
        }
        return members
    }

    private func mermaidMember(element: SyntaxStructure, context: DiagramContext) -> String? {
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

        if kind != .extension {
            let generateMembersWithAccessLevel: [ElementAccessibility] = context.configuration.elements
                .showMembersWithAccessLevel.compactMap { ElementAccessibility(orig: $0) }
            let effectiveAccessibility = actualElement.accessibility ?? ElementAccessibility.internal
            if generateMembersWithAccessLevel.contains(effectiveAccessibility) == false {
                return nil
            }
        }

        var msig = "    "
        msig.addOrSkipMemberAccessLevelAttribute(for: actualElement, basedOn: context.configuration)
        msig += mermaidMemberName(of: actualElement)
        return msig
    }

    private func mermaidMemberName(of element: SyntaxStructure) -> String {
        guard let kind = element.kind, let name = element.name else { return "" }
        switch kind {
        case .functionMethodInstance:
            return "\(name)()"
        case .functionMethodStatic:
            return "\(name)()$"
        case .varInstance:
            if let typename = element.typename {
                return "\(typename) \(name)"
            }
            return "\(name)"
        case .varStatic:
            if let typename = element.typename {
                return "\(typename) \(name)$"
            }
            return "\(name)$"
        case .enumelement:
            return "\(name)"
        default:
            return ""
        }
    }
}
