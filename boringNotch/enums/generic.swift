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
    case winter

    var id: Self { self }

    var title: String {
        switch self {
        case .standard: "Standard"
        case .autumn: "Fall"
        case .halloween: "Halloween"
        case .christmas: "Christmas"
        case .winter: "Winter"
        }
    }

    var assetName: String {
        switch self {
        case .standard: "AppIconStandard"
        case .autumn: "AppIconAutumn"
        case .halloween: "AppIconHalloween"
        case .christmas: "AppIconChristmas"
        case .winter: "AppIconWinter"
        }
    }

    @MainActor
    func apply() {
        // Theme changes and startup must not touch a hidden Dock tile. The
        // saved icon choice is applied when Dock visibility is re-enabled.
        guard Defaults[.showDockIcon], NSApp.activationPolicy() == .regular else { return }
        guard let image = NSImage(named: assetName) else { return }
        if self == .autumn || self == .halloween {
            // Legacy seasonal artwork has a square backdrop. Apply a rounded
            // silhouette when drawing the Dock representation, preserving alpha.
            let icon = NSImage(size: NSSize(width: 1024, height: 1024))
            icon.lockFocus()
            NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 190, yRadius: 190).addClip()
            image.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024))
            icon.unlockFocus()
            NSApp.applicationIconImage = icon
        } else {
            NSApp.applicationIconImage = image
        }
    }
}

enum AppTheme: String, CaseIterable, Defaults.Serializable, Identifiable {
    case system
    case autumn
    case halloween
    case christmas
    case winter

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System"
        case .autumn: "Fall"
        case .halloween: "Halloween"
        case .christmas: "Christmas"
        case .winter: "Winter"
        }
    }

    var symbol: String {
        switch self {
        case .system: "apple.logo"
        case .autumn: "leaf.fill"
        case .halloween: "moon.stars.fill"
        case .christmas: "tree.fill"
        case .winter: "snowflake"
        }
    }

    var accentColor: NSColor? {
        switch self {
        case .system: nil
        case .autumn: NSColor(red: 0.82, green: 0.32, blue: 0.12, alpha: 1)
        case .halloween: NSColor(red: 0.62, green: 0.32, blue: 0.92, alpha: 1)
        case .christmas: NSColor(red: 0.14, green: 0.62, blue: 0.38, alpha: 1)
        case .winter: NSColor(red: 0.35, green: 0.64, blue: 0.84, alpha: 1)
        }
    }

    var matchingIcon: AppIconVariant {
        switch self {
        case .system: .standard
        case .autumn: .autumn
        case .halloween: .halloween
        case .christmas: .christmas
        case .winter: .winter
        }
    }

    var homeDecoration: String? {
        switch self {
        case .system: nil
        case .autumn: "🍁"
        case .halloween: "🎃"
        case .christmas: "🎄"
        case .winter: nil
        }
    }

    var homeBackdrop: String? {
        switch self {
        case .autumn: "AutumnBackdrop"
        case .christmas: "ChristmasBackdrop"
        case .halloween: "HalloweenBackdrop"
        case .winter: "WinterBackdrop"
        default: nil
        }
    }

    var hasHomeScene: Bool { homeBackdrop != nil }

    var subtitle: String {
        switch self {
        case .system: "Classic Mac appearance"
        case .autumn: "Golden leaves and a warm cabin"
        case .halloween: "Pumpkin glow and candlelight"
        case .christmas: "Tree lights and a cozy fireplace"
        case .winter: "Snowy pines, without holiday decorations"
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
