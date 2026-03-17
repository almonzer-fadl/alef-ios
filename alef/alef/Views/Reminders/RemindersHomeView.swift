//
//  RemindersHomeView.swift
//  alef
//
//  Main Reminders screen — Apple Reminders style.
//
//  Layout:
//  - Smart lists at top (2x2 grid of cards):
//    • Today (blue calendar) — count of due today
//    • Scheduled (red calendar.badge.clock) — count of upcoming
//    • All (gray tray.full) — total count
//    • Flagged (orange flag.fill) — count of flagged
//  - "My Lists" section with user-created lists
//  - Each list row: colored icon, name, reminder count
//  - Add List button at bottom
//

import SwiftUI

struct RemindersHomeView: View {

    @StateObject private var viewModel = RemindersViewModel()
    @AppStorage("authToken") private var authToken = ""

    @State private var showingCreateList = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AlefLayout.sectionSpacing) {

                    // Smart Lists Grid
                    smartListsGrid

                    // My Lists Section
                    myListsSection

                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
                .padding(.top, AlefLayout.sectionSpacing)
            }
            .background(Color.alefBg.ignoresSafeArea())
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateList = true
                        Haptics.light()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.alefReminders)
                    }
                }
            }
            .sheet(isPresented: $showingCreateList) {
                CreateListView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadLists(token: authToken)
            }
            .refreshable {
                await viewModel.loadLists(token: authToken)
            }
        }
    }

    // MARK: - Smart Lists Grid

    private var smartListsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            smartListCard(
                title: "Today",
                icon: "calendar",
                color: .alefReminders,
                count: viewModel.smartListCounts.today,
                destination: ReminderListView(
                    title: "Today",
                    filterType: .today,
                    accentColor: .alefReminders
                )
            )

            smartListCard(
                title: "Scheduled",
                icon: "calendar.badge.clock",
                color: .alefReminders.opacity(0.8),
                count: viewModel.smartListCounts.upcoming,
                destination: ReminderListView(
                    title: "Scheduled",
                    filterType: .upcoming,
                    accentColor: .alefReminders
                )
            )

            smartListCard(
                title: "All",
                icon: "tray.fill",
                color: .alefTextSecondary,
                count: viewModel.smartListCounts.all,
                destination: ReminderListView(
                    title: "All",
                    filterType: .all,
                    accentColor: .alefTextSecondary
                )
            )

            smartListCard(
                title: "Flagged",
                icon: "flag.fill",
                color: .alefReminders,
                count: viewModel.smartListCounts.flagged,
                destination: ReminderListView(
                    title: "Flagged",
                    filterType: .flagged,
                    accentColor: .alefReminders
                )
            )
        }
    }

    private func smartListCard<Destination: View>(
        title: String,
        icon: String,
        color: Color,
        count: Int,
        destination: Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                    Spacer()
                }

                Spacer()

                Text(title)
                    .font(AlefFont.medium(15))
                    .foregroundColor(.alefText)

                Text("\(count)")
                    .font(AlefFont.Rounded.bold(28))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 110)
            .padding(16)
            .background(Color.alefSurface)
            .cornerRadius(AlefLayout.cardRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - My Lists Section

    private var myListsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Lists")
                .font(AlefFont.bold(20))
                .foregroundColor(.alefText)
                .padding(.horizontal, 4)

            if viewModel.lists.isEmpty {
                emptyListsPlaceholder
            } else {
                ForEach(viewModel.lists) { list in
                    NavigationLink(destination: ReminderListView(
                        title: list.name,
                        filterType: .list(id: list.id),
                        accentColor: list.swiftUIColor
                    )) {
                        listRow(list: list)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func listRow(list: ReminderListWithCount) -> some View {
        HStack(spacing: 12) {
            Image(systemName: list.icon)
                .font(.system(size: 20))
                .foregroundColor(list.swiftUIColor)
                .frame(width: 32, height: 32)
                .background(list.swiftUIColor.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(list.name)
                    .font(AlefFont.medium(16))
                    .foregroundColor(.alefText)
            }

            Spacer()

            Text("\(list.count)")
                .font(AlefFont.Rounded.semibold(16))
                .foregroundColor(.alefTextSecondary)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.alefTextTertiary)
        }
        .padding(12)
        .background(Color.alefSurface)
        .cornerRadius(12)
    }

    private var emptyListsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 40))
                .foregroundColor(.alefTextTertiary)
                .padding(.top, 24)

            Text("No lists yet")
                .font(AlefFont.medium(16))
                .foregroundColor(.alefTextSecondary)

            Text("Tap + to create your first list")
                .font(AlefFont.regular(14))
                .foregroundColor(.alefTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
}

// MARK: - Create List Sheet

struct CreateListView: View {

    @ObservedObject var viewModel: RemindersViewModel
    @AppStorage("authToken") private var authToken = ""

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColor = Color.alefReminders
    @State private var selectedIcon = "list.bullet"

    private let colorOptions: [Color] = [
        .alefReminders, .alefHealth, .alefFitness, .alefDiet, .alefJournal,
        .alefProjects, .alefBooks, .alefMovies, .alefCalendar
    ]

    private let iconOptions = [
        "list.bullet", "checkmark.circle", "star.fill", "flag.fill",
        "cart.fill", "house.fill", "briefcase.fill", "book.fill"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("List name", text: $name)
                        .font(AlefFont.regular(16))
                }

                Section(header: Text("Icon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                Haptics.selection()
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedIcon == icon ? selectedColor : .alefTextSecondary)
                                    .frame(width: 60, height: 60)
                                    .background(selectedIcon == icon ? selectedColor.opacity(0.15) : Color.alefSurface)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button {
                                selectedColor = color
                                Haptics.selection()
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.alefBg)
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.alefTextSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            let colorHex = selectedColor.toHex() ?? "#F472B6"
                            let success = await viewModel.createList(
                                name: name,
                                icon: selectedIcon,
                                color: colorHex,
                                token: authToken
                            )
                            if success {
                                Haptics.success()
                                dismiss()
                            } else {
                                Haptics.error()
                            }
                        }
                    }
                    .foregroundColor(.alefReminders)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
