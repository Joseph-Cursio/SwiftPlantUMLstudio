import Foundation

enum AttemptOutcome {
    case success
    case retry
    case fail
}

final class ImportJob {
    func run() async throws {
        for index in 0 ..< 3 {
            do {
                let outcome = try await self.attempt(index: index)
                switch outcome {
                case .success:
                    return
                case .retry:
                    continue
                case .fail:
                    throw ImportError.giveUp
                }
            } catch {
                self.log(error)
            }
        }
    }

    func attempt(index: Int) async throws -> AttemptOutcome {
        .success
    }

    func log(_ error: Error) {
        print("Import failed: \(error)")
    }
}

enum ImportError: Error {
    case giveUp
}
