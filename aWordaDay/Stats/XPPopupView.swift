//
//  XPPopupView.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

struct XPPopupView: View {
    let xpAmount: Int
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(DesignTokens.color.xpGold)

            Text("+\(xpAmount) XP")
                .font(DesignTokens.typography.callout(weight: .bold))
                .foregroundStyle(DesignTokens.color.headingPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(DesignTokens.color.cardBackground)
                .shadow(color: DesignTokens.color.xpGold.opacity(0.4), radius: 12, x: 0, y: 4)
        )
        .offset(y: offset)
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                offset = -80
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
                opacity = 0
            }
        }
    }
}
