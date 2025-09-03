
import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    
    @State private var presentAdd = false
    @State private var showOnlyToday = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        
                        if visibleHabits.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 14, pinnedViews: []) {
                                ForEach(visibleHabits) { habit in
                                    HabitCard(habit: habit) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                            habit.toggleToday()
                                        }
                                    } onDelete: {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                                            context.delete(habit)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 80)
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingAddButton {
                            presentAdd = true
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("My Habits")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        ToolbarGlassIcon(
                            systemName: "gearshape.fill",
                            gradient: LinearGradient(colors: [.blue, .purple],
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing)
                        )
                    }
                    .accessibilityLabel("Settings")
                }


                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarGlassIcon(
                        systemName: "plus",
                        gradient: LinearGradient(colors: [.green, .teal],
                                                 startPoint: .topLeading,
                                                 endPoint: .bottomTrailing)
                    ) {
                        presentAdd = true
                    }
                    .accessibilityLabel("Add Habit")
                }
            }


            .sheet(isPresented: $presentAdd) {
                AddEditHabitView()
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    private var visibleHabits: [Habit] {
        if showOnlyToday {
            return habits.filter { $0.isScheduled(on: .now) }
        } else {
            return habits
        }
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            Picker("", selection: $showOnlyToday) {
                Text("Today").tag(true)
                Text("All").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            if !habits.isEmpty {
                let progress = weeklyProgressForVisibleHabits()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly progress")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text("\(Int(progress * 100))%")
                            .font(.title3.bold())
                    }
                    Spacer()
                    ProgressRing(progress: progress)
                        .frame(width: 28, height: 28)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.18), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 8)
                )
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func weeklyProgressForVisibleHabits() -> Double {
        let hs = visibleHabits
        guard !hs.isEmpty else { return 0 }
        let sum = hs.reduce(0.0) { $0 + $1.weeklyProgress() }
        return min(1.0, max(0.0, sum / Double(hs.count)))
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "No habits",
                systemImage: "sparkles",
                description: Text("Add your first habit")
            )
            Button {
                presentAdd = true
            } label: {
                Label("Create habit", systemImage: "plus")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }
}

@available(iOS 17, *)
struct HabitCard: View {
    let habit: Habit
    var onToggleToday: () -> Void
    var onDelete: () -> Void
    
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: habit.colorHex).opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: habit.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(hex: habit.colorHex))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.name)
                        .font(.headline)
                    
                    HStack(spacing: 10) {
                        ProgressRing(progress: habit.weeklyProgress())
                            .frame(width: 18, height: 18)
                        Text("Streak: \(habit.currentStreak())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    onToggleToday()
                } label: {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(habit.hasCompletion(on: .now) ? .green : .secondary)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onToggleToday()
            } label: {
                Label(habit.hasCompletion(on: .now) ? "Unmark today" : "Mark as done", systemImage: "checkmark")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showDetail) {
            HabitDetailView(habit: habit)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.name), streak \(habit.currentStreak())")
    }
}

struct FloatingAddButton: View {
    var action: () -> Void
    @State private var hover = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle().strokeBorder(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.9), Color.teal.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                        )
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green, Color.teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .green.opacity(0.25), radius: 16, x: 0, y: 10)
                .scaleEffect(hover ? 1.07 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hover)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.15, pressing: { pressing in
            hover = pressing
        }, perform: {})
        .accessibilityLabel("Add habit")
    }
}

struct ToolbarGlassIcon: View {
    let systemName: String
    let gradient: LinearGradient
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { content }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
        .contentShape(Rectangle())
    }

    private var content: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)

            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: systemName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(gradient)
                )
        }
        .compositingGroup()
        .padding(2)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 17.0, *) {
            HomeView()
                .modelContainer(previewContainer)
        } else {
            // Fallback on earlier versions
        }
    }
}
#endif
