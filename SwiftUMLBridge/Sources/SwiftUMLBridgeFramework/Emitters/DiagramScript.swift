import Foundation

/// Swift type representing a PlantUML script (@startuml ... @enduml)
public struct DiagramScript: @unchecked Sendable {
    /// Textual representation of the script
    public private(set) var text: String = ""

    private var context: DiagramContext

    /// Default initializer
    internal init(items: [SyntaxStructure], configuration: Configuration = .default) {
        context = DiagramContext(configuration: configuration)

        let methodStart = Date()

        text = "@startuml"
        if let theme = configuration.theme {
            text.appendAsNewLine("!theme \(theme.rawValue)")
        }
        if let includeRemoteURL = configuration.includeRemoteURL {
            text.appendAsNewLine("!include \(includeRemoteURL)")
        }
        text.appendAsNewLine(defaultStyling)
        text.appendAsNewLine("set namespaceSeparator none")

        if let texts = configuration.texts?.plantuml() {
            text.appendAsNewLine(texts)
        }

        let newLine = "\n"
        var mainContent = newLine

        var adjustedItems = items

        if context.configuration.elements.showNestedTypes {
            adjustedItems = adjustedItems.populateNestedTypes()
        }

        adjustedItems = adjustedItems.orderedByProtocolsFirstExtensionsLast()

        if context.configuration.shallExtensionsBeMerged {
            let indicator = context.configuration.elements.mergedExtensionMemberIndicator
            adjustedItems = adjustedItems.mergeExtensions(mergedMemberIndicator: indicator)
        }

        for (index, element) in adjustedItems.enumerated() {
            if let text = processStructureItem(item: element, index: index) {
                mainContent.appendAsNewLine(text)
            }
        }

        context.collectNestedTypeConnections(items: adjustedItems)

        let connections = context.connections.joined(separator: newLine)
        let extnConnections = context.extnConnections.joined(separator: newLine)
        let definitions = mainContent + newLine + connections + newLine + extnConnections

        text.appendAsNewLine(definitions)
        text.appendAsNewLine("@enduml")

        BridgeLogger.shared.debug("DiagramScript created in \(Date().timeIntervalSince(methodStart)) seconds")
    }

    /// Encode diagram text for PlantUML URL embedding
    public func encodeText() -> String {
        DiagramText(rawValue: text).encodedValue
    }

    /// Default styling block
    internal var defaultStyling: String {
        let hideShowCommands: [String] = context.configuration.hideShowCommands ?? ["hide empty members"]
        let skinparamCommands: [String] = context.configuration.skinparamCommands ?? ["skinparam shadowing false"]

        if hideShowCommands.isEmpty, skinparamCommands.isEmpty {
            return ""
        } else {
            return """
            ' STYLE START
            \(hideShowCommands.joined(separator: "\n"))
            \(skinparamCommands.joined(separator: "\n"))
            ' STYLE END
            """
        }
    }

    mutating func processStructureItem(item: SyntaxStructure, index _: Int) -> String? {
        let processableKinds: [ElementKind] = [.class, .struct, .extension, .enum, .protocol, .actor, .macro]
        guard let elementKind = item.kind else { return nil }
        guard processableKinds.contains(elementKind) else { return nil }
        return item.plantuml(context: context) ?? nil
    }
}
