//
//  CreateReminderView.swift
//  alef
//
//  Form to create or edit a reminder.
//
//  Fields:
//  - Title (required)
//  - Notes
//  - Date toggle + date picker
//  - Time toggle + time picker
//  - Priority picker (None, Low !, Medium !!, High !!!)
//  - Flag toggle
//  - List picker
//  - Recurrence picker (None, Daily, Weekly, Monthly, Yearly)
//  - URL field
//

import SwiftUI

struct CreateReminderView: View {

    @ObservedObject var viewModel: RemindersViewModel
    var listId: String?
    let accentColor: Color

    @AppStorage("authToken") private var authToken = ""
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasDueTime = false
    @State private var dueTime = Date()
    @State private var priority: ReminderPriority = .none
    @State private var flagged = false
    @State private var selectedListId: String?
    @State private var recurrence: ReminderRecurrence = .none
    @State private var url = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(AlefFont.medium(16))
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .font(AlefFont.regular(15))
                        .lineLimit(3...6)
                }

                Section(header: Text("Due Date")) {
                    Toggle("Date", isOn: $hasDueDate)
                        .font(AlefFont.regular(16))
                        .onChange(of: hasDueDate) { newValue in
                            Haptics.light()
                        }

                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }

                    Toggle("Time", isOn: $hasDueTime)
                        .font(AlefFont.regular(16))
                        .onChange(of: hasDueTime) { newValue in
                            Haptics.light()
                        }

                    if hasDueTime {
                        DatePicker("", selection: $dueTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(ReminderPriority.allCases, id: \.self) { p in
                            HStack {
                                if !p.icon.isEmpty {
                                    Text(p.icon)
                                        .foregroundColor(p.color)
                                }
                                Text(p.label)
                                    .font(AlefFont.regular(16))
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: priority) { _ in
                        Haptics.selection()
                    }
                }

                Section(header: Text("Options")) {
                    Toggle(isOn: $flagged) {
                        HStack {
                            Image(systemName: "flag.fill")
                                .foregroundColor(.alefDiet)
                            Text("Flag")
                                .font(AlefFont.regular(16))
                        }
                    }
                    .onChange(of: flagged) { _ in
                        Haptics.light()
                    }

                    Picker("Repeat", selection: $recurrence) {
                        ForEach(ReminderRecurrence.allCases, id: \.self) { rec in
                            Text(rec.label)
                                .font(AlefFont.regular(16))
                                .tag(rec)
                        }
                    }
                    .onChange(of: recurrence) { _ in
                        Haptics.selection()
                    }
                }

                Section(header: Text("List")) {
                    Picker("List", selection: $selectedListId) {
                        Text("None")
                            .tag(nil as String?)
                        ForEach(viewModel.lists) { list in
                            HStack {
                                Image(systemName: list.icon)
                                    .foregroundColor(list.swiftUIColor)
                                Text(list.name)
                                    .font(AlefFont.regular(16))
                            }
                            .tag(list.id as String?)
                        }
                    }
                    .onChange(of: selectedListId) { _ in
                        Haptics.selection()
                    }
                }

                Section(header: Text("URL")) {
                    TextField("https://example.com", text: $url)
                        .font(AlefFont.regular(15))
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.alefBg)
            .navigationTitle("New Reminder")
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
                            await createReminder()
                        }
                    }
                    .foregroundColor(accentColor)
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            selectedListId = listId
        }
    }

    private func createReminder() async {
        let dueDateStr: String? = hasDueDate ? formatDate(dueDate) : nil
        let dueTimeStr: String? = hasDueTime ? formatTime(dueTime) : nil
        let recurrenceStr: String? = recurrence == .none ? nil : recurrence.rawValue

        let success = await viewModel.createReminder(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            listId: selectedListId,
            priority: priority.rawValue,
            dueDate: dueDateStr,
            dueTime: dueTimeStr,
            recurrence: recurrenceStr,
            flagged: flagged,
            url: url.isEmpty ? nil : url,
            token: authToken
        )

        if success {
            Haptics.success()
            dismiss()
        } else {
            Haptics.error()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
