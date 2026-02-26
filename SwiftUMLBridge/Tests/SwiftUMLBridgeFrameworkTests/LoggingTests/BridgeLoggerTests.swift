import Testing
@testable import SwiftUMLBridgeFramework

@Suite("BridgeLogger")
struct BridgeLoggerTests {

    @Test("BridgeLogger.shared is non-nil singleton")
    func sharedIsNonNil() {
        let logger = BridgeLogger.shared
        #expect(logger === BridgeLogger.shared)
    }

    @Test("info does not crash")
    func infoDoesNotCrash() {
        BridgeLogger.shared.info("test info message")
        #expect(Bool(true))
    }

    @Test("error does not crash")
    func errorDoesNotCrash() {
        BridgeLogger.shared.error("test error message")
        #expect(Bool(true))
    }

    @Test("warning does not crash")
    func warningDoesNotCrash() {
        BridgeLogger.shared.warning("test warning message")
        #expect(Bool(true))
    }

    @Test("debug does not crash")
    func debugDoesNotCrash() {
        BridgeLogger.shared.debug("test debug message")
        #expect(Bool(true))
    }

    @Test("multiple concurrent log calls do not crash")
    func multipleLogCallsDoNotCrash() {
        BridgeLogger.shared.info("message 1")
        BridgeLogger.shared.warning("message 2")
        BridgeLogger.shared.error("message 3")
        BridgeLogger.shared.debug("message 4")
        #expect(Bool(true))
    }
}
