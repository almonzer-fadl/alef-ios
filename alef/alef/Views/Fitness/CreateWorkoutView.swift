//
//  CreateWorkoutView.swift
//  alef
//
//  Form to log a new workout.
//

import SwiftUI
import Combine

struct CreateWorkoutView: View {
    @ObservedObject var vm: FitnessViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: WorkoutType = .running
    @State private var date = Date()
    @State private var durationMin = 30
    @State private var caloriesBurned = 0
    @State private var distanceKm = 0.0
    @State private var notes = ""
    @State private var exercises: [Exercise] = []
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.alefBg.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AlefLayout.sectionSpacing) {
                        section("Workout Type") { workoutTypePicker }
                        section("Date") { datePicker }
                        section("Duration") { durationField }
                        section("Calories Burned (optional)") { caloriesField }
                        if selectedType.tracksDistance { section("Distance") { distanceField } }
                        if selectedType.hasExercises { section("Exercises") { exercisesEditor } }
                        section("Notes (optional)") { notesField }
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.alefTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await save() } } label: {
                        if isSaving {
                            ProgressView().tint(.alefFitness)
                        } else {
                            Text("Save")
                                .font(AlefFont.semibold(16))
                                .foregroundColor(.alefFitness)
                        }
                    }.disabled(isSaving)
                }
            }
        }
    }
    
    private var workoutTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    Button {
                        Haptics.selection()
                        selectedType = type
                        if !type.tracksDistance { distanceKm = 0.0 }
                        if !type.hasExercises { exercises = [] }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon).font(.system(size: 24, weight: .semibold))
                            Text(type.label).font(AlefFont.medium(13))
                        }
                        .foregroundColor(selectedType == type ? .alefBg : .alefText)
                        .frame(width: 90, height: 80)
                        .background(RoundedRectangle(cornerRadius: 12).fill(selectedType == type ? Color.alefFitness : Color.alefSurface))
                    }
                }
            }
        }
    }
    
    private var datePicker: some View {
        DatePicker("", selection: $date, displayedComponents: .date)
            .datePickerStyle(.compact)
            .labelsHidden()
            .colorScheme(.dark)
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.alefSurface)
            .cornerRadius(12)
    }
    
    private var durationField: some View {
        HStack(spacing: 12) {
            TextField("", value: $durationMin, format: .number)
                .font(AlefFont.Rounded.semibold(20))
                .foregroundColor(.alefText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 80, height: 50)
                .background(Color.alefSurface)
                .cornerRadius(12)
            Text("minutes").font(AlefFont.regular(15)).foregroundColor(.alefTextSecondary)
        }
    }
    
    private var caloriesField: some View {
        HStack(spacing: 12) {
            TextField("", value: $caloriesBurned, format: .number)
                .font(AlefFont.Rounded.semibold(20))
                .foregroundColor(.alefText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 100, height: 50)
                .background(Color.alefSurface)
                .cornerRadius(12)
            Text("kcal").font(AlefFont.regular(15)).foregroundColor(.alefTextSecondary)
        }
    }
    
    private var distanceField: some View {
        HStack(spacing: 12) {
            TextField("", value: $distanceKm, format: .number)
                .font(AlefFont.Rounded.semibold(20))
                .foregroundColor(.alefText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 100, height: 50)
                .background(Color.alefSurface)
                .cornerRadius(12)
            Text("km").font(AlefFont.regular(15)).foregroundColor(.alefTextSecondary)
        }
    }
    
    private var exercisesEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(exercises.indices, id: \.self) { exerciseIndex in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Exercise name", text: $exercises[exerciseIndex].name)
                            .font(AlefFont.semibold(15))
                            .foregroundColor(.alefText)
                            .padding(.horizontal, 12)
                            .frame(height: 40)
                            .background(Color.alefSurfaceSecondary)
                            .cornerRadius(8)
                        Button { exercises.remove(at: exerciseIndex) } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.alefError)
                                .frame(width: 40, height: 40)
                                .background(Color.alefSurfaceSecondary)
                                .cornerRadius(8)
                        }
                    }
                    ForEach(exercises[exerciseIndex].sets.indices, id: \.self) { setIndex in
                        HStack(spacing: 8) {
                            Text("Set \(setIndex + 1)").font(AlefFont.medium(12)).foregroundColor(.alefTextTertiary).frame(width: 50, alignment: .leading)
                            TextField("Reps", value: $exercises[exerciseIndex].sets[setIndex].reps, format: .number)
                                .font(AlefFont.Rounded.semibold(14))
                                .foregroundColor(.alefText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 60, height: 36)
                                .background(Color.alefSurfaceSecondary)
                                .cornerRadius(6)
                            Text("reps").font(AlefFont.regular(12)).foregroundColor(.alefTextSecondary)
                            TextField("Weight", value: Binding(
                                get: { exercises[exerciseIndex].sets[setIndex].weight ?? 0 },
                                set: { exercises[exerciseIndex].sets[setIndex].weight = $0 > 0 ? $0 : nil }
                            ), format: .number)
                                .font(AlefFont.Rounded.semibold(14))
                                .foregroundColor(.alefText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 60, height: 36)
                                .background(Color.alefSurfaceSecondary)
                                .cornerRadius(6)
                            Text("kg").font(AlefFont.regular(12)).foregroundColor(.alefTextSecondary)
                            Spacer()
                            if setIndex == exercises[exerciseIndex].sets.count - 1 {
                                Button {
                                    exercises[exerciseIndex].sets.append(ExerciseSet(reps: 0, weight: nil))
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.alefFitness)
                                        .font(.system(size: 20))
                                }
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.alefSurface)
                .cornerRadius(12)
            }
            Button {
                exercises.append(Exercise(name: "", sets: [ExerciseSet(reps: 0, weight: nil)]))
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Exercise").font(AlefFont.semibold(14))
                }
                .foregroundColor(.alefFitness)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.alefFitness.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var notesField: some View {
        TextEditor(text: $notes)
            .font(AlefFont.regular(15))
            .foregroundColor(.alefText)
            .scrollContentBackground(.hidden)
            .background(Color.alefSurface)
            .frame(height: 100)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.alefBorder, lineWidth: 1))
    }
    
    private func save() async {
        isSaving = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        let exercisesJSON: String? = selectedType.hasExercises && !exercises.isEmpty ? FitnessViewModel.encodeExercises(exercises) : nil
        let body = CreateWorkoutBody(
            date: dateString,
            type: selectedType.rawValue,
            durationMin: durationMin > 0 ? durationMin : nil,
            caloriesBurned: caloriesBurned > 0 ? caloriesBurned : nil,
            distanceKm: distanceKm > 0 ? distanceKm : nil,
            notes: notes.isEmpty ? nil : notes,
            exercises: exercisesJSON
        )
        await vm.createWorkout(body)
        isSaving = false
        dismiss()
    }
    
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(AlefFont.medium(11)).foregroundColor(.alefTextTertiary).tracking(1).textCase(.uppercase)
            content()
        }
    }
}
