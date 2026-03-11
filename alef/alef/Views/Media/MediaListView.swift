//
//  MediaListView.swift
//  alef
//
//  Main screen for Movies & TV module.
//  Shows poster grid with filters and search.
//

import SwiftUI

struct MediaListView: View {
    
    @StateObject private var viewModel = MediaViewModel()
    @AppStorage("authToken") private var authToken = ""
    
    @State private var showingSearch = false
    @State private var selectedItem: MediaItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.alefBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Type Picker: Movies | TV Shows
                    typePicker
                    
                    // Status Filter Chips
                    statusFilter
                    
                    // Content
                    if viewModel.isLoading && viewModel.items.isEmpty {
                        loadingState
                    } else if viewModel.hasItems {
                        posterGrid
                    } else {
                        emptyState
                    }
                }
            }
            .navigationTitle("Media")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.alefMovies)
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                MediaSearchView(mediaType: viewModel.selectedType)
            }
            .sheet(item: $selectedItem) { item in
                MediaDetailView(item: item)
            }
            .task {
                await viewModel.fetchMedia(token: authToken)
            }
        }
    }
    
    // MARK: - Type Picker
    
    private var typePicker: some View {
        HStack(spacing: 12) {
            ForEach([MediaType.movie, MediaType.tv], id: \.self) { type in
                Button {
                    Haptics.selection()
                    viewModel.selectedType = type
                    Task {
                        await viewModel.fetchMedia(token: authToken)
                    }
                } label: {
                    Text(type.label)
                        .font(AlefFont.semibold(16))
                        .foregroundColor(
                            viewModel.selectedType == type ? .alefText : .alefTextSecondary
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.selectedType == type
                                ? Color.alefMovies.opacity(0.2)
                                : Color.clear
                        )
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, AlefLayout.horizontalPadding)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Status Filter
    
    private var statusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All filter
                filterChip(label: "All", status: nil)
                
                // Status filters
                ForEach(MediaStatus.allCases, id: \.self) { status in
                    filterChip(label: status.label, status: status)
                }
            }
            .padding(.horizontal, AlefLayout.horizontalPadding)
        }
        .padding(.bottom, 12)
    }
    
    private func filterChip(label: String, status: MediaStatus?) -> some View {
        Button {
            Haptics.selection()
            viewModel.selectedStatus = status
            Task {
                await viewModel.fetchMedia(token: authToken)
            }
        } label: {
            Text(label)
                .font(AlefFont.medium(13))
                .foregroundColor(
                    viewModel.selectedStatus == status ? .alefText : .alefTextSecondary
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    viewModel.selectedStatus == status
                        ? Color.alefMovies.opacity(0.2)
                        : Color.alefSurface
                )
                .cornerRadius(8)
        }
    }
    
    // MARK: - Poster Grid
    
    private var posterGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 16
            ) {
                ForEach(viewModel.filteredItems) { item in
                    PosterCard(item: item)
                        .onTapGesture {
                            Haptics.medium()
                            selectedItem = item
                        }
                }
            }
            .padding(.horizontal, AlefLayout.horizontalPadding)
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.fetchMedia(token: authToken)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.selectedType == .movie ? "film" : "tv")
                .font(.system(size: 64))
                .foregroundColor(.alefTextTertiary)
            
            Text("No \(viewModel.selectedType.label)")
                .font(AlefFont.semibold(18))
                .foregroundColor(.alefTextSecondary)
            
            Text(emptyStateMessage)
                .font(AlefFont.regular(14))
                .foregroundColor(.alefTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingSearch = true
            } label: {
                Text("Add \(viewModel.selectedType == .movie ? "Movie" : "Show")")
                    .font(AlefFont.semibold(16))
                    .foregroundColor(.alefText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.alefMovies)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateMessage: String {
        if let status = viewModel.selectedStatus {
            return "No items in \(status.label.lowercased())"
        } else {
            return "Tap + to search and add \(viewModel.selectedType.label.lowercased())"
        }
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack {
            ProgressView()
                .tint(.alefMovies)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Poster Card

struct PosterCard: View {
    let item: MediaItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster Image
            if let posterUrl = item.posterUrl, let url = URL(string: posterUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    posterPlaceholder
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                posterPlaceholder
                    .frame(height: 240)
            }
            
            // Title
            Text(item.title)
                .font(AlefFont.semibold(14))
                .foregroundColor(.alefText)
                .lineLimit(2)
            
            // Rating Stars
            if let rating = item.displayRating {
                HStack(spacing: 3) {
                    ForEach(0..<5) { index in
                        Image(systemName: starIcon(for: index, rating: rating))
                            .font(.system(size: 12))
                            .foregroundColor(.alefMovies)
                    }
                }
            }
        }
    }
    
    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.alefSurfaceSecondary.opacity(0.3))
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 32))
                    .foregroundColor(.alefTextTertiary)
            )
    }
    
    private func starIcon(for index: Int, rating: Double) -> String {
        if rating >= Double(index) + 1 {
            return "star.fill"
        } else if rating >= Double(index) + 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}
