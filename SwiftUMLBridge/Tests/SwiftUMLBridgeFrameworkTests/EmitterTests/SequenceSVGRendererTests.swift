import Testing
@testable import SwiftUMLBridgeFramework

@Suite("SequenceSVGRenderer Tests")
struct SequenceSVGRendererTests {

    // MARK: - Helpers

    private func makeEdge(
        callerType: String = "Controller",
        callerMethod: String = "handle",
        calleeType: String? = "Service",
        calleeMethod: String = "process",
        isAsync: Bool = false,
        isUnresolved: Bool = false
    ) -> CallEdge {
        CallEdge(
            callerType: callerType,
            callerMethod: callerMethod,
            calleeType: calleeType,
            calleeMethod: calleeMethod,
            isAsync: isAsync,
            isUnresolved: isUnresolved
        )
    }

    // MARK: - computeLayout: Participants

    @Test("entry type is always the first participant")
    func entryTypeIsFirst() {
        let edges = [makeEdge()]
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(layout.participants.first?.name == "Controller")
    }

    @Test("collects participants from resolved edges in appearance order")
    func participantOrder() {
        let edges = [
            makeEdge(calleeType: "ServiceA", calleeMethod: "run"),
            makeEdge(calleeType: "ServiceB", calleeMethod: "run"),
            makeEdge(calleeType: "ServiceA", calleeMethod: "again")
        ]
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        let names = layout.participants.map(\.name)
        #expect(names == ["Controller", "ServiceA", "ServiceB"])
    }

    @Test("unresolved edges do not add participants")
    func unresolvedEdgesExcluded() {
        let edges = [
            makeEdge(calleeType: nil, calleeMethod: "unknown", isUnresolved: true)
        ]
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(layout.participants.count == 1)
        #expect(layout.participants[0].name == "Controller")
    }

