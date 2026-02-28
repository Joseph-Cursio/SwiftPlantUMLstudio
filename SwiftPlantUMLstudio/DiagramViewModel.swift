//
//  DiagramViewModel.swift
//  SwiftPlantUMLstudio
//
//  Created by joe cursio on 2/27/26.
//

import Observation
import SwiftUMLBridgeFramework

@Observable @MainActor
final class DiagramViewModel {
    var selectedPaths: [String] = []
    var script: DiagramScript?
    var isGenerating: Bool = false
    var errorMessage: String?
    var diagramFormat: DiagramFormat = .plantuml

    func generate() {
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
}
