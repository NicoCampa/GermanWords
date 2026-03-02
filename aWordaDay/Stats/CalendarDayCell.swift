//
//  CalendarDayCell.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

struct CalendarDayCell: View {
    let date: Date?
    let isStreakDay: Bool
    let isToday: Bool

    var body: some View {
        ZStack {
            if let date = date {
                let dayNumber = Calendar.current.component(.day, from: date)

                Circle()
                    .fill(
                        isStreakDay ?
                            DesignTokens.color.flameSubtle :
                            DesignTokens.color.backgroundLight
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isToday ? DesignTokens.color.progressTint : Color.clear,
                                lineWidth: 2
                            )
                    )

                if isStreakDay {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DesignTokens.color.flame)
                } else {
                    Text("\(dayNumber)")
                        .font(DesignTokens.typography.caption())
                        .foregroundStyle(DesignTokens.color.textTertiary)
                }
            }
        }
        .frame(height: 40)
    }
}
