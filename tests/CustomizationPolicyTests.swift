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
        for preview in [false, true] {
            check(NotchLockScreenPresentation.resolve(isLocked: true, enabled: false, preview: preview) == .hidden,
                  "A preview cannot override lock-screen visibility being off")
            check(NotchLockScreenPresentation.resolve(isLocked: true, enabled: true, preview: preview) == .lockedHome,
                  "A locked Mac can only show the isolated lock view")
        }
        for enabled in [false, true] {
            check(NotchLockScreenPresentation.resolve(isLocked: false, enabled: enabled) == .normal,
                  "Unlock restores the normal menu without changing the preference")
            check(NotchLockScreenPresentation.resolve(isLocked: false, enabled: enabled, preview: true) == .lockedHome,
                  "Unlocked preview uses the same isolated view")
        }
        let builtIn = NotchDisplayDestination(id: "built-in", isBuiltIn: true)
        let external = NotchDisplayDestination(id: "external", isBuiltIn: false)
        let anotherExternal = NotchDisplayDestination(id: "external-two", isBuiltIn: false)
        let displays = [external, builtIn, anotherExternal]
        check(NotchDisplayPolicy.eligible(displays, showExternal: true) == displays, "External displays stay enabled by default")
        check(NotchDisplayPolicy.eligible(displays, showExternal: false) == [builtIn], "All-display mode excludes every external display")
        check(NotchDisplayPolicy.eligible([external], showExternal: false).isEmpty, "Desktop or clamshell does not secretly fall back to external")
        for automatic in [false, true] {
            check(NotchDisplayPolicy.selectedID(in: displays, preferred: external.id, main: external.id,
                automaticallySwitch: automatic, showExternal: false) == builtIn.id, "Built-in fallback respects external off, automatic=\(automatic)")
            check(NotchDisplayPolicy.selectedID(in: [external], preferred: external.id, main: external.id,
                automaticallySwitch: automatic, showExternal: false) == nil, "No external window in clamshell, automatic=\(automatic)")
            check(NotchDisplayPolicy.selectedID(in: displays, preferred: external.id, main: builtIn.id,
                automaticallySwitch: automatic, showExternal: true) == external.id, "Restore the preferred external display without rewriting its ID")
        }
        check(NotchDisplayPolicy.selectedID(in: displays, preferred: "disconnected", main: external.id,
            automaticallySwitch: true, showExternal: true) == external.id, "Automatic fallback still works")
        check(NotchDisplayPolicy.selectedID(in: displays, preferred: "disconnected", main: external.id,
            automaticallySwitch: false, showExternal: true) == nil, "Do not change original automatic-switch preference")
        check(NotchDisplayPolicy.selectedID(in: [], preferred: nil, main: nil,
            automaticallySwitch: true, showExternal: false) == nil, "No forced unwrap with no connected display")
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
        check(BatteryPolicy.percentage(current: 4000, maximum: 5000) == 80, "Normalize raw charge units")
        check(BatteryPolicy.percentage(current: 120, maximum: 100) == 100, "Clamp impossible high charge")
        check(BatteryPolicy.percentage(current: 0, maximum: 100) == 0, "Zero charge is valid")
        check(BatteryPolicy.percentage(current: 10, maximum: 0) == nil, "Missing scale is not zero battery")
        check(BatteryPolicy.percentage(current: .nan, maximum: 100) == nil, "Reject nonfinite readings")
        let reading = { (level: Double) in BatteryReading(level: level, pluggedIn: false, charging: false, fullyCharged: false) }
        let alert = { (old: BatteryReading?, new: BatteryReading) in
            BatteryPolicy.alert(from: old, to: new, low20: true, low10: true, full: true)
        }
        check(alert(nil, reading(5)) == nil, "No low-battery startup spam")
        check(alert(reading(21), reading(20)) == .low20, "20 percent crossing")
        check(alert(reading(20), reading(19)) == nil, "No duplicate threshold alert")
        check(alert(reading(11), reading(10)) == .low10, "10 percent crossing")
        check(alert(reading(40), reading(8)) == .low10, "Only most urgent alert after a large drop")
        check(BatteryPolicy.alert(from: reading(21), to: reading(19), low20: false, low10: false, full: false) == nil, "Optional alerts remain optional")
        let paused = BatteryReading(level: 80, pluggedIn: true, charging: false, fullyCharged: false)
        check(!paused.status.contains("Desktop"), "Never invent why charging is paused")
        check(alert(reading(21), BatteryReading(level: 10, pluggedIn: true, charging: true, fullyCharged: false)) == nil, "No low alerts while charging")
        let full = BatteryReading(level: 100, pluggedIn: true, charging: false, fullyCharged: true)
        check(alert(paused, full) == .full, "Reported full charge transition")
        check(alert(full, full) == nil, "No repeated full-charge alert")
        check(alert(nil, full) == nil, "No full-charge startup spam")
        check(alert(paused, paused) == nil, "Charging limit is not a full-charge event")
        let sample = BatteryHistorySample(date: now, level: 80, pluggedIn: true)
        check(BatteryHistoryPolicy.adding(sample, to: []).count == 1, "First actual history reading")
        let same = BatteryHistorySample(date: now.addingTimeInterval(20), level: 80, pluggedIn: true)
        check(BatteryHistoryPolicy.adding(same, to: [sample]).count == 1, "Coalesce repeated history events")
        let changed = BatteryHistorySample(date: now.addingTimeInterval(30), level: 79, pluggedIn: true)
        check(BatteryHistoryPolicy.adding(changed, to: [sample]).count == 2, "Save actual level changes")
        let oldSample = BatteryHistorySample(date: now.addingTimeInterval(-86401), level: 80, pluggedIn: true)
        let future = BatteryHistorySample(date: now.addingTimeInterval(3600), level: 80, pluggedIn: true)
        check(BatteryHistoryPolicy.retained([oldSample, sample, future], now: now) == [sample], "24-hour retention excludes future samples")
        let many = (0..<600).map { BatteryHistorySample(date: now.addingTimeInterval(Double(-600 + $0)), level: 50, pluggedIn: false) }
        check(BatteryHistoryPolicy.retained(many, now: now).count == 512, "Bound battery history storage")
        let decodedSample = try JSONDecoder().decode(BatteryHistorySample.self, from: JSONEncoder().encode(sample))
        check(decodedSample == sample, "Local history persistence round trip")
        check(BatteryPresentationStyle.allCases.contains(.original), "Original battery style stays available")
        check(BatteryIndicatorDisplay.allCases.count == 3, "Icon, percentage, and both options")
        check(BatteryPolicy.symbol(level: 0, charging: false) == "battery.0percent", "Native empty battery symbol")
        check(BatteryPolicy.symbol(level: 25, charging: false) == "battery.25percent", "Native quarter battery symbol")
        check(BatteryPolicy.symbol(level: 50, charging: false) == "battery.50percent", "Native half battery symbol")
        check(BatteryPolicy.symbol(level: 75, charging: false) == "battery.75percent", "Native three-quarter battery symbol")
        check(BatteryPolicy.symbol(level: 100, charging: false) == "battery.100percent", "Native full battery symbol")
        check(BatteryPolicy.symbol(level: 20, charging: true) == "battery.100percent.bolt", "Charging uses a fixed-size native symbol")
        check(!BatteryPolicy.shouldShow(enabled: true, hasBattery: false, hideWhenAbsent: true), "Auto-hide batteryless desktops")
        check(BatteryPolicy.shouldShow(enabled: true, hasBattery: false, hideWhenAbsent: false), "Allow manual desktop override")
        check(BatteryPolicy.shouldShow(enabled: true, hasBattery: true, hideWhenAbsent: true), "Keep battery indicator on laptops")
        check(!BatteryPolicy.shouldShow(enabled: false, hasBattery: true, hideWhenAbsent: false), "Respect the existing hide toggle")
        #if BATTERY_IOKIT_TEST
        check(!BatteryInfo.absent.hasBattery && BatteryInfo.absent.isAvailable, "Absent battery is distinct from read failure")
        check(!BatteryInfo.unavailable.isAvailable, "Read failure is not a zero-percent battery")
        let snapshot = BatteryActivityManager.shared.initializeBatteryInfo()
        check(snapshot.isAvailable, "Read real system power source successfully")
        check(!snapshot.hasBattery || (0...100).contains(snapshot.currentCapacity), "Live percentage is valid")
        #endif
        print("Passed \(count) customization policy checks")
    }
}
