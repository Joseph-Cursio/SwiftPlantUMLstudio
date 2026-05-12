import Foundation
import Core
import Storage

public struct AppRunner {
    private let storage: StorageClient

    public init(storage: StorageClient = StorageClient()) {
        self.storage = storage
    }

    public func handle(_ identifier: CoreIdentifier) -> String? {
        self.storage.read(identifier)
    }
}
