//
//  FitnessViewModel.swift
//  alef
//
//  Drives the Fitness module — workout list, creation, and detail views.
//
//  Responsibilities:
//  - Fetch recent workouts from the API
//  - Filter workouts by type (All, Running, Strength, etc.)
//  - Create new workouts (cardio + strength)
//  - Update workouts
//  - Delete workouts
//  - Parse exercises JSON for strength workouts
//
//  The ViewModel is the single source of truth for workout state.
//  Views observe @Published properties and react to changes.
//

import SwiftUI
import Combine

@MainActor
final class FitnessViewModel: ObservableObject {

    // MARK: - Published State

    /// All fetched workouts from the API.
    @Published var workouts: [Workout] = []

    /// Currently selected filter (All, Running, Strength, etc.).
    @Published var selectedFilter: WorkoutType? = nil

    /// Loading state for the initial fetch.
    @Published var isLoading = false

    /// Error message to display in the UI.
    @Published var error: String?

    /// Controls the create workout sheet presentation.
    @Published var showCreateSheet = false

    // MARK: - Dependencies

    private let service = FitnessService()

    /// Auth token — injected from the view's @AppStorage.
    var token: String = ""

    // MARK: - Computed

    /// Filtered workouts based on the selected filter.
    var filteredWorkouts: [Workout] {
        guard let filter = selectedFilter else { return workouts }
        return workouts.filter { $0.workoutType == filter }
    }

    // MARK: - Fetch

    /// Load recent workouts from the API.
    /// Called on appear and after creating/deleting workouts.
    func fetchWorkouts() async {
        guard !token.isEmpty else { return }
        isLoading = workouts.isEmpty // only show spinner on first load
        error = nil

        do {
            workouts = try await service.fetchWorkouts(limit: 30, token: token)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Create

    /// Create a new workout and refresh the list.
    func createWorkout(_ body: CreateWorkoutBody) async {
        do {
            _ = try await service.create(body, token: token)
            Haptics.success()
            showCreateSheet = false
            await fetchWorkouts()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Update

    /// Update an existing workout.
    func updateWorkout(id: String, body: UpdateWorkoutBody) async {
        do {
            _ = try await service.update(id: id, body: body, token: token)
            Haptics.success()
            await fetchWorkouts()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Delete

    /// Delete a workout permanently.
    func deleteWorkout(id: String) async {
        do {
            try await service.delete(id: id, token: token)
            Haptics.medium()
            await fetchWorkouts()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    /// Encode exercises array to JSON string for storage.
    static func encodeExercises(_ exercises: [Exercise]) -> String? {
        guard let data = try? JSONEncoder().encode(exercises),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }
}
