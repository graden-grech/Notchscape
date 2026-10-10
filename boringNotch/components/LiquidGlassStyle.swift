import SwiftUI

enum AgentProviderStyle {
    static func isClaude(_ provider: String) -> Bool {
        provider.localizedCaseInsensitiveContains("claude")
    }

    static func accent(for provider: String) -> Color {
        isClaude(provider)
            ? Color(red: 0.96, green: 0.45, blue: 0.24)
            : Color(red: 0.56, green: 0.38, blue: 0.98)
    }

    static func secondary(for provider: String) -> Color {
        isClaude(provider)
            ? Color(red: 1.0, green: 0.72, blue: 0.40)
            : Color(red: 0.38, green: 0.28, blue: 0.82)
    }

    static func symbol(for provider: String) -> String {
        isClaude(provider) ? "sparkle" : "apple.intelligence"
    }
}

struct AgentProviderMark: View {
    let provider: String
    let state: AgentActivityState
    let size: CGFloat
    var symbolOverride: String?

    private var accent: Color {
        state == .completed ? .green : AgentProviderStyle.accent(for: provider)
    }

    private var secondary: Color {
        state == .completed ? Color(red: 0.28, green: 0.82, blue: 0.42) : AgentProviderStyle.secondary(for: provider)
    }

    private var symbol: String {
        if let symbolOverride { return symbolOverride }
        switch state {
        case .completed: return "checkmark"
        case .interrupted: return "pause.fill"
        case .needsInput: return "exclamationmark"
        case .working: return AgentProviderStyle.symbol(for: provider)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [secondary.opacity(0.92), accent.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.42), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.72
                    )
                )

            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.58), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )

            Image(systemName: symbol)
                .font(.system(size: max(9, size * 0.4), weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .repeating, isActive: state == .working)
        }
        .frame(width: size, height: size)
        .shadow(color: accent.opacity(state == .completed ? 0.18 : 0.34), radius: 7, y: 2)
        .accessibilityHidden(true)
    }
}

private struct LiquidGlassPanelModifier: ViewModifier {
    let tint: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.13),
                                tint.opacity(0.15),
                                .black.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.30), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: tint.opacity(0.13), radius: 13, y: 5)
    }
}

private struct LiquidGlassCapsuleModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Capsule())
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.12), tint.opacity(0.16), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.34), tint.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
            .shadow(color: tint.opacity(0.18), radius: 8, y: 2)
    }
}

extension View {
    func liquidGlassPanel(tint: Color = .white, cornerRadius: CGFloat = 18) -> some View {
        modifier(LiquidGlassPanelModifier(tint: tint, cornerRadius: cornerRadius))
    }

    func liquidGlassCapsule(tint: Color = .white) -> some View {
        modifier(LiquidGlassCapsuleModifier(tint: tint))
    }
}
