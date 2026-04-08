import Foundation

/// Handles user authentication and session management.
public actor AuthService {
    private let userStore: UserStore
    private var activeSessions: [String: Date] = [:]

    public init(userStore: UserStore) {
        self.userStore = userStore
    }

    public func login(email: String, password: String) async throws -> User {
        let user = try await userStore.findByEmail(email)
        try user.validate()
        activeSessions[user.identifier] = Date()
        return user
    }

    public func logout(userIdentifier: String) {
        activeSessions.removeValue(forKey: userIdentifier)
    }

    public func isAuthenticated(userIdentifier: String) -> Bool {
        activeSessions[userIdentifier] != nil
    }
}
