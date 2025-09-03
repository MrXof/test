import SwiftUI


struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    
    
    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Weekday.allCases) { wd in
                let isOn = selection.contains(wd.rawValue)
                Button(action: {
                    if isOn { selection.remove(wd.rawValue) } else { selection.insert(wd.rawValue) }
                }) {
                    Text(wd.short)
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(isOn ? Color.accentColor : Color(.systemFill)))
                        .foregroundStyle(isOn ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
