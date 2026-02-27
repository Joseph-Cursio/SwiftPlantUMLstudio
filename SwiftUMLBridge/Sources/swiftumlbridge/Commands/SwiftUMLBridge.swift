import ArgumentParser
import Foundation
import SwiftUMLBridgeFramework

struct SwiftUMLBridgeCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftumlbridge",
        abstract: "Generate architectural diagrams from Swift source code",
        version: SwiftUMLBridgeFramework.Version.current.value,
        subcommands: [ClassDiagramCommand.self],
        defaultSubcommand: ClassDiagramCommand.self
    )
}
