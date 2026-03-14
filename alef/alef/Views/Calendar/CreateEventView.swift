//
//  CreateEventView.swift
//  alef
//
//  Form to create a new calendar event.
//
//  Fields:
//  - Title (required)
//  - All-day toggle
//  - Start date/time picker
//  - End date/time picker
//  - Location
//  - Colour picker
//  - Recurrence picker (None, Daily, Weekly, Monthly, Yearly)
//  - Reminder picker (None, At time, 5/15/30 min, 1 hour)
//  - Description (multiline text)
//
//  Design: Matches AlefTheme, similar structure to CreateHabitView
//

import SwiftUI
import Combine

struct CreateEventView: View {
    @ObservedObject var vm: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var title = ""
    @State private var description = ""
    @State private var allDay = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // +1 hour
    @State private var location = ""
    @State private var selectedColor = Color.alefCalendar
    @State private var recurrence: EventRecurrence = .none
    @State private var reminder: EventReminder = .none

    /// Whether the form is being submitted
    @State private var isSubmitting = false

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
            .navigationTitle("New Event")
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
                await createEvent()
            }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.alefBg)
                } else {
                    Text("Create Event")
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

    // MARK: - Create Event

    private func createEvent() async {
        guard !title.isEmpty else { return }

        isSubmitting = true

        let formatter = ISO8601DateFormatter()
        let startTimeString = formatter.string(from: startDate)
        let endTimeString = formatter.string(from: endDate)

        // Convert color to hex
        let hexColor = selectedColor.toHex()

        let body = CreateEventBody(
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

        await vm.createEvent(body)
        isSubmitting = false

        if vm.error == nil {
            dismiss()
        }
    }
}
