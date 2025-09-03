import SwiftUI


struct ProgressRing: View {
    var progress: Double
    
    
    var body: some View {
        ZStack {
            Circle().stroke(lineWidth: 3).opacity(0.2)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)
        }
    }
}


struct ProgressBar: View {
    var progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.systemFill))
                Capsule().fill(Color.accentColor).frame(width: geo.size.width * progress)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
        }
    }
}
