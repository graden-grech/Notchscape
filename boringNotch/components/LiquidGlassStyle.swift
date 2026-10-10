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
        switch state {
        case .completed: .green
        case .usageLimited: .red
        default: AgentProviderStyle.accent(for: provider)
        }
    }

    private var secondary: Color {
        switch state {
        case .completed: Color(red: 0.28, green: 0.82, blue: 0.42)
        case .usageLimited: Color(red: 1.0, green: 0.32, blue: 0.34)
        default: AgentProviderStyle.secondary(for: provider)
        }
    }

    private var symbol: String {
        if let symbolOverride { return symbolOverride }
        switch state {
        case .completed: return "checkmark"
        case .interrupted: return "pause.fill"
        case .needsInput: return "exclamationmark"
        case .usageLimited: return "exclamationmark"
        case .working: return AgentProviderStyle.symbol(for: provider)
        }
    }

    var body: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)

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
                .symbolEffect(.bounce, value: state == .completed || state == .usageLimited)
        }
        .frame(width: size, height: size)
        .shadow(color: accent.opacity(state == .completed ? 0.18 : 0.34), radius: 7, y: 2)
        .accessibilityHidden(true)
    }
}

struct LiquidGlassSettingsBackground: View {
    var body: some View {
        ZStack {
            Rectangle().fill(.regularMaterial)
            LinearGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.accentColor.opacity(0.035),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.white.opacity(0.11), .clear],
                center: UnitPoint(x: 0.16, y: 0.06),
                startRadius: 0,
                endRadius: 310
            )

            RadialGradient(
                colors: [Color.accentColor.opacity(0.08), .clear],
                center: UnitPoint(x: 0.92, y: 0.88),
                startRadius: 0,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
                        AngularGradient(
                            colors: [
                                .white.opacity(0.46),
                                tint.opacity(0.16),
                                .white.opacity(0.04),
                                .white.opacity(0.22),
                                .white.opacity(0.46)
                            ],
                            center: .center,
                            startAngle: .degrees(-55),
                            endAngle: .degrees(305)
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay(alignment: .top) {
                Capsule()
                    .fill(.white.opacity(0.18))
                    .frame(height: 1)
                    .padding(.horizontal, cornerRadius)
                    .blur(radius: 0.25)
            }
            .overlay(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .trim(from: 0.44, to: 0.72)
                    .stroke(tint.opacity(0.13), lineWidth: 1)
                    .padding(1)
            }
            .shadow(color: .black.opacity(0.22), radius: 12, y: 6)
            .shadow(color: tint.opacity(0.12), radius: 9, y: 2)
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
                        AngularGradient(
                            colors: [
                                .white.opacity(0.48),
                                tint.opacity(0.18),
                                .white.opacity(0.05),
                                .white.opacity(0.24),
                                .white.opacity(0.48)
                            ],
                            center: .center,
                            startAngle: .degrees(-55),
                            endAngle: .degrees(305)
                        ),
                        lineWidth: 0.75
                    )
            }
            .overlay(alignment: .top) {
                Capsule()
                    .fill(.white.opacity(0.24))
                    .frame(height: 1)
                    .padding(.horizontal, 9)
            }
            .shadow(color: .black.opacity(0.18), radius: 7, y: 3)
            .shadow(color: tint.opacity(0.14), radius: 6, y: 1)
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
