import Foundation
import Yams

/// Load Configuration from file or defaults
public struct ConfigurationProvider {
    public init() {}

    public func getConfiguration(for path: String?) -> Configuration {
        guard let configPath = path else {
            return readSwiftConfig()
        }
        BridgeLogger.shared.info("search config file with custom location \(configPath)")
        let fileURL = URL(fileURLWithPath: configPath)
        if let config = decodeYml(config: fileURL) {
            BridgeLogger.shared.info("config file \(configPath) found")
            return config
        } else {
            return readSwiftConfig()
        }
    }

    func readSwiftConfig() -> Configuration {
        BridgeLogger.shared.info("search for config file in current directory with name '.swiftumlbridge.yml'")
        if let config = decodeYml(config: defaultYmlPath) {
            BridgeLogger.shared.info(".swiftumlbridge.yml file found")
            return config
        } else {
            BridgeLogger.shared.info("return default configuration")
            return defaultConfig
        }
    }

    var defaultYmlPath: URL {
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return dir.appendingPathComponent(".swiftumlbridge.yml")
    }

    func decodeYml(config: URL) -> Configuration? {
        var encodedYAML: String
        do {
            encodedYAML = try String(contentsOf: config, encoding: .utf8)
        } catch {
            BridgeLogger.shared.info("cannot find/read yaml file")
            return nil
        }
        do {
            let decoder = YAMLDecoder()
            return try decoder.decode(Configuration.self, from: encodedYAML)
        } catch {
            let decodingError = error as? DecodingError
            switch decodingError {
            case let .dataCorrupted(context):
                BridgeLogger.shared.error("invalid value for \(context.codingPath.map(\.stringValue).joined(separator: ".")) in \(config.path)")
            case let .keyNotFound(missingKey, _):
                BridgeLogger.shared.error("missing key \(missingKey.stringValue) in \(config.path)")
            default:
                BridgeLogger.shared.error("\(error.localizedDescription) in \(config.path)")
            }
            return nil
        }
    }

    var defaultConfig: Configuration {
        Configuration.default
    }
}
