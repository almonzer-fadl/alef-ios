//
//  EventDetailView.swift
//  alef
//
//  Displays full event details with edit and delete options.
//
//  Layout:
//  - Coloured header bar
//  - Event title
//  - Time range with icon
//  - Location with icon
//  - Recurrence info
//  - Reminder info
//  - Description
//  - Edit button
//  - Delete button (destructive)
//
//  Design: Similar to HabitDetailView structure
//

import SwiftUI

struct EventDetailView: View {
    let event: CalendarEvent
    @ObservedObject var vm: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.alefBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AlefLayout.sectionSpacing) {

                        // ── Coloured header bar ──────────────
                        Rectangle()
                            .fill(event.swiftUIColor)
                            .frame(height: 4)
                            .padding(.horizontal, AlefLayout.horizontalPadding)

                        // ── Title ────────────────────────────
                        Text(event.title)
                            .font(AlefFont.bold(28))
                            .foregroundColor(.alefText)
                            .padding(.horizontal, AlefLayout.horizontalPadding)

                        // ── Time ─────────────────────────────
                        detailRow(
                            icon: "clock.fill",
                            label: "Time",
                            value: event.timeRangeString
                        )

                        // ── Location ─────────────────────────
                        if let location = event.location, !location.isEmpty {
                            detailRow(
                                icon: "location.fill",
                                label: "Location",
                                value: location
                            )
                        }

                        // ── Recurrence ───────────────────────
                        if event.recurrenceType != .none {
                            detailRow(
                                icon: "repeat",
                                label: "Recurrence",
                                value: event.recurrenceType.label
                            )
                        }

                        // ── Reminder ─────────────────────────
                        if event.reminderType != .none {
                            detailRow(
                                icon: "bell.fill",
                                label: "Reminder",
                                value: event.reminderType.label
                            )
                        }

                        // ── Description ──────────────────────
                        if let description = event.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(AlefFont.medium(14))
                                    .foregroundColor(.alefTextSecondary)

                                Text(description)
                                    .font(AlefFont.regular(16))
                                    .foregroundColor(.alefText)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.alefSurface)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, AlefLayout.horizontalPadding)
                        }

                        // ── Edit button ──────────────────────
                        Button {
                            showEditSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Event")
                                    .font(AlefFont.semibold(16))
                            }
                            .foregroundColor(.alefText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.alefSurface)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                        .padding(.top, 8)

                        // ── Delete button ────────────────────
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Event")
                                    .font(AlefFont.semibold(16))
                            }
                            .foregroundColor(.alefError)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.alefSurface)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, AlefLayout.horizontalPadding)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.alefTextSecondary)
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditEventView(event: event, vm: vm)
            }
            .alert("Delete Event", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await vm.deleteEvent(id: event.id)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
        }
    }

    // MARK: - Detail Row

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(event.swiftUIColor)
                .frame(width: 32, height: 32)
                .background(event.swiftUIColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AlefFont.medium(12))
                    .foregroundColor(.alefTextSecondary)

                Text(value)
                    .font(AlefFont.regular(16))
                    .foregroundColor(.alefText)
            }

            Spacer()
        }
        .padding()
        .background(Color.alefSurface)
        .cornerRadius(12)
        .padding(.horizontal, AlefLayout.horizontalPadding)
    }
}
