import Foundation

final class OrderService {
    func placeOrder() async {
        guard self.validate() else { return }
        await self.charge()
        self.notify()
    }

    func validate() -> Bool {
        true
    }

    func charge() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    func notify() {
        print("Order placed.")
    }
}
