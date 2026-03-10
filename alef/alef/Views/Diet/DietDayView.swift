//
//  DietDayView.swift
//  alef
//
//  Main daily diet screen showing macro rings, meal sections, and FAB to add meals.
//

import SwiftUI

struct DietDayView: View {
    
    @StateObject private var viewModel = DietViewModel()
    @AppStorage("authToken") private var authToken = ""
    @State private var showingAddMeal = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: AlefLayout.sectionSpacing) {
                    
                    // Date selector
                    dateSelector
                    
                    // Daily macro summary
                    macroSummaryCard
                    
                    // Meal sections
                    mealSections
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
                .padding(.bottom, 100) // space for FAB
            }
            .background(Color.alefBg)
            .refreshable {
                await viewModel.fetchMeals(token: authToken)
            }
            
            // FAB to add meal
            addMealButton
        }
        .navigationTitle("Diet")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.fetchMeals(token: authToken)
        }
        .onChange(of: viewModel.selectedDate) { _ in
            Task {
                await viewModel.fetchMeals(token: authToken)
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealView(selectedDate: viewModel.selectedDate) { _ in
                Task {
                    await viewModel.fetchMeals(token: authToken)
                }
            }
        }
    }
    
    // MARK: - Date Selector
    
    private var dateSelector: some View {
        HStack {
            Button(action: { viewModel.goToPreviousDay() }) {
                Image(systemName: "chevron.left")
                    .font(AlefFont.semibold(16))
                    .foregroundColor(.alefText)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(formattedDate)
                    .font(AlefFont.semibold(17))
                    .foregroundColor(.alefText)
                
                if !viewModel.isToday {
                    Button("Today") {
                        viewModel.goToToday()
                    }
                    .font(AlefFont.medium(12))
                    .foregroundColor(.alefDiet)
                }
            }
            
            Spacer()
            
            Button(action: { viewModel.goToNextDay() }) {
                Image(systemName: "chevron.right")
                    .font(AlefFont.semibold(16))
                    .foregroundColor(.alefText)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: viewModel.selectedDate)
    }
    
    // MARK: - Macro Summary Card
    
    private var macroSummaryCard: some View {
        VStack(spacing: 16) {
            MacroRingView(macros: viewModel.dailyMacros)
            MacroLegendView(macros: viewModel.dailyMacros)
        }
        .padding(20)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    // MARK: - Meal Sections
    
    private var mealSections: some View {
        VStack(spacing: AlefLayout.sectionSpacing) {
            ForEach(MealType.allCases, id: \.self) { type in
                if let meals = viewModel.mealsByType[type], !meals.isEmpty {
                    mealSection(type: type, meals: meals)
                }
            }
            
            if viewModel.meals.isEmpty {
                emptyState
            }
        }
    }
    
    private func mealSection(type: MealType, meals: [Meal]) -> some View {
        VStack(alignment: .leading, spacing: AlefLayout.itemSpacing) {
            
            // Section header
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(AlefFont.semibold(14))
                    .foregroundColor(type.color)
                
                Text(type.label.uppercased())
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
                    .tracking(1)
            }
            
            // Meal cards
            ForEach(meals) { meal in
                MealCard(meal: meal) {
                    Task {
                        await viewModel.deleteMeal(id: meal.id, token: authToken)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.alefTextTertiary)
            
            Text("No meals logged yet")
                .font(AlefFont.medium(16))
                .foregroundColor(.alefTextSecondary)
            
            Text("Tap + to add your first meal")
                .font(AlefFont.regular(14))
                .foregroundColor(.alefTextTertiary)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - FAB
    
    private var addMealButton: some View {
        Button(action: {
            Haptics.medium()
            showingAddMeal = true
        }) {
            Image(systemName: "plus")
                .font(AlefFont.semibold(20))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.alefDiet)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, AlefLayout.horizontalPadding)
        .padding(.bottom, 32)
    }
}

// MARK: - Meal Card

struct MealCard: View {
    let meal: Meal
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // Meal icon
            Image(systemName: meal.type.icon)
                .font(AlefFont.semibold(18))
                .foregroundColor(meal.type.color)
                .frame(width: 40, height: 40)
                .background(meal.type.color.opacity(0.15))
                .cornerRadius(10)
            
            // Meal info
            VStack(alignment: .leading, spacing: 6) {
                Text(meal.name)
                    .font(AlefFont.semibold(15))
                    .foregroundColor(.alefText)
                
                // Macros row
                HStack(spacing: 12) {
                    if let calories = meal.calories {
                        MacroBadge(label: "\(calories) cal", color: .alefDiet)
                    }
                    if let protein = meal.protein {
                        MacroBadge(label: "\(Int(protein))g P", color: .alefFitness)
                    }
                    if let carbs = meal.carbs {
                        MacroBadge(label: "\(Int(carbs))g C", color: .alefMovies)
                    }
                    if let fat = meal.fat {
                        MacroBadge(label: "\(Int(fat))g F", color: .alefCalendar)
                    }
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(AlefFont.medium(14))
                    .foregroundColor(.alefError)
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
}

struct MacroBadge: View {
    let label: String
    let color: Color
    
    var body: some View {
        Text(label)
            .font(AlefFont.Rounded.medium(11))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}
