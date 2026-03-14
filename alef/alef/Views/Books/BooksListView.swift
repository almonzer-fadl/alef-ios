//
//  BooksListView.swift
//  alef
//
//  Main Books screen — shows user's reading collection with status filters.
//
//  Layout:
//  - Status filter chips (All / Reading / Want to Read / Completed / Dropped)
//  - Book cards in list format (cover + title + author + progress + rating)
//  - FAB to search and add new books
//  - Pull-to-refresh
//

import SwiftUI

struct BooksListView: View {
    @StateObject private var viewModel = BookViewModel()
    @AppStorage("authToken") private var authToken = ""
    
    @State private var showSearchSheet = false
    
    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.books.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Status filter chips
                        statusFilterRow
                            .padding(.top, 12)
                            .padding(.horizontal, AlefLayout.horizontalPadding)
                        
                        // Book cards
                        LazyVStack(spacing: AlefLayout.itemSpacing) {
                            ForEach(viewModel.books) { book in
                                NavigationLink(destination: BookDetailView(bookId: book.id)) {
                                    BookCard(book: book)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showSearchSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.alefBg)
                            .frame(width: 56, height: 56)
                            .background(Color.alefBooks)
                            .clipShape(Circle())
                            .shadow(color: Color.alefBooks.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.trailing, AlefLayout.horizontalPadding)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Books")
        .task {
            viewModel.token = authToken
            await viewModel.fetchBooks()
        }
        .refreshable {
            await viewModel.fetchBooks()
        }
        .sheet(isPresented: $showSearchSheet) {
            BookSearchView()
        }
    }
    
    // MARK: - Status Filter Row
    
    private var statusFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                StatusChip(
                    label: "All",
                    isSelected: viewModel.selectedStatus == nil,
                    color: .alefBooks
                ) {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedStatus = nil
                    }
                    Task { await viewModel.fetchBooks() }
                }
                
                StatusChip(
                    label: "Want to Read",
                    isSelected: viewModel.selectedStatus == "watchlist",
                    color: .alefBooks
                ) {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedStatus = "watchlist"
                    }
                    Task { await viewModel.fetchBooks() }
                }
                
                StatusChip(
                    label: "Reading",
                    isSelected: viewModel.selectedStatus == "watching",
                    color: .alefBooks
                ) {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedStatus = "watching"
                    }
                    Task { await viewModel.fetchBooks() }
                }
                
                StatusChip(
                    label: "Completed",
                    isSelected: viewModel.selectedStatus == "completed",
                    color: .alefBooks
                ) {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedStatus = "completed"
                    }
                    Task { await viewModel.fetchBooks() }
                }
                
                StatusChip(
                    label: "Dropped",
                    isSelected: viewModel.selectedStatus == "dropped",
                    color: .alefBooks
                ) {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedStatus = "dropped"
                    }
                    Task { await viewModel.fetchBooks() }
                }
            }
        }
    }
    
    // MARK: - Book Card
    
    private struct BookCard: View {
        let book: MediaItem
        
        var body: some View {
            HStack(spacing: 12) {
                // Cover thumbnail
                Group {
                    if let posterUrl = book.posterUrl, let url = URL(string: posterUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(2/3, contentMode: .fill)
                            } else {
                                placeholderCover
                            }
                        }
                    } else {
                        placeholderCover
                    }
                }
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(book.title)
                        .font(AlefFont.semibold(16))
                        .foregroundColor(.alefText)
                        .lineLimit(2)
                    
                    // Status
                    Text(Self.statusLabel(book.status))
                        .font(AlefFont.medium(12))
                        .foregroundColor(.alefBooks)
                    
                    // Progress bar (if reading)
                    if let progress = book.progress, book.status == "watching" {
                        ProgressView(value: Double(progress), total: 100)
                            .tint(.alefBooks)
                            .frame(height: 4)
                    }
                    
                    // Rating (if exists)
                    if let rating = book.displayRating {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: starIcon(index: index, rating: rating))
                                    .font(.system(size: 12))
                                    .foregroundColor(.alefBooks)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color.alefSurface)
            .clipShape(RoundedRectangle(cornerRadius: AlefLayout.cardRadius))
        }
        
        private var placeholderCover: some View {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.alefSurfaceSecondary)
                .overlay(
                    Image(systemName: "book")
                        .font(.system(size: 24))
                        .foregroundColor(.alefTextTertiary)
                )
        }
        
        private func starIcon(index: Int, rating: Double) -> String {
            if rating >= Double(index) + 1 {
                return "star.fill"
            } else if rating >= Double(index) + 0.5 {
                return "star.leadinghalf.filled"
            } else {
                return "star"
            }
        }
        
        static func statusLabel(_ status: String) -> String {
            switch status {
            case "watchlist": return "Want to Read"
            case "watching": return "Reading"
            case "completed": return "Completed"
            case "dropped": return "Dropped"
            default: return status.capitalized
            }
        }
    }
    
    // MARK: - Status Chip
    
    private struct StatusChip: View {
        let label: String
        let isSelected: Bool
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(label)
                    .font(AlefFont.medium(13))
                    .foregroundColor(isSelected ? .alefBg : .alefTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isSelected ? color : Color.alefSurface)
                    )
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AlefLayout.itemSpacing) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonView.bookCard
                }
            }
            .padding(.horizontal, AlefLayout.horizontalPadding)
            .padding(.top, 60)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.alefBooks.opacity(0.3))
            
            Text("No books yet")
                .font(AlefFont.bold(20))
                .foregroundColor(.alefText)
            
            Text("Tap + to add your first book")
                .font(AlefFont.regular(15))
                .foregroundColor(.alefTextSecondary)
        }
    }
    
}

// MARK: - Skeleton Views

extension SkeletonView {
    static var bookCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.alefSurfaceSecondary.opacity(0.3))
                .frame(width: 60, height: 90)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.alefSurfaceSecondary.opacity(0.3))
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.alefSurfaceSecondary.opacity(0.2))
                    .frame(width: 100, height: 12)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.alefSurface)
        .clipShape(RoundedRectangle(cornerRadius: AlefLayout.cardRadius))
    }
}
