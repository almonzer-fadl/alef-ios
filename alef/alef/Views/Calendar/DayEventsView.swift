//
//  DayEventsView.swift
//  alef
//
//  Shows events for the selected day.
//
//  Layout:
//  - Section header with the selected date
//  - All-day events shown first in a separate section
//  - Timed events shown below, sorted by start time
//  - Each event card has a coloured left bar, title, time, location
//
//  Interactions:
//  - Tap an event → open detail view
//

import SwiftUI

struct DayEventsView: View {
    let events: [CalendarEvent]
    let selectedDate: Date
    let onEventTap: (CalendarEvent) -> Void

    var allDayEvents: [CalendarEvent] {
        events.filter { $0.isAllDay }
    }

    var timedEvents: [CalendarEvent] {
        events.filter { !$0.isAllDay }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            sectionHeader

            // All-day events
            if !allDayEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("All day")
                        .font(AlefFont.medium(12))
                        .foregroundColor(.alefTextSecondary)
                        .padding(.horizontal, AlefLayout.horizontalPadding)

                    ForEach(allDayEvents) { event in
                        eventCard(for: event)
                    }
                }
            }

            // Timed events
            if !timedEvents.isEmpty {
                if !allDayEvents.isEmpty {
                    Divider()
                        .background(Color.alefBorder)
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                }

                VStack(spacing: 8) {
                    ForEach(timedEvents) { event in
                        eventCard(for: event)
                    }
                }
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatter.string(from: selectedDate))
                    .font(AlefFont.semibold(18))
                    .foregroundColor(.alefText)

                Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                    .font(AlefFont.regular(14))
                    .foregroundColor(.alefTextSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, AlefLayout.horizontalPadding)
    }

    // MARK: - Event Card

    private func eventCard(for event: CalendarEvent) -> some View {
        Button {
            onEventTap(event)
        } label: {
            HStack(spacing: 0) {
                // Coloured left bar
                Rectangle()
                    .fill(event.swiftUIColor)
                    .frame(width: 4)

                // Event details
                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(event.title)
                        .font(AlefFont.semibold(16))
                        .foregroundColor(.alefText)
                        .lineLimit(2)

                    // Time range
                    Text(event.timeRangeString)
                        .font(AlefFont.regular(14))
                        .foregroundColor(.alefTextSecondary)

                    // Location
                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text(location)
                                .font(AlefFont.regular(13))
                        }
                        .foregroundColor(.alefTextTertiary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.alefTextTertiary)
                    .padding(.trailing, 16)
            }
            .background(Color.alefSurface)
            .cornerRadius(AlefLayout.cardRadius)
            .padding(.horizontal, AlefLayout.horizontalPadding)
        }
        .buttonStyle(.plain)
    }
}
