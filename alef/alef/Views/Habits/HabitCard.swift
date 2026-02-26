//
//  HabitCard.swift
//  alef
//
//  A single habit row in the daily checklist.
//
//  Three display modes based on goal type:
//  - boolean: checkmark circle that fills on tap with scale animation
//  - numeric: progress bar with value counter and +/- stepper
//  - timer: elapsed time display with play button
//
//  Streak badge shows in the top-right when streak > 0.
//  Card background tints with the habit's accent colour on completion.
//
//  Inspired by Grit: per-habit streaks, coloured icons, satisfying
//  tap feedback with spring animations.
//

import SwiftUI

struct HabitCard: View {
    let habit: TodayHabit
    let onToggle: () -> Void
    let onIncrement: (Int) -> Void

    /// Tracks tap animation state for the bounce effect
    @State private var justCompleted = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // ── Icon with coloured background ────────────────
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(habit.swiftUIColor.opacity(habit.completed ? 0.2 : 0.1))
                        .frame(width: 44, height: 44)

                    if let iconName = habit.icon, !iconName.isEmpty {
                        Image(systemName: iconName)
                            .font(.system(size: 20))
                            .foregroundColor(habit.completed ? habit.swiftUIColor : habit.swiftUIColor.opacity(0.6))
                    } else {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(habit.swiftUIColor.opacity(0.6))
                    }
                }

                // ── Content ──────────────────────────────────────
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(AlefFont.semibold(16))
                        .foregroundColor(.alefText)

                    // Subtitle based on goal type
                    subtitle
                }

                Spacer()

                // ── Right side ───────────────────────────────────
                rightContent
            }

            // ── Progress bar (numeric habits) ────────────────────
            if habit.goalType == .numeric, let goal = habit.goalValue, goal > 0 {
                let current = habit.todayEntry?.value ?? 0
                let progress = min(Double(current) / Double(goal), 1.0)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.alefSurfaceSecondary.opacity(0.3))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(habit.swiftUIColor)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.spring(response: 0.4), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.top, 10)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .fill(habit.completed
                    ? habit.swiftUIColor.opacity(0.06)
                    : Color.alefSurface
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .stroke(
                    habit.completed
                        ? habit.swiftUIColor.opacity(0.15)
                        : Color.alefBorder,
                    lineWidth: 1
                )
        )
        // Streak badge in top-right corner
        .overlay(alignment: .topTrailing) {
            streakBadge
        }
        .scaleEffect(justCompleted ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: justCompleted)
        .animation(.spring(response: 0.3), value: habit.completed)
    }

    // MARK: - Streak Badge

    /// Shows streak count when > 0.
    /// Flame icon + day count in the habit's accent colour.
    @ViewBuilder
    private var streakBadge: some View {
        // We don't have streak data in TodayHabit yet,
        // so we show a simple "done" indicator for now.
        // TODO: Add streak count to /habits/today response
        if habit.completed {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                Text("Done")
                    .font(AlefFont.Rounded.semibold(10))
            }
            .foregroundColor(habit.swiftUIColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(habit.swiftUIColor.opacity(0.1))
            .clipShape(Capsule())
            .offset(x: -8, y: 8)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Completion Button

    private var completionButton: some View {
        Button {
            // Trigger bounce animation
            justCompleted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                justCompleted = false
            }
            onToggle()
        } label: {
            ZStack {
                Circle()
                    .stroke(
                        habit.completed ? habit.swiftUIColor : Color.alefSurfaceSecondary,
                        lineWidth: 2.5
                    )
                    .frame(width: 28, height: 28)

                if habit.completed {
                    Circle()
                        .fill(habit.swiftUIColor)
                        .frame(width: 28, height: 28)
                        .transition(.scale)

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
            } else {
                Text(habit.frequency.label)
                    .font(AlefFont.regular(12))
                    .foregroundColor(.alefTextTertiary)
            }

        case .numeric:
            let current = habit.todayEntry?.value ?? 0
            let target = habit.goalValue ?? 1
            let unit = habit.goalUnit ?? ""
            Text("\(current)/\(target) \(unit)")
                .font(AlefFont.Rounded.medium(13))
                .foregroundColor(habit.completed ? habit.swiftUIColor : .alefTextSecondary)

        case .timer:
            let seconds = habit.todayEntry?.value ?? 0
            let target = habit.goalValue ?? 60
            Text("\(formatTime(seconds)) / \(formatTime(target))")
                .font(AlefFont.Rounded.medium(13))
                .foregroundColor(habit.completed ? habit.swiftUIColor : .alefTextSecondary)
        }
    }

    // MARK: - Right Content

    @ViewBuilder
    private var rightContent: some View {
        switch habit.goalType {
        case .boolean:
            completionButton

        case .numeric:
            // Stepper buttons
            HStack(spacing: 8) {
                stepperButton(systemName: "minus", step: -(habit.goalValue ?? 1) / 10)
                stepperButton(systemName: "plus", step: (habit.goalValue ?? 1) / 10)
            }

        case .timer:
            // Play button
            Button(action: onToggle) {
                Image(systemName: habit.completed ? "checkmark.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(habit.swiftUIColor)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stepper Button

    private func stepperButton(systemName: String, step: Int) -> some View {
        Button {
            let actualStep = max(abs(step), 1) * (step < 0 ? -1 : 1)
            onIncrement(actualStep)
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

    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        if mins < 60 { return "\(mins)m" }
        return "\(mins / 60)h \(mins % 60)m"
    }
}
