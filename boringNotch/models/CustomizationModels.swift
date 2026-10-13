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

enum BatteryPresentationStyle: String, Codable, CaseIterable, Identifiable {
    case original, enhanced
    var id: Self { self }
    var title: String { self == .original ? "Original" : "Enhanced" }
}

enum BatteryIndicatorDisplay: String, Codable, CaseIterable, Identifiable {
    case iconOnly, percentageOnly, both
    var id: Self { self }
    var title: String {
        switch self {
        case .iconOnly: "Icon only"
        case .percentageOnly: "Percentage only"
        case .both: "Icon and percentage"
        }
    }
}

struct BatteryReading: Equatable {
    var level: Double
    var pluggedIn: Bool
    var charging: Bool
    var fullyCharged: Bool
    var status: String {
        if charging { return "Charging" }
        if pluggedIn { return fullyCharged ? "Fully charged" : "Connected to power · Not charging" }
        return "On battery"
    }
}

enum BatteryAlertKind: String {
    case low20, low10, full
    var title: String {
        switch self {
        case .low20: "Battery at 20% or lower"
        case .low10: "Battery at 10% or lower"
        case .full: "Battery fully charged"
        }
    }
}

enum BatteryPolicy {
    static func shouldShow(enabled: Bool, hasBattery: Bool, hideWhenAbsent: Bool) -> Bool {
        enabled && (hasBattery || !hideWhenAbsent)
    }
    static func percentage(current: Double, maximum: Double) -> Double? {
        guard current.isFinite, maximum.isFinite, current >= 0, maximum > 0 else { return nil }
        return min(100, max(0, current / maximum * 100))
    }
    static func alert(from old: BatteryReading?, to new: BatteryReading,
                      low20: Bool, low10: Bool, full: Bool) -> BatteryAlertKind? {
        guard let old else { return nil }
        if full && new.pluggedIn && new.fullyCharged && !old.fullyCharged { return .full }
        guard !new.pluggedIn, !new.charging else { return nil }
        if low10 && old.level > 10 && new.level <= 10 { return .low10 }
        if low20 && old.level > 20 && new.level <= 20 { return .low20 }
        return nil
    }
}

struct BatteryHistorySample: Codable, Equatable, Identifiable {
    var date: Date
    var level: Double
    var pluggedIn: Bool
    var id: Date { date }
}

enum BatteryHistoryPolicy {
    static func retained(_ samples: [BatteryHistorySample], now: Date) -> [BatteryHistorySample] {
        Array(samples.filter { $0.date <= now && now.timeIntervalSince($0.date) <= 86400
            && $0.level.isFinite && (0...100).contains($0.level) }.sorted { $0.date < $1.date }.suffix(512))
    }
    static func adding(_ sample: BatteryHistorySample, to samples: [BatteryHistorySample]) -> [BatteryHistorySample] {
        var result = retained(samples, now: sample.date)
        if let last = result.last, last.level == sample.level, last.pluggedIn == sample.pluggedIn,
           sample.date.timeIntervalSince(last.date) < 300 { return result }
        result.append(sample)
        return Array(result.suffix(512))
    }
}
