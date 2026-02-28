import Testing
@testable import SwiftUMLBridgeFramework

@Suite("DependencyGraphModel")
struct DependencyGraphModelTests {

    // MARK: - Cycle detection: no cycles

    @Test("empty graph has no cycles")
    func emptyCycles() {
        let model = DependencyGraphModel(edges: [])
        #expect(model.detectCycles().isEmpty)
    }

    @Test("linear chain has no cycles")
    func linearChainNoCycles() {
        let edges = [
            DependencyEdge(from: "A", to: "B", kind: .conforms),
            DependencyEdge(from: "B", to: "C", kind: .conforms)
        ]
        let model = DependencyGraphModel(edges: edges)
        #expect(model.detectCycles().isEmpty)
    }

    @Test("star topology (no cycles) has no cycles")
    func starTopologyNoCycles() {
        let edges = [
            DependencyEdge(from: "Core", to: "A", kind: .imports),
            DependencyEdge(from: "Core", to: "B", kind: .imports),
            DependencyEdge(from: "Core", to: "C", kind: .imports)
        ]
        let model = DependencyGraphModel(edges: edges)
        #expect(model.detectCycles().isEmpty)
    }

    // MARK: - Cycle detection: direct cycles

    @Test("direct cycle A→B→A marks both nodes")
    func directCycleMarksBothNodes() {
        let edges = [
            DependencyEdge(from: "A", to: "B", kind: .conforms),
            DependencyEdge(from: "B", to: "A", kind: .conforms)
        ]
        let model = DependencyGraphModel(edges: edges)
        let cycles = model.detectCycles()
        #expect(cycles.contains("A"))
        #expect(cycles.contains("B"))
    }

    @Test("self-cycle marks the node")
    func selfCycleMarksNode() {
        let edges = [
            DependencyEdge(from: "Recursive", to: "Recursive", kind: .imports)
        ]
        let model = DependencyGraphModel(edges: edges)
        let cycles = model.detectCycles()
        #expect(cycles.contains("Recursive"))
    }

    // MARK: - Cycle detection: transitive cycles

    @Test("transitive cycle A→B→C→A marks all three nodes")
    func transitiveCycleMarksAllNodes() {
        let edges = [
            DependencyEdge(from: "A", to: "B", kind: .imports),
            DependencyEdge(from: "B", to: "C", kind: .imports),
            DependencyEdge(from: "C", to: "A", kind: .imports)
        ]
        let model = DependencyGraphModel(edges: edges)
        let cycles = model.detectCycles()
        #expect(cycles.contains("A"))
        #expect(cycles.contains("B"))
        #expect(cycles.contains("C"))
    }

    @Test("node not in cycle is not reported")
    func nodeNotInCycleNotReported() {
        // D → A → B → C → A (cycle: A,B,C; D feeds into cycle but is not in it)
        let edges = [
            DependencyEdge(from: "D", to: "A", kind: .imports),
            DependencyEdge(from: "A", to: "B", kind: .imports),
            DependencyEdge(from: "B", to: "C", kind: .imports),
            DependencyEdge(from: "C", to: "B", kind: .imports)
        ]
        let model = DependencyGraphModel(edges: edges)
        let cycles = model.detectCycles()
        // B and C are in a cycle; D and A feed into the cycle but are not in it
        #expect(cycles.contains("B"))
        #expect(cycles.contains("C"))
        #expect(!cycles.contains("D"))
    }

    // MARK: - edges property

    @Test("model exposes edges")
    func modelExposesEdges() {
        let edges = [
            DependencyEdge(from: "Foo", to: "Bar", kind: .inherits),
            DependencyEdge(from: "Bar", to: "Baz", kind: .conforms)
        ]
        let model = DependencyGraphModel(edges: edges)
        #expect(model.edges.count == 2)
    }
}
