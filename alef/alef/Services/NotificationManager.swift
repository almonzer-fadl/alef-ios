//
//  NotificationManager.swift
//  alef
//
//  Local notification scheduling for habit reminders.
//
//  Handles:
//  - Daily habit reminders at user-specified times
//  - "Don't break your streak" nudges
//  - Focus timer completion alerts (when app is backgrounded)
//
//  Uses UNUserNotificationCenter for all scheduling.
//  No push notifications needed — everything is local.
//

import UserNotifications
import UIKit
import Combine

@MainActor
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    /// Request notification permission. Call on first launch or settings.
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    /// Check current authorization status without prompting.
    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Daily Reminder

    /// Schedule a daily reminder for habits at a specific time.
    /// Replaces any existing daily reminder.
    func scheduleDailyReminder(hour: Int, minute: Int) {
        // Remove old daily reminders
        center.removePendingNotificationRequests(withIdentifiers: ["alef.daily.reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to check in"
        content.body = "Your daily habits are waiting. Keep the streak alive."
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "alef.daily.reminder", content: content, trigger: trigger)

        center.add(request)
    }

    /// Cancel the daily reminder.
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["alef.daily.reminder"])
    }

    // MARK: - Streak Reminder

    /// Schedule a "don't break your streak" nudge for the evening
    /// if habits aren't completed by a certain time.
    func scheduleStreakReminder(hour: Int = 21, minute: Int = 0) {
        center.removePendingNotificationRequests(withIdentifiers: ["alef.streak.reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak"
        content.body = "You still have habits to complete today."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "alef.streak.reminder", content: content, trigger: trigger)

        center.add(request)
    }

    // MARK: - Focus Timer

    /// Schedule a notification for when the focus timer completes
    /// (in case the app is backgrounded).
    func scheduleFocusTimerEnd(in seconds: TimeInterval, habitName: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["alef.focus.timer"])

        let content = UNMutableNotificationContent()
        content.title = "Focus complete"
        content.body = "\(habitName) — session finished. Well done."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "alef.focus.timer", content: content, trigger: trigger)

        center.add(request)
    }

    /// Cancel the focus timer notification (user stopped/reset).
    func cancelFocusTimer() {
        center.removePendingNotificationRequests(withIdentifiers: ["alef.focus.timer"])
    }

    // MARK: - Badge Management

    /// Clear the app badge count.
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    /// Remove all delivered notifications.
    func clearDelivered() {
        center.removeAllDeliveredNotifications()
    }
}
