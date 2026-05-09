import Foundation

/// A rendered Component diagram. PlantUML is the only supported output for
/// v1; Mermaid lacks a dedicated component-diagram dialect, and the existing
/// `flowchart` workaround would just duplicate `deps --modules`.
public struct ComponentScript: Sendable {
    public let text: String
    public let format: DiagramFormat

    public static let empty = ComponentScript(text: "", format: .plantuml)

    public init(model: ComponentModel, configuration: Configuration = .default) {
        self.format = configuration.format == .mermaid ? .mermaid : .plantuml
        switch self.format {
        case .mermaid:
            self.text = ComponentScript.buildMermaidText(model: model)
        default:
            self.text = ComponentScript.buildPlantUMLText(model: model)
        }
    }

    private init(text: String, format: DiagramFormat) {
        self.text = text
        self.format = format
    }

    public func encodeText() -> String {
        DiagramText(rawValue: text).encodedValue
    }
}

extension ComponentScript: DiagramOutputting {}

// MARK: - PlantUML

private extension ComponentScript {
    static func buildPlantUMLText(model: ComponentModel) -> String {
        var lines: [String] = ["@startuml"]
        for component in model.components {
            let stereotype = stereotypeText(for: component.kind)
            lines.append("component \"\(component.name)\" as \(safeAlias(component.name)) \(stereotype) {")
            for interfaceName in component.providedInterfaces {
                lines.append("  [\(interfaceName)]")
            }
            lines.append("}")
        }
        for dependency in model.dependencies {
            lines.append("\(safeAlias(dependency.from)) ..> \(safeAlias(dependency.to))")
        }
        lines.append("@enduml")
        return lines.joined(separator: "\n")
    }

    static func stereotypeText(for kind: Component.Kind) -> String {
        switch kind {
        case .executable: return "<<executable>>"
        case .library:    return "<<library>>"
        case .test:       return "<<test>>"
        case .other:      return ""
        }
    }
}

// MARK: - Mermaid (flowchart fallback — Mermaid has no component dialect)

private extension ComponentScript {
    static func buildMermaidText(model: ComponentModel) -> String {
        var lines: [String] = ["flowchart TD"]
        for component in model.components {
            let alias = safeAlias(component.name)
            // Use Mermaid's subgraph for the component box; one line per
            // provided interface inside.
            lines.append("    subgraph \(alias)[\"\(component.name)\"]")
            for interfaceName in component.providedInterfaces {
                lines.append("        \(safeAlias("\(component.name)_\(interfaceName)"))[\"\(interfaceName)\"]")
            }
            lines.append("    end")
        }
        for dependency in model.dependencies {
            lines.append("    \(safeAlias(dependency.from)) -.-> \(safeAlias(dependency.to))")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Helpers

private extension ComponentScript {
    /// Convert a target name into a valid PlantUML / Mermaid identifier.
    static func safeAlias(_ name: String) -> String {
        name.replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "+", with: "_")
    }
}
