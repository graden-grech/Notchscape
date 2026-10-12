//
//  generic.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import Foundation
import Defaults
import AppKit

public enum Style {
    case notch
    case floating
}

public enum ContentType: Int, Codable, Hashable, Equatable {
    case normal
    case menu
    case settings
}

public enum NotchState {
    case closed
    case open
}

public enum NotchViews {
    case home
    case shelf
    case live
    case system
}

enum SettingsEnum {
    case general
    case about
    case charge
    case download
    case mediaPlayback
    case hud
    case shelf
    case extensions
}

enum DownloadIndicatorStyle: String, Defaults.Serializable {
    case progress = "Progress"
    case percentage = "Percentage"
}

enum DownloadIconStyle: String, Defaults.Serializable {
    case onlyAppIcon = "Only app icon"
    case onlyIcon = "Only download icon"
    case iconAndAppIcon = "Icon and app icon"
}

enum MirrorShapeEnum: String, Defaults.Serializable {
    case rectangle = "Rectangular"
    case circle = "Circular"
    case roundedRectangle = "Rounded Rectangle"
    case squircle = "Squircle"
    case capsule = "Capsule"
}

enum WindowHeightMode: String, Defaults.Serializable {
    case matchMenuBar = "Match menubar height"
    case matchRealNotchSize = "Match real notch height"
    case custom = "Custom height"
}

enum NonNotchPresentation: String, CaseIterable, Defaults.Serializable, Identifiable {
    case dynamicIsland
    case notch

    var id: Self { self }

    var title: String {
        switch self {
        case .dynamicIsland: "Dynamic Island"
        case .notch: "Notch"
        }
    }
}

enum AppIconVariant: String, CaseIterable, Defaults.Serializable, Identifiable {
    case standard
    case autumn
    case halloween
    case christmas

    var id: Self { self }

    var title: String {
        switch self {
        case .standard: "Standard"
        case .autumn: "Autumn"
        case .halloween: "Halloween"
        case .christmas: "Christmas"
        }
    }

    var assetName: String {
        switch self {
        case .standard: "AppIconStandard"
        case .autumn: "AppIconAutumn"
        case .halloween: "AppIconHalloween"
        case .christmas: "AppIconChristmas"
        }
    }

    @MainActor
    func apply() {
        guard let image = NSImage(named: assetName) else { return }
        NSApp.applicationIconImage = image
    }
}

enum AppTheme: String, CaseIterable, Defaults.Serializable, Identifiable {
    case system
    case autumn
    case halloween
    case christmas

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System"
        case .autumn: "Autumn"
        case .halloween: "Halloween"
        case .christmas: "Christmas"
        }
    }

    var symbol: String {
        switch self {
        case .system: "apple.logo"
        case .autumn: "leaf.fill"
        case .halloween: "moon.stars.fill"
        case .christmas: "snowflake"
        }
    }

    var accentColor: NSColor? {
        switch self {
        case .system: nil
        case .autumn: NSColor(red: 0.82, green: 0.32, blue: 0.12, alpha: 1)
        case .halloween: NSColor(red: 0.62, green: 0.32, blue: 0.92, alpha: 1)
        case .christmas: NSColor(red: 0.14, green: 0.62, blue: 0.38, alpha: 1)
        }
    }

    var matchingIcon: AppIconVariant {
        switch self {
        case .system: .standard
        case .autumn: .autumn
        case .halloween: .halloween
        case .christmas: .christmas
        }
    }

    var homeDecoration: String? {
        switch self {
        case .system: nil
        case .autumn: "🍁"
        case .halloween: "🎃"
        case .christmas: "🎄"
        }
    }
}

enum WeatherTilePosition: String, CaseIterable, Defaults.Serializable, Identifiable {
    case front
    case afterMusic
    case end

    var id: Self { self }

    var title: String {
        switch self {
        case .front: "Front"
        case .afterMusic: "After Music"
        case .end: "End"
        }
    }
}

enum SportsLeague: String, CaseIterable, Defaults.Serializable, Identifiable {
    case nba
    case nfl
    case mlb
    case nhl
    case mls
    case wnba
    case collegeFootball
    case collegeBasketball

    var id: Self { self }

    var title: String {
        switch self {
        case .nba: "NBA"
        case .nfl: "NFL"
        case .mlb: "MLB"
        case .nhl: "NHL"
        case .mls: "MLS"
        case .wnba: "WNBA"
        case .collegeFootball: "College Football"
        case .collegeBasketball: "College Basketball"
        }
    }

    var endpointPath: String {
        switch self {
        case .nba: "basketball/nba"
        case .nfl: "football/nfl"
        case .mlb: "baseball/mlb"
        case .nhl: "hockey/nhl"
        case .mls: "soccer/usa.1"
        case .wnba: "basketball/wnba"
        case .collegeFootball: "football/college-football"
        case .collegeBasketball: "basketball/mens-college-basketball"
        }
    }

    var symbol: String {
        switch self {
        case .nba, .wnba, .collegeBasketball: "basketball.fill"
        case .nfl, .collegeFootball: "football.fill"
        case .mlb: "baseball.fill"
        case .nhl: "hockey.puck.fill"
        case .mls: "soccerball"
        }
    }
}

enum LiveActivityPriority: String, CaseIterable, Defaults.Serializable, Identifiable {
    case combined
    case musicOnly
    case agentOnly

    var id: Self { self }

    var title: String {
        switch self {
        case .combined: "Music + AI"
        case .musicOnly: "Music only"
        case .agentOnly: "AI only"
        }
    }
}

enum ActivityProfile: String, CaseIterable, Defaults.Serializable, Identifiable {
    case everything
    case focus
    case minimal
    case entertainment

    var id: Self { self }

    var title: String {
        switch self {
        case .everything: "Everything"
        case .focus: "Focus"
        case .minimal: "Minimal"
        case .entertainment: "Entertainment"
        }
    }
}

enum SliderColorEnum: String, CaseIterable, Defaults.Serializable {
    case white = "White"
    case albumArt = "Match album art"
    case accent = "Accent color"
}
