import SwiftUI

struct SplashView: View {
    var onFinish: () -> Void
    @State private var scale: CGFloat = 0.8
    @State private var blur: CGFloat = 20
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#22D3EE"), Color(hex: "#A78BFA")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(scale)
                        .blur(radius: blur)
                        .shadow(radius: 20)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 72, weight: .semibold))
                                .foregroundStyle(.white)
                                .opacity(opacity)
                        )
                }
                
                Text("HabitHen")
                    .font(.system(size: 34, weight: .bold))
                    .opacity(opacity)
                
                Text("Your assistant for building habits")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .opacity(opacity)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                scale = 1.1
                blur = 0
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                onFinish()
            }
        }
    }
}
