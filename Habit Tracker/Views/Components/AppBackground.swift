import SwiftUI


struct AppBackground: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color(hex: "#0EA5E9").opacity(0.15), Color(hex: "#8B5CF6").opacity(0.15)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}
