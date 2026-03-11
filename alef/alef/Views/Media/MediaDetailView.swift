//
//  MediaDetailView.swift
//  alef
//
//  Detail view for a media item.
//  Edit status, rating, review, progress (for TV shows).
//

import SwiftUI

struct MediaDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("authToken") private var authToken = ""
    
    @State var item: MediaItem
    
    @State private var selectedStatus: MediaStatus
    @State private var rating: Int = 0
    @State private var review: String = ""
    @State private var progress: Double = 0
    @State private var showingDeleteConfirmation = false
    
    private let service = MediaService.shared
    
    init(item: MediaItem) {
        self.item = item
        _selectedStatus = State(initialValue: item.statusEnum)
        _rating = State(initialValue: item.rating ?? 0)
        _review = State(initialValue: item.review ?? "")
        _progress = State(initialValue: Double(item.progress ?? 0))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.alefBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Poster
                        posterSection
                        
                        // Title & Overview
                        titleSection
                        
                        // Status Picker
                        statusSection
                        
                        // Star Rating
                        ratingSection
                        
                        // Progress (for TV shows)
                        if item.typeEnum == .tv {
                            progressSection
                        }
                        
                        // Review
                        reviewSection
                        
                        // Delete Button
                        deleteButton
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.alefTextSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .foregroundColor(.alefMovies)
                    .font(AlefFont.semibold(17))
                }
            }
            .confirmationDialog(
                "Delete this item?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteItem()
                    }
                }
            }
        }
    }
    
    // MARK: - Poster Section
    
    private var posterSection: some View {
        Group {
            if let posterUrl = item.posterUrl, let url = URL(string: posterUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    posterPlaceholder
                }
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: AlefLayout.cardRadiusLarge))
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            } else {
                posterPlaceholder
                    .frame(height: 400)
            }
        }
        .padding(.top, 20)
    }
    
    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: AlefLayout.cardRadiusLarge)
            .fill(Color.alefSurfaceSecondary.opacity(0.3))
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 64))
                    .foregroundColor(.alefTextTertiary)
            )
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(AlefFont.bold(24))
                .foregroundColor(.alefText)
            
            // Type badge
            HStack(spacing: 8) {
                Image(systemName: item.typeEnum.icon)
                    .font(.system(size: 12))
                Text(item.typeEnum.label)
                    .font(AlefFont.medium(13))
            }
            .foregroundColor(.alefTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATUS")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            HStack(spacing: 8) {
                ForEach(MediaStatus.allCases, id: \.self) { status in
                    Button {
                        Haptics.selection()
                        selectedStatus = status
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: status.icon)
                                .font(.system(size: 18))
                            
                            Text(status.label)
                                .font(AlefFont.medium(11))
                        }
                        .foregroundColor(
                            selectedStatus == status ? .alefText : .alefTextSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedStatus == status
                                ? Color.alefMovies.opacity(0.2)
                                : Color.alefSurface
                        )
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Rating Section
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RATING")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        Haptics.selection()
                        rating = star * 2 // Convert 1-5 to 1-10
                    } label: {
                        Image(systemName: rating >= star * 2 ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(rating >= star * 2 ? .alefMovies : .alefTextTertiary)
                    }
                }
                
                if rating > 0 {
                    Button {
                        Haptics.light()
                        rating = 0
                    } label: {
                        Text("Clear")
                            .font(AlefFont.medium(13))
                            .foregroundColor(.alefTextSecondary)
                            .padding(.leading, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Section (TV Shows)
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PROGRESS")
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
                    .tracking(1)
                
                Spacer()
                
                Text("\(Int(progress))%")
                    .font(AlefFont.Rounded.semibold(15))
                    .foregroundColor(.alefMovies)
            }
            
            Slider(value: $progress, in: 0...100, step: 5)
                .tint(.alefMovies)
                .onChange(of: progress) { _ in
                    Haptics.light()
                }
        }
    }
    
    // MARK: - Review Section
    
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REVIEW")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            TextEditor(text: $review)
                .font(AlefFont.regular(15))
                .foregroundColor(.alefText)
                .scrollContentBackground(.hidden)
                .background(Color.alefSurface)
                .frame(height: 120)
                .padding(12)
                .background(Color.alefSurface)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            Text("Delete from Collection")
                .font(AlefFont.semibold(16))
                .foregroundColor(.alefError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.alefSurface)
                .cornerRadius(12)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Actions
    
    private func saveChanges() async {
        do {
            _ = try await service.updateMedia(
                id: item.id,
                status: selectedStatus,
                rating: rating > 0 ? rating : nil,
                review: review.isEmpty ? nil : review,
                progress: item.typeEnum == .tv ? Int(progress) : nil,
                token: authToken
            )
            
            Haptics.success()
            dismiss()
        } catch {
            print("Save error:", error)
        }
    }
    
    private func deleteItem() async {
        do {
            try await service.deleteMedia(id: item.id, token: authToken)
            Haptics.success()
            dismiss()
        } catch {
            print("Delete error:", error)
        }
    }
}
