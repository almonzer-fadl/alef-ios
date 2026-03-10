//
//  Fitness.swift
//  alef
//
//  Data models for the Fitness module.
//
//  Maps to the backend schema:
//  - Workout → `workouts` table
//  - Exercise → parsed from the `exercises` JSON field for strength workouts
//
//  Workout types:
//  - Cardio: running, cycling, swimming, walking (distance + duration)
//  - Strength: structured exercises with sets, reps, and weight
//  - Other: yoga, HIIT, general workouts
//

import Foundation
import SwiftUI

// MARK: - Workout Type

/// Workout category — determines which fields and icons are shown.
enum WorkoutType: String, Codable, CaseIterable {
    case running
    case strength
    case cycling
    case yoga
    case swimming
    case walking
    case hiit
    case other
    
    var label: String {
        switch self {
        case .running:   return "Running"
        case .strength:  return "Strength"
        case .cycling:   return "Cycling"
        case .yoga:      return "Yoga"
        case .swimming:  return "Swimming"
        case .walking:   return "Walking"
        case .hiit:      return "HIIT"
        case .other:     return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .running:   return "figure.run"
        case .strength:  return "dumbbell.fill"
        case .cycling:   return "bicycle"
        case .yoga:      return "figure.yoga"
        case .swimming:  return "figure.pool.swim"
        case .walking:   return "figure.walk"
        case .hiit:      return "flame.fill"
        case .other:     return "figure.mixed.cardio"
        }
    }
    
    /// Whether this workout type tracks distance (cardio workouts).
    var tracksDistance: Bool {
        [.running, .cycling, .swimming, .walking].contains(self)
    }
    
    /// Whether this workout type uses structured exercises (strength).
    var hasExercises: Bool {
        self == .strength
    }
}

// MARK: - Exercise Set

/// A single set in a strength exercise (reps + weight).
struct ExerciseSet: Codable, Identifiable {
    var id = UUID()
    var reps: Int
    var weight: Double?  // kg
    
    enum CodingKeys: String, CodingKey {
        case reps, weight
    }
}

// MARK: - Exercise

/// A strength exercise with multiple sets.
struct Exercise: Codable, Identifiable {
    var id = UUID()
    var name: String
    var sets: [ExerciseSet]
    
    enum CodingKeys: String, CodingKey {
        case name, sets
    }
}

// MARK: - Workout

/// A single workout session.
struct Workout: Codable, Identifiable {
    let id: String
    let userId: String
    let date: String
    var type: String           // "running", "strength", etc.
    var durationMin: Int?
    var caloriesBurned: Int?
    var distanceKm: Double?
    var notes: String?
    var exercises: String?     // JSON string: [{name, sets: [{reps, weight}]}]
    let createdAt: String
    
    /// Parsed workout type (safe conversion from string).
    var workoutType: WorkoutType {
        WorkoutType(rawValue: type) ?? .other
    }
    
    /// Parsed exercises for strength workouts.
    var parsedExercises: [Exercise] {
        guard let exercises = exercises,
              let data = exercises.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Exercise].self, from: data) else {
            return []
        }
        return decoded
    }
    
    /// Calculate pace for cardio workouts (min/km).
    var pacePerKm: Double? {
        guard let distance = distanceKm, let duration = durationMin, distance > 0 else {
            return nil
        }
        return Double(duration) / distance
    }
    
    /// Formatted pace string (e.g., "5:30 /km").
    var formattedPace: String? {
        guard let pace = pacePerKm else { return nil }
        let mins = Int(pace)
        let secs = Int((pace - Double(mins)) * 60)
        return String(format: "%d:%02d /km", mins, secs)
    }
}

// MARK: - API Response Wrappers

/// GET /fitness response
struct WorkoutsResponse: Codable {
    let workouts: [Workout]
}

/// GET /fitness/:id and POST /fitness response
struct WorkoutResponse: Codable {
    let workout: Workout
}

// MARK: - Create/Update DTOs

/// Body for POST /fitness
struct CreateWorkoutBody: Encodable {
    let date: String
    let type: String
    var durationMin: Int?
    var caloriesBurned: Int?
    var distanceKm: Double?
    var notes: String?
    var exercises: String?
}

/// Body for PATCH /fitness/:id
struct UpdateWorkoutBody: Encodable {
    var date: String?
    var type: String?
    var durationMin: Int?
    var caloriesBurned: Int?
    var distanceKm: Double?
    var notes: String?
    var exercises: String?
}
