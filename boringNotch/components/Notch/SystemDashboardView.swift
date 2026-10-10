import SwiftUI

struct SystemDashboardView: View {
    @ObservedObject private var performance = SystemPerformanceManager.shared

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                metricCard("CPU", value: performance.cpuUsage, detail: performance.thermalState, color: .cyan)
                metricCard(
                    "Memory",
                    value: performance.memoryUsage,
                    detail: byteSummary(performance.usedMemory, performance.totalMemory),
                    color: .purple
                )
                metricCard(
                    "Storage",
                    value: performance.diskUsage,
                    detail: byteSummary(UInt64(max(0, performance.usedDisk)), UInt64(max(0, performance.totalDisk))),
                    color: .blue
                )
            }

            HStack(spacing: 8) {
                controlButton("Activity Monitor", icon: "chart.xyaxis.line", action: performance.openActivityMonitor)
                controlButton("Settings", icon: "gearshape.fill", action: performance.openSystemSettings)
                controlButton("Sleep Display", icon: "display", action: performance.sleepDisplay)
                controlButton("Lock", icon: "lock.fill", action: performance.lockMac)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 5)
        .onAppear { performance.startSampling() }
        .onDisappear { performance.stopSampling() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("System performance")
    }

    private func metricCard(_ title: String, value: Double, detail: String, color: Color) -> some View {
        HStack(spacing: 11) {
            Gauge(value: min(max(value, 0), 1)) {
                Text(title)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(color.gradient)
            .scaleEffect(1.08)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(value, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                Text(detail).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(11)
        .frame(maxWidth: .infinity)
        .liquidGlassPanel(tint: color, cornerRadius: 16)
    }

    private func controlButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .liquidGlassCapsule(tint: .accentColor)
    }

    private func byteSummary(_ used: UInt64, _ total: UInt64) -> String {
        guard total > 0 else { return "Loading…" }
        return "\(ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)) / \(ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory))"
    }
}
