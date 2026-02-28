//
//  ContentView.swift
//  SwiftPlantUMLstudio
//
//  Created by joe cursio on 2/26/26.
//

import AppKit
import SwiftUI
import SwiftUMLBridgeFramework
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var viewModel = DiagramViewModel()

    var body: some View {
        HSplitView {
            // Left pane — raw diagram text
            TextEditor(text: .constant(viewModel.currentScript?.text ?? ""))
                .font(.system(.body, design: .monospaced))
                .disabled(true)
                .frame(minWidth: 300)

            // Right pane — preview
            Group {
                if viewModel.isGenerating {
                    ProgressView("Generating…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.currentScript != nil {
                    DiagramWebView(script: viewModel.currentScript)
                } else if viewModel.diagramMode == .sequenceDiagram && viewModel.entryPoint.isEmpty {
                    Text("Enter an entry point (e.g. MyType.myMethod), then click Generate.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Select Swift source files or a folder, then click Generate.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Open…") {
                    openPanel()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Text(pathSummary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 300, alignment: .leading)
            }

            ToolbarItem(placement: .primaryAction) {
                Picker("Mode", selection: Bindable(viewModel).diagramMode) {
                    ForEach(DiagramMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 360)
            }

            ToolbarItem(placement: .primaryAction) {
                Picker("Format", selection: Bindable(viewModel).diagramFormat) {
                    Text("PlantUML").tag(DiagramFormat.plantuml)
                    Text("Mermaid").tag(DiagramFormat.mermaid)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }

            // Sequence-diagram-specific controls
            if viewModel.diagramMode == .sequenceDiagram {
                ToolbarItem(placement: .primaryAction) {
                    TextField("Type.method", text: Bindable(viewModel).entryPoint)
                        .frame(width: 160)
                        .textFieldStyle(.roundedBorder)
                }

                ToolbarItem(placement: .primaryAction) {
                    Stepper(
                        "Depth: \(viewModel.sequenceDepth)",
                        value: Bindable(viewModel).sequenceDepth,
                        in: 1...10
                    )
                    .frame(width: 120)
                }
            }

            // Dependency-graph-specific controls
            if viewModel.diagramMode == .dependencyGraph {
                ToolbarItem(placement: .primaryAction) {
                    Picker("Deps Mode", selection: Bindable(viewModel).depsMode) {
                        ForEach(DepsMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Generate") {
                    viewModel.generate()
                }
                .disabled(viewModel.selectedPaths.isEmpty || viewModel.isGenerating)
            }
        }
    }

    private var pathSummary: String {
        switch viewModel.selectedPaths.count {
        case 0:
            return "No source selected"
        case 1:
            return URL(fileURLWithPath: viewModel.selectedPaths[0]).lastPathComponent
        default:
            let first = URL(fileURLWithPath: viewModel.selectedPaths[0]).lastPathComponent
            return "\(first) + \(viewModel.selectedPaths.count - 1) more"
        }
    }

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.swiftSource]
        panel.canSelectHiddenExtension = true

        guard panel.runModal() == .OK else { return }
        viewModel.selectedPaths = panel.urls.map(\.path)
    }
}

#Preview {
    ContentView()
}
