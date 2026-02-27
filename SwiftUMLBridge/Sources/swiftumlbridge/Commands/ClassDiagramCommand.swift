import ArgumentParser
import Foundation
import SwiftUMLBridgeFramework

extension SwiftUMLBridgeCLI {
    struct ClassDiagramCommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "classdiagram",
            abstract: "Generate PlantUML class diagram from Swift sources",
            helpNames: [.short, .long]
        )

        // swiftlint:disable:next line_length
        @Option(help: "Path to custom configuration file (otherwise searches for '.swiftumlbridge.yml' in current directory)")
        var config: String?

        @Option(help: "Paths to source files to exclude. Takes precedence over arguments.")
        var exclude = [String]()

        @Option(help: ArgumentHelp(
            "Output format. Options: \(ClassDiagramOutput.allCases.map(\.rawValue).joined(separator: ", "))",
            valueName: "format"
        ))
        var output: ClassDiagramOutput?

        @Option(help: "macOS SDK path for type inference resolution (e.g. `$(xcrun --show-sdk-path -sdk macosx)`)")
        var sdk: String?

        @Flag(help: "Decide if/how Swift extensions appear in the diagram")
        var extensionVisualization: ExtensionVisualizationFlag = .showExtensions

        @Flag(help: "Enable verbose logging")
        var verbose: Bool = false

        @Argument(help: "Paths to Swift source files or directories")
        var paths = [String]()

        mutating func run() async throws {
            var bridgeConfig = ConfigurationProvider().getConfiguration(for: self.config)

            if !exclude.isEmpty {
                bridgeConfig.files.exclude = exclude
            }

            if bridgeConfig.elements.showExtensions == nil {
                switch extensionVisualization {
                case .hideExtensions:
                    bridgeConfig.elements.showExtensions = ExtensionVisualization.none
                case .mergeExtensions:
                    bridgeConfig.elements.showExtensions = .merged
                case .showExtensions:
                    bridgeConfig.elements.showExtensions = .all
                }
            }

            BridgeLogger.shared.info("SDK: \(sdk ?? "no SDK path provided")")

            let directory = FileManager.default.currentDirectoryPath
            let files = FileCollector().getFiles(for: paths, in: directory, honoring: bridgeConfig.files)

            let generator = ClassDiagramGenerator()

            switch output {
            case .browserImageOnly:
                await generator.generate(
                    for: files.map(\.path), with: bridgeConfig,
                    presentedBy: BrowserPresenter(format: .png), sdkPath: sdk
                )
            case .consoleOnly:
                await generator.generate(
                    for: files.map(\.path), with: bridgeConfig,
                    presentedBy: ConsolePresenter(), sdkPath: sdk
                )
            default:
                await generator.generate(
                    for: files.map(\.path), with: bridgeConfig,
                    presentedBy: BrowserPresenter(format: .default), sdkPath: sdk
                )
            }
        }
    }
}

extension ClassDiagramOutput: ExpressibleByArgument {}

enum ExtensionVisualizationFlag: EnumerableFlag {
    case hideExtensions
    case mergeExtensions
    case showExtensions
}
