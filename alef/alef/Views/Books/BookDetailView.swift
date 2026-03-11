//
//  BookDetailView.swift
//  alef
//
//  Book detail screen — view and edit book details, rating, progress.
//
//  Layout:
//  - Large cover image
//  - Title, author, year
//  - Status picker (Want to Read / Reading / Completed / Dropped)
//  - Reading progress slider (0-100%)
//  - Star rating (1-5 stars → 1-10 internally)
//  - Review text area
//  - Delete option
//

import SwiftUI

struct BookDetailView: View {
    let bookId: String
    
    @AppStorage("authToken") private var authToken = ""
    
    private let mediaService = MediaService.shared
    
    @State private var book: MediaItem?
    @State private var isLoading = true
    @State private var showDeleteAlert = false
    
    // Editable fields
    @State private var selectedStatus = "watchlist"
    @State private var progress: Double = 0
    @State private var rating: Double = 0
    @State private var review = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()
            
            if isLoading {
                ProgressView().tint(.alefBooks)
            } else if let book = book {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AlefLayout.sectionSpacing) {
                        // Cover image
                        coverSection(book: book)
                        
                        // Book info
                        bookInfoSection(book: book)
                        
                        // Status picker
                        statusSection
                        
                        // Reading progress (show only when reading)
                        if selectedStatus == "watching" {
                            progressSection
                        }
                        
                        // Rating
                        ratingSection
                        
                        // Review
                        reviewSection
                        
                        // Delete button
                        deleteButton
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 16)
                }
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBook()
        }
        .alert("Delete this book?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteBook()
                }
            }
        } message: {
            Text("This will remove the book from your collection.")
        }
    }
    
    // MARK: - Cover Section
    
    private func coverSection(book: MediaItem) -> some View {
        Group {
            if let posterUrl = book.posterUrl, let url = URL(string: posterUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fit)
                    } else {
                        placeholderCover
                    }
                }
            } else {
                placeholderCover
            }
        }
        .frame(maxWidth: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        .padding(.top, 8)
    }
    
    private var placeholderCover: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.alefSurfaceSecondary)
            .aspectRatio(2/3, contentMode: .fit)
            .frame(maxWidth: 200)
            .overlay(
                Image(systemName: "book")
                    .font(.system(size: 48))
                    .foregroundColor(.alefTextTertiary)
            )
    }
    
    // MARK: - Book Info
    
    private func bookInfoSection(book: MediaItem) -> some View {
        VStack(spacing: 8) {
            Text(book.title)
                .font(AlefFont.bold(24))
                .foregroundColor(.alefText)
                .multilineTextAlignment(.center)
            
            if let externalId = book.externalId {
                Text("OLID: \(externalId)")
                    .font(AlefFont.medium(13))
                    .foregroundColor(.alefTextTertiary)
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATUS")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            Picker("Status", selection: $selectedStatus) {
                Text("Want to Read").tag("watchlist")
                Text("Reading").tag("watching")
                Text("Completed").tag("completed")
                Text("Dropped").tag("dropped")
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedStatus) { oldValue, newValue in
                Haptics.selection()
                Task { await saveChanges() }
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .clipShape(RoundedRectangle(cornerRadius: AlefLayout.cardRadius))
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("READING PROGRESS")
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
                    .tracking(1)
                
                Spacer()
                
                Text("\(Int(progress))%")
                    .font(AlefFont.Rounded.bold(16))
                    .foregroundColor(.alefBooks)
            }
            
            Slider(value: $progress, in: 0...100, step: 1)
                .tint(.alefBooks)
                .onChange(of: progress) { oldValue, newValue in
                    // Debounce: only save after user stops dragging
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        if progress == newValue {
                            await saveChanges()
                        }
                    }
                }
        }
        .padding(16)
        .background(Color.alefSurface)
        .clipShape(RoundedRectangle(cornerRadius: AlefLayout.cardRadius))
    }
    
    // MARK: - Rating Section
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RATING")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { index in
                    Button {
                        Haptics.selection()
                        // Allow deselecting by tapping the same star
                        if rating == Double(index) {
                            rating = 0
                        } else {
                            rating = Double(index)
                        }
                        Task { await saveChanges() }
                    } label: {
                        Image(systemName: rating >= Double(index) ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(rating >= Double(index) ? .alefMovies : .alefTextTertiary)
                    }
                }
                
                if rating > 0 {
                    Text("\(Int(rating))/5")
                        .font(AlefFont.Rounded.bold(18))
                        .foregroundColor(.alefText)
                        .padding(.leading, 8)
                }
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .clipShape(RoundedRectangle(cornerRadius: AlefLayout.cardRadius))
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
                .frame(minHeight: 120)
                .padding(12)
                .background(Color.alefBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: review) { oldValue, newValue in
                    // Debounced save
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        if review == newValue {
                            await saveChanges()
                        }
                    }
                }
        }
        .padding(16)
        .background(Color.alefSurface)
        .clipShape(RoundedRectangle(cornerRadius: AlefLayout.cardRadius))
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Text("Remove from Collection")
                .font(AlefFont.medium(15))
                .foregroundColor(.alefError)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.alefError.opacity(0.08))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Data
    
    private func loadBook() async {
        isLoading = true
        do {
            book = try await mediaService.fetch(id: bookId, token: authToken)
            if let book = book {
                selectedStatus = book.status
                progress = Double(book.progress ?? 0)
                rating = book.displayRating ?? 0
                review = book.review ?? ""
            }
        } catch {
            print("Error loading book: \(error)")
        }
        isLoading = false
    }
    
    private func saveChanges() async {
        guard book != nil else { return }
        
        // Convert 1-5 star rating to 1-10 internal rating
        let internalRating = rating > 0 ? Int(rating * 2) : nil
        
        let body = UpdateMediaBody(
            status: selectedStatus,
            rating: internalRating,
            review: review.isEmpty ? nil : review,
            progress: Int(progress),
            startedAt: nil,
            completedAt: nil
        )
        
        do {
            book = try await mediaService.update(id: bookId, body, token: authToken)
            Haptics.success()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
    
    private func deleteBook() async {
        do {
            try await mediaService.delete(id: bookId, token: authToken)
            Haptics.success()
            dismiss()
        } catch {
            print("Error deleting book: \(error)")
        }
    }
}
