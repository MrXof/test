
import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct AddEditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var name: String
    @State private var icon: String
    @State private var color: Color
    @State private var selectedWeekdays: Set<Int>
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var showSymbolPicker = false
    
    var habitToEdit: Habit?
    
    init(habitToEdit: Habit? = nil) {
        self.habitToEdit = habitToEdit
        _name = State(initialValue: habitToEdit?.name ?? "")
        _icon = State(initialValue: habitToEdit?.icon ?? "flame.fill")
        _color = State(initialValue: Color(hex: habitToEdit?.colorHex ?? "#4F46E5"))
        _selectedWeekdays = State(initialValue: Set(habitToEdit?.weekdays ?? Weekday.allCases.map { $0.rawValue }))
        _reminderEnabled = State(initialValue: habitToEdit?.reminderEnabled ?? false)
        
        let defaultTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
        _reminderTime = State(initialValue: habitToEdit?.reminderTime ?? defaultTime)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.green.opacity(0.15), Color.teal.opacity(0.15)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Form {
                    Section("Name & Style") {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(colors: [color, color.opacity(0.6)],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing)
                                    )
                                    .opacity(0.25)
                                    .frame(width: 46, height: 46)
                                    .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 4)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(color)
                            }
                            
                            TextField("Habit name", text: $name)
                                .textInputAutocapitalization(.sentences)
                                .autocorrectionDisabled()
                            
                            ColorPicker("", selection: $color, supportsOpacity: false)
                                .labelsHidden()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
                                .accessibilityLabel("Pick color")
                        }
                        
                        Button {
                            showSymbolPicker = true
                        } label: {
                            HStack {
                                Label("Choose icon", systemImage: icon)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Choose SF Symbol icon")
                    }
                    
                    Section("Weekdays") {
                        WeekdayPicker(selection: $selectedWeekdays)
                            .accessibilityLabel("Pick weekdays")
                    }
                    
                    Section("Reminder") {
                        Toggle("Enabled", isOn: $reminderEnabled)
                        if reminderEnabled {
                            DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(habitToEdit == nil ? "New Habit" : "Edit Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showSymbolPicker) {
                SymbolPicker(selectedSymbol: $icon)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func save() {
        let hex = color.toHex()
        
        if let habit = habitToEdit {
            habit.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            habit.icon = icon.isEmpty ? "flame.fill" : icon
            habit.colorHex = hex
            habit.weekdays = Array(selectedWeekdays).sorted()
            habit.reminderEnabled = reminderEnabled
            habit.reminderTime = reminderTime
            
            reminderEnabled
                ? NotificationManager.shared.scheduleNotifications(for: habit)
                : NotificationManager.shared.removeNotifications(for: habit)
        } else {
            let habit = Habit(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: icon.isEmpty ? "flame.fill" : icon,
                colorHex: hex,
                weekdays: Array(selectedWeekdays).sorted(),
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTime
            )
            context.insert(habit)
            
            if reminderEnabled {
                NotificationManager.shared.scheduleNotifications(for: habit)
            }
        }
        dismiss()
    }
}

fileprivate struct SymbolPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSymbol: String
    
    @State private var query: String = ""
    @State private var category: SymbolCategory = .popular
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.green.opacity(0.1), Color.teal.opacity(0.15)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(filteredSymbols, id: \.self) { symbol in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedSymbol = symbol
                                dismiss()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .strokeBorder(Color.green.opacity(0.35), lineWidth: 1)
                                        )
                                    Image(systemName: symbol)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(colors: [Color.green, Color.teal],
                                                           startPoint: .topLeading,
                                                           endPoint: .bottomTrailing)
                                        )
                                }
                                .frame(height: 50)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(symbol)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Icon")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .searchable(text: $query, prompt: "Search")
        }
    }
    
    private var filteredSymbols: [String] {
        let base = category.symbols
        let q = query.lowercased()
        return q.isEmpty ? base : base.filter { $0.contains(q) }
    }
}

fileprivate enum SymbolCategory: String, CaseIterable, Identifiable {
    case popular, activity, health, time, focus, nature, productivity
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .popular: return "Popular"
        case .activity: return "Activity"
        case .health: return "Health"
        case .time: return "Time"
        case .focus: return "Focus"
        case .nature: return "Nature"
        case .productivity: return "Productivity"
        }
    }
    
    var symbols: [String] {
        switch self {
        case .popular:
            return [
                "flame.fill","bolt.fill","heart.fill","star.fill","checkmark.circle.fill",
                "bell.fill","leaf.fill","sun.max.fill","moon.stars.fill","brain.head.profile",
                "figure.run","drop.fill","timer","calendar","book.fill","sparkles"
            ]
        case .activity:
            return [
                "figure.walk","figure.run","dumbbell.fill","bicycle","sportscourt.fill",
                "trophy.fill","medal.fill","figure.strengthtraining.traditional",
                "figure.yoga","figure.cooldown"
            ]
        case .health:
            return [
                "bandage.fill","cross.case.fill","stethoscope","pill.fill","bed.double.fill",
                "lungs.fill","carrot.fill","cup.and.saucer.fill","waterbottle.fill","fork.knife"
            ]
        case .time:
            return [
                "clock.fill","timer","alarm.fill","hourglass","calendar",
                "sunrise.fill","sunset.fill","moon.zzz.fill"
            ]
        case .focus:
            return [
                "target","checkmark.seal.fill","shield.checkerboard","brain","sparkles",
                "bell.slash.fill","eye.fill","airplane"
            ]
        case .nature:
            return [
                "leaf.fill","hare.fill","tortoise.fill","drop.fill","wind",
                "snowflake","tree.fill","mountain.2.fill","pawprint.fill"
            ]
        case .productivity:
            return [
                "square.and.pencil","list.bullet","doc.text.fill","folder.fill","tray.full.fill",
                "paperplane.fill","bookmark.fill","chart.bar.fill","chart.line.uptrend.xyaxis","server.rack"
            ]
        }
    }
}

#if DEBUG
struct AddEditHabitView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 17.0, *) {
            AddEditHabitView()
                .modelContainer(previewContainer)
        } else {
            // Fallback on earlier versions
        }
    }
}
#endif
