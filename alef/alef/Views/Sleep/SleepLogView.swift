//
//  SleepLogView.swift
//  alef
//
//  Sleep tracking view — log bedtime, wake time, duration, and quality.
//
//  Layout:
//  1. Circular sleep clock showing bedtime→wake arc
//  2. Time pickers for bedtime and wake time
//  3. Sleep quality rating (1-5)
//  4. Recent sleep history (last 7 days)
//
//  Uses HealthService — sleep data lives in health_logs table.
//

import SwiftUI
import Combine

struct SleepLogView: View {
    @AppStorage("authToken") private var authToken = ""
    
    @State private var todayLog: HealthLog?
    @State private var recentLogs: [HealthLog] = []
    @State private var isLoading = true
    
    // Today's form fields
    @State private var bedtime = Date()
    @State private var wakeTime = Date()
    @State private var sleepQuality: Int = 3
    
    private let service = HealthService()
    
    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AlefLayout.sectionSpacing) {
                    
                    // ── Today's sleep ───────────────────────────
                    todaySection
                        .padding(.top, 16)
                    
                    // ── Circular sleep clock ────────────────────
                    sleepClockCard
                    
                    // ── Time pickers ────────────────────────────
                    timePickersCard
                    
                    // ── Sleep quality ───────────────────────────
                    qualitySection
                    
                    // ── Save button ─────────────────────────────
                    Button {
                        Task { await saveLog() }
                    } label: {
                        Text("Save Sleep Log")
                            .font(AlefFont.semibold(16))
                            .foregroundColor(.alefBg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.alefSleep)
                            .cornerRadius(AlefLayout.cardRadius)
                    }
                    
                    // ── Recent sleep history ────────────────────
                    if !recentLogs.isEmpty {
                        recentSection
                    }
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
            }
        }
        .navigationTitle("Sleep")
        .task { await loadData() }
        .refreshable { await loadData() }
    }
    
    // MARK: - Today's Section
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(todayFormatted)
                .font(AlefFont.regular(13))
                .foregroundColor(.alefTextTertiary)
            Text("Sleep Tracker")
                .font(AlefFont.bold(24))
                .foregroundColor(.alefText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Sleep Clock Card
    
    private var sleepClockCard: some View {
        VStack(spacing: 16) {
            // Circular clock face
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.alefSurfaceSecondary, lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                // Sleep arc
                Circle()
                    .trim(from: sleepArcStart, to: sleepArcEnd)
                    .stroke(Color.alefSleep, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                // Center display
                VStack(spacing: 4) {
                    Text(String(format: "%.1fh", calculatedSleepHours))
                        .font(AlefFont.Rounded.bold(40))
                        .foregroundColor(.alefText)
                    Text("sleep")
                        .font(AlefFont.medium(13))
                        .foregroundColor(.alefTextSecondary)
                }
            }
            
            // Time labels
            HStack {
                VStack(spacing: 4) {
                    Text("BEDTIME")
                        .font(AlefFont.medium(11))
                        .foregroundColor(.alefTextTertiary)
                        .tracking(1)
                    Text(bedtimeFormatted)
                        .font(AlefFont.Rounded.semibold(20))
                        .foregroundColor(.alefSleep)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.alefTextTertiary)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("WAKE TIME")
                        .font(AlefFont.medium(11))
                        .foregroundColor(.alefTextTertiary)
                        .tracking(1)
                    Text(wakeTimeFormatted)
                        .font(AlefFont.Rounded.semibold(20))
                        .foregroundColor(.alefSleep)
                }
            }
        }
        .padding(20)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    // MARK: - Time Pickers Card
    
    private var timePickersCard: some View {
        VStack(spacing: AlefLayout.itemSpacing) {
            // Bedtime picker
            VStack(alignment: .leading, spacing: 8) {
                Text("BEDTIME")
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
                    .tracking(1)
                
                DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .onChange(of: bedtime) { _, _ in
                        Haptics.selection()
                    }
            }
            
            Divider()
                .background(Color.alefBorder)
            
            // Wake time picker
            VStack(alignment: .leading, spacing: 8) {
                Text("WAKE TIME")
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
                    .tracking(1)
                
                DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .onChange(of: wakeTime) { _, _ in
                        Haptics.selection()
                    }
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    // MARK: - Quality Section
    
    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SLEEP QUALITY")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        sleepQuality = rating
                        Haptics.selection()
                    } label: {
                        Image(systemName: rating <= sleepQuality ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundColor(rating <= sleepQuality ? Color.alefSleep : Color.alefTextTertiary.opacity(0.3))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    // MARK: - Recent Section
    
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT SLEEP")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            VStack(spacing: 8) {
                ForEach(recentLogs.prefix(7)) { log in
                    if let sleepHours = log.sleepHours {
                        recentLogRow(log: log, hours: sleepHours)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    private func recentLogRow(log: HealthLog, hours: Double) -> some View {
        HStack(spacing: 12) {
            // Date
            Text(formatLogDate(log.date))
                .font(AlefFont.medium(13))
                .foregroundColor(.alefTextSecondary)
                .frame(width: 60, alignment: .leading)
            
            // Bar chart
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.alefSurfaceSecondary)
                    .frame(height: 24)
                
                // Sleep bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(sleepColor(hours: hours))
                    .frame(width: barWidth(hours: hours), height: 24)
            }
            
            // Hours label
            Text(String(format: "%.1fh", hours))
                .font(AlefFont.Rounded.semibold(13))
                .foregroundColor(.alefText)
                .frame(width: 40, alignment: .trailing)
            
            // Quality stars
            if let quality = log.sleepQuality {
                HStack(spacing: 2) {
                    ForEach(1...quality, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.alefSleep.opacity(0.6))
                    }
                }
            }
        }
    }
    
    // MARK: - Data
    
    private func loadData() async {
        isLoading = true
        
        do {
            // Fetch today's log
            let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
            todayLog = try await service.fetchByDate(date: String(today), token: authToken)
            
            // Load existing values
            if let log = todayLog {
                if let bedtimeStr = log.bedtime {
                    bedtime = parseTime(bedtimeStr) ?? Date()
                }
                if let wakeTimeStr = log.wakeTime {
                    wakeTime = parseTime(wakeTimeStr) ?? Date()
                }
                sleepQuality = log.sleepQuality ?? 3
            }
            
            // Fetch recent logs
            recentLogs = try await service.fetchRecent(token: authToken, limit: 30)
                .filter { $0.sleepHours != nil }
                .sorted { $0.date > $1.date }
            
        } catch {
            print("Failed to load sleep data: \(error)")
        }
        
        isLoading = false
    }
    
    private func saveLog() async {
        Haptics.light()
        
        let dateFormatter = ISO8601DateFormatter()
        let today = String(dateFormatter.string(from: Date()).prefix(10))
        
        let body = CreateHealthLogBody(
            date: today,
            sleepHours: calculatedSleepHours,
            sleepQuality: sleepQuality,
            bedtime: formatTimeForAPI(bedtime),
            wakeTime: formatTimeForAPI(wakeTime)
        )
        
        do {
            todayLog = try await service.upsert(body, token: authToken)
            Haptics.success()
            await loadData()
        } catch {
            print("Failed to save sleep log: \(error)")
            Haptics.error()
        }
    }
    
    // MARK: - Helpers
    
    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: Date())
    }
    
    private var bedtimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: bedtime)
    }
    
    private var wakeTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: wakeTime)
    }
    
    private var calculatedSleepHours: Double {
        var diff = wakeTime.timeIntervalSince(bedtime)
        
        // If wake time is earlier than bedtime, add 24 hours
        if diff < 0 {
            diff += 24 * 60 * 60
        }
        
        return diff / 3600.0
    }
    
    private var sleepArcStart: Double {
        let hour = Double(Calendar.current.component(.hour, from: bedtime))
        let minute = Double(Calendar.current.component(.minute, from: bedtime))
        return (hour + minute / 60.0) / 24.0
    }
    
    private var sleepArcEnd: Double {
        let hour = Double(Calendar.current.component(.hour, from: wakeTime))
        let minute = Double(Calendar.current.component(.minute, from: wakeTime))
        var end = (hour + minute / 60.0) / 24.0
        
        // Handle overnight sleep
        if end < sleepArcStart {
            end += 1.0
        }
        
        return end
    }
    
    private func formatTimeForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }
    
    private func formatLogDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        guard let date = inputFormatter.date(from: dateString + "T00:00:00Z") else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d"
        return outputFormatter.string(from: date)
    }
    
    private func sleepColor(hours: Double) -> Color {
        if hours >= 7 && hours <= 9 {
            return .alefSuccess
        } else if (hours >= 6 && hours < 7) || hours > 9 {
            return .alefWarning
        } else {
            return .alefError
        }
    }
    
    private func barWidth(hours: Double) -> CGFloat {
        let maxWidth: CGFloat = 120
        let maxHours: Double = 10
        return min(maxWidth * CGFloat(hours / maxHours), maxWidth)
    }
}
