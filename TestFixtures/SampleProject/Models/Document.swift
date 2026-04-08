import Foundation

/// A document that can be saved and versioned.
public struct Document: Identifiable, Persistable {
    public let identifier: String
    public var title: String
    public var content: String
    public var version: Int
    public let createdAt: Date

    public init(identifier: String, title: String, content: String) {
        self.identifier = identifier
        self.title = title
        self.content = content
        self.version = 1
        self.createdAt = Date()
    }

    public func save() throws {
        // Persist to storage
    }

    public func delete() throws {
        // Remove from storage
    }

    public mutating func updateContent(_ newContent: String) {
        content = newContent
        version += 1
    }
}

/// The status of a document in a review workflow.
public enum DocumentStatus: String {
    case draft
    case review
    case approved
    case published
    case archived
}
