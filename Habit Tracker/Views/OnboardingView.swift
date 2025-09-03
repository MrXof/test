
import SwiftUI


struct OnboardingView: View {
    var onFinished: () -> Void
    @State private var page = 0
    @State private var breathe = false
    @Namespace private var ns

    var body: some View {
        ZStack {
            AnimatedBackground()

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("HabitHen")
                        .font(.system(size: 34, weight: .bold))
                        .shadow(radius: 10)
                        .transition(.opacity.combined(with: .scale))

                    Text("Your buddy for better habits")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .opacity(0.95)
                }
                .padding(.top, 12)
                .modifier(Parallax(amount: 6, page: page))

                TabView(selection: $page) {
                    OnboardPageView(
                        title: "Create habits",
                        subtitle: "Name, icon, color and weekdays",
                        systemImage: "square.and.pencil",
                        accent: Color(hex: "#22D3EE"),
                        secondary: Color(hex: "#A78BFA")
                    )
                    .tag(0)

                    OnboardPageView(
                        title: "Track progress",
                        subtitle: "Daily check-ins, streaks and stats",
                        systemImage: "chart.bar.fill",
                        accent: Color(hex: "#10B981"),
                        secondary: Color(hex: "#60A5FA")
                    )
                    .tag(1)

                    OnboardPageView(
                        title: "Get reminders",
                        subtitle: "Flexible time on selected days",
                        systemImage: "bell.badge.fill",
                        accent: Color(hex: "#F59E0B"),
                        secondary: Color(hex: "#A78BFA")
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(maxHeight: 500)
                .padding(.horizontal, 12)
                .animation(.spring(response: 0.6, dampingFraction: 0.9), value: page)

                Button {
                    Task {
                        _ = await NotificationManager.shared.requestAuthorization()
                        onFinished()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(page < 2 ? "Skip" : "Get Started")
                        Image(systemName: page < 2 ? "arrow.right.circle.fill" : "checkmark.seal.fill")
                            .matchedGeometryEffect(id: "ctaicon", in: ns)
                    }
                    .font(.headline)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal)
                }
                .scaleEffect(breathe ? 1.01 : 1.0)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathe)
                .padding(.top, 4)
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
            }
        }
        .onAppear { breathe = true }

        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    withAnimation { page = max(0, page - 1) }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(SoftGlassButtonStyle())
                .disabled(page == 0)
                .opacity(page == 0 ? 0.5 : 1)

                Spacer(minLength: 24)

                Button {
                    withAnimation {
                        if page < 2 { page += 1 }
                        else {
                            Task {
                                _ = await NotificationManager.shared.requestAuthorization()
                                onFinished()
                            }
                        }
                    }
                } label: {
                    Label(page < 2 ? "Next" : "Done", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(SoftGlassButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.clear)
        }
    }
}

struct OnboardPageView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    let secondary: Color

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)

            SoftGlassCard(corner: 28) {
                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let rot = Angle(degrees: 2.0 * sin(t * 0.9 * .pi))
                    let scl = 1.0 + 0.012 * sin(t * 1.1 * .pi)
                    let y   = 2.0 * sin(t * 1.3 * .pi)

                    Image(systemName: systemImage)
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [accent, secondary],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .scaleEffect(scl)
                        .rotationEffect(rot)
                        .offset(y: y)
                        .animation(nil, value: t)
                }
            }
            .frame(width: 300, height: 160)
            .padding(.horizontal, 24)

            Text(title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .shadow(radius: 6)

            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer(minLength: 8)
        }
    }
}

fileprivate struct AnimatedBackground: View {
    @State private var move = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0EA5E9").opacity(0.18), Color(hex: "#8B5CF6").opacity(0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#A78BFA").opacity(0.33))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: move ? -130 : 110, y: move ? -210 : -90)
                .animation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: move)

            Circle()
                .fill(Color(hex: "#22D3EE").opacity(0.33))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: move ? 130 : -110, y: move ? 210 : 120)
                .animation(.easeInOut(duration: 9.0).repeatForever(autoreverses: true), value: move)

            RoundedRectangle(cornerRadius: 300, style: .continuous)
                .fill(Color(hex: "#10B981").opacity(0.24))
                .frame(width: 420, height: 280)
                .blur(radius: 70)
                .rotationEffect(.degrees(move ? 7 : -7))
                .offset(y: move ? 140 : 100)
                .animation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true), value: move)
        }
        .onAppear { move = true }
    }
}

fileprivate struct Parallax: ViewModifier {
    let amount: CGFloat
    let page: Int
    func body(content: Content) -> some View {
        content
            .offset(x: CGFloat(page) * -amount)
            .animation(.easeInOut(duration: 0.6), value: page)
    }
}

fileprivate struct SoftGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                    .shadow(
                        color: .black.opacity(configuration.isPressed ? 0.08 : 0.16),
                        radius: configuration.isPressed ? 6 : 10,
                        x: 0, y: configuration.isPressed ? 4 : 8
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct SoftGlassCard<Content: View>: View {
    var corner: CGFloat = 28
    @ViewBuilder var content: Content
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.black.opacity(0.12))
                .blur(radius: 20)
                .offset(y: 8)
                .opacity(0.9)
                .allowsHitTesting(false)
            
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                )
            
            content
        }
        .compositingGroup()
        .shadow(color: .clear, radius: 0)
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView { }
            .preferredColorScheme(.light)
    }
}
#endif
