import Foundation

/// Sends notifications to users.
public struct NotificationService {
    public let userStore: UserStore

    public init(userStore: UserStore) {
        self.userStore = userStore
    }

    public func notifyUser(_ user: User, message: String) {
        // Send notification
    }

    public func broadcastToAll(message: String) {
        let users = userStore.allUsers()
        for user in users {
            notifyUser(user, message: message)
        }
    }
}
