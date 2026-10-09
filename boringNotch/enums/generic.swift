//
//  generic.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import Foundation
import Defaults

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
}

enum WindowHeightMode: String, Defaults.Serializable {
    case matchMenuBar = "Match menubar height"
    case matchRealNotchSize = "Match real notch height"
    case custom = "Custom height"
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
