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
                    Color(red: 0.97, green: 0.98, blue: 1.0),
                    Color(red: 0.88, green: 0.93, blue: 1.0),
                    Color(red: 0.82, green: 0.89, blue: 0.99)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.95),
                    Color.white.opacity(0)
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 320
            )
            .blendMode(.screen)

            Circle()
                .fill(Color(red: 0.27, green: 0.58, blue: 1.0).opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: -150, y: -230)

            Circle()
                .fill(Color(red: 0.14, green: 0.79, blue: 0.76).opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 64)
                .offset(x: 150, y: 120)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(Color.white.opacity(0.24))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(24))
                .blur(radius: 18)
                .offset(x: 170, y: -250)

            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(-16))
                .offset(x: -170, y: 260)
        }
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.5),
                    Color.white.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
