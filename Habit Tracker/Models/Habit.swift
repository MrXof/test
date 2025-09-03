
import Foundation
import SwiftData


@available(iOS 17, *)
@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    

    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date
    
    var weekdays: [Int]
    
    var reminderEnabled: Bool
    var reminderTime: Date?
    
    var completions: [Date]
    
    init(name: String,
         icon: String = "flame.fill",
         colorHex: String = "#4F46E5",
         createdAt: Date = .now,
         weekdays: [Int] = Weekday.allCases.map { $0.rawValue },
         reminderEnabled: Bool = false,
         reminderTime: Date? = nil,
         completions: [Date] = []) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.weekdays = weekdays
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.completions = completions
    }
}

@available(iOS 17, *)
extension Habit {
    func isScheduled(on date: Date) -> Bool {
        weekdays.contains(date.isoWeekday)
    }
    
    func hasCompletion(on date: Date) -> Bool {
        let d = date.startOfDay
        return completions.contains { Calendar.current.isDate($0, inSameDayAs: d) }
    }
    
    func toggleToday() {
        let today = Date().startOfDay
        if let idx = completions.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            completions.remove(at: idx)
        } else {
            completions.append(today)
        }
    }
    
    func currentStreak(reference: Date = .now) -> Int {
        var streak = 0
        var day = reference.startOfDay
        let cal = Calendar.current
        
        while true {
            if !isScheduled(on: day) {
                guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
                continue
            }
            
            if hasCompletion(on: day) {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            } else {
                break
            }
        }
        
        return streak
    }
    
    func weeklyProgress(weekOf reference: Date = .now) -> Double {
        let scheduledSet = Set(weekdays)
        if scheduledSet.isEmpty { return 0 }
        
        let cal = Calendar.current
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference)) ?? reference.startOfDay
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
        
        let relevantDays = days.filter { scheduledSet.contains($0.isoWeekday) }
        if relevantDays.isEmpty { return 0 }
        
        let doneCount = relevantDays.reduce(0) { $0 + (hasCompletion(on: $1) ? 1 : 0) }
        return Double(doneCount) / Double(relevantDays.count)
    }
}

