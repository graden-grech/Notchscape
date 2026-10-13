//
//  TabSelectionView.swift
//  boringNotch
//
//  Created by Hugo Persson on 2024-08-25.
//

import Defaults
import SwiftUI

struct TabModel: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let view: NotchViews
}

let standardTabs = [
    TabModel(label: "Home", icon: "house.fill", view: .home),
    TabModel(label: "Live", icon: "sparkles", view: .live),
    TabModel(label: "Shelf", icon: "tray.fill", view: .shelf)
]

struct TabSelectionView: View {
    @ObservedObject private var performance = AppPerformanceManager.shared
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @Default(.systemDashboardEnabled) private var systemDashboardEnabled
    @Default(.appTheme) private var appTheme
    @Default(.useCustomAccentColor) private var useCustomAccentColor
    @Default(.customAccentColorData) private var customAccentColorData
    @Namespace private var selectionAnimation

    private var tabs: [TabModel] {
        systemDashboardEnabled
            ? standardTabs + [TabModel(label: "System", icon: "gauge.with.dots.needle.50percent", view: .system)]
            : standardTabs
    }

    var body: some View {
        Group {
            if #available(macOS 26.0, *), !performance.lowImpact {
                nativeGlassTabs
            } else {
                fallbackTabs
            }
        }
        .frame(maxWidth: 140)
        .onChange(of: systemDashboardEnabled) { _, enabled in
            if !enabled && coordinator.currentView == .system {
                coordinator.currentView = .home
            }
        }
    }

    @available(macOS 26.0, *)
    private var nativeGlassTabs: some View {
        HStack(spacing: 2) {
            ForEach(tabs) { tab in
                tabControl(tab)
            }
        }
        .padding(3)
        .glassEffect(.regular.interactive(), in: Capsule())
    }

    private var fallbackTabs: some View {
        HStack(spacing: 2) {
            ForEach(tabs) { tab in
                tabControl(tab)
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func tabControl(_ tab: TabModel) -> some View {
        let selected = coordinator.currentView == tab.view
        return TabButton(label: tab.label, icon: tab.icon, selected: selected) {
            select(tab)
        }
        .buttonStyle(.plain)
        .foregroundStyle(selected ? .white : Color.white.opacity(0.58))
        .background {
            if selected {
                Capsule()
                    .fill(Color(nsColor: NSColor.resolvedAccent(theme: appTheme, customEnabled: useCustomAccentColor, customData: customAccentColorData)).opacity(0.42))
                    .matchedGeometryEffect(id: "selected-notch-tab", in: selectionAnimation)
            }
        }
    }

    private func select(_ tab: TabModel) {
        withAnimation(.smooth(duration: 0.25)) {
            coordinator.currentView = tab.view
        }
    }
}

#Preview {
    BoringHeader().environmentObject(BoringViewModel())
}
