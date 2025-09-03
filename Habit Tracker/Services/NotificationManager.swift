import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch { return false }
    }
    
    private func appleWeekday(fromISO iso: Int) -> Int { (iso % 7) + 1 }
    
    @available(iOS 17, *)
    func scheduleNotifications(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        
        let idsToRemove = habit.weekdays.map { "\(habit.id.uuidString)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        
        guard habit.reminderEnabled, let time = habit.reminderTime else { return }
        
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let content = UNMutableNotificationContent()
        
        content.title = NSLocalizedString("notification_title", comment: "Notification title for habit reminder")
        content.body = String(format: NSLocalizedString("notification_body", comment: "Notification body with habit name"), habit.name)
        content.sound = .default
        
        for iso in habit.weekdays.sorted() {
            var triggerComps = DateComponents()
            triggerComps.weekday = appleWeekday(fromISO: iso)
            triggerComps.hour = comps.hour
            triggerComps.minute = comps.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: true)
            let id = "\(habit.id.uuidString)-\(iso)"
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(req)
        }
    }
    
    @available(iOS 17, *)
    func removeNotifications(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        let ids = habit.weekdays.map { "\(habit.id.uuidString)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
