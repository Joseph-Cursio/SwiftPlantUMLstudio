import Foundation
import Core

public final class StorageClient {
    public init() {}

    public func read(_ identifier: CoreIdentifier) -> String? {
        nil
    }

    public func write(_ identifier: CoreIdentifier, value: String) {
        _ = identifier
        _ = value
    }
}
