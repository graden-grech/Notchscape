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
        check(StarWarsCharacterArtwork.allCases.count == 2, "Lightsaber scenery and character artwork stay separate choices")
        for artwork in StarWarsCharacterArtwork.allCases {
            let restored = try JSONDecoder().decode(StarWarsCharacterArtwork.self, from: JSONEncoder().encode(artwork))
            check(restored == artwork, "Vader artwork choice persists")
            for variant in StarWarsThemeVariant.allCases {
                check(variant.backdropName(artwork: artwork, characterArtworkAvailable: false) == variant.backdropName,
                      "Missing character artwork always keeps the original scene instead of a blank background")
                let asset = variant.backdropName(artwork: artwork)
                if variant == .vader && artwork == .character {
                    check(asset == "StarWarsVaderSceneBackdrop", "Only the selected Vader character scene uses the new artwork")
                } else {
                    check(asset == variant.backdropName, "Other themes and original lightsaber scenery are unchanged")
                }
            }
        }
        check(StarWarsThemeVariant.characters.count == 8, "Eight characters live under the single theme family")
        check(Set(StarWarsThemeVariant.allCases.map(\.rawValue)).count == 10, "Every Star Wars variant has a stable unique setting")
        for variant in StarWarsThemeVariant.allCases {
            let decodedVariant = try JSONDecoder().decode(StarWarsThemeVariant.self, from: JSONEncoder().encode(variant))
            check(decodedVariant == variant, "Star Wars choice persists")
            check(["StarWarsJediBackdrop", "StarWarsDarkSideBackdrop", "StarWarsDesertBackdrop"].contains(variant.backdropName), "Every variant uses a bundled scene")
            check((0...1).contains(variant.rgb.red) && (0...1).contains(variant.rgb.green) && (0...1).contains(variant.rgb.blue), "Character colors are valid RGB")
        }
        check(StarWarsThemeVariant.vader.category == .characters && StarWarsThemeVariant.vader.backdropName == StarWarsThemeVariant.darkSide.backdropName, "Vader keeps a Dark Side environment on the character page")
        check(LightsaberColorMode.allCases.count == 3, "Theme, album cover, and any custom color are available")
        for (value, duration, expected) in [(0.0, 0.0, 0.0), (50, 100, 0.5), (-20, 100, 0), (120, 100, 1), (10, -1, 0)] {
            check(LightsaberTrackPolicy.progress(value: value, duration: duration) == expected, "Playback progress is clamped safely")
        }
        check(LightsaberTrackPolicy.progress(value: .nan, duration: 100) == 0, "Invalid track metadata cannot create an invalid frame")
        check(LightsaberTrackPolicy.progress(value: 10, duration: .infinity) == 0, "Live or unknown duration is not a full blade")
        check(LightsaberTrackPolicy.time(at: 50, width: 100, duration: 240) == 120, "Scrubbing maps to the track's time")
        check(LightsaberTrackPolicy.time(at: -10, width: 100, duration: 240) == 0, "Scrubbing before the hilt clamps to the start")
        check(LightsaberTrackPolicy.time(at: 200, width: 100, duration: 240) == 240, "Scrubbing beyond the tip clamps to the end")
        check(LightsaberTrackPolicy.time(at: .nan, width: 100, duration: 240) == nil, "Invalid drag coordinates are ignored")
        check(LightsaberTrackPolicy.time(at: 10, width: 0, duration: 240) == nil, "Zero-width playback bars cannot divide by zero")
        check(LightsaberTrackPolicy.time(at: 10, width: 100, duration: 0) == nil, "An empty player never issues a seek")
        for music in [false, true] {
            for override in [false, true] {
                for activities in [false, true] {
                    for profileAllowsMusic in [false, true] {
                        let allowed = MusicPresentationPolicy.isAllowed(musicEnabled: music,
                            overrideEnabled: override, liveActivitiesEnabled: activities,
                            profileAllowsMusic: profileAllowsMusic)
                        let expected = music && (override || (activities && profileAllowsMusic))
                        check(allowed == expected, "Music override respects its own switch and all activity/profile combinations")
                    }
                }
            }
        }
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
        check(HomeLayoutPolicy.reordered(.music, over: .weather, in: all) == [.calendar, .weather, .music, .quickActions], "Drag a tile forward")
        check(HomeLayoutPolicy.reordered(.weather, over: .music, in: all) == [.weather, .music, .calendar, .quickActions], "Drag a tile backward")
        check(HomeLayoutPolicy.reordered(.music, over: .music, in: all) == all, "Dragging over itself is stable")
        check(HomeLayoutPolicy.reordered(.music, over: .weather, in: [.music]) == [.music], "A hidden/missing target cannot corrupt the layout")
        for count in 3...5 {
            for index in 0..<count {
                check(NotchTabLayoutPolicy.index(at: (Double(index) + 0.5) * 134 / Double(count), width: 134, count: count) == index, "Tab drag picks the correct segment")
            }
            check(NotchTabLayoutPolicy.index(at: -100, width: 134, count: count) == 0, "Drag clamps before the first tab")
            check(NotchTabLayoutPolicy.index(at: 1000, width: 134, count: count) == count - 1, "Drag clamps after the last tab")
        }
        check(NotchTabLayoutPolicy.index(at: .nan, width: 134, count: 5) == nil, "Invalid drag coordinate rejected")
        check(NotchTabLayoutPolicy.index(at: 0, width: 0, count: 0) == nil, "No division by zero with no tabs")
        check(SeasonalThemeSchedule.easterComponents(year: 2026)?.month == 4 && SeasonalThemeSchedule.easterComponents(year: 2026)?.day == 5, "Easter 2026 follows its real date")
        check(SeasonalThemeSchedule.easterComponents(year: 2027)?.month == 3 && SeasonalThemeSchedule.easterComponents(year: 2027)?.day == 28, "Easter moves in 2027")
        check(SeasonalThemeSchedule.easterComponents(year: 2028)?.day == 16, "Easter computus handles leap years")
        check(SeasonalThemeSchedule.easterComponents(year: 0) == nil, "Invalid Easter year rejected")
        let gregorian = Calendar(identifier: .gregorian)
        let easter2026 = gregorian.date(from: DateComponents(year: 2026, month: 4, day: 5))!
        for delta in [-8, -7, 0, 1, 2] {
            let date = gregorian.date(byAdding: .day, value: delta, to: easter2026)!
            let theme = SeasonalThemeSchedule.themeName(date: date, hemisphere: .northern, halloween: false, christmas: false, easter: true, calendar: gregorian)
            check((theme == "easter") == (-7...1).contains(delta), "Easter schedule boundary \(delta)")
        }
        check(SeasonalThemeSchedule.themeName(date: easter2026, hemisphere: .northern, halloween: false, christmas: false, easter: false, calendar: gregorian) == "system", "Easter is never enabled without opt-in")

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
