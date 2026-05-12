import Foundation
import Storage

public struct User {
    public let identifier: UUID
    public let name: String

    public init(identifier: UUID, name: String) {
        self.identifier = identifier
        self.name = name
    }
}
