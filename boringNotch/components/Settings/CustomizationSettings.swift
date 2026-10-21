import Defaults
import SwiftUI

enum PresetAccentColor: String, CaseIterable, Identifiable {
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case graphite = "Graphite"

    var id: String { self.rawValue }

    var color: Color {
        switch self {
        case .blue: return Color(red: 0.0, green: 0.478, blue: 1.0)
        case .purple: return Color(red: 0.686, green: 0.322, blue: 0.871)
        case .pink: return Color(red: 1.0, green: 0.176, blue: 0.333)
        case .red: return Color(red: 1.0, green: 0.271, blue: 0.227)
        case .orange: return Color(red: 1.0, green: 0.584, blue: 0.0)
        case .yellow: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .green: return Color(red: 0.4, green: 0.824, blue: 0.176)
        case .graphite: return Color(red: 0.557, green: 0.557, blue: 0.576)
        }
    }
}

struct HomeLayoutSettings: View {
    @Default(.homeWidgetOrder) private var order
    @Default(.hiddenHomeWidgets) private var hidden
    @Default(.weatherTilePosition) private var legacyWeatherPosition
    @Default(.weatherOnLiveTab) private var weatherOnLiveTab
    @Default(.weatherEnabled) private var weatherEnabled
    @Default(.showCalendar) private var showCalendar

    private var widgets: [HomeWidget] { HomeLayoutPolicy.normalized(order, legacyWeatherPosition: legacyWeatherPosition.rawValue) }

    var body: some View {
        ForEach(Array(widgets.enumerated()), id: \.element) { index, widget in
            HStack(spacing: 10) {
                Toggle(isOn: visibility(widget)) {
                    Label(widget.title, systemImage: widget.symbol)
                }
                .toggleStyle(.checkbox)
                Spacer()
                Button { order = HomeLayoutPolicy.moved(widget, by: -1, in: widgets) } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(index == 0)
                .help("Move \(widget.title) earlier")
                .accessibilityLabel("Move \(widget.title) earlier")
                Button { order = HomeLayoutPolicy.moved(widget, by: 1, in: widgets) } label: {
                    Image(systemName: "chevron.down")
                }
                .disabled(index == widgets.count - 1)
                .help("Move \(widget.title) later")
                .accessibilityLabel("Move \(widget.title) later")
            }
            .buttonStyle(.borderless)
        }
        Button("Reset Home layout") { order = []; hidden = [] }
        Text("Use the arrows to reorder tiles; uncheck a tile to hide it from Home. Showing Weather here moves it from Live. Calendar alerts and other Live Activities are unchanged.")
            .font(.caption).foregroundStyle(.secondary)
    }

    private func visibility(_ widget: HomeWidget) -> Binding<Bool> {
        Binding(get: {
            !hidden.contains(widget) && (widget != .weather || (weatherEnabled && !weatherOnLiveTab))
                && (widget != .calendar || showCalendar)
        }, set: { enabled in
            if enabled {
                hidden.remove(widget)
                if widget == .weather { weatherEnabled = true; weatherOnLiveTab = false }
                if widget == .calendar { showCalendar = true }
            } else { hidden.insert(widget) }
        })
    }
}

struct SeasonalThemeSettings: View {
    @Default(.automaticSeasonalThemes) private var automatic
    @Default(.seasonHemisphere) private var hemisphere
    @Default(.seasonalHalloween) private var halloween
    @Default(.seasonalChristmas) private var christmas
    @Default(.appTheme) private var theme

    var body: some View {
        Toggle("Automatically follow the seasons", isOn: $automatic)
        if automatic {
            Picker("Season schedule", selection: $hemisphere) {
                ForEach(SeasonHemisphere.allCases) { Text($0.title).tag($0) }
            }
            Toggle("Include Halloween · October 15–31", isOn: $halloween)
            Toggle("Include Christmas · December 1–26", isOn: $christmas)
            LabeledContent("Current theme", value: theme.title)
        }
        Text(hemisphere == .northern
             ? "Fall: September–November. Winter: December–February. System: March–August. Holiday themes are optional. Selecting a theme yourself turns off automatic switching."
             : "Fall: March–May. Winter: June–August. System: September–February. Optional holiday themes still follow their calendar dates. Selecting a theme yourself turns off automatic switching.")
            .font(.caption).foregroundStyle(.secondary)
    }
}

