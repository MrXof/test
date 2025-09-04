
import SwiftUI

protocol HabitRepresentable {
    var id: UUID { get }
    var name: String { get set }
    var icon: String { get set }
    var colorHex: String { get set }
    var createdAt: Date { get set }
    var weekdays: [Int] { get set }
    var reminderEnabled: Bool { get set }
    var reminderTime: Date? { get set }
    var completions: [Date] { get set }

    func isScheduled(on date: Date) -> Bool
    func hasCompletion(on date: Date) -> Bool
    mutating func toggleToday()
    func currentStreak(reference: Date) -> Int
    func weeklyProgress(weekOf reference: Date) -> Double
}
fileprivate func hhtISOWeekday(_ date: Date) -> Int {
    let w = Calendar.current.component(.weekday, from: date)
    return w == 1 ? 7 : w - 1
}
fileprivate func hhtStartOfDay(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
}
fileprivate func hhtColorFromHex(_ hex: String) -> Color {
    var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if s.hasPrefix("#") { s.removeFirst() }
    var rgb: UInt64 = 0
    Scanner(string: s).scanHexInt64(&rgb)
    let r, g, b: Double
    if s.count == 6 {
        r = Double((rgb & 0xFF0000) >> 16) / 255
        g = Double((rgb & 0x00FF00) >> 8) / 255
        b = Double(rgb & 0x0000FF) / 255
    } else { r = 0.31; g = 0.27; b = 0.90 }
    return Color(red: r, green: g, blue: b)
}

extension HabitRepresentable {
    func isScheduled(on date: Date) -> Bool {
        weekdays.contains(hhtISOWeekday(date))
    }
    func hasCompletion(on date: Date) -> Bool {
        let d = hhtStartOfDay(date)
        return completions.contains { Calendar.current.isDate($0, inSameDayAs: d) }
    }
    mutating func toggleToday() {
        let today = hhtStartOfDay(Date())
        if let idx = completions.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            completions.remove(at: idx)
        } else {
            completions.append(today)
        }
    }
    func currentStreak(reference: Date = .now) -> Int {
        var streak = 0
        var day = hhtStartOfDay(reference)
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
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference)) ?? hhtStartOfDay(reference)
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
        let relevantDays = days.filter { scheduledSet.contains(hhtISOWeekday($0)) }
        if relevantDays.isEmpty { return 0 }
        let doneCount = relevantDays.reduce(0) { $0 + (hasCompletion(on: $1) ? 1 : 0) }
        return Double(doneCount) / Double(relevantDays.count)
    }
}

struct HabitMock: HabitRepresentable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date
    var weekdays: [Int]
    var reminderEnabled: Bool
    var reminderTime: Date?
    var completions: [Date]

    init(
        name: String = "Read 20 min",
        icon: String = "book.fill",
        colorHex: String = "#22C55E",
        createdAt: Date = .now,
        weekdays: [Int] = [1,2,3,4,5,6,7],
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        completions: [Date] = []
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.weekdays = weekdays
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.completions = completions.map { hhtStartOfDay($0) }
    }
}

#if canImport(SwiftData)
import SwiftData
@available(iOS 17, *)
extension Habit: HabitRepresentable {}
#endif


struct HabitDetailView<H: HabitRepresentable>: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: H
    @State private var shownMonth: Date = .now

    init(habit: H) {
        _model = State(initialValue: habit)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [hhtColorFromHex("#0EA5E9").opacity(0.10), hhtColorFromHex("#8B5CF6").opacity(0.10)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        GlassCard {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(hhtColorFromHex(model.colorHex).opacity(0.18))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: model.icon)
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundStyle(hhtColorFromHex(model.colorHex))
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(model.name)
                                        .font(.title2.bold())
                                    HStack(spacing: 10) {
                                        StatChip(icon: "flame.fill", title: "", value: "\(model.currentStreak()) days")
                                        if model.reminderEnabled, let t = model.reminderTime {
                                            StatChip(icon: "bell.fill", title: "Reminder", value: t.formatted(date: .omitted, time: .shortened))
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("This Week").font(.headline)
                                ProgressBar(progress: model.weeklyProgress())
                                    .frame(height: 12)
                            }
                        }
                        .padding(.horizontal, 16)

                        GlassCard {
                            CalendarMonthView(habit: model, month: shownMonth, onToggleDay: toggleCompletion)
                        }
                        .padding(.horizontal, 16)
                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    model.toggleToday()
                                }
                            } label: {
                                Label(
                                    model.hasCompletion(on: .now) ? "Unmark Today" : "Mark Today",
                                    systemImage: model.hasCompletion(on: .now) ? "minus.circle.fill" : "checkmark.circle.fill"
                                )
                            }
                            .buttonStyle(.borderedProminent)

                            #if canImport(SwiftData)
                            if #available(iOS 17, *),
                               let realHabit = model as? Habit {
                                NavigationLink {
                                    AddEditHabitView(habitToEdit: realHabit)
                                } label: {
                                    Label("Edit", systemImage: "square.and.pencil")
                                }
                                .buttonStyle(.bordered)
                            }
                            #endif
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("Details")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { shownMonth = Date() }
        }
    }

    private func toggleCompletion(_ date: Date) {
        let d = hhtStartOfDay(date)
        if let idx = model.completions.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: d) }) {
            model.completions.remove(at: idx)
        } else {
            model.completions.append(d)
        }
    }
}

