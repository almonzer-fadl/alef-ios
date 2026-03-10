//
//  FitnessService.swift
//  alef
//
//  Network layer for the Fitness module.
//  Wraps APIClient calls with typed methods for each endpoint.
//
//  All methods require an auth token — the calling ViewModel
//  reads it from @AppStorage("authToken").
//

import Foundation

struct FitnessService {

    private let api = APIClient.shared

    /// Fetch recent workouts (default 30, ordered by date desc).
    func fetchWorkouts(limit: Int = 30, token: String) async throws -> [Workout] {
        let response: WorkoutsResponse = try await api.request(
            "GET", "/fitness?limit=\(limit)", token: token
        )
        return response.workouts
    }

    /// Fetch a single workout by id.
    func fetchWorkout(id: String, token: String) async throws -> Workout {
        let response: WorkoutResponse = try await api.request(
            "GET", "/fitness/\(id)", token: token
        )
        return response.workout
    }

    /// Create a new workout.
    func create(_ body: CreateWorkoutBody, token: String) async throws -> Workout {
        let response: WorkoutResponse = try await api.request(
            "POST", "/fitness", body: body, token: token
        )
        return response.workout
    }

    /// Update an existing workout.
    func update(id: String, body: UpdateWorkoutBody, token: String) async throws -> Workout {
        let response: WorkoutResponse = try await api.request(
            "PATCH", "/fitness/\(id)", body: body, token: token
        )
        return response.workout
    }

    /// Delete a workout permanently.
    func delete(id: String, token: String) async throws {
        try await api.requestVoid("DELETE", "/fitness/\(id)", token: token)
    }
}
