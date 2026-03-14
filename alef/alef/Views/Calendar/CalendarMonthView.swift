//
//  CalendarMonthView.swift
//  alef
//
//  The main Calendar screen — inspired by Apple Calendar.
//
//  Layout (top to bottom):
//  1. Month header — prev/next arrows, month name
//  2. Weekday labels (S M T W T F S)
//  3. Calendar grid — 7 columns, coloured dots for events
//  4. Selected day events — time-sorted list below the grid
//  5. FAB — floating + button to create new events
//
//  Interactions:
//  - Tap a day → highlights it, shows events for that day
//  - Swipe left/right → change months (TODO: add gesture)
//  - Tap FAB → open create event sheet
//

import SwiftUI
import Combine

struct CalendarMonthView: View {
    @StateObject private var vm = CalendarViewModel()
    @AppStorage("authToken") private var authToken = ""

    /// Controls the event detail sheet
    @State private var showEventDetail = false

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Month header ─────────────────────────
                    monthHeader
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                        .padding(.top, 8)

                    // ── Calendar grid ────────────────────────
                    VStack(spacing: 0) {
                        weekdayLabels
                            .padding(.top, 20)

                        calendarGrid
                            .padding(.top, 12)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)

                    // ── Selected day events ──────────────────
                    if !vm.selectedDayEvents.isEmpty {
                        DayEventsView(
                            events: vm.selectedDayEvents,
                            selectedDate: vm.selectedDate,
                            onEventTap: { event in
                                vm.selectedEvent = event
                                showEventDetail = true
                            }
                        )
                        .padding(.top, 24)
                    } else {
                        noEventsForDay
                            .padding(.top, 24)
                    }

                    Spacer(minLength: 100)
                }
            }

            // ── FAB ──────────────────────────────────────────────
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        vm.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.alefBg)
                            .frame(width: 56, height: 56)
                            .background(Color.alefCalendar)
                            .clipShape(Circle())
                            .shadow(color: Color.alefCalendar.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.trailing, AlefLayout.horizontalPadding)
                    .padding(.bottom, 24)
                }
            }
        }
        .task {
            vm.token = authToken
            await vm.fetchMonth()
        }
        .sheet(isPresented: $vm.showCreateSheet) {
            CreateEventView(vm: vm)
        }
        .sheet(isPresented: $showEventDetail) {
            if let event = vm.selectedEvent {
                EventDetailView(event: event, vm: vm)
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            // Previous month
            Button {
                vm.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.alefText)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Month name
            Text(vm.monthYearString)
                .font(AlefFont.semibold(20))
                .foregroundColor(.alefText)

            Spacer()

            // Next month
            Button {
                vm.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.alefText)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(AlefFont.medium(12))
                    .foregroundColor(.alefTextSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(vm.daysInMonth.indices, id: \.self) { index in
                if let date = vm.daysInMonth[index] {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(for date: Date) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: vm.selectedDate)
        let hasEvents = vm.hasEvents(on: date)

        return Button {
            vm.selectDay(date)
        } label: {
            VStack(spacing: 4) {
                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(AlefFont.Rounded.bold(16))
                    .foregroundColor(isSelected ? .alefBg : (isToday ? .alefCalendar : .alefText))
                    .frame(width: 32, height: 32)
                    .background(
                        isSelected
                            ? Color.alefCalendar
                            : (isToday ? Color.alefCalendar.opacity(0.15) : Color.clear)
                    )
                    .clipShape(Circle())

                // Event indicator dot
                if hasEvents {
                    Circle()
                        .fill(vm.eventColor(for: date))
                        .frame(width: 4, height: 4)
                } else {
                    Color.clear.frame(width: 4, height: 4)
                }
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    // MARK: - No Events

    private var noEventsForDay: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.alefTextTertiary)

            Text("No events")
                .font(AlefFont.medium(14))
                .foregroundColor(.alefTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