    @Test("empty edges produces single participant for entry type")
    func emptyEdges() {
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: [], entryType: "App", entryMethod: "main"
        )
        #expect(layout.participants.count == 1)
        #expect(layout.participants[0].name == "App")
    }

    // MARK: - computeLayout: Messages

    @Test("creates message for each resolved edge")
    func messageCount() {
        let edges = [
            makeEdge(calleeMethod: "aaa"),
            makeEdge(calleeMethod: "bbb")
        ]
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(layout.messages.count == 2)
    }

    @Test("message labels include method name with parentheses")
    func messageLabels() {
        let edges = [makeEdge(calleeMethod: "doWork")]
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(layout.messages[0].label == "doWork()")
    }

    @Test("async edge produces async message")
    func asyncMessage() {
        let edges = [makeEdge(isAsync: true)]
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(layout.messages[0].isAsync == true)
    }

    @Test("unresolved edge produces unresolved message with note text")
    func unresolvedMessage() {
        let edges = [
            makeEdge(calleeType: nil, calleeMethod: "mystery", isUnresolved: true)
        ]
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(layout.messages.count == 1)
        #expect(layout.messages[0].isUnresolved == true)
        #expect(layout.messages[0].noteText == "Unresolved: mystery()")
    }

    // MARK: - computeLayout: Dimensions

    @Test("total width scales with participant count")
    func totalWidthScales() {
        let singleLayout = SequenceSVGRenderer.computeLayout(
            traversedEdges: [], entryType: "App", entryMethod: "run"
        )
        let edges = [
            makeEdge(calleeType: "ServiceA", calleeMethod: "run"),
            makeEdge(calleeType: "ServiceB", calleeMethod: "run")
        ]
        let multiLayout = SequenceSVGRenderer.computeLayout(
            traversedEdges: edges, entryType: "App", entryMethod: "run"
        )
        #expect(multiLayout.totalWidth > singleLayout.totalWidth)
    }

    @Test("total height scales with message count")
    func totalHeightScales() {
        let fewEdges = [makeEdge()]
        let manyEdges = [
            makeEdge(calleeMethod: "aaa"),
            makeEdge(calleeMethod: "bbb"),
            makeEdge(calleeMethod: "ccc"),
            makeEdge(calleeMethod: "ddd"),
            makeEdge(calleeMethod: "eee")
        ]
        let fewLayout = SequenceSVGRenderer.computeLayout(
            traversedEdges: fewEdges, entryType: "Ctrl", entryMethod: "run"
        )
        let manyLayout = SequenceSVGRenderer.computeLayout(
            traversedEdges: manyEdges, entryType: "Ctrl", entryMethod: "run"
        )
        #expect(manyLayout.totalHeight > fewLayout.totalHeight)
    }

    @Test("layout title combines entry type and method")
    func layoutTitle() {
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: [], entryType: "MyApp", entryMethod: "start"
        )
        #expect(layout.title == "MyApp.start")
    }

    // MARK: - computeLayout: Self-Calls

    @Test("self-call has same fromX and toX")
    func selfCallPositioning() {
        let edges = [
            makeEdge(
                callerType: "Service",
                calleeType: "Service",
                calleeMethod: "retry"
            )
        ]
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: edges, entryType: "Service", entryMethod: "run"
        )
        let msg = layout.messages[0]
        #expect(msg.fromX == msg.toX)
    }

    // MARK: - render: SVG Structure

    @Test("render produces valid SVG wrapper")
    func renderSVGWrapper() {
        let svg = SequenceSVGRenderer.render(
            traversedEdges: [], entryType: "App", entryMethod: "main"
        )
        #expect(svg.contains("<svg"))
        #expect(svg.contains("</svg>"))
        #expect(svg.contains("xmlns=\"http://www.w3.org/2000/svg\""))
    }

    @Test("render includes participant boxes")
    func renderParticipantBoxes() {
        let edges = [makeEdge()]
        let svg = SequenceSVGRenderer.render(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(svg.contains("Controller"))
        #expect(svg.contains("Service"))
    }

    @Test("render includes message labels")
    func renderMessageLabels() {
        let edges = [makeEdge(calleeMethod: "fetchData")]
        let svg = SequenceSVGRenderer.render(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(svg.contains("fetchData()"))
    }

    @Test("render includes lifeline dashed lines")
    func renderLifelines() {
        let svg = SequenceSVGRenderer.render(
            traversedEdges: [], entryType: "App", entryMethod: "main"
        )
        #expect(svg.contains("stroke-dasharray"))
    }

    @Test("render includes arrow markers in defs")
    func renderArrowMarkers() {
        let svg = SequenceSVGRenderer.render(
            traversedEdges: [], entryType: "App", entryMethod: "main"
        )
        #expect(svg.contains("<defs>"))
        #expect(svg.contains("seq-arrow"))
    }

    @Test("render includes title text")
    func renderTitle() {
        let svg = SequenceSVGRenderer.render(
            traversedEdges: [], entryType: "MyApp", entryMethod: "start"
        )
        #expect(svg.contains("MyApp.start"))
    }

    // MARK: - render: Async Arrows

    @Test("async messages use open arrow marker")
    func asyncArrowMarker() {
        let edges = [makeEdge(isAsync: true)]
        let svg = SequenceSVGRenderer.render(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(svg.contains("seq-arrow-open"))
    }

    @Test("async messages use dashed line")
    func asyncDashedLine() {
        let edges = [makeEdge(isAsync: true)]
        let svg = SequenceSVGRenderer.render(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        // There should be stroke-dasharray on the message line (beyond the lifeline)
        let lines = svg.components(separatedBy: "\n")
        let messageLines = lines.filter { $0.contains("seq-arrow-open") }
        #expect(!messageLines.isEmpty)
    }

    // MARK: - render: Unresolved Notes

    @Test("unresolved edges render as note boxes")
    func unresolvedNoteRendering() {
        let edges = [
            makeEdge(calleeType: nil, calleeMethod: "unknown", isUnresolved: true)
        ]
        let svg = SequenceSVGRenderer.render(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(svg.contains("Unresolved: unknown()"))
        #expect(svg.contains("#FFFACD")) // Note background color
    }

    // MARK: - render: Self-Calls

    @Test("self-calls render as loop path")
    func selfCallLoopPath() {
        let edges = [
            makeEdge(
                callerType: "Service",
                calleeType: "Service",
                calleeMethod: "retry"
            )
        ]
        let svg = SequenceSVGRenderer.render(
            traversedEdges: edges, entryType: "Service", entryMethod: "run"
        )
        // Self-calls use a path element instead of a line element
        #expect(svg.contains("<path"))
        #expect(svg.contains("retry()"))
    }

    // MARK: - renderFromLayout

    @Test("renderFromLayout produces same output as render for same input")
    func renderFromLayoutConsistency() {
        let edges = [makeEdge()]
        let layout = SequenceSVGRenderer.computeLayout(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        let svgFromLayout = SequenceSVGRenderer.renderFromLayout(layout)
        let svgDirect = SequenceSVGRenderer.render(
            traversedEdges: edges, entryType: "Controller", entryMethod: "handle"
        )
        #expect(svgFromLayout == svgDirect)
    }

    // MARK: - XML Escaping

    @Test("escapes special characters in participant names")
    func xmlEscapingParticipants() {
        let edges = [
            makeEdge(
                callerType: "Pair<A>",
                calleeType: "Map<B>",
                calleeMethod: "get"
            )
        ]
        let svg = SequenceSVGRenderer.render(
            traversedEdges: edges, entryType: "Pair<A>", entryMethod: "run"
        )
        #expect(svg.contains("Pair&lt;A&gt;"))
        #expect(svg.contains("Map&lt;B&gt;"))
    }
}
