import Foundation
import JavaScriptCore

/// Computes node positions and edge routes for a `LayoutGraph` using the graphre (dagre)
/// layout engine via JavaScriptCore. No WebView or internet required.
public struct DagreLayoutEngine: Sendable {

    /// Estimated character width in the diagram font (px).
    private static let charWidth: Double = 7.5
    /// Line height for members (px).
    private static let lineHeight: Double = 18.0
    /// Vertical padding inside each compartment (px).
    private static let compartmentPadding: Double = 8.0
    /// Horizontal padding inside node boxes (px).
    private static let horizontalPadding: Double = 20.0
    /// Height of the stereotype + label header area (px).
    private static let headerHeight: Double = 36.0

    /// Lay out the graph, returning a new graph with positions set.
    public static func layout(_ graph: LayoutGraph) -> LayoutGraph {
        guard !graph.nodes.isEmpty else { return graph }

        var sized = graph
        sizeNodes(&sized)

        guard let context = JSContext() else {
            BridgeLogger.shared.debug("DagreLayoutEngine: failed to create JSContext")
            return fallbackLayout(sized)
        }

        // Load graphre.js
        guard let jsURL = Bundle.module.url(forResource: "graphre", withExtension: "js"),
              let jsSource = try? String(contentsOf: jsURL, encoding: .utf8) else {
            BridgeLogger.shared.debug("DagreLayoutEngine: graphre.js not found in bundle")
            return fallbackLayout(sized)
        }

        context.evaluateScript(jsSource)

        // Build and execute the layout script
        let layoutScript = buildLayoutScript(for: sized)
        guard let result = context.evaluateScript(layoutScript),
              !result.isUndefined else {
            BridgeLogger.shared.debug("DagreLayoutEngine: layout script returned undefined")
            return fallbackLayout(sized)
        }

        return parseResult(result, into: sized)
    }

    // MARK: - Node Sizing

    /// Estimates node dimensions based on label and compartment contents.
    private static func sizeNodes(_ graph: inout LayoutGraph) {
        for idx in graph.nodes.indices {
            let node = graph.nodes[idx]
            let labelWidth = Double(node.label.count) * charWidth + horizontalPadding
            var maxWidth = labelWidth
            var totalHeight = headerHeight

            for compartment in node.compartments where !compartment.items.isEmpty {
                totalHeight += compartmentPadding
                for item in compartment.items {
                    let itemWidth = Double(item.count) * charWidth + horizontalPadding
                    maxWidth = max(maxWidth, itemWidth)
                    totalHeight += lineHeight
                }
                totalHeight += compartmentPadding
            }

            graph.nodes[idx].width = max(maxWidth, 100)
            graph.nodes[idx].height = max(totalHeight, 50)
        }
    }

    // MARK: - JavaScript Generation

    /// Builds a JS script that creates a dagre graph, runs layout, and returns JSON results.
    private static func buildLayoutScript(for graph: LayoutGraph) -> String {
        var script = """
        (function() {
            var Graph = graphre.graphlib.Graph;
            var layout = graphre.layout;

            var graph = new Graph({ directed: true, compound: false, multigraph: false });
            graph.setGraph({ rankdir: "TB", nodesep: 60, ranksep: 60, marginx: 20, marginy: 20 });
            graph.setDefaultEdgeLabel(function() { return {}; });

        """

        // Add nodes
        for node in graph.nodes {
            let escapedId = node.id.replacingOccurrences(of: "\"", with: "\\\"")
            script += "    graph.setNode(\"\(escapedId)\", { width: \(node.width), height: \(node.height) });\n"
        }

        // Add edges
        for (idx, edge) in graph.edges.enumerated() {
            let escapedSrc = edge.sourceId.replacingOccurrences(of: "\"", with: "\\\"")
            let escapedTgt = edge.targetId.replacingOccurrences(of: "\"", with: "\\\"")
            script += "    graph.setEdge(\"\(escapedSrc)\", \"\(escapedTgt)\", { id: \"e\(idx)\" });\n"
        }

        script += """

            layout(graph);

            var nodes = {};
            graph.nodes().forEach(function(v) {
                var n = graph.node(v);
                if (n) nodes[v] = { x: n.x, y: n.y, width: n.width, height: n.height };
            });

            var edges = [];
            graph.edges().forEach(function(e) {
                var edge = graph.edge(e);
                if (edge && edge.points) {
                    edges.push({
                        source: e.v,
                        target: e.w,
                        points: edge.points.map(function(p) { return { x: p.x, y: p.y }; })
                    });
                }
            });

            var graphInfo = graph.graph();
            return JSON.stringify({
                nodes: nodes,
                edges: edges,
                width: graphInfo.width || 800,
                height: graphInfo.height || 600
            });
        })();
        """

        return script
    }

    // MARK: - Result Parsing

    /// Parses the JSON result from dagre back into the LayoutGraph.
    private static func parseResult(_ jsValue: JSValue, into graph: LayoutGraph) -> LayoutGraph {
        guard let jsonString = jsValue.toString(),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return fallbackLayout(graph)
        }

        var result = graph

        // Parse graph dimensions
        result.width = (json["width"] as? Double) ?? 800
        result.height = (json["height"] as? Double) ?? 600

        // Parse node positions
        if let nodesDict = json["nodes"] as? [String: [String: Double]] {
            for idx in result.nodes.indices {
                let nodeId = result.nodes[idx].id
                if let pos = nodesDict[nodeId] {
                    result.nodes[idx].posX = pos["x"] ?? 0
                    result.nodes[idx].posY = pos["y"] ?? 0
                    result.nodes[idx].width = pos["width"] ?? result.nodes[idx].width
                    result.nodes[idx].height = pos["height"] ?? result.nodes[idx].height
                }
            }
        }

        // Parse edge points
        if let edgesArray = json["edges"] as? [[String: Any]] {
            for edgeInfo in edgesArray {
                guard let source = edgeInfo["source"] as? String,
                      let target = edgeInfo["target"] as? String,
                      let points = edgeInfo["points"] as? [[String: Double]] else { continue }

                let layoutPoints = points.compactMap { point -> LayoutPoint? in
                    guard let posX = point["x"], let posY = point["y"] else { return nil }
                    return LayoutPoint(posX: posX, posY: posY)
                }

                // Find matching edge and set points
                for idx in result.edges.indices {
                    if result.edges[idx].sourceId == source && result.edges[idx].targetId == target
                        && result.edges[idx].points.isEmpty {
                        result.edges[idx].points = layoutPoints
                        break
                    }
                }
            }
        }

        return result
    }

    // MARK: - Fallback

    /// Simple grid layout when JavaScriptCore fails.
    private static func fallbackLayout(_ graph: LayoutGraph) -> LayoutGraph {
        var result = graph
        let columns = max(Int(ceil(sqrt(Double(graph.nodes.count)))), 1)
        let spacingX: Double = 250
        let spacingY: Double = 200

        for idx in result.nodes.indices {
            let col = idx % columns
            let row = idx / columns
            result.nodes[idx].posX = Double(col) * spacingX + spacingX / 2
            result.nodes[idx].posY = Double(row) * spacingY + spacingY / 2
        }

        result.width = Double(columns) * spacingX
        result.height = Double((graph.nodes.count + columns - 1) / columns) * spacingY
        return result
    }
}
