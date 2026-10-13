import Foundation

enum HomeWidget: String, Codable, CaseIterable, Identifiable {
    case music, calendar, weather, quickActions
    var id: Self { self }
    var title: String {
        switch self {
        case .music: "Music"
        case .calendar: "Calendar"
        case .weather: "Weather"
        case .quickActions: "Quick Actions"
        }
    }
    var symbol: String {
        switch self {
        case .music: "music.note"
        case .calendar: "calendar"
        case .weather: "cloud.sun"
        case .quickActions: "bolt.fill"
        }
    }
}

enum HomeLayoutPolicy {
    static func normalized(_ order: [HomeWidget], legacyWeatherPosition: String) -> [HomeWidget] {
        let legacy: [HomeWidget]
        switch legacyWeatherPosition {
        case "front": legacy = [.weather, .music, .calendar, .quickActions]
        case "afterMusic": legacy = [.music, .weather, .calendar, .quickActions]
        default: legacy = HomeWidget.allCases
        }
        var result: [HomeWidget] = []
        for widget in (order.isEmpty ? legacy : order) + HomeWidget.allCases where !result.contains(widget) {
            result.append(widget)
        }
        return result
    }

    static func moved(_ widget: HomeWidget, by delta: Int, in order: [HomeWidget]) -> [HomeWidget] {
        guard let index = order.firstIndex(of: widget), order.indices.contains(index + delta) else { return order }
        var result = order
        result.swapAt(index, index + delta)
        return result
    }
}

enum SeasonHemisphere: String, Codable, CaseIterable, Identifiable {
    case northern, southern
    var id: Self { self }
    var title: String { self == .northern ? "Northern Hemisphere" : "Southern Hemisphere" }
}

enum SeasonalThemeSchedule {
    /// Explicit, testable schedule. Holiday themes are optional in either hemisphere.
    static func themeName(month: Int, day: Int, hemisphere: SeasonHemisphere, halloween: Bool, christmas: Bool) -> String {
        if halloween && month == 10 && day >= 15 { return "halloween" }
        if christmas && month == 12 && day <= 26 { return "christmas" }
        let seasonalMonth = hemisphere == .northern ? month : ((month + 5) % 12) + 1
        switch seasonalMonth {
        case 9...11: return "autumn"
        case 12, 1, 2: return "winter"
        default: return "system"
        }
    }
}

enum AppPerformanceMode: String, Codable, CaseIterable, Identifiable {
    case balanced, lowImpact, automatic
    var id: Self { self }
    var title: String {
        switch self {
        case .balanced: "Balanced"
        case .lowImpact: "Low impact"
        case .automatic: "Automatic on battery"
        }
    }
    func isLowImpact(onBattery: Bool, systemLowPower: Bool) -> Bool {
        self == .lowImpact || (self == .automatic && (onBattery || systemLowPower))
    }
}

enum QuickActionKind: String, Codable { case application, shortcut }

struct NotchQuickAction: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var kind: QuickActionKind
    var target: String
    var symbol: String { kind == .application ? "app.fill" : "bolt.fill" }
}

struct AgentHistoryEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var provider: String
    var title: String
    var state: AgentActivityState
    var startedAt: Date
    var endedAt: Date
}
