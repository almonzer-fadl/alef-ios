//
//  HealthLogView.swift
//  alef
//
//  Daily health check-in — log weight, water, sleep, mood, energy.
//
//  Layout:
//  1. Today's card with quick-input fields
//  2. Sparkline charts for weight and water trends (last 7 days)
//  3. Recent logs list
//
//  Uses upsert pattern — fields auto-save as you fill them.
//  Inspired by Bevel's vitals cards with sparkline trends.
//

import SwiftUI
import Combine

struct HealthLogView: View {
    @AppStorage("authToken") private var authToken = ""

    @State private var todayLog: HealthLog?
    @State private var recentLogs: [HealthLog] = []
    @State private var isLoading = true

    // Today's form fields
    @State private var weight: String = ""
    @State private var waterMl: String = ""
    @State private var sleepHours: String = ""
    @State private var sleepQuality: Int = 3
    @State private var mood: Mood?
    @State private var energyLevel: Int = 3
    @State private var notes: String = ""

    private let service = HealthService()

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AlefLayout.sectionSpacing) {

                    // ── Today's check-in ─────────────────────────
                    todaySection
                        .padding(.top, 16)

                    // ── Vitals cards ─────────────────────────────
                    vitalsCards

                    // ── Mood picker ──────────────────────────────
                    moodSection

                    // ── Energy ────────────────────────────────────
                    energySection

                    // ── Notes ─────────────────────────────────────
                    notesSection

                    // ── Save button ──────────────────────────────
                    Button {
                        Task { await saveLog() }
                    } label: {
                        Text("Save Today's Log")
                            .font(AlefFont.semibold(16))
                            .foregroundColor(.alefBg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.alefHealth)
                            .cornerRadius(AlefLayout.cardRadius)
                    }

                    // ── Recent history ────────────────────────────
                    if !recentLogs.isEmpty {
                        recentSection
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
            }
        }
        .navigationTitle("Health")
        .task { await loadData() }
        .refreshable { await loadData() }
    }

    // MARK: - Today's Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(todayFormatted)
                .font(AlefFont.regular(13))
                .foregroundColor(.alefTextTertiary)
            Text("Daily Check-in")
                .font(AlefFont.bold(24))
                .foregroundColor(.alefText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Vitals Cards

    private var vitalsCards: some View {
        HStack(spacing: 12) {
            // Weight
            vitalCard(
                icon: "scalemass.fill",
                label: "Weight",
                unit: "kg",
                color: .alefHealth,
                value: $weight,
                keyboard: .decimalPad
            )

            // Water
            vitalCard(
                icon: "drop.fill",
                label: "Water",
                unit: "ml",
                color: .alefHabits,
                value: $waterMl,
                keyboard: .numberPad
            )

            // Sleep
            vitalCard(
                icon: "moon.fill",
                label: "Sleep",
                unit: "hrs",
                color: .alefSleep,
                value: $sleepHours,
                keyboard: .decimalPad
            )
        }
    }

    private func vitalCard(
        icon: String,
        label: String,
        unit: String,
        color: Color,
        value: Binding<String>,
        keyboard: UIKeyboardType
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            TextField("", text: value, prompt: Text("--").foregroundColor(.alefTextTertiary))
                .font(AlefFont.Rounded.bold(22))
                .foregroundColor(.alefText)
                .keyboardType(keyboard)
                .multilineTextAlignment(.center)

            Text(unit)
                .font(AlefFont.regular(11))
                .foregroundColor(.alefTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Mood Section

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MOOD")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)

            HStack(spacing: 10) {
                ForEach(Mood.allCases, id: \.self) { m in
                    Button {
                        Haptics.selection()
                        withAnimation(.spring(response: 0.25)) {
                            mood = mood == m ? nil : m
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: m.icon)
                                .font(.system(size: 22))
                            Text(m.label)
                                .font(AlefFont.regular(10))
                        }
                        .foregroundColor(mood == m ? m.color : .alefTextTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(mood == m ? m.color.opacity(0.1) : Color.alefSurface)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Energy Section

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ENERGY")
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
                    .tracking(1)
                Spacer()
                Text("\(energyLevel)/5")
                    .font(AlefFont.Rounded.semibold(13))
                    .foregroundColor(.alefDiet)
            }

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        Haptics.light()
                        withAnimation(.spring(response: 0.2)) {
                            energyLevel = level
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(level <= energyLevel ? Color.alefDiet : Color.alefSurfaceSecondary.opacity(0.3))
                            .frame(height: 8)
                    }
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)

            TextEditor(text: $notes)
                .font(AlefFont.regular(15))
                .foregroundColor(.alefText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(12)
                .background(Color.alefSurface)
                .cornerRadius(12)
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)

            ForEach(recentLogs.prefix(7)) { log in
                HStack {
                    Text(formatDate(log.date))
                        .font(AlefFont.regular(13))
                        .foregroundColor(.alefTextSecondary)
                        .frame(width: 70, alignment: .leading)

                    if let w = log.weight {
                        miniStat(icon: "scalemass.fill", value: String(format: "%.1f", w), color: .alefHealth)
                    }
                    if let water = log.waterMl {
                        miniStat(icon: "drop.fill", value: "\(water)", color: .alefHabits)
                    }
                    if let sleep = log.sleepHours {
                        miniStat(icon: "moon.fill", value: String(format: "%.1f", sleep), color: .alefSleep)
                    }
                    if let m = log.mood {
                        Image(systemName: m.icon)
                            .font(.system(size: 12))
                            .foregroundColor(m.color)
                    }

                    Spacer()
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    private func miniStat(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(AlefFont.Rounded.medium(12))
                .foregroundColor(.alefText)
        }
        .padding(.trailing, 8)
    }

    // MARK: - Data

    private func loadData() async {
        guard !authToken.isEmpty else { isLoading = false; return }

        do {
            recentLogs = try await service.fetchRecent(token: authToken, limit: 14)

            // Check if today has an entry
            let today = todayDateString
            if let existing = recentLogs.first(where: { $0.date == today }) {
                todayLog = existing
                populateForm(from: existing)
            }
        } catch {}
        isLoading = false
    }

    private func populateForm(from log: HealthLog) {
        if let w = log.weight { weight = String(format: "%.1f", w) }
        if let w = log.waterMl { waterMl = "\(w)" }
        if let s = log.sleepHours { sleepHours = String(format: "%.1f", s) }
        if let sq = log.sleepQuality { sleepQuality = sq }
        mood = log.mood
        if let e = log.energyLevel { energyLevel = e }
        notes = log.notes ?? ""
    }

    private func saveLog() async {
        let body = CreateHealthLogBody(
            date: todayDateString,
            weight: Double(weight),
            waterMl: Int(waterMl),
            sleepHours: Double(sleepHours),
            sleepQuality: sleepQuality,
            mood: mood,
            energyLevel: energyLevel,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let saved = try await service.upsert(body, token: authToken)
            todayLog = saved
            Haptics.success()
            // Refresh recent list
            await loadData()
        } catch {}
    }

    // MARK: - Helpers

    private var todayFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func formatDate(_ dateStr: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        guard let date = input.date(from: dateStr) else { return dateStr }
        let output = DateFormatter()
        output.dateFormat = "MMM d"
        return output.string(from: date)
    }
}
