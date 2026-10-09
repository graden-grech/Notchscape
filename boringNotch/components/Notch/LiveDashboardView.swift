import Defaults
import SwiftUI

struct LiveDashboardView: View {
    @ObservedObject private var agents = AgentStatusManager.shared
    @Default(.weatherOnLiveTab) private var weatherOnLiveTab

    var body: some View {
        HStack(spacing: 12) {
            agentCard

            if weatherOnLiveTab {
                HomeWeatherTile()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
        .task {
            agents.start()
        }
    }

    private var agentCard: some View {
        dashboardCard(title: "AI Agents", symbol: "sparkles") {
            if let activity = agents.activities.first {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Image(systemName: activity.state.symbol)
                            .foregroundStyle(color(for: activity.state))
                            .symbolEffect(.pulse, isActive: activity.state == .working)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(activity.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text("\(activity.provider) • \(activity.state.label)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    Text(activity.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Label(agents.isListening ? "Ready for Codex" : "Starting bridge…", systemImage: agents.isListening ? "dot.radiowaves.left.and.right" : "hourglass")
                        .font(.subheadline.weight(.medium))
                    Text("Agent activity will appear here.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func dashboardCard<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func color(for state: AgentActivityState) -> Color {
        switch state {
        case .working: .blue
        case .needsInput: .orange
        case .completed: .green
        case .interrupted: .gray
        }
    }
}

struct HomeWeatherTile: View {
    @ObservedObject private var weather = WeatherManager.shared
    @Default(.weatherEnabled) private var weatherEnabled

    var body: some View {
        if weatherEnabled {
            VStack(alignment: .leading, spacing: 7) {
                if let current = weather.weather {
                    HStack(alignment: .top, spacing: 6) {
                        Text(current.location == "Current location" ? "My Location" : current.location)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Image(systemName: current.symbol)
                            .font(.system(size: 22, weight: .medium))
                            .symbolRenderingMode(.multicolor)
                    }

                    Text("\(current.temperature, specifier: "%.0f")°")
                        .font(.system(size: 34, weight: .medium, design: .rounded))
                        .tracking(-1.5)

                    Text(current.condition)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        Text("H:\(current.high, specifier: "%.0f")°")
                        Text("L:\(current.low, specifier: "%.0f")°")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                } else if weather.isLoading {
                    Spacer(minLength: 0)
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: 0)
                } else {
                    Label("Weather", systemImage: "cloud.sun.fill")
                        .font(.caption.weight(.semibold))
                    Spacer(minLength: 4)
                    Text(weather.errorMessage ?? "Weather unavailable")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .frame(width: 132)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(weatherTint.opacity(0.22))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.75)
            }
            .shadow(color: weatherTint.opacity(0.16), radius: 12, y: 5)
            .task { weather.refresh() }
        }
    }

    private var weatherTint: Color {
        guard let code = weather.weather?.weatherCode else { return .blue }
        switch code {
        case 0...2: return .blue
        case 45, 48: return .gray
        case 51...67, 80...82: return .indigo
        case 71...77, 85, 86: return .cyan
        case 95...99: return .purple
        default: return .blue
        }
    }
}
