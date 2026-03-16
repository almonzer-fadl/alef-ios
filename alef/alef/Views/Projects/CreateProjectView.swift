//
//  CreateProjectView.swift
//  alef
//
//  Form to create a new project
//

import SwiftUI

struct CreateProjectView: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProjectViewModel
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "#22D3EE"
    @State private var selectedIcon = "folder.fill"
    
    private let colorOptions = [
        "#22D3EE", // Projects cyan
        "#34D399", // Habits green
        "#F472B6", // Journal pink
        "#60A5FA", // Health blue
        "#FB923C", // Diet orange
        "#FBBF24", // Movies yellow
        "#A78BFA", // Calendar purple
        "#F87171", // Fitness red
    ]
    
    private let iconOptions = [
        "folder.fill", "briefcase.fill", "lightbulb.fill",
        "star.fill", "flag.fill", "target",
        "chart.bar.fill", "bolt.fill", "sparkles"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.alefBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AlefLayout.sectionSpacing) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Project Name")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            TextField("Enter name", text: $name)
                                .font(AlefFont.regular(17))
                                .foregroundColor(.alefText)
                                .padding(16)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }
                        
                        // Description Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            TextField("Optional", text: $description)
                                .font(AlefFont.regular(17))
                                .foregroundColor(.alefText)
                                .padding(16)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }
                        
                        // Colour Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Colour")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(colorOptions, id: \.self) { color in
                                        colorCircle(color)
                                    }
                                }
                            }
                        }
                        
                        // Icon Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                                ForEach(iconOptions, id: \.self) { icon in
                                    iconButton(icon)
                                }
                            }
                        }
                        
                        // Create Button
                        Button {
                            createProject()
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.alefBg)
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(Color.alefProjects)
                                    .cornerRadius(12)
                            } else {
                                Text("Create Project")
                                    .font(AlefFont.semibold(17))
                                    .foregroundColor(.alefBg)
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(name.isEmpty ? Color.alefTextTertiary : Color.alefProjects)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(name.isEmpty || viewModel.isLoading)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.alefTextSecondary)
                }
            }
        }
    }
    
    // MARK: - Colour Circle
    
    private func colorCircle(_ hex: String) -> some View {
        Button {
            Haptics.selection()
            selectedColor = hex
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: hex) ?? .alefProjects)
                    .frame(width: 48, height: 48)
                
                if selectedColor == hex {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.alefBg)
                }
            }
        }
    }
    
    // MARK: - Icon Button
    
    private func iconButton(_ icon: String) -> some View {
        Button {
            Haptics.selection()
            selectedIcon = icon
        } label: {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(selectedIcon == icon ? .alefBg : Color(hex: selectedColor) ?? .alefProjects)
                .frame(width: 60, height: 60)
                .background(selectedIcon == icon ? Color(hex: selectedColor) ?? .alefProjects : Color.alefSurface)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Create Project
    
    private func createProject() {
        Task {
            await viewModel.createProject(
                name: name,
                description: description.isEmpty ? nil : description,
                color: selectedColor,
                icon: selectedIcon
            )
            dismiss()
        }
    }
}
