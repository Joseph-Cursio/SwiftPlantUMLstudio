import Foundation

/// Builds a `LayoutGraph` from parsed `SyntaxStructure` items for class diagrams,
/// or from a `DependencyGraphModel` for dependency graphs.
struct LayoutGraphBuilder {

    // MARK: - Class Diagram

    /// Build a layout graph from parsed syntax structures (class diagram).
    static func buildClassDiagram(
        from items: [SyntaxStructure],
        configuration: Configuration
    ) -> LayoutGraph {
        var adjustedItems = items

        if configuration.elements.showNestedTypes {
            adjustedItems = adjustedItems.populateNestedTypes()
        }

        adjustedItems = adjustedItems.orderedByProtocolsFirstExtensionsLast()

        if configuration.shallExtensionsBeMerged {
            let indicator = configuration.elements.mergedExtensionMemberIndicator
            adjustedItems = adjustedItems.mergeExtensions(mergedMemberIndicator: indicator)
        }

        let processableKinds: [ElementKind] = [.class, .struct, .extension, .enum, .protocol, .actor, .macro]
        var nodes: [LayoutNode] = []
        var edges: [LayoutEdge] = []
        var nameToId: [String: String] = [:]

        for item in adjustedItems {
            guard let kind = item.kind, processableKinds.contains(kind) else { continue }
            guard let itemName = item.fullName ?? item.name else { continue }

            let stereotype = stereotypeName(for: kind)
            let (properties, methods) = extractMembers(from: item, configuration: configuration)

            var compartments: [NodeCompartment] = []
            if !properties.isEmpty {
                compartments.append(NodeCompartment(title: nil, items: properties))
            }
            if !methods.isEmpty {
                compartments.append(NodeCompartment(title: nil, items: methods))
            }

            let nodeId = uniqueId(for: itemName, existing: &nameToId)
            let node = LayoutNode(
                id: nodeId,
                label: item.displayName ?? itemName,
                stereotype: stereotype,
                compartments: compartments
            )
            nodes.append(node)
            nameToId[itemName] = nodeId

            // Extract edges from inherited types
            if let inheritedTypes = item.inheritedTypes {
                for parent in inheritedTypes {
                    guard let parentName = parent.name?.removeAngleBracketsWithContent() else { continue }
                    let edgeStyle = edgeStyleForInheritance(
                        parentName: parentName,
                        itemKind: kind,
                        existingNames: nameToId
                    )
                    edges.append(LayoutEdge(
                        sourceId: nodeId,
                        targetId: parentName,
                        style: edgeStyle
                    ))
                }
            }

            // Nested type connection
            if let parent = item.parent, let parentName = parent.fullName ?? parent.name {
                if let parentId = nameToId[parentName] {
                    edges.append(LayoutEdge(
                        sourceId: parentId,
                        targetId: nodeId,
                        style: .composition
                    ))
                }
            }
        }

        // Resolve edge target IDs (some targets reference types by name)
        for idx in edges.indices {
            let targetId = edges[idx].targetId
            if let resolved = nameToId[targetId] {
                edges[idx] = LayoutEdge(
                    sourceId: edges[idx].sourceId,
                    targetId: resolved,
                    label: edges[idx].label,
                    style: edges[idx].style
                )
            }
        }

        // Remove edges referencing nodes that don't exist in the graph
        let nodeIds = Set(nodes.map(\.id))
        edges = edges.filter { nodeIds.contains($0.sourceId) && nodeIds.contains($0.targetId) }

        return LayoutGraph(nodes: nodes, edges: edges)
    }

    // MARK: - Dependency Graph

    /// Build a layout graph from a dependency graph model.
    static func buildDependencyGraph(from model: DependencyGraphModel) -> LayoutGraph {
        var nodeNames = Set<String>()
        for edge in model.edges {
            nodeNames.insert(edge.from)
            nodeNames.insert(edge.to)
        }

        let cycleNodes = model.detectCycles()
        let nodes = nodeNames.sorted().map { name in
            LayoutNode(
                id: name,
                label: name,
                stereotype: cycleNodes.contains(name) ? "warning" : nil
            )
        }

        let edges = model.edges.map { edge in
            let style: EdgeStyle
            switch edge.kind {
            case .inherits: style = .inheritance
            case .conforms: style = .realization
            case .imports: style = .dependency
            }
            return LayoutEdge(sourceId: edge.from, targetId: edge.to, style: style)
        }

        return LayoutGraph(nodes: nodes, edges: edges)
    }

    // MARK: - Helpers

    private static func stereotypeName(for kind: ElementKind) -> String {
        switch kind {
        case .class: return "class"
        case .struct: return "struct"
        case .enum: return "enum"
        case .protocol: return "protocol"
        case .actor: return "actor"
        case .extension: return "extension"
        case .macro: return "macro"
        default: return "class"
        }
    }

    private static func edgeStyleForInheritance(
        parentName: String,
        itemKind: ElementKind,
        existingNames: [String: String]
    ) -> EdgeStyle {
        // If the parent is a known protocol, use realization style
        // Otherwise default to inheritance
        if itemKind == .extension {
            return .dependency
        }
        return .inheritance
    }

    private static func uniqueId(for name: String, existing: inout [String: String]) -> String {
        if existing[name] == nil {
            return name
        }
        var counter = 1
        var candidate = "\(name)_\(counter)"
        while existing.values.contains(candidate) {
            counter += 1
            candidate = "\(name)_\(counter)"
        }
        return candidate
    }

    private static func extractMembers(
        from item: SyntaxStructure,
        configuration: Configuration
    ) -> (properties: [String], methods: [String]) {
        var properties: [String] = []
        var methods: [String] = []
        guard let substructure = item.substructure, !substructure.isEmpty else {
            return (properties, methods)
        }

        let showAccess = configuration.elements.showMemberAccessLevelAttribute
        let accessLevels: [ElementAccessibility] = configuration.elements
            .showMembersWithAccessLevel.compactMap { ElementAccessibility(orig: $0) }

        for sub in substructure {
            let actualElement: SyntaxStructure
            if sub.kind == .enumcase {
                guard let first = sub.substructure?.first else { continue }
                actualElement = first
            } else {
                actualElement = sub
            }

            // Filter by access level (skip for extensions)
            if item.kind != .extension {
                let effective = actualElement.accessibility ?? .internal
                if !accessLevels.contains(effective) { continue }
            }

            let prefix = showAccess ? accessPrefix(for: actualElement) : ""

            guard let kind = actualElement.kind, let memberName = actualElement.name else { continue }
            switch kind {
            case .functionMethodInstance:
                methods.append("\(prefix)\(memberName)()")
            case .functionMethodStatic:
                methods.append("\(prefix)static \(memberName)()")
            case .varInstance:
                if let typename = actualElement.typename {
                    properties.append("\(prefix)\(memberName): \(typename)")
                } else {
                    properties.append("\(prefix)\(memberName)")
                }
            case .varStatic:
                if let typename = actualElement.typename {
                    properties.append("\(prefix)static \(memberName): \(typename)")
                } else {
                    properties.append("\(prefix)static \(memberName)")
                }
            case .enumelement:
                properties.append(memberName)
            default:
                continue
            }
        }

        return (properties, methods)
    }

    private static func accessPrefix(for element: SyntaxStructure) -> String {
        guard let accessibility = element.accessibility else { return "~ " }
        switch accessibility {
        case .open, .public:
            return "+ "
        case .internal, .package, .other:
            return "~ "
        case .private, .fileprivate:
            return "- "
        }
    }
}
