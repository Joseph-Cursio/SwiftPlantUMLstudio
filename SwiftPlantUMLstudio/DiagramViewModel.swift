//
//  DiagramViewModel.swift
//  SwiftPlantUMLstudio
//
//  Created by joe cursio on 2/27/26.
//

import Foundation
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

        // ClassDiagramGenerator.generate() uses DispatchSemaphore internally and must
        // not run on the main thread. Use GCD to stay outside Swift Concurrency's actor
        // isolation model, which avoids the nonisolated-conformance warning.
        let paths = selectedPaths
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let generator = ClassDiagramGenerator()
            var captured: DiagramScript?
            let presenter = SwiftUIPresenter { captured = $0 }
            generator.generate(for: paths, with: .default, presentedBy: presenter)
            DispatchQueue.main.async {
                self?.script = captured
                self?.isGenerating = false
            }
        }
    }
}
