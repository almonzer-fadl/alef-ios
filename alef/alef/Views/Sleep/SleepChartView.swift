//
//  SleepChartView.swift
//  alef
//
//  Weekly sleep trend chart — bar chart with quality colour coding.
//
//  Shows last 7 days of sleep with:
//  - Bar chart for sleep hours
//  - Average line
//  - Colour coding (green 7-9h, yellow 6-7h/9+, red <6h)
//

import SwiftUI
import Combine

struct SleepChartView: View {
    @AppStorage("authToken") private var authToken = ""
    
    @State private var recentLogs: [HealthLog] = []
    @State private var isLoading = true
    
    private let service = HealthService()
    
    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AlefLayout.sectionSpacing) {
                    
                    // ── Header ──────────────────────────────────
                    headerSection
                        .padding(.top, 16)
                    
                    // ── Stats card ──────────────────────────────
                    statsCard
                    
                    // ── Bar chart ───────────────────────────────
                    chartCard
                    
                    // ── Legend ──────────────────────────────────
                    legendCard
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
            }
        }
        .navigationTitle("Sleep Trends")
        .task { await loadData() }
        .refreshable { await loadData() }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LAST 7 DAYS")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            Text("Sleep Trends")
                .font(AlefFont.bold(24))
                .foregroundColor(.alefText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        HStack(spacing: 20) {
            // Average sleep
            VStack(spacing: 4) {
                Text(String(format: "%.1fh", averageSleepHours))
                    .font(AlefFont.Rounded.bold(32))
                    .foregroundColor(.alefText)
                Text("avg sleep")
                    .font(AlefFont.medium(13))
                    .foregroundColor(.alefTextSecondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 50)
                .background(Color.alefBorder)
            
            // Average quality
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", averageQuality))
                        .font(AlefFont.Rounded.bold(32))
                        .foregroundColor(.alefText)
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.alefSleep)
                        .offset(y: 4)
                }
                Text("avg quality")
                    .font(AlefFont.medium(13))
                    .foregroundColor(.alefTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    // MARK: - Chart Card
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SLEEP DURATION")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            // Chart
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    // Average line
                    if averageSleepHours > 0 {
                        Path { path in
                            let y = chartHeight(for: averageSleepHours, maxHeight: geo.size.height)
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                        .stroke(Color.alefSleep.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                    
                    // Bars
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(last7Days, id: \.date) { dayData in
                            VStack(spacing: 8) {
                                // Bar
                                if let hours = dayData.sleepHours {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(sleepColor(hours: hours))
                                        .frame(height: chartHeight(for: hours, maxHeight: geo.size.height))
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.alefSurfaceSecondary.opacity(0.3))
                                        .frame(height: 20)
                                }
                                
                                // Day label
                                Text(dayData.dayLabel)
                                    .font(AlefFont.medium(11))
                                    .foregroundColor(.alefTextTertiary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    // MARK: - Legend Card
    
    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUALITY ZONES")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            
            VStack(spacing: 8) {
                legendRow(color: .alefSuccess, label: "Optimal", range: "7-9 hours")
                legendRow(color: .alefWarning, label: "Acceptable", range: "6-7h or 9+ hours")
                legendRow(color: .alefError, label: "Insufficient", range: "< 6 hours")
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    private func legendRow(color: Color, label: String, range: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AlefFont.semibold(14))
                    .foregroundColor(.alefText)
                Text(range)
                    .font(AlefFont.regular(12))
                    .foregroundColor(.alefTextSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Data
    
    private func loadData() async {
        isLoading = true
        
        do {
            recentLogs = try await service.fetchRecent(token: authToken, limit: 30)
                .filter { $0.sleepHours != nil }
                .sorted { $0.date > $1.date }
        } catch {
            print("Failed to load sleep data: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    private var last7Days: [DayData] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).reversed().map { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return DayData(date: "", dayLabel: "", sleepHours: nil)
            }
            
            let dateFormatter = ISO8601DateFormatter()
            let dateString = String(dateFormatter.string(from: date).prefix(10))
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"
            let dayLabel = dayFormatter.string(from: date).uppercased()
            
            let log = recentLogs.first { $0.date.hasPrefix(dateString) }
            
            return DayData(date: dateString, dayLabel: dayLabel, sleepHours: log?.sleepHours)
        }
    }
    
    private var averageSleepHours: Double {
        let validLogs = last7Days.compactMap { $0.sleepHours }
        guard !validLogs.isEmpty else { return 0 }
        return validLogs.reduce(0, +) / Double(validLogs.count)
    }
    
    private var averageQuality: Double {
        let validQualities = recentLogs.prefix(7).compactMap { $0.sleepQuality }
        guard !validQualities.isEmpty else { return 0 }
        return Double(validQualities.reduce(0, +)) / Double(validQualities.count)
    }
    
    // MARK: - Helpers
    
    private func sleepColor(hours: Double) -> Color {
        if hours >= 7 && hours <= 9 {
            return .alefSuccess
        } else if (hours >= 6 && hours < 7) || hours > 9 {
            return .alefWarning
        } else {
            return .alefError
        }
    }
    
    private func chartHeight(for hours: Double, maxHeight: CGFloat) -> CGFloat {
        let maxHours: Double = 10
        let minHeight: CGFloat = 10
        let height = (maxHeight - 40) * CGFloat(hours / maxHours)
        return max(height, minHeight)
    }
}

// MARK: - Supporting Types

private struct DayData {
    let date: String
    let dayLabel: String
    let sleepHours: Double?
}
