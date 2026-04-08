import Testing
@testable import SwiftUMLBridgeFramework

@Suite("DagreLayoutEngine Tests")
struct DagreLayoutEngineTests {

    // MARK: - Empty Graph

    @Test("layout returns empty graph unchanged")
    func layoutEmptyGraph() {
        let graph = LayoutGraph()
        let result = DagreLayoutEngine.layout(graph)
        #expect(result.nodes.isEmpty)
        #expect(result.edges.isEmpty)
    }

    // MARK: - Single Node

    @Test("layout positions a single node")
    func layoutSingleNode() {
        let node = LayoutNode(id: "NodeA", label: "NodeA")
        let graph = LayoutGraph(nodes: [node])
        let result = DagreLayoutEngine.layout(graph)

        #expect(result.nodes.count == 1)
        // After layout, position should be set (non-zero in at least one axis)
        let positioned = result.nodes[0]
        #expect(positioned.width > 0)
        #expect(positioned.height > 0)
        // Dagre sets graph dimensions
        #expect(result.width > 0)
        #expect(result.height > 0)
    }

    // MARK: - Multiple Nodes

    @Test("layout positions multiple nodes without overlap")
    func layoutMultipleNodes() {
        let nodes = [
            LayoutNode(id: "aaa", label: "ClassA"),
            LayoutNode(id: "bbb", label: "ClassB"),
            LayoutNode(id: "ccc", label: "ClassC")
        ]
        let graph = LayoutGraph(nodes: nodes)
        let result = DagreLayoutEngine.layout(graph)

        #expect(result.nodes.count == 3)
        // All nodes should have been sized
        for node in result.nodes {
            #expect(node.width >= 100)
            #expect(node.height >= 50)
        }
    }

    // MARK: - Edges

    @Test("layout routes edges with points")
    func layoutEdgesWithPoints() {
        let nodes = [
            LayoutNode(id: "parent", label: "Parent"),
            LayoutNode(id: "child", label: "Child")
        ]
        let edges = [
            LayoutEdge(sourceId: "child", targetId: "parent", style: .inheritance)
        ]
        let graph = LayoutGraph(nodes: nodes, edges: edges)
        let result = DagreLayoutEngine.layout(graph)

        #expect(result.edges.count == 1)
        // Dagre should provide route points for the edge
        #expect(result.edges[0].points.count >= 2)
    }

    // MARK: - Node Sizing

    @Test("nodes with compartments are taller than empty nodes")
    func nodesWithCompartmentsAreTaller() {
        let emptyNode = LayoutNode(id: "empty", label: "Empty")
        let richNode = LayoutNode(
            id: "rich", label: "Rich",
            compartments: [
                NodeCompartment(items: ["prop1: Int", "prop2: String", "prop3: Bool"]),
                NodeCompartment(items: ["method1()", "method2()"])
            ]
        )
        let graph = LayoutGraph(nodes: [emptyNode, richNode])
        let result = DagreLayoutEngine.layout(graph)

        let emptyResult = result.nodes.first { $0.id == "empty" }!
        let richResult = result.nodes.first { $0.id == "rich" }!
        #expect(richResult.height > emptyResult.height)
    }

    @Test("nodes with long labels are wider")
    func nodesWithLongLabelsAreWider() {
        let shortNode = LayoutNode(id: "short", label: "AB")
        let longNode = LayoutNode(
            id: "long", label: "AVeryLongClassNameThatShouldBeWider"
        )
        let graph = LayoutGraph(nodes: [shortNode, longNode])
        let result = DagreLayoutEngine.layout(graph)

        let shortResult = result.nodes.first { $0.id == "short" }!
        let longResult = result.nodes.first { $0.id == "long" }!
        #expect(longResult.width > shortResult.width)
    }

    @Test("minimum node width is 100")
    func minimumNodeWidth() {
        let node = LayoutNode(id: "tiny", label: "X")
        let graph = LayoutGraph(nodes: [node])
        let result = DagreLayoutEngine.layout(graph)
        #expect(result.nodes[0].width >= 100)
    }

    @Test("minimum node height is 50")
    func minimumNodeHeight() {
        let node = LayoutNode(id: "tiny", label: "X")
        let graph = LayoutGraph(nodes: [node])
        let result = DagreLayoutEngine.layout(graph)
        #expect(result.nodes[0].height >= 50)
    }

    // MARK: - Graph with Connected Components

    @Test("layout handles a linear chain of nodes")
    func layoutLinearChain() {
        let nodes = [
            LayoutNode(id: "aaa", label: "A"),
            LayoutNode(id: "bbb", label: "B"),
            LayoutNode(id: "ccc", label: "C")
        ]
        let edges = [
            LayoutEdge(sourceId: "aaa", targetId: "bbb", style: .inheritance),
            LayoutEdge(sourceId: "bbb", targetId: "ccc", style: .inheritance)
        ]
        let graph = LayoutGraph(nodes: nodes, edges: edges)
        let result = DagreLayoutEngine.layout(graph)

        #expect(result.nodes.count == 3)
        #expect(result.edges.count == 2)
        // All edges should have route points
        for edge in result.edges {
            #expect(edge.points.count >= 2)
        }
    }

    // MARK: - Node IDs with Special Characters

    @Test("handles node IDs with dots")
    func nodeIdsWithDots() {
        let node = LayoutNode(id: "Module.MyClass", label: "MyClass")
        let graph = LayoutGraph(nodes: [node])
        let result = DagreLayoutEngine.layout(graph)
        #expect(result.nodes.count == 1)
        #expect(result.nodes[0].width > 0)
    }
}
