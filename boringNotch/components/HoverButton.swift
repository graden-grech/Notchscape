//
//  HoverButton.swift
//  boringNotch
//
//  Created by Kraigo on 04.09.2024.
//

import SwiftUI

struct HoverButton: View {
    var icon: String
    var iconColor: Color = .primary
    var scale: Image.Scale = .medium
    var action: () -> Void
    
    @State private var isHovering = false

    var body: some View {
        let size = CGFloat(scale == .large ? 40 : 30)

        Group {
            if #available(macOS 26.0, *) {
                button(size: size)
                    .buttonStyle(.plain)
                    .glassEffect(.regular, in: Circle())
            } else {
                button(size: size)
                    .buttonStyle(.plain)
            }
        }
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.3)) {
                isHovering = hovering
            }
        }
    }

    private func button(size: CGFloat) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(scale == .large ? .largeTitle : .body)
                .frame(width: size, height: size)
                .background(isHovering ? Color.white.opacity(0.08) : .clear, in: Circle())
                .contentShape(Circle())
        }
    }
}
