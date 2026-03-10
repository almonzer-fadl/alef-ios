//
//  Diet.swift
//  alef
//
//  Data models for the Diet module.
//

import Foundation
import SwiftUI

// MARK: - Meal Type

/// The four meal categories for daily tracking.
enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    
    var label: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch:     return "sun.max.fill"
        case .dinner:    return "moon.fill"
        case .snack:     return "leaf.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .alefMovies      // amber
        case .lunch:     return .alefDiet        // orange
        case .dinner:    return .alefCalendar    // violet
        case .snack:     return .alefBooks       // teal
        }
    }
}

// MARK: - Meal

/// A single meal entry.
/// Maps to the backend `meals` table.
struct Meal: Codable, Identifiable {
    let id: String
    let userId: String
    let date: String                // "YYYY-MM-DD"
    var mealType: String            // "breakfast", "lunch", "dinner", "snack"
    var name: String
    var calories: Int?
    var protein: Double?            // grams
    var carbs: Double?              // grams
    var fat: Double?                // grams
    var description: String?
    let createdAt: String
    
    /// Typed meal type for SwiftUI display
    var type: MealType {
        MealType(rawValue: mealType) ?? .snack
    }
}

// MARK: - API Response Wrappers

/// GET /diet response (recent meals)
struct MealsResponse: Codable {
    let meals: [Meal]
}

/// GET /diet/day/:date response
struct DayMealsResponse: Codable {
    let meals: [Meal]
    let date: String
}

/// POST/PATCH /diet response
struct MealResponse: Codable {
    let meal: Meal
}

// MARK: - Create/Update DTOs

/// Body for POST /diet
struct CreateMealBody: Encodable {
    let date: String
    let mealType: String
    let name: String
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var description: String?
}

/// Body for PATCH /diet/:id
struct UpdateMealBody: Encodable {
    var mealType: String?
    var name: String?
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var description: String?
}

// MARK: - Daily Summary

/// Aggregated macros for a day's meals.
/// Calculated client-side from the meal list.
struct DailyMacros {
    var totalCalories: Int
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    
    static let zero = DailyMacros(totalCalories: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0)
    
    /// Calculate totals from a list of meals
    static func from(meals: [Meal]) -> DailyMacros {
        DailyMacros(
            totalCalories: meals.reduce(0) { $0 + ($1.calories ?? 0) },
            totalProtein: meals.reduce(0) { $0 + ($1.protein ?? 0) },
            totalCarbs: meals.reduce(0) { $0 + ($1.carbs ?? 0) },
            totalFat: meals.reduce(0) { $0 + ($1.fat ?? 0) }
        )
    }
}
