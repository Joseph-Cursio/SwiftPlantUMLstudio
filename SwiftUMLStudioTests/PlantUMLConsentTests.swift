import Foundation
import Testing
@testable import SwiftUMLStudio

// `.serialized` because all tests mutate the same shared UserDefaults key —
// running in parallel produces interleaved grant/revoke races.
@Suite("PlantUMLConsent", .serialized)
struct PlantUMLConsentTests {

    @Test("revoke + hasConsented round trip")
    func defaultIsRevoked() {
        PlantUMLConsent.revoke()
        #expect(PlantUMLConsent.hasConsented == false)
    }

    @Test("grant sets hasConsented to true")
    func grantSetsTrue() {
        PlantUMLConsent.revoke()
        PlantUMLConsent.grant()
        #expect(PlantUMLConsent.hasConsented == true)
        PlantUMLConsent.revoke()
    }

    @Test("revoke after grant clears the flag")
    func revokeClears() {
        PlantUMLConsent.grant()
        PlantUMLConsent.revoke()
        #expect(PlantUMLConsent.hasConsented == false)
    }
}
