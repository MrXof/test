
import SwiftUI

struct SettingsView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = true

    private let privacyURL = URL(string: "https://docs.google.com/document/d/1AbkoLKHej8z3EAmHam6Ii5jEnlhU1g_D-UvVhy3qJyw/edit?usp=sharing")!
    private let termsURL   = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfCFgudDupfivsvW8CzyJfRReMh6CNjL9yv08JcVSG4wO4UpQ/viewform?usp=header")!

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green.opacity(0.14), Color.teal.opacity(0.14)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    GlassSection(title: "Onboarding") {
                        Button {
                            hasOnboarded = false
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                                        .frame(width: 32, height: 32)
                                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                }

                                Text("Show again")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    GlassSection(title: "About App") {
                        InfoRow(label: "Name", value: "HabitHen")
                        Divider().opacity(0.08)
                        InfoRow(label: "Version", value: "1.0")
                        Divider().opacity(0.08)
                        InfoRow(label: "Developer", value: "Max Korkoskii")
                    }

                    GlassSection(title: "Legal") {
                        LinkRow(title: "Privacy Policy", systemImage: "lock.shield.fill", destination: privacyURL)
                        Divider().opacity(0.08)
                        LinkRow(title: "Support", systemImage: "doc.text.fill", destination: termsURL)
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Settings")
    }
}

fileprivate struct GlassSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 8)
            )
        }
    }
}

fileprivate struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.body)
        .padding(.horizontal, 2)
    }
}

fileprivate struct LinkRow: View {
    let title: String
    let systemImage: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .imageScale(.medium)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.blue)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.18), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    )

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack { SettingsView() }
                .preferredColorScheme(.light)

            NavigationStack { SettingsView() }
                .preferredColorScheme(.dark)
        }
    }
}
#endif
