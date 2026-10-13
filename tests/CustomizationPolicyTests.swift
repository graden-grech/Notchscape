import Foundation

// Compile only the pure policy models for this standalone regression suite.
// The running app uses its real AgentActivityState; this fixture provides the
// same Codable cases without starting the live network bridge during tests.
#if CUSTOMIZATION_POLICY_TEST
enum AgentActivityState: String, Codable { case working, needsInput, completed, interrupted, usageLimited }
#endif

@main
struct CustomizationPolicyTests {
    static var count = 0
    static func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
        count += 1
    }

    static func main() throws {
        let all = HomeWidget.allCases
        check(HomeLayoutPolicy.normalized([], legacyWeatherPosition: "end") == all, "Default layout")
        check(HomeLayoutPolicy.normalized([], legacyWeatherPosition: "front") == [.weather, .music, .calendar, .quickActions], "Preserve front weather")
        check(HomeLayoutPolicy.normalized([], legacyWeatherPosition: "afterMusic") == [.music, .weather, .calendar, .quickActions], "Preserve after-music weather")
        check(HomeLayoutPolicy.normalized([.calendar, .calendar, .music], legacyWeatherPosition: "front") == [.calendar, .music, .weather, .quickActions], "Normalize duplicate and missing tiles")
        check(HomeLayoutPolicy.moved(.music, by: -1, in: all) == all, "Cannot move beyond first tile")
        check(HomeLayoutPolicy.moved(.quickActions, by: 1, in: all) == all, "Cannot move beyond last tile")
        check(HomeLayoutPolicy.moved(.calendar, by: -1, in: all) == [.calendar, .music, .weather, .quickActions], "Move calendar earlier")

        for month in 1...12 {
            let north = SeasonalThemeSchedule.themeName(month: month, day: 20, hemisphere: .northern, halloween: false, christmas: false)
            check(north == ([9, 10, 11].contains(month) ? "autumn" : [12, 1, 2].contains(month) ? "winter" : "system"), "Northern schedule \(month)")
            let south = SeasonalThemeSchedule.themeName(month: month, day: 20, hemisphere: .southern, halloween: false, christmas: false)
            check(south == ([3, 4, 5].contains(month) ? "autumn" : [6, 7, 8].contains(month) ? "winter" : "system"), "Southern schedule \(month)")
        }
        check(SeasonalThemeSchedule.themeName(month: 10, day: 14, hemisphere: .northern, halloween: true, christmas: false) == "autumn", "Halloween not early")
        check(SeasonalThemeSchedule.themeName(month: 10, day: 15, hemisphere: .northern, halloween: true, christmas: false) == "halloween", "Halloween boundary")
        check(SeasonalThemeSchedule.themeName(month: 11, day: 1, hemisphere: .northern, halloween: true, christmas: false) == "autumn", "Halloween ends")
        check(SeasonalThemeSchedule.themeName(month: 12, day: 26, hemisphere: .southern, halloween: false, christmas: true) == "christmas", "Optional Christmas in south")
        check(SeasonalThemeSchedule.themeName(month: 12, day: 27, hemisphere: .northern, halloween: false, christmas: true) == "winter", "Return to neutral winter")
        check(SeasonalThemeSchedule.themeName(month: 12, day: 20, hemisphere: .northern, halloween: false, christmas: false) == "winter", "Never opt people into Christmas")

        for battery in [false, true] {
            for lowPower in [false, true] {
                check(!AppPerformanceMode.balanced.isLowImpact(onBattery: battery, systemLowPower: lowPower), "Balanced stays explicit")
                check(AppPerformanceMode.lowImpact.isLowImpact(onBattery: battery, systemLowPower: lowPower), "Low impact always active")
                check(AppPerformanceMode.automatic.isLowImpact(onBattery: battery, systemLowPower: lowPower) == (battery || lowPower), "Automatic power policy")
            }
        }
        let action = NotchQuickAction(name: "My \"Shortcut\" & Focus", kind: .shortcut, target: "-A shortcut with spaces")
        let decodedAction = try JSONDecoder().decode(NotchQuickAction.self, from: JSONEncoder().encode(action))
        check(decodedAction == action, "Action names round-trip without shell parsing")
        let now = Date(timeIntervalSince1970: 1700000000)
        let history = AgentHistoryEntry(id: UUID(), provider: "Codex", title: "Project", state: .usageLimited, startedAt: now, endedAt: now)
        let encoded = try JSONEncoder().encode(history)
        let decodedHistory = try JSONDecoder().decode(AgentHistoryEntry.self, from: encoded)
        check(decodedHistory.state == .usageLimited, "Quota outcome is never completion")
        let object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        check(Set(object.keys) == Set(["id", "provider", "title", "state", "startedAt", "endedAt"]), "History contains metadata only")
        print("Passed \(count) customization policy checks")
    }
}
