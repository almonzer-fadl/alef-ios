//
//  AddMealView.swift
//  alef
//
//  Form to log a new meal with type, name, calories, and macros.
//

import SwiftUI

struct AddMealView: View {
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("authToken") private var authToken = ""
    
    let selectedDate: Date
    let onMealAdded: (Meal) -> Void
    
    @State private var selectedType: MealType = .breakfast
    @State private var name = ""
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""
    @State private var description = ""
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let service = DietService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AlefLayout.sectionSpacing) {
                    
                    // Meal type selector
                    mealTypePicker
                    
                    // Form fields
                    formFields
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
                .padding(.vertical, 24)
            }
            .background(Color.alefBg)
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.alefTextSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveMeal()
                        }
                    }
                    .font(AlefFont.semibold(16))
                    .foregroundColor(.alefDiet)
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Meal Type Picker
    
    private var mealTypePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MEAL TYPE")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            HStack(spacing: 12) {
                ForEach(MealType.allCases, id: \.self) { type in
                    MealTypeButton(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                        Haptics.selection()
                    }
                }
            }
        }
    }
    
    // MARK: - Form Fields
    
    private var formFields: some View {
        VStack(spacing: 20) {
            
            // Name
            FormField(
                label: "Name",
                placeholder: "e.g., Oatmeal with Blueberries",
                text: $name
            )
            
            // Calories
            FormField(
                label: "Calories",
                placeholder: "Optional",
                text: $caloriesText,
                keyboardType: .numberPad
            )
            
            // Macros
            VStack(alignment: .leading, spacing: 12) {
                Text("MACROS (GRAMS)")
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
                    .tracking(1)
                
                HStack(spacing: 12) {
                    FormField(
                        label: "Protein",
                        placeholder: "0",
                        text: $proteinText,
                        keyboardType: .decimalPad
                    )
                    
                    FormField(
                        label: "Carbs",
                        placeholder: "0",
                        text: $carbsText,
                        keyboardType: .decimalPad
                    )
                    
                    FormField(
                        label: "Fat",
                        placeholder: "0",
                        text: $fatText,
                        keyboardType: .decimalPad
                    )
                }
            }
            
            // Description/Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("NOTES")
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
                    .tracking(1)
                
                TextEditor(text: $description)
                    .font(AlefFont.regular(15))
                    .foregroundColor(.alefText)
                    .frame(height: 100)
                    .padding(12)
                    .background(Color.alefSurface)
                    .cornerRadius(12)
                    .scrollContentBackground(.hidden)
            }
        }
    }
    
    // MARK: - Save Meal
    
    private func saveMeal() async {
        guard !name.isEmpty else { return }
        
        isSaving = true
        errorMessage = nil
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        do {
            let meal = try await service.createMeal(
                date: dateString,
                mealType: selectedType,
                name: name,
                calories: Int(caloriesText),
                protein: Double(proteinText),
                carbs: Double(carbsText),
                fat: Double(fatText),
                description: description.isEmpty ? nil : description,
                token: authToken
            )
            
            Haptics.success()
            onMealAdded(meal)
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
        
        isSaving = false
    }
}

// MARK: - Meal Type Button

struct MealTypeButton: View {
    let type: MealType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(AlefFont.semibold(20))
                    .foregroundColor(isSelected ? type.color : .alefTextTertiary)
                
                Text(type.label)
                    .font(AlefFont.medium(11))
                    .foregroundColor(isSelected ? .alefText : .alefTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? type.color.opacity(0.15) : Color.alefSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Form Field

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            TextField(placeholder, text: $text)
                .font(AlefFont.regular(15))
                .foregroundColor(.alefText)
                .padding(12)
                .background(Color.alefSurface)
                .cornerRadius(12)
                .keyboardType(keyboardType)
        }
    }
}

// MARK: - Preview

#Preview {
    AddMealView(selectedDate: Date()) { _ in }
}
