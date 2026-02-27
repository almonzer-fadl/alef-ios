//
//  FocusTimerView.swift
//  alef
//
//  Built-in focus timer for timer-type habits.
//
//  Features:
//  - Circular countdown ring with remaining time
//  - Start / pause / reset controls
//  - Ambient sound picker (rain, cafe, fire, ocean, forest, silence)
//  - Auto-logs completion when target is reached
//  - Haptic feedback on completion
//
//  Presented from the habit card's play button or detail view.
//  Inspired by Grit's focus timer with ambient sound tabs.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Ambient Sound

/// Background sounds that play during focus sessions.
/// Each maps to a system sound or will map to bundled audio files.
enum AmbientSound: String, CaseIterable, Identifiable {
    case silence = "Silence"
    case rain = "Rain"
    case cafe = "Cafe"
    case fire = "Fire"
    case ocean = "Ocean"
    case forest = "Forest"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .silence: return "speaker.slash.fill"
        case .rain:    return "cloud.rain.fill"
        case .cafe:    return "cup.and.saucer.fill"
        case .fire:    return "flame.fill"
        case .ocean:   return "water.waves"
        case .forest:  return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .silence: return .alefTextTertiary
        case .rain:    return .alefHealth
        case .cafe:    return .alefDiet
        case .fire:    return .alefFitness
        case .ocean:   return .alefSleep
        case .forest:  return .alefHabits
        }
    }
}

// MARK: - Timer State

enum TimerState {
    case idle
    case running
    case paused
}

// MARK: - Focus Timer View

struct FocusTimerView: View {
    let habitId: String
    let habitName: String
    let targetSeconds: Int
    let habitColor: Color
    let token: String

    @State private var elapsedSeconds = 0
    @State private var timerState: TimerState = .idle
    @State private var selectedSound: AmbientSound = .silence
    @State private var showCompletion = false
    @State private var timer: Timer?
    @Environment(\.dismiss) private var dismiss

    private let service = HabitService()

    /// Progress from 0.0 to 1.0
    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(Double(elapsedSeconds) / Double(targetSeconds), 1.0)
    }

    /// Remaining seconds
    private var remaining: Int {
        max(targetSeconds - elapsedSeconds, 0)
    }

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ───────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.alefTextSecondary)
                            .frame(width: 36, height: 36)
                            .background(Color.alefSurface)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(habitName)
                        .font(AlefFont.semibold(17))
                        .foregroundColor(.alefText)
                    Spacer()
                    // Balance the layout
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
                .padding(.top, 16)

                Spacer()

                // ── Timer ring ───────────────────────────────────
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.alefSurfaceSecondary.opacity(0.2), lineWidth: 10)
                        .frame(width: 240, height: 240)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            habitColor,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: progress)

                    // Time display
                    VStack(spacing: 4) {
                        Text(formatTime(remaining))
                            .font(AlefFont.Rounded.heavy(48))
                            .foregroundColor(.alefText)
                            .monospacedDigit()

                        Text(timerState == .idle ? "Ready" : timerState == .running ? "Focus" : "Paused")
                            .font(AlefFont.medium(14))
                            .foregroundColor(.alefTextSecondary)
                    }
                }

                Spacer()

                // ── Controls ─────────────────────────────────────
                HStack(spacing: 24) {
                    // Reset
                    Button {
                        resetTimer()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.alefTextSecondary)
                            .frame(width: 56, height: 56)
                            .background(Color.alefSurface)
                            .clipShape(Circle())
                    }
                    .opacity(timerState == .idle ? 0.3 : 1)
                    .disabled(timerState == .idle)

                    // Play / Pause
                    Button {
                        toggleTimer()
                    } label: {
                        Image(systemName: timerState == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.alefBg)
                            .frame(width: 72, height: 72)
                            .background(habitColor)
                            .clipShape(Circle())
                            .shadow(color: habitColor.opacity(0.3), radius: 8, y: 4)
                    }

                    // +5 minutes
                    Button {
                        elapsedSeconds = max(elapsedSeconds - 300, 0) // effectively adds 5 min to remaining
                    } label: {
                        Text("+5m")
                            .font(AlefFont.Rounded.semibold(14))
                            .foregroundColor(.alefTextSecondary)
                            .frame(width: 56, height: 56)
                            .background(Color.alefSurface)
                            .clipShape(Circle())
                    }
                }

                Spacer().frame(height: 32)

                // ── Ambient sounds ───────────────────────────────
                VStack(spacing: 12) {
                    Text("AMBIENT SOUND")
                        .font(AlefFont.medium(11))
                        .foregroundColor(.alefTextTertiary)
                        .tracking(1)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(AmbientSound.allCases) { sound in
                                Button {
                                    selectedSound = sound
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: sound.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(
                                                selectedSound == sound ? sound.color : .alefTextTertiary
                                            )
                                        Text(sound.rawValue)
                                            .font(AlefFont.regular(11))
                                            .foregroundColor(
                                                selectedSound == sound ? .alefText : .alefTextTertiary
                                            )
                                    }
                                    .frame(width: 56, height: 56)
                                    .background(
                                        selectedSound == sound
                                            ? sound.color.opacity(0.1)
                                            : Color.alefSurface
                                    )
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                    }
                }

                Spacer().frame(height: 40)
            }

            // ── Completion overlay ───────────────────────────────
            if showCompletion {
                completionOverlay
                    .transition(.opacity)
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Timer Controls

    private func toggleTimer() {
        switch timerState {
        case .idle, .paused:
            startTimer()
        case .running:
            pauseTimer()
        }
    }

    private func startTimer() {
        timerState = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                elapsedSeconds += 1
                if elapsedSeconds >= targetSeconds {
                    await completeTimer()
                }
            }
        }
    }

    private func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
        timer = nil
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        timerState = .idle
        elapsedSeconds = 0
    }

    private func completeTimer() async {
        stopTimer()
        timerState = .idle

        // Log the completion
        let today = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()

        let body = LogEntryBody(date: today, value: elapsedSeconds)
        _ = try? await service.log(habitId: habitId, body: body, token: token)

        // Haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.spring()) {
            showCompletion = true
        }

        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showCompletion = false }
            dismiss()
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.alefBg.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(habitColor)

                Text("Complete!")
                    .font(AlefFont.bold(28))
                    .foregroundColor(.alefText)

                Text(formatTime(elapsedSeconds) + " focused")
                    .font(AlefFont.regular(16))
                    .foregroundColor(.alefTextSecondary)
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
