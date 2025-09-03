import SwiftUI
import SwiftData


@available(iOS 17, *)
@MainActor
let previewContainer: ModelContainer = {
    let schema = Schema([Habit.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    
    
    let h1 = Habit(name: "Вода 2л", icon: "drop.fill", colorHex: "#0EA5E9", weekdays: [2,3,4,5,6], reminderEnabled: true, reminderTime: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: .now))
    let h2 = Habit(name: "Ранкова зарядка", icon: "figure.run", colorHex: "#10B981", weekdays: [2,3,4,5,6,7,1], reminderEnabled: false)
    h1.completions = [Date().startOfDay]
    h2.completions = [Date().startOfDay]
    
    
    container.mainContext.insert(h1)
    container.mainContext.insert(h2)
    return container
}()


struct HomeViewWithPreviewData_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 17.0, *) {
            HomeView()
                .modelContainer(previewContainer)
        } else {
            // Fallback on earlier versions
        }
    }
}
