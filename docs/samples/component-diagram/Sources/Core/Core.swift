import Foundation

public struct CoreIdentifier: Hashable, Sendable {
    public let value: String

    public init(value: String) {
        self.value = value
    }
}

public protocol CoreLogger: Sendable {
    func info(_ message: String)
}
