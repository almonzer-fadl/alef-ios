//
//  DietViewModel.swift
//  alef
//
//  Drives the daily diet view — meal list, macro summary, date navigation.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class DietViewModel: ObservableObject {
    
    @Published var meals: [Meal] = []
    @Published var selectedDate: Date = Date()
    @Published var dailyMacros: DailyMacros = .zero
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = DietService.shared
    
    // MARK: - Date Helpers
    
    /// Current selected date as "YYYY-MM-DD"
    var selectedDateString: String {
        dateFormatter.string(from: selectedDate)
    }
    
    /// ISO date formatter for API calls
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    /// Whether the selected date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    // MARK: - Grouped Meals
    
    /// Meals grouped by type (breakfast, lunch, dinner, snack)
    var mealsByType: [MealType: [Meal]] {
        Dictionary(grouping: meals) { $0.type }
    }
    
    // MARK: - Fetch Meals
    
    func fetchMeals(token: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            meals = try await service.fetchMealsForDay(date: selectedDateString, token: token)
            calculateMacros()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Calculate Macros
    
    private func calculateMacros() {
        dailyMacros = DailyMacros.from(meals: meals)
    }
    
    // MARK: - Delete Meal
    
    func deleteMeal(id: String, token: String) async {
        do {
            try await service.deleteMeal(id: id, token: token)
            meals.removeAll { $0.id == id }
            calculateMacros()
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
    
    // MARK: - Date Navigation
    
    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Haptics.selection()
    }
    
    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        Haptics.selection()
    }
    
    func goToToday() {
        selectedDate = Date()
        Haptics.selection()
    }
}