struct PerformanceSettingsSection: View {
    @Default(.performanceMode) private var mode
    @ObservedObject private var performance = AppPerformanceManager.shared
    var body: some View {
        Section("Performance") {
            Picker("Rendering mode", selection: $mode) {
                ForEach(AppPerformanceMode.allCases) { Text($0.title).tag($0) }
            }
            LabeledContent("Currently", value: performance.lowImpact ? "Low impact" : "Balanced")
            Text("Low impact simplifies glass, shadows and artwork effects, uses a static music indicator and refreshes media and system stats less often. Automatic enables it on battery or in macOS Low Power Mode. Reduce Motion is respected in every mode.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct QuickActionsSettings: View {
    @Default(.quickActions) private var actions
    @ObservedObject private var manager = QuickActionsManager.shared
    @State private var shortcutName = ""

    var body: some View {
        ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
            HStack(spacing: 8) {
                Label(action.name, systemImage: action.symbol).lineLimit(1)
                Spacer(minLength: 5)
                Button { move(index, by: -1) } label: { Image(systemName: "chevron.up") }
                    .disabled(index == 0).accessibilityLabel("Move \(action.name) earlier")
                Button { move(index, by: 1) } label: { Image(systemName: "chevron.down") }
                    .disabled(index == actions.count - 1).accessibilityLabel("Move \(action.name) later")
                Button { actions.removeAll { $0.id == action.id } } label: { Image(systemName: "minus.circle") }
                    .accessibilityLabel("Remove \(action.name) from Quick Actions")
            }
            .buttonStyle(.borderless)
        }
        Button("Add app…", systemImage: "plus.app") { manager.addApplication() }
            .disabled(actions.count >= 6)
        HStack {
            if !manager.shortcutNames.isEmpty {
                Picker("Apple Shortcut", selection: $shortcutName) {
                    Text("Choose a shortcut").tag("")
                    ForEach(manager.shortcutNames, id: \.self) { Text($0).tag($0) }
                }
            } else {
                TextField("Exact name of an Apple Shortcut", text: $shortcutName)
            }
            Button("Add") { manager.addShortcut(shortcutName); shortcutName = "" }
                .disabled(shortcutName.isEmpty || actions.count >= 6)
        }
        HStack {
            Button("Refresh shortcut list") { Task { await manager.loadShortcuts() } }
                .disabled(manager.isLoading)
            if manager.isLoading { ProgressView().controlSize(.small) }
        }
        if let error = manager.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
        Text("Add up to six apps or Apple Shortcuts. They appear in the Quick Actions Home tile, which can be moved or hidden above. Shortcuts only run when you click them, and may request their own permissions.")
            .font(.caption).foregroundStyle(.secondary)
        .task { await manager.loadShortcuts() }
    }

    private func move(_ index: Int, by delta: Int) {
        guard actions.indices.contains(index + delta) else { return }
        actions.swapAt(index, index + delta)
    }
}

struct QuickActionsHomeTile: View {
    @Default(.quickActions) private var actions
    @ObservedObject private var manager = QuickActionsManager.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Quick Actions", systemImage: "bolt.fill").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(actions.prefix(6)) { action in
                    Button { manager.run(action) } label: {
                        VStack(spacing: 3) {
                            if manager.runningIDs.contains(action.id) {
                                ProgressView().controlSize(.small).frame(height: 18)
                            } else if let icon = manager.icon(for: action) {
                                Image(nsImage: icon).resizable().scaledToFit().frame(width: 18, height: 18)
                            } else {
                                Image(systemName: action.symbol).frame(height: 18)
                            }
                            Text(action.name).font(.system(size: 9, weight: .medium)).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .liquidGlassCapsule()
                    .disabled(manager.runningIDs.contains(action.id))
                    .help("Run \(action.name)")
                    .accessibilityLabel("Run \(action.name)")
                }
            }
            if let error = manager.errorMessage {
                Text(error).font(.caption2).foregroundStyle(.red).lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 132, height: 130, alignment: .topLeading)
    }
}

struct AgentHistoryRows: View {
    let entries: [AgentHistoryEntry]
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(entries) { entry in
                HStack(spacing: 8) {
                    Image(systemName: entry.state.symbol)
                        .foregroundStyle(entry.state == .completed ? Color.green : entry.state == .usageLimited ? .red : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title).font(.caption.weight(.semibold)).lineLimit(1)
                        Text("\(entry.provider) · \(entry.state.label)").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    Text(entry.endedAt, style: .time).font(.caption2).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

struct AgentHistorySettings: View {
    @Default(.agentHistoryEnabled) private var enabled
    @ObservedObject private var agents = AgentStatusManager.shared
    @State private var confirmClear = false
    var body: some View {
        Section("Recent AI activity") {
            Toggle("Keep local AI activity history", isOn: $enabled)
            if agents.history.isEmpty {
                Text(enabled ? "Finished tasks will appear here." : "History is off.").foregroundStyle(.secondary)
            } else {
                ScrollView { AgentHistoryRows(entries: agents.history) }.frame(maxHeight: 180)
                Button("Clear history", role: .destructive) { confirmClear = true }
                    .confirmationDialog("Clear the local AI activity history?", isPresented: $confirmClear) {
                        Button("Clear history", role: .destructive) { agents.clearHistory() }
                    }
            }
            Text("Keeps the latest 50 outcomes on this Mac: provider, project name, times and status. No prompts, replies or full folder paths are saved. Turning this off stops new recording; use Clear history to erase existing entries.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
