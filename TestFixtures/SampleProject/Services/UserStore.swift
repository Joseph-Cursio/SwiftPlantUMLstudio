import Foundation

/// Manages persistence and retrieval of users.
public class UserStore: Persistable {
    private var users: [String: User] = [:]

    public init() {}

    public func addUser(_ user: User) {
        users[user.identifier] = user
    }

    public func findByEmail(_ email: String) async throws -> User {
        guard let user = users.values.first(where: { $0.email == email }) else {
            throw UserStoreError.notFound
        }
        return user
    }

    public func allUsers() -> [User] {
        Array(users.values)
    }

    public func save() throws {
        // Persist all users
    }

    public func delete() throws {
        users.removeAll()
    }
}

/// Errors from user storage operations.
public enum UserStoreError: Error {
    case notFound
    case duplicateEmail
    case storageFailure
}
