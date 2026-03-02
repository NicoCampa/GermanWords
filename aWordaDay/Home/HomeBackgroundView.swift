//
//  HomeBackgroundView.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

struct HomeBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DesignTokens.color.backgroundGradientTop,
                    DesignTokens.color.backgroundGradientBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                Circle()
                    .fill(DesignTokens.color.primary.opacity(0.06))
                    .frame(width: 240, height: 240)
                    .blur(radius: 40)
                    .offset(x: -140, y: -180)

                Spacer()

                Circle()
                    .fill(DesignTokens.color.skyBlue.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 50)
                    .offset(x: 160, y: 160)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
