//
//  RemindersViewModel.swift
//  alef
//
//  State management for the Reminders module.
//
//  Handles fetching reminders, lists, smart list counts,
//  creating/updating/deleting reminders and lists,
//  and toggling completion status.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class RemindersViewModel: ObservableObject {

    @Published var reminders: [Reminder] = []
    @Published var lists: [ReminderListWithCount] = []
    @Published var smartListCounts: SmartListCounts = SmartListCounts(today: 0, upcoming: 0, all: 0, flagged: 0)

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = ReminderService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Fetch

    /// Load all lists and smart list counts.
    func loadLists(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.fetchLists(token: token)
            lists = response.lists
            smartListCounts = response.smartLists
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load reminders for a specific view (smart list or user list).
    func loadReminders(
        token: String,
        listId: String? = nil,
        completed: Bool? = false,
        flagged: Bool? = nil,
        due: String? = nil
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            reminders = try await service.fetchAll(
                token: token,
                listId: listId,
                completed: completed,
                flagged: flagged,
                due: due
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load reminders due today.
    func loadToday(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.fetchToday(token: token)
            reminders = response.reminders
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load reminders due in the next 7 days.
    func loadUpcoming(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.fetchUpcoming(token: token)
            reminders = response.reminders
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Create

    /// Create a new reminder.
    func createReminder(
        title: String,
        notes: String? = nil,
        listId: String? = nil,
        priority: Int = 0,
        dueDate: String? = nil,
        dueTime: String? = nil,
        recurrence: String? = nil,
        flagged: Bool = false,
        url: String? = nil,
        token: String
    ) async -> Bool {
        errorMessage = nil

        let body = CreateReminderBody(
            title: title,
            notes: notes,
            listId: listId,
            priority: priority,
            dueDate: dueDate,
            dueTime: dueTime,
            recurrence: recurrence,
            flagged: flagged,
            url: url
        )

        do {
            let reminder = try await service.create(body, token: token)
            reminders.insert(reminder, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Create a new reminder list.
    func createList(
        name: String,
        icon: String = "list.bullet",
        color: String = "#60A5FA",
        token: String
    ) async -> Bool {
        errorMessage = nil

        let body = CreateListBody(name: name, icon: icon, color: color, sortOrder: lists.count)

        do {
            let list = try await service.createList(body, token: token)
            let listWithCount = ReminderListWithCount(
                id: list.id,
                userId: list.userId,
                name: list.name,
                icon: list.icon,
                color: list.color,
                sortOrder: list.sortOrder,
                createdAt: list.createdAt,
                count: 0
            )
            lists.append(listWithCount)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Update

    /// Toggle completion status of a reminder.
    func toggleCompletion(reminder: Reminder, token: String) async {
        let newStatus = !reminder.isCompleted

        do {
            let updated = try await service.toggleCompletion(
                id: reminder.id,
                isCompleted: newStatus,
                token: token
            )

            // Update local state
            if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                reminders[index] = updated
            }

            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    /// Update a reminder.
    func updateReminder(
        id: String,
        title: String? = nil,
        notes: String? = nil,
        listId: String? = nil,
        priority: Int? = nil,
        dueDate: String? = nil,
        dueTime: String? = nil,
        recurrence: String? = nil,
        flagged: Bool? = nil,
        url: String? = nil,
        token: String
    ) async -> Bool {
        errorMessage = nil

        let body = UpdateReminderBody(
            title: title,
            notes: notes,
            listId: listId,
            priority: priority,
            dueDate: dueDate,
            dueTime: dueTime,
            recurrence: recurrence,
            flagged: flagged,
            url: url
        )

        do {
            let updated = try await service.update(id: id, body: body, token: token)
            if let index = reminders.firstIndex(where: { $0.id == id }) {
                reminders[index] = updated
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Delete

    /// Delete a reminder.
    func deleteReminder(id: String, token: String) async {
        errorMessage = nil

        do {
            try await service.delete(id: id, token: token)
            reminders.removeAll(where: { $0.id == id })
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    /// Delete a reminder list.
    func deleteList(id: String, token: String) async {
        errorMessage = nil

        do {
            try await service.deleteList(id: id, token: token)
            lists.removeAll(where: { $0.id == id })
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}
