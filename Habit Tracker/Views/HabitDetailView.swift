
import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let habit: Habit
    @State private var shownMonth: Date = .now

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#0EA5E9").opacity(0.10), Color(hex: "#8B5CF6").opacity(0.10)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        GlassCard {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: habit.colorHex).opacity(0.18))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: habit.icon)
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundStyle(Color(hex: habit.colorHex))
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(habit.name)
                                        .font(.title2.bold())
                                    HStack(spacing: 10) {
                                        StatChip(icon: "flame.fill", title: "", value: "\(habit.currentStreak()) days")
                                        if habit.reminderEnabled, let t = habit.reminderTime {
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
                                Text("This Week")
                                    .font(.headline)
                                ProgressBar(progress: habit.weeklyProgress())
                                    .frame(height: 12)
                            }
                        }
                        .padding(.horizontal, 16)

                        GlassCard {
                            CalendarMonthView(
                                habit: habit,
                                month: shownMonth,
                                onToggleDay: toggleCompletion
                            )
                        }
                        .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    habit.toggleToday()
                                }
                            } label: {
                                Label(habit.hasCompletion(on: .now) ? "Unmark Today" : "Mark Today", systemImage: habit.hasCompletion(on: .now) ? "minus.circle.fill" : "checkmark.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)

                            NavigationLink {
                                AddEditHabitView(habitToEdit: habit)
                            } label: {
                                Label("Edit", systemImage: "square.and.pencil")
                            }
                            .buttonStyle(.bordered)
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
        let d = date.startOfDay
        if let idx = habit.completions.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: d) }) {
            habit.completions.remove(at: idx)
        } else {
            habit.completions.append(d)
        }
    }
}

fileprivate struct CalendarMonthView: View {
    let habit: Habit
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
                        DayCell(date: date, habit: habit) {
                            onToggleDay(date)
                        }
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

fileprivate struct DayCell: View {
    let date: Date
    let habit: Habit
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
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.semibold)
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
        let container = previewContainer
        let context = container.mainContext
        let fetch = FetchDescriptor<Habit>()
        let habits = (try? context.fetch(fetch)) ?? []

        return Group {
            if let sample = habits.first {
                NavigationStack {
                    HabitDetailView(habit: sample)
                }
                .modelContainer(container)
                .preferredColorScheme(.light)

                NavigationStack {
                    HabitDetailView(habit: sample)
                }
                .modelContainer(container)
                .preferredColorScheme(.dark)
            } else {
                Text("⚠️ No data in previewContainer")
            }
        }
    }
}
#endif
