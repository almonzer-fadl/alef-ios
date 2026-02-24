//
//  HabitCard.swift
//  alef
//
//  A single habit row in the daily checklist.
//
//  Three display modes based on goal type:
//  - boolean: checkmark circle that fills on tap
//  - numeric: value counter with +/- stepper buttons
//  - timer: elapsed time display (tapping opens timer)
//
//  The card background tints with the habit's accent colour
//  when completed, giving satisfying visual feedback.
//

import SwiftUI

struct HabitCard: View {
    let habit: TodayHabit
    let onToggle: () -> Void
    let onIncrement: (Int) -> Void

    var body: some View {
        HStack(spacing: 14) {
            // ── Completion indicator ─────────────────────────────
            completionButton

            // ── Content ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(AlefFont.semibold(16))
                    .foregroundColor(.alefText)
                    .strikethrough(habit.completed, color: .alefTextTertiary)

                // Subtitle based on goal type
                subtitle
            }

            Spacer()

            // ── Right side (progress or stepper) ─────────────────
            rightContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .fill(habit.completed
                    ? habit.swiftUIColor.opacity(0.08)
                    : Color.alefSurface
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .stroke(
                    habit.completed
                        ? habit.swiftUIColor.opacity(0.2)
                        : Color.alefBorder,
                    lineWidth: 1
                )
        )
        .animation(.spring(response: 0.3), value: habit.completed)
    }

    // MARK: - Completion Button

    @ViewBuilder
    private var completionButton: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .stroke(
                        habit.completed ? habit.swiftUIColor : Color.alefSurfaceSecondary,
                        lineWidth: 2
                    )
                    .frame(width: 28, height: 28)

                if habit.completed {
                    Circle()
                        .fill(habit.swiftUIColor)
                        .frame(width: 28, height: 28)

                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.alefBg)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subtitle

    @ViewBuilder
    private var subtitle: some View {
        switch habit.goalType {
        case .boolean:
            if let group = habit.groupName, !group.isEmpty {
                Text(group)
                    .font(AlefFont.regular(12))
                    .foregroundColor(.alefTextTertiary)
            }

        case .numeric:
            let current = habit.todayEntry?.value ?? 0
            let target = habit.goalValue ?? 1
            let unit = habit.goalUnit ?? ""
            Text("\(current)/\(target) \(unit)")
                .font(AlefFont.Rounded.medium(12))
                .foregroundColor(.alefTextSecondary)

        case .timer:
            let seconds = habit.todayEntry?.value ?? 0
            let target = habit.goalValue ?? 60
            Text("\(formatTime(seconds))/\(formatTime(target))")
                .font(AlefFont.Rounded.medium(12))
                .foregroundColor(.alefTextSecondary)
        }
    }

    // MARK: - Right Content

    @ViewBuilder
    private var rightContent: some View {
        switch habit.goalType {
        case .boolean:
            // Show the habit's icon if it has one
            if let iconName = habit.icon, !iconName.isEmpty {
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(habit.swiftUIColor.opacity(0.5))
            }

        case .numeric:
            // Stepper buttons for incrementing
            HStack(spacing: 8) {
                stepperButton(systemName: "minus", step: -1)
                stepperButton(systemName: "plus", step: 1)
            }

        case .timer:
            // Play button to start timer (links to detail view)
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(habit.swiftUIColor.opacity(0.6))
        }
    }

    // MARK: - Stepper Button

    private func stepperButton(systemName: String, step: Int) -> some View {
        Button {
            onIncrement(step)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.alefText)
                .frame(width: 32, height: 32)
                .background(Color.alefSurfaceSecondary.opacity(0.5))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    /// Format seconds into "Xm" or "Xh Ym" for display.
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        if mins < 60 { return "\(mins)m" }
        return "\(mins / 60)h \(mins % 60)m"
    }
}
