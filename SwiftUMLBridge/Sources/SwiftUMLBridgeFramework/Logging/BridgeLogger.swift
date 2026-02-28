import Foundation
import os.log

/// Singleton logger for SwiftUMLBridge using os.Logger
public final class BridgeLogger: Sendable {
    public static let shared: BridgeLogger = BridgeLogger()

    private let logger = Logger(subsystem: "name.JosephCursio.SwiftUMLBridge", category: "SwiftUMLBridge")

    private init() {}

    public func error(_ message: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        logger.error("\(message, privacy: .public)")
    }

    public func warning(
        _ message: String,
        _ file: String = #file,
        _ function: String = #function,
        _ line: Int = #line
    ) {
        logger.warning("\(message, privacy: .public)")
    }

    public func info(_ message: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        logger.info("\(message, privacy: .public)")
    }

    public func debug(_ message: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        logger.debug("\(message, privacy: .public)")
    }
}