fileprivate struct CalendarMonthView<H: HabitRepresentable>: View {
    let habit: H
    let month: Date
    var onToggleDay: (Date) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var currentMonth: Date = .now

    private let weekSymbols = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    var body: some View {
        VStack(spacing: 10) {
            header
            HStack {
                ForEach(weekSymbols, id: \.self) { s in
                    Text(s).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            let grid = monthGrid(for: currentMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(grid, id: \.self) { maybeDate in
                    if let date = maybeDate {
                        DayCell(date: date, habit: habit) { onToggleDay(date) }
                    } else {
                        Rectangle().fill(Color.clear).frame(height: 34)
                    }
                }
            }

            legend
        }
        .onAppear { currentMonth = month }
    }

    private var header: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: { Image(systemName: "chevron.left") }
            .buttonStyle(.plain)

            Spacer()
            Text(currentMonth, format: .dateTime.year().month(.wide))
                .font(.headline)
            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: { Image(systemName: "chevron.right") }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 4)
    }

    private func monthGrid(for month: Date) -> [Date?] {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let range = cal.range(of: .day, in: .month, for: startOfMonth)!
        let weekday = cal.component(.weekday, from: startOfMonth)
        let mondayFirstOffset = (weekday + 5) % 7

        var result: [Date?] = Array(repeating: nil, count: mondayFirstOffset)
        for day in 1...range.count {
            if let date = cal.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                result.append(date)
            }
        }
        while result.count % 7 != 0 { result.append(nil) }
        if result.count < 42 { result.append(contentsOf: Array(repeating: nil, count: 42 - result.count)) }
        return result
    }

    private var legend: some View {
        HStack(spacing: 12) {
            LegendDot(color: .accentColor, text: "done")
            LegendDot(color: Color(.systemFill), text: "scheduled")
            LegendDot(color: .clear, stroke: .secondary, text: "off-day")
            Spacer()
        }
        .font(.caption)
        .padding(.top, 6)
    }
}
fileprivate struct DayCell<H: HabitRepresentable>: View {
    let date: Date
    let habit: H
    var onTap: () -> Void

    var body: some View {
        let isToday = Calendar.current.isDateInToday(date)
        let scheduled = habit.isScheduled(on: date)
        let done = habit.hasCompletion(on: date)

        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColor(done: done, scheduled: scheduled))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isToday ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: isToday ? 1.5 : 0)
                    )
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(done ? .white : .primary)
                    .opacity(scheduled || done ? 1 : 0.6)
            }
            .frame(height: 34)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(date.formatted(date: .abbreviated, time: .omitted)) — \(done ? "done" : (scheduled ? "scheduled" : "off-day"))"))
    }

    private func backgroundColor(done: Bool, scheduled: Bool) -> some ShapeStyle {
        if done { return AnyShapeStyle(Color.accentColor) }
        if scheduled { return AnyShapeStyle(Color(.systemFill)) }
        return AnyShapeStyle(Color.clear)
    }
}

fileprivate struct StatChip: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            if !title.isEmpty {
                Text(title).foregroundStyle(.secondary)
            }
            Text(value).fontWeight(.semibold)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(.ultraThinMaterial)
                .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        )
    }
}

fileprivate struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading) { content }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.18), lineWidth: 1))
                    .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 8)
            )
    }
}

fileprivate struct LegendDot: View {
    let color: Color
    var stroke: Color? = nil
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .overlay(
                    Circle().strokeBorder(stroke ?? .clear, lineWidth: stroke == nil ? 0 : 1)
                )
                .frame(width: 10, height: 10)
            Text(text)
        }
    }
}


#if DEBUG
struct HabitDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mock = HabitMock(
            name: "Read 20 min",
            icon: "book.fill",
            colorHex: "#22C55E",
            weekdays: [1,2,3,4,5],
            reminderEnabled: true,
            reminderTime: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: .now),
            completions: [Date(), Date().addingTimeInterval(-86400*1), Date().addingTimeInterval(-86400*3)]
        )

        Group {
            NavigationStack { HabitDetailView(habit: mock) }
                .preferredColorScheme(.light)

            NavigationStack { HabitDetailView(habit: mock) }
                .preferredColorScheme(.dark)
        }
    }
}
#endif
