import SwiftUI
import SwiftData


import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            if #available(iOS 17.0, *) {
                AppRoot17(
                    hasOnboarded: $hasOnboarded,
                    showSplash: $showSplash
                )
                .modelContainer(for: Habit.self)
            } else {
                UnsupportedIOSView()
            }
        }
    }
}

@available(iOS 17.0, *)
private struct AppRoot17: View {
    @Binding var hasOnboarded: Bool
    @Binding var showSplash: Bool

    var body: some View {
        ZStack {
            AppBackground()
            Group {
                if showSplash {
                    SplashView {
                        Task {
                            _ = await NotificationManager.shared.requestAuthorization()
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                showSplash = false
                            }
                        }
                    }
                    .transition(.opacity)
                } else if !hasOnboarded {
                    OnboardingView {
                        hasOnboarded = true
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                } else {
                    HomeView()
                        .transition(.opacity)
                }
            }
        }
    }
}

import SwiftUI

struct UnsupportedIOSView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("iOS 17 required")
                .font(.title2.bold())
            Text("This version uses SwiftData, which is available only on iOS 17 or later.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
    }
}
