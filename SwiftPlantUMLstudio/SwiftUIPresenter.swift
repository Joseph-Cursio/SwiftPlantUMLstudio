//
//  SwiftUIPresenter.swift
//  SwiftPlantUMLstudio
//
//  Created by joe cursio on 2/27/26.
//

import SwiftUMLBridgeFramework

/// Custom DiagramPresenting that captures the generated script for use in SwiftUI.
struct SwiftUIPresenter: DiagramPresenting {
    nonisolated(unsafe) var onScript: (DiagramScript) -> Void

    nonisolated func present(script: DiagramScript, completionHandler: @escaping () -> Void) {
        onScript(script)
        completionHandler()
    }
}
