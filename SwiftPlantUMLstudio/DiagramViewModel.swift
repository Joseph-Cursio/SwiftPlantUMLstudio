//
//  DiagramViewModel.swift
//  SwiftPlantUMLstudio
//
//  Created by joe cursio on 2/27/26.
//

import Observation
import SwiftUMLBridgeFramework

enum DiagramMode: String, CaseIterable, Identifiable {
    case classDiagram = "Class Diagram"
    case sequenceDiagram = "Sequence Diagram"
    var id: String { rawValue }
}

@Observable @MainActor
final class DiagramViewModel {
    var selectedPaths: [String] = []
    var script: DiagramScript?
    var sequenceScript: SequenceScript?
    var isGenerating: Bool = false
    var errorMessage: String?
    var diagramFormat: DiagramFormat = .plantuml
    var diagramMode: DiagramMode = .classDiagram
    var entryPoint: String = ""
    var sequenceDepth: Int = 3

    var currentScript: (any DiagramOutputting)? {
        switch diagramMode {
        case .classDiagram: return script
        case .sequenceDiagram: return sequenceScript
        }
    }

    func generate() {
        switch diagramMode {
        case .classDiagram:
            generateClassDiagram()
        case .sequenceDiagram:
            generateSequenceDiagram()
        }
    }

    private func generateClassDiagram() {
        guard !selectedPaths.isEmpty else { return }
        isGenerating = true
        errorMessage = nil
        script = nil

        let paths = selectedPaths
        let format = diagramFormat
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                var config = Configuration.default
                config.format = format
                return ClassDiagramGenerator().generateScript(for: paths, with: config)
            }.value
            script = result
            isGenerating = false
        }
    }

    private func generateSequenceDiagram() {
        guard !selectedPaths.isEmpty, !entryPoint.isEmpty else { return }
        let parts = entryPoint.split(separator: ".").map(String.init)
        guard parts.count == 2 else { return }
        let entryType = parts[0]
        let entryMethod = parts[1]

        isGenerating = true
        errorMessage = nil
        sequenceScript = nil

        let paths = selectedPaths
        let format = diagramFormat
        let depth = sequenceDepth
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                var config = Configuration.default
                config.format = format
                return SequenceDiagramGenerator().generateScript(
                    for: paths,
                    entryType: entryType,
                    entryMethod: entryMethod,
                    depth: depth,
                    with: config
                )
            }.value
            sequenceScript = result
            isGenerating = false
        }
    }
}
