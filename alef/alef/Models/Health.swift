//
//  Health.swift
//  alef
//
//  Data models for the Health module.
//
//  Maps to the backend `health_logs` table.
//  One log per day covering weight, hydration, sleep basics,
//  mood, and energy. Think of it as a daily health check-in.
//

import Foundation

// MARK: - Health Log

struct HealthLog: Codable, Identifiable {
    let id: String
    let userId: String
    let date: String
    var weight: Double?
    var waterMl: Int?
    var sleepHours: Double?
    var sleepQuality: Int?     // 1-5
    var bedtime: String?       // "23:30"
    var wakeTime: String?      // "07:00"
    var mood: Mood?
    var energyLevel: Int?      // 1-5
    var notes: String?
    let createdAt: String
    var updatedAt: String
}

// MARK: - API Response Wrappers

struct HealthLogsResponse: Codable {
    let logs: [HealthLog]
}

struct HealthLogResponse: Codable {
    let log: HealthLog
}

struct HealthLogNullable: Codable {
    let log: HealthLog?
}

// MARK: - Create/Update DTO

struct CreateHealthLogBody: Encodable {
    let date: String
    var weight: Double?
    var waterMl: Int?
    var sleepHours: Double?
    var sleepQuality: Int?
    var bedtime: String?
    var wakeTime: String?
    var mood: Mood?
    var energyLevel: Int?
    var notes: String?
}
