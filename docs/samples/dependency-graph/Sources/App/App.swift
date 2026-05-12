import Foundation
import Domain
import Storage

public enum App {
    public static func run() {
        let store = UserStore()
        store.save("anything")
    }
}
