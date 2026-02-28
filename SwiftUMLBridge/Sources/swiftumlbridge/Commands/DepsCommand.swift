import ArgumentParser
import Foundation
import SwiftUMLBridgeFramework

extension SwiftUMLBridgeCLI {
    struct DepsCommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "deps",
            abstract: "Generate a dependency graph from Swift source files",
            helpNames: [.short, .long]
        )

        @Argument(help: "Paths to Swift source files or directories")
        var paths: [String] = []

        @Flag(help: "Generate a module-level graph from import statements")
        var modules: Bool = false

        @Flag(help: "Generate a type-level graph from inheritance and conformance (default)")
        var types: Bool = false

        @Flag(help: "Include only public and open types")
        var publicOnly: Bool = false

        @Option(help: "Exclude types or modules matching these patterns")
        var exclude: [String] = []

        @Option(help: "Diagram format. Options: plantuml, mermaid")
        var format: DiagramFormat?

        @Option(help: ArgumentHelp(
            "Output format. Options: \(ClassDiagramOutput.allCases.map(\.rawValue).joined(separator: ", "))",
            valueName: "output"
        ))
        var output: ClassDiagramOutput?

        @Option(help: "Path to custom configuration file")
        var config: String?

        mutating func run() async throws {
            var bridgeConfig = ConfigurationProvider().getConfiguration(for: self.config)

            if let format {
                bridgeConfig.format = format
            }

            if publicOnly {
                bridgeConfig.elements = ElementOptions(
                    havingAccessLevel: [.open, .public],
                    showMembersWithAccessLevel: bridgeConfig.elements.showMembersWithAccessLevel
                )
            }

            if !exclude.isEmpty {
                bridgeConfig.elements = ElementOptions(
                    havingAccessLevel: bridgeConfig.elements.havingAccessLevel,
                    showMembersWithAccessLevel: bridgeConfig.elements.showMembersWithAccessLevel,
                    exclude: exclude
                )
            }

            // `--modules` takes precedence; `--types` is also valid; default to types
            let mode: DepsMode = modules ? .modules : .types

            let sourcePaths = paths.isEmpty ? ["."] : paths
            let script = DependencyGraphGenerator().generateScript(
                for: sourcePaths,
                mode: mode,
                with: bridgeConfig
            )

            switch output {
            case .browserImageOnly:
                await BrowserPresenter(format: .png).present(script: script)
            case .consoleOnly:
                await ConsolePresenter().present(script: script)
            default:
                await BrowserPresenter(format: .default).present(script: script)
            }
        }
    }
}
