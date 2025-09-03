import SwiftUI

@available(iOS 17, *)
struct CalendarHeatmap: View {
    let habit: Habit

    var body: some View {
        let cal = Calendar.current
        let today = Date().startOfDay
        let days = (0..<28).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }.reversed()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { day in
                let scheduled = habit.isScheduled(on: day)
                let done = habit.hasCompletion(on: day)

                RoundedRectangle(cornerRadius: 6)
                    .fill(colorFor(done: done, scheduled: scheduled))
                    .frame(height: 18)
                    .overlay(
                        Text(shortWeek(for: day))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .opacity(Calendar.current.isDateInToday(day) ? 1 : 0)
                    )
                    .accessibilityLabel(
                        Text("\(day.formatted(date: .abbreviated, time: .omitted)) — \(done ? "done" : (scheduled ? "scheduled" : "off"))")
                    )
            }
        }
    }

    private func colorFor(done: Bool, scheduled: Bool) -> Color {
        if done { return Color.accentColor }
        return scheduled ? Color(.systemFill) : Color.clear
    }

    private func shortWeek(for date: Date) -> String {
        let wd = Calendar.current.component(.weekday, from: date)
        switch wd {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        default: return "Sat"
        }
    }
}
