//
//  CreateHabitView.swift
//  alef
//
//  Form to create a new habit.
//
//  Fields: name, icon (SF Symbol), colour, goal type, target value,
//  unit, frequency, group name.
//
//  Inspired by Grit's rich creation form — preview card at the top
//  shows what the habit will look like in the daily list.
//
//  Presented as a sheet from HabitsListView.
//

import SwiftUI

struct CreateHabitView: View {
    @ObservedObject var vm: HabitsViewModel
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name = ""
    @State private var icon = "checkmark.circle"
    @State private var selectedColor = Color.alefHabits
    @State private var selectedColorHex = "#34D399"
    @State private var goalType: GoalType = .boolean
    @State private var goalValue = 1
    @State private var goalUnit = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var groupName = ""
    @State private var isSaving = false
    @State private var customDays: Set<Int> = [] // 1=Sun, 2=Mon, ..., 7=Sat

    /// Preset SF Symbol icons for quick selection
    private let iconOptions = [
        "checkmark.circle", "drop.fill", "book.fill", "figure.run",
        "brain.head.profile", "moon.fill", "sun.max.fill", "heart.fill",
        "leaf.fill", "cup.and.saucer.fill", "dumbbell.fill", "pencil.line",
        "music.note", "paintbrush.fill", "gamecontroller.fill", "phone.down.fill",
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.alefBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AlefLayout.sectionSpacing) {

                        // ── Preview card ─────────────────────────
                        previewCard
                            .padding(.top, 8)

                        // ── Name ─────────────────────────────────
                        section("Name") {
                            TextField("", text: $name, prompt: Text("e.g. Drink Water").foregroundColor(.alefTextTertiary))
                                .font(AlefFont.regular(16))
                                .foregroundColor(.alefText)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }

                        // ── Icon picker ──────────────────────────
                        section("Icon") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 8), spacing: 10) {
                                ForEach(iconOptions, id: \.self) { ic in
                                    Button {
                                        icon = ic
                                    } label: {
                                        Image(systemName: ic)
                                            .font(.system(size: 18))
                                            .foregroundColor(icon == ic ? selectedColor : .alefTextTertiary)
                                            .frame(width: 40, height: 40)
                                            .background(icon == ic ? selectedColor.opacity(0.15) : Color.alefSurface)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }

                        // ── Colour picker ────────────────────────
                        section("Colour") {
                            HStack(spacing: 10) {
                                ForEach(Array(zip(Color.alefPalette.indices, Color.alefPalette)), id: \.0) { _, color in
                                    Button {
                                        selectedColor = color
                                        selectedColorHex = color.toHex()
                                    } label: {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.alefText, lineWidth: selectedColor == color ? 2 : 0)
                                                    .padding(-3)
                                            )
                                    }
                                }
                            }
                        }

                        // ── Goal type ────────────────────────────
                        section("Goal Type") {
                            HStack(spacing: 10) {
                                ForEach(GoalType.allCases, id: \.self) { type in
                                    Button {
                                        goalType = type
                                        // Reset defaults when switching type
                                        if type == .boolean { goalValue = 1; goalUnit = "" }
                                        if type == .timer { goalUnit = "seconds" }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 20))
                                            Text(type.label)
                                                .font(AlefFont.medium(12))
                                        }
                                        .foregroundColor(goalType == type ? selectedColor : .alefTextSecondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 64)
                                        .background(goalType == type ? selectedColor.opacity(0.1) : Color.alefSurface)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(goalType == type ? selectedColor.opacity(0.3) : Color.alefBorder, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }

                        // ── Target value (numeric/timer only) ────
                        if goalType != .boolean {
                            section("Target") {
                                HStack(spacing: 12) {
                                    TextField("", value: $goalValue, format: .number, prompt: Text("0").foregroundColor(.alefTextTertiary))
                                        .font(AlefFont.Rounded.semibold(20))
                                        .foregroundColor(.alefText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 80, height: 50)
                                        .background(Color.alefSurface)
                                        .cornerRadius(12)

                                    if goalType == .numeric {
                                        TextField("", text: $goalUnit, prompt: Text("unit (ml, pages...)").foregroundColor(.alefTextTertiary))
                                            .font(AlefFont.regular(15))
                                            .foregroundColor(.alefText)
                                            .padding(.horizontal, 16)
                                            .frame(height: 50)
                                            .background(Color.alefSurface)
                                            .cornerRadius(12)
                                    } else {
                                        Text("minutes")
                                            .font(AlefFont.regular(15))
                                            .foregroundColor(.alefTextSecondary)
                                    }
                                }
                            }
                        }

                        // ── Frequency ────────────────────────────
                        section("Frequency") {
                            VStack(spacing: 10) {
                                HStack(spacing: 8) {
                                    ForEach(HabitFrequency.allCases, id: \.self) { freq in
                                        Button {
                                            frequency = freq
                                        } label: {
                                            Text(freq.label)
                                                .font(AlefFont.medium(13))
                                                .foregroundColor(frequency == freq ? selectedColor : .alefTextSecondary)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 38)
                                                .background(frequency == freq ? selectedColor.opacity(0.1) : Color.alefSurface)
                                                .cornerRadius(10)
                                        }
                                    }
                                }

                                // Custom day picker — shown when frequency is "custom"
                                if frequency == .custom {
                                    customDayPicker
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }

                        // ── Group (optional) ─────────────────────
                        section("Group (optional)") {
                            TextField("", text: $groupName, prompt: Text("e.g. Morning Routine").foregroundColor(.alefTextTertiary))
                                .font(AlefFont.regular(16))
                                .foregroundColor(.alefText)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.alefTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().tint(.alefHabits)
                        } else {
                            Text("Save")
                                .foregroundColor(name.isEmpty ? .alefTextTertiary : .alefHabits)
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .toolbarBackground(Color.alefBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Preview Card

    /// Shows a live preview of what the habit will look like
    /// in the daily checklist. Updates as the user fills in fields.
    private var previewCard: some View {
        HStack(spacing: 14) {
            // Completion circle
            ZStack {
                Circle()
                    .stroke(selectedColor, lineWidth: 2)
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(name.isEmpty ? "Habit Name" : name)
                    .font(AlefFont.semibold(16))
                    .foregroundColor(name.isEmpty ? .alefTextTertiary : .alefText)

                if goalType == .numeric && goalValue > 0 {
                    Text("0/\(goalValue) \(goalUnit)")
                        .font(AlefFont.Rounded.medium(12))
                        .foregroundColor(.alefTextSecondary)
                }
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(selectedColor.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .fill(Color.alefSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .stroke(Color.alefBorder, lineWidth: 1)
        )
    }

    // MARK: - Section Helper

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AlefFont.medium(13))
                .foregroundColor(.alefTextSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            content()
        }
    }

    // MARK: - Custom Day Picker

    /// Row of 7 day circles — tap to toggle which days this habit repeats.
    /// Inspired by Grit's repeat schedule picker.
    private var customDayPicker: some View {
        let days = [
            (1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")
        ]

        return HStack(spacing: 8) {
            ForEach(days, id: \.0) { day, label in
                let isSelected = customDays.contains(day)
                Button {
                    if isSelected {
                        customDays.remove(day)
                    } else {
                        customDays.insert(day)
                    }
                } label: {
                    Text(label)
                        .font(AlefFont.Rounded.semibold(14))
                        .foregroundColor(isSelected ? .alefBg : .alefTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isSelected ? selectedColor : Color.alefSurface)
                        )
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.clear : Color.alefBorder, lineWidth: 1)
                        )
                }
            }
        }
        .animation(.spring(response: 0.25), value: customDays)
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        // Convert timer target from minutes to seconds for the API
        let apiGoalValue = goalType == .timer ? goalValue * 60 : goalValue
        let apiGoalUnit = goalType == .timer ? "seconds" : (goalUnit.isEmpty ? nil : goalUnit)

        let body = CreateHabitBody(
            name: name,
            icon: icon,
            color: selectedColorHex,
            goalType: goalType,
            goalValue: goalType == .boolean ? 1 : apiGoalValue,
            goalUnit: apiGoalUnit,
            frequency: frequency,
            groupName: groupName.isEmpty ? nil : groupName
        )

        await vm.createHabit(body)
    }
}

// MARK: - Color → Hex

// MARK: - Color extension moved to AlefTheme.swift
