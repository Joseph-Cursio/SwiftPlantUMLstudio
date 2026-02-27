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

    func generate() {
        guard !selectedPaths.isEmpty else { return }
        isGenerating = true
        errorMessage = nil
        script = nil

        let paths = selectedPaths
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                ClassDiagramGenerator().generateScript(for: paths)
            }.value
            script = result
            isGenerating = false
        }
    }
}
