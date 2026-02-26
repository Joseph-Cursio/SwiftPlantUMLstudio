import ArgumentParser
import Foundation
import SwiftUMLBridgeFramework

struct SwiftUMLBridgeCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "swiftumlbridge",
        abstract: "Generate architectural diagrams from Swift source code",
        version: SwiftUMLBridgeFramework.Version.current.value,
        subcommands: [ClassDiagramCommand.self],
        defaultSubcommand: ClassDiagramCommand.self
    )
}
