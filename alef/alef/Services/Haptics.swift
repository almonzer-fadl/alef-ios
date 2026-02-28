//
//  Haptics.swift
//  alef
//
//  Centralised haptic feedback for the app.
//
//  Uses UIKit's haptic generators for consistent tactile feedback.
//  Haptics make the app feel native and responsive — a checkmark tap
//  should feel different from a button press.
//
//  Call these from any view: Haptics.success(), Haptics.tap(), etc.
//

import UIKit

enum Haptics {

    // MARK: - Impact

    /// Light tap — for toggles, selections, small interactions.
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium tap — for button presses, card taps.
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Heavy tap — for significant actions (delete, reset).
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    // MARK: - Notification

    /// Success — habit completed, timer finished, save confirmed.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning — approaching limit, undo available.
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Error — validation failed, network error.
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - Selection

    /// Selection change — for pickers, segment controls, day selector.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
