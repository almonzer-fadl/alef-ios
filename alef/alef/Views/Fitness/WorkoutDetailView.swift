//
//  WorkoutDetailView.swift
//  alef
//
//  Detailed view of a single workout.
//

import SwiftUI
import Combine

struct WorkoutDetailView: View {
    let workoutId: String
    @ObservedObject var vm: FitnessViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var workout: Workout?
    @State private var isLoading = true
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()
            
            if isLoading {
                ProgressView().tint(.alefFitness)
            } else if let workout = workout {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AlefLayout.sectionSpacing) {
                        headerCard(workout: workout)
                        statsSection(workout: workout)
                        if workout.workoutType.hasExercises && !workout.parsedExercises.isEmpty {
                            exercisesSection(workout: workout)
                        }
                        if let notes = workout.notes, !notes.isEmpty {
                            notesSection(notes: notes)
                        }
                        deleteButton
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            } else {
                Text("Workout not found")
                    .font(AlefFont.regular(15))
                    .foregroundColor(.alefTextSecondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadWorkout() }
        .alert("Delete Workout?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await vm.deleteWorkout(id: workoutId)
                    dismiss()
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func headerCard(workout: Workout) -> some View {
        HStack(spacing: 16) {
            Image(systemName: workout.workoutType.icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.alefFitness)
                .frame(width: 64, height: 64)
                .background(Color.alefFitness.opacity(0.15))
                .cornerRadius(16)
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutType.label).font(AlefFont.bold(22)).foregroundColor(.alefText)
                Text(formattedDate(workout.date)).font(AlefFont.regular(14)).foregroundColor(.alefTextSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    private func statsSection(workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats").font(AlefFont.medium(11)).foregroundColor(.alefTextTertiary).tracking(1).textCase(.uppercase)
            VStack(spacing: 12) {
                if let duration = workout.durationMin {
                    statRow(icon: "clock", label: "Duration", value: "\(duration) min")
                }
                if let calories = workout.caloriesBurned {
                    statRow(icon: "flame.fill", label: "Calories Burned", value: "\(calories) kcal")
                }
                if let distance = workout.distanceKm {
                    statRow(icon: "location.fill", label: "Distance", value: String(format: "%.2f km", distance))
                }
                if let pace = workout.formattedPace {
                    statRow(icon: "speedometer", label: "Pace", value: pace)
                }
            }
            .padding(16)
            .background(Color.alefSurface)
            .cornerRadius(AlefLayout.cardRadius)
        }
    }
    
    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(.alefFitness).frame(width: 24)
            Text(label).font(AlefFont.regular(15)).foregroundColor(.alefTextSecondary)
            Spacer()
            Text(value).font(AlefFont.Rounded.semibold(15)).foregroundColor(.alefText)
        }
    }
    
    private func exercisesSection(workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises").font(AlefFont.medium(11)).foregroundColor(.alefTextTertiary).tracking(1).textCase(.uppercase)
            VStack(spacing: 12) {
                ForEach(workout.parsedExercises) { exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name).font(AlefFont.semibold(16)).foregroundColor(.alefText)
                        VStack(spacing: 4) {
                            ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                                HStack {
                                    Text("Set \(index + 1)").font(AlefFont.medium(13)).foregroundColor(.alefTextSecondary).frame(width: 50, alignment: .leading)
                                    Text("\(set.reps) reps").font(AlefFont.Rounded.regular(13)).foregroundColor(.alefText)
                                    if let weight = set.weight {
                                        Text("×").font(AlefFont.regular(13)).foregroundColor(.alefTextTertiary)
                                        Text(String(format: "%.1f kg", weight)).font(AlefFont.Rounded.semibold(13)).foregroundColor(.alefFitness)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.alefSurfaceSecondary)
                    .cornerRadius(12)
                }
            }
            .padding(16)
            .background(Color.alefSurface)
            .cornerRadius(AlefLayout.cardRadius)
        }
    }
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes").font(AlefFont.medium(11)).foregroundColor(.alefTextTertiary).tracking(1).textCase(.uppercase)
            Text(notes)
                .font(AlefFont.regular(15))
                .foregroundColor(.alefText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.alefSurface)
                .cornerRadius(AlefLayout.cardRadius)
        }
    }
    
    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Text("Delete Workout")
                .font(AlefFont.semibold(15))
                .foregroundColor(.alefError)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.alefError.opacity(0.1))
                .cornerRadius(12)
        }
        .padding(.top, 8)
    }
    
    private func loadWorkout() async {
        workout = vm.workouts.first { $0.id == workoutId }
        isLoading = false
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
}
