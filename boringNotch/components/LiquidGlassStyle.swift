import SwiftUI

enum AgentProviderStyle {
    static func isClaude(_ provider: String) -> Bool {
        provider.localizedCaseInsensitiveContains("claude")
    }

    static func accent(for provider: String) -> Color {
        isClaude(provider)
            ? Color(red: 0.86, green: 0.40, blue: 0.24)
            : Color(red: 0.34, green: 0.20, blue: 0.72)
    }

    static func secondary(for provider: String) -> Color {
        isClaude(provider)
            ? Color(red: 0.96, green: 0.62, blue: 0.34)
            : Color(red: 0.52, green: 0.36, blue: 0.88)
    }

    static func symbol(for provider: String) -> String {
        isClaude(provider) ? "sparkle" : "apple.intelligence"
    }
}

struct AgentProviderMark: View {
    @ObservedObject private var performance = AppPerformanceManager.shared
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
        Group {
            if performance.lowImpact {
                Image(systemName: symbol)
                    .font(.system(size: max(9, size * 0.4), weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(accent, in: Circle())
            } else { richMark }
        }
        .accessibilityHidden(true)
    }

    private var richMark: some View {
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
                .symbolEffect(.bounce, value: state == .completed || state == .usageLimited)
        }
        .frame(width: size, height: size)
        .shadow(color: accent.opacity(state == .completed ? 0.18 : 0.34), radius: 7, y: 2)
        .accessibilityHidden(true)
    }
}

struct LiquidGlassSettingsBackground: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .windowBackgroundColor))
            .overlay {
                LinearGradient(
                    colors: [Color.white.opacity(0.035), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct LiquidGlassPanelModifier: ViewModifier {
    @ObservedObject private var performance = AppPerformanceManager.shared
    let tint: Color
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(macOS 26.0, *), !performance.lowImpact {
            content
                .glassEffect(.regular.tint(tint.opacity(0.18)), in: shape)
        } else {
            content
                .background(.thinMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(.white.opacity(0.16), lineWidth: 0.75)
                }
                .shadow(color: .black.opacity(performance.lowImpact ? 0 : 0.16), radius: 7, y: 3)
        }
    }
}

private struct LiquidGlassCapsuleModifier: ViewModifier {
    @ObservedObject private var performance = AppPerformanceManager.shared
    let tint: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *), !performance.lowImpact {
            content
                .glassEffect(.regular.tint(tint.opacity(0.2)).interactive(), in: Capsule())
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.75)
                }
                .shadow(color: .black.opacity(performance.lowImpact ? 0 : 0.14), radius: 5, y: 2)
        }
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
