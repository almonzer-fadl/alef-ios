//
//  MacroRingView.swift
//  alef
//
//  Circular macro display with three concentric rings for protein, carbs, fat.
//  Calorie total displayed in the centre.
//

import SwiftUI

struct MacroRingView: View {
    
    let macros: DailyMacros
    let calorieTarget: Int = 2000        // TODO: Make this user-configurable
    let proteinTarget: Double = 150      // grams
    let carbsTarget: Double = 200        // grams
    let fatTarget: Double = 65           // grams
    
    var body: some View {
        ZStack {
            // Background rings (full circle at target opacity)
            Circle()
                .stroke(Color.alefFitness.opacity(0.2), lineWidth: 12)
                .frame(width: 180, height: 180)
            
            Circle()
                .stroke(Color.alefMovies.opacity(0.2), lineWidth: 12)
                .frame(width: 156, height: 156)
            
            Circle()
                .stroke(Color.alefCalendar.opacity(0.2), lineWidth: 12)
                .frame(width: 132, height: 132)
            
            // Protein ring (outermost)
            Circle()
                .trim(from: 0, to: min(macros.totalProtein / proteinTarget, 1.0))
                .stroke(
                    Color.alefFitness,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: macros.totalProtein)
            
            // Carbs ring (middle)
            Circle()
                .trim(from: 0, to: min(macros.totalCarbs / carbsTarget, 1.0))
                .stroke(
                    Color.alefMovies,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 156, height: 156)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6).delay(0.1), value: macros.totalCarbs)
            
            // Fat ring (innermost)
            Circle()
                .trim(from: 0, to: min(macros.totalFat / fatTarget, 1.0))
                .stroke(
                    Color.alefCalendar,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6).delay(0.2), value: macros.totalFat)
            
            // Centre label — total calories
            VStack(spacing: 2) {
                Text("\(macros.totalCalories)")
                    .font(AlefFont.Rounded.bold(32))
                    .foregroundColor(.alefText)
                
                Text("/ \(calorieTarget) cal")
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
            }
        }
        .frame(height: 200)
    }
}

// MARK: - Macro Legend

/// Legend showing protein/carbs/fat with current/target values
struct MacroLegendView: View {
    
    let macros: DailyMacros
    let proteinTarget: Double = 150
    let carbsTarget: Double = 200
    let fatTarget: Double = 65
    
    var body: some View {
        HStack(spacing: 20) {
            MacroLegendItem(
                label: "Protein",
                color: .alefFitness,
                current: Int(macros.totalProtein),
                target: Int(proteinTarget),
                unit: "g"
            )
            
            MacroLegendItem(
                label: "Carbs",
                color: .alefMovies,
                current: Int(macros.totalCarbs),
                target: Int(carbsTarget),
                unit: "g"
            )
            
            MacroLegendItem(
                label: "Fat",
                color: .alefCalendar,
                current: Int(macros.totalFat),
                target: Int(fatTarget),
                unit: "g"
            )
        }
    }
}

struct MacroLegendItem: View {
    let label: String
    let color: Color
    let current: Int
    let target: Int
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(label.uppercased())
                    .font(AlefFont.medium(10))
                    .foregroundColor(.alefTextTertiary)
                    .tracking(0.5)
            }
            
            Text("\(current) / \(target)\(unit)")
                .font(AlefFont.Rounded.semibold(13))
                .foregroundColor(.alefText)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        MacroRingView(macros: DailyMacros(
            totalCalories: 1450,
            totalProtein: 98,
            totalCarbs: 145,
            totalFat: 52
        ))
        
        MacroLegendView(macros: DailyMacros(
            totalCalories: 1450,
            totalProtein: 98,
            totalCarbs: 145,
            totalFat: 52
        ))
    }
    .padding()
    .background(Color.alefBg)
}
