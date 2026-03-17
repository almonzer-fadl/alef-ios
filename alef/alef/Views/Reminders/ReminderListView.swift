//
//  ReminderListView.swift
//  alef
//
//  Displays reminders in a specific list or smart list.
//
//  Features:
//  - List of reminder rows with completion circles
//  - Completion toggle (tap circle)
//  - Due date badges, priority indicators, flags
//  - Collapsible "Completed" section
//  - Inline "New Reminder" creation
//  - Pull-to-refresh
//  - Swipe to delete
//

import SwiftUI

enum ReminderFilterType {
    case today
    case upcoming
    case all
    case flagged
    case list(id: String)
}

struct ReminderListView: View {

    let title: String
    let filterType: ReminderFilterType
    let accentColor: Color

    @StateObject private var viewModel = RemindersViewModel()
    @AppStorage("authToken") private var authToken = ""

    @State private var showingCreateReminder = false
    @State private var showCompletedSection = true

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // Incomplete reminders
                    if incompletedReminders.isEmpty && completedReminders.isEmpty {
                        emptyState
                    } else {
                        ForEach(incompletedReminders) { reminder in
                            reminderRow(reminder: reminder)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteReminder(id: reminder.id, token: authToken)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }

                        // Completed Section
                        if !completedReminders.isEmpty {
                            completedSectionHeader
                            if showCompletedSection {
                                ForEach(completedReminders) { reminder in
                                    reminderRow(reminder: reminder)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task {
                                                    await viewModel.deleteReminder(id: reminder.id, token: authToken)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }

                    // New Reminder Button
                    newReminderButton
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
                .padding(.top, 12)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadReminders()
        }
        .refreshable {
            await loadReminders()
        }
        .sheet(isPresented: $showingCreateReminder) {
            CreateReminderView(
                viewModel: viewModel,
                listId: listIdForFilter,
                accentColor: accentColor
            )
        }
    }

    // MARK: - Computed Properties

    private var incompletedReminders: [Reminder] {
        viewModel.reminders.filter { !$0.isCompleted }
    }

    private var completedReminders: [Reminder] {
        viewModel.reminders.filter { $0.isCompleted }
    }

    private var listIdForFilter: String? {
        if case .list(let id) = filterType {
            return id
        }
        return nil
    }

    // MARK: - Load Data

    private func loadReminders() async {
        switch filterType {
        case .today:
            await viewModel.loadToday(token: authToken)
        case .upcoming:
            await viewModel.loadUpcoming(token: authToken)
        case .all:
            await viewModel.loadReminders(token: authToken, completed: false)
        case .flagged:
            await viewModel.loadReminders(token: authToken, completed: false, flagged: true)
        case .list(let id):
            await viewModel.loadReminders(token: authToken, listId: id, completed: false)
        }
    }

    // MARK: - Reminder Row

    private func reminderRow(reminder: Reminder) -> some View {
        HStack(spacing: 12) {
            // Completion Circle
            Button {
                Task {
                    await viewModel.toggleCompletion(reminder: reminder, token: authToken)
                }
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(reminder.isCompleted ? .alefSuccess : accentColor)
            }
            .buttonStyle(PlainButtonStyle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    // Priority indicator
                    if reminder.priority > 0 {
                        Text(reminder.priorityEnum.icon)
                            .font(AlefFont.semibold(12))
                            .foregroundColor(reminder.priorityEnum.color)
                    }

                    Text(reminder.title)
                        .font(AlefFont.medium(16))
                        .foregroundColor(reminder.isCompleted ? .alefTextTertiary : .alefText)
                        .strikethrough(reminder.isCompleted)
                        .lineLimit(2)

                    Spacer()

                    // Flag
                    if reminder.flagged {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.alefDiet)
                    }
                }

                // Due date badge
                if let dueFormatted = reminder.dueDateFormatted {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(dueFormatted)
                            .font(AlefFont.regular(13))
                        if let time = reminder.dueTime {
                            Text(time)
                                .font(AlefFont.regular(13))
                        }
                    }
                    .foregroundColor(.alefTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.alefSurfaceSecondary)
                    .cornerRadius(6)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color.alefSurface)
        .cornerRadius(12)
        .padding(.bottom, 8)
    }

    // MARK: - Completed Section Header

    private var completedSectionHeader: some View {
        Button {
            withAnimation {
                showCompletedSection.toggle()
            }
            Haptics.light()
        } label: {
            HStack {
                Text("Completed")
                    .font(AlefFont.semibold(15))
                    .foregroundColor(.alefTextSecondary)

                Spacer()

                Image(systemName: showCompletedSection ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.alefTextSecondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - New Reminder Button

    private var newReminderButton: some View {
        Button {
            showingCreateReminder = true
            Haptics.light()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)

                Text("New Reminder")
                    .font(AlefFont.medium(16))
                    .foregroundColor(.alefText)

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color.alefSurface)
            .cornerRadius(12)
            .padding(.top, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(accentColor.opacity(0.4))
                .padding(.top, 60)

            Text("No reminders")
                .font(AlefFont.medium(18))
                .foregroundColor(.alefTextSecondary)

            Text("Tap below to create your first reminder")
                .font(AlefFont.regular(14))
                .foregroundColor(.alefTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }
}
