//
//  EditHabitView.swift
//  alef
//
//  Edit an existing habit's properties.
//
//  Reuses the same layout as CreateHabitView but pre-populates
//  fields from the existing habit and uses PATCH instead of POST.
//
//  Accessible from HabitDetailView's toolbar.
//

import SwiftUI

struct EditHabitView: View {
    let habit: Habit
    let token: String
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let service = HabitService()

    // Pre-populated form state
    @State private var name: String
    @State private var icon: String
    @State private var selectedColorHex: String
    @State private var goalType: GoalType
    @State private var goalValue: Int
    @State private var goalUnit: String
    @State private var frequency: HabitFrequency
    @State private var groupName: String
    @State private var isArchived: Bool
    @State private var isSaving = false

    /// Preset SF Symbol icons
    private let iconOptions = [
        "checkmark.circle", "drop.fill", "book.fill", "figure.run",
        "brain.head.profile", "moon.fill", "sun.max.fill", "heart.fill",
        "leaf.fill", "cup.and.saucer.fill", "dumbbell.fill", "pencil.line",
        "music.note", "paintbrush.fill", "gamecontroller.fill", "phone.down.fill",
    ]

    init(habit: Habit, token: String, onSave: @escaping () -> Void) {
        self.habit = habit
        self.token = token
        self.onSave = onSave
        _name = State(initialValue: habit.name)
        _icon = State(initialValue: habit.icon ?? "checkmark.circle")
        _selectedColorHex = State(initialValue: habit.color ?? "#34D399")
        _goalType = State(initialValue: habit.goalType)
        _goalValue = State(initialValue: habit.goalValue ?? 1)
        _goalUnit = State(initialValue: habit.goalUnit ?? "")
        _frequency = State(initialValue: habit.frequency)
        _groupName = State(initialValue: habit.groupName ?? "")
        _isArchived = State(initialValue: habit.isArchived)
    }

    private var selectedColor: Color {
        Color(hex: selectedColorHex.replacingOccurrences(of: "#", with: ""))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.alefBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AlefLayout.sectionSpacing) {

                        // ── Name ─────────────────────────────────
                        section("Name") {
                            TextField("", text: $name, prompt: Text("Habit name").foregroundColor(.alefTextTertiary))
                                .font(AlefFont.regular(16))
                                .foregroundColor(.alefText)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }

                        // ── Icon ─────────────────────────────────
                        section("Icon") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 8), spacing: 10) {
                                ForEach(iconOptions, id: \.self) { ic in
                                    Button { icon = ic } label: {
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

                        // ── Colour ───────────────────────────────
                        section("Colour") {
                            HStack(spacing: 10) {
                                ForEach(Array(zip(Color.alefPalette.indices, Color.alefPalette)), id: \.0) { _, color in
                                    Button {
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

                        // ── Target (numeric/timer) ───────────────
                        if goalType != .boolean {
                            section("Target") {
                                HStack(spacing: 12) {
                                    TextField("", value: $goalValue, format: .number)
                                        .font(AlefFont.Rounded.semibold(20))
                                        .foregroundColor(.alefText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 80, height: 50)
                                        .background(Color.alefSurface)
                                        .cornerRadius(12)

                                    if goalType == .numeric {
                                        TextField("", text: $goalUnit, prompt: Text("unit").foregroundColor(.alefTextTertiary))
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
                            HStack(spacing: 8) {
                                ForEach(HabitFrequency.allCases, id: \.self) { freq in
                                    Button { frequency = freq } label: {
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
                        }

                        // ── Group ────────────────────────────────
                        section("Group (optional)") {
                            TextField("", text: $groupName, prompt: Text("e.g. Morning Routine").foregroundColor(.alefTextTertiary))
                                .font(AlefFont.regular(16))
                                .foregroundColor(.alefText)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }

                        // ── Archive toggle ───────────────────────
                        section("Status") {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Archived")
                                        .font(AlefFont.medium(15))
                                        .foregroundColor(.alefText)
                                    Text("Hidden from daily list but keeps history")
                                        .font(AlefFont.regular(12))
                                        .foregroundColor(.alefTextTertiary)
                                }
                                Spacer()
                                Toggle("", isOn: $isArchived)
                                    .tint(selectedColor)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.alefSurface)
                            .cornerRadius(12)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Edit Habit")
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

    // MARK: - Save

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let apiGoalValue = goalType == .timer ? goalValue * 60 : goalValue

        var body: [String: Any] = [
            "name": name,
            "icon": icon,
            "color": selectedColorHex,
            "goal_value": apiGoalValue,
            "frequency": frequency.rawValue,
            "is_archived": isArchived,
        ]

        if goalType == .numeric {
            body["goal_unit"] = goalUnit.isEmpty ? NSNull() : goalUnit
        }
        if !groupName.isEmpty {
            body["group_name"] = groupName
        } else {
            body["group_name"] = NSNull()
        }

        _ = try? await service.update(id: habit.id, body: body, token: token)
        onSave()
        dismiss()
    }
}
