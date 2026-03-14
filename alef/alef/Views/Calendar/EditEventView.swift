//
//  EditEventView.swift
//  alef
//
//  Form to edit an existing calendar event.
//  Pre-fills all fields with the event's current values.
//
//  Design: Identical to CreateEventView, but Save button calls update API
//

import SwiftUI
import Combine

struct EditEventView: View {
    let event: CalendarEvent
    @ObservedObject var vm: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    // Form state (pre-filled)
    @State private var title: String
    @State private var description: String
    @State private var allDay: Bool
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location: String
    @State private var selectedColor: Color
    @State private var recurrence: EventRecurrence
    @State private var reminder: EventReminder

    @State private var isSubmitting = false

    init(event: CalendarEvent, vm: CalendarViewModel) {
        self.event = event
        self.vm = vm

        // Pre-fill form state
        _title = State(initialValue: event.title)
        _description = State(initialValue: event.description ?? "")
        _allDay = State(initialValue: event.isAllDay)
        _startDate = State(initialValue: event.startDate ?? Date())
        _endDate = State(initialValue: event.endDate ?? Date().addingTimeInterval(3600))
        _location = State(initialValue: event.location ?? "")
        _selectedColor = State(initialValue: event.swiftUIColor)
        _recurrence = State(initialValue: event.recurrenceType)
        _reminder = State(initialValue: event.reminderType)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.alefBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AlefLayout.sectionSpacing) {

                        // ── Title ────────────────────────────
                        formSection(title: "Title") {
                            TextField("Event title", text: $title)
                                .font(AlefFont.regular(16))
                                .foregroundColor(.alefText)
                                .padding()
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }

                        // ── All-day toggle ────────────────────
                        formSection(title: "All day") {
                            Toggle("", isOn: $allDay)
                                .tint(.alefCalendar)
                                .labelsHidden()
                        }

                        // ── Start date/time ───────────────────
                        formSection(title: "Starts") {
                            DatePicker(
                                "",
                                selection: $startDate,
                                displayedComponents: allDay ? [.date] : [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }

                        // ── End date/time ─────────────────────
                        formSection(title: "Ends") {
                            DatePicker(
                                "",
                                selection: $endDate,
                                displayedComponents: allDay ? [.date] : [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }

                        // ── Location ──────────────────────────
                        formSection(title: "Location") {
                            TextField("Add location", text: $location)
                                .font(AlefFont.regular(16))
                                .foregroundColor(.alefText)
                                .padding()
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }

                        // ── Colour picker ─────────────────────
                        formSection(title: "Colour") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                                ForEach(Color.alefPalette, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.alefText, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                            Haptics.selection()
                                        }
                                }
                            }
                        }

                        // ── Recurrence ────────────────────────
                        formSection(title: "Recurrence") {
                            Picker("", selection: $recurrence) {
                                ForEach(EventRecurrence.allCases, id: \.self) { option in
                                    Text(option.label).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.alefText)
                        }

                        // ── Reminder ──────────────────────────
                        formSection(title: "Reminder") {
                            Picker("", selection: $reminder) {
                                ForEach(EventReminder.allCases, id: \.self) { option in
                                    Text(option.label).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.alefText)
                        }

                        // ── Description ───────────────────────
                        formSection(title: "Description") {
                            TextEditor(text: $description)
                                .font(AlefFont.regular(16))
                                .foregroundColor(.alefText)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                                .scrollContentBackground(.hidden)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }

                // ── Save button ──────────────────────────────────
                VStack {
                    Spacer()
                    saveButton
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.alefTextSecondary)
                }
            }
        }
    }

    // MARK: - Form Section

    private func formSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AlefFont.medium(14))
                .foregroundColor(.alefTextSecondary)

            content()
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task {
                await updateEvent()
            }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.alefBg)
                } else {
                    Text("Save Changes")
                        .font(AlefFont.semibold(16))
                        .foregroundColor(.alefBg)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(title.isEmpty ? Color.alefSurfaceSecondary : Color.alefCalendar)
            .cornerRadius(16)
        }
        .disabled(title.isEmpty || isSubmitting)
    }

    // MARK: - Update Event

    private func updateEvent() async {
        guard !title.isEmpty else { return }

        isSubmitting = true

        let formatter = ISO8601DateFormatter()
        let startTimeString = formatter.string(from: startDate)
        let endTimeString = formatter.string(from: endDate)

        // Convert color to hex
        let hexColor = selectedColor.toHex()

        let body = UpdateEventBody(
            title: title,
            description: description.isEmpty ? nil : description,
            startTime: startTimeString,
            endTime: endTimeString,
            allDay: allDay,
            location: location.isEmpty ? nil : location,
            color: hexColor,
            recurrence: recurrence == .none ? nil : recurrence.rawValue,
            remindMinutes: reminder.minutes
        )

        await vm.updateEvent(id: event.id, body: body)
        isSubmitting = false

        if vm.error == nil {
            dismiss()
        }
    }
}
