//
//  FitnessListView.swift
//  alef
//
//  Main workout list screen for the Fitness module.
//
//  Layout (top to bottom):
//  1. Filter chips — All, Running, Strength, Cycling, Yoga
//  2. Workout cards — type icon, duration, calories, date
//  3. FAB — floating + button to log a new workout
//
//  Features:
//  - Pull-to-refresh to fetch latest workouts
//  - Context menu on cards: edit, delete
//  - Tap to view workout details
//

import SwiftUI
import Combine

struct FitnessListView: View {
    @StateObject private var vm = FitnessViewModel()
    @AppStorage("authToken") private var authToken = ""
    
    /// Filter options shown in the horizontal chip row.
    private let filterOptions: [WorkoutType?] = [nil, .running, .strength, .cycling, .yoga]
    
    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()
            
            if vm.isLoading {
                ProgressView()
                    .tint(.alefFitness)
            } else if vm.workouts.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // ── Filter chips ──────────────────
                        filterChips
                            .padding(.top, 8)
                            .padding(.horizontal, AlefLayout.horizontalPadding)
                        
                        // ── Workout cards ──────────────────────────
                        workoutList
                            .padding(.top, 20)
                            .padding(.horizontal, AlefLayout.horizontalPadding)
                            .padding(.bottom, 100)
                    }
                }
            }
            
            // ── FAB ──────────────────────────────────────────────
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        Haptics.medium()
                        vm.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.alefBg)
                            .frame(width: 56, height: 56)
                            .background(Color.alefFitness)
                            .clipShape(Circle())
                            .shadow(color: Color.alefFitness.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.trailing, AlefLayout.horizontalPadding)
                    .padding(.bottom, 24)
                }
            }
        }
        .task {
            vm.token = authToken
            await vm.fetchWorkouts()
        }
        .refreshable {
            await vm.fetchWorkouts()
        }
        .sheet(isPresented: $vm.showCreateSheet) {
            CreateWorkoutView(vm: vm)
        }
    }
    
    // MARK: - Filter Chips
    
    /// Horizontal scrolling row of workout type filters.
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOptions.indices, id: \.self) { index in
                    let filter = filterOptions[index]
                    let isSelected = vm.selectedFilter == filter
                    
                    Button {
                        Haptics.selection()
                        withAnimation(.spring(response: 0.3)) {
                            vm.selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if let filter = filter {
                                Image(systemName: filter.icon)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(filter?.label ?? "All")
                                .font(AlefFont.semibold(14))
                        }
                        .foregroundColor(isSelected ? .alefBg : .alefText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.alefFitness : Color.alefSurface)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Workout List
    
    /// List of workout cards filtered by selected type.
    private var workoutList: some View {
        LazyVStack(spacing: AlefLayout.itemSpacing) {
            ForEach(vm.filteredWorkouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workoutId: workout.id, vm: vm)) {
                    WorkoutCard(workout: workout)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        // Edit action — TODO: implement edit sheet
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        Task {
                            await vm.deleteWorkout(id: workout.id)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.alefFitness.opacity(0.3))
            
            Text("No workouts yet")
                .font(AlefFont.bold(20))
                .foregroundColor(.alefText)
            
            Text("Tap + to log your first workout")
                .font(AlefFont.regular(15))
                .foregroundColor(.alefTextSecondary)
        }
    }
}

// MARK: - Workout Card

/// Individual workout card shown in the list.
private struct WorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        HStack(spacing: 16) {
            // ── Icon ──────────────────
            Image(systemName: workout.workoutType.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.alefFitness)
                .frame(width: 48, height: 48)
                .background(Color.alefFitness.opacity(0.15))
                .cornerRadius(12)
            
            // ── Details ──────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutType.label)
                    .font(AlefFont.semibold(16))
                    .foregroundColor(.alefText)
                
                HStack(spacing: 12) {
                    // Duration
                    if let duration = workout.durationMin {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text("\(duration) min")
                                .font(AlefFont.regular(13))
                        }
                        .foregroundColor(.alefTextSecondary)
                    }
                    
                    // Calories
                    if let calories = workout.caloriesBurned {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                            Text("\(calories) kcal")
                                .font(AlefFont.regular(13))
                        }
                        .foregroundColor(.alefTextSecondary)
                    }
                    
                    // Distance
                    if let distance = workout.distanceKm {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text(String(format: "%.1f km", distance))
                                .font(AlefFont.regular(13))
                        }
                        .foregroundColor(.alefTextSecondary)
                    }
                }
            }
            
            Spacer()
            
            // ── Date ──────────────────
            Text(formattedDate(workout.date))
                .font(AlefFont.medium(12))
                .foregroundColor(.alefTextTertiary)
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}
