//
//  MonthlyStreakCalendar.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

struct MonthlyStreakCalendar: View {
    let currentStreak: Int

    private var calendar: Calendar {
        Calendar.current
    }

    private var currentMonth: Date {
        Date()
    }

    private var monthDays: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private func isStreakDay(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let dateStart = Calendar.current.startOfDay(for: date)

        let daysDifference = calendar.dateComponents([.day], from: dateStart, to: today).day ?? 0

        return daysDifference >= 0 && daysDifference < currentStreak && dateStart <= today
    }

    private func isToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(monthYearString)
                    .font(DesignTokens.typography.headline(weight: .bold))
                    .foregroundStyle(DesignTokens.color.headingPrimary)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignTokens.color.flame)
                    Text("\(currentStreak) days")
                        .font(DesignTokens.typography.caption(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textLight)
                }
            }

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(DesignTokens.typography.footnote(weight: .bold))
                        .foregroundStyle(DesignTokens.color.textLight)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    CalendarDayCell(
                        date: date,
                        isStreakDay: isStreakDay(date),
                        isToday: isToday(date)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DesignTokens.color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        return formatter.veryShortWeekdaySymbols
    }
}
