import Foundation

/// A directed graph of dependency edges between Swift types or modules.
public struct DependencyGraphModel: Sendable {
    /// All edges in the dependency graph.
    public let edges: [DependencyEdge]

    /// SPM target kind keyed by target name. Populated by the
    /// `forPackage:` generator path in modules mode so emitters can render
    /// `<<library>>` / `<<executable>>` / `<<test>>` stereotypes. Empty in
    /// the path-based flow.
    public let targetKinds: [String: SPMTargetDescription.Kind]

    public init(
        edges: [DependencyEdge],
        targetKinds: [String: SPMTargetDescription.Kind] = [:]
    ) {
        self.edges = edges
        self.targetKinds = targetKinds
    }

    /// DFS cycle detection. Returns names of all nodes involved in cycles.
    public func detectCycles() -> Set<String> {
        // Build adjacency list and collect all nodes
        var adj: [String: [String]] = [:]
        var nodeSet = Set<String>()
        for edge in edges {
            adj[edge.from, default: []].append(edge.to)
            nodeSet.insert(edge.from)
            nodeSet.insert(edge.to)
        }

        // 0 = unvisited, 1 = in current DFS stack, 2 = fully processed
        var color: [String: Int] = [:]
        var stackPath: [String] = []
        var cycleNodes = Set<String>()

        func dfs(_ node: String) {
            color[node] = 1
            stackPath.append(node)

            for neighbor in adj[node] ?? [] {
                let neighborColor = color[neighbor] ?? 0
                if neighborColor == 0 {
                    dfs(neighbor)
                } else if neighborColor == 1 {
                    // Back edge: neighbor is in current stack — cycle found
                    if let idx = stackPath.firstIndex(of: neighbor) {
                        for member in stackPath[idx...] {
                            cycleNodes.insert(member)
                        }
                    }
                    cycleNodes.insert(node)
                }
            }

            stackPath.removeLast()
            color[node] = 2
        }

        for node in nodeSet where (color[node] ?? 0) == 0 {
            dfs(node)
        }

        return cycleNodes
    }
}
