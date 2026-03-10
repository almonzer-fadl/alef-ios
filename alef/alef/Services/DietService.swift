//
//  DietService.swift
//  alef
//
//  Network service for the Diet module.
//

import Foundation

final class DietService {
    
    static let shared = DietService()
    private init() {}
    
    // MARK: - Fetch Meals
    
    /// Get all meals for a specific date
    func fetchMealsForDay(date: String, token: String) async throws -> [Meal] {
        let response: DayMealsResponse = try await APIClient.shared.request(
            "GET",
            "/diet/day/\(date)",
            token: token
        )
        return response.meals
    }
    
    /// Get recent meals (default 30)
    func fetchRecentMeals(limit: Int = 30, token: String) async throws -> [Meal] {
        let response: MealsResponse = try await APIClient.shared.request(
            "GET",
            "/diet?limit=\(limit)",
            token: token
        )
        return response.meals
    }
    
    // MARK: - Create Meal
    
    func createMeal(
        date: String,
        mealType: MealType,
        name: String,
        calories: Int?,
        protein: Double?,
        carbs: Double?,
        fat: Double?,
        description: String?,
        token: String
    ) async throws -> Meal {
        let body = CreateMealBody(
            date: date,
            mealType: mealType.rawValue,
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            description: description
        )
        
        let response: MealResponse = try await APIClient.shared.request(
            "POST",
            "/diet",
            body: body,
            token: token
        )
        return response.meal
    }
    
    // MARK: - Update Meal
    
    func updateMeal(
        id: String,
        mealType: MealType?,
        name: String?,
        calories: Int?,
        protein: Double?,
        carbs: Double?,
        fat: Double?,
        description: String?,
        token: String
    ) async throws -> Meal {
        let body = UpdateMealBody(
            mealType: mealType?.rawValue,
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            description: description
        )
        
        let response: MealResponse = try await APIClient.shared.request(
            "PATCH",
            "/diet/\(id)",
            body: body,
            token: token
        )
        return response.meal
    }
    
    // MARK: - Delete Meal
    
    func deleteMeal(id: String, token: String) async throws {
        try await APIClient.shared.requestVoid(
            "DELETE",
            "/diet/\(id)",
            token: token
        )
    }
}
