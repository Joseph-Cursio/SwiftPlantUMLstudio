import Foundation

actor ImageCache {
    private var cache: [String: Data] = [:]

    func store(_ data: Data, for key: String) {
        cache[key] = data
    }

    func retrieve(for key: String) -> Data? {
        cache[key]
    }
}

actor NetworkManager {
    var requestCount: Int = 0

    func fetch(url: URL) async throws -> Data {
        requestCount += 1
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
