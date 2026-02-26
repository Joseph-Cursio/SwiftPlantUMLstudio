import Foundation
import SourceKittenFramework

internal extension SyntaxStructure {
    private static func create(from file: File, sdkPath: String? = nil) -> SyntaxStructure? {
        guard let sdkPath = sdkPath else { return createStructure(from: file) }
        guard let docs = SwiftDocs(file: file, arguments: ["-j4", "-sdk", sdkPath, file.path ?? ""]) else {
            BridgeLogger.shared.warning(
                "cannot parse source code with type inference! Is Applications/Xcode.app available?"
            )
            return createStructure(from: file)
        }
        let structure = Structure(sourceKitResponse: docs.docsDictionary)
        guard let jsonData = structure.description.data(using: .utf8) else {
            BridgeLogger.shared.error("failed to encode structure description as UTF-8 data")
            return nil
        }
        do {
            return try JSONDecoder().decode(SyntaxStructure.self, from: jsonData)
        } catch {
            BridgeLogger.shared.error("failed to decode SyntaxStructure from docs JSON: \(error)")
            return nil
        }
    }

    private static func createStructure(from file: File) -> SyntaxStructure? {
        let structure: Structure
        do {
            structure = try Structure(file: file)
        } catch {
            BridgeLogger.shared.error("failed to parse structure from file: \(error)")
            return nil
        }
        guard let jsonData = structure.description.data(using: .utf8) else {
            BridgeLogger.shared.error("failed to encode structure description as UTF-8 data")
            return nil
        }
        do {
            return try JSONDecoder().decode(SyntaxStructure.self, from: jsonData)
        } catch {
            BridgeLogger.shared.error("failed to decode SyntaxStructure from JSON: \(error)")
            return nil
        }
    }

    static func create(from fileOnDisk: URL, sdkPath: String? = nil) -> SyntaxStructure? {
        let methodStart = Date()
        guard let file = File(path: fileOnDisk.path) else {
            BridgeLogger.shared.error("not able to read contents of file \(fileOnDisk)")
            return nil
        }
        let structure = create(from: file, sdkPath: sdkPath)
        let methodFinish = Date()
        let executionTime = methodFinish.timeIntervalSince(methodStart)
        let sdkLabel = (sdkPath != nil && !sdkPath!.isEmpty) ? "parsing with SDK" : ""
        BridgeLogger.shared.debug("read \(fileOnDisk) \(sdkLabel) in \(executionTime)")
        return structure
    }

    static func create(from contents: String) -> SyntaxStructure? {
        let file = File(contents: contents)
        return create(from: file)
    }
}
