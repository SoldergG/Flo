import SwiftUI
import SwiftData

struct WeeklyPlannerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]

    private let weekDays: [String] = {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }()

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<7, id: \.self) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Calendar.current.startOfDay(for: .now))!
                        daySection(date: date)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Week")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func daySection(date: Date) -> some View {
        let dayTasks = tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return Calendar.current.isDate(due, inSameDayAs: date)
        }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide)))
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textSecondary)

                Spacer()

                Text("\(dayTasks.count)")
                    .font(FloTypography.badge)
                    .foregroundStyle(FloColors.Hex.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(FloColors.Hex.accentSoft)
                    .clipShape(Capsule())
            }

            if dayTasks.isEmpty {
                Text("No tasks")
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(dayTasks) { task in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(task.isCompleted ? FloColors.Hex.success : FloColors.Hex.border)
                            .frame(width: 8, height: 8)
                        Text(task.title)
                            .font(FloTypography.body)
                            .foregroundStyle(FloColors.Hex.textPrimary)
                            .strikethrough(task.isCompleted)
                        Spacer()
                    }
                }
            }
        }
        .padding(14)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
