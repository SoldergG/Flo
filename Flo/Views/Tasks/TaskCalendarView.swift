import SwiftUI
import SwiftData

struct TaskCalendarView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TaskItem> { $0.parentTask == nil },
           sort: \TaskItem.dueDate)
    private var allTasks: [TaskItem]

    @State private var selectedDate: Date = .now
    @State private var displayedMonth: Date = .now
    @State private var animateDirection: Int = 0

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        calendarSection
                        selectedDateTasks
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Calendar")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        FloCard {
            VStack(spacing: 16) {
                // Month navigation
                HStack {
                    Button {
                        withAnimation(FloAnimations.springSnappy) {
                            animateDirection = -1
                            displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(FloColors.Hex.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(FloColors.Hex.background)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    Spacer()

                    Button {
                        withAnimation(FloAnimations.springSnappy) {
                            animateDirection = 1
                            displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(FloColors.Hex.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(FloColors.Hex.background)
                            .clipShape(Circle())
                    }
                }

                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(FloTypography.caption2)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar grid
                let days = daysInMonth()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                    ForEach(days, id: \.self) { date in
                        if let date = date {
                            dayCell(date)
                        } else {
                            Color.clear
                                .frame(height: 44)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let dayTasks = tasksForDate(date)
        let priorityDots = uniquePriorities(in: dayTasks)

        return Button {
            withAnimation(FloAnimations.springSnappy) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: date))")
                    .font(isToday ? FloTypography.headline : FloTypography.subheadline)
                    .foregroundStyle(
                        isSelected ? .white :
                        isToday ? FloColors.Hex.accent :
                        isCurrentMonth(date) ? FloColors.Hex.textPrimary : FloColors.Hex.textTertiary
                    )
                    .frame(width: 32, height: 32)
                    .background(
                        isSelected ? FloColors.Hex.accent :
                        isToday ? FloColors.Hex.accentSoft :
                        Color.clear
                    )
                    .clipShape(Circle())

                // Priority dots
                HStack(spacing: 2) {
                    ForEach(priorityDots, id: \.self) { priority in
                        Circle()
                            .fill(priority.color)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selected Date Tasks

    private var selectedDateTasks: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Spacer()

                let count = tasksForDate(selectedDate).count
                if count > 0 {
                    Text("\(count) task\(count == 1 ? "" : "s")")
                        .font(FloTypography.badge)
                        .foregroundStyle(FloColors.Hex.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(FloColors.Hex.accentSoft)
                        .clipShape(Capsule())
                }
            }

            let dayTasks = tasksForDate(selectedDate)
            if dayTasks.isEmpty {
                FloCard {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundStyle(FloColors.Hex.border)
                        Text("No tasks for this day")
                            .font(FloTypography.body)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        Spacer()
                    }
                }
            } else {
                ForEach(dayTasks) { task in
                    TaskRow(task: task) {
                        withAnimation(FloAnimations.springBouncy) {
                            task.isCompleted.toggle()
                            task.completedAt = task.isCompleted ? .now : nil
                            try? context.save()
                        }
                    }
                    .background(FloColors.Hex.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let prefixDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: prefixDays)

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        // Fill remaining to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func tasksForDate(_ date: Date) -> [TaskItem] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return allTasks.filter { task in
            if let dueDate = task.dueDate {
                return dueDate >= dayStart && dueDate < dayEnd
            }
            if let scheduled = task.scheduledDate {
                return scheduled >= dayStart && scheduled < dayEnd
            }
            return false
        }
    }

    private func uniquePriorities(in tasks: [TaskItem]) -> [Priority] {
        let prioritySet = Set(tasks.map(\.priority))
        return Array(prioritySet).sorted { $0.rawValue < $1.rawValue }
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.component(.month, from: date) == calendar.component(.month, from: displayedMonth)
    }
}
