import Foundation

/// A rendered dependency graph in PlantUML or Mermaid format.
public struct DepsScript: Sendable {
    /// The diagram text.
    public let text: String

    /// The output format.
    public let format: DiagramFormat

    /// Encode diagram text for PlantUML URL embedding (same encoding as DiagramScript).
    public func encodeText() -> String {
        DiagramText(rawValue: text).encodedValue
    }

    internal init(model: DependencyGraphModel, configuration: Configuration) {
        self.format = configuration.format
        let cycleNodes = model.detectCycles()

        switch configuration.format {
        case .plantuml:
            self.text = DepsScript.buildPlantUMLText(model: model, cycleNodes: cycleNodes)
        case .mermaid:
            self.text = DepsScript.buildMermaidText(model: model, cycleNodes: cycleNodes)
        case .nomnoml:
            self.text = DepsScript.buildNomnomlText(model: model, cycleNodes: cycleNodes)
        case .svg:
            self.text = DepsScript.buildSVGText(model: model)
        }
    }
}

// MARK: - DiagramOutputting

extension DepsScript: DiagramOutputting {}

// MARK: - PlantUML

private extension DepsScript {
    static func buildPlantUMLText(model: DependencyGraphModel, cycleNodes: Set<String>) -> String {
        var lines: [String] = ["@startuml"]

        // Emit one edge per line
        for edge in model.edges {
            lines.append("\(edge.from) --> \(edge.to) : \(edge.kind.rawValue)")
        }

        // Annotate cycle nodes with a note block
        if !cycleNodes.isEmpty {
            let sorted = cycleNodes.sorted()
            lines.append("")
            lines.append("note as CyclicDependencies")
            lines.append("  Cyclic nodes: \(sorted.joined(separator: ", "))")
            lines.append("end note")
        }

        lines.append("@enduml")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Mermaid

private extension DepsScript {
    static func buildMermaidText(model: DependencyGraphModel, cycleNodes: Set<String>) -> String {
        var lines: [String] = ["graph TD"]

        // Collect unique node names for declarations
        var seenNodes = Set<String>()
        for edge in model.edges {
            seenNodes.insert(edge.from)
            seenNodes.insert(edge.to)
        }

        // Declare nodes with quoted labels
        for node in seenNodes.sorted() {
            let safeId = mermaidId(node)
            lines.append("    \(safeId)[\"\(node)\"]")
        }

        if !seenNodes.isEmpty {
            lines.append("")
        }

        // Emit edge lines
        for edge in model.edges {
            let fromId = mermaidId(edge.from)
            let toId = mermaidId(edge.to)
            lines.append("    \(fromId) --> \(toId)")
        }

        // Annotate cycle nodes with red fill
        if !cycleNodes.isEmpty {
            lines.append("")
            for node in cycleNodes.sorted() {
                let safeId = mermaidId(node)
                lines.append("    style \(safeId) fill:#ffcccc,stroke:#cc0000")
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Convert a type/module name to a Mermaid-safe identifier (no spaces, generics, etc.).
    static func mermaidId(_ name: String) -> String {
        name
            .replacingOccurrences(of: "<", with: "_")
            .replacingOccurrences(of: ">", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}

// MARK: - SVG

private extension DepsScript {
    static func buildSVGText(model: DependencyGraphModel) -> String {
        let graph = LayoutGraphBuilder.buildDependencyGraph(from: model)
        let positioned = DagreLayoutEngine.layout(graph)
        return SVGRenderer.render(positioned)
    }
}

// MARK: - Nomnoml

private extension DepsScript {
    static func buildNomnomlText(model: DependencyGraphModel, cycleNodes: Set<String>) -> String {
        var lines: [String] = [
            "#direction: down",
            "#fontSize: 12",
            "#spacing: 60",
            "#edges: rounded"
        ]

        // Emit edges: [From] arrow [To]
        for edge in model.edges {
            let arrow: String
            switch edge.kind {
            case .inherits:
                arrow = "-:>"
            case .conforms:
                arrow = "--:>"
            case .imports:
                arrow = "-->"
            }
            let safeTo = nomnomlEscape(edge.to)
            let safeFrom = nomnomlEscape(edge.from)
            lines.append("[\(safeFrom)] \(arrow) [\(safeTo)]")
        }

        // Annotate cycle nodes
        if !cycleNodes.isEmpty {
            let sorted = cycleNodes.sorted()
            lines.append("")
            lines.append("// Cyclic nodes: \(sorted.joined(separator: ", "))")
            // nomnoml supports custom styles for highlighting
            for node in sorted {
                let safeName = nomnomlEscape(node)
                lines.append("#.warning: fill=#ffcccc stroke=#cc0000")
                lines.append("[<warning> \(safeName)]")
            }
        }

        return lines.joined(separator: "\n")
    }

    static func nomnomlEscape(_ name: String) -> String {
        name
            .replacingOccurrences(of: "[", with: "(")
            .replacingOccurrences(of: "]", with: ")")
            .replacingOccurrences(of: "|", with: "/")
            .replacingOccurrences(of: ";", with: ",")
    }
}
