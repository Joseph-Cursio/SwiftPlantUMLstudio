//
//  ReviewReminderManagerTests.swift
//  SwiftPlantUMLstudioTests
//
//  Unit tests for ReviewReminderManager scheduling and state logic.
//

import Foundation
import Testing
@testable import SwiftPlantUMLstudio

// MARK: - GCD dispatch helpers

private func runOnMain(_ block: @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(block)
    } else {
        DispatchQueue.main.sync { MainActor.assumeIsolated(block) }
    }
}

// MARK: - ReviewReminderManager Tests

@Suite("ReviewReminderManager", .serialized)
struct ReviewReminderManagerTests {

    /// Reset UserDefaults state before each test by disabling the reminder.
    private func resetState() {
        runOnMain {
            ReviewReminderManager.intervalDays = 0
        }
    }

    @Test("isEnabled returns false when intervalDays is zero")
    func isEnabledFalseWhenZero() {
        resetState()
        runOnMain {
            ReviewReminderManager.intervalDays = 0
            #expect(ReviewReminderManager.isEnabled == false)
        }
    }

    @Test("isEnabled returns true when intervalDays is positive")
    func isEnabledTrueWhenPositive() {
        resetState()
        runOnMain {
            ReviewReminderManager.intervalDays = 7
            #expect(ReviewReminderManager.isEnabled == true)
            // Clean up
            ReviewReminderManager.intervalDays = 0
        }
    }

    @Test("intervalDays getter and setter round-trip through UserDefaults")
    func intervalDaysRoundTrip() {
        resetState()
        runOnMain {
            ReviewReminderManager.intervalDays = 14
            #expect(ReviewReminderManager.intervalDays == 14)

            ReviewReminderManager.intervalDays = 30
            #expect(ReviewReminderManager.intervalDays == 30)

            // Clean up
            ReviewReminderManager.intervalDays = 0
        }
    }

    @Test("disableReminder sets intervalDays to zero")
    func disableReminderSetsZero() {
        resetState()
        runOnMain {
            ReviewReminderManager.intervalDays = 14
            #expect(ReviewReminderManager.isEnabled == true)

            ReviewReminderManager.disableReminder()
            #expect(ReviewReminderManager.intervalDays == 0)
            #expect(ReviewReminderManager.isEnabled == false)
        }
    }

    @Test("rescheduleIfEnabled does nothing when disabled")
    func rescheduleIfEnabledNoop() {
        resetState()
        runOnMain {
            ReviewReminderManager.intervalDays = 0
            // Should not crash or throw
            ReviewReminderManager.rescheduleIfEnabled()
            #expect(ReviewReminderManager.isEnabled == false)
        }
    }

    @Test("rescheduleIfEnabled runs when enabled without crashing")
    func rescheduleIfEnabledWhenActive() {
        resetState()
        runOnMain {
            ReviewReminderManager.intervalDays = 7
            // Should not crash — notification center may deny permission in tests
            // but the method should still complete.
            ReviewReminderManager.rescheduleIfEnabled()
            #expect(ReviewReminderManager.isEnabled == true)
            // Clean up
            ReviewReminderManager.intervalDays = 0
        }
    }

    @Test("enableReminder sets intervalDays and marks as enabled")
    func enableReminderSetsInterval() {
        resetState()
        runOnMain {
            ReviewReminderManager.enableReminder(intervalDays: 21)
            #expect(ReviewReminderManager.intervalDays == 21)
            #expect(ReviewReminderManager.isEnabled == true)
            // Clean up
            ReviewReminderManager.disableReminder()
        }
    }

    @Test("enableReminder with default interval uses 14 days")
    func enableReminderDefaultInterval() {
        resetState()
        runOnMain {
            ReviewReminderManager.enableReminder()
            #expect(ReviewReminderManager.intervalDays == 14)
            // Clean up
            ReviewReminderManager.disableReminder()
        }
    }
}
